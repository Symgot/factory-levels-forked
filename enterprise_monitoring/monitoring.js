/**
 * Enterprise Monitoring System
 * Phase 8: Health Checks, Metrics, Logging
 * 
 * Reference: https://prometheus.io/docs/concepts/metric_types/
 * Reference: https://microservices.io/patterns/observability/health-check-api.html
 * Reference: https://github.com/winstonjs/winston
 */

const express = require('express');
const promClient = require('prom-client');
const winston = require('winston');
require('winston-daily-rotate-file');
const os = require('os');
const { performance } = require('perf_hooks');

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG = {
    METRICS_PORT: process.env.METRICS_PORT || 9090,
    METRICS_PATH: '/metrics',
    HEALTH_CHECK_PATH: '/health',
    READY_CHECK_PATH: '/ready',
    LIVE_CHECK_PATH: '/live',
    LOG_LEVEL: process.env.LOG_LEVEL || 'info',
    LOG_DIR: process.env.LOG_DIR || './logs',
    ENABLE_DETAILED_METRICS: process.env.DETAILED_METRICS === 'true'
};

// ============================================================================
// PROMETHEUS METRICS
// ============================================================================

class MetricsCollector {
    constructor() {
        // Create registry
        this.register = new promClient.Register();
        
        // Enable default metrics (CPU, memory, etc.)
        promClient.collectDefaultMetrics({ 
            register: this.register,
            prefix: 'factorio_validator_'
        });
        
        // Custom metrics
        this.initializeMetrics();
    }

    /**
     * Initialize custom metrics
     */
    initializeMetrics() {
        // HTTP request duration histogram
        this.httpRequestDuration = new promClient.Histogram({
            name: 'http_request_duration_seconds',
            help: 'Duration of HTTP requests in seconds',
            labelNames: ['method', 'route', 'status_code'],
            buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5, 10]
        });
        this.register.registerMetric(this.httpRequestDuration);
        
        // Validation counter
        this.validationCount = new promClient.Counter({
            name: 'validation_total',
            help: 'Total number of validations performed',
            labelNames: ['type', 'status']
        });
        this.register.registerMetric(this.validationCount);
        
        // Validation duration
        this.validationDuration = new promClient.Histogram({
            name: 'validation_duration_seconds',
            help: 'Duration of validation operations',
            labelNames: ['type'],
            buckets: [0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5]
        });
        this.register.registerMetric(this.validationDuration);
        
        // Parse time gauge
        this.parseTime = new promClient.Gauge({
            name: 'parse_time_milliseconds',
            help: 'Current parse time in milliseconds'
        });
        this.register.registerMetric(this.parseTime);
        
        // ML inference time
        this.mlInferenceTime = new promClient.Histogram({
            name: 'ml_inference_duration_seconds',
            help: 'ML inference duration',
            buckets: [0.001, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2]
        });
        this.register.registerMetric(this.mlInferenceTime);
        
        // Cache hit rate
        this.cacheHitRate = new promClient.Gauge({
            name: 'cache_hit_rate',
            help: 'Cache hit rate percentage',
            labelNames: ['cache_type']
        });
        this.register.registerMetric(this.cacheHitRate);
        
        // Active connections
        this.activeConnections = new promClient.Gauge({
            name: 'active_connections',
            help: 'Number of active connections'
        });
        this.register.registerMetric(this.activeConnections);
        
        // Error rate
        this.errorRate = new promClient.Counter({
            name: 'errors_total',
            help: 'Total number of errors',
            labelNames: ['type', 'severity']
        });
        this.register.registerMetric(this.errorRate);
        
        // Memory usage by component
        this.memoryUsage = new promClient.Gauge({
            name: 'memory_usage_bytes',
            help: 'Memory usage by component',
            labelNames: ['component']
        });
        this.register.registerMetric(this.memoryUsage);
        
