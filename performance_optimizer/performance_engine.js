/**
 * Performance Optimizer for Factorio Lua Parser
 * Phase 8: Sub-20ms Multi-Core Implementation
 * 
 * Reference: https://nodejs.org/api/worker_threads.html
 * Reference: https://nodejs.org/api/stream.html
 * Reference: https://luajit.org/performance.html
 */

const { Worker, isMainThread, parentPort, workerData } = require('worker_threads');
const { LRUCache } = require('lru-cache');
const fs = require('fs').promises;
const path = require('path');
const { performance } = require('perf_hooks');
const os = require('os');
const Piscina = require('piscina');

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG = {
    NUM_WORKERS: process.env.NUM_WORKERS || os.cpus().length,
    CHUNK_SIZE: 8192, // 8KB chunks for streaming
    CACHE_SIZE: process.env.CACHE_SIZE || 1000,
    CACHE_TTL: 1000 * 60 * 30, // 30 minutes
    MAX_FILE_SIZE: 50 * 1024 * 1024, // 50MB
    MEMORY_POOL_SIZE: 100 * 1024 * 1024, // 100MB
    PROFILING_ENABLED: process.env.PROFILING === 'true',
    TARGET_PARSE_TIME: 20 // milliseconds
};

// ============================================================================
// MEMORY POOL MANAGER
// ============================================================================

class MemoryPool {
    constructor(size) {
        this.pool = [];
        this.maxSize = size;
        this.currentSize = 0;
        this.allocations = 0;
        this.deallocations = 0;
        this.hits = 0;
        this.misses = 0;
    }

    /**
     * Allocate buffer from pool
     */
    allocate(size) {
        this.allocations++;
        
        // Try to reuse existing buffer
        for (let i = 0; i < this.pool.length; i++) {
            if (this.pool[i].length >= size && !this.pool[i].inUse) {
                this.pool[i].inUse = true;
                this.hits++;
                return this.pool[i];
            }
        }
        
        // Create new buffer if pool has space
        if (this.currentSize + size <= this.maxSize) {
            const buffer = Buffer.allocUnsafe(size);
            buffer.inUse = true;
            this.pool.push(buffer);
            this.currentSize += size;
            this.misses++;
            return buffer;
        }
        
        // Fallback to regular allocation
        this.misses++;
        return Buffer.allocUnsafe(size);
    }

    /**
     * Return buffer to pool
     */
    deallocate(buffer) {
        this.deallocations++;
        
        if (buffer && buffer.inUse !== undefined) {
            buffer.inUse = false;
        }
    }

    /**
     * Clear pool
     */
    clear() {
        this.pool = [];
        this.currentSize = 0;
    }

    /**
     * Get pool statistics
     */
    getStats() {
        return {
            allocations: this.allocations,
            deallocations: this.deallocations,
            hits: this.hits,
            misses: this.misses,
            hitRate: this.allocations > 0 ? (this.hits / this.allocations * 100).toFixed(2) + '%' : '0%',
            currentSize: this.currentSize,
            maxSize: this.maxSize,
            pooledBuffers: this.pool.length
        };
    }
}

// ============================================================================
// RESULT CACHE
// ============================================================================

class ResultCache {
    constructor() {
        this.cache = new LRUCache({
            max: CONFIG.CACHE_SIZE,
            ttl: CONFIG.CACHE_TTL,
            updateAgeOnGet: true,
            updateAgeOnHas: true
        });
        
        this.hits = 0;
        this.misses = 0;
    }

    /**
     * Get cached result
     */
    get(key) {
        const result = this.cache.get(key);
        
        if (result) {
            this.hits++;
            return result;
        }
        
        this.misses++;
        return null;
    }

    /**
     * Set cached result
     */
    set(key, value) {
        this.cache.set(key, value);
    }

    /**
     * Check if key exists
     */
    has(key) {
        return this.cache.has(key);
    }

    /**
     * Clear cache
     */
    clear() {
        this.cache.clear();
        this.hits = 0;
        this.misses = 0;
    }

    /**
     * Get cache statistics
     */
    getStats() {
        return {
            size: this.cache.size,
            maxSize: CONFIG.CACHE_SIZE,
            hits: this.hits,
            misses: this.misses,
            hitRate: (this.hits + this.misses) > 0 ? 
                (this.hits / (this.hits + this.misses) * 100).toFixed(2) + '%' : '0%'
        };
    }
}

