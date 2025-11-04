#!/usr/bin/env lua
-- CLI Validation Tool for Factorio Mods
-- Phase 5: Extended Syntax Validation & Reverse Engineering System

-- Add current directory to package path
package.path = package.path .. ";./?.lua;./?/init.lua"

-- Load dependencies
local validation_engine = require('validation_engine')
local mod_archive_validator = require('mod_archive_validator')
local false_positive_generator = require('false_positive_generator')
local api_reference_checker = require('api_reference_checker')

-- ============================================================================
-- CLI INTERFACE
-- ============================================================================

local cli_tool = {}

-- Print usage information
function cli_tool.print_usage()
    print([[
Factorio Mod Validation Tool - Phase 5
=======================================

Usage: lua cli_validation_tool.lua [OPTIONS] <target>

OPTIONS:
    --validate-file <file>          Validate single Lua file
    --validate-directory <dir>      Validate all Lua files in directory
    --validate-archive <zip>        Validate mod ZIP archive
    --batch-validate <pattern>      Validate multiple archives (glob pattern)
    --generate-tests                Generate automated test cases
    --api-coverage [dir]            Analyze API coverage
    --false-positive-tests          Generate false positive tests
    --iterations <n>                Number of iterations for generation
    --help                          Show this help message

EXAMPLES:
    # Validate single file
    lua cli_validation_tool.lua --validate-file control.lua
    
    # Validate directory
    lua cli_validation_tool.lua --validate-directory my-mod/
    
    # Validate archive
    lua cli_validation_tool.lua --validate-archive my-mod_1.0.0.zip
    
    # Batch validate
    lua cli_validation_tool.lua --batch-validate "mods/*.zip"
    
    # Generate tests
    lua cli_validation_tool.lua --generate-tests --api-coverage=100%
    
    # Generate false positive tests
    lua cli_validation_tool.lua --false-positive-tests --iterations=1000
]])
end

-- ============================================================================
-- COMMAND HANDLERS
-- ============================================================================

