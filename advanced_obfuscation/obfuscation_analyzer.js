/**
 * Advanced Obfuscation Analyzer for Factorio Lua
 * Phase 8: Control Flow Graph Based Deobfuscation
 * 
 * Reference: https://en.wikipedia.org/wiki/Control_flow_graph
 * Reference: https://en.wikipedia.org/wiki/Data-flow_analysis
 * Reference: https://github.com/java-deobfuscator/deobfuscator
 */

const { Graph, alg } = require('graphlib');
const _ = require('lodash');
const crypto = require('crypto');

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG = {
    MAX_CFG_NODES: 10000,
    MAX_DFA_ITERATIONS: 100,
    ENTROPY_THRESHOLD: 4.5,
    STRING_OBFUSCATION_THRESHOLD: 0.7,
    CONTROL_FLOW_COMPLEXITY_THRESHOLD: 20,
    VARIABLE_RENAME_PATTERN: /^[a-zA-Z_][a-zA-Z0-9_]{0,2}$/
};

// ============================================================================
// CONTROL FLOW GRAPH BUILDER
// ============================================================================

class ControlFlowGraphBuilder {
    constructor() {
        this.graph = new Graph({ directed: true });
        this.nodeCounter = 0;
        this.basicBlocks = new Map();
    }

    /**
     * Build CFG from AST
     */
    buildCFG(ast) {
        const entryNode = this.createNode('entry', 'Entry');
        const exitNode = this.createNode('exit', 'Exit');
        
        this.processNode(ast, entryNode, exitNode);
        
        return {
            graph: this.graph,
            entry: entryNode,
            exit: exitNode,
            basicBlocks: Array.from(this.basicBlocks.values())
        };
    }

    /**
     * Create new CFG node
     */
    createNode(type, label = '') {
        const nodeId = `node_${this.nodeCounter++}`;
        
        this.graph.setNode(nodeId, {
            id: nodeId,
            type,
            label: label || type,
            statements: [],
            predecessors: [],
            successors: []
        });
        
        return nodeId;
    }

    /**
     * Add edge between nodes
     */
    addEdge(from, to, label = '') {
        if (!this.graph.hasNode(from) || !this.graph.hasNode(to)) {
            return;
        }
        
        this.graph.setEdge(from, to, { label });
        
        const fromNode = this.graph.node(from);
        const toNode = this.graph.node(to);
        
        if (!fromNode.successors.includes(to)) {
            fromNode.successors.push(to);
        }
        
        if (!toNode.predecessors.includes(from)) {
            toNode.predecessors.push(from);
        }
    }

    /**
     * Process AST node and build CFG
     */
    processNode(node, entryNode, exitNode) {
        if (!node) return entryNode;
        
        switch (node.type) {
            case 'Program':
            case 'Chunk':
                return this.processChunk(node, entryNode, exitNode);
            
            case 'IfStatement':
                return this.processIfStatement(node, entryNode, exitNode);
            
            case 'WhileStatement':
                return this.processWhileStatement(node, entryNode, exitNode);
            
            case 'ForStatement':
                return this.processForStatement(node, entryNode, exitNode);
            
            case 'FunctionDeclaration':
                return this.processFunctionDeclaration(node, entryNode, exitNode);
            
            case 'ReturnStatement':
                return this.processReturnStatement(node, entryNode, exitNode);
            
            default:
                return this.processStatement(node, entryNode, exitNode);
        }
    }

    processChunk(node, entryNode, exitNode) {
        let currentNode = entryNode;
        
        if (node.body && Array.isArray(node.body)) {
            for (const statement of node.body) {
                const nextNode = this.processNode(statement, currentNode, exitNode);
                if (nextNode !== currentNode) {
                    this.addEdge(currentNode, nextNode);
                    currentNode = nextNode;
                }
            }
        }
        
        this.addEdge(currentNode, exitNode);
        return exitNode;
    }