// ============================================================================
// STREAMING FILE PROCESSOR
// ============================================================================

class StreamingProcessor {
    constructor() {
        this.memoryPool = new MemoryPool(CONFIG.MEMORY_POOL_SIZE);
    }

    /**
     * Process large file in chunks
     */
    async processLargeFile(filePath, processor) {
        const stats = await fs.stat(filePath);
        const fileSize = stats.size;
        
        if (fileSize > CONFIG.MAX_FILE_SIZE) {
            throw new Error(`File too large: ${fileSize} bytes (max: ${CONFIG.MAX_FILE_SIZE})`);
        }
        
        const chunks = [];
        const chunkCount = Math.ceil(fileSize / CONFIG.CHUNK_SIZE);
        
        const fileHandle = await fs.open(filePath, 'r');
        
        try {
            for (let i = 0; i < chunkCount; i++) {
                const buffer = this.memoryPool.allocate(CONFIG.CHUNK_SIZE);
                const { bytesRead } = await fileHandle.read(buffer, 0, CONFIG.CHUNK_SIZE, i * CONFIG.CHUNK_SIZE);
                
                if (bytesRead > 0) {
                    const chunk = buffer.slice(0, bytesRead).toString('utf-8');
                    const processed = await processor(chunk, i, chunkCount);
                    chunks.push(processed);
                }
                
                this.memoryPool.deallocate(buffer);
            }
        } finally {
            await fileHandle.close();
        }
        
        return chunks;
    }

    /**
     * Process file with streaming and combine results
     */
    async processFileStreaming(filePath) {
        const startTime = performance.now();
        
        const chunks = await this.processLargeFile(filePath, async (chunk, index, total) => {
            return {
                index,
                content: chunk,
                size: chunk.length
            };
        });
        
        const processingTime = performance.now() - startTime;
        
        return {
            chunks,
            totalChunks: chunks.length,
            processingTime,
            memoryStats: this.memoryPool.getStats()
        };
    }
}

// ============================================================================
// WORKER POOL MANAGER
// ============================================================================

class WorkerPool {
    constructor(workerScript, numWorkers = CONFIG.NUM_WORKERS) {
        this.piscina = new Piscina({
            filename: workerScript,
            minThreads: Math.max(2, Math.floor(numWorkers / 2)),
            maxThreads: numWorkers,
            idleTimeout: 30000
        });
        
        this.taskCount = 0;
        this.completedTasks = 0;
        this.failedTasks = 0;
        this.totalProcessingTime = 0;
    }

    /**
     * Run task in worker
     */
    async runTask(task, data) {
        this.taskCount++;
        const startTime = performance.now();
        
        try {
            const result = await this.piscina.run({ task, data });
            
            const processingTime = performance.now() - startTime;
            this.totalProcessingTime += processingTime;
            this.completedTasks++;
            
            return {
                success: true,
                result,
                processingTime
            };
        } catch (error) {
            this.failedTasks++;
            
            return {
                success: false,
                error: error.message,
                processingTime: performance.now() - startTime
            };
        }
    }

    /**
     * Run multiple tasks in parallel
     */
    async runParallel(tasks) {
        const promises = tasks.map(({ task, data }) => this.runTask(task, data));
        return await Promise.all(promises);
    }

    /**
     * Get worker pool statistics
     */
    getStats() {
        return {
            workers: {
                min: this.piscina.options.minThreads,
                max: this.piscina.options.maxThreads,
                active: this.piscina.threads.length,
                idle: this.piscina.threads.filter(t => t.currentUsage === 0).length
            },
            tasks: {
                total: this.taskCount,
                completed: this.completedTasks,
                failed: this.failedTasks,
                successRate: this.taskCount > 0 ? 
                    (this.completedTasks / this.taskCount * 100).toFixed(2) + '%' : '0%'
            },
            performance: {
                totalProcessingTime: this.totalProcessingTime.toFixed(2) + 'ms',
                avgProcessingTime: this.completedTasks > 0 ? 
                    (this.totalProcessingTime / this.completedTasks).toFixed(2) + 'ms' : '0ms'
            }
        };
    }

    /**
     * Shutdown worker pool
     */
    async shutdown() {
        await this.piscina.destroy();
    }
}

// ============================================================================
// PARSER WORKER IMPLEMENTATION
// ============================================================================

