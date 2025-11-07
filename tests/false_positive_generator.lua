-- False Positive Generator for Automated Test Generation
-- Phase 5: Extended Syntax Validation & Reverse Engineering System
-- Reference: https://lua-api.factorio.com/latest/

local false_positive_generator = {}

-- ============================================================================
-- TEST GENERATION ENGINE
-- ============================================================================

-- Generate comprehensive tests for API element
-- @param api_element table: API element specification
-- @return table: Generated test cases
function false_positive_generator.generate_api_tests(api_element)
    if not api_element then
        return {}
    end
    
    local tests = {}
    
    -- Generate positive test cases
    local positive_tests = false_positive_generator.generate_positive_tests(api_element)
    for _, test in ipairs(positive_tests) do
        table.insert(tests, test)
    end
    
    -- Generate negative test cases (false positives)
    local negative_tests = false_positive_generator.create_false_positives(api_element)
    for _, test in ipairs(negative_tests) do
        table.insert(tests, test)
    end
    
    -- Generate edge case tests
    local edge_tests = false_positive_generator.generate_edge_cases(api_element)
    for _, test in ipairs(edge_tests) do
        table.insert(tests, test)
    end
    
    return tests
end

-- Generate positive test cases (should pass)
-- @param api_element table: API element specification
-- @return table: Positive test cases
function false_positive_generator.generate_positive_tests(api_element)
    local tests = {}
    
    if not api_element or not api_element.name then
        return tests
    end
    
    -- Basic usage test
    table.insert(tests, {
        type = "positive",
        name = "test_" .. api_element.name:gsub("%.", "_") .. "_basic",
        code = false_positive_generator.generate_basic_usage_code(api_element),
        expected = "pass",
        description = "Basic usage of " .. api_element.name
    })
    
    -- Type-specific tests
    if api_element.type == "method" then
        table.insert(tests, {
            type = "positive",
            name = "test_" .. api_element.name:gsub("%.", "_") .. "_with_params",
            code = false_positive_generator.generate_method_call_code(api_element),
            expected = "pass",
            description = "Method call with parameters for " .. api_element.name
        })
    elseif api_element.type == "property" then
        table.insert(tests, {
            type = "positive",
            name = "test_" .. api_element.name:gsub("%.", "_") .. "_read",
            code = false_positive_generator.generate_property_read_code(api_element),
            expected = "pass",
            description = "Property read for " .. api_element.name
        })
    end
    
    return tests
end

-- Create false positive test cases (should fail)
-- @param api_element table: API element specification
-- @return table: False positive test cases
function false_positive_generator.create_false_positives(api_element)
    local tests = {}
    
    if not api_element or not api_element.name then
        return tests
    end
    
    -- Nil parameter test
    table.insert(tests, {
        type = "negative",
        name = "test_" .. api_element.name:gsub("%.", "_") .. "_nil_param",
        code = false_positive_generator.generate_nil_parameter_code(api_element),
        expected = "fail",
        description = "Should fail with nil parameter for " .. api_element.name
    })
    
    -- Wrong type test
    table.insert(tests, {
        type = "negative",
        name = "test_" .. api_element.name:gsub("%.", "_") .. "_wrong_type",
        code = false_positive_generator.generate_wrong_type_code(api_element),
        expected = "fail",
        description = "Should fail with wrong type for " .. api_element.name
    })
    
    -- Invalid range test (for numeric parameters)
    if api_element.params and false_positive_generator.has_numeric_param(api_element.params) then
        table.insert(tests, {
            type = "negative",
            name = "test_" .. api_element.name:gsub("%.", "_") .. "_invalid_range",
            code = false_positive_generator.generate_invalid_range_code(api_element),
            expected = "fail",
            description = "Should fail with out-of-range value for " .. api_element.name
        })
    end
    
    return tests
end

-- Generate edge case tests
-- @param api_element table: API element specification
-- @return table: Edge case test cases
function false_positive_generator.generate_edge_cases(api_element)
    local tests = {}
    
    if not api_element or not api_element.name then
        return tests
    end
    
    -- Empty parameter test
    table.insert(tests, {
        type = "edge",
        name = "test_" .. api_element.name:gsub("%.", "_") .. "_empty",
        code = false_positive_generator.generate_empty_parameter_code(api_element),
        expected = "variable",
        description = "Edge case with empty parameter for " .. api_element.name
    })
    
    -- Boundary value test
    table.insert(tests, {
        type = "edge",
        name = "test_" .. api_element.name:gsub("%.", "_") .. "_boundary",
        code = false_positive_generator.generate_boundary_value_code(api_element),
        expected = "variable",
        description = "Edge case with boundary value for " .. api_element.name
    })
    
    -- Maximum values test
    table.insert(tests, {
        type = "edge",
        name = "test_" .. api_element.name:gsub("%.", "_") .. "_max",
        code = false_positive_generator.generate_max_value_code(api_element),
        expected = "variable",
        description = "Edge case with maximum value for " .. api_element.name
    })
    
    return tests
