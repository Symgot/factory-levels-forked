/**
 * ML Pattern Recognition Engine for Factorio Lua Code
 * Phase 8: Complete ML Implementation
 * 
 * Reference: https://www.tensorflow.org/js/guide/nodejs
 * Reference: https://arxiv.org/abs/1803.07734 (Code Pattern Analysis)
 * Reference: https://github.com/github/semantic (Semantic Code Analysis)
 */

const tf = require('@tensorflow/tfjs-node');
const natural = require('natural');
const math = require('mathjs');
const fs = require('fs-extra');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG = {
    MODEL_DIR: process.env.MODEL_DIR || './models',
    TRAINING_DATA_DIR: process.env.TRAINING_DATA_DIR || './training_data',
    FEATURE_VECTOR_SIZE: 256,
    MAX_SEQUENCE_LENGTH: 512,
    BATCH_SIZE: 32,
    EPOCHS: 50,
    LEARNING_RATE: 0.001,
    VALIDATION_SPLIT: 0.2,
    MIN_CONFIDENCE: 0.7,
    PATTERN_CACHE_SIZE: 1000
};

// ============================================================================
// FEATURE EXTRACTION
// ============================================================================

class FeatureExtractor {
    constructor() {
        this.tokenizer = new natural.WordTokenizer();
        this.tfidf = new natural.TfIdf();
        this.vocabulary = new Map();
        this.apiPatterns = new Map();
    }

    /**
     * Extract features from AST node
     * Reference: Code2Vec pattern (https://github.com/tech-srl/code2vec)
     */
    extractASTFeatures(ast) {
        const features = {
            nodeType: this.encodeNodeType(ast.type),
            depth: this.calculateDepth(ast),
            fanout: this.calculateFanout(ast),
            complexity: this.calculateComplexity(ast),
            apiCalls: this.extractAPICalls(ast),
            controlFlow: this.extractControlFlowFeatures(ast),
            dataFlow: this.extractDataFlowFeatures(ast),
            lexical: this.extractLexicalFeatures(ast),
            structural: this.extractStructuralFeatures(ast),
            semantic: this.extractSemanticFeatures(ast)
        };

        return this.normalizeFeatures(features);
    }

    /**
     * Encode node type as one-hot vector
     */
    encodeNodeType(nodeType) {
        const types = [
            'FunctionDeclaration', 'VariableDeclaration', 'Assignment',
            'CallExpression', 'MemberExpression', 'IfStatement',
            'WhileStatement', 'ForStatement', 'ReturnStatement',
            'BinaryExpression', 'UnaryExpression', 'TableConstructor',
            'IndexExpression', 'LocalStatement', 'DoStatement'
        ];
        
        const index = types.indexOf(nodeType);
        const vector = new Array(types.length).fill(0);
        if (index >= 0) vector[index] = 1;
        
        return vector;
    }

    /**
     * Calculate AST depth
     */
    calculateDepth(node, currentDepth = 0) {
        if (!node) return currentDepth;
        
        let maxDepth = currentDepth;
        
        if (node.body && Array.isArray(node.body)) {
            for (const child of node.body) {
                const depth = this.calculateDepth(child, currentDepth + 1);
                maxDepth = Math.max(maxDepth, depth);
            }
        }
        
        return maxDepth;
    }

    /**
     * Calculate fanout (number of direct children)
     */
    calculateFanout(node) {
        if (!node) return 0;
        
        let count = 0;
        
        if (node.body && Array.isArray(node.body)) {
            count += node.body.length;
        }
        
        if (node.arguments && Array.isArray(node.arguments)) {
            count += node.arguments.length;
        }
        
        return count;
    }

