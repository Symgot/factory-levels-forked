/**
 * Phase 8 Integration Module for Backend API
 * Integrates ML, Performance, Obfuscation, and Monitoring
 * 
 * This module extends the Phase 7 backend with Phase 8 features
 */

const path = require('path');

// Phase 8 imports
const { MLEngine } = require('../ml_pattern_recognition/ml_engine');
const { PerformanceEngine } = require('../performance_optimizer/performance_engine');
const { ObfuscationAnalyzer } = require('../advanced_obfuscation/obfuscation_analyzer');
const { MonitoringServer } = require('../enterprise_monitoring/monitoring');

// ============================================================================
// PHASE 8 INTEGRATION CLASS
// ============================================================================

class Phase8Integration {
    constructor() {
        this.mlEngine = null;
        this.performanceEngine = null;
        this.obfuscationAnalyzer = null;
        this.monitoring = null;
        this.initialized = false;
    }

    /**
     * Initialize all Phase 8 components
     */
    async initialize() {
        console.log('Initializing Phase 8 components...');

        try {
            // Initialize ML Engine
            this.mlEngine = new MLEngine();
            await this.mlEngine.initialize();
            console.log('✓ ML Engine initialized');

            // Initialize Performance Engine
            this.performanceEngine = new PerformanceEngine();
            await this.performanceEngine.initialize();
            console.log('✓ Performance Engine initialized');

            // Initialize Obfuscation Analyzer
            this.obfuscationAnalyzer = new ObfuscationAnalyzer();
            console.log('✓ Obfuscation Analyzer initialized');

            // Initialize Monitoring
            this.monitoring = new MonitoringServer();
            this.monitoring.start();
            console.log('✓ Monitoring Server started');

            this.initialized = true;
            console.log('Phase 8 Integration complete');

            return true;
        } catch (error) {
            console.error('Phase 8 initialization error:', error);
            throw error;
        }
    }

    /**
     * Enhanced validation with ML, performance, and obfuscation analysis
     */
    async enhancedValidation(source, ast, options = {}) {
        if (!this.initialized) {
            throw new Error('Phase 8 components not initialized');
        }

        const startTime = Date.now();
        const results = {
            phase7: {}, // Standard validation
            phase8: {}  // Enhanced features
        };

        try {
            // ML Pattern Recognition
            if (options.mlAnalysis !== false) {
                const mlAnalysis = await this.mlEngine.analyzeCode(ast, source);
                results.phase8.mlAnalysis = mlAnalysis;
                
                this.monitoring.metrics.recordMLInference(mlAnalysis.inferenceTime);
            }

            // Performance Optimized Parsing
            if (options.performanceAnalysis !== false) {
                const perfResult = await this.performanceEngine.parse(source);
                results.phase8.performance = {
                    parseTime: perfResult.parseTime,
                    strategy: perfResult.strategy,
                    cached: perfResult.cached
                };
                
                this.monitoring.metrics.recordParseTime(perfResult.parseTime);
            }

            // Obfuscation Analysis
            if (options.obfuscationAnalysis !== false) {
                const obfuscationResult = await this.obfuscationAnalyzer.analyze(source, ast);
                results.phase8.obfuscation = obfuscationResult;
            }

            const totalTime = Date.now() - startTime;
            results.phase8.totalAnalysisTime = totalTime;

            // Log to monitoring
            this.monitoring.logger.logValidation(
                'enhanced',
                'success',
                totalTime,
                { mlEnabled: !!results.phase8.mlAnalysis }
            );

            // Record metrics
            this.monitoring.metrics.recordValidation('enhanced', 'success', totalTime);

            return results;

        } catch (error) {
            const totalTime = Date.now() - startTime;
            
            this.monitoring.logger.error('Enhanced validation failed', error);
            this.monitoring.metrics.recordError('ValidationError', 'critical');
            this.monitoring.metrics.recordValidation('enhanced', 'failure', totalTime);

            throw error;
        }
    }

