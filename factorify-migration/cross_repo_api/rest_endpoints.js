const express = require('express');
const router = express.Router();
const axios = require('axios');
const { validateToken, checkRateLimit } = require('../authentication/token_manager');
const { enqueueJob } = require('../distributed_orchestration/queue_manager');
const MLEngine = require('../../ml_pattern_recognition/ml_engine');
const PerformanceOptimizer = require('../../performance_optimizer/performance_optimizer');
const ObfuscationAnalyzer = require('../../advanced_obfuscation/obfuscation_analyzer');

const mlEngine = new MLEngine();
const performanceOptimizer = new PerformanceOptimizer();
const obfuscationAnalyzer = new ObfuscationAnalyzer();

router.post('/api/v1/analyze/mod', validateToken, checkRateLimit, async (req, res) => {
    try {
        const { repository, url, type, options = {} } = req.body;

        if (!repository && !url) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Either repository or url must be provided',
                code: 'MISSING_SOURCE'
            });
        }

        const jobId = `job_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        const analysisConfig = {
            type: type || 'full',
            ml: options.ml !== false,
            performance: options.performance !== false,
            obfuscation: options.obfuscation !== false,
            timeout: options.timeout || 300000
        };

        await enqueueJob({
            id: jobId,
            type: 'mod_analysis',
            priority: options.priority || 'normal',
            data: {
                repository,
                url,
                config: analysisConfig,
                requestedBy: req.user.login,
                requestedAt: new Date().toISOString()
            }
        });

        res.status(202).json({
            jobId,
            status: 'queued',
            estimatedTime: '2-5 minutes',
            statusUrl: `/api/v1/status/${jobId}`,
            message: 'Analysis job queued successfully'
        });

    } catch (error) {
        console.error('Mod analysis error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error.message,
            code: 'ANALYSIS_ERROR'
        });
    }
});

router.get('/api/v1/status/:jobId', validateToken, checkRateLimit, async (req, res) => {
    try {
        const { jobId } = req.params;
        
        const job = await getJobStatus(jobId);
        
        if (!job) {
            return res.status(404).json({
                error: 'Not Found',
                message: `Job ${jobId} not found`,
                code: 'JOB_NOT_FOUND'
            });
        }

        const response = {
            jobId: job.id,
            status: job.status,
            progress: job.progress || 0,
            createdAt: job.createdAt,
            updatedAt: job.updatedAt
        };

        if (job.status === 'completed') {
            response.result = job.result;
            response.completedAt = job.completedAt;
        } else if (job.status === 'failed') {
            response.error = job.error;
            response.failedAt = job.failedAt;
        } else if (job.status === 'running') {
            response.estimatedTimeRemaining = job.estimatedTimeRemaining;
        }

        res.json(response);

    } catch (error) {
        console.error('Status check error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error.message,
            code: 'STATUS_ERROR'
        });
    }
});

router.post('/api/v1/ml/predict', validateToken, checkRateLimit, async (req, res) => {
    try {
        const { code, modelType = 'pattern_recognition' } = req.body;

        if (!code) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Code content is required',
                code: 'MISSING_CODE'
            });
        }

        await mlEngine.initialize();

        let result;
        const startTime = Date.now();

        switch (modelType) {
            case 'pattern_recognition':
                result = await mlEngine.analyzeLuaCode(code);
                break;
            case 'anomaly_detection':
                result = await mlEngine.detectAnomalies(code);
                break;
            case 'quality_prediction':
                result = await mlEngine.predictQuality(code);
                break;
            default:
                return res.status(400).json({
                    error: 'Bad Request',
                    message: `Unknown model type: ${modelType}`,
                    code: 'INVALID_MODEL'
                });
        }

        const inferenceTime = Date.now() - startTime;

        res.json({
            modelType,
            result,
            inferenceTime,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('ML prediction error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error.message,
            code: 'PREDICTION_ERROR'
        });
    }
});

router.post('/api/v1/performance/benchmark', validateToken, checkRateLimit, async (req, res) => {
    try {
        const { code, benchmarkType = 'parse', iterations = 100 } = req.body;

        if (!code) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Code content is required',
                code: 'MISSING_CODE'
            });
        }

        if (iterations > 1000) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Maximum 1000 iterations allowed',
                code: 'TOO_MANY_ITERATIONS'
            });
        }

        await performanceOptimizer.initialize();

        const result = await performanceOptimizer.benchmark({
            code,
            type: benchmarkType,
            iterations
        });

        res.json({
            benchmarkType,
            iterations,
            result: {
                mean: result.mean,
                median: result.median,
                p95: result.p95,
                p99: result.p99,
                min: result.min,
                max: result.max,
                stdDev: result.stdDev
            },
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Performance benchmark error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error.message,
            code: 'BENCHMARK_ERROR'
        });
    }
});

router.post('/api/v1/obfuscation/detect', validateToken, checkRateLimit, async (req, res) => {
    try {
        const { code, detailed = false } = req.body;

        if (!code) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Code content is required',
                code: 'MISSING_CODE'
            });
        }

        await obfuscationAnalyzer.initialize();

        const result = await obfuscationAnalyzer.analyze(code, { detailed });

        res.json({
            obfuscationScore: result.score,
            isObfuscated: result.score > 45,
            confidence: result.confidence,
            techniques: result.techniques,
            ...(detailed && {
                cfgMetrics: result.cfgMetrics,
                entropyAnalysis: result.entropyAnalysis,
                stringPatterns: result.stringPatterns
            }),
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Obfuscation detection error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error.message,
            code: 'DETECTION_ERROR'
        });
    }
});

router.get('/api/v1/health', async (req, res) => {
    try {
        const health = {
            status: 'healthy',
            timestamp: new Date().toISOString(),
            version: '1.0.0',
            services: {
                ml: await checkMLHealth(),
                performance: await checkPerformanceHealth(),
                obfuscation: await checkObfuscationHealth(),
                queue: await checkQueueHealth()
            },
            uptime: process.uptime(),
            memory: process.memoryUsage()
        };

        const allHealthy = Object.values(health.services).every(s => s.status === 'healthy');
        res.status(allHealthy ? 200 : 503).json(health);

    } catch (error) {
        console.error('Health check error:', error);
        res.status(503).json({
            status: 'unhealthy',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

router.post('/api/v1/workflow/trigger', validateToken, checkRateLimit, async (req, res) => {
    try {
        const { workflow, ref = 'main', inputs = {}, targetRepo } = req.body;

        if (!workflow) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Workflow name is required',
                code: 'MISSING_WORKFLOW'
            });
        }

        const workflowId = `workflow_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        await enqueueJob({
            id: workflowId,
            type: 'workflow_trigger',
            priority: inputs.priority || 'normal',
            data: {
                workflow,
                ref,
                inputs,
                targetRepo: targetRepo || req.body.repository,
                requestedBy: req.user.login,
                requestedAt: new Date().toISOString()
            }
        });

        res.status(202).json({
            workflowId,
            status: 'queued',
            statusUrl: `/api/v1/status/${workflowId}`,
            message: 'Workflow trigger queued successfully'
        });

    } catch (error) {
        console.error('Workflow trigger error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error.message,
            code: 'WORKFLOW_ERROR'
        });
    }
});

async function getJobStatus(jobId) {
    const { getJob } = require('../distributed_orchestration/queue_manager');
    return await getJob(jobId);
}

async function checkMLHealth() {
    try {
        await mlEngine.initialize();
        return { status: 'healthy', latency: 0 };
    } catch (error) {
        return { status: 'unhealthy', error: error.message };
    }
}

async function checkPerformanceHealth() {
    try {
        await performanceOptimizer.initialize();
        return { status: 'healthy', latency: 0 };
    } catch (error) {
        return { status: 'unhealthy', error: error.message };
    }
}

async function checkObfuscationHealth() {
    try {
        await obfuscationAnalyzer.initialize();
        return { status: 'healthy', latency: 0 };
    } catch (error) {
        return { status: 'unhealthy', error: error.message };
    }
}

async function checkQueueHealth() {
    try {
        const { getQueueMetrics } = require('../distributed_orchestration/queue_manager');
        const metrics = await getQueueMetrics();
        return {
            status: metrics.queueSize < 500 ? 'healthy' : 'degraded',
            pendingJobs: metrics.queueSize
        };
    } catch (error) {
        return { status: 'unhealthy', pendingJobs: 0, error: error.message };
    }
}

module.exports = router;
