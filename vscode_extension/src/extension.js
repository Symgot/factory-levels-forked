// Factorio Mod Validator - VSCode Extension
// Phase 6: IDE Integration for Real-time Validation
// Reference: https://code.visualstudio.com/api

const vscode = require('vscode');
const { spawn } = require('child_process');
const path = require('path');

// Diagnostic collection for syntax errors
let diagnosticCollection;

/**
 * Extension activation
 */
function activate(context) {
    console.log('Factorio Mod Validator extension activated');

    // Create diagnostic collection
    diagnosticCollection = vscode.languages.createDiagnosticCollection('factorio');
    context.subscriptions.push(diagnosticCollection);

    // Register commands
    context.subscriptions.push(
        vscode.commands.registerCommand('factorio-validator.validateFile', validateCurrentFile)
    );
    
    context.subscriptions.push(
        vscode.commands.registerCommand('factorio-validator.validateWorkspace', validateWorkspace)
    );
    
    context.subscriptions.push(
        vscode.commands.registerCommand('factorio-validator.showMetrics', showCodeMetrics)
    );

    // Register document change listener for real-time validation
    context.subscriptions.push(
        vscode.workspace.onDidChangeTextDocument(event => {
            const config = vscode.workspace.getConfiguration('factorio-validator');
            if (config.get('enableRealTimeValidation')) {
                if (event.document.languageId === 'lua') {
                    validateDocument(event.document);
                }
            }
        })
    );

    // Register save listener
    context.subscriptions.push(
        vscode.workspace.onDidSaveTextDocument(document => {
            if (document.languageId === 'lua') {
                validateDocument(document);
                
                const config = vscode.workspace.getConfiguration('factorio-validator');
                if (config.get('showMetricsOnSave')) {
                    showCodeMetrics();
                }
            }
        })
    );

    // Validate active editor on startup
    if (vscode.window.activeTextEditor) {
        validateDocument(vscode.window.activeTextEditor.document);
    }
}

/**
 * Validate current file
 */
async function validateCurrentFile() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showWarningMessage('No active editor');
        return;
    }

    if (editor.document.languageId !== 'lua') {
        vscode.window.showWarningMessage('Not a Lua file');
        return;
    }

    await validateDocument(editor.document);
    vscode.window.showInformationMessage('Validation complete');
}

/**
 * Validate entire workspace
 */
async function validateWorkspace() {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) {
        vscode.window.showWarningMessage('No workspace folder open');
        return;
    }

    vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: 'Validating Factorio mod...',
        cancellable: false
    }, async (progress) => {
        progress.report({ increment: 0 });

        const luaFiles = await vscode.workspace.findFiles('**/*.lua', '**/node_modules/**');
        const total = luaFiles.length;

        for (let i = 0; i < luaFiles.length; i++) {
            const doc = await vscode.workspace.openTextDocument(luaFiles[i]);
            await validateDocument(doc, false);
            progress.report({ increment: (100 / total) });
        }

        vscode.window.showInformationMessage(`Validated ${total} Lua files`);
    });
}

/**
 * Show code metrics for current file
 */
async function showCodeMetrics() {
    const editor = vscode.window.activeTextEditor;
    if (!editor || editor.document.languageId !== 'lua') {
        vscode.window.showWarningMessage('No Lua file active');
        return;
    }

    const metrics = await calculateMetrics(editor.document);
    
    const panel = vscode.window.createWebviewPanel(
        'factorioMetrics',
        'Code Metrics',
        vscode.ViewColumn.Beside,
        {}
    );

    panel.webview.html = getMetricsHtml(metrics);
}

/**
 * Validate a document
 */