    /**
     * Get comprehensive statistics
     */
    getStatistics() {
        if (!this.initialized) {
            return { error: 'Not initialized' };
        }

        return {
            ml: this.mlEngine.getStatistics(),
            performance: this.performanceEngine.getStats(),
            obfuscation: this.obfuscationAnalyzer.getStatistics(),
            monitoring: 'See /metrics endpoint'
        };
    }

    /**
     * Get monitoring middleware
     */
    getMonitoringMiddleware() {
        if (!this.monitoring) {
            throw new Error('Monitoring not initialized');
        }
        return this.monitoring.getMiddleware();
    }

    /**
     * Get error handler middleware
     */
    getErrorHandler() {
        if (!this.monitoring) {
            throw new Error('Monitoring not initialized');
        }
        return this.monitoring.getErrorHandler();
    }

    /**
     * Health check
     */
    async healthCheck() {
        return {
            phase8: {
                mlEngine: this.mlEngine ? 'healthy' : 'not initialized',
                performanceEngine: this.performanceEngine ? 'healthy' : 'not initialized',
                obfuscationAnalyzer: this.obfuscationAnalyzer ? 'healthy' : 'not initialized',
                monitoring: this.monitoring ? 'healthy' : 'not initialized'
            },
            stats: this.getStatistics()
        };
    }

    /**
     * Shutdown all components
     */
    async shutdown() {
        console.log('Shutting down Phase 8 components...');

        if (this.performanceEngine) {
            await this.performanceEngine.shutdown();
        }

        if (this.monitoring) {
            this.monitoring.stop();
        }

        this.initialized = false;
        console.log('Phase 8 shutdown complete');
    }
}

// ============================================================================
// EXPRESS ROUTE HANDLERS
// ============================================================================

/**
 * Create Phase 8 API routes
 */
function createPhase8Routes(integration) {
    const router = require('express').Router();

    // Enhanced validation endpoint
    router.post('/validate/enhanced', async (req, res) => {
        try {
            const { source, ast, options } = req.body;

            if (!source) {
                return res.status(400).json({ error: 'Source code required' });
            }

            const result = await integration.enhancedValidation(source, ast, options);
            
            res.json({
                success: true,
                result,
                timestamp: new Date().toISOString()
            });

        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // ML analysis endpoint
    router.post('/ml/analyze', async (req, res) => {
        try {
            const { ast, source } = req.body;

            if (!ast) {
                return res.status(400).json({ error: 'AST required' });
            }

            const result = await integration.mlEngine.analyzeCode(ast, source);
            
            res.json({
                success: true,
                analysis: result
            });

        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // Performance benchmark endpoint
    router.post('/performance/benchmark', async (req, res) => {
        try {
            const { source, iterations = 100 } = req.body;

            if (!source) {
                return res.status(400).json({ error: 'Source code required' });
            }

            const result = await integration.performanceEngine.benchmark(source, iterations);
            
            res.json({
                success: true,
                benchmark: result
            });

        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // Obfuscation detection endpoint
    router.post('/obfuscation/detect', async (req, res) => {
        try {
            const { source, ast } = req.body;

            if (!source) {
                return res.status(400).json({ error: 'Source code required' });
            }

            const result = await integration.obfuscationAnalyzer.analyze(source, ast);
            
            res.json({
                success: true,
                analysis: result
            });

        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // Phase 8 statistics endpoint
    router.get('/phase8/stats', async (req, res) => {
        try {
            const stats = integration.getStatistics();
            
            res.json({
                success: true,
                stats
            });

        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // Phase 8 health check
    router.get('/phase8/health', async (req, res) => {
        try {
            const health = await integration.healthCheck();
            
            res.json({
                success: true,
                health
            });

        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    return router;
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
    Phase8Integration,
    createPhase8Routes
};

// Example usage
if (require.main === module) {
    (async () => {
        const integration = new Phase8Integration();
        await integration.initialize();

        const testCode = `
            local function test()
                game.print("Hello Factorio")
            end
        `;

        const testAST = {
            type: 'Program',
            body: []
        };

        const result = await integration.enhancedValidation(testCode, testAST);
        console.log('Enhanced validation result:', JSON.stringify(result, null, 2));

        await integration.shutdown();
    })();
}