    processIfStatement(node, entryNode, exitNode) {
        const conditionNode = this.createNode('condition', 'If Condition');
        this.addEdge(entryNode, conditionNode);
        
        const thenNode = this.createNode('block', 'Then Block');
        this.addEdge(conditionNode, thenNode, 'true');
        
        let elseNode = null;
        if (node.alternate) {
            elseNode = this.createNode('block', 'Else Block');
            this.addEdge(conditionNode, elseNode, 'false');
        }
        
        const mergeNode = this.createNode('merge', 'Merge');
        
        if (node.consequent) {
            const thenExit = this.processNode(node.consequent, thenNode, mergeNode);
            this.addEdge(thenExit, mergeNode);
        } else {
            this.addEdge(thenNode, mergeNode);
        }
        
        if (elseNode) {
            const elseExit = this.processNode(node.alternate, elseNode, mergeNode);
            this.addEdge(elseExit, mergeNode);
        } else {
            this.addEdge(conditionNode, mergeNode, 'false');
        }
        
        return mergeNode;
    }

    processWhileStatement(node, entryNode, exitNode) {
        const conditionNode = this.createNode('condition', 'While Condition');
        this.addEdge(entryNode, conditionNode);
        
        const bodyNode = this.createNode('block', 'Loop Body');
        this.addEdge(conditionNode, bodyNode, 'true');
        
        const loopExit = this.processNode(node.body, bodyNode, conditionNode);
        this.addEdge(loopExit, conditionNode);
        
        const afterLoop = this.createNode('block', 'After Loop');
        this.addEdge(conditionNode, afterLoop, 'false');
        
        return afterLoop;
    }

    processForStatement(node, entryNode, exitNode) {
        const initNode = this.createNode('statement', 'For Init');
        this.addEdge(entryNode, initNode);
        
        const conditionNode = this.createNode('condition', 'For Condition');
        this.addEdge(initNode, conditionNode);
        
        const bodyNode = this.createNode('block', 'For Body');
        this.addEdge(conditionNode, bodyNode, 'true');
        
        const updateNode = this.createNode('statement', 'For Update');
        this.addEdge(bodyNode, updateNode);
        this.addEdge(updateNode, conditionNode);
        
        const afterLoop = this.createNode('block', 'After For');
        this.addEdge(conditionNode, afterLoop, 'false');
        
        return afterLoop;
    }

    processFunctionDeclaration(node, entryNode, exitNode) {
        const funcNode = this.createNode('function', 
            node.identifier ? `Function: ${node.identifier.name}` : 'Anonymous Function');
        
        this.addEdge(entryNode, funcNode);
        
        const funcExit = this.createNode('function_exit', 'Function Exit');
        
        if (node.body) {
            this.processNode(node.body, funcNode, funcExit);
        } else {
            this.addEdge(funcNode, funcExit);
        }
        
        return funcExit;
    }

    processReturnStatement(node, entryNode, exitNode) {
        const returnNode = this.createNode('return', 'Return');
        this.addEdge(entryNode, returnNode);
        this.addEdge(returnNode, exitNode);
        
        return returnNode;
    }

    processStatement(node, entryNode, exitNode) {
        const stmtNode = this.createNode('statement', node.type || 'Statement');
        this.addEdge(entryNode, stmtNode);
        
        return stmtNode;
    }

    /**
     * Calculate CFG metrics
     */
    calculateMetrics() {
        const nodes = this.graph.nodes();
        const edges = this.graph.edges();
        
        // Calculate cyclomatic complexity: M = E - N + 2P
        // where E = edges, N = nodes, P = connected components
        const components = alg.components(this.graph).length;
        const cyclomaticComplexity = edges.length - nodes.length + 2 * components;
        
        return {
            nodes: nodes.length,
            edges: edges.length,
            cyclomaticComplexity,
            maxDepth: this.calculateMaxDepth(),
            avgBranchingFactor: nodes.length > 0 ? edges.length / nodes.length : 0
        };
    }

    calculateMaxDepth() {
        const entryNodes = this.graph.nodes().filter(n => {
            const node = this.graph.node(n);
            return node.type === 'entry';
        });
        
        if (entryNodes.length === 0) return 0;
        
        let maxDepth = 0;
        
        const dfs = (nodeId, depth) => {
            maxDepth = Math.max(maxDepth, depth);
            
            const successors = this.graph.successors(nodeId) || [];
            for (const successor of successors) {
                dfs(successor, depth + 1);
            }
        };
        
        dfs(entryNodes[0], 0);
        return maxDepth;
    }
}

// ============================================================================
// DATA FLOW ANALYZER
// ============================================================================

class DataFlowAnalyzer {
    constructor(cfg) {
        this.cfg = cfg;
        this.reachingDefinitions = new Map();
        this.liveVariables = new Map();
    }