// This function runs in worker threads
function parseWorkerTask({ task, data }) {
    switch (task) {
        case 'tokenize':
            return tokenizeLua(data.source);
        
        case 'parseChunk':
            return parseChunk(data.tokens, data.startIndex, data.endIndex);
        
        case 'validateSyntax':
            return validateSyntax(data.source);
        
        case 'extractAPICalls':
            return extractAPICalls(data.ast);
        
        default:
            throw new Error(`Unknown task: ${task}`);
    }
}

/**
 * Tokenize Lua source code
 */
function tokenizeLua(source) {
    const tokens = [];
    let i = 0;
    
    const patterns = {
        whitespace: /^\s+/,
        comment: /^--[^\n]*/,
        multilineComment: /^--\[\[(.*?)\]\]/s,
        number: /^0x[0-9a-fA-F]+|^\d+\.?\d*([eE][+-]?\d+)?/,
        string: /^"([^"\\]|\\.)*"|^'([^'\\]|\\.)*'/,
        identifier: /^[a-zA-Z_][a-zA-Z0-9_]*/,
        operator: /^(==|~=|<=|>=|\.\.|\+|-|\*|\/|%|\^|#|<|>|=)/,
        punctuation: /^[{}()\[\];,.:]/
    };
    
    while (i < source.length) {
        let matched = false;
        
        for (const [type, pattern] of Object.entries(patterns)) {
            const match = source.slice(i).match(pattern);
            
            if (match) {
                if (type !== 'whitespace' && type !== 'comment') {
                    tokens.push({
                        type,
                        value: match[0],
                        start: i,
                        end: i + match[0].length
                    });
                }
                
                i += match[0].length;
                matched = true;
                break;
            }
        }
        
        if (!matched) {
            i++;
        }
    }
    
    return tokens;
}

/**
 * Parse token chunk into AST
 */
function parseChunk(tokens, startIndex, endIndex) {
    const chunk = tokens.slice(startIndex, endIndex);
    
    const ast = {
        type: 'Chunk',
        body: [],
        start: chunk[0]?.start || 0,
        end: chunk[chunk.length - 1]?.end || 0
    };
    
    let i = 0;
    while (i < chunk.length) {
        const token = chunk[i];
        
        if (token.type === 'identifier' && token.value === 'function') {
            ast.body.push(parseFunctionDeclaration(chunk, i));
        } else if (token.type === 'identifier' && token.value === 'local') {
            ast.body.push(parseLocalStatement(chunk, i));
        }
        
        i++;
    }
    
    return ast;
}

function parseFunctionDeclaration(tokens, startIndex) {
    return {
        type: 'FunctionDeclaration',
        identifier: tokens[startIndex + 1],
        body: []
    };
}

function parseLocalStatement(tokens, startIndex) {
    return {
        type: 'LocalStatement',
        variables: [tokens[startIndex + 1]],
        init: []
    };
}

/**
 * Validate syntax
 */
function validateSyntax(source) {
    const errors = [];
    
    const lines = source.split('\n');
    const stack = [];
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        
        if (line.includes('function')) {
            stack.push({ type: 'function', line: i });
        } else if (line.includes('if')) {
            stack.push({ type: 'if', line: i });
        } else if (line.includes('end')) {
            if (stack.length === 0) {
                errors.push({
                    line: i + 1,
                    message: 'Unmatched "end" keyword'
                });
            } else {
                stack.pop();
            }
        }
    }
    
    if (stack.length > 0) {
        errors.push({
            line: stack[0].line + 1,
            message: `Unclosed ${stack[0].type} block`
        });
    }
    
    return {
        isValid: errors.length === 0,
        errors
    };
}

/**
 * Extract API calls from AST
 */
function extractAPICalls(ast) {
    const apiCalls = [];
    
    function traverse(node) {
        if (!node) return;
        
        if (node.type === 'CallExpression' && node.base) {
            apiCalls.push({
                type: 'call',
                name: node.base.name || 'unknown',
                location: { start: node.start, end: node.end }
            });
        }
        
        if (node.body && Array.isArray(node.body)) {
            node.body.forEach(traverse);
        }
    }
    
    traverse(ast);
    
    return apiCalls;
}

// ============================================================================
// PERFORMANCE ENGINE
// ============================================================================