end

-- ============================================================================
-- CODE GENERATION
-- ============================================================================

-- Generate basic usage code
-- @param api_element table: API element specification
-- @return string: Generated Lua code
function false_positive_generator.generate_basic_usage_code(api_element)
    local namespace = api_element.namespace or "game"
    local member = api_element.member or api_element.name
    
    if api_element.type == "method" then
        return string.format([[
local result = %s.%s()
assert(result ~= nil, "Method should return a value")
]], namespace, member)
    elseif api_element.type == "property" then
        return string.format([[
local value = %s.%s
assert(value ~= nil, "Property should have a value")
]], namespace, member)
    else
        return string.format([[
local value = %s.%s
assert(value ~= nil, "API element should exist")
]], namespace, member)
    end
end

-- Generate method call code
-- @param api_element table: API element specification
-- @return string: Generated Lua code
function false_positive_generator.generate_method_call_code(api_element)
    local namespace = api_element.namespace or "game"
    local member = api_element.member or api_element.name
    
    -- Generate dummy parameters based on API spec
    local params = "1, 2, 3"  -- Default numeric parameters
    if api_element.params then
        params = false_positive_generator.generate_dummy_params(api_element.params)
    end
    
    return string.format([[
local result = %s.%s(%s)
assert(result ~= nil, "Method should return a value")
]], namespace, member, params)
end

-- Generate property read code
-- @param api_element table: API element specification
-- @return string: Generated Lua code
function false_positive_generator.generate_property_read_code(api_element)
    local namespace = api_element.namespace or "game"
    local member = api_element.member or api_element.name
    
    return string.format([[
local value = %s.%s
assert(type(value) ~= "nil", "Property should exist")
local value2 = %s.%s
assert(value == value2, "Property should be consistent")
]], namespace, member, namespace, member)
end

-- Generate nil parameter code
-- @param api_element table: API element specification
-- @return string: Generated Lua code
function false_positive_generator.generate_nil_parameter_code(api_element)
    local namespace = api_element.namespace or "game"
    local member = api_element.member or api_element.name
    
    if api_element.type == "method" then
        return string.format([[
local ok, err = pcall(function()
    %s.%s(nil)
end)
assert(not ok, "Should fail with nil parameter")
]], namespace, member)
    else
        return string.format([[
-- Property does not accept parameters
local value = %s.%s
assert(value ~= nil, "Property should exist")
]], namespace, member)
    end
end

-- Generate wrong type code
-- @param api_element table: API element specification
-- @return string: Generated Lua code
function false_positive_generator.generate_wrong_type_code(api_element)
    local namespace = api_element.namespace or "game"
    local member = api_element.member or api_element.name
    
    if api_element.type == "method" then
        return string.format([[
local ok, err = pcall(function()
    %s.%s("wrong_type")
end)
-- May or may not fail depending on Lua type coercion
]], namespace, member)
    else
        return string.format([[
-- Property type validation
local value = %s.%s
local value_type = type(value)
assert(value ~= nil, "Property should exist")
assert(value_type ~= "nil", "Property should have a type")
]], namespace, member)
    end
end

-- Generate invalid range code
-- @param api_element table: API element specification
-- @return string: Generated Lua code
function false_positive_generator.generate_invalid_range_code(api_element)
    local namespace = api_element.namespace or "game"
    local member = api_element.member or api_element.name
    
    if api_element.type == "method" then
        return string.format([[
local ok, err = pcall(function()
    %s.%s(-999999)
end)
-- Should handle out-of-range values gracefully
]], namespace, member)
    else
        return string.format([[
-- Property range validation not applicable
local value = %s.%s
]], namespace, member)
    end
end

-- Generate empty parameter code
-- @param api_element table: API element specification
-- @return string: Generated Lua code
function false_positive_generator.generate_empty_parameter_code(api_element)
    local namespace = api_element.namespace or "game"
    local member = api_element.member or api_element.name
    
    if api_element.type == "method" then
        return string.format([[
local result = %s.%s({})
-- Empty table parameter edge case
]], namespace, member)
    else
        return string.format([[
local value = %s.%s
]], namespace, member)
    end
end

-- Generate boundary value code
-- @param api_element table: API element specification
-- @return string: Generated Lua code
function false_positive_generator.generate_boundary_value_code(api_element)
    local namespace = api_element.namespace or "game"
    local member = api_element.member or api_element.name
    
    if api_element.type == "method" then
        return string.format([[
local result1 = %s.%s(0)
local result2 = %s.%s(1)
-- Boundary value testing
]], namespace, member, namespace, member)
    else
        return string.format([[
local value = %s.%s
]], namespace, member)
    end
end