    /**
     * Perform reaching definitions analysis
     */
    analyzeReachingDefinitions() {
        const workList = [...this.cfg.graph.nodes()];
        const gen = new Map();
        const kill = new Map();
        const inSets = new Map();
        const outSets = new Map();
        
        // Initialize gen and kill sets
        for (const nodeId of workList) {
            const node = this.cfg.graph.node(nodeId);
            gen.set(nodeId, this.computeGen(node));
            kill.set(nodeId, this.computeKill(node));
            inSets.set(nodeId, new Set());
            outSets.set(nodeId, new Set());
        }
        
        // Iterative dataflow analysis
        let changed = true;
        let iterations = 0;
        
        while (changed && iterations < CONFIG.MAX_DFA_ITERATIONS) {
            changed = false;
            iterations++;
            
            for (const nodeId of workList) {
                // IN[n] = ∪ OUT[p] for all predecessors p
                const inSet = new Set();
                const predecessors = this.cfg.graph.predecessors(nodeId) || [];
                
                for (const pred of predecessors) {
                    const predOut = outSets.get(pred);
                    if (predOut) {
                        for (const def of predOut) {
                            inSet.add(def);
                        }
                    }
                }
                
                // OUT[n] = GEN[n] ∪ (IN[n] - KILL[n])
                const outSet = new Set(gen.get(nodeId));
                for (const def of inSet) {
                    if (!kill.get(nodeId).has(def)) {
                        outSet.add(def);
                    }
                }
                
                // Check if OUT set changed
                const oldOutSet = outSets.get(nodeId);
                if (!this.setsEqual(outSet, oldOutSet)) {
                    changed = true;
                    outSets.set(nodeId, outSet);
                }
                
                inSets.set(nodeId, inSet);
            }
        }
        
        this.reachingDefinitions = { inSets, outSets, iterations };
        return this.reachingDefinitions;
    }

    computeGen(node) {
        const gen = new Set();
        
        if (node.statements) {
            for (const stmt of node.statements) {
                if (stmt.type === 'AssignmentStatement' && stmt.variables) {
                    for (const variable of stmt.variables) {
                        gen.add(`${variable.name}@${node.id}`);
                    }
                }
            }
        }
        
        return gen;
    }

    computeKill(node) {
        const kill = new Set();
        
        if (node.statements) {
            for (const stmt of node.statements) {
                if (stmt.type === 'AssignmentStatement' && stmt.variables) {
                    for (const variable of stmt.variables) {
                        // Kill all other definitions of this variable
                        for (const otherNode of this.cfg.graph.nodes()) {
                            if (otherNode !== node.id) {
                                kill.add(`${variable.name}@${otherNode}`);
                            }
                        }
                    }
                }
            }
        }
        
        return kill;
    }

    /**
     * Perform live variable analysis
     */
    analyzeLiveVariables() {
        const workList = [...this.cfg.graph.nodes()].reverse();
        const use = new Map();
        const def = new Map();
        const inSets = new Map();
        const outSets = new Map();
        
        // Initialize use and def sets
        for (const nodeId of workList) {
            const node = this.cfg.graph.node(nodeId);
            use.set(nodeId, this.computeUse(node));
            def.set(nodeId, this.computeDef(node));
            inSets.set(nodeId, new Set());
            outSets.set(nodeId, new Set());
        }
        
        // Backward dataflow analysis
        let changed = true;
        let iterations = 0;
        
        while (changed && iterations < CONFIG.MAX_DFA_ITERATIONS) {
            changed = false;
            iterations++;
            
            for (const nodeId of workList) {
                // OUT[n] = ∪ IN[s] for all successors s
                const outSet = new Set();
                const successors = this.cfg.graph.successors(nodeId) || [];
                
                for (const succ of successors) {
                    const succIn = inSets.get(succ);
                    if (succIn) {
                        for (const variable of succIn) {
                            outSet.add(variable);
                        }
                    }
                }
                
                // IN[n] = USE[n] ∪ (OUT[n] - DEF[n])
                const inSet = new Set(use.get(nodeId));
                for (const variable of outSet) {
                    if (!def.get(nodeId).has(variable)) {
                        inSet.add(variable);
                    }
                }
                
                // Check if IN set changed
                const oldInSet = inSets.get(nodeId);
                if (!this.setsEqual(inSet, oldInSet)) {
                    changed = true;
                    inSets.set(nodeId, inSet);
                }
                
                outSets.set(nodeId, outSet);
            }
        }
        
        this.liveVariables = { inSets, outSets, iterations };
        return this.liveVariables;
    }

