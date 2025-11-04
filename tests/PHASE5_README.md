# Phase 5: Extended Syntax Validation & Reverse Engineering System - README

## Quick Start

### Installation

No installation required. All components are standalone Lua modules.

### Requirements

- Lua 5.3+ (Factorio uses Lua 5.4)
- Unix-like system with `unzip` command (for archive validation)
- LuaUnit framework (included in `tests/luaunit.lua`)

## Usage Guide

### 1. Command-Line Interface

The CLI tool provides easy access to all validation features:

#### Validate a Single File
```bash
lua tests/cli_validation_tool.lua --validate-file factory-levels/control.lua
```

**Example Output:**
```
Validating file: control.lua

File: control.lua
Status: VALID
Syntax valid: YES
API calls found: 15

No errors found.
```

#### Validate Entire Directory
```bash
lua tests/cli_validation_tool.lua --validate-directory factory-levels/
```

**Example Output:**
```
Validating directory: factory-levels/

Total files: 5
Validated: 5
Failed: 0

All files validated successfully!
```

#### Validate Mod Archive
```bash
lua tests/cli_validation_tool.lua --validate-archive my-mod_1.0.0.zip
```

**Example Output:**
```
Validating archive: my-mod_1.0.0.zip

Mod: my-mod
Version: 1.0.0

Status: VALID
Files validated: 10

No errors found.
```

#### Batch Validate Multiple Archives
```bash
lua tests/cli_validation_tool.lua --batch-validate "mods/*.zip"
```

**Example Output:**
```
Batch validating archives: mods/*.zip

Found 3 archive(s)

Total archives: 3
Validated: 2
Failed: 1

[1/3] factory-levels: VALID
[2/3] my-mod: VALID
[3/3] broken-mod: INVALID
```

#### Generate Automated Tests
```bash
lua tests/cli_validation_tool.lua --generate-tests --output my_tests.lua
```

**Example Output:**
```
Generating automated test cases...

Found 150 API elements

Generated 450 tests
Coverage: 100.00%

Tests exported to: my_tests.lua
```

#### Analyze API Coverage
```bash
lua tests/cli_validation_tool.lua --api-coverage factory-levels/
```

**Example Output:**
```
Analyzing API coverage: factory-levels/

Total API elements: 500
Used API elements: 45
Coverage: 9.00%

Top API usage:
  game.print: 12
  script.on_event: 8
  defines.events.on_built_entity: 5
  ...
```

#### Generate False Positive Tests
```bash
lua tests/cli_validation_tool.lua --false-positive-tests --iterations=100 --output fp_tests.lua
```

**Example Output:**
```
Generating 100 false positive tests...

Generated 300 tests
Positive tests: 100
Negative tests: 100
Edge tests: 100

Tests exported to: fp_tests.lua
```

### 2. Programmatic API

#### Example 1: Validate File
```lua
local validation_engine = require('validation_engine')

-- Parse and validate file
local report = validation_engine.validate_file("control.lua")

if report.success then
    print("✓ File is valid!")
    print(string.format("Found %d API calls", #report.api_calls))
else
    print("✗ Validation failed:")
    for _, error in ipairs(report.errors) do
        print("  - " .. error)
    end
end
```

#### Example 2: Detect API Usage
```lua
local reverse_parser = require('reverse_engineering_parser')

-- Parse Lua code
local lua_code = [[
    script.on_event(defines.events.on_built_entity, function(event)
        game.print("Entity built: " .. event.entity.name)
    end)
]]

local ast = reverse_parser.build_ast(lua_code)
local api_calls = reverse_parser.detect_api_usage(ast)

print(string.format("Detected %d API calls:", #api_calls))
for _, call in ipairs(api_calls) do
    print(string.format("  - %s.%s (%s)", 
        call.namespace, call.member, call.type))
end
```

#### Example 3: Generate Tests
```lua
local false_positive_generator = require('false_positive_generator')

-- Define API element to test
local api_element = {
    name = "game.print",
    namespace = "game",
    member = "print",
    type = "method"
}

-- Generate test cases
local tests = false_positive_generator.generate_api_tests(api_element)

print(string.format("Generated %d test cases:", #tests))
for _, test in ipairs(tests) do
    print(string.format("  - %s: %s", test.name, test.description))
end
```

