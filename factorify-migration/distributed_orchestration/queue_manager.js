const EventEmitter = require('events');

class QueueManager extends EventEmitter {
    constructor(config = {}) {
        super();

        this.config = {
            maxQueueSize: config.maxQueueSize || 1000,
            maxWaitTime: config.maxWaitTime || 300000,
            cleanupInterval: config.cleanupInterval || 60000,
            persistToRedis: config.persistToRedis || false,
            redisClient: config.redisClient || null,
            ...config
        };

        this.queues = {
            critical: [],
            high: [],
            normal: [],
            low: []
        };

        this.jobs = new Map();
        this.metrics = {
            enqueued: 0,
            dequeued: 0,
            expired: 0,
            totalWaitTime: 0
        };

        this.isRunning = false;
    }

    async initialize() {
        console.log('Initializing Queue Manager...');
        this.isRunning = true;
        this.startCleanup();

        if (this.config.persistToRedis && this.config.redisClient) {
            await this.loadFromRedis();
        }

        console.log('Queue Manager initialized successfully');
    }

    async enqueueJob(jobConfig) {
        const { id, type, priority = 'normal', data, expiresIn } = jobConfig;

        if (!id || !type) {
            throw new Error('Job id and type are required');
        }

        const totalSize = Object.values(this.queues).reduce((sum, q) => sum + q.length, 0);

        if (totalSize >= this.config.maxQueueSize) {
            throw new Error(`Queue at capacity (${this.config.maxQueueSize} jobs)`);
        }

        const job = {
            id,
            type,
            priority,
            data,
            enqueuedAt: Date.now(),
            expiresAt: expiresIn ? Date.now() + expiresIn : Date.now() + this.config.maxWaitTime,
            retryCount: jobConfig.retryCount || 0
        };

        const queue = this.queues[priority] || this.queues.normal;
        queue.push(job);

        this.jobs.set(id, job);
        this.metrics.enqueued++;

        if (this.config.persistToRedis && this.config.redisClient) {
            await this.saveToRedis(job);
        }

        console.log(`Job ${id} enqueued with ${priority} priority (queue size: ${queue.length})`);
        this.emit('job:enqueued', { jobId: id, priority, queueSize: queue.length });

        return job;
    }

    async dequeueJob(capability = null) {
        const priorities = ['critical', 'high', 'normal', 'low'];

        for (const priority of priorities) {
            const queue = this.queues[priority];

            if (queue.length === 0) {
                continue;
            }

            let jobIndex = 0;

            if (capability) {
                jobIndex = queue.findIndex(job => {
                    return !capability || job.type === capability || (job.data && job.data.capabilities && job.data.capabilities.includes(capability));
                });

                if (jobIndex === -1) {
                    continue;
                }
            }

            const job = queue.splice(jobIndex, 1)[0];

            const waitTime = Date.now() - job.enqueuedAt;
            this.metrics.dequeued++;
            this.metrics.totalWaitTime += waitTime;

            if (this.config.persistToRedis && this.config.redisClient) {
                await this.removeFromRedis(job.id);
            }

            console.log(`Job ${job.id} dequeued after ${waitTime}ms (${priority} priority)`);
            this.emit('job:dequeued', { jobId: job.id, priority, waitTime });

            return job;
        }

        return null;
    }

    async removeJob(jobId) {
        const job = this.jobs.get(jobId);

        if (!job) {
            return false;
        }

        const queue = this.queues[job.priority];
        const index = queue.findIndex(j => j.id === jobId);

        if (index !== -1) {
            queue.splice(index, 1);
        }

        this.jobs.delete(jobId);

        if (this.config.persistToRedis && this.config.redisClient) {
            await this.removeFromRedis(jobId);
        }

        console.log(`Job ${jobId} removed from queue`);
        this.emit('job:removed', { jobId });

        return true;
    }

    async changePriority(jobId, newPriority) {
        const job = this.jobs.get(jobId);

        if (!job) {
            throw new Error(`Job ${jobId} not found`);
        }

        if (job.priority === newPriority) {
            return job;
        }

        const oldQueue = this.queues[job.priority];
        const index = oldQueue.findIndex(j => j.id === jobId);

        if (index !== -1) {
            oldQueue.splice(index, 1);
        }

        job.priority = newPriority;
        this.queues[newPriority].push(job);

        if (this.config.persistToRedis && this.config.redisClient) {
            await this.saveToRedis(job);
        }

        console.log(`Job ${jobId} priority changed to ${newPriority}`);
        this.emit('job:priority_changed', { jobId, oldPriority: job.priority, newPriority });

        return job;
    }

    getJob(jobId) {
        return this.jobs.get(jobId);
    }

    getJobsByType(type) {
        return Array.from(this.jobs.values()).filter(job => job.type === type);
    }

    startCleanup() {
        this.cleanupInterval = setInterval(() => {
            this.cleanupExpiredJobs();
        }, this.config.cleanupInterval);

        console.log('Cleanup task started');
    }