class PerformanceEngine {
    constructor() {
        this.cache = new ResultCache();
        this.memoryPool = new MemoryPool(CONFIG.MEMORY_POOL_SIZE);
        this.streamingProcessor = new StreamingProcessor();
        this.workerPool = null;
        this.metrics = {
            parseCount: 0,
            totalParseTime: 0,
            cacheHits: 0,
            cacheMisses: 0
        };
    }

    /**
     * Initialize performance engine
     */
    async initialize() {
        // Worker pool is initialized on-demand to avoid creating workers unnecessarily
        console.log('Performance Engine initialized');
        console.log(`Target parse time: ${CONFIG.TARGET_PARSE_TIME}ms`);
        console.log(`Available CPU cores: ${os.cpus().length}`);
        console.log(`Worker threads: ${CONFIG.NUM_WORKERS}`);
    }

    /**
     * Initialize worker pool on-demand
     */
    initializeWorkerPool() {
        if (!this.workerPool) {
            this.workerPool = new WorkerPool(path.join(__dirname, 'worker.js'), CONFIG.NUM_WORKERS);
        }
    }

    /**
     * Parse source code with optimizations
     */
    async parse(source, options = {}) {
        const startTime = performance.now();
        
        // Generate cache key
        const cacheKey = this.generateCacheKey(source);
        
        // Check cache
        if (!options.skipCache) {
            const cached = this.cache.get(cacheKey);
            if (cached) {
                this.metrics.cacheHits++;
                return {
                    ...cached,
                    cached: true,
                    parseTime: performance.now() - startTime
                };
            }
        }
        
        this.metrics.cacheMisses++;
        
        // Determine parsing strategy based on size
        let result;
        if (source.length > CONFIG.CHUNK_SIZE * 10) {
            // Large file: use streaming + multi-core
            result = await this.parseLarge(source);
        } else if (source.length > CONFIG.CHUNK_SIZE) {
            // Medium file: use multi-core
            result = await this.parseParallel(source);
        } else {
            // Small file: parse directly
            result = await this.parseDirect(source);
        }
        
        const parseTime = performance.now() - startTime;
        
        result.parseTime = parseTime;
        result.cached = false;
        
        // Update metrics
        this.metrics.parseCount++;
        this.metrics.totalParseTime += parseTime;
        
        // Cache result
        if (!options.skipCache) {
            this.cache.set(cacheKey, result);
        }
        
        return result;
    }

    /**
     * Parse directly (small files)
     */
    async parseDirect(source) {
        const tokens = tokenizeLua(source);
        const ast = parseChunk(tokens, 0, tokens.length);
        const validation = validateSyntax(source);
        
        return {
            ast,
            tokens,
            validation,
            strategy: 'direct',
            size: source.length
        };
    }

    /**
     * Parse with parallelization (medium files)
     */
    async parseParallel(source) {
        this.initializeWorkerPool();
        
        // Tokenize first
        const tokenizeResult = await this.workerPool.runTask('tokenize', { source });
        
        if (!tokenizeResult.success) {
            throw new Error('Tokenization failed: ' + tokenizeResult.error);
        }
        
        const tokens = tokenizeResult.result;
        
        // Split tokens into chunks for parallel parsing
        const chunkSize = Math.ceil(tokens.length / CONFIG.NUM_WORKERS);
        const tasks = [];
        
        for (let i = 0; i < CONFIG.NUM_WORKERS; i++) {
            const startIndex = i * chunkSize;
            const endIndex = Math.min((i + 1) * chunkSize, tokens.length);
            
            if (startIndex < tokens.length) {
                tasks.push({
                    task: 'parseChunk',
                    data: { tokens, startIndex, endIndex }
                });
            }
        }
        
        // Parse chunks in parallel
        const results = await this.workerPool.runParallel(tasks);
        
        // Combine chunks
        const ast = {
            type: 'Program',
            body: results.filter(r => r.success).flatMap(r => r.result.body)
        };
        
        // Validate
        const validation = await this.workerPool.runTask('validateSyntax', { source });
        
        return {
            ast,
            tokens,
            validation: validation.success ? validation.result : { isValid: false, errors: [] },
            strategy: 'parallel',
            size: source.length,
            workers: CONFIG.NUM_WORKERS
        };
    }