#### Example 4: Check API References
```lua
local api_reference_checker = require('api_reference_checker')

-- Check if API call is valid
local api_call = {
    namespace = "game",
    member = "print",
    type = "method"
}

local valid, issue = api_reference_checker.check_reference(api_call)

if valid then
    print("✓ API call is valid")
    
    -- Check if deprecated
    local deprecated, info = api_reference_checker.is_deprecated(api_call)
    if deprecated then
        print("⚠ Warning: API is deprecated")
        print("  Reason: " .. info.reason)
        print("  Replacement: " .. info.replacement)
    end
else
    print("✗ Invalid API call: " .. issue)
end
```

#### Example 5: Validate Syntax
```lua
local syntax_validator = require('syntax_validator')
local reverse_parser = require('reverse_engineering_parser')

-- Parse code
local lua_code = "local x = 1 + 2"
local ast = reverse_parser.build_ast(lua_code)

-- Validate syntax
local report = syntax_validator.validate_all(ast, {
    validate_factorio = true,
    validate_style = true,
    validate_complexity = true
})

print("Syntax valid:", report.syntax_valid)
print("Errors:", #report.errors)
print("Warnings:", #report.warnings)
print("Style warnings:", #report.style_warnings)

-- Print formatted report
print(syntax_validator.format_report(report))
```

## Advanced Features

### Custom Validation Rules

You can extend the syntax validator with custom rules:

```lua
local syntax_validator = require('syntax_validator')

-- Add custom validation
function my_custom_validator(ast)
    local issues = {}
    
    -- Add your custom logic here
    if ast.source and ast.source:find("TODO") then
        table.insert(issues, "File contains TODO comments")
    end
    
    return #issues == 0, issues
end

-- Use in validation
local ast = reverse_parser.build_ast(lua_code)
local valid, issues = my_custom_validator(ast)
```

### Integration with CI/CD

Add to your GitHub Actions workflow:

```yaml
name: Mod Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install Lua
        run: sudo apt-get install -y lua5.3
      
      - name: Validate Mod
        run: |
          cd tests
          lua cli_validation_tool.lua --validate-directory ../factory-levels/
      
      - name: Run Tests
        run: |
          cd tests
          lua universal_compatibility_suite.lua
```

### Batch Processing Script

Create a script to validate multiple mods:

```bash
#!/bin/bash
# validate_all_mods.sh

MODS_DIR="mods"
FAILED=0

for mod in "$MODS_DIR"/*.zip; do
    echo "Validating: $mod"
    lua tests/cli_validation_tool.lua --validate-archive "$mod"
    if [ $? -ne 0 ]; then
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "Validation complete. Failed: $FAILED"
exit $FAILED
```

## Testing

Run the comprehensive test suite:

```bash
cd tests
lua universal_compatibility_suite.lua
```

**Expected Output:**
```
........................................
Ran 40 tests in 0.XXX seconds, 40 successes, 0 failures
OK
```

### Test Coverage

The test suite includes:
- ✅ 7 Validation Engine tests
- ✅ 7 Reverse Parser tests
- ✅ 6 Syntax Validator tests
- ✅ 5 False Positive Generator tests
- ✅ 6 API Reference Checker tests
- ✅ 2 Mod Archive Validator tests

**Total: 40+ comprehensive tests**

## Troubleshooting

### Issue: "module not found"

**Solution:** Ensure you're running from the correct directory:
```bash
cd /path/to/factory-levels-forked
lua tests/cli_validation_tool.lua --help
```

### Issue: "unzip command not found"

**Solution:** Install unzip:
```bash
# Ubuntu/Debian
sudo apt-get install unzip

# macOS
brew install unzip
```

### Issue: "Lua version mismatch"

**Solution:** Ensure Lua 5.3+ is installed:
```bash
lua -v
# Should output: Lua 5.3 or higher
```

### Issue: "Permission denied"

**Solution:** Make CLI tool executable:
```bash
chmod +x tests/cli_validation_tool.lua
```