    computeUse(node) {
        const use = new Set();
        
        if (node.statements) {
            for (const stmt of node.statements) {
                // Simplified: extract identifiers
                this.extractIdentifiers(stmt, use);
            }
        }
        
        return use;
    }

    computeDef(node) {
        const def = new Set();
        
        if (node.statements) {
            for (const stmt of node.statements) {
                if (stmt.type === 'AssignmentStatement' && stmt.variables) {
                    for (const variable of stmt.variables) {
                        def.add(variable.name);
                    }
                }
            }
        }
        
        return def;
    }

    extractIdentifiers(node, identifiers) {
        if (!node) return;
        
        if (node.type === 'Identifier' && node.name) {
            identifiers.add(node.name);
        }
        
        if (node.body && Array.isArray(node.body)) {
            for (const child of node.body) {
                this.extractIdentifiers(child, identifiers);
            }
        }
        
        if (node.arguments && Array.isArray(node.arguments)) {
            for (const arg of node.arguments) {
                this.extractIdentifiers(arg, identifiers);
            }
        }
    }

    setsEqual(set1, set2) {
        if (set1.size !== set2.size) return false;
        
        for (const item of set1) {
            if (!set2.has(item)) return false;
        }
        
        return true;
    }
}

// ============================================================================
// STRING DEOBFUSCATOR
// ============================================================================

class StringDeobfuscator {
    constructor() {
        this.patterns = [
            // Common Lua obfuscation patterns
            { name: 'char_concat', regex: /string\.char\(([^)]+)\)/g },
            { name: 'byte_array', regex: /\{([0-9,\s]+)\}/g },
            { name: 'hex_escape', regex: /\\x([0-9a-fA-F]{2})/g },
            { name: 'unicode_escape', regex: /\\u\{([0-9a-fA-F]+)\}/g }
        ];
    }

    /**
     * Attempt to deobfuscate strings
     */
    deobfuscate(source) {
        let deobfuscated = source;
        const replacements = [];
        
        for (const pattern of this.patterns) {
            const matches = [...source.matchAll(pattern.regex)];
            
            for (const match of matches) {
                try {
                    const decoded = this.decodePattern(pattern.name, match);
                    
                    if (decoded) {
                        replacements.push({
                            original: match[0],
                            decoded,
                            pattern: pattern.name,
                            position: match.index
                        });
                        
                        deobfuscated = deobfuscated.replace(match[0], `"${decoded}"`);
                    }
                } catch (error) {
                    // Skip if decoding fails
                }
            }
        }
        
        return {
            source: deobfuscated,
            replacements,
            deobfuscationRate: replacements.length / Math.max(1, this.patterns.length)
        };
    }

    decodePattern(patternName, match) {
        switch (patternName) {
            case 'char_concat':
                return this.decodeCharConcat(match[1]);
            
            case 'byte_array':
                return this.decodeByteArray(match[1]);
            
            case 'hex_escape':
                return String.fromCharCode(parseInt(match[1], 16));
            
            case 'unicode_escape':
                return String.fromCodePoint(parseInt(match[1], 16));
            
            default:
                return null;
        }
    }

    decodeCharConcat(charCodes) {
        const codes = charCodes.split(',').map(s => parseInt(s.trim()));
        return String.fromCharCode(...codes);
    }

    decodeByteArray(byteString) {
        const bytes = byteString.split(',').map(s => parseInt(s.trim()));
        return String.fromCharCode(...bytes);
    }

    /**
     * Calculate entropy of string
     */
    calculateEntropy(str) {
        if (!str || str.length === 0) return 0;
        
        const frequency = new Map();
        
        for (const char of str) {
            frequency.set(char, (frequency.get(char) || 0) + 1);
        }
        
        let entropy = 0;
        
        for (const count of frequency.values()) {
            const probability = count / str.length;
            entropy -= probability * Math.log2(probability);
        }
        
        return entropy;
    }

    /**
     * Detect obfuscated strings by entropy
     */
    detectObfuscatedStrings(source) {
        const stringPattern = /"([^"]*)"|'([^']*)'/g;
        const matches = [...source.matchAll(stringPattern)];
        const obfuscated = [];
        
        for (const match of matches) {
            const str = match[1] || match[2];
            const entropy = this.calculateEntropy(str);
            
            if (entropy > CONFIG.ENTROPY_THRESHOLD) {
                obfuscated.push({
                    string: str,
                    entropy,
                    position: match.index,
                    isObfuscated: true
                });
            }
        }
        
        return obfuscated;
    }
}

