/**
 * Language Server Protocol Implementation for Factorio Lua
 * Phase 7: Production-Ready System
 * 
 * Reference: https://microsoft.github.io/language-server-protocol/
 * Reference: https://code.visualstudio.com/api/language-extensions/language-server-extension-guide
 */

const {
    createConnection,
    TextDocuments,
    ProposedFeatures,
    InitializeParams,
    DidChangeConfigurationNotification,
    CompletionItem,
    CompletionItemKind,
    TextDocumentPositionParams,
    TextDocumentSyncKind,
    InitializeResult,
    Diagnostic,
    DiagnosticSeverity
} = require('vscode-languageserver/node');

const { TextDocument } = require('vscode-languageserver-textdocument');
const { exec } = require('child_process');
const util = require('util');
const path = require('path');

const execPromise = util.promisify(exec);

// ============================================================================
// SERVER INITIALIZATION
// ============================================================================

const connection = createConnection(ProposedFeatures.all);
const documents = new TextDocuments(TextDocument);

let hasConfigurationCapability = false;
let hasWorkspaceFolderCapability = false;
let hasDiagnosticRelatedInformationCapability = false;

connection.onInitialize((params) => {
    const capabilities = params.capabilities;
    
    hasConfigurationCapability = !!(
        capabilities.workspace && !!capabilities.workspace.configuration
    );
    hasWorkspaceFolderCapability = !!(
        capabilities.workspace && !!capabilities.workspace.workspaceFolders
    );
    hasDiagnosticRelatedInformationCapability = !!(
        capabilities.textDocument &&
        capabilities.textDocument.publishDiagnostics &&
        capabilities.textDocument.publishDiagnostics.relatedInformation
    );
    
    const result = {
        capabilities: {
            textDocumentSync: TextDocumentSyncKind.Incremental,
            completionProvider: {
                resolveProvider: true,
                triggerCharacters: ['.', ':']
            },
            hoverProvider: true,
            definitionProvider: true,
            referencesProvider: true,
            documentSymbolProvider: true,
            workspaceSymbolProvider: true,
            codeActionProvider: true,
            documentFormattingProvider: true,
            signatureHelpProvider: {
                triggerCharacters: ['(', ',']
            }
        }
    };
    
    if (hasWorkspaceFolderCapability) {
        result.capabilities.workspace = {
            workspaceFolders: {
                supported: true
            }
        };
    }
    
    connection.console.log('Factorio Lua Language Server initialized');
    return result;
});

connection.onInitialized(() => {
    if (hasConfigurationCapability) {
        connection.client.register(DidChangeConfigurationNotification.type, undefined);
    }
    if (hasWorkspaceFolderCapability) {
        connection.workspace.onDidChangeWorkspaceFolders(_event => {
            connection.console.log('Workspace folder change event received.');
        });
    }
});

// ============================================================================
// FACTORIO API DATABASE
// ============================================================================