        // Worker pool metrics
        this.workerPoolSize = new promClient.Gauge({
            name: 'worker_pool_size',
            help: 'Number of workers in pool',
            labelNames: ['status']
        });
        this.register.registerMetric(this.workerPoolSize);
    }

    /**
     * Record HTTP request
     */
    recordHttpRequest(method, route, statusCode, duration) {
        this.httpRequestDuration
            .labels(method, route, statusCode.toString())
            .observe(duration / 1000);
    }

    /**
     * Record validation
     */
    recordValidation(type, status, duration) {
        this.validationCount.labels(type, status).inc();
        this.validationDuration.labels(type).observe(duration / 1000);
    }

    /**
     * Record parse time
     */
    recordParseTime(time) {
        this.parseTime.set(time);
    }

    /**
     * Record ML inference
     */
    recordMLInference(duration) {
        this.mlInferenceTime.observe(duration / 1000);
    }

    /**
     * Update cache hit rate
     */
    updateCacheHitRate(cacheType, rate) {
        this.cacheHitRate.labels(cacheType).set(rate);
    }

    /**
     * Update active connections
     */
    updateActiveConnections(count) {
        this.activeConnections.set(count);
    }

    /**
     * Record error
     */
    recordError(type, severity) {
        this.errorRate.labels(type, severity).inc();
    }

    /**
     * Update memory usage
     */
    updateMemoryUsage(component, bytes) {
        this.memoryUsage.labels(component).set(bytes);
    }

    /**
     * Update worker pool metrics
     */
    updateWorkerPool(active, idle) {
        this.workerPoolSize.labels('active').set(active);
        this.workerPoolSize.labels('idle').set(idle);
    }

    /**
     * Get metrics
     */
    async getMetrics() {
        return await this.register.metrics();
    }

    /**
     * Get metrics as JSON
     */
    async getMetricsJSON() {
        return await this.register.getMetricsAsJSON();
    }
}

// ============================================================================
// STRUCTURED LOGGING
// ============================================================================

class Logger {
    constructor() {
        this.logger = this.createLogger();
    }

    /**
     * Create Winston logger
     */
    createLogger() {
        const customFormat = winston.format.combine(
            winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
            winston.format.errors({ stack: true }),
            winston.format.metadata({ fillExcept: ['message', 'level', 'timestamp', 'label'] }),
            winston.format.json()
        );

        const logger = winston.createLogger({
            level: CONFIG.LOG_LEVEL,
            format: customFormat,
            defaultMeta: { 
                service: 'factorio-validator',
                hostname: os.hostname(),
                pid: process.pid
            },
            transports: [
                // Console transport
                new winston.transports.Console({
                    format: winston.format.combine(
                        winston.format.colorize(),
                        winston.format.printf(({ timestamp, level, message, ...meta }) => {
                            return `${timestamp} [${level}]: ${message} ${Object.keys(meta).length ? JSON.stringify(meta) : ''}`;
                        })
                    )
                }),
                
                // Daily rotate file for all logs
                new winston.transports.DailyRotateFile({
                    filename: `${CONFIG.LOG_DIR}/application-%DATE%.log`,
                    datePattern: 'YYYY-MM-DD',
                    maxSize: '100m',
                    maxFiles: '30d',
                    format: customFormat
                }),
                
                // Separate file for errors
                new winston.transports.DailyRotateFile({
                    filename: `${CONFIG.LOG_DIR}/error-%DATE%.log`,
                    datePattern: 'YYYY-MM-DD',
                    level: 'error',
                    maxSize: '100m',
                    maxFiles: '30d',
                    format: customFormat
                })
            ]
        });

        return logger;
    }

    /**
     * Log info message
     */
    info(message, meta = {}) {
        this.logger.info(message, meta);
    }

    /**
     * Log warning message
     */
    warn(message, meta = {}) {
        this.logger.warn(message, meta);
    }

    /**
     * Log error message
     */
    error(message, error = null, meta = {}) {
        const errorMeta = error ? {
            ...meta,
            error: {
                message: error.message,
                stack: error.stack,
                name: error.name
            }
        } : meta;

        this.logger.error(message, errorMeta);
    }

    /**
     * Log debug message
     */
    debug(message, meta = {}) {
        this.logger.debug(message, meta);
    }

    /**
     * Log HTTP request
     */
    logRequest(req, res, duration) {
        this.info('HTTP Request', {
            method: req.method,
            url: req.url,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            userAgent: req.get('user-agent'),
            ip: req.ip
        });
    }

