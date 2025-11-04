# LuaUnit Testing Infrastructure for Factory Levels

## Overview

Comprehensive Lua syntax validation and testing infrastructure using LuaUnit v3.4 for the Factory Levels Factorio mod. This setup provides automated testing through GitHub Actions and local development support via Visual Studio Code.

## Features

- **LuaUnit v3.4 Integration**: Industry-standard Lua testing framework
- **Factorio API Mock**: Complete simulation of Factorio Lua API for isolated testing
- **Syntax Validation**: Automated checks for all Lua files in the mod
- **GitHub Actions**: Automated CI/CD pipeline for pull requests and commits
- **VSCode Integration**: Tasks and debugging configurations for local development
- **Comprehensive Test Coverage**: Tests for control logic, invisible module system, and machine level calculations

## Directory Structure

```
tests/
├── luaunit.lua          # LuaUnit v3.4 testing framework
├── factorio_mock.lua    # Factorio API mock implementation
└── test_control.lua     # Main test suite
```

## Requirements

- Lua 5.3
- LuaUnit v3.4 (included)
- Visual Studio Code (optional, for local development)

## Installation

### Local Setup

1. Install Lua 5.3:
```bash
# Ubuntu/Debian
sudo apt-get install lua5.3

# macOS
brew install lua@5.3

# Windows
# Download from http://luabinaries.sourceforge.net/
```

2. Verify installation:
```bash
lua5.3 -v
```

## Running Tests

### Command Line

Run all tests:
```bash
cd tests
lua5.3 test_control.lua
```

Run tests with verbose output:
```bash
cd tests
lua5.3 test_control.lua -v
```

### Visual Studio Code

#### Using Tasks

1. Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
2. Select "Tasks: Run Task"
3. Choose one of:
   - "Run Lua Tests" (default test task)
   - "Run Lua Tests (Verbose)"
   - "Validate Lua Syntax"

#### Using Keyboard Shortcuts

- Press `Ctrl+Shift+B` / `Cmd+Shift+B` to run default test task

#### Using Debug Configuration

1. Open Debug view (Ctrl+Shift+D / Cmd+Shift+D)
2. Select "Run Lua Tests" configuration
3. Press F5 to start debugging

## GitHub Actions

Tests run automatically on:
- Push to `main`, `master`, `develop`, or `copilot/**` branches
- Pull requests targeting `main`, `master`, or `develop`
- Manual workflow dispatch

View test results in the "Actions" tab of the repository.

## Test Suites

### TestSyntax
Validates Lua syntax for all mod files:
- `control.lua` - Runtime logic
- `data.lua` - Data stage definitions
- `settings.lua` - Mod settings

### TestInvisibleModules
Tests invisible module system:
- Bonus formula definitions
- Machine tracking system
- Entity effect application

### TestMachineLevels
Tests machine leveling logic:
- Level determination based on products finished
- Max level configuration per tier
- Machine progression system

### TestStringUtils
Tests string utility functions:
- `string_starts_with()` helper function

### TestRemoteInterface
Tests remote interface registration:
- Remote interface existence
- API availability

## Factorio API Mock

The `factorio_mock.lua` provides complete simulation of Factorio Lua API:

### Mocked Components
- `storage` - Global storage table
- `script` - Event system and handlers
- `defines` - Game constants and enums
- `settings` - Mod settings (startup and runtime-global)
- `game` - Game state and surfaces
- `remote` - Remote interfaces
- `table.deepcopy` - Deep copy utility

### Mock Helpers
```lua
-- Set mod settings
factorio_mock.set_setting("startup", "setting-name", value)
factorio_mock.set_setting("global", "setting-name", value)

-- Create test entities
local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine", {
    products_finished = 100
})

-- Reset mock state between tests
factorio_mock.reset()
```

## Writing New Tests

Add test cases to `test_control.lua`:

```lua
TestNewFeature = {}

function TestNewFeature:setUp()
    factorio_mock.reset()
    dofile("../factory-levels/control.lua")
end

function TestNewFeature:testFeatureBehavior()
    -- Test implementation
    lu.assertEquals(actual, expected, "Test description")
end
```

## Continuous Integration

The GitHub Actions workflow:
1. Checks out repository
2. Installs Lua 5.3
3. Verifies test structure
4. Runs all test suites
5. Reports results

## Troubleshooting

### Lua Not Found
```bash
# Verify Lua installation
which lua5.3
lua5.3 -v
```

### Module Not Found
Ensure working directory is `tests/` when running tests:
```bash
cd tests
lua5.3 test_control.lua
```

### VSCode Lua Extension
Install the Lua language server extension:
1. Open Extensions (Ctrl+Shift+X / Cmd+Shift+X)
2. Search for "Lua"
3. Install "Lua" by sumneko

## References

- **LuaUnit Documentation**: https://luaunit.readthedocs.io/en/luaunit_v3_4/
- **Factorio Lua API**: https://lua-api.factorio.com/latest/index.html
- **Lua Testing Tutorial**: https://martin-fieber.de/blog/how-to-test-your-lua/
- **LuaUnit Repository**: https://github.com/bluebird75/luaunit/blob/v3.4/README.md
- **VSCode Lua Debugging**: https://moldstud.com/articles/p-debug-lua-in-visual-studio-code-a-complete-guide

## Contributing

When adding new features:
1. Write tests first (TDD approach)
2. Ensure all tests pass locally
3. Verify GitHub Actions workflow succeeds
4. Update this README if adding new test suites

## License

This testing infrastructure follows the same license as the Factory Levels mod.
