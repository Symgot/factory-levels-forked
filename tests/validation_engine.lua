-- Validation Engine for Factorio Mod Syntax & API Validation
-- Phase 5: Extended Syntax Validation & Reverse Engineering System
-- Reference: https://lua-api.factorio.com/latest/

local validation_engine = {}

-- Dependencies
local reverse_parser
local syntax_validator
local api_checker
local false_positive_gen

-- Lazy load dependencies to avoid circular references
local function ensure_dependencies()
    if not reverse_parser then
        reverse_parser = require('reverse_engineering_parser')
    end
    if not syntax_validator then
        syntax_validator = require('syntax_validator')
    end
    if not api_checker then
        api_checker = require('api_reference_checker')
    end
    if not false_positive_gen then
        false_positive_gen = require('false_positive_generator')
    end
end

-- ============================================================================
-- CORE VALIDATION ENGINE
-- ============================================================================

-- Parse a Lua file and return AST
-- @param filepath string: Path to Lua file
-- @return table: AST representation or nil on error
-- @return string: Error message if parse failed
function validation_engine.parse_lua_file(filepath)
    ensure_dependencies()
    
    -- Read file content
    local file, err = io.open(filepath, "r")
    if not file then
        return nil, "Failed to open file: " .. tostring(err)
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Parse Lua code into AST
    local ast, parse_err = reverse_parser.build_ast(content)
    if not ast then
        return nil, "Parse error: " .. tostring(parse_err)
    end
    
    return ast, nil
end

-- Extract all API calls from AST
-- @param ast table: Abstract Syntax Tree
-- @return table: List of API calls with metadata
function validation_engine.extract_api_calls(ast)
    ensure_dependencies()
    
    if not ast then
        return {}
    end
    
    -- Use reverse engineering parser to detect API usage
    local api_calls = reverse_parser.detect_api_usage(ast)
    
    return api_calls or {}
end

-- Validate API references against mock implementation
-- @param api_calls table: List of API calls to validate
-- @return table: Validation results with errors and warnings
function validation_engine.validate_references(api_calls)
    ensure_dependencies()
    
    local results = {
        valid = {},
        invalid = {},
        warnings = {},
        errors = {}
    }
    
    if not api_calls or #api_calls == 0 then
        return results
    end
    
    -- Check each API call against reference checker
    for _, call in ipairs(api_calls) do
        local is_valid, issue = api_checker.check_reference(call)
        
        if is_valid then
            table.insert(results.valid, call)
        else
            table.insert(results.invalid, call)
            table.insert(results.errors, {
                api_call = call,
                reason = issue
            })
        end
    end
    
    return results
end

-- Generate synthetic tests for API elements
-- @param api_elements table: List of API elements to test
-- @return table: Generated test cases
function validation_engine.generate_synthetic_tests(api_elements)
    ensure_dependencies()
    
    if not api_elements or #api_elements == 0 then
        return {}
    end
    
    -- Use false positive generator to create test cases
    local tests = false_positive_gen.generate_api_tests(api_elements)
    
    return tests or {}
end

-- Validate a complete mod archive
-- @param zip_path string: Path to mod .zip archive
-- @return table: Comprehensive validation report
function validation_engine.validate_mod_archive(zip_path)
    local report = {
        success = false,
        mod_name = nil,
        files_validated = 0,
        errors = {},
        warnings = {},
        api_coverage = {},
        syntax_issues = {}
    }
    
    -- Check if file exists
    local file = io.open(zip_path, "rb")
    if not file then
        table.insert(report.errors, "Cannot open archive: " .. zip_path)
        return report
    end
    file:close()
    
    -- TODO: Implement ZIP extraction and validation
    -- For now, return placeholder
    report.success = true
    table.insert(report.warnings, "ZIP archive validation not yet implemented")
    
    return report
end

-- ============================================================================
-- BATCH VALIDATION
-- ============================================================================

-- Validate multiple files in a directory
-- @param directory string: Path to directory
-- @param recursive boolean: Whether to scan recursively
-- @return table: Aggregated validation results
function validation_engine.validate_directory(directory, recursive)
    local results = {
        total_files = 0,
        validated_files = 0,
        failed_files = 0,
        errors = {},
        warnings = {},
        file_reports = {}
    }
    
    -- Find all .lua files
    local lua_files = validation_engine.find_lua_files(directory, recursive)
    results.total_files = #lua_files
    
    -- Validate each file
    for _, filepath in ipairs(lua_files) do
        local file_result = validation_engine.validate_file(filepath)
        table.insert(results.file_reports, file_result)
        
        if file_result.success then
            results.validated_files = results.validated_files + 1
        else
            results.failed_files = results.failed_files + 1
            for _, err in ipairs(file_result.errors) do
                table.insert(results.errors, {
                    file = filepath,
                    error = err
                })
            end
        end
        
        for _, warn in ipairs(file_result.warnings or {}) do
            table.insert(results.warnings, {
                file = filepath,
                warning = warn
            })
        end
    end
    
    return results
end