// ============================================================================
// OBFUSCATION DETECTOR
// ============================================================================

class ObfuscationDetector {
    constructor() {
        this.stringDeobfuscator = new StringDeobfuscator();
    }

    /**
     * Detect obfuscation in source code
     */
    detectObfuscation(source, ast) {
        const detectionResults = {
            isObfuscated: false,
            obfuscationScore: 0,
            techniques: [],
            confidence: 0
        };
        
        // Check for various obfuscation techniques
        const checks = [
            this.checkVariableRenaming(ast),
            this.checkControlFlowFlattening(ast),
            this.checkStringObfuscation(source),
            this.checkDeadCodeInjection(ast),
            this.checkConstantFolding(ast)
        ];
        
        for (const check of checks) {
            if (check.detected) {
                detectionResults.techniques.push(check);
                detectionResults.obfuscationScore += check.score;
            }
        }
        
        detectionResults.obfuscationScore = Math.min(100, detectionResults.obfuscationScore);
        detectionResults.isObfuscated = detectionResults.obfuscationScore > 50;
        detectionResults.confidence = this.calculateConfidence(checks);
        
        return detectionResults;
    }

    checkVariableRenaming(ast) {
        const identifiers = [];
        
        const collectIdentifiers = (node) => {
            if (!node) return;
            
            if (node.type === 'Identifier' && node.name) {
                identifiers.push(node.name);
            }
            
            if (node.body && Array.isArray(node.body)) {
                node.body.forEach(collectIdentifiers);
            }
        };
        
        collectIdentifiers(ast);
        
        const shortNames = identifiers.filter(name => 
            CONFIG.VARIABLE_RENAME_PATTERN.test(name)
        ).length;
        
        const renameRatio = identifiers.length > 0 ? shortNames / identifiers.length : 0;
        
        return {
            technique: 'Variable Renaming',
            detected: renameRatio > 0.5,
            score: renameRatio * 30,
            details: {
                totalIdentifiers: identifiers.length,
                shortNames,
                renameRatio
            }
        };
    }

    checkControlFlowFlattening(ast) {
        const cfgBuilder = new ControlFlowGraphBuilder();
        const cfg = cfgBuilder.buildCFG(ast);
        const metrics = cfgBuilder.calculateMetrics();
        
        const isFlattened = metrics.cyclomaticComplexity > CONFIG.CONTROL_FLOW_COMPLEXITY_THRESHOLD;
        
        return {
            technique: 'Control Flow Flattening',
            detected: isFlattened,
            score: isFlattened ? 25 : 0,
            details: metrics
        };
    }

    checkStringObfuscation(source) {
        const obfuscatedStrings = this.stringDeobfuscator.detectObfuscatedStrings(source);
        const stringPattern = /"[^"]*"|'[^']*'/g;
        const totalStrings = (source.match(stringPattern) || []).length;
        
        const obfuscationRatio = totalStrings > 0 ? 
            obfuscatedStrings.length / totalStrings : 0;
        
