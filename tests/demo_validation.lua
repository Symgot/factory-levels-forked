-- Example: Complete Validation Workflow
-- This demonstrates Phase 5 validation system capabilities

package.path = package.path .. ";./?.lua;./tests/?.lua"

print("=========================================")
print("Phase 5 Validation System - Demo")
print("=========================================")
print("")

-- Load all modules
local validation_engine = require('validation_engine')
local reverse_parser = require('reverse_engineering_parser')
local syntax_validator = require('syntax_validator')
local false_positive_generator = require('false_positive_generator')
local api_reference_checker = require('api_reference_checker')

-- ============================================================================
-- DEMO 1: Parse and Analyze Lua Code
-- ============================================================================

print("Demo 1: Parse and Analyze Lua Code")
print("-----------------------------------")

local sample_code = [[
-- Sample Factorio mod code
local my_mod = {}

function my_mod.on_built(event)
    local entity = event.entity
    if entity.type == "assembling-machine" then
        game.print("Assembling machine built: " .. entity.name)
        entity.active = true
    end
end

script.on_event(defines.events.on_built_entity, my_mod.on_built)

return my_mod
]]

print("Parsing code...")
local ast, parse_err = reverse_parser.build_ast(sample_code)

if ast then
    print("✓ Code parsed successfully")
    
    -- Extract functions
    local functions = reverse_parser.extract_functions(ast)
    print(string.format("  Found %d function(s)", #functions))
    for _, func in ipairs(functions) do
        if func.name then
            print(string.format("    - %s", func.name))
        end
    end
    
    -- Detect API usage
    local api_calls = reverse_parser.detect_api_usage(ast)
    print(string.format("  Found %d API call(s)", #api_calls))
    for _, call in ipairs(api_calls) do
        print(string.format("    - %s.%s (%s)", 
            call.namespace, call.member or "", call.type))
    end
    
    -- Calculate metrics
    local metrics = reverse_parser.calculate_metrics(ast)
    print(string.format("  Metrics:"))
    print(string.format("    - Total lines: %d", metrics.total_lines))
    print(string.format("    - Code lines: %d", metrics.code_lines))
    print(string.format("    - Functions: %d", metrics.functions))
    print(string.format("    - Complexity: %d", metrics.complexity))
else
    print("✗ Parse error: " .. tostring(parse_err))
end

print("")

-- ============================================================================
-- DEMO 2: Validate Syntax
-- ============================================================================

print("Demo 2: Validate Syntax")
print("-----------------------")

local syntax_report = syntax_validator.validate_all(ast, {
    validate_factorio = true,
    validate_style = true,
    validate_complexity = true
})

print(string.format("Syntax valid: %s", syntax_report.syntax_valid and "YES" or "NO"))
print(string.format("Errors: %d", #syntax_report.errors))
print(string.format("Warnings: %d", #syntax_report.warnings))
print(string.format("Style warnings: %d", #syntax_report.style_warnings))

if #syntax_report.errors > 0 then
    print("Errors found:")
    for i, err in ipairs(syntax_report.errors) do
        print(string.format("  [%d] %s", i, err))
    end
end

print("")

-- ============================================================================
-- DEMO 3: Validate API References
-- ============================================================================

print("Demo 3: Validate API References")
print("--------------------------------")

local api_results = api_reference_checker.validate_all(api_calls)

print(string.format("Valid API calls: %d", #api_results.valid))
print(string.format("Invalid API calls: %d", #api_results.invalid))
print(string.format("Deprecated API calls: %d", #api_results.deprecated))

if #api_results.invalid > 0 then
    print("Invalid calls:")
    for _, invalid in ipairs(api_results.invalid) do
        print(string.format("  - %s: %s", 
            invalid.api_call.full_name or "unknown", 
            invalid.reason))
    end
end

if #api_results.deprecated > 0 then
    print("Deprecated calls:")
    for _, deprecated in ipairs(api_results.deprecated) do
        local info = deprecated.info
        print(string.format("  - %s", 
            deprecated.api_call.full_name or "unknown"))
        print(string.format("    Reason: %s", info.reason))
        print(string.format("    Replacement: %s", info.replacement))
    end
end

print("")

-- ============================================================================
-- DEMO 4: Generate Test Cases
-- ============================================================================

print("Demo 4: Generate Test Cases")
print("---------------------------")

-- Get sample API elements
local sample_elements = {
    {name = "game.print", namespace = "game", member = "print", type = "method"},
    {name = "game.tick", namespace = "game", member = "tick", type = "property"},
    {name = "script.on_event", namespace = "script", member = "on_event", type = "method"}
}

print(string.format("Generating tests for %d API elements...", #sample_elements))

local test_suite = false_positive_generator.generate_test_suite(sample_elements)

print(string.format("Generated %d tests", #test_suite.tests))
print(string.format("  Positive tests: %d", test_suite.coverage.positive_tests))
print(string.format("  Negative tests: %d", test_suite.coverage.negative_tests))
print(string.format("  Edge tests: %d", test_suite.coverage.edge_tests))
print(string.format("Coverage: %.2f%%", test_suite.coverage.coverage_percentage))

-- Show sample test
if #test_suite.tests > 0 then
    local sample_test = test_suite.tests[1]
    print("")
    print("Sample generated test:")
    print("  Name: " .. sample_test.name)
    print("  Type: " .. sample_test.type)
    print("  Description: " .. sample_test.description)
    print("  Code:")
    for line in sample_test.code:gmatch("[^\r\n]+") do
        print("    " .. line)
    end
end

print("")

-- ============================================================================
-- DEMO 5: API Coverage Analysis
-- ============================================================================

print("Demo 5: API Coverage Analysis")
print("------------------------------")

local all_apis = api_reference_checker.get_all_api_elements()
local coverage = api_reference_checker.calculate_coverage(api_calls)

print(string.format("Total known APIs: %d", #all_apis))
print(string.format("APIs used in code: %d", #api_calls))
print(string.format("Coverage: %.2f%%", coverage.coverage_percentage))

print("")

-- ============================================================================
-- DEMO 6: Statistics Summary
-- ============================================================================

print("Demo 6: Statistics Summary")
print("--------------------------")

local stats = reverse_parser.get_statistics(ast)

print("AST Statistics:")
print(string.format("  Total nodes: %d", stats.nodes))
print(string.format("  Max depth: %d", stats.depth))
print(string.format("  Functions: %d", stats.functions))
print(string.format("  Variables: %d", stats.variables))
print(string.format("  API calls: %d", stats.api_calls))

print("")

-- ============================================================================
-- Summary
-- ============================================================================

print("=========================================")
print("Demo Complete!")
print("=========================================")
print("")
print("Phase 5 Validation System provides:")
print("  ✓ Lua code parsing and AST generation")
print("  ✓ Comprehensive syntax validation")
print("  ✓ API reference checking")
print("  ✓ Deprecated API detection")
print("  ✓ Automated test generation")
print("  ✓ Code metrics and statistics")
print("  ✓ Complete validation reports")
print("")
print("For more information, see:")
print("  - PHASE5_COMPLETION.md")
print("  - tests/PHASE5_README.md")
print("  - tests/cli_validation_tool.lua --help")
print("")
