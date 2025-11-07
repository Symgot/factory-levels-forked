class RateLimiter {
    constructor(config = {}) {
        this.config = {
            maxRequestsPerHour: config.maxRequestsPerHour || 5000,
            maxRequestsPerMinute: config.maxRequestsPerMinute || 100,
            maxConcurrentRequests: config.maxConcurrentRequests || 50,
            burstSize: config.burstSize || 20,
            ...config
        };

        this.userLimits = new Map();
        this.ipLimits = new Map();
        this.concurrentRequests = 0;
    }

    async initialize() {
        console.log('Initializing Rate Limiter...');
        this.startCleanup();
        console.log('Rate Limiter initialized successfully');
    }

    async checkLimit(identifier, type = 'user') {
        const limits = type === 'user' ? this.userLimits : this.ipLimits;

        if (!limits.has(identifier)) {
            limits.set(identifier, {
                hourlyRequests: [],
                minuteRequests: [],
                burstRequests: [],
                lastReset: Date.now()
            });
        }

        const limit = limits.get(identifier);
        const now = Date.now();

        limit.hourlyRequests = limit.hourlyRequests.filter(ts => now - ts < 3600000);
        limit.minuteRequests = limit.minuteRequests.filter(ts => now - ts < 60000);
        limit.burstRequests = limit.burstRequests.filter(ts => now - ts < 1000);

        const checks = {
            hourly: limit.hourlyRequests.length < this.config.maxRequestsPerHour,
            minute: limit.minuteRequests.length < this.config.maxRequestsPerMinute,
            burst: limit.burstRequests.length < this.config.burstSize,
            concurrent: this.concurrentRequests < this.config.maxConcurrentRequests
        };

        if (!checks.hourly) {
            return {
                allowed: false,
                reason: 'hourly_limit_exceeded',
                retryAfter: 3600 - Math.floor((now - limit.hourlyRequests[0]) / 1000),
                limits: this.getLimitInfo(limit)
            };
        }

        if (!checks.minute) {
            return {
                allowed: false,
                reason: 'minute_limit_exceeded',
                retryAfter: 60 - Math.floor((now - limit.minuteRequests[0]) / 1000),
                limits: this.getLimitInfo(limit)
            };
        }

        if (!checks.burst) {
            return {
                allowed: false,
                reason: 'burst_limit_exceeded',
                retryAfter: 1,
                limits: this.getLimitInfo(limit)
            };
        }

        if (!checks.concurrent) {
            return {
                allowed: false,
                reason: 'concurrent_limit_exceeded',
                retryAfter: 5,
                limits: this.getLimitInfo(limit)
            };
        }

        limit.hourlyRequests.push(now);
        limit.minuteRequests.push(now);
        limit.burstRequests.push(now);
        this.concurrentRequests++;

        return {
            allowed: true,
            limits: this.getLimitInfo(limit)
        };
    }

    releaseRequest() {
        this.concurrentRequests = Math.max(0, this.concurrentRequests - 1);
    }

    getLimitInfo(limit) {
        return {
            hourlyRemaining: this.config.maxRequestsPerHour - limit.hourlyRequests.length,
            minuteRemaining: this.config.maxRequestsPerMinute - limit.minuteRequests.length,
            burstRemaining: this.config.burstSize - limit.burstRequests.length,
            concurrentRemaining: this.config.maxConcurrentRequests - this.concurrentRequests
        };
    }

    resetLimits(identifier, type = 'user') {
        const limits = type === 'user' ? this.userLimits : this.ipLimits;
        limits.delete(identifier);
        console.log(`Reset limits for ${type} ${identifier}`);
    }

    startCleanup() {
        this.cleanupInterval = setInterval(() => {
            this.cleanupExpiredLimits();
        }, 300000);

        console.log('Rate limit cleanup task started');
    }

    cleanupExpiredLimits() {
        const now = Date.now();
        let cleanedUser = 0;
        let cleanedIp = 0;

        for (const [identifier, limit] of this.userLimits.entries()) {
            if (limit.hourlyRequests.length === 0 && now - limit.lastReset > 3600000) {
                this.userLimits.delete(identifier);
                cleanedUser++;
            }
        }

        for (const [identifier, limit] of this.ipLimits.entries()) {
            if (limit.hourlyRequests.length === 0 && now - limit.lastReset > 3600000) {
                this.ipLimits.delete(identifier);
                cleanedIp++;
            }
        }

        if (cleanedUser > 0 || cleanedIp > 0) {
            console.log(`Cleaned up ${cleanedUser} user limits and ${cleanedIp} IP limits`);
        }
    }

    async shutdown() {
        console.log('Shutting down Rate Limiter...');

        if (this.cleanupInterval) {
            clearInterval(this.cleanupInterval);
        }

        console.log('Rate Limiter shutdown complete');
    }

    getMetrics() {
        return {
            trackedUsers: this.userLimits.size,
            trackedIPs: this.ipLimits.size,
            concurrentRequests: this.concurrentRequests,
            maxConcurrentRequests: this.config.maxConcurrentRequests,
            utilizationPercent: Math.round((this.concurrentRequests / this.config.maxConcurrentRequests) * 100)
        };
    }
}

function checkRateLimit(req, res, next) {
    const rateLimiter = req.app.locals.rateLimiter;
    const identifier = req.user ? req.user.id : req.ip;
    const type = req.user ? 'user' : 'ip';

    rateLimiter.checkLimit(identifier, type).then(result => {
        res.setHeader('X-RateLimit-Remaining-Hourly', result.limits.hourlyRemaining);
        res.setHeader('X-RateLimit-Remaining-Minute', result.limits.minuteRemaining);
        res.setHeader('X-RateLimit-Remaining-Concurrent', result.limits.concurrentRemaining);

        if (!result.allowed) {
            res.setHeader('Retry-After', result.retryAfter);

            return res.status(429).json({
                error: 'Too Many Requests',
                message: `Rate limit exceeded: ${result.reason}`,
                retryAfter: result.retryAfter,
                limits: result.limits,
                code: 'RATE_LIMIT_EXCEEDED'
            });
        }

        res.on('finish', () => {
            rateLimiter.releaseRequest();
        });

        next();
    }).catch(error => {
        console.error('Rate limit check error:', error);
        next();
    });
}

const rateLimiter = new RateLimiter();

module.exports = {
    RateLimiter,
    checkRateLimit,
    initializeRateLimiter: (config) => rateLimiter.initialize(config),
    checkUserLimit: (identifier, type) => rateLimiter.checkLimit(identifier, type),
    releaseRequest: () => rateLimiter.releaseRequest(),
    resetLimits: (identifier, type) => rateLimiter.resetLimits(identifier, type),
    getRateLimiterMetrics: () => rateLimiter.getMetrics(),
    shutdownRateLimiter: () => rateLimiter.shutdown()
};