-- Validate single file
-- @param filepath string: Path to file
function cli_tool.validate_file(filepath)
    print("Validating file: " .. filepath)
    print("")
    
    local report = validation_engine.validate_file(filepath)
    
    -- Print results
    print(string.format("File: %s", report.file))
    print(string.format("Status: %s", report.success and "VALID" or "INVALID"))
    print(string.format("Syntax valid: %s", report.syntax_valid and "YES" or "NO"))
    print(string.format("API calls found: %d", #report.api_calls))
    print("")
    
    if #report.errors > 0 then
        print("ERRORS:")
        for i, err in ipairs(report.errors) do
            print(string.format("  [%d] %s", i, err))
        end
        print("")
    end
    
    if #report.warnings > 0 then
        print("WARNINGS:")
        for i, warn in ipairs(report.warnings) do
            print(string.format("  [%d] %s", i, warn))
        end
        print("")
    end
    
    return report.success and 0 or 1
end

-- Validate directory
-- @param directory string: Path to directory
function cli_tool.validate_directory(directory)
    print("Validating directory: " .. directory)
    print("")
    
    local results = validation_engine.validate_directory(directory, true)
    
    print(validation_engine.generate_report(results))
    
    return results.failed_files == 0 and 0 or 1
end

-- Validate archive
-- @param zip_path string: Path to ZIP archive
function cli_tool.validate_archive(zip_path)
    print("Validating archive: " .. zip_path)
    print("")
    
    local report = mod_archive_validator.validate_mod_archive(zip_path)
    
    print(mod_archive_validator.generate_report(report))
    
    return report.success and 0 or 1
end

-- Batch validate archives
-- @param pattern string: Glob pattern for archives
function cli_tool.batch_validate(pattern)
    print("Batch validating archives: " .. pattern)
    print("")
    
    -- Find matching files
    local cmd = string.format('ls %s 2>/dev/null', pattern)
    local handle = io.popen(cmd)
    local zip_paths = {}
    
    if handle then
        for line in handle:lines() do
            table.insert(zip_paths, line)
        end
        handle:close()
    end
    
    print(string.format("Found %d archive(s)", #zip_paths))
    print("")
    
    if #zip_paths == 0 then
        print("No archives found matching pattern: " .. pattern)
        return 1
    end
    
    local results = mod_archive_validator.validate_multiple(zip_paths)
    
    print(string.format("Total archives: %d", results.total_archives))
    print(string.format("Validated: %d", results.validated))
    print(string.format("Failed: %d", results.failed))
    print("")
    
    -- Print individual results
    for i, report in ipairs(results.reports) do
        print(string.format("[%d/%d] %s: %s", 
            i, #results.reports,
            report.mod_name or "unknown",
            report.success and "VALID" or "INVALID"))
    end
    
    return results.failed == 0 and 0 or 1
end

-- Generate tests
-- @param options table: Generation options
function cli_tool.generate_tests(options)
    print("Generating automated test cases...")
    print("")
    
    -- Get all API elements
    local api_elements = api_reference_checker.get_all_api_elements()
    
    print(string.format("Found %d API elements", #api_elements))
    print("")
    
    -- Generate test suite
    local test_suite = false_positive_generator.generate_test_suite(api_elements)
    
    print(string.format("Generated %d tests", #test_suite.tests))
    print(string.format("Coverage: %.2f%%", test_suite.coverage.coverage_percentage))
    print("")
    
    -- Export to file
    local output_path = options.output or "generated_tests.lua"
    local ok, err = false_positive_generator.export_test_suite(test_suite, output_path)
    
    if ok then
        print("Tests exported to: " .. output_path)
        return 0
    else
        print("Failed to export tests: " .. tostring(err))
        return 1
    end
end

-- Analyze API coverage
-- @param directory string: Path to directory
function cli_tool.analyze_api_coverage(directory)
    print("Analyzing API coverage: " .. (directory or "."))
    print("")
    
    local coverage = validation_engine.analyze_api_coverage(directory or ".")
    
    print(string.format("Total API elements: %d", coverage.total_api_elements))
    print(string.format("Used API elements: %d", coverage.used_api_elements))
    print(string.format("Coverage: %.2f%%", coverage.coverage_percentage))
    print("")
    
    if #coverage.api_usage_count > 0 then
        print("Top API usage:")
        local sorted = {}
        for api_name, count in pairs(coverage.api_usage_count) do
            table.insert(sorted, {name = api_name, count = count})
        end
        table.sort(sorted, function(a, b) return a.count > b.count end)
        
        for i = 1, math.min(10, #sorted) do
            print(string.format("  %s: %d", sorted[i].name, sorted[i].count))
        end
    end
    
    return 0
end

-- Generate false positive tests
-- @param options table: Generation options
function cli_tool.generate_false_positive_tests(options)
    local iterations = options.iterations or 100
    
    print(string.format("Generating %d false positive tests...", iterations))
    print("")
    
    -- Get sample API elements
    local api_elements = api_reference_checker.get_all_api_elements()
    
    -- Take subset based on iterations
    local subset = {}
    for i = 1, math.min(iterations, #api_elements) do
        table.insert(subset, api_elements[i])
    end
    
    -- Generate tests
    local test_suite = false_positive_generator.generate_test_suite(subset)
    
    print(string.format("Generated %d tests", #test_suite.tests))
    print(string.format("Positive tests: %d", test_suite.coverage.positive_tests))
    print(string.format("Negative tests: %d", test_suite.coverage.negative_tests))
    print(string.format("Edge tests: %d", test_suite.coverage.edge_tests))
    print("")
    
    -- Export
    local output_path = options.output or "false_positive_tests.lua"
    local ok, err = false_positive_generator.export_test_suite(test_suite, output_path)
    
    if ok then
        print("Tests exported to: " .. output_path)
        return 0
    else
        print("Failed to export tests: " .. tostring(err))
        return 1
    end
end

-- ============================================================================
-- ARGUMENT PARSING
-- ============================================================================

-- Parse command line arguments
-- @param args table: Command line arguments
-- @return table: Parsed options
function cli_tool.parse_args(args)
    local options = {
        command = nil,
        target = nil,
        iterations = 100,
        api_coverage = false,
        output = nil
    }
    
    local i = 1
    while i <= #args do
        local arg = args[i]
        
        if arg == "--help" or arg == "-h" then
            options.command = "help"
            return options
        elseif arg == "--validate-file" then
            options.command = "validate_file"
            i = i + 1
            options.target = args[i]
        elseif arg == "--validate-directory" then
            options.command = "validate_directory"
            i = i + 1
            options.target = args[i]
        elseif arg == "--validate-archive" then
            options.command = "validate_archive"
            i = i + 1
            options.target = args[i]
        elseif arg == "--batch-validate" then
            options.command = "batch_validate"
            i = i + 1
            options.target = args[i]
        elseif arg == "--generate-tests" then
            options.command = "generate_tests"
        elseif arg == "--api-coverage" then
            if i + 1 <= #args and not args[i+1]:match("^%-%-") then
                i = i + 1
                options.target = args[i]
            end
            options.command = "api_coverage"
        elseif arg == "--false-positive-tests" then
            options.command = "false_positive_tests"
        elseif arg == "--iterations" then
            i = i + 1
            options.iterations = tonumber(args[i]) or 100
        elseif arg == "--output" or arg == "-o" then
            i = i + 1
            options.output = args[i]
        end
        
        i = i + 1
    end
    
    return options
end

-- ============================================================================
-- MAIN ENTRY POINT
-- ============================================================================

-- Main function
-- @param args table: Command line arguments
-- @return number: Exit code
function cli_tool.main(args)
    local options = cli_tool.parse_args(args)
    
    if not options.command or options.command == "help" then
        cli_tool.print_usage()
        return 0
    end
    
    -- Dispatch to appropriate handler
    if options.command == "validate_file" then
        if not options.target then
            print("Error: No file specified")
            return 1
        end
        return cli_tool.validate_file(options.target)
        
    elseif options.command == "validate_directory" then
        if not options.target then
            print("Error: No directory specified")
            return 1
        end
        return cli_tool.validate_directory(options.target)
        
    elseif options.command == "validate_archive" then
        if not options.target then
            print("Error: No archive specified")
            return 1
        end
        return cli_tool.validate_archive(options.target)
        
    elseif options.command == "batch_validate" then
        if not options.target then
            print("Error: No pattern specified")
            return 1
        end
        return cli_tool.batch_validate(options.target)
        
    elseif options.command == "generate_tests" then
        return cli_tool.generate_tests(options)
        
    elseif options.command == "api_coverage" then
        return cli_tool.analyze_api_coverage(options.target)
        
    elseif options.command == "false_positive_tests" then
        return cli_tool.generate_false_positive_tests(options)
        
    else
        print("Error: Unknown command: " .. tostring(options.command))
        return 1
    end
end

-- ============================================================================
-- EXECUTE IF RUN AS SCRIPT
-- ============================================================================

if arg then
    local exit_code = cli_tool.main(arg)
    os.exit(exit_code)
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return cli_tool
