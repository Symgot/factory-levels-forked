# Factorio Mod Validator - VSCode Extension

IDE integration for real-time Factorio mod validation.

## Features

### Real-time Validation
- **Syntax Checking**: Instant Lua syntax validation while typing
- **API Validation**: Verify Factorio API usage against official documentation
- **Error Highlighting**: Visual indicators for syntax errors and warnings
- **Inline Suggestions**: Quick fixes for common issues

### Commands

- `Factorio: Validate Current File` (Ctrl+Shift+V / Cmd+Shift+V)
- `Factorio: Validate Entire Mod`
- `Factorio: Show Code Metrics`

### Code Metrics

- Lines of Code
- Cyclomatic Complexity
- Maintainability Index
- Function Count
- Comment Ratio

### Settings

```json
{
  "factorio-validator.enableRealTimeValidation": true,
  "factorio-validator.factorioVersion": "2.0",
  "factorio-validator.showMetricsOnSave": false
}
```

## Installation

### From VSIX
1. Download .vsix file
2. Open VSCode
3. Extensions → Install from VSIX

### Development
```bash
cd vscode_extension
npm install
code .
```

Press F5 to launch extension development host.

## Usage

1. Open a Factorio mod project
2. Edit .lua files
3. Validation runs automatically
4. View errors in Problems panel
5. Use Cmd/Ctrl+Shift+V to manually validate

## Architecture

- **Language Server**: Real-time validation engine
- **Diagnostics Provider**: Error and warning reporting
- **Code Actions**: Quick fixes and refactoring
- **WebView**: Metrics visualization

## Integration

Connects to Phase 6 validation backend:
- Enhanced Parser: `../tests/enhanced_parser.lua`
- Validation Engine: `../tests/validation_engine.lua`
- API Reference: `../tests/api_reference_checker.lua`

## References

- VSCode Extension API: https://code.visualstudio.com/api
- Factorio API: https://lua-api.factorio.com/latest/
- Phase 6 Implementation: ../tests/
