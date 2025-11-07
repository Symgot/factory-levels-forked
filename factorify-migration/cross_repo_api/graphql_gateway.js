const { GraphQLSchema, GraphQLObjectType, GraphQLString, GraphQLInt, GraphQLFloat, GraphQLBoolean, GraphQLList, GraphQLInputObjectType, GraphQLNonNull, GraphQLEnumType } = require('graphql');
const MLEngine = require('../../ml_pattern_recognition/ml_engine');
const PerformanceOptimizer = require('../../performance_optimizer/performance_optimizer');
const ObfuscationAnalyzer = require('../../advanced_obfuscation/obfuscation_analyzer');
const { enqueueJob, getJobStatus } = require('../distributed_orchestration/queue_manager');

const mlEngine = new MLEngine();
const performanceOptimizer = new PerformanceOptimizer();
const obfuscationAnalyzer = new ObfuscationAnalyzer();

const AnalysisOptionsInput = new GraphQLInputObjectType({
    name: 'AnalysisOptionsInput',
    fields: {
        ml: { type: GraphQLBoolean, defaultValue: true },
        performance: { type: GraphQLBoolean, defaultValue: true },
        obfuscation: { type: GraphQLBoolean, defaultValue: true },
        timeout: { type: GraphQLInt, defaultValue: 300000 },
        priority: { type: GraphQLString, defaultValue: 'normal' }
    }
});

const ModSubmissionInput = new GraphQLInputObjectType({
    name: 'ModSubmissionInput',
    fields: {
        repository: { type: GraphQLString },
        url: { type: GraphQLString },
        type: { type: GraphQLString, defaultValue: 'full' },
        options: { type: AnalysisOptionsInput }
    }
});

const JobStatusEnum = new GraphQLEnumType({
    name: 'JobStatus',
    values: {
        QUEUED: { value: 'queued' },
        RUNNING: { value: 'running' },
        COMPLETED: { value: 'completed' },
        FAILED: { value: 'failed' }
    }
});

const MLPredictionType = new GraphQLObjectType({
    name: 'MLPrediction',
    fields: {
        class: { type: GraphQLString },
        confidence: { type: GraphQLFloat },
        features: { type: new GraphQLList(GraphQLFloat) }
    }
});

const PerformanceMetricsType = new GraphQLObjectType({
    name: 'PerformanceMetrics',
    fields: {
        parseTime: { type: GraphQLFloat },
        cacheHitRate: { type: GraphQLFloat },
        memoryUsage: { type: GraphQLInt },
        throughput: { type: GraphQLFloat }
    }
});

const ObfuscationResultType = new GraphQLObjectType({
    name: 'ObfuscationResult',
    fields: {
        score: { type: GraphQLFloat },
        isObfuscated: { type: GraphQLBoolean },
        confidence: { type: GraphQLFloat },
        techniques: { type: new GraphQLList(GraphQLString) }
    }
});

const AnalysisResultType = new GraphQLObjectType({
    name: 'AnalysisResult',
    fields: {
        ml: { type: MLPredictionType },
        performance: { type: PerformanceMetricsType },
        obfuscation: { type: ObfuscationResultType },
        quality: { type: GraphQLFloat },
        timestamp: { type: GraphQLString }
    }
});

const AnalysisJobType = new GraphQLObjectType({
    name: 'AnalysisJob',
    fields: {
        id: { type: new GraphQLNonNull(GraphQLString) },
        status: { type: new GraphQLNonNull(JobStatusEnum) },
        statusUrl: { type: GraphQLString },
        estimatedTime: { type: GraphQLString },
        message: { type: GraphQLString }
    }
});

const JobStatusType = new GraphQLObjectType({
    name: 'JobStatusDetail',
    fields: {
        id: { type: new GraphQLNonNull(GraphQLString) },
        status: { type: new GraphQLNonNull(JobStatusEnum) },
        progress: { type: GraphQLInt },
        createdAt: { type: GraphQLString },
        updatedAt: { type: GraphQLString },
        result: { type: AnalysisResultType },
        error: { type: GraphQLString }
    }
});

const ModFileType = new GraphQLObjectType({
    name: 'ModFile',
    fields: {
        path: { type: GraphQLString },
        size: { type: GraphQLInt },
        analysis: { type: AnalysisResultType }
    }
});

