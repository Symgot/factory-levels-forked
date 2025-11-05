-- Test Suite for Phase 6 Enhancements
-- Tests for Enhanced Parser, Native Libraries, and Bytecode Analyzer

local luaunit = require('luaunit')
local enhanced_parser = require('enhanced_parser')
local native_libs = require('native_libraries')
local bytecode_analyzer = require('bytecode_analyzer')

-- ============================================================================
-- ENHANCED PARSER TESTS
-- ============================================================================

TestEnhancedParser = {}

function TestEnhancedParser:test_tokenize_basic()
    local source = "local x = 42"
    local tokens = enhanced_parser.tokenize(source)
    
    luaunit.assertNotNil(tokens)
    luaunit.assertTrue(#tokens >= 4)
    luaunit.assertEquals(tokens[1].type, "keyword")
    luaunit.assertEquals(tokens[1].value, "local")
end

function TestEnhancedParser:test_tokenize_lua54_operators()
    local source = "x = 10 // 3"  -- Integer division
    local tokens = enhanced_parser.tokenize(source)
    
    local found_int_div = false
    for _, token in ipairs(tokens) do
        if token.type == "operator" and token.value == "//" then
            found_int_div = true
            break
        end
    end
    
    luaunit.assertTrue(found_int_div, "Should tokenize // operator")
end

function TestEnhancedParser:test_tokenize_bitwise_operators()
    local source = "y = x & 0xFF | z << 2"
    local tokens = enhanced_parser.tokenize(source)
    
    local operators = {}
    for _, token in ipairs(tokens) do
        if token.type == "operator" then
            table.insert(operators, token.value)
        end
    end
    
    -- Check that we have the key bitwise operators
    local has_and = false
    local has_or = false
    local has_shift = false
    for _, op in ipairs(operators) do
        if op == "&" then has_and = true end
        if op == "|" then has_or = true end
        if op == "<<" then has_shift = true end
    end
    
    luaunit.assertTrue(has_and, "Should have & operator")
    luaunit.assertTrue(has_or, "Should have | operator")
    luaunit.assertTrue(has_shift, "Should have << operator")
end

function TestEnhancedParser:test_tokenize_long_string()
    local source = "str = [[multi\nline\nstring]]"
    local tokens = enhanced_parser.tokenize(source)
    
    local found_string = false
    for _, token in ipairs(tokens) do
        if token.type == "string" and token.long_form then
            found_string = true
            luaunit.assertNotNil(token.value:find("multi"))
            break
        end
    end
    
    luaunit.assertTrue(found_string)
end

function TestEnhancedParser:test_tokenize_hex_numbers()
    local source = "x = 0xFF"
    local tokens = enhanced_parser.tokenize(source)
    
    local found_number = false
    for _, token in ipairs(tokens) do
        if token.type == "number" then
            found_number = true
            luaunit.assertEquals(token.value, 255)
            break
        end
    end
    
    luaunit.assertTrue(found_number)
end

function TestEnhancedParser:test_tokenize_goto_label()
    local source = "::label:: goto label"
    local tokens = enhanced_parser.tokenize(source)
    
    local has_label_op = false
    for _, token in ipairs(tokens) do
        if token.type == "operator" and token.value == "::" then
            has_label_op = true
            break
        end
    end
    
    luaunit.assertTrue(has_label_op)
end

function TestEnhancedParser:test_build_ast_basic()
    local source = "local x = 1\nreturn x"
    local tokens = enhanced_parser.tokenize(source)
    local ast = enhanced_parser.build_complete_ast(tokens)
    
    luaunit.assertNotNil(ast)
    luaunit.assertEquals(ast.type, enhanced_parser.NODE_TYPES.CHUNK)
    luaunit.assertNotNil(ast.body)
    luaunit.assertTrue(#ast.body > 0)
end

function TestEnhancedParser:test_build_ast_goto()
    local source = "goto skip\nprint('test')\n::skip::"
    local tokens = enhanced_parser.tokenize(source)
    local ast = enhanced_parser.build_complete_ast(tokens)
    
    luaunit.assertNotNil(ast)
    luaunit.assertTrue(#ast.body > 0)
    
    local has_goto = false
    local has_label = false
    for _, stmt in ipairs(ast.body) do
        if stmt.type == enhanced_parser.NODE_TYPES.GOTO then
            has_goto = true
        elseif stmt.type == enhanced_parser.NODE_TYPES.LABEL then
            has_label = true
        end
    end
    
    luaunit.assertTrue(has_goto)
    luaunit.assertTrue(has_label)
end

function TestEnhancedParser:test_validate_lua54_syntax()
    local source = "::label1::\nprint('hello')\n::label1::"  -- Duplicate label
    local tokens = enhanced_parser.tokenize(source)
    local ast = enhanced_parser.build_complete_ast(tokens)
    local valid, issues = enhanced_parser.validate_lua54_syntax(ast)
    
    luaunit.assertFalse(valid)
    luaunit.assertTrue(#issues > 0)
end

function TestEnhancedParser:test_extract_halstead_metrics()
    local source = "local x = 1 + 2 * 3"
    local tokens = enhanced_parser.tokenize(source)
    local ast = enhanced_parser.build_complete_ast(tokens)
    local metrics = enhanced_parser.extract_advanced_metrics(ast)
    
    luaunit.assertNotNil(metrics.halstead)
    luaunit.assertTrue(metrics.halstead.vocabulary > 0)
    luaunit.assertTrue(metrics.halstead.volume >= 0)
end

function TestEnhancedParser:test_extract_complexity()
    local source = [[
        if x > 0 then
            return 1
        elseif x < 0 then
            return -1
        else
            return 0
        end
    ]]
    local tokens = enhanced_parser.tokenize(source)
    local ast = enhanced_parser.build_complete_ast(tokens)
    local metrics = enhanced_parser.extract_advanced_metrics(ast)
    
    luaunit.assertNotNil(metrics.cyclomatic_complexity)
    luaunit.assertTrue(metrics.cyclomatic_complexity >= 1)
end

function TestEnhancedParser:test_maintainability_index()
    local source = "local x = 1\nreturn x"
    local tokens = enhanced_parser.tokenize(source)
    local ast = enhanced_parser.build_complete_ast(tokens)
    local metrics = enhanced_parser.extract_advanced_metrics(ast)
    
    luaunit.assertNotNil(metrics.maintainability_index)
    luaunit.assertTrue(metrics.maintainability_index >= 0)
    luaunit.assertTrue(metrics.maintainability_index <= 100)
end

-- ============================================================================
-- NATIVE LIBRARIES TESTS
-- ============================================================================

TestNativeLibraries = {}

function TestNativeLibraries:test_json_parse_object()
    local json_str = '{"name": "test", "value": 42}'
    local obj = native_libs.json.parse(json_str)
    
    luaunit.assertNotNil(obj)
    luaunit.assertEquals(obj.name, "test")
    luaunit.assertEquals(obj.value, 42)
end

function TestNativeLibraries:test_json_parse_array()
    local json_str = '[1, 2, 3, 4, 5]'
    local arr = native_libs.json.parse(json_str)
    
    luaunit.assertNotNil(arr)
    luaunit.assertEquals(#arr, 5)
    luaunit.assertEquals(arr[1], 1)
    luaunit.assertEquals(arr[5], 5)
end

function TestNativeLibraries:test_json_stringify_object()
    local obj = {name = "test", value = 42, active = true}
    local json_str = native_libs.json.stringify(obj)
    
    luaunit.assertNotNil(json_str)
    luaunit.assertNotNil(json_str:find('"name"'))
    luaunit.assertNotNil(json_str:find('"test"'))
    luaunit.assertNotNil(json_str:find('42'))
end

function TestNativeLibraries:test_json_stringify_array()
    local arr = {1, 2, 3, 4, 5}
    local json_str = native_libs.json.stringify(arr)
    
    luaunit.assertNotNil(json_str)
    luaunit.assertNotNil(json_str:find('%['))
    luaunit.assertNotNil(json_str:find('%]'))
    luaunit.assertNotNil(json_str:find('1'))
end

function TestNativeLibraries:test_json_null()
    local json_str = '{"value": null}'
    local obj = native_libs.json.parse(json_str)
    
    luaunit.assertNotNil(obj)
    luaunit.assertEquals(obj.value, native_libs.json.null)
end

function TestNativeLibraries:test_fs_exists()
    -- Test with a file that should exist (this test file itself)
    local exists = native_libs.fs.exists("test_phase6.lua")
    -- May not exist if run from different location, so just test the function works
    luaunit.assertNotNil(exists)
    luaunit.assertIsBoolean(exists)
end

function TestNativeLibraries:test_fs_read_write()
    local test_file = "/tmp/test_phase6_" .. os.time() .. ".txt"
    local test_content = "Hello, Phase 6!"
    
    -- Write
    local success, err = native_libs.fs.write_file(test_file, test_content)
    luaunit.assertTrue(success, err)
    
    -- Read
    local content, err = native_libs.fs.read_file(test_file)
    luaunit.assertNotNil(content, err)
    luaunit.assertEquals(content, test_content)
    
    -- Cleanup
    native_libs.fs.remove(test_file)
end

function TestNativeLibraries:test_platform_detection()
    local os_name = native_libs.platform.get_os()
    luaunit.assertNotNil(os_name)
    luaunit.assertTrue(os_name == "linux" or os_name == "macos" or os_name == "windows" or os_name == "unknown")
end

function TestNativeLibraries:test_zip_is_available()
    local available = native_libs.zip.is_available()
    luaunit.assertIsBoolean(available)
    -- Note: unzip may not be installed in all environments
end

-- ============================================================================
-- BYTECODE ANALYZER TESTS
-- ============================================================================

TestBytecodeAnalyzer = {}

function TestBytecodeAnalyzer:test_opcodes_defined()
    luaunit.assertNotNil(bytecode_analyzer.OPCODES)
    luaunit.assertEquals(bytecode_analyzer.OPCODES[0], "MOVE")
    luaunit.assertEquals(bytecode_analyzer.OPCODES[68], "CALL")
    luaunit.assertEquals(bytecode_analyzer.OPCODES[70], "RETURN")
end

function TestBytecodeAnalyzer:test_load_invalid_file()
    local bytecode, err = bytecode_analyzer.load_luac_file("/nonexistent/file.luac")
    luaunit.assertNil(bytecode)
    luaunit.assertNotNil(err)
end

function TestBytecodeAnalyzer:test_create_test_bytecode()
    -- Create a minimal mock bytecode for testing
    local test_file = "/tmp/test_bytecode_" .. os.time() .. ".luac"
    local file = io.open(test_file, "wb")
    
    -- Write Lua signature
    file:write("\x1bLua")
    file:write(string.char(0x54))  -- Version 5.4
    file:write(string.char(0x00))  -- Format
    file:write(string.rep("\x00", 20))  -- Dummy data
    file:close()
    
    -- Test loading
    local bytecode, err = bytecode_analyzer.load_luac_file(test_file)
    luaunit.assertNotNil(bytecode, err)
    luaunit.assertEquals(bytecode.signature, "\x1bLua")
    luaunit.assertEquals(bytecode.version, 0x54)
    
    -- Cleanup
    os.remove(test_file)
end

function TestBytecodeAnalyzer:test_verify_integrity()
    local bytecode = {
        signature = "\x1bLua",
        version = 0x54,
        format = 0x00,
        raw = string.rep("\x00", 100),
        valid = true
    }
    
    local valid, verification = bytecode_analyzer.verify_integrity(bytecode)
    luaunit.assertTrue(valid)
    luaunit.assertNotNil(verification.checks)
    luaunit.assertTrue(#verification.checks > 0)
end

function TestBytecodeAnalyzer:test_analyze_bytecode()
    local bytecode = {
        signature = "\x1bLua",
        version = 0x54,
        format = 0x00,
        raw = string.rep("\x00", 100),
        data = string.rep("\x00\x00\x00\x00", 10),
        valid = true
    }
    
    local analysis = bytecode_analyzer.analyze_bytecode(bytecode)
    luaunit.assertNotNil(analysis)
    luaunit.assertTrue(analysis.valid)
    luaunit.assertNotNil(analysis.statistics)
end

function TestBytecodeAnalyzer:test_obfuscation_detection()
    local bytecode = {
        signature = "\x1bLua",
        version = 0x54,
        format = 0x00,
        raw = string.rep("\x00", 100),
        data = string.rep("\x00\x00\x00\x00", 10),
        valid = true
    }
    
    local obfuscated, detection = bytecode_analyzer.analyze_obfuscation(bytecode)
    luaunit.assertNotNil(detection)
    luaunit.assertNotNil(detection.confidence)
    luaunit.assertIsBoolean(obfuscated)
end

function TestBytecodeAnalyzer:test_decompile_bytecode()
    local bytecode = {
        signature = "\x1bLua",
        version = 0x54,
        format = 0x00,
        raw = string.rep("\x00", 100),
        data = string.rep("\x00\x00\x00\x00", 5),
        valid = true
    }
    
    local source, err = bytecode_analyzer.decompile_bytecode(bytecode)
    luaunit.assertNotNil(source, err)
    luaunit.assertNotNil(source:find("function main"))
end

function TestBytecodeAnalyzer:test_format_report()
    local report = {
        filepath = "test.luac",
        success = true,
        integrity = {
            checks = {"✓ Valid signature"},
            warnings = {},
            errors = {}
        },
        analysis = {
            version = 0x54,
            size = 100,
            statistics = {num_instructions = 10}
        },
        obfuscation = {
            likely_obfuscated = false,
            confidence = 10,
            indicators = {},
            techniques = {}
        },
        errors = {}
    }
    
    local formatted = bytecode_analyzer.format_report(report)
    luaunit.assertNotNil(formatted)
    luaunit.assertNotNil(formatted:find("test.luac"))
    luaunit.assertNotNil(formatted:find("Success"))
end

-- ============================================================================
-- INTEGRATION TESTS
-- ============================================================================

TestIntegration = {}

function TestIntegration:test_enhanced_parser_with_complex_lua()
    local source = [[
        local function test(x)
            if x > 0 then
                return x * 2
            else
                return 0
            end
        end
        
        for i = 1, 10 do
            print(test(i))
        end
    ]]
    
    local tokens = enhanced_parser.tokenize(source)
    luaunit.assertNotNil(tokens)
    luaunit.assertTrue(#tokens > 20)
    
    local ast = enhanced_parser.build_complete_ast(tokens)
    luaunit.assertNotNil(ast)
    luaunit.assertEquals(ast.type, enhanced_parser.NODE_TYPES.CHUNK)
    
    local metrics = enhanced_parser.extract_advanced_metrics(ast)
    luaunit.assertNotNil(metrics)
    luaunit.assertTrue(metrics.cyclomatic_complexity >= 2)
end

function TestIntegration:test_json_roundtrip()
    local original = {
        name = "Test Mod",
        version = "1.0.0",
        dependencies = {"base >= 2.0"},
        author = "Tester"
    }
    
    local json_str = native_libs.json.stringify(original)
    local parsed = native_libs.json.parse(json_str)
    
    luaunit.assertEquals(parsed.name, original.name)
    luaunit.assertEquals(parsed.version, original.version)
    luaunit.assertEquals(parsed.author, original.author)
end

function TestIntegration:test_enhanced_parser_factorio_patterns()
    local source = [[
        script.on_event(defines.events.on_player_created, function(event)
            game.print("Player created: " .. event.player_index)
        end)
    ]]
    
    local tokens = enhanced_parser.tokenize(source)
    luaunit.assertNotNil(tokens)
    
    local has_script = false
    local has_on_event = false
    for _, token in ipairs(tokens) do
        if token.type == "identifier" and token.value == "script" then
            has_script = true
        elseif token.type == "identifier" and token.value == "on_event" then
            has_on_event = true
        end
    end
    
    luaunit.assertTrue(has_script)
    luaunit.assertTrue(has_on_event)
end

-- Run all tests
os.exit(luaunit.LuaUnit.run())