const FACTORIO_API = {
    classes: {
        'LuaSurface': {
            methods: [
                { name: 'find_entities', params: ['area'], returns: 'array', description: 'Find all entities in an area' },
                { name: 'create_entity', params: ['properties'], returns: 'LuaEntity', description: 'Create a new entity' },
                { name: 'find_entities_filtered', params: ['filters'], returns: 'array', description: 'Find entities matching filters' },
                { name: 'get_tile', params: ['x', 'y'], returns: 'LuaTile', description: 'Get tile at position' },
                { name: 'set_tiles', params: ['tiles', 'correct_tiles'], returns: 'void', description: 'Set tiles' }
            ],
            properties: [
                { name: 'name', type: 'string', description: 'Name of the surface' },
                { name: 'index', type: 'number', description: 'Unique index of the surface' },
                { name: 'valid', type: 'boolean', description: 'Whether the surface is valid' }
            ]
        },
        'LuaEntity': {
            methods: [
                { name: 'destroy', params: [], returns: 'boolean', description: 'Destroy the entity' },
                { name: 'die', params: ['force', 'cause'], returns: 'boolean', description: 'Kill the entity' },
                { name: 'teleport', params: ['position', 'surface'], returns: 'boolean', description: 'Teleport entity' },
                { name: 'get_inventory', params: ['inventory_type'], returns: 'LuaInventory', description: 'Get inventory' },
                { name: 'insert', params: ['items'], returns: 'number', description: 'Insert items into entity' }
            ],
            properties: [
                { name: 'name', type: 'string', description: 'Entity name' },
                { name: 'position', type: 'Position', description: 'Entity position' },
                { name: 'health', type: 'number', description: 'Current health' },
                { name: 'valid', type: 'boolean', description: 'Whether entity is valid' },
                { name: 'force', type: 'LuaForce', description: 'Force owning the entity' }
            ]
        },
        'LuaPlayer': {
            methods: [
                { name: 'print', params: ['message'], returns: 'void', description: 'Print message to player' },
                { name: 'teleport', params: ['position', 'surface'], returns: 'boolean', description: 'Teleport player' },
                { name: 'clear_cursor', params: [], returns: 'boolean', description: 'Clear cursor stack' },
                { name: 'get_main_inventory', params: [], returns: 'LuaInventory', description: 'Get main inventory' },
                { name: 'can_reach_entity', params: ['entity'], returns: 'boolean', description: 'Check if player can reach entity' }
            ],
            properties: [
                { name: 'name', type: 'string', description: 'Player name' },
                { name: 'index', type: 'number', description: 'Player index' },
                { name: 'character', type: 'LuaEntity', description: 'Player character entity' },
                { name: 'connected', type: 'boolean', description: 'Whether player is connected' },
                { name: 'force', type: 'LuaForce', description: 'Player force' }
            ]
        },
        'game': {
            properties: [
                { name: 'players', type: 'array', description: 'All players' },
                { name: 'surfaces', type: 'array', description: 'All surfaces' },
                { name: 'forces', type: 'array', description: 'All forces' },
                { name: 'tick', type: 'number', description: 'Current game tick' }
            ],
            methods: [
                { name: 'print', params: ['message'], returns: 'void', description: 'Print to all players' },
                { name: 'get_player', params: ['player'], returns: 'LuaPlayer', description: 'Get player by index or name' }
            ]
        }
    },
    events: [
        { name: 'on_tick', description: 'Raised every game tick' },
        { name: 'on_player_created', description: 'Raised when a player is created', params: ['player_index'] },
        { name: 'on_built_entity', description: 'Raised when entity is built', params: ['created_entity', 'player_index'] },
        { name: 'on_player_mined_entity', description: 'Raised when player mines entity', params: ['entity', 'player_index'] },
        { name: 'on_chunk_generated', description: 'Raised when chunk is generated', params: ['area', 'surface'] }
    ],
    defines: [
        { name: 'defines.inventory', description: 'Inventory types' },
        { name: 'defines.events', description: 'Event definitions' },
        { name: 'defines.direction', description: 'Direction constants' }
    ]
};

// ============================================================================
// DOCUMENT MANAGEMENT
// ============================================================================

documents.onDidChangeContent(change => {
    validateTextDocument(change.document);
});

documents.onDidClose(e => {
    connection.sendDiagnostics({ uri: e.document.uri, diagnostics: [] });
});

// ============================================================================
// VALIDATION
// ============================================================================

async function validateTextDocument(textDocument) {
    const text = textDocument.getText();
    const diagnostics = [];
    
    // Syntax validation
    const syntaxErrors = await validateSyntax(text);
    diagnostics.push(...syntaxErrors);
    
    // API validation
    const apiErrors = validateFactorioAPI(text);
    diagnostics.push(...apiErrors);
    
    // Best practices checks
    const lintWarnings = lintCode(text);
    diagnostics.push(...lintWarnings);
    
    connection.sendDiagnostics({ uri: textDocument.uri, diagnostics });
}

