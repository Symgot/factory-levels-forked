const { Octokit } = require('@octokit/rest');
const EventEmitter = require('events');
const { enqueueJob, getJobStatus } = require('./queue_manager');
const { getAvailableWorkers, registerWorker } = require('./worker_pool');

class MultiRepoSupervisor extends EventEmitter {
    constructor(config = {}) {
        super();

        this.config = {
            maxParallelJobs: config.maxParallelJobs || 40,
            githubToken: config.githubToken || process.env.GITHUB_TOKEN,
            pollingInterval: config.pollingInterval || 30000,
            retryAttempts: config.retryAttempts || 3,
            retryDelay: config.retryDelay || 5000,
            ...config
        };

        this.octokit = new Octokit({ auth: this.config.githubToken });
        this.activeJobs = new Map();
        this.repositories = new Set();
        this.isRunning = false;
        this.stats = {
            jobsDispatched: 0,
            jobsCompleted: 0,
            jobsFailed: 0,
            totalExecutionTime: 0
        };
    }

    async initialize() {
        console.log('Initializing Multi-Repository Supervisor...');
        this.isRunning = true;
        this.startMonitoring();
        console.log('Multi-Repository Supervisor initialized successfully');
    }

    async registerRepository(owner, repo, config = {}) {
        const repoKey = `${owner}/${repo}`;

        if (this.repositories.has(repoKey)) {
            console.log(`Repository ${repoKey} already registered`);
            return;
        }

        try {
            const { data: repository } = await this.octokit.repos.get({ owner, repo });

            this.repositories.add(repoKey);

            await registerWorker({
                id: `worker_${repoKey}_${Date.now()}`,
                repository: repoKey,
                capabilities: config.capabilities || ['mod_analysis', 'workflow_trigger'],
                maxConcurrentJobs: config.maxConcurrentJobs || 5,
                status: 'available',
                registeredAt: new Date().toISOString()
            });

            console.log(`Repository ${repoKey} registered successfully`);
            this.emit('repository:registered', { repository: repoKey, config });

        } catch (error) {
            console.error(`Failed to register repository ${repoKey}:`, error.message);
            throw error;
        }
    }

    async unregisterRepository(owner, repo) {
        const repoKey = `${owner}/${repo}`;

        if (!this.repositories.has(repoKey)) {
            console.log(`Repository ${repoKey} not registered`);
            return;
        }

        this.repositories.delete(repoKey);

        const { unregisterWorker } = require('./worker_pool');
        await unregisterWorker(repoKey);

        console.log(`Repository ${repoKey} unregistered successfully`);
        this.emit('repository:unregistered', { repository: repoKey });
    }