-- Validate a single file
-- @param filepath string: Path to file
-- @return table: Validation report for file
function validation_engine.validate_file(filepath)
    local report = {
        file = filepath,
        success = false,
        errors = {},
        warnings = {},
        api_calls = {},
        syntax_valid = false
    }
    
    -- Parse file
    local ast, parse_err = validation_engine.parse_lua_file(filepath)
    if not ast then
        table.insert(report.errors, "Parse failed: " .. tostring(parse_err))
        return report
    end
    
    -- Syntax validation
    ensure_dependencies()
    local syntax_valid, syntax_issues = syntax_validator.validate_syntax(ast)
    report.syntax_valid = syntax_valid
    
    if not syntax_valid then
        for _, issue in ipairs(syntax_issues or {}) do
            table.insert(report.errors, "Syntax error: " .. tostring(issue))
        end
    end
    
    -- Extract API calls
    local api_calls = validation_engine.extract_api_calls(ast)
    report.api_calls = api_calls
    
    -- Validate API references
    local ref_results = validation_engine.validate_references(api_calls)
    
    for _, err in ipairs(ref_results.errors) do
        table.insert(report.errors, "API error: " .. tostring(err.reason))
    end
    
    for _, warn in ipairs(ref_results.warnings) do
        table.insert(report.warnings, tostring(warn))
    end
    
    -- Success if no errors
    report.success = #report.errors == 0
    
    return report
end

-- Find all Lua files in directory
-- @param directory string: Path to directory
-- @param recursive boolean: Whether to scan recursively
-- @return table: List of file paths
function validation_engine.find_lua_files(directory, recursive)
    local files = {}
    
    -- Use shell command to find files
    local cmd = recursive 
        and string.format('find "%s" -type f -name "*.lua" 2>/dev/null', directory)
        or string.format('find "%s" -maxdepth 1 -type f -name "*.lua" 2>/dev/null', directory)
    
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            table.insert(files, line)
        end
        handle:close()
    end
    
    return files
end

-- ============================================================================
-- REPORT GENERATION
-- ============================================================================

-- Generate detailed validation report
-- @param results table: Validation results
-- @return string: Formatted report
function validation_engine.generate_report(results)
    local lines = {}
    
    table.insert(lines, "===========================================")
    table.insert(lines, "Factorio Mod Validation Report")
    table.insert(lines, "===========================================")
    table.insert(lines, "")
    
    if results.total_files then
        table.insert(lines, string.format("Total files: %d", results.total_files))
        table.insert(lines, string.format("Validated: %d", results.validated_files))
        table.insert(lines, string.format("Failed: %d", results.failed_files))
        table.insert(lines, "")
    end
    
    if #results.errors > 0 then
        table.insert(lines, "ERRORS:")
        for i, err in ipairs(results.errors) do
            if err.file then
                table.insert(lines, string.format("  [%d] %s: %s", i, err.file, err.error))
            else
                table.insert(lines, string.format("  [%d] %s", i, tostring(err)))
            end
        end
        table.insert(lines, "")
    end
    
    if #results.warnings > 0 then
        table.insert(lines, "WARNINGS:")
        for i, warn in ipairs(results.warnings) do
            if warn.file then
                table.insert(lines, string.format("  [%d] %s: %s", i, warn.file, warn.warning))
            else
                table.insert(lines, string.format("  [%d] %s", i, tostring(warn)))
            end
        end
        table.insert(lines, "")
    end
    
    table.insert(lines, "===========================================")
    
    return table.concat(lines, "\n")
end

-- ============================================================================
-- COVERAGE ANALYSIS
-- ============================================================================

-- Analyze API coverage for a mod
-- @param directory string: Path to mod directory
-- @return table: Coverage statistics
function validation_engine.analyze_api_coverage(directory)
    local coverage = {
        total_api_elements = 0,
        used_api_elements = 0,
        unused_api_elements = {},
        coverage_percentage = 0.0,
        api_usage_count = {}
    }
    
    -- Validate directory to get API calls
    local results = validation_engine.validate_directory(directory, true)
    
    -- Count unique API elements used
    local used_apis = {}
    for _, report in ipairs(results.file_reports) do
        for _, api_call in ipairs(report.api_calls or {}) do
            local api_name = api_call.name or tostring(api_call)
            used_apis[api_name] = (used_apis[api_name] or 0) + 1
        end
    end
    
    coverage.used_api_elements = 0
    for api_name, count in pairs(used_apis) do
        coverage.used_api_elements = coverage.used_api_elements + 1
        coverage.api_usage_count[api_name] = count
    end
    
    -- Get total API elements from API reference checker
    local api_reference_checker = require('api_reference_checker')
    local all_elements = api_reference_checker.get_all_api_elements()
    coverage.total_api_elements = #all_elements
    
    if coverage.total_api_elements > 0 then
        coverage.coverage_percentage = (coverage.used_api_elements / coverage.total_api_elements) * 100
    end
    
    return coverage
end

-- ============================================================================
-- INTEGRATION HELPERS
-- ============================================================================

-- Initialize validation engine with custom configuration
-- @param config table: Configuration options
function validation_engine.init(config)
    config = config or {}
    
    -- Store configuration
    validation_engine.config = {
        strict_mode = config.strict_mode or false,
        enable_warnings = config.enable_warnings ~= false,
        max_errors = config.max_errors or 100,
        verbose = config.verbose or false
    }
    
    -- Initialize dependencies
    ensure_dependencies()
end

-- Get validation engine version
-- @return string: Version string
function validation_engine.get_version()
    return "1.0.0-phase5"
end

-- Check if validation engine is ready
-- @return boolean: True if ready
function validation_engine.is_ready()
    local ok = pcall(ensure_dependencies)
    return ok
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return validation_engine