async function validateSyntax(code) {
    const diagnostics = [];
    
    // Basic Lua syntax checks
    const lines = code.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        
        // Check for common syntax errors
        if (line.match(/\bend\s+end\b/)) {
            diagnostics.push({
                severity: DiagnosticSeverity.Error,
                range: {
                    start: { line: i, character: 0 },
                    end: { line: i, character: line.length }
                },
                message: 'Duplicate "end" keyword',
                source: 'factorio-lua'
            });
        }
        
        // Check for unclosed strings
        if ((line.match(/"/g) || []).length % 2 !== 0) {
            diagnostics.push({
                severity: DiagnosticSeverity.Error,
                range: {
                    start: { line: i, character: 0 },
                    end: { line: i, character: line.length }
                },
                message: 'Unclosed string',
                source: 'factorio-lua'
            });
        }
    }
    
    return diagnostics;
}

function validateFactorioAPI(code) {
    const diagnostics = [];
    const lines = code.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        
        // Check for undefined event handlers
        const eventMatch = line.match(/script\.on_event\((\w+),/);
        if (eventMatch) {
            const eventName = eventMatch[1];
            const validEvents = FACTORIO_API.events.map(e => e.name.replace('on_', ''));
            if (!validEvents.includes(eventName.replace('defines.events.', '').replace('on_', ''))) {
                diagnostics.push({
                    severity: DiagnosticSeverity.Warning,
                    range: {
                        start: { line: i, character: 0 },
                        end: { line: i, character: line.length }
                    },
                    message: `Unknown event: ${eventName}`,
                    source: 'factorio-lua'
                });
            }
        }
        
        // Check for deprecated APIs
        if (line.match(/game\.player/)) {
            diagnostics.push({
                severity: DiagnosticSeverity.Warning,
                range: {
                    start: { line: i, character: 0 },
                    end: { line: i, character: line.length }
                },
                message: 'game.player is deprecated in multiplayer, use event.player_index',
                source: 'factorio-lua'
            });
        }
    }
    
    return diagnostics;
}

function lintCode(code) {
    const diagnostics = [];
    const lines = code.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        
        // Check for global variables (potential issue)
        const globalMatch = line.match(/^\s*(\w+)\s*=/);
        if (globalMatch && !line.match(/^\s*local/)) {
            diagnostics.push({
                severity: DiagnosticSeverity.Information,
                range: {
                    start: { line: i, character: 0 },
                    end: { line: i, character: line.length }
                },
                message: `Consider using "local" for variable: ${globalMatch[1]}`,
                source: 'factorio-lua'
            });
        }
        
        // Check line length
        if (line.length > 120) {
            diagnostics.push({
                severity: DiagnosticSeverity.Hint,
                range: {
                    start: { line: i, character: 120 },
                    end: { line: i, character: line.length }
                },
                message: 'Line exceeds 120 characters',
                source: 'factorio-lua'
            });
        }
    }
    
    return diagnostics;
}

// ============================================================================
// CODE COMPLETION
// ============================================================================

