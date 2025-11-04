-- Universal Compatibility Suite for Factorio Mod Testing
-- Phase 5: Extended Syntax Validation & Reverse Engineering System

local lu = require('luaunit')
local validation_engine = require('validation_engine')
local reverse_parser = require('reverse_engineering_parser')
local syntax_validator = require('syntax_validator')
local false_positive_generator = require('false_positive_generator')
local api_reference_checker = require('api_reference_checker')
local mod_archive_validator = require('mod_archive_validator')

-- ============================================================================
-- TEST SUITE: VALIDATION ENGINE
-- ============================================================================

TestValidationEngine = {}

function TestValidationEngine:testParseValidLuaFile()
    -- Create temporary test file
    local test_file = "/tmp/test_valid.lua"
    local file = io.open(test_file, "w")
    file:write("local x = 1\nreturn x")
    file:close()
    
    local ast, err = validation_engine.parse_lua_file(test_file)
    lu.assertNotNil(ast, "Should parse valid Lua file")
    lu.assertNil(err, "Should not have parse error")
    
    os.remove(test_file)
end

function TestValidationEngine:testParseInvalidFile()
    local ast, err = validation_engine.parse_lua_file("/nonexistent/file.lua")
    lu.assertNil(ast, "Should fail for nonexistent file")
    lu.assertNotNil(err, "Should return error message")
end