async function validateDocument(document, showErrors = true) {
    if (document.languageId !== 'lua') {
        return;
    }

    const diagnostics = [];
    const text = document.getText();

    // TODO: Production validator integration
    // Replace simple pattern matching with actual Lua parser from Phase 6
    // Example: const { spawn } = require('child_process');
    // const validator = spawn('lua5.4', ['validation_engine.lua', document.uri.fsPath]);
    // Parse validator output and create diagnostics from results
    
    // SIMPLIFIED VALIDATION - Pattern-based checks for demonstration
    const lines = text.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        
        // Check for common issues (simplified - real validator would use enhanced_parser.lua)
        if (line.includes('game.player')) {
            diagnostics.push({
                severity: vscode.DiagnosticSeverity.Warning,
                range: new vscode.Range(i, 0, i, line.length),
                message: 'Deprecated: Use game.get_player() instead of game.player',
                source: 'factorio-validator'
            });
        }
        
        // Check for unbalanced parentheses
        const openParen = (line.match(/\(/g) || []).length;
        const closeParen = (line.match(/\)/g) || []).length;
        if (openParen !== closeParen) {
            diagnostics.push({
                severity: vscode.DiagnosticSeverity.Error,
                range: new vscode.Range(i, 0, i, line.length),
                message: 'Unbalanced parentheses',
                source: 'factorio-validator'
            });
        }
        
        // Check for undefined global
        if (line.match(/\bundefined_function\(/)) {
            diagnostics.push({
                severity: vscode.DiagnosticSeverity.Error,
                range: new vscode.Range(i, 0, i, line.length),
                message: 'Undefined function call',
                source: 'factorio-validator'
            });
        }
    }

    diagnosticCollection.set(document.uri, diagnostics);
    
    if (showErrors && diagnostics.length > 0) {
        const errorCount = diagnostics.filter(d => d.severity === vscode.DiagnosticSeverity.Error).length;
        const warningCount = diagnostics.filter(d => d.severity === vscode.DiagnosticSeverity.Warning).length;
        
        vscode.window.showInformationMessage(
            `Found ${errorCount} errors and ${warningCount} warnings`
        );
    }
}

/**
 * Calculate code metrics
 */
async function calculateMetrics(document) {
    const text = document.getText();
    const lines = text.split('\n');
    
    const metrics = {
        lines: lines.length,
        codeLines: lines.filter(l => l.trim() && !l.trim().startsWith('--')).length,
        commentLines: lines.filter(l => l.trim().startsWith('--')).length,
        functions: (text.match(/function\s+\w+/g) || []).length,
        complexity: 1, // Simplified
        maintainability: 85 // Mock value
    };
    
    // Count control flow statements for complexity
    const controlFlow = text.match(/\b(if|while|for|repeat)\b/g) || [];
    metrics.complexity += controlFlow.length;
    
    return metrics;
}

/**
 * Generate metrics HTML
 */
function getMetricsHtml(metrics) {
    return `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 20px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                }
                .metric {
                    margin: 20px 0;
                    padding: 20px;
                    background: rgba(255,255,255,0.1);
                    border-radius: 10px;
                    backdrop-filter: blur(10px);
                }
                .metric-label {
                    font-size: 14px;
                    opacity: 0.8;
                    text-transform: uppercase;
                    letter-spacing: 1px;
                }
                .metric-value {
                    font-size: 36px;
                    font-weight: bold;
                    margin-top: 10px;
                }
                .complexity-rating {
                    color: ${metrics.complexity <= 10 ? '#4caf50' : metrics.complexity <= 20 ? '#ff9800' : '#f44336'};
                }
            </style>
        </head>
        <body>
            <h1>📊 Code Metrics</h1>
            
            <div class="metric">
                <div class="metric-label">Lines of Code</div>
                <div class="metric-value">${metrics.codeLines}</div>
            </div>
            
            <div class="metric">
                <div class="metric-label">Total Lines</div>
                <div class="metric-value">${metrics.lines}</div>
            </div>
            
            <div class="metric">
                <div class="metric-label">Comment Lines</div>
                <div class="metric-value">${metrics.commentLines}</div>
            </div>
            
            <div class="metric">
                <div class="metric-label">Functions</div>
                <div class="metric-value">${metrics.functions}</div>
            </div>
            
            <div class="metric">
                <div class="metric-label">Cyclomatic Complexity</div>
                <div class="metric-value complexity-rating">${metrics.complexity}</div>
                <div style="margin-top: 10px; opacity: 0.8;">
                    ${metrics.complexity <= 10 ? 'Low (Good)' : metrics.complexity <= 20 ? 'Moderate' : 'High (Refactor recommended)'}
                </div>
            </div>
            
            <div class="metric">
                <div class="metric-label">Maintainability Index</div>
                <div class="metric-value">${metrics.maintainability}</div>
            </div>
        </body>
        </html>
    `;
}

/**
 * Extension deactivation
 */
function deactivate() {
    if (diagnosticCollection) {
        diagnosticCollection.dispose();
    }
}

module.exports = {
    activate,
    deactivate
};