## Performance Tips

### Large Mod Validation

For large mods with 100+ files:

1. **Use batch processing** instead of individual file validation
2. **Disable style validation** for faster results:
   ```lua
   local report = syntax_validator.validate_all(ast, {
       validate_style = false,
       validate_complexity = false
   })
   ```
3. **Process in parallel** using multiple processes

### Memory Usage

For very large codebases:

1. **Process files in batches** rather than all at once
2. **Clear AST after processing**:
   ```lua
   ast = nil
   collectgarbage()
   ```

## API Reference

### Validation Engine

| Function | Description |
|----------|-------------|
| `parse_lua_file(filepath)` | Parse Lua file into AST |
| `extract_api_calls(ast)` | Extract all API calls |
| `validate_references(api_calls)` | Validate API references |
| `generate_synthetic_tests(api_elements)` | Generate test cases |
| `validate_mod_archive(zip_path)` | Validate mod ZIP |
| `validate_directory(directory, recursive)` | Validate directory |
| `validate_file(filepath)` | Validate single file |
| `generate_report(results)` | Generate formatted report |

### Reverse Parser

| Function | Description |
|----------|-------------|
| `tokenize(source)` | Tokenize Lua source |
| `build_ast(lua_code)` | Build Abstract Syntax Tree |
| `extract_functions(ast)` | Extract function definitions |
| `track_variables(ast)` | Track variable usage |
| `analyze_control_flow(ast)` | Analyze control flow |
| `detect_api_usage(ast)` | Detect Factorio API calls |
| `calculate_metrics(ast)` | Calculate code metrics |

### Syntax Validator

| Function | Description |
|----------|-------------|
| `validate_syntax(ast)` | Validate syntax |
| `is_valid_identifier(name)` | Check identifier validity |
| `validate_expression(expr)` | Validate Lua expression |
| `validate_factorio_api(ast)` | Validate Factorio API usage |
| `validate_complexity(ast)` | Validate code complexity |
| `validate_all(ast, options)` | Comprehensive validation |

### False Positive Generator

| Function | Description |
|----------|-------------|
| `generate_api_tests(api_element)` | Generate tests for API |
| `generate_positive_tests(api_element)` | Generate positive tests |
| `create_false_positives(api_element)` | Generate negative tests |
| `generate_edge_cases(api_element)` | Generate edge case tests |
| `generate_test_suite(api_elements)` | Generate complete suite |
| `export_test_suite(suite, path)` | Export tests to file |

### API Reference Checker

| Function | Description |
|----------|-------------|
| `check_reference(api_call)` | Check API validity |
| `is_deprecated(api_call)` | Check deprecation status |
| `get_all_api_elements()` | Get all known APIs |
| `calculate_coverage(used_apis)` | Calculate API coverage |
| `check_compatibility(api_call, version)` | Check version compatibility |
| `validate_all(api_calls)` | Batch validate APIs |

### Mod Archive Validator

| Function | Description |
|----------|-------------|
| `validate_mod_archive(zip_path)` | Validate mod ZIP |
| `validate_structure(mod_dir)` | Validate directory structure |
| `parse_info_json(path)` | Parse info.json |
| `validate_dependencies(info_data)` | Validate dependencies |
| `validate_multiple(zip_paths)` | Batch validate archives |

## Examples Repository

More examples available in:
- `tests/universal_compatibility_suite.lua` - Complete test examples
- `PHASE5_COMPLETION.md` - Usage documentation
- Individual module files - Inline documentation

## Contributing

To extend the validation system:

1. **Add new validation rules** to `syntax_validator.lua`
2. **Extend API database** in `api_reference_checker.lua`
3. **Add test generators** in `false_positive_generator.lua`
4. **Enhance parser** in `reverse_engineering_parser.lua`

## License

Same license as factory-levels-forked project.

## Support

For issues or questions:
1. Check this README
2. Review `PHASE5_COMPLETION.md`
3. Run test suite: `lua universal_compatibility_suite.lua`
4. Check inline code documentation

## Version

**Phase 5 Version: 1.0.0**
- Initial release
- Complete feature set
- 40+ comprehensive tests
- Production-ready