function TestValidationEngine:testExtractAPICallsFromAST()
    local ast = {
        tokens = {
            {type = "identifier", value = "game"},
            {type = "operator", value = "."},
            {type = "identifier", value = "print"},
            {type = "operator", value = "("}
        }
    }
    
    local api_calls = validation_engine.extract_api_calls(ast)
    lu.assertNotNil(api_calls, "Should extract API calls")
    lu.assertTrue(#api_calls > 0, "Should find at least one API call")
end

function TestValidationEngine:testValidateReferences()
    local api_calls = {
        {namespace = "game", member = "print", type = "method"},
        {namespace = "invalid", member = "method", type = "method"}
    }
    
    local results = validation_engine.validate_references(api_calls)
    lu.assertNotNil(results, "Should return validation results")
    lu.assertTrue(#results.valid > 0, "Should have valid API calls")
    lu.assertTrue(#results.invalid > 0, "Should have invalid API calls")
end

function TestValidationEngine:testGenerateSyntheticTests()
    local api_elements = {
        {name = "game.print", namespace = "game", member = "print", type = "method"}
    }
    
    local tests = validation_engine.generate_synthetic_tests(api_elements)
    lu.assertNotNil(tests, "Should generate tests")
end

function TestValidationEngine:testFindLuaFiles()
    local files = validation_engine.find_lua_files(".", false)
    lu.assertNotNil(files, "Should return file list")
    lu.assertTrue(type(files) == "table", "Should return table")
end

function TestValidationEngine:testGenerateReport()
    local results = {
        total_files = 10,
        validated_files = 8,
        failed_files = 2,
        errors = {},
        warnings = {}
    }
    
    local report = validation_engine.generate_report(results)
    lu.assertNotNil(report, "Should generate report")
    lu.assertTrue(type(report) == "string", "Report should be string")
    lu.assertTrue(#report > 0, "Report should not be empty")
end

-- ============================================================================
-- TEST SUITE: REVERSE ENGINEERING PARSER
-- ============================================================================

TestReverseParser = {}

function TestReverseParser:testTokenizeSimpleCode()
    local code = "local x = 1"
    local tokens = reverse_parser.tokenize(code)
    
    lu.assertNotNil(tokens, "Should tokenize code")
    lu.assertTrue(#tokens > 0, "Should have tokens")
end

function TestReverseParser:testBuildASTFromCode()
    local code = "function test()\n  return 1\nend"
    local ast, err = reverse_parser.build_ast(code)
    
    lu.assertNotNil(ast, "Should build AST")
    lu.assertNil(err, "Should not have error")
    lu.assertEquals(ast.type, "chunk", "Should be chunk type")
end

function TestReverseParser:testExtractFunctionsFromAST()
    local code = "function test1()\nend\nfunction test2()\nend"
    local ast = reverse_parser.build_ast(code)
    
    local functions = reverse_parser.extract_functions(ast)
    lu.assertNotNil(functions, "Should extract functions")
    lu.assertTrue(#functions >= 2, "Should find at least 2 functions")
end

function TestReverseParser:testTrackVariables()
    local code = "local x = 1\nlocal y = 2"
    local ast = reverse_parser.build_ast(code)
    
    local variables = reverse_parser.track_variables(ast)
    lu.assertNotNil(variables, "Should track variables")
    lu.assertNotNil(variables.local_vars, "Should have local vars")
end

function TestReverseParser:testDetectAPIUsage()
    local code = "game.print('test')\nscript.on_event(1, function() end)"
    local ast = reverse_parser.build_ast(code)
    
    local api_calls = reverse_parser.detect_api_usage(ast)
    lu.assertNotNil(api_calls, "Should detect API usage")
    lu.assertTrue(#api_calls > 0, "Should find API calls")
end

function TestReverseParser:testAnalyzeControlFlow()
    local code = "if true then\n  return 1\nend"
    local ast = reverse_parser.build_ast(code)
    
    local flow = reverse_parser.analyze_control_flow(ast)
    lu.assertNotNil(flow, "Should analyze control flow")
    lu.assertNotNil(flow.complexity, "Should have complexity metric")
end

function TestReverseParser:testCalculateMetrics()
    local code = "function test()\n  return 1\nend"
    local ast = reverse_parser.build_ast(code)
    
    local metrics = reverse_parser.calculate_metrics(ast)
    lu.assertNotNil(metrics, "Should calculate metrics")
    lu.assertTrue(metrics.total_lines > 0, "Should count lines")
end

-- ============================================================================
-- TEST SUITE: SYNTAX VALIDATOR
-- ============================================================================

TestSyntaxValidator = {}

function TestSyntaxValidator:testValidateSyntax()
    local code = "local x = 1"
    local ast = reverse_parser.build_ast(code)
    
    local valid, issues = syntax_validator.validate_syntax(ast)
    lu.assertTrue(valid, "Should validate valid syntax")
    lu.assertEquals(#issues, 0, "Should have no issues")
end

function TestSyntaxValidator:testDetectInvalidIdentifier()
    lu.assertFalse(syntax_validator.is_valid_identifier("123abc"), 
        "Should reject identifier starting with number")
    lu.assertFalse(syntax_validator.is_valid_identifier("if"), 
        "Should reject keyword as identifier")
    lu.assertTrue(syntax_validator.is_valid_identifier("valid_name"), 
        "Should accept valid identifier")
end

function TestSyntaxValidator:testValidateExpression()
    local valid1, err1 = syntax_validator.validate_expression("1 + 2")
    lu.assertTrue(valid1, "Should validate valid expression")
    
    local valid2, err2 = syntax_validator.validate_expression("function(")
    lu.assertFalse(valid2, "Should reject invalid expression")
end

function TestSyntaxValidator:testValidateFactorioAPI()
    local code = "local x = game.print('test')"
    local ast = reverse_parser.build_ast(code)
    
    local valid, issues = syntax_validator.validate_factorio_api(ast)
    lu.assertNotNil(issues, "Should return issues list")
end

function TestSyntaxValidator:testValidateComplexity()
    local code = "if true then\n  if true then\n    if true then\n      return 1\n    end\n  end\nend"
    local ast = reverse_parser.build_ast(code)
    
    local valid, warnings = syntax_validator.validate_complexity(ast)
    lu.assertNotNil(warnings, "Should return complexity warnings")
end

function TestSyntaxValidator:testValidateAll()
    local code = "local x = 1"
    local ast = reverse_parser.build_ast(code)
    
    local report = syntax_validator.validate_all(ast, {})
    lu.assertNotNil(report, "Should generate validation report")
    lu.assertNotNil(report.syntax_valid, "Should have syntax_valid field")
end

-- ============================================================================
-- TEST SUITE: FALSE POSITIVE GENERATOR
-- ============================================================================

TestFalsePositiveGenerator = {}

function TestFalsePositiveGenerator:testGenerateAPITests()
    local api_element = {
        name = "game.print",
        namespace = "game",
        member = "print",
        type = "method"
    }
    
    local tests = false_positive_generator.generate_api_tests(api_element)
    lu.assertNotNil(tests, "Should generate tests")
    lu.assertTrue(#tests > 0, "Should have at least one test")
end

function TestFalsePositiveGenerator:testGeneratePositiveTests()
    local api_element = {
        name = "game.tick",
        namespace = "game",
        member = "tick",
        type = "property"
    }
    
    local tests = false_positive_generator.generate_positive_tests(api_element)
    lu.assertNotNil(tests, "Should generate positive tests")
end

function TestFalsePositiveGenerator:testCreateFalsePositives()
    local api_element = {
        name = "game.print",
        namespace = "game",
        member = "print",
        type = "method"
    }
    
    local tests = false_positive_generator.create_false_positives(api_element)
    lu.assertNotNil(tests, "Should create false positive tests")
end

function TestFalsePositiveGenerator:testGenerateTestSuite()
    local api_elements = {
        {name = "game.print", namespace = "game", member = "print", type = "method"},
        {name = "game.tick", namespace = "game", member = "tick", type = "property"}
    }
    
    local suite = false_positive_generator.generate_test_suite(api_elements)
    lu.assertNotNil(suite, "Should generate test suite")
    lu.assertNotNil(suite.tests, "Should have tests")
    lu.assertTrue(#suite.tests > 0, "Should have generated tests")
end

function TestFalsePositiveGenerator:testValidateCoverage()
    local test_suite = {
        {type = "positive"},
        {type = "negative"},
        {type = "edge"}
    }
    
    local coverage = false_positive_generator.validate_coverage(test_suite)
    lu.assertNotNil(coverage, "Should calculate coverage")
    lu.assertEquals(coverage.total_tests, 3, "Should count all tests")
end

-- ============================================================================
-- TEST SUITE: API REFERENCE CHECKER
-- ============================================================================

TestAPIReferenceChecker = {}

function TestAPIReferenceChecker:testCheckValidReference()
    local api_call = {
        namespace = "game",
        member = "print",
        type = "method"
    }
    
    local valid, issue = api_reference_checker.check_reference(api_call)
    lu.assertTrue(valid, "Should validate known API call")
end

function TestAPIReferenceChecker:testCheckInvalidReference()
    local api_call = {
        namespace = "invalid_namespace",
        member = "invalid_method",
        type = "method"
    }
    
    local valid, issue = api_reference_checker.check_reference(api_call)
    lu.assertFalse(valid, "Should reject unknown API call")
    lu.assertNotNil(issue, "Should provide issue description")
end

function TestAPIReferenceChecker:testIsDeprecated()
    local api_call = {
        namespace = "global",
        full_name = "global"
    }
    
    local deprecated, info = api_reference_checker.is_deprecated(api_call)
    lu.assertTrue(deprecated, "Should detect deprecated API")
    lu.assertNotNil(info, "Should provide deprecation info")
end

function TestAPIReferenceChecker:testGetAllAPIElements()
    local elements = api_reference_checker.get_all_api_elements()
    lu.assertNotNil(elements, "Should return API elements")
    lu.assertTrue(#elements > 0, "Should have API elements")
end

function TestAPIReferenceChecker:testCalculateCoverage()
    local used_apis = {
        {namespace = "game", member = "print", full_name = "game.print"}
    }
    
    local coverage = api_reference_checker.calculate_coverage(used_apis)
    lu.assertNotNil(coverage, "Should calculate coverage")
    lu.assertNotNil(coverage.coverage_percentage, "Should have percentage")
end

function TestAPIReferenceChecker:testValidateAll()
    local api_calls = {
        {namespace = "game", member = "print", type = "method"},
        {namespace = "invalid", member = "method", type = "method"}
    }
    
    local results = api_reference_checker.validate_all(api_calls)
    lu.assertNotNil(results, "Should return results")
    lu.assertTrue(#results.valid > 0, "Should have valid calls")
    lu.assertTrue(#results.invalid > 0, "Should have invalid calls")
end

-- ============================================================================
-- TEST SUITE: MOD ARCHIVE VALIDATOR
-- ============================================================================

TestModArchiveValidator = {}

function TestModArchiveValidator:testValidateStructure()
    -- Create temporary mod directory
    local temp_dir = "/tmp/test_mod_" .. os.time()
    os.execute("mkdir -p " .. temp_dir)
    
    -- Create info.json
    local file = io.open(temp_dir .. "/info.json", "w")
    file:write('{"name":"test","version":"1.0.0"}')
    file:close()
    
    local valid, issues = mod_archive_validator.validate_structure(temp_dir)
    lu.assertTrue(valid, "Should validate structure with required files")
    
    os.execute("rm -rf " .. temp_dir)
end

function TestModArchiveValidator:testParseInfoJSON()
    local temp_file = "/tmp/test_info.json"
    local file = io.open(temp_file, "w")
    file:write('{"name":"test","version":"1.0.0","title":"Test","author":"Test","factorio_version":"2.0"}')
    file:close()
    
    local info_data, err = mod_archive_validator.parse_info_json(temp_file)
    lu.assertNotNil(info_data, "Should parse valid info.json")
    lu.assertEquals(info_data.name, "test", "Should extract name")
    
    os.remove(temp_file)
end

-- ============================================================================
-- RUN TESTS
-- ============================================================================

os.exit(lu.LuaUnit.run())