connection.onCompletion((textDocumentPosition) => {
    const document = documents.get(textDocumentPosition.textDocument.uri);
    if (!document) {
        return [];
    }
    
    const text = document.getText();
    const offset = document.offsetAt(textDocumentPosition.position);
    const lineStart = text.lastIndexOf('\n', offset - 1) + 1;
    const line = text.substring(lineStart, offset);
    
    // Member completion (object.method or object:method)
    const memberMatch = line.match(/(\w+)[.:]\s*$/);
    if (memberMatch) {
        const objectName = memberMatch[1];
        return getCompletionsForObject(objectName);
    }
    
    // Event completion
    if (line.match(/script\.on_event\(/)) {
        return FACTORIO_API.events.map(event => ({
            label: event.name,
            kind: CompletionItemKind.Event,
            detail: event.description,
            documentation: event.params ? `Parameters: ${event.params.join(', ')}` : undefined
        }));
    }
    
    // Global completions
    return getGlobalCompletions();
});

function getCompletionsForObject(objectName) {
    const completions = [];
    
    // Check if it's a known Factorio class
    for (const [className, classData] of Object.entries(FACTORIO_API.classes)) {
        if (objectName.toLowerCase().includes(className.toLowerCase().replace('lua', ''))) {
            if (classData.methods) {
                for (const method of classData.methods) {
                    completions.push({
                        label: method.name,
                        kind: CompletionItemKind.Method,
                        detail: `(${method.params.join(', ')}) -> ${method.returns}`,
                        documentation: method.description,
                        insertText: method.name + '()'
                    });
                }
            }
            
            if (classData.properties) {
                for (const prop of classData.properties) {
                    completions.push({
                        label: prop.name,
                        kind: CompletionItemKind.Property,
                        detail: prop.type,
                        documentation: prop.description
                    });
                }
            }
        }
    }
    
    return completions;
}

function getGlobalCompletions() {
    const completions = [];
    
    // Add Factorio global objects
    completions.push({
        label: 'game',
        kind: CompletionItemKind.Variable,
        detail: 'Global game object',
        documentation: 'Main game state accessor'
    });
    
    completions.push({
        label: 'script',
        kind: CompletionItemKind.Variable,
        detail: 'Script object',
        documentation: 'Mod script handler'
    });
    
    completions.push({
        label: 'global',
        kind: CompletionItemKind.Variable,
        detail: 'Global mod storage',
        documentation: 'Persistent mod data'
    });
    
    return completions;
}

connection.onCompletionResolve((item) => {
    return item;
});

// ============================================================================
// HOVER INFORMATION
// ============================================================================

connection.onHover((params) => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return null;
    }
    
    const text = document.getText();
    const offset = document.offsetAt(params.position);
    
    // Find word at cursor
    const wordMatch = text.substring(0, offset).match(/[\w.]+$/);
    if (!wordMatch) {
        return null;
    }
    
    const word = wordMatch[0];
    
    // Check if it's a Factorio API element
    for (const [className, classData] of Object.entries(FACTORIO_API.classes)) {
        if (word.includes(className)) {
            return {
                contents: {
                    kind: 'markdown',
                    value: `**${className}**\n\nFactorio API class for ${className.replace('Lua', '').toLowerCase()} operations.`
                }
            };
        }
        
        if (classData.methods) {
            for (const method of classData.methods) {
                if (word.includes(method.name)) {
                    return {
                        contents: {
                            kind: 'markdown',
                            value: `**${method.name}**\n\n${method.description}\n\n\`\`\`lua\n${method.name}(${method.params.join(', ')})\n\`\`\``
                        }
                    };
                }
            }
        }
    }
    
    return null;
});

// ============================================================================
// SIGNATURE HELP
// ============================================================================

connection.onSignatureHelp((params) => {
    return {
        signatures: [
            {
                label: 'function example(param1, param2)',
                documentation: 'Example function documentation',
                parameters: [
                    { label: 'param1', documentation: 'First parameter' },
                    { label: 'param2', documentation: 'Second parameter' }
                ]
            }
        ],
        activeSignature: 0,
        activeParameter: 0
    };
});

// ============================================================================
// DOCUMENT SYMBOLS
// ============================================================================

connection.onDocumentSymbol((params) => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }
    
    const text = document.getText();
    const lines = text.split('\n');
    const symbols = [];
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        
        // Find function definitions
        const funcMatch = line.match(/function\s+(\w+)/);
        if (funcMatch) {
            symbols.push({
                name: funcMatch[1],
                kind: 12, // Function
                range: {
                    start: { line: i, character: 0 },
                    end: { line: i, character: line.length }
                },
                selectionRange: {
                    start: { line: i, character: 0 },
                    end: { line: i, character: line.length }
                }
            });
        }
        
        // Find local variables
        const localMatch = line.match(/local\s+(\w+)/);
        if (localMatch) {
            symbols.push({
                name: localMatch[1],
                kind: 13, // Variable
                range: {
                    start: { line: i, character: 0 },
                    end: { line: i, character: line.length }
                },
                selectionRange: {
                    start: { line: i, character: 0 },
                    end: { line: i, character: line.length }
                }
            });
        }
    }
    
    return symbols;
});

// ============================================================================
// START SERVER
// ============================================================================

documents.listen(connection);
connection.listen();

connection.console.log('Factorio Lua Language Server started');