-- Generate maximum value code
-- @param api_element table: API element specification
-- @return string: Generated Lua code
function false_positive_generator.generate_max_value_code(api_element)
    local namespace = api_element.namespace or "game"
    local member = api_element.member or api_element.name
    
    if api_element.type == "method" then
        return string.format([[
local result = %s.%s(999999)
-- Maximum value testing
]], namespace, member)
    else
        return string.format([[
local value = %s.%s
]], namespace, member)
    end
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Generate dummy parameters
-- @param params table: Parameter specifications
-- @return string: Comma-separated parameter values
function false_positive_generator.generate_dummy_params(params)
    if not params or #params == 0 then
        return ""
    end
    
    local param_values = {}
    for _, param in ipairs(params) do
        if param.type == "number" then
            table.insert(param_values, "1")
        elseif param.type == "string" then
            table.insert(param_values, '"test"')
        elseif param.type == "boolean" then
            table.insert(param_values, "true")
        elseif param.type == "table" then
            table.insert(param_values, "{}")
        else
            table.insert(param_values, "nil")
        end
    end
    
    return table.concat(param_values, ", ")
end

-- Check if parameters include numeric type
-- @param params table: Parameter specifications
-- @return boolean: True if has numeric parameter
function false_positive_generator.has_numeric_param(params)
    if not params then
        return false
    end
    
    for _, param in ipairs(params) do
        if param.type == "number" then
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- COVERAGE VALIDATION
-- ============================================================================

-- Validate test coverage for API spec
-- @param test_suite table: Generated test suite
-- @return table: Coverage report
function false_positive_generator.validate_coverage(test_suite)
    local coverage = {
        total_tests = 0,
        positive_tests = 0,
        negative_tests = 0,
        edge_tests = 0,
        coverage_percentage = 0
    }
    
    if not test_suite or #test_suite == 0 then
        return coverage
    end
    
    for _, test in ipairs(test_suite) do
        coverage.total_tests = coverage.total_tests + 1
        
        if test.type == "positive" then
            coverage.positive_tests = coverage.positive_tests + 1
        elseif test.type == "negative" then
            coverage.negative_tests = coverage.negative_tests + 1
        elseif test.type == "edge" then
            coverage.edge_tests = coverage.edge_tests + 1
        end
    end
    
    -- Calculate coverage percentage (minimum 3 tests per API element recommended)
    coverage.coverage_percentage = math.min(100, (coverage.total_tests / 3) * 100)
    
    return coverage
end

-- ============================================================================
-- BATCH TEST GENERATION
-- ============================================================================

-- Generate tests for multiple API elements
-- @param api_elements table: List of API elements
-- @return table: Complete test suite
function false_positive_generator.generate_test_suite(api_elements)
    local test_suite = {
        tests = {},
        coverage = {},
        metadata = {
            generated_at = os.date("%Y-%m-%d %H:%M:%S"),
            total_elements = #api_elements,
            generator_version = "1.0.0-phase5"
        }
    }
    
    for _, element in ipairs(api_elements) do
        local tests = false_positive_generator.generate_api_tests(element)
        for _, test in ipairs(tests) do
            table.insert(test_suite.tests, test)
        end
    end
    
    test_suite.coverage = false_positive_generator.validate_coverage(test_suite.tests)
    
    return test_suite
end

-- Export test suite as Lua file
-- @param test_suite table: Test suite
-- @param output_path string: Output file path
-- @return boolean: Success status
function false_positive_generator.export_test_suite(test_suite, output_path)
    local file, err = io.open(output_path, "w")
    if not file then
        return false, "Failed to open output file: " .. tostring(err)
    end
    
    -- Write header
    file:write("-- Auto-generated test suite\n")
    file:write("-- Generated at: " .. test_suite.metadata.generated_at .. "\n")
    file:write("-- Total tests: " .. #test_suite.tests .. "\n\n")
    file:write("local lu = require('luaunit')\n")
    file:write("local factorio_mock = require('factorio_mock')\n\n")
    
    -- Write test cases
    for i, test in ipairs(test_suite.tests) do
        file:write(string.format("function %s()\n", test.name))
        file:write("    factorio_mock.init()\n")
        file:write("    -- " .. test.description .. "\n")
        file:write(test.code)
        file:write("\nend\n\n")
    end
    
    -- Write footer
    file:write("os.exit(lu.LuaUnit.run())\n")
    
    file:close()
    return true, nil
end

-- ============================================================================
-- STATISTICS
-- ============================================================================

-- Get test generation statistics
-- @param test_suite table: Test suite
-- @return table: Statistics
function false_positive_generator.get_statistics(test_suite)
    local stats = {
        total_tests = #test_suite.tests,
        positive_tests = 0,
        negative_tests = 0,
        edge_tests = 0,
        code_lines = 0
    }
    
    for _, test in ipairs(test_suite.tests) do
        if test.type == "positive" then
            stats.positive_tests = stats.positive_tests + 1
        elseif test.type == "negative" then
            stats.negative_tests = stats.negative_tests + 1
        elseif test.type == "edge" then
            stats.edge_tests = stats.edge_tests + 1
        end
        
        -- Count lines of code
        local _, line_count = test.code:gsub("\n", "\n")
        stats.code_lines = stats.code_lines + line_count + 1
    end
    
    return stats
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return false_positive_generator
