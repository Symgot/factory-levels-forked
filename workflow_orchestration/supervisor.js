/**
 * Workflow Supervisor - GitHub Actions Orchestration Engine
 * Phase 9: Workflow Integration & Distributed Runner Orchestration
 * 
 * Reference: https://docs.github.com/rest/actions/workflows
 * Reference: https://docs.github.com/rest/actions/workflow-runs
 */

const { Octokit } = require('@octokit/rest');
const winston = require('winston');
const PQueue = require('p-queue').default;
const pRetry = require('p-retry');
const cron = require('node-cron');

class WorkflowSupervisor {
    constructor(options = {}) {
        this.options = {
            maxParallelJobs: options.maxParallelJobs || 10,
            retryAttempts: options.retryAttempts || 2,
            retryDelay: options.retryDelay || 30000,
            slotUtilizationTarget: options.slotUtilizationTarget || 0.95,
            monitoringInterval: options.monitoringInterval || 30000,
            ...options
        };

        this.octokit = new Octokit({
            auth: options.githubToken || process.env.GITHUB_TOKEN
        });

        this.logger = winston.createLogger({
            level: 'info',
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.json()
            ),
            transports: [
                new winston.transports.Console(),
                new winston.transports.File({ filename: 'supervisor.log' })
            ]
        });

        this.jobQueue = new PQueue({
            concurrency: this.options.maxParallelJobs,
            timeout: 3600000
        });

        this.state = {
            runningJobs: new Map(),
            queuedJobs: [],
            completedJobs: [],
            failedJobs: [],
            slotUtilization: 0,
            lastUpdate: null
        };