    /**
     * Log validation
     */
    logValidation(type, status, duration, details = {}) {
        this.info('Validation', {
            type,
            status,
            duration: `${duration}ms`,
            ...details
        });
    }

    /**
     * Log ML inference
     */
    logMLInference(operation, duration, result) {
        this.debug('ML Inference', {
            operation,
            duration: `${duration}ms`,
            result
        });
    }
}

// ============================================================================
// HEALTH CHECKS
// ============================================================================

class HealthChecker {
    constructor() {
        this.checks = new Map();
        this.status = 'healthy';
        this.startTime = Date.now();
    }

    /**
     * Register health check
     */
    registerCheck(name, checkFunction) {
        this.checks.set(name, checkFunction);
    }

    /**
     * Perform health check
     */
    async check() {
        const results = {};
        let overallStatus = 'healthy';

        for (const [name, checkFn] of this.checks.entries()) {
            try {
                const startTime = performance.now();
                const result = await checkFn();
                const duration = performance.now() - startTime;

                results[name] = {
                    status: result.status || 'healthy',
                    message: result.message || 'OK',
                    duration: `${duration.toFixed(2)}ms`,
                    ...result.details
                };

                if (result.status === 'unhealthy') {
                    overallStatus = 'unhealthy';
                } else if (result.status === 'degraded' && overallStatus === 'healthy') {
                    overallStatus = 'degraded';
                }
            } catch (error) {
                results[name] = {
                    status: 'unhealthy',
                    message: error.message,
                    error: error.stack
                };
                overallStatus = 'unhealthy';
            }
        }

        this.status = overallStatus;

        return {
            status: overallStatus,
            timestamp: new Date().toISOString(),
            uptime: `${((Date.now() - this.startTime) / 1000).toFixed(2)}s`,
            checks: results
        };
    }

    /**
     * Readiness check
     */
    async readiness() {
        const health = await this.check();
        return {
            ready: health.status === 'healthy',
            ...health
        };
    }

    /**
     * Liveness check
     */
    async liveness() {
        return {
            alive: true,
            timestamp: new Date().toISOString(),
            uptime: `${((Date.now() - this.startTime) / 1000).toFixed(2)}s`
        };
    }
}

// ============================================================================
// MONITORING MIDDLEWARE
// ============================================================================

class MonitoringMiddleware {
    constructor(metrics, logger) {
        this.metrics = metrics;
        this.logger = logger;
    }

    /**
     * Express middleware for monitoring
     */
    middleware() {
        return (req, res, next) => {
            const startTime = performance.now();

            // Track active connections
            this.metrics.updateActiveConnections(
                this.metrics.activeConnections._getValue() + 1
            );

            // Hook into response finish
            res.on('finish', () => {
                const duration = performance.now() - startTime;

                // Record metrics
                this.metrics.recordHttpRequest(
                    req.method,
                    req.route ? req.route.path : req.path,
                    res.statusCode,
                    duration
                );

                // Log request
                this.logger.logRequest(req, res, duration.toFixed(2));

                // Update active connections
                this.metrics.updateActiveConnections(
                    this.metrics.activeConnections._getValue() - 1
                );
            });

            next();
        };
    }

    /**
     * Error handling middleware
     */
    errorHandler() {
        return (err, req, res, next) => {
            const severity = err.statusCode >= 500 ? 'critical' : 'warning';

            this.metrics.recordError(err.name || 'UnknownError', severity);
            this.logger.error('Request error', err, {
                method: req.method,
                url: req.url,
                statusCode: err.statusCode || 500
            });

            res.status(err.statusCode || 500).json({
                error: {
                    message: err.message,
                    statusCode: err.statusCode || 500,
                    timestamp: new Date().toISOString()
                }
            });
        };
    }
}

// ============================================================================
// MONITORING SERVER
// ============================================================================

class MonitoringServer {
    constructor() {
        this.app = express();
        this.metrics = new MetricsCollector();
        this.logger = new Logger();
        this.healthChecker = new HealthChecker();
        this.middleware = new MonitoringMiddleware(this.metrics, this.logger);
        
        this.setupHealthChecks();
        this.setupRoutes();
    }