        return {
            technique: 'String Obfuscation',
            detected: obfuscationRatio > CONFIG.STRING_OBFUSCATION_THRESHOLD,
            score: obfuscationRatio * 35,
            details: {
                totalStrings,
                obfuscatedStrings: obfuscatedStrings.length,
                obfuscationRatio
            }
        };
    }

    checkDeadCodeInjection(ast) {
        let unreachableBlocks = 0;
        let totalBlocks = 0;
        
        const checkReachability = (node) => {
            if (!node) return;
            
            if (node.type === 'IfStatement') {
                totalBlocks++;
                
                if (node.test && node.test.type === 'Literal') {
                    if (node.test.value === false && node.consequent) {
                        unreachableBlocks++;
                    }
                    if (node.test.value === true && node.alternate) {
                        unreachableBlocks++;
                    }
                }
            }
            
            if (node.body && Array.isArray(node.body)) {
                node.body.forEach(checkReachability);
            }
        };
        
        checkReachability(ast);
        
        const deadCodeRatio = totalBlocks > 0 ? unreachableBlocks / totalBlocks : 0;
        
        return {
            technique: 'Dead Code Injection',
            detected: deadCodeRatio > 0.1,
            score: deadCodeRatio * 20,
            details: {
                totalBlocks,
                unreachableBlocks,
                deadCodeRatio
            }
        };
    }

    checkConstantFolding(ast) {
        let constantExpressions = 0;
        let totalExpressions = 0;
        
        const checkExpressions = (node) => {
            if (!node) return;
            
            if (node.type === 'BinaryExpression') {
                totalExpressions++;
                
                if (node.left && node.left.type === 'Literal' && 
                    node.right && node.right.type === 'Literal') {
                    constantExpressions++;
                }
            }
            
            if (node.body && Array.isArray(node.body)) {
                node.body.forEach(checkExpressions);
            }
        };
        
        checkExpressions(ast);
        
        const constantRatio = totalExpressions > 0 ? 
            constantExpressions / totalExpressions : 0;
        
        return {
            technique: 'Constant Folding',
            detected: constantRatio > 0.3,
            score: constantRatio * 15,
            details: {
                totalExpressions,
                constantExpressions,
                constantRatio
            }
        };
    }

    calculateConfidence(checks) {
        const detectedCount = checks.filter(c => c.detected).length;
        return (detectedCount / checks.length) * 100;
    }
}

// ============================================================================
// OBFUSCATION ANALYZER MAIN CLASS
// ============================================================================

class ObfuscationAnalyzer {
    constructor() {
        this.cfgBuilder = new ControlFlowGraphBuilder();
        this.stringDeobfuscator = new StringDeobfuscator();
        this.detector = new ObfuscationDetector();
    }

    /**
     * Analyze code for obfuscation
     */
    async analyze(source, ast) {
        const startTime = Date.now();
        
        // Build CFG
        const cfg = this.cfgBuilder.buildCFG(ast);
        const cfgMetrics = this.cfgBuilder.calculateMetrics();
        
        // Perform data flow analysis
        const dfaAnalyzer = new DataFlowAnalyzer(cfg);
        const reachingDefs = dfaAnalyzer.analyzeReachingDefinitions();
        const liveVars = dfaAnalyzer.analyzeLiveVariables();
        
        // Detect obfuscation
        const detection = this.detector.detectObfuscation(source, ast);
        
        // Attempt string deobfuscation
        const deobfuscation = this.stringDeobfuscator.deobfuscate(source);
        
        const analysisTime = Date.now() - startTime;
        
        return {
            controlFlowGraph: {
                nodes: cfg.graph.nodes().length,
                edges: cfg.graph.edges().length,
                metrics: cfgMetrics
            },
            dataFlowAnalysis: {
                reachingDefinitions: {
                    iterations: reachingDefs.iterations,
                    converged: reachingDefs.iterations < CONFIG.MAX_DFA_ITERATIONS
                },
                liveVariables: {
                    iterations: liveVars.iterations,
                    converged: liveVars.iterations < CONFIG.MAX_DFA_ITERATIONS
                }
            },
            obfuscationDetection: detection,
            deobfuscation,
            analysisTime,
            timestamp: new Date().toISOString()
        };
    }

    /**
     * Get analysis statistics
     */
    getStatistics() {
        return {
            cfgNodesLimit: CONFIG.MAX_CFG_NODES,
            dfaIterationsLimit: CONFIG.MAX_DFA_ITERATIONS,
            entropyThreshold: CONFIG.ENTROPY_THRESHOLD,
            stringObfuscationThreshold: CONFIG.STRING_OBFUSCATION_THRESHOLD
        };
    }
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
    ObfuscationAnalyzer,
    ControlFlowGraphBuilder,
    DataFlowAnalyzer,
    StringDeobfuscator,
    ObfuscationDetector,
    CONFIG
};

// Example usage
if (require.main === module) {
    (async () => {
        const analyzer = new ObfuscationAnalyzer();
        
        const testCode = `
            local function obfuscated()
                local a = string.char(72, 101, 108, 108, 111)
                if false then
                    game.print("Dead code")
                end
                local b = 10 + 20
                return a
            end
        `;
        
        // Simplified AST for testing
        const testAST = {
            type: 'Program',
            body: []
        };
        
        console.log('Analyzing code for obfuscation...');
        const result = await analyzer.analyze(testCode, testAST);
        
        console.log('\nAnalysis Results:');
        console.log(JSON.stringify(result, null, 2));
    })();
}