    /**
     * Calculate cyclomatic complexity
     */
    calculateComplexity(node) {
        let complexity = 1;
        
        const traverse = (n) => {
            if (!n) return;
            
            if (n.type === 'IfStatement' || n.type === 'WhileStatement' || 
                n.type === 'ForStatement' || n.type === 'RepeatStatement') {
                complexity++;
            }
            
            if (n.type === 'BinaryExpression' && (n.operator === 'and' || n.operator === 'or')) {
                complexity++;
            }
            
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return complexity;
    }

    /**
     * Extract Factorio API call patterns
     */
    extractAPICalls(ast) {
        const apiCalls = [];
        
        const traverse = (node) => {
            if (!node) return;
            
            if (node.type === 'CallExpression' || node.type === 'MemberExpression') {
                const callPath = this.extractCallPath(node);
                if (this.isFactorioAPI(callPath)) {
                    apiCalls.push({
                        path: callPath,
                        context: this.extractContext(node),
                        frequency: 1
                    });
                }
            }
            
            if (node.body && Array.isArray(node.body)) {
                node.body.forEach(traverse);
            }
            
            if (node.arguments && Array.isArray(node.arguments)) {
                node.arguments.forEach(traverse);
            }
        };
        
        traverse(ast);
        
        return this.aggregateAPICalls(apiCalls);
    }

    /**
     * Extract call path from expression
     */
    extractCallPath(node) {
        const parts = [];
        
        let current = node;
        while (current) {
            if (current.type === 'Identifier') {
                parts.unshift(current.name);
                break;
            } else if (current.type === 'MemberExpression') {
                if (current.identifier && current.identifier.name) {
                    parts.unshift(current.identifier.name);
                }
                current = current.base;
            } else if (current.type === 'CallExpression') {
                current = current.base;
            } else {
                break;
            }
        }
        
        return parts.join('.');
    }

    /**
     * Check if call path is Factorio API
     */
    isFactorioAPI(path) {
        const factorioAPIs = [
            'game', 'script', 'remote', 'commands', 'settings',
            'rendering', 'rcon', 'defines', 'data', 'mods'
        ];
        
        const firstPart = path.split('.')[0];
        return factorioAPIs.includes(firstPart);
    }

    /**
     * Extract context around API call
     */
    extractContext(node) {
        return {
            parentType: node.parent ? node.parent.type : null,
            nearbyAPICalls: [],
            localVariables: []
        };
    }

    /**
     * Aggregate API call statistics
     */
    aggregateAPICalls(apiCalls) {
        const aggregated = new Map();
        
        for (const call of apiCalls) {
            if (aggregated.has(call.path)) {
                const existing = aggregated.get(call.path);
                existing.frequency++;
            } else {
                aggregated.set(call.path, { ...call });
            }
        }
        
        return Array.from(aggregated.values());
    }

    /**
     * Extract control flow features
     */
    extractControlFlowFeatures(ast) {
        return {
            numBranches: this.countBranches(ast),
            numLoops: this.countLoops(ast),
            maxNestingDepth: this.calculateMaxNestingDepth(ast),
            numReturns: this.countReturns(ast),
            hasRecursion: this.detectRecursion(ast)
        };
    }

    countBranches(node) {
        let count = 0;
        
        const traverse = (n) => {
            if (!n) return;
            if (n.type === 'IfStatement') count++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return count;
    }

    countLoops(node) {
        let count = 0;
        
        const traverse = (n) => {
            if (!n) return;
            if (n.type === 'WhileStatement' || n.type === 'ForStatement' || 
                n.type === 'RepeatStatement') count++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return count;
    }

    calculateMaxNestingDepth(node, currentDepth = 0) {
        if (!node) return currentDepth;
        
        let maxDepth = currentDepth;
        
        const isNestable = ['IfStatement', 'WhileStatement', 'ForStatement', 
                            'RepeatStatement', 'FunctionDeclaration'].includes(node.type);
        
        const nextDepth = isNestable ? currentDepth + 1 : currentDepth;
        
        if (node.body && Array.isArray(node.body)) {
            for (const child of node.body) {
                const depth = this.calculateMaxNestingDepth(child, nextDepth);
                maxDepth = Math.max(maxDepth, depth);
            }
        }
        
        return maxDepth;
    }

    countReturns(node) {
        let count = 0;
        
        const traverse = (n) => {
            if (!n) return;
            if (n.type === 'ReturnStatement') count++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return count;
    }

    detectRecursion(node) {
        const functionNames = new Set();
        const callNames = new Set();
        
        const traverse = (n, currentFunction = null) => {
            if (!n) return;
            
            if (n.type === 'FunctionDeclaration' && n.identifier) {
                const funcName = n.identifier.name;
                functionNames.add(funcName);
                if (n.body && Array.isArray(n.body)) {
                    n.body.forEach(child => traverse(child, funcName));
                }
            } else if (n.type === 'CallExpression' && n.base) {
                if (n.base.type === 'Identifier') {
                    callNames.add(n.base.name);
                }
                if (n.body && Array.isArray(n.body)) {
                    n.body.forEach(child => traverse(child, currentFunction));
                }
            } else {
                if (n.body && Array.isArray(n.body)) {
                    n.body.forEach(child => traverse(child, currentFunction));
                }
            }
        };
        
        traverse(node);
        
        for (const funcName of functionNames) {
            if (callNames.has(funcName)) {
                return true;
            }
        }
        
        return false;
    }

    /**
     * Extract data flow features
     */
    extractDataFlowFeatures(ast) {
        return {
            numVariables: this.countVariables(ast),
            numAssignments: this.countAssignments(ast),
            numGlobals: this.countGlobals(ast),
            numLocals: this.countLocals(ast),
            variableReuse: this.analyzeVariableReuse(ast)
        };
    }

    countVariables(node) {
        const variables = new Set();
        
        const traverse = (n) => {
            if (!n) return;
            
            if (n.type === 'VariableDeclaration' || n.type === 'LocalStatement') {
                if (n.variables && Array.isArray(n.variables)) {
                    n.variables.forEach(v => {
                        if (v.name) variables.add(v.name);
                    });
                }
            }
            
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return variables.size;
    }

    countAssignments(node) {
        let count = 0;
        
        const traverse = (n) => {
            if (!n) return;
            if (n.type === 'AssignmentStatement') count++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return count;
    }

    countGlobals(node) {
        let count = 0;
        
        const traverse = (n) => {
            if (!n) return;
            if (n.type === 'VariableDeclaration' && !n.isLocal) count++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return count;
    }

    countLocals(node) {
        let count = 0;
        
        const traverse = (n) => {
            if (!n) return;
            if (n.type === 'LocalStatement') count++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return count;
    }

    analyzeVariableReuse(node) {
        const usage = new Map();
        
        const traverse = (n) => {
            if (!n) return;
            
            if (n.type === 'Identifier' && n.name) {
                usage.set(n.name, (usage.get(n.name) || 0) + 1);
            }
            
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        
        const reuseCount = Array.from(usage.values()).filter(count => count > 1).length;
        const totalVariables = usage.size;
        
        return totalVariables > 0 ? reuseCount / totalVariables : 0;
    }

    /**
     * Extract lexical features
     */
    extractLexicalFeatures(sourceCode) {
        const tokens = this.tokenizer.tokenize(sourceCode || '');
        
        return {
            numTokens: tokens.length,
            avgTokenLength: this.calculateAvgTokenLength(tokens),
            uniqueTokenRatio: this.calculateUniqueRatio(tokens),
            keywordDensity: this.calculateKeywordDensity(tokens),
            commentDensity: this.calculateCommentDensity(sourceCode)
        };
    }

    calculateAvgTokenLength(tokens) {
        if (tokens.length === 0) return 0;
        const totalLength = tokens.reduce((sum, token) => sum + token.length, 0);
        return totalLength / tokens.length;
    }

    calculateUniqueRatio(tokens) {
        if (tokens.length === 0) return 0;
        const uniqueTokens = new Set(tokens);
        return uniqueTokens.size / tokens.length;
    }

    calculateKeywordDensity(tokens) {
        const keywords = new Set([
            'local', 'function', 'end', 'if', 'then', 'else', 'elseif',
            'while', 'do', 'for', 'repeat', 'until', 'return', 'break'
        ]);
        
        const keywordCount = tokens.filter(token => keywords.has(token.toLowerCase())).length;
        return tokens.length > 0 ? keywordCount / tokens.length : 0;
    }

    calculateCommentDensity(sourceCode) {
        if (!sourceCode) return 0;
        
        const lines = sourceCode.split('\n');
        const commentLines = lines.filter(line => line.trim().startsWith('--')).length;
        
        return lines.length > 0 ? commentLines / lines.length : 0;
    }

    /**
     * Extract structural features
     */
    extractStructuralFeatures(ast) {
        return {
            numFunctions: this.countFunctions(ast),
            numClasses: this.countTables(ast),
            avgFunctionLength: this.calculateAvgFunctionLength(ast),
            maxFunctionLength: this.calculateMaxFunctionLength(ast),
            functionCallRatio: this.calculateFunctionCallRatio(ast)
        };
    }

    countFunctions(node) {
        let count = 0;
        
        const traverse = (n) => {
            if (!n) return;
            if (n.type === 'FunctionDeclaration') count++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return count;
    }

    countTables(node) {
        let count = 0;
        
        const traverse = (n) => {
            if (!n) return;
            if (n.type === 'TableConstructorExpression') count++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return count;
    }

    calculateAvgFunctionLength(node) {
        const lengths = [];
        
        const traverse = (n) => {
            if (!n) return;
            
            if (n.type === 'FunctionDeclaration') {
                lengths.push(this.calculateNodeSize(n));
            }
            
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        
        return lengths.length > 0 ? lengths.reduce((sum, len) => sum + len, 0) / lengths.length : 0;
    }

    calculateMaxFunctionLength(node) {
        let maxLength = 0;
        
        const traverse = (n) => {
            if (!n) return;
            
            if (n.type === 'FunctionDeclaration') {
                maxLength = Math.max(maxLength, this.calculateNodeSize(n));
            }
            
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        
        return maxLength;
    }

    calculateNodeSize(node) {
        let size = 1;
        
        const traverse = (n) => {
            if (!n) return;
            size++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        
        return size;
    }

    calculateFunctionCallRatio(node) {
        const calls = this.countCalls(node);
        const statements = this.countStatements(node);
        
        return statements > 0 ? calls / statements : 0;
    }

    countCalls(node) {
        let count = 0;
        
        const traverse = (n) => {
            if (!n) return;
            if (n.type === 'CallExpression') count++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return count;
    }

    countStatements(node) {
        let count = 0;
        
        const traverse = (n) => {
            if (!n) return;
            if (n.type && n.type.includes('Statement')) count++;
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        return count;
    }

    /**
     * Extract semantic features
     */
    extractSemanticFeatures(ast) {
        return {
            apiUsagePatterns: this.analyzeAPIUsage(ast),
            errorHandlingScore: this.analyzeErrorHandling(ast),
            modularityScore: this.analyzeModularity(ast),
            namingQuality: this.analyzeNamingQuality(ast)
        };
    }

    analyzeAPIUsage(ast) {
        const apiCalls = this.extractAPICalls(ast);
        
        const patternScore = apiCalls.length > 0 ? 
            apiCalls.filter(call => call.frequency > 1).length / apiCalls.length : 0;
        
        return patternScore;
    }

    analyzeErrorHandling(ast) {
        let protectedCalls = 0;
        let totalCalls = 0;
        
        const traverse = (n) => {
            if (!n) return;
            
            if (n.type === 'CallExpression') {
                totalCalls++;
                if (this.isProtectedCall(n)) {
                    protectedCalls++;
                }
            }
            
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(ast);
        
        return totalCalls > 0 ? protectedCalls / totalCalls : 0;
    }

    isProtectedCall(node) {
        let parent = node.parent;
        while (parent) {
            if (parent.type === 'CallExpression' && parent.base) {
                if (parent.base.type === 'Identifier' && parent.base.name === 'pcall') {
                    return true;
                }
            }
            parent = parent.parent;
        }
        return false;
    }

    analyzeModularity(ast) {
        const functions = this.countFunctions(ast);
        const avgFuncLength = this.calculateAvgFunctionLength(ast);
        
        const modularityScore = functions > 0 && avgFuncLength > 0 ?
            Math.min(1, functions / (avgFuncLength / 10)) : 0;
        
        return modularityScore;
    }

    analyzeNamingQuality(ast) {
        const identifiers = [];
        
        const traverse = (n) => {
            if (!n) return;
            
            if (n.type === 'Identifier' && n.name) {
                identifiers.push(n.name);
            }
            
            if (n.body && Array.isArray(n.body)) {
                n.body.forEach(traverse);
            }
        };
        
        traverse(node);
        
        const descriptiveNames = identifiers.filter(name => 
            name.length > 2 && /[a-z]/i.test(name)
        ).length;
        
        return identifiers.length > 0 ? descriptiveNames / identifiers.length : 0;
    }

    /**
     * Normalize feature vector to fixed size
     */
    normalizeFeatures(features) {
        const vector = [];
        
        const flattenObject = (obj, prefix = '') => {
            for (const [key, value] of Object.entries(obj)) {
                if (typeof value === 'object' && !Array.isArray(value) && value !== null) {
                    flattenObject(value, `${prefix}${key}_`);
                } else if (Array.isArray(value)) {
                    for (let i = 0; i < Math.min(value.length, 10); i++) {
                        if (typeof value[i] === 'number') {
                            vector.push(value[i]);
                        } else if (typeof value[i] === 'boolean') {
                            vector.push(value[i] ? 1 : 0);
                        }
                    }
                } else if (typeof value === 'number') {
                    vector.push(value);
                } else if (typeof value === 'boolean') {
                    vector.push(value ? 1 : 0);
                }
            }
        };
        
        flattenObject(features);
        
        while (vector.length < CONFIG.FEATURE_VECTOR_SIZE) {
            vector.push(0);
        }
        
        return vector.slice(0, CONFIG.FEATURE_VECTOR_SIZE);
    }
}

// ============================================================================
// ML MODEL CLASSES
// ============================================================================

class PatternRecognitionModel {
    constructor() {
        this.model = null;
        this.isLoaded = false;
        this.featureExtractor = new FeatureExtractor();
    }

    /**
     * Build neural network model for pattern recognition
     */
    buildModel() {
        const model = tf.sequential();
        
        // Input layer
        model.add(tf.layers.dense({
            inputShape: [CONFIG.FEATURE_VECTOR_SIZE],
            units: 512,
            activation: 'relu',
            kernelInitializer: 'heNormal'
        }));
        
        model.add(tf.layers.dropout({ rate: 0.3 }));
        
        // Hidden layers
        model.add(tf.layers.dense({
            units: 256,
            activation: 'relu',
            kernelInitializer: 'heNormal'
        }));
        
        model.add(tf.layers.dropout({ rate: 0.3 }));
        
        model.add(tf.layers.dense({
            units: 128,
            activation: 'relu',
            kernelInitializer: 'heNormal'
        }));
        
        model.add(tf.layers.dropout({ rate: 0.2 }));
        
        // Output layer - multi-class classification
        model.add(tf.layers.dense({
            units: 10,
            activation: 'softmax'
        }));
        
        // Compile model
        model.compile({
            optimizer: tf.train.adam(CONFIG.LEARNING_RATE),
            loss: 'categoricalCrossentropy',
            metrics: ['accuracy', 'precision', 'recall']
        });
        
        this.model = model;
        return model;
    }

    /**
     * Train model on dataset
     */
    async train(trainingData, validationData) {
        if (!this.model) {
            this.buildModel();
        }
        
        const xs = tf.tensor2d(trainingData.features);
        const ys = tf.tensor2d(trainingData.labels);
        
        const valXs = validationData ? tf.tensor2d(validationData.features) : null;
        const valYs = validationData ? tf.tensor2d(validationData.labels) : null;
        
        const history = await this.model.fit(xs, ys, {
            batchSize: CONFIG.BATCH_SIZE,
            epochs: CONFIG.EPOCHS,
            validationData: validationData ? [valXs, valYs] : null,
            callbacks: {
                onEpochEnd: (epoch, logs) => {
                    console.log(`Epoch ${epoch + 1}: loss = ${logs.loss.toFixed(4)}, accuracy = ${logs.acc.toFixed(4)}`);
                }
            }
        });
        
        xs.dispose();
        ys.dispose();
        if (valXs) valXs.dispose();
        if (valYs) valYs.dispose();
        
        return history;
    }

    /**
     * Predict pattern for given AST
     */
    async predict(ast) {
        if (!this.model) {
            throw new Error('Model not loaded or trained');
        }
        
        const features = this.featureExtractor.extractASTFeatures(ast);
        const inputTensor = tf.tensor2d([features]);
        
        const prediction = this.model.predict(inputTensor);
        const probabilities = await prediction.array();
        
        inputTensor.dispose();
        prediction.dispose();
        
        const patternClasses = [
            'EntityManipulation',
            'EventHandling',
            'DataManagement',
            'Rendering',
            'NetworkCommunication',
            'ResourceProcessing',
            'UIInteraction',
            'PerformanceOptimization',
            'ErrorHandling',
            'CustomLogic'
        ];
        
        const results = probabilities[0].map((prob, idx) => ({
            pattern: patternClasses[idx],
            confidence: prob
        }));
        
        results.sort((a, b) => b.confidence - a.confidence);
        
        return results.filter(r => r.confidence >= CONFIG.MIN_CONFIDENCE);
    }

    /**
     * Save model to disk
     */
    async save(modelPath) {
        if (!this.model) {
            throw new Error('No model to save');
        }
        
        await fs.ensureDir(CONFIG.MODEL_DIR);
        const savePath = path.join(CONFIG.MODEL_DIR, modelPath);
        await this.model.save(`file://${savePath}`);
        
        console.log(`Model saved to ${savePath}`);
    }

    /**
     * Load model from disk
     */
    async load(modelPath) {
        const loadPath = path.join(CONFIG.MODEL_DIR, modelPath);
        
        if (await fs.pathExists(loadPath)) {
            this.model = await tf.loadLayersModel(`file://${loadPath}/model.json`);
            this.isLoaded = true;
            console.log(`Model loaded from ${loadPath}`);
        } else {
            throw new Error(`Model not found at ${loadPath}`);
        }
    }
}

// ============================================================================
// ANOMALY DETECTION
// ============================================================================

class AnomalyDetector {
    constructor() {
        this.autoencoder = null;
        this.threshold = 0.1;
    }

    /**
     * Build autoencoder for anomaly detection
     */
    buildAutoencoder() {
        const inputLayer = tf.input({ shape: [CONFIG.FEATURE_VECTOR_SIZE] });
        
        // Encoder
        let encoded = tf.layers.dense({ units: 128, activation: 'relu' }).apply(inputLayer);
        encoded = tf.layers.dense({ units: 64, activation: 'relu' }).apply(encoded);
        encoded = tf.layers.dense({ units: 32, activation: 'relu' }).apply(encoded);
        
        // Decoder
        let decoded = tf.layers.dense({ units: 64, activation: 'relu' }).apply(encoded);
        decoded = tf.layers.dense({ units: 128, activation: 'relu' }).apply(decoded);
        decoded = tf.layers.dense({ units: CONFIG.FEATURE_VECTOR_SIZE, activation: 'sigmoid' }).apply(decoded);
        
        this.autoencoder = tf.model({ inputs: inputLayer, outputs: decoded });
        
        this.autoencoder.compile({
            optimizer: 'adam',
            loss: 'meanSquaredError'
        });
    }

    /**
     * Train autoencoder
     */
    async train(normalData) {
        if (!this.autoencoder) {
            this.buildAutoencoder();
        }
        
        const xs = tf.tensor2d(normalData);
        
        await this.autoencoder.fit(xs, xs, {
            batchSize: CONFIG.BATCH_SIZE,
            epochs: 30,
            shuffle: true
        });
        
        xs.dispose();
    }

    /**
     * Detect anomalies
     */
    async detectAnomaly(features) {
        if (!this.autoencoder) {
            throw new Error('Autoencoder not trained');
        }
        
        const inputTensor = tf.tensor2d([features]);
        const reconstruction = this.autoencoder.predict(inputTensor);
        
        const mse = tf.losses.meanSquaredError(inputTensor, reconstruction);
        const mseValue = await mse.data();
        
        inputTensor.dispose();
        reconstruction.dispose();
        mse.dispose();
        
        const isAnomaly = mseValue[0] > this.threshold;
        
        return {
            isAnomaly,
            score: mseValue[0],
            threshold: this.threshold
        };
    }
}

// ============================================================================
// CODE QUALITY PREDICTOR
// ============================================================================

class CodeQualityPredictor {
    constructor() {
        this.model = null;
        this.featureExtractor = new FeatureExtractor();
    }

    /**
     * Build regression model for code quality prediction
     */
    buildModel() {
        const model = tf.sequential();
        
        model.add(tf.layers.dense({
            inputShape: [CONFIG.FEATURE_VECTOR_SIZE],
            units: 256,
            activation: 'relu'
        }));
        
        model.add(tf.layers.dropout({ rate: 0.2 }));
        
        model.add(tf.layers.dense({
            units: 128,
            activation: 'relu'
        }));
        
        model.add(tf.layers.dropout({ rate: 0.2 }));
        
        model.add(tf.layers.dense({
            units: 64,
            activation: 'relu'
        }));
        
        // Output: quality score 0-100
        model.add(tf.layers.dense({
            units: 1,
            activation: 'sigmoid'
        }));
        
        model.compile({
            optimizer: 'adam',
            loss: 'meanSquaredError',
            metrics: ['mae']
        });
        
        this.model = model;
    }

    /**
     * Predict code quality score
     */
    async predictQuality(ast) {
        if (!this.model) {
            this.buildModel();
        }
        
        const features = this.featureExtractor.extractASTFeatures(ast);
        const inputTensor = tf.tensor2d([features]);
        
        const prediction = this.model.predict(inputTensor);
        const qualityScore = await prediction.data();
        
        inputTensor.dispose();
        prediction.dispose();
        
        return Math.round(qualityScore[0] * 100);
    }
}

// ============================================================================
// ML ENGINE MAIN CLASS
// ============================================================================

class MLEngine {
    constructor() {
        this.patternRecognizer = new PatternRecognitionModel();
        this.anomalyDetector = new AnomalyDetector();
        this.qualityPredictor = new CodeQualityPredictor();
        this.cache = new Map();
    }

    /**
     * Initialize ML engine
     */
    async initialize() {
        try {
            await this.patternRecognizer.load('pattern_recognition');
            await this.anomalyDetector.autoencoder?.load('anomaly_detection');
            console.log('ML Engine initialized successfully');
        } catch (error) {
            console.log('No pre-trained models found, will need training');
        }
    }

    /**
     * Analyze code with full ML pipeline
     */
    async analyzeCode(ast, sourceCode) {
        const cacheKey = this.generateCacheKey(ast);
        
        if (this.cache.has(cacheKey)) {
            return this.cache.get(cacheKey);
        }
        
        const startTime = Date.now();
        
        const [patterns, anomaly, quality] = await Promise.all([
            this.patternRecognizer.predict(ast),
            this.detectAnomaly(ast),
            this.qualityPredictor.predictQuality(ast)
        ]);
        
        const inferenceTime = Date.now() - startTime;
        
        const result = {
            patterns,
            anomaly,
            quality,
            inferenceTime,
            timestamp: new Date().toISOString()
        };
        
        if (this.cache.size < CONFIG.PATTERN_CACHE_SIZE) {
            this.cache.set(cacheKey, result);
        }
        
        return result;
    }

    /**
     * Detect anomalies in code
     */
    async detectAnomaly(ast) {
        const features = this.patternRecognizer.featureExtractor.extractASTFeatures(ast);
        return await this.anomalyDetector.detectAnomaly(features);
    }

    /**
     * Generate cache key
     */
    generateCacheKey(ast) {
        const astString = JSON.stringify(ast);
        return require('crypto').createHash('md5').update(astString).digest('hex');
    }

    /**
     * Clear cache
     */
    clearCache() {
        this.cache.clear();
    }

    /**
     * Get statistics
     */
    getStatistics() {
        return {
            cacheSize: this.cache.size,
            cacheLimit: CONFIG.PATTERN_CACHE_SIZE,
            modelsLoaded: {
                patternRecognition: this.patternRecognizer.isLoaded,
                anomalyDetection: !!this.anomalyDetector.autoencoder,
                qualityPrediction: !!this.qualityPredictor.model
            }
        };
    }
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
    MLEngine,
    PatternRecognitionModel,
    AnomalyDetector,
    CodeQualityPredictor,
    FeatureExtractor,
    CONFIG
};

// Example usage
if (require.main === module) {
    (async () => {
        const engine = new MLEngine();
        await engine.initialize();
        
        console.log('ML Pattern Recognition Engine ready');
        console.log('Statistics:', engine.getStatistics());
    })();
}
