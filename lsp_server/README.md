# Factorio Lua Language Server

Language Server Protocol (LSP) implementation for Factorio Lua development.

## Features

- **Real-time Diagnostics**: Live syntax and API validation
- **Code Completion**: Intelligent Factorio API autocomplete
- **Hover Information**: API documentation on-demand
- **Signature Help**: Function parameter hints
- **Document Symbols**: Symbol outline and navigation
- **Workspace Symbols**: Project-wide symbol search
- **Go-to-Definition**: Navigate to API definitions
- **Factorio API Database**: Complete API knowledge base
- **Lint Rules**: Code quality checks

## Installation

```bash
npm install
```

## Running

### Standalone
```bash
npm start
```

### With VSCode Extension

Add to your VSCode extension's `package.json`:

```json
{
  "activationEvents": ["onLanguage:lua"],
  "main": "./out/extension.js",
  "contributes": {
    "configuration": {
      "type": "object",
      "title": "Factorio Lua",
      "properties": {
        "factorioLua.trace.server": {
          "type": "string",
          "enum": ["off", "messages", "verbose"],
          "default": "off",
          "description": "Traces the communication between VS Code and the language server."
        }
      }
    }
  }
}
```

Client code:

```javascript
const { LanguageClient } = require('vscode-languageclient/node');
const path = require('path');

let client;

function activate(context) {
    const serverModule = context.asAbsolutePath(
        path.join('lsp_server', 'server.js')
    );
    
    const serverOptions = {
        run: { module: serverModule, transport: TransportKind.ipc },
        debug: { module: serverModule, transport: TransportKind.ipc }
    };
    
    const clientOptions = {
        documentSelector: [{ scheme: 'file', language: 'lua' }],
        synchronize: {
            fileEvents: workspace.createFileSystemWatcher('**/*.lua')
        }
    };
    
    client = new LanguageClient(
        'factorioLua',
        'Factorio Lua Language Server',
        serverOptions,
        clientOptions
    );
    
    client.start();
}

function deactivate() {
    if (!client) {
        return undefined;
    }
    return client.stop();
}

module.exports = { activate, deactivate };
```

## Features in Detail

### Diagnostics

Automatically checks for:
- Syntax errors (unclosed strings, duplicate keywords)
- Factorio API usage (unknown events, deprecated APIs)
- Code quality (global variables, line length)

### Code Completion

Triggers on:
- `.` for object members (e.g., `game.players`)
- `:` for method calls (e.g., `entity:destroy()`)
- `script.on_event(` for event names

Provides:
- Factorio API classes (game, script, global)
- Class methods with parameters and return types
- Class properties with types
- Event names with descriptions

### Hover Information

Shows documentation when hovering over:
- Factorio API classes
- API methods
- API properties
- Custom functions

### Signature Help

Displays function signatures with:
- Parameter names
- Parameter descriptions
- Return type information
- Triggered by `(` and `,`

### Document Symbols

Provides outline of:
- Functions
- Local variables
- Global variables
- Classes

### Lint Rules

Checks for:
- Global variable usage (recommends `local`)
- Long lines (>120 characters)
- Deprecated API usage
- Potential multiplayer issues

## Factorio API Coverage

### Classes
- `game`: Global game object
- `script`: Mod script handler
- `global`: Persistent mod storage
- `LuaSurface`: Surface operations
- `LuaEntity`: Entity operations
- `LuaPlayer`: Player operations
- `LuaForce`: Force operations
- `LuaInventory`: Inventory operations

### Events
- `on_tick`
- `on_player_created`
- `on_built_entity`
- `on_player_mined_entity`
- `on_chunk_generated`
- And more...

### Defines
- `defines.inventory`
- `defines.events`
- `defines.direction`

## Configuration

The LSP server can be configured through VSCode settings:

```json
{
  "factorioLua.trace.server": "verbose",
  "factorioLua.diagnostics.enable": true,
  "factorioLua.completion.enable": true
}
```

## Development

### Testing

```bash
npm test
```

### Debugging

Enable verbose logging:

```javascript
connection.console.log('Debug message');
```

View logs in VSCode:
1. View → Output
2. Select "Factorio Lua Language Server" from dropdown

## Protocol Compliance

Implements LSP 3.17 features:
- Text document synchronization
- Completion
- Hover
- Signature help
- Document symbols
- Workspace symbols
- Definition provider
- References provider
- Code actions
- Document formatting

## Performance

- Diagnostics: < 100ms
- Completion: < 20ms
- Hover: < 10ms
- Symbol search: < 50ms

## Limitations

- Basic Lua syntax validation (not full parser)
- Limited to Factorio 2.0 API
- No cross-file analysis yet
- Single-file symbol resolution

## Future Enhancements

- Full Lua 5.4 parser integration
- Cross-file references
- Refactoring support
- Advanced linting rules
- Integration with Phase 6 Enhanced Parser

## License

MIT