    cleanupExpiredJobs() {
        const now = Date.now();
        let expiredCount = 0;

        for (const priority of Object.keys(this.queues)) {
            const queue = this.queues[priority];

            for (let i = queue.length - 1; i >= 0; i--) {
                const job = queue[i];

                if (job.expiresAt && job.expiresAt < now) {
                    queue.splice(i, 1);
                    this.jobs.delete(job.id);
                    expiredCount++;

                    console.log(`Job ${job.id} expired after ${now - job.enqueuedAt}ms`);
                    this.emit('job:expired', {
                        jobId: job.id,
                        priority: job.priority,
                        age: now - job.enqueuedAt
                    });
                }
            }
        }

        if (expiredCount > 0) {
            this.metrics.expired += expiredCount;
            console.log(`Cleaned up ${expiredCount} expired jobs`);
        }
    }

    async saveToRedis(job) {
        if (!this.config.redisClient) {
            return;
        }

        try {
            const key = `factorify:queue:${job.priority}:${job.id}`;
            await this.config.redisClient.set(key, JSON.stringify(job));
            await this.config.redisClient.expire(key, Math.ceil(this.config.maxWaitTime / 1000));
        } catch (error) {
            console.error('Redis save error:', error.message);
        }
    }

    async removeFromRedis(jobId) {
        if (!this.config.redisClient) {
            return;
        }

        try {
            const priorities = ['critical', 'high', 'normal', 'low'];

            for (const priority of priorities) {
                const key = `factorify:queue:${priority}:${jobId}`;
                await this.config.redisClient.del(key);
            }
        } catch (error) {
            console.error('Redis remove error:', error.message);
        }
    }

    async loadFromRedis() {
        if (!this.config.redisClient) {
            return;
        }

        try {
            console.log('Loading queue from Redis...');

            const priorities = ['critical', 'high', 'normal', 'low'];
            let loadedCount = 0;

            for (const priority of priorities) {
                const pattern = `factorify:queue:${priority}:*`;
                const keys = await this.config.redisClient.keys(pattern);

                for (const key of keys) {
                    const jobData = await this.config.redisClient.get(key);

                    if (jobData) {
                        const job = JSON.parse(jobData);
                        this.queues[priority].push(job);
                        this.jobs.set(job.id, job);
                        loadedCount++;
                    }
                }
            }

            console.log(`Loaded ${loadedCount} jobs from Redis`);
        } catch (error) {
            console.error('Redis load error:', error.message);
        }
    }

    async shutdown() {
        console.log('Shutting down Queue Manager...');
        this.isRunning = false;

        if (this.cleanupInterval) {
            clearInterval(this.cleanupInterval);
        }

        if (this.config.persistToRedis && this.config.redisClient) {
            console.log('Persisting queue state to Redis...');

            for (const [id, job] of this.jobs.entries()) {
                await this.saveToRedis(job);
            }
        }

        console.log('Queue Manager shutdown complete');
    }

    getMetrics() {
        const totalSize = Object.values(this.queues).reduce((sum, q) => sum + q.length, 0);
        const avgWaitTime = this.metrics.dequeued > 0
            ? Math.round(this.metrics.totalWaitTime / this.metrics.dequeued)
            : 0;

        return {
            queueSize: totalSize,
            queuesByPriority: {
                critical: this.queues.critical.length,
                high: this.queues.high.length,
                normal: this.queues.normal.length,
                low: this.queues.low.length
            },
            enqueued: this.metrics.enqueued,
            dequeued: this.metrics.dequeued,
            expired: this.metrics.expired,
            averageWaitTime: avgWaitTime,
            oldestJob: this.getOldestJob(),
            timestamp: new Date().toISOString()
        };
    }

    getOldestJob() {
        let oldest = null;

        for (const queue of Object.values(this.queues)) {
            for (const job of queue) {
                if (!oldest || job.enqueuedAt < oldest.enqueuedAt) {
                    oldest = job;
                }
            }
        }

        return oldest ? {
            id: oldest.id,
            age: Date.now() - oldest.enqueuedAt,
            priority: oldest.priority
        } : null;
    }
}

const queueManager = new QueueManager();

module.exports = {
    QueueManager,
    enqueueJob: (config) => queueManager.enqueueJob(config),
    dequeueJob: (capability) => queueManager.dequeueJob(capability),
    removeJob: (jobId) => queueManager.removeJob(jobId),
    changePriority: (jobId, newPriority) => queueManager.changePriority(jobId, newPriority),
    getJob: (jobId) => queueManager.getJob(jobId),
    getJobsByType: (type) => queueManager.getJobsByType(type),
    getQueueMetrics: () => queueManager.getMetrics(),
    initializeQueue: (config) => queueManager.initialize(config),
    shutdownQueue: () => queueManager.shutdown()
};
