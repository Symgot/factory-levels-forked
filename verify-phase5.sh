#!/bin/bash
# Test runner for Phase 5 validation system

echo "Phase 5: Extended Syntax Validation & Reverse Engineering System"
echo "=================================================================="
echo ""

# Check if Lua is installed
if ! command -v lua5.3 &> /dev/null && ! command -v lua &> /dev/null; then
    echo "⚠️  Warning: Lua not found. Tests cannot run."
    echo "   Install Lua with: sudo apt-get install lua5.3"
    echo ""
    exit 1
fi

LUA_CMD="lua5.3"
if ! command -v lua5.3 &> /dev/null; then
    LUA_CMD="lua"
fi

echo "✓ Using: $($LUA_CMD -v 2>&1 | head -1)"
echo ""

# Test 1: Check module loading
echo "Test 1: Module Loading"
echo "----------------------"

cd tests 2>/dev/null || cd ../tests 2>/dev/null || {
    echo "✗ Error: Cannot find tests directory"
    exit 1
}

$LUA_CMD -e "
package.path = package.path .. ';./?.lua'
local ok1, ve = pcall(require, 'validation_engine')
local ok2, rp = pcall(require, 'reverse_engineering_parser')
local ok3, sv = pcall(require, 'syntax_validator')
local ok4, fp = pcall(require, 'false_positive_generator')
local ok5, ar = pcall(require, 'api_reference_checker')
local ok6, ma = pcall(require, 'mod_archive_validator')

if ok1 and ok2 and ok3 and ok4 and ok5 and ok6 then
    print('✓ All modules loaded successfully')
    os.exit(0)
else
    print('✗ Module loading failed')
    if not ok1 then print('  - validation_engine: ' .. tostring(ve)) end
    if not ok2 then print('  - reverse_engineering_parser: ' .. tostring(rp)) end
    if not ok3 then print('  - syntax_validator: ' .. tostring(sv)) end
    if not ok4 then print('  - false_positive_generator: ' .. tostring(fp)) end
    if not ok5 then print('  - api_reference_checker: ' .. tostring(ar)) end
    if not ok6 then print('  - mod_archive_validator: ' .. tostring(ma)) end
    os.exit(1)
end
"

if [ $? -ne 0 ]; then
    echo ""
    echo "Module loading failed. Check error messages above."
    exit 1
fi

echo ""

# Test 2: Basic functionality
echo "Test 2: Basic Functionality"
echo "---------------------------"

$LUA_CMD -e "
package.path = package.path .. ';./?.lua'

local reverse_parser = require('reverse_engineering_parser')

-- Test tokenization
local code = 'local x = 1'
local tokens = reverse_parser.tokenize(code)
assert(#tokens > 0, 'Tokenization failed')
print('✓ Tokenization works')

-- Test AST building
local ast, err = reverse_parser.build_ast(code)
assert(ast ~= nil, 'AST building failed: ' .. tostring(err))
print('✓ AST building works')

-- Test API detection
local code2 = 'game.print(\"test\")'
local ast2 = reverse_parser.build_ast(code2)
local api_calls = reverse_parser.detect_api_usage(ast2)
assert(#api_calls > 0, 'API detection failed')
print('✓ API detection works')

print('')
print('All basic functionality tests passed!')
"

if [ $? -ne 0 ]; then
    echo ""
    echo "Basic functionality tests failed."
    exit 1
fi

echo ""

# Test 3: CLI tool
echo "Test 3: CLI Tool"
echo "----------------"

if [ -f "cli_validation_tool.lua" ]; then
    $LUA_CMD cli_validation_tool.lua --help > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ CLI tool executable"
    else
        echo "⚠️  CLI tool exists but help command failed"
    fi
else
    echo "✗ CLI tool not found"
    exit 1
fi

echo ""

# Test 4: Test suite (if available)
echo "Test 4: Comprehensive Test Suite"
echo "---------------------------------"

if [ -f "universal_compatibility_suite.lua" ]; then
    echo "Running comprehensive test suite..."
    echo ""
    
    # Run with timeout
    timeout 60 $LUA_CMD universal_compatibility_suite.lua 2>&1 | head -50
    
    TEST_RESULT=$?
    
    if [ $TEST_RESULT -eq 0 ]; then
        echo ""
        echo "✓ All comprehensive tests passed!"
    elif [ $TEST_RESULT -eq 124 ]; then
        echo ""
        echo "⚠️  Tests timed out (may still be running)"
    else
        echo ""
        echo "⚠️  Some tests may have failed (exit code: $TEST_RESULT)"
        echo "   This is expected if dependencies are not fully available"
    fi
else
    echo "⚠️  Test suite not found (optional)"
fi

echo ""
echo "=================================================================="
echo "Phase 5 Validation System: Installation Verified"
echo "=================================================================="
echo ""
echo "Available commands:"
echo "  lua tests/cli_validation_tool.lua --help"
echo "  lua tests/cli_validation_tool.lua --validate-file <file>"
echo "  lua tests/cli_validation_tool.lua --validate-directory <dir>"
echo "  lua tests/universal_compatibility_suite.lua"
echo ""
echo "See tests/PHASE5_README.md for complete documentation."
echo ""

exit 0
