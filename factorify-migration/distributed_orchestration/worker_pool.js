const EventEmitter = require('events');

class WorkerPool extends EventEmitter {
    constructor(config = {}) {
        super();

        this.config = {
            maxWorkers: config.maxWorkers || 100,
            healthCheckInterval: config.healthCheckInterval || 60000,
            heartbeatTimeout: config.heartbeatTimeout || 300000,
            ...config
        };

        this.workers = new Map();
        this.isRunning = false;
    }

    async initialize() {
        console.log('Initializing Worker Pool...');
        this.isRunning = true;
        this.startHealthChecks();
        console.log('Worker Pool initialized successfully');
    }

    async registerWorker(workerConfig) {
        const { id, repository, capabilities = [], maxConcurrentJobs = 5 } = workerConfig;

        if (!id || !repository) {
            throw new Error('Worker id and repository are required');
        }

        if (this.workers.has(id)) {
            console.log(`Worker ${id} already registered, updating configuration`);
        }

        if (this.workers.size >= this.config.maxWorkers && !this.workers.has(id)) {
            throw new Error(`Worker pool at capacity (${this.config.maxWorkers} workers)`);
        }

        const worker = {
            id,
            repository,
            capabilities,
            maxConcurrentJobs,
            activeJobs: 0,
            totalJobsCompleted: 0,
            status: 'available',
            registeredAt: new Date().toISOString(),
            lastHeartbeat: Date.now(),
            metadata: workerConfig.metadata || {}
        };

        this.workers.set(id, worker);

        console.log(`Worker ${id} registered for repository ${repository}`);
        this.emit('worker:registered', worker);

        return worker;
    }

    async unregisterWorker(workerId) {
        const worker = this.workers.get(workerId);

        if (!worker) {
            console.log(`Worker ${workerId} not found`);
            return;
        }

        if (worker.activeJobs > 0) {
            console.warn(`Worker ${workerId} has ${worker.activeJobs} active jobs, marking for removal`);
            worker.status = 'draining';
            return;
        }

        this.workers.delete(workerId);

        console.log(`Worker ${workerId} unregistered`);
        this.emit('worker:unregistered', { workerId, repository: worker.repository });
    }

    async getAvailableWorkers(capability = null) {
        const available = [];

        for (const [id, worker] of this.workers.entries()) {
            if (worker.status !== 'available') {
                continue;
            }

            if (worker.activeJobs >= worker.maxConcurrentJobs) {
                continue;
            }

            if (capability && !worker.capabilities.includes(capability)) {
                continue;
            }

            available.push(worker);
        }

        return available.sort((a, b) => a.activeJobs - b.activeJobs);
    }

    async assignJobToWorker(jobType, targetRepository = null) {
        const workers = await this.getAvailableWorkers(jobType);

        if (workers.length === 0) {
            throw new Error(`No available workers for job type: ${jobType}`);
        }

        let selectedWorker;

        if (targetRepository) {
            selectedWorker = workers.find(w => w.repository === targetRepository);

            if (!selectedWorker) {
                console.warn(`No worker found for repository ${targetRepository}, using alternative`);
                selectedWorker = workers[0];
            }
        } else {
            selectedWorker = workers[0];
        }

        selectedWorker.activeJobs++;
        selectedWorker.status = selectedWorker.activeJobs >= selectedWorker.maxConcurrentJobs
            ? 'busy'
            : 'available';

        this.emit('job:assigned', {
            workerId: selectedWorker.id,
            repository: selectedWorker.repository,
            jobType,
            activeJobs: selectedWorker.activeJobs
        });

        return selectedWorker;
    }

    async releaseWorker(workerId, success = true) {
        const worker = this.workers.get(workerId);

        if (!worker) {
            console.warn(`Worker ${workerId} not found during release`);
            return;
        }

        worker.activeJobs = Math.max(0, worker.activeJobs - 1);

        if (success) {
            worker.totalJobsCompleted++;
        }

        if (worker.status === 'draining' && worker.activeJobs === 0) {
            await this.unregisterWorker(workerId);
            return;
        }

        if (worker.activeJobs < worker.maxConcurrentJobs) {
            worker.status = 'available';
        }

        this.emit('job:released', {
            workerId,
            repository: worker.repository,
            success,
            activeJobs: worker.activeJobs
        });
    }