    /**
     * Parse with streaming (large files)
     */
    async parseLarge(source) {
        // For very large sources, write to temp file and process with streaming
        const tempFile = path.join(os.tmpdir(), `factorio-parse-${Date.now()}.lua`);
        
        try {
            await fs.writeFile(tempFile, source);
            
            const streamResult = await this.streamingProcessor.processFileStreaming(tempFile);
            
            // Tokenize each chunk
            this.initializeWorkerPool();
            const tokenizeTasks = streamResult.chunks.map(chunk => ({
                task: 'tokenize',
                data: { source: chunk.content }
            }));
            
            const tokenizeResults = await this.workerPool.runParallel(tokenizeTasks);
            
            const allTokens = tokenizeResults
                .filter(r => r.success)
                .flatMap(r => r.result);
            
            // Parse combined tokens
            const ast = parseChunk(allTokens, 0, allTokens.length);
            
            return {
                ast,
                tokens: allTokens,
                validation: { isValid: true, errors: [] },
                strategy: 'streaming',
                size: source.length,
                chunks: streamResult.totalChunks
            };
        } finally {
            // Clean up temp file
            try {
                await fs.unlink(tempFile);
            } catch (error) {
                // Ignore cleanup errors
            }
        }
    }

    /**
     * Generate cache key
     */
    generateCacheKey(source) {
        const crypto = require('crypto');
        return crypto.createHash('md5').update(source).digest('hex');
    }

    /**
     * Get performance statistics
     */
    getStats() {
        return {
            parsing: {
                count: this.metrics.parseCount,
                totalTime: this.metrics.totalParseTime.toFixed(2) + 'ms',
                avgTime: this.metrics.parseCount > 0 ? 
                    (this.metrics.totalParseTime / this.metrics.parseCount).toFixed(2) + 'ms' : '0ms',
                target: CONFIG.TARGET_PARSE_TIME + 'ms'
            },
            cache: this.cache.getStats(),
            memory: this.memoryPool.getStats(),
            workers: this.workerPool ? this.workerPool.getStats() : 'Not initialized'
        };
    }

    /**
     * Benchmark parsing performance
     */
    async benchmark(source, iterations = 100) {
        const times = [];
        
        console.log(`Running ${iterations} iterations...`);
        
        for (let i = 0; i < iterations; i++) {
            const startTime = performance.now();
            await this.parse(source, { skipCache: true });
            const endTime = performance.now();
            
            times.push(endTime - startTime);
        }
        
        times.sort((a, b) => a - b);
        
        const avg = times.reduce((sum, t) => sum + t, 0) / times.length;
        const median = times[Math.floor(times.length / 2)];
        const p95 = times[Math.floor(times.length * 0.95)];
        const p99 = times[Math.floor(times.length * 0.99)];
        const min = times[0];
        const max = times[times.length - 1];
        
        return {
            iterations,
            avg: avg.toFixed(2) + 'ms',
            median: median.toFixed(2) + 'ms',
            p95: p95.toFixed(2) + 'ms',
            p99: p99.toFixed(2) + 'ms',
            min: min.toFixed(2) + 'ms',
            max: max.toFixed(2) + 'ms',
            targetMet: avg < CONFIG.TARGET_PARSE_TIME
        };
    }

    /**
     * Clear all caches
     */
    clearCaches() {
        this.cache.clear();
        this.memoryPool.clear();
    }

    /**
     * Shutdown engine
     */
    async shutdown() {
        if (this.workerPool) {
            await this.workerPool.shutdown();
        }
        
        this.clearCaches();
        console.log('Performance Engine shutdown complete');
    }
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
    PerformanceEngine,
    WorkerPool,
    StreamingProcessor,
    MemoryPool,
    ResultCache,
    parseWorkerTask,
    CONFIG
};

// Example usage
if (require.main === module) {
    (async () => {
        const engine = new PerformanceEngine();
        await engine.initialize();
        
        const testCode = `
            local function test()
                game.print("Hello Factorio")
                for i = 1, 10 do
                    game.players[1].insert{name="iron-plate", count=100}
                end
            end
        `;
        
        console.log('Parsing test code...');
        const result = await engine.parse(testCode);
        console.log('Parse time:', result.parseTime.toFixed(2) + 'ms');
        console.log('Strategy:', result.strategy);
        
        console.log('\nRunning benchmark...');
        const benchmark = await engine.benchmark(testCode, 100);
        console.log('Benchmark results:', benchmark);
        
        console.log('\nEngine statistics:');
        console.log(JSON.stringify(engine.getStats(), null, 2));
        
        await engine.shutdown();
    })();
}