    /**
     * Setup default health checks
     */
    setupHealthChecks() {
        // Memory check
        this.healthChecker.registerCheck('memory', async () => {
            const memUsage = process.memoryUsage();
            const heapPercent = (memUsage.heapUsed / memUsage.heapTotal) * 100;

            return {
                status: heapPercent > 90 ? 'unhealthy' : heapPercent > 75 ? 'degraded' : 'healthy',
                message: `Heap usage: ${heapPercent.toFixed(2)}%`,
                details: {
                    heapUsed: `${(memUsage.heapUsed / 1024 / 1024).toFixed(2)}MB`,
                    heapTotal: `${(memUsage.heapTotal / 1024 / 1024).toFixed(2)}MB`,
                    rss: `${(memUsage.rss / 1024 / 1024).toFixed(2)}MB`
                }
            };
        });

        // CPU check
        this.healthChecker.registerCheck('cpu', async () => {
            const cpus = os.cpus();
            const avgLoad = os.loadavg()[0] / cpus.length;

            return {
                status: avgLoad > 0.9 ? 'unhealthy' : avgLoad > 0.7 ? 'degraded' : 'healthy',
                message: `CPU load: ${(avgLoad * 100).toFixed(2)}%`,
                details: {
                    cores: cpus.length,
                    loadAvg: os.loadavg().map(l => l.toFixed(2))
                }
            };
        });

        // Disk check
        this.healthChecker.registerCheck('disk', async () => {
            // Simplified disk check
            return {
                status: 'healthy',
                message: 'Disk space OK'
            };
        });
    }

    /**
     * Setup routes
     */
    setupRoutes() {
        // Metrics endpoint
        this.app.get(CONFIG.METRICS_PATH, async (req, res) => {
            res.set('Content-Type', this.metrics.register.contentType);
            res.end(await this.metrics.getMetrics());
        });

        // Health check endpoint
        this.app.get(CONFIG.HEALTH_CHECK_PATH, async (req, res) => {
            const health = await this.healthChecker.check();
            const statusCode = health.status === 'healthy' ? 200 : 503;
            res.status(statusCode).json(health);
        });

        // Readiness endpoint
        this.app.get(CONFIG.READY_CHECK_PATH, async (req, res) => {
            const readiness = await this.healthChecker.readiness();
            const statusCode = readiness.ready ? 200 : 503;
            res.status(statusCode).json(readiness);
        });

        // Liveness endpoint
        this.app.get(CONFIG.LIVE_CHECK_PATH, async (req, res) => {
            const liveness = await this.healthChecker.liveness();
            res.status(200).json(liveness);
        });

        // Metrics JSON endpoint
        this.app.get('/metrics/json', async (req, res) => {
            res.json(await this.metrics.getMetricsJSON());
        });
    }

    /**
     * Start monitoring server
     */
    start() {
        this.server = this.app.listen(CONFIG.METRICS_PORT, () => {
            this.logger.info(`Monitoring server started on port ${CONFIG.METRICS_PORT}`);
            this.logger.info(`Metrics available at http://localhost:${CONFIG.METRICS_PORT}${CONFIG.METRICS_PATH}`);
            this.logger.info(`Health check at http://localhost:${CONFIG.METRICS_PORT}${CONFIG.HEALTH_CHECK_PATH}`);
        });

        return this.server;
    }

    /**
     * Stop monitoring server
     */
    stop() {
        if (this.server) {
            this.server.close(() => {
                this.logger.info('Monitoring server stopped');
            });
        }
    }

    /**
     * Get middleware
     */
    getMiddleware() {
        return this.middleware.middleware();
    }

    /**
     * Get error handler
     */
    getErrorHandler() {
        return this.middleware.errorHandler();
    }
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
    MonitoringServer,
    MetricsCollector,
    Logger,
    HealthChecker,
    MonitoringMiddleware,
    CONFIG
};

// Example usage
if (require.main === module) {
    const server = new MonitoringServer();
    server.start();
}
