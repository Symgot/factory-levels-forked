/**
 * Job Queue Manager - Priority-based Job Scheduling
 * Phase 9: Workflow Integration & Distributed Runner Orchestration
 * 
 * Reference: https://docs.github.com/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow
 */

const EventEmitter = require('events');
const winston = require('winston');

class JobQueueManager extends EventEmitter {
    constructor(options = {}) {
        super();
        
        this.options = {
            maxQueueSize: options.maxQueueSize || 1000,
            priorityLevels: options.priorityLevels || ['critical', 'high', 'normal', 'low'],
            maxWaitTime: options.maxWaitTime || 300000,
            ...options
        };

        this.queues = new Map();
        this.options.priorityLevels.forEach(level => {
            this.queues.set(level, []);
        });

        this.logger = winston.createLogger({
            level: 'info',
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.json()
            ),
            transports: [
                new winston.transports.Console()
            ]
        });

        this.metrics = {
            totalEnqueued: 0,
            totalDequeued: 0,
            totalExpired: 0,
            averageWaitTime: 0,
            queueLengthByPriority: {}
        };

        setInterval(() => this.cleanupExpiredJobs(), 60000);
    }

    enqueue(job) {
        const priority = job.priority || 'normal';
        
        if (!this.queues.has(priority)) {
            throw new Error(`Invalid priority level: ${priority}`);
        }

        const totalQueued = Array.from(this.queues.values())
            .reduce((sum, queue) => sum + queue.length, 0);

        if (totalQueued >= this.options.maxQueueSize) {
            throw new Error('Queue is full');
        }

        const queuedJob = {
            ...job,
            enqueuedAt: Date.now(),
            expiresAt: Date.now() + this.options.maxWaitTime
        };

        this.queues.get(priority).push(queuedJob);
        this.metrics.totalEnqueued++;

        this.logger.info('Job enqueued', {
            jobId: job.id,
            priority,
            queueLength: this.queues.get(priority).length
        });

        this.emit('job-enqueued', queuedJob);
        return queuedJob;
    }

    dequeue() {
        for (const priority of this.options.priorityLevels) {
            const queue = this.queues.get(priority);
            
            if (queue.length > 0) {
                const job = queue.shift();
                const waitTime = Date.now() - job.enqueuedAt;
                
                this.metrics.totalDequeued++;
                this.updateAverageWaitTime(waitTime);

                this.logger.info('Job dequeued', {
                    jobId: job.id,
                    priority,
                    waitTime: `${waitTime}ms`
                });

                this.emit('job-dequeued', job);
                return job;
            }
        }

        return null;
    }

    peek(priority) {
        if (priority) {
            const queue = this.queues.get(priority);
            return queue && queue.length > 0 ? queue[0] : null;
        }

        for (const level of this.options.priorityLevels) {
            const job = this.peek(level);
            if (job) return job;
        }

        return null;
    }

    remove(jobId) {
        for (const [priority, queue] of this.queues.entries()) {
            const index = queue.findIndex(job => job.id === jobId);
            if (index !== -1) {
                const job = queue.splice(index, 1)[0];
                this.logger.info('Job removed from queue', { jobId, priority });
                this.emit('job-removed', job);
                return job;
            }
        }
        return null;
    }

    changePriority(jobId, newPriority) {
        if (!this.queues.has(newPriority)) {
            throw new Error(`Invalid priority level: ${newPriority}`);
        }

        const job = this.remove(jobId);
        if (!job) {
            throw new Error(`Job not found: ${jobId}`);
        }

        job.priority = newPriority;
        return this.enqueue(job);
    }

    cleanupExpiredJobs() {
        const now = Date.now();
        let expiredCount = 0;

        for (const [priority, queue] of this.queues.entries()) {
            const validJobs = [];
            const expiredJobs = [];

            for (const job of queue) {
                if (job.expiresAt > now) {
                    validJobs.push(job);
                } else {
                    expiredJobs.push(job);
                }
            }

            this.queues.set(priority, validJobs);
            expiredCount += expiredJobs.length;

            expiredJobs.forEach(job => {
                this.logger.warn('Job expired', {
                    jobId: job.id,
                    priority,
                    enqueuedAt: new Date(job.enqueuedAt).toISOString()
                });
                this.emit('job-expired', job);
            });
        }

        if (expiredCount > 0) {
            this.metrics.totalExpired += expiredCount;
            this.logger.info('Expired jobs cleaned up', { count: expiredCount });
        }
    }

    getQueueLength(priority) {
        if (priority) {
            const queue = this.queues.get(priority);
            return queue ? queue.length : 0;
        }

        return Array.from(this.queues.values())
            .reduce((sum, queue) => sum + queue.length, 0);
    }

    getQueueStatistics() {
        const stats = {
            totalLength: 0,
            byPriority: {},
            metrics: {
                totalEnqueued: this.metrics.totalEnqueued,
                totalDequeued: this.metrics.totalDequeued,
                totalExpired: this.metrics.totalExpired,
                averageWaitTime: `${this.metrics.averageWaitTime.toFixed(2)}ms`,
                currentUtilization: 0
            }
        };

        for (const [priority, queue] of this.queues.entries()) {
            const length = queue.length;
            stats.byPriority[priority] = {
                length,
                oldestJob: queue.length > 0 ? {
                    id: queue[0].id,
                    waitTime: Date.now() - queue[0].enqueuedAt
                } : null
            };
            stats.totalLength += length;
        }

        stats.metrics.currentUtilization = 
            `${((stats.totalLength / this.options.maxQueueSize) * 100).toFixed(2)}%`;

        return stats;
    }

    updateAverageWaitTime(waitTime) {
        const totalDequeued = this.metrics.totalDequeued;
        const currentAvg = this.metrics.averageWaitTime;
        
        this.metrics.averageWaitTime = 
            (currentAvg * (totalDequeued - 1) + waitTime) / totalDequeued;
    }

    clear(priority) {
        if (priority) {
            const queue = this.queues.get(priority);
            if (queue) {
                const count = queue.length;
                this.queues.set(priority, []);
                this.logger.info('Queue cleared', { priority, count });
                return count;
            }
            return 0;
        }

        let totalCleared = 0;
        for (const priority of this.options.priorityLevels) {
            totalCleared += this.clear(priority);
        }
        return totalCleared;
    }

    isEmpty() {
        return this.getQueueLength() === 0;
    }

    isFull() {
        return this.getQueueLength() >= this.options.maxQueueSize;
    }
}

module.exports = { JobQueueManager };