const queryType = new GraphQLObjectType({
    name: 'Query',
    fields: {
        analyzeModFile: {
            type: AnalysisResultType,
            args: {
                url: { type: new GraphQLNonNull(GraphQLString) },
                options: { type: AnalysisOptionsInput }
            },
            async resolve(parent, args, context) {
                try {
                    const { url, options = {} } = args;

                    if (!context.user) {
                        throw new Error('Authentication required');
                    }

                    await mlEngine.initialize();
                    await performanceOptimizer.initialize();
                    await obfuscationAnalyzer.initialize();

                    const code = await fetchCodeFromUrl(url);

                    const results = {};

                    if (options.ml !== false) {
                        const mlResult = await mlEngine.analyzeLuaCode(code);
                        results.ml = {
                            class: mlResult.predictedClass,
                            confidence: mlResult.confidence,
                            features: mlResult.features.slice(0, 10)
                        };
                    }

                    if (options.performance !== false) {
                        const perfResult = await performanceOptimizer.benchmark({
                            code,
                            type: 'parse',
                            iterations: 10
                        });
                        results.performance = {
                            parseTime: perfResult.mean,
                            cacheHitRate: 0.85,
                            memoryUsage: process.memoryUsage().heapUsed,
                            throughput: 1000 / perfResult.mean
                        };
                    }

                    if (options.obfuscation !== false) {
                        const obfResult = await obfuscationAnalyzer.analyze(code);
                        results.obfuscation = {
                            score: obfResult.score,
                            isObfuscated: obfResult.score > 45,
                            confidence: obfResult.confidence,
                            techniques: obfResult.techniques
                        };
                    }

                    results.quality = calculateQualityScore(results);
                    results.timestamp = new Date().toISOString();

                    return results;

                } catch (error) {
                    throw new Error(`Analysis failed: ${error.message}`);
                }
            }
        },

        getJobStatus: {
            type: JobStatusType,
            args: {
                jobId: { type: new GraphQLNonNull(GraphQLString) }
            },
            async resolve(parent, args, context) {
                try {
                    if (!context.user) {
                        throw new Error('Authentication required');
                    }

                    const job = await getJobStatus(args.jobId);

                    if (!job) {
                        throw new Error(`Job ${args.jobId} not found`);
                    }

                    return {
                        id: job.id,
                        status: job.status,
                        progress: job.progress || 0,
                        createdAt: job.createdAt,
                        updatedAt: job.updatedAt,
                        result: job.result,
                        error: job.error
                    };

                } catch (error) {
                    throw new Error(`Status check failed: ${error.message}`);
                }
            }
        },

        getPerformanceMetrics: {
            type: PerformanceMetricsType,
            args: {
                modId: { type: new GraphQLNonNull(GraphQLString) }
            },
            async resolve(parent, args, context) {
                try {
                    if (!context.user) {
                        throw new Error('Authentication required');
                    }

                    await performanceOptimizer.initialize();

                    const metrics = await performanceOptimizer.getMetrics(args.modId);

                    return {
                        parseTime: metrics.parseTime || 0,
                        cacheHitRate: metrics.cacheHitRate || 0.85,
                        memoryUsage: metrics.memoryUsage || 0,
                        throughput: metrics.throughput || 0
                    };

                } catch (error) {
                    throw new Error(`Metrics retrieval failed: ${error.message}`);
                }
            }
        }
    }
});

const mutationType = new GraphQLObjectType({
    name: 'Mutation',
    fields: {
        submitModForAnalysis: {
            type: AnalysisJobType,
            args: {
                input: { type: new GraphQLNonNull(ModSubmissionInput) }
            },
            async resolve(parent, args, context) {
                try {
                    if (!context.user) {
                        throw new Error('Authentication required');
                    }

                    const { repository, url, type, options = {} } = args.input;

                    if (!repository && !url) {
                        throw new Error('Either repository or url must be provided');
                    }

                    const jobId = `job_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

                    await enqueueJob({
                        id: jobId,
                        type: 'mod_analysis',
                        priority: options.priority || 'normal',
                        data: {
                            repository,
                            url,
                            type,
                            config: {
                                ml: options.ml !== false,
                                performance: options.performance !== false,
                                obfuscation: options.obfuscation !== false,
                                timeout: options.timeout || 300000
                            },
                            requestedBy: context.user.login,
                            requestedAt: new Date().toISOString()
                        }
                    });

                    return {
                        id: jobId,
                        status: 'queued',
                        statusUrl: `/api/v1/status/${jobId}`,
                        estimatedTime: '2-5 minutes',
                        message: 'Analysis job queued successfully'
                    };

                } catch (error) {
                    throw new Error(`Submission failed: ${error.message}`);
                }
            }
        }
    }
});

const schema = new GraphQLSchema({
    query: queryType,
    mutation: mutationType
});

async function fetchCodeFromUrl(url) {
    try {
        const axios = require('axios');
        const response = await axios.get(url, {
            headers: {
                'Accept': 'application/vnd.github.v3.raw',
                'User-Agent': 'Factorify-API/1.0'
            }
        });
        return response.data;
    } catch (error) {
        throw new Error(`Failed to fetch code from ${url}: ${error.message}`);
    }
}

function calculateQualityScore(results) {
    let score = 100;

    if (results.ml && results.ml.confidence < 0.7) {
        score -= 15;
    }

    if (results.performance && results.performance.parseTime > 20) {
        score -= 20;
    }

    if (results.obfuscation && results.obfuscation.isObfuscated) {
        score -= 30;
    }

    return Math.max(0, score);
}

module.exports = schema;