        this.metrics = {
            totalJobsScheduled: 0,
            totalJobsCompleted: 0,
            totalJobsFailed: 0,
            averageExecutionTime: 0,
            averageWaitTime: 0,
            slotUtilizationHistory: []
        };
    }

    async initialize() {
        this.logger.info('Initializing Workflow Supervisor', {
            maxParallelJobs: this.options.maxParallelJobs,
            slotUtilizationTarget: this.options.slotUtilizationTarget
        });

        cron.schedule('*/30 * * * * *', () => this.monitorSlotUtilization());
        cron.schedule('0 * * * *', () => this.generateHourlyReport());

        this.logger.info('Workflow Supervisor initialized successfully');
    }

    async scheduleWorkflow(workflowConfig) {
        const jobId = `job-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        
        const job = {
            id: jobId,
            workflow: workflowConfig.workflow,
            ref: workflowConfig.ref || 'main',
            inputs: workflowConfig.inputs || {},
            priority: workflowConfig.priority || 'normal',
            scheduledAt: Date.now(),
            status: 'queued'
        };

        this.state.queuedJobs.push(job);
        this.metrics.totalJobsScheduled++;

        this.logger.info('Workflow scheduled', { jobId, workflow: job.workflow });

        const jobPromise = this.jobQueue.add(
            () => this.executeWorkflow(job),
            { priority: this.getPriorityValue(job.priority) }
        );

        return { jobId, promise: jobPromise };
    }

    async executeWorkflow(job) {
        const startTime = Date.now();
        job.status = 'running';
        job.startedAt = startTime;
        
        this.state.runningJobs.set(job.id, job);
        this.state.queuedJobs = this.state.queuedJobs.filter(j => j.id !== job.id);

        this.logger.info('Executing workflow', { jobId: job.id, workflow: job.workflow });

        try {
            const result = await pRetry(
                () => this.triggerGitHubWorkflow(job),
                {
                    retries: this.options.retryAttempts,
                    minTimeout: this.options.retryDelay,
                    onFailedAttempt: (error) => {
                        this.logger.warn('Workflow execution attempt failed', {
                            jobId: job.id,
                            attempt: error.attemptNumber,
                            error: error.message
                        });
                    }
                }
            );

            const executionTime = Date.now() - startTime;
            job.status = 'completed';
            job.completedAt = Date.now();
            job.executionTime = executionTime;
            job.result = result;

            this.state.runningJobs.delete(job.id);
            this.state.completedJobs.push(job);
            this.metrics.totalJobsCompleted++;

            this.updateAverageExecutionTime(executionTime);

            this.logger.info('Workflow completed successfully', {
                jobId: job.id,
                executionTime: `${executionTime}ms`
            });

            return result;

        } catch (error) {
            const executionTime = Date.now() - startTime;
            job.status = 'failed';
            job.failedAt = Date.now();
            job.executionTime = executionTime;
            job.error = error.message;

            this.state.runningJobs.delete(job.id);
            this.state.failedJobs.push(job);
            this.metrics.totalJobsFailed++;

            this.logger.error('Workflow execution failed', {
                jobId: job.id,
                error: error.message,
                executionTime: `${executionTime}ms`
            });

            throw error;
        }
    }

    async triggerGitHubWorkflow(job) {
        const [owner, repo] = (process.env.GITHUB_REPOSITORY || 'owner/repo').split('/');

        try {
            const response = await this.octokit.rest.actions.createWorkflowDispatch({
                owner,
                repo,
                workflow_id: job.workflow,
                ref: job.ref,
                inputs: job.inputs
            });

            this.logger.info('GitHub workflow triggered', {
                jobId: job.id,
                workflow: job.workflow,
                status: response.status
            });

            await this.pollWorkflowCompletion(owner, repo, job);

            return {
                success: true,
                jobId: job.id,
                workflow: job.workflow
            };

        } catch (error) {
            this.logger.error('Failed to trigger GitHub workflow', {
                jobId: job.id,
                error: error.message
            });
            throw error;
        }
    }

    async pollWorkflowCompletion(owner, repo, job, maxAttempts = 60) {
        for (let attempt = 0; attempt < maxAttempts; attempt++) {
            await this.sleep(5000);

            try {
                const runs = await this.octokit.rest.actions.listWorkflowRuns({
                    owner,
                    repo,
                    workflow_id: job.workflow,
                    per_page: 1
                });

                if (runs.data.workflow_runs.length > 0) {
                    const latestRun = runs.data.workflow_runs[0];
                    
                    if (latestRun.status === 'completed') {
                        if (latestRun.conclusion === 'success') {
                            return { success: true, runId: latestRun.id };
                        } else {
                            throw new Error(`Workflow failed with conclusion: ${latestRun.conclusion}`);
                        }
                    }
                }
            } catch (error) {
                this.logger.warn('Error polling workflow status', {
                    attempt,
                    error: error.message
                });
            }
        }

        throw new Error('Workflow polling timeout');
    }

    async monitorSlotUtilization() {
        const runningCount = this.state.runningJobs.size;
        const queuedCount = this.state.queuedJobs.length;
        const utilization = runningCount / this.options.maxParallelJobs;

        this.state.slotUtilization = utilization;
        this.state.lastUpdate = Date.now();

        this.metrics.slotUtilizationHistory.push({
            timestamp: Date.now(),
            utilization,
            running: runningCount,
            queued: queuedCount
        });

        if (this.metrics.slotUtilizationHistory.length > 100) {
            this.metrics.slotUtilizationHistory.shift();
        }

        this.logger.info('Slot utilization update', {
            utilization: `${(utilization * 100).toFixed(2)}%`,
            running: runningCount,
            queued: queuedCount,
            available: this.options.maxParallelJobs - runningCount
        });

        if (utilization < this.options.slotUtilizationTarget && queuedCount > 0) {
            this.logger.warn('Slot utilization below target with queued jobs', {
                utilization: `${(utilization * 100).toFixed(2)}%`,
                target: `${(this.options.slotUtilizationTarget * 100).toFixed(2)}%`,
                queued: queuedCount
            });
        }
    }

    async generateHourlyReport() {
        const avgUtilization = this.metrics.slotUtilizationHistory.length > 0
            ? this.metrics.slotUtilizationHistory.reduce((sum, m) => sum + m.utilization, 0) / this.metrics.slotUtilizationHistory.length
            : 0;

        const report = {
            timestamp: new Date().toISOString(),
            jobs: {
                scheduled: this.metrics.totalJobsScheduled,
                completed: this.metrics.totalJobsCompleted,
                failed: this.metrics.totalJobsFailed,
                running: this.state.runningJobs.size,
                queued: this.state.queuedJobs.length
            },
            performance: {
                averageExecutionTime: `${this.metrics.averageExecutionTime.toFixed(2)}ms`,
                averageSlotUtilization: `${(avgUtilization * 100).toFixed(2)}%`,
                targetUtilization: `${(this.options.slotUtilizationTarget * 100).toFixed(2)}%`
            },
            efficiency: {
                completionRate: this.metrics.totalJobsScheduled > 0
                    ? `${((this.metrics.totalJobsCompleted / this.metrics.totalJobsScheduled) * 100).toFixed(2)}%`
                    : '0%',
                failureRate: this.metrics.totalJobsScheduled > 0
                    ? `${((this.metrics.totalJobsFailed / this.metrics.totalJobsScheduled) * 100).toFixed(2)}%`
                    : '0%'
            }
        };

        this.logger.info('Hourly workflow supervisor report', report);
        return report;
    }

    getJobStatistics() {
        return {
            state: {
                running: this.state.runningJobs.size,
                queued: this.state.queuedJobs.length,
                completed: this.state.completedJobs.length,
                failed: this.state.failedJobs.length
            },
            metrics: {
                ...this.metrics,
                currentSlotUtilization: `${(this.state.slotUtilization * 100).toFixed(2)}%`,
                targetUtilization: `${(this.options.slotUtilizationTarget * 100).toFixed(2)}%`
            }
        };
    }

    getPriorityValue(priority) {
        const priorities = {
            critical: 4,
            high: 3,
            normal: 2,
            low: 1
        };
        return priorities[priority] || priorities.normal;
    }

    updateAverageExecutionTime(executionTime) {
        const totalCompleted = this.metrics.totalJobsCompleted;
        const currentAvg = this.metrics.averageExecutionTime;
        
        this.metrics.averageExecutionTime = 
            (currentAvg * (totalCompleted - 1) + executionTime) / totalCompleted;
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async shutdown() {
        this.logger.info('Shutting down Workflow Supervisor');
        
        await this.jobQueue.onIdle();
        
        const finalReport = await this.generateHourlyReport();
        this.logger.info('Final report generated', finalReport);
        
        this.logger.info('Workflow Supervisor shutdown complete');
    }
}

module.exports = { WorkflowSupervisor };