    async updateHeartbeat(workerId) {
        const worker = this.workers.get(workerId);

        if (!worker) {
            console.warn(`Worker ${workerId} not found during heartbeat update`);
            return;
        }

        worker.lastHeartbeat = Date.now();

        if (worker.status === 'unhealthy') {
            worker.status = 'available';
            this.emit('worker:recovered', { workerId, repository: worker.repository });
        }
    }

    startHealthChecks() {
        this.healthCheckInterval = setInterval(() => {
            this.performHealthChecks();
        }, this.config.healthCheckInterval);

        console.log('Health checks started');
    }

    performHealthChecks() {
        const now = Date.now();
        const timeout = this.config.heartbeatTimeout;

        for (const [id, worker] of this.workers.entries()) {
            if (worker.status === 'draining') {
                continue;
            }

            if (now - worker.lastHeartbeat > timeout) {
                console.warn(`Worker ${id} heartbeat timeout (last: ${new Date(worker.lastHeartbeat).toISOString()})`);

                if (worker.status !== 'unhealthy') {
                    worker.status = 'unhealthy';
                    this.emit('worker:unhealthy', { workerId: id, repository: worker.repository });
                }

                if (now - worker.lastHeartbeat > timeout * 2) {
                    console.error(`Worker ${id} exceeded timeout threshold, unregistering`);
                    this.unregisterWorker(id);
                }
            }
        }
    }

    async shutdown() {
        console.log('Shutting down Worker Pool...');
        this.isRunning = false;

        if (this.healthCheckInterval) {
            clearInterval(this.healthCheckInterval);
        }

        const activeWorkers = Array.from(this.workers.values()).filter(w => w.activeJobs > 0);

        if (activeWorkers.length > 0) {
            console.log(`Waiting for ${activeWorkers.length} workers with active jobs...`);
        }

        console.log('Worker Pool shutdown complete');
    }

    getMetrics() {
        const workers = Array.from(this.workers.values());

        return {
            totalWorkers: workers.length,
            availableWorkers: workers.filter(w => w.status === 'available').length,
            busyWorkers: workers.filter(w => w.status === 'busy').length,
            unhealthyWorkers: workers.filter(w => w.status === 'unhealthy').length,
            drainingWorkers: workers.filter(w => w.status === 'draining').length,
            totalActiveJobs: workers.reduce((sum, w) => sum + w.activeJobs, 0),
            totalJobsCompleted: workers.reduce((sum, w) => sum + w.totalJobsCompleted, 0),
            averageUtilization: workers.length > 0
                ? workers.reduce((sum, w) => sum + (w.activeJobs / w.maxConcurrentJobs), 0) / workers.length
                : 0,
            repositories: [...new Set(workers.map(w => w.repository))]
        };
    }

    getWorkerDetails(workerId) {
        return this.workers.get(workerId);
    }

    getAllWorkers() {
        return Array.from(this.workers.values());
    }
}

const workerPool = new WorkerPool();

module.exports = {
    WorkerPool,
    registerWorker: (config) => workerPool.registerWorker(config),
    unregisterWorker: (workerId) => workerPool.unregisterWorker(workerId),
    getAvailableWorkers: (capability) => workerPool.getAvailableWorkers(capability),
    assignJobToWorker: (jobType, targetRepository) => workerPool.assignJobToWorker(jobType, targetRepository),
    releaseWorker: (workerId, success) => workerPool.releaseWorker(workerId, success),
    updateHeartbeat: (workerId) => workerPool.updateHeartbeat(workerId),
    getPoolMetrics: () => workerPool.getMetrics(),
    initializeWorkerPool: () => workerPool.initialize(),
    shutdownWorkerPool: () => workerPool.shutdown()
};