    async dispatchJob(jobConfig) {
        const { targetRepository, workflow, ref = 'main', inputs = {}, priority = 'normal' } = jobConfig;

        if (!targetRepository) {
            throw new Error('Target repository is required');
        }

        const [owner, repo] = targetRepository.split('/');

        if (!this.repositories.has(targetRepository)) {
            await this.registerRepository(owner, repo);
        }

        const jobId = `job_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        await enqueueJob({
            id: jobId,
            type: 'workflow_dispatch',
            priority,
            data: {
                targetRepository,
                workflow,
                ref,
                inputs,
                dispatchedAt: new Date().toISOString()
            }
        });

        console.log(`Job ${jobId} dispatched to ${targetRepository}`);
        this.stats.jobsDispatched++;
        this.emit('job:dispatched', { jobId, targetRepository, workflow });

        return jobId;
    }

    async processJob(job) {
        const startTime = Date.now();
        const { targetRepository, workflow, ref, inputs } = job.data;
        const [owner, repo] = targetRepository.split('/');

        try {
            this.activeJobs.set(job.id, {
                ...job,
                startedAt: new Date().toISOString(),
                status: 'running'
            });

            this.emit('job:started', { jobId: job.id, targetRepository });

            await this.octokit.actions.createWorkflowDispatch({
                owner,
                repo,
                workflow_id: workflow,
                ref,
                inputs
            });

            const executionTime = Date.now() - startTime;
            this.stats.totalExecutionTime += executionTime;
            this.stats.jobsCompleted++;

            this.activeJobs.delete(job.id);

            console.log(`Job ${job.id} completed in ${executionTime}ms`);
            this.emit('job:completed', { jobId: job.id, executionTime });

            return { success: true, executionTime };

        } catch (error) {
            const executionTime = Date.now() - startTime;
            this.stats.jobsFailed++;

            this.activeJobs.delete(job.id);

            console.error(`Job ${job.id} failed after ${executionTime}ms:`, error.message);
            this.emit('job:failed', { jobId: job.id, error: error.message, executionTime });

            if (job.retryCount < this.config.retryAttempts) {
                await this.retryJob(job);
            }

            throw error;
        }
    }

    async retryJob(job) {
        const retryDelay = this.config.retryDelay * Math.pow(2, job.retryCount || 0);

        console.log(`Retrying job ${job.id} in ${retryDelay}ms (attempt ${(job.retryCount || 0) + 1})`);

        setTimeout(async () => {
            await enqueueJob({
                ...job,
                retryCount: (job.retryCount || 0) + 1
            });
        }, retryDelay);
    }

    startMonitoring() {
        this.monitoringInterval = setInterval(async () => {
            try {
                await this.processQueue();
                await this.checkWorkerHealth();
                await this.emitMetrics();
            } catch (error) {
                console.error('Monitoring error:', error.message);
            }
        }, this.config.pollingInterval);

        console.log('Monitoring started');
    }

    async processQueue() {
        const workers = await getAvailableWorkers();
        const { dequeueJob } = require('./queue_manager');
        const availableSlots = workers.reduce((sum, w) => sum + (w.maxConcurrentJobs - (w.activeJobs || 0)), 0);

        if (availableSlots === 0) {
            return;
        }

        const jobsToProcess = Math.min(availableSlots, this.config.maxParallelJobs - this.activeJobs.size);

        for (let i = 0; i < jobsToProcess; i++) {
            const job = await dequeueJob();

            if (!job) {
                break;
            }

            this.processJob(job).catch(error => {
                console.error(`Job processing error:`, error.message);
            });
        }
    }

    async checkWorkerHealth() {
        const workers = await getAvailableWorkers();
        const { unregisterWorker } = require('./worker_pool');

        for (const worker of workers) {
            if (worker.status === 'unhealthy' || worker.lastHeartbeat < Date.now() - 300000) {
                console.warn(`Worker ${worker.id} is unhealthy, unregistering`);
                await unregisterWorker(worker.repository);
            }
        }
    }

    async emitMetrics() {
        const { getQueueMetrics } = require('./queue_manager');
        const queueMetrics = await getQueueMetrics();
        const workers = await getAvailableWorkers();

        const metrics = {
            activeJobs: this.activeJobs.size,
            queuedJobs: queueMetrics.queueSize,
            availableWorkers: workers.filter(w => w.status === 'available').length,
            totalWorkers: workers.length,
            registeredRepositories: this.repositories.size,
            stats: this.stats,
            averageExecutionTime: this.stats.jobsCompleted > 0
                ? Math.round(this.stats.totalExecutionTime / this.stats.jobsCompleted)
                : 0,
            timestamp: new Date().toISOString()
        };

        this.emit('metrics', metrics);

        if (metrics.queuedJobs > 100) {
            this.emit('alert:high_queue', metrics);
        }

        if (metrics.availableWorkers < 2) {
            this.emit('alert:low_workers', metrics);
        }
    }

    async shutdown() {
        console.log('Shutting down Multi-Repository Supervisor...');
        this.isRunning = false;

        if (this.monitoringInterval) {
            clearInterval(this.monitoringInterval);
        }

        for (const [jobId, job] of this.activeJobs.entries()) {
            console.log(`Waiting for active job ${jobId} to complete...`);
        }

        console.log('Multi-Repository Supervisor shutdown complete');
    }

    getMetrics() {
        return {
            activeJobs: this.activeJobs.size,
            registeredRepositories: this.repositories.size,
            stats: this.stats,
            isRunning: this.isRunning
        };
    }
}

module.exports = MultiRepoSupervisor;
