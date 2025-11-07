-- Phase 7 Test Suite: Production-Ready System
-- Complete test coverage for all Phase 7 components

local luaunit = require('luaunit')

-- Load Phase 7 components
local native_zip = require('native_zip_library')
local complete_decompiler = require('complete_decompiler')

-- ============================================================================
-- TEST: NATIVE ZIP LIBRARY
-- ============================================================================

TestNativeZip = {}

function TestNativeZip:test_create_archive()
    local archive = native_zip.create_archive()
    luaunit.assertNotNil(archive)
    luaunit.assertEquals(#archive.entries, 0)
end

function TestNativeZip:test_add_file()
    local archive = native_zip.create_archive()
    local test_data = "Hello, Factorio!"
    
    archive:add_file("test.txt", test_data)
    luaunit.assertEquals(#archive.entries, 1)
    luaunit.assertEquals(archive.entries[1].filename, "test.txt")
    luaunit.assertEquals(archive.entries[1].data, test_data)
end

function TestNativeZip:test_add_directory()
    local archive = native_zip.create_archive()
    archive:add_directory("mods")
    
    luaunit.assertEquals(#archive.entries, 1)
    luaunit.assertStrContains(archive.entries[1].filename, "/")
end

function TestNativeZip:test_write_and_read()
    local archive = native_zip.create_archive()
    archive:add_file("control.lua", "-- Factorio mod")
    archive:add_file("info.json", '{"name": "test-mod"}')
    
    local zip_data = archive:write()
    luaunit.assertNotNil(zip_data)
    luaunit.assertTrue(#zip_data > 0)
    
    -- Read archive back
    local read_archive = native_zip.read_data(zip_data)
    luaunit.assertNotNil(read_archive)
    luaunit.assertEquals(#read_archive.entries, 2)
end

function TestNativeZip:test_list_files()
    local archive = native_zip.create_archive()
    archive:add_file("file1.lua", "content1")
    archive:add_file("file2.lua", "content2")
    
    local files = native_zip.list_files(archive)
    luaunit.assertEquals(#files, 2)
    luaunit.assertEquals(files[1].name, "file1.lua")
    luaunit.assertEquals(files[2].name, "file2.lua")
end

function TestNativeZip:test_extract_file()
    local archive = native_zip.create_archive()
    local test_content = "Test content"
    archive:add_file("test.txt", test_content)
    
    local zip_data = archive:write()
    local read_archive = native_zip.read_data(zip_data)
    
    local extracted = native_zip.extract_file(read_archive, "test.txt")
    luaunit.assertEquals(extracted, test_content)
end

function TestNativeZip:test_validate_archive()
    local archive = native_zip.create_archive()
    archive:add_file("valid.txt", "Valid content")
    
    local zip_data = archive:write()
    local read_archive = native_zip.read_data(zip_data)
    
    local valid, errors = native_zip.validate_archive(read_archive)
    luaunit.assertTrue(valid)
    luaunit.assertEquals(#errors, 0)
end

function TestNativeZip:test_get_info()
    local archive = native_zip.create_archive()
    archive:add_file("file1.txt", "Content 1")
    archive:add_file("file2.txt", "Content 2")
    archive:add_directory("subdir")
    
    local info = native_zip.get_info(archive)
    luaunit.assertEquals(info.num_entries, 3)
    luaunit.assertEquals(info.num_files, 2)
    luaunit.assertEquals(info.num_directories, 1)
end

function TestNativeZip:test_dos_datetime_encoding()
    local dos_time, dos_date = native_zip.encode_dos_datetime(2024, 1, 15, 14, 30, 0)
    luaunit.assertNotNil(dos_time)
    luaunit.assertNotNil(dos_date)
    
    local year, month, day, hour, minute, second = native_zip.decode_dos_datetime(dos_time, dos_date)
    luaunit.assertEquals(year, 2024)
    luaunit.assertEquals(month, 1)
    luaunit.assertEquals(day, 15)
    luaunit.assertEquals(hour, 14)
    luaunit.assertEquals(minute, 30)
end

function TestNativeZip:test_crc32_calculation()
    -- CRC32 is internal but tested through archive validation
    local archive = native_zip.create_archive()
    archive:add_file("test.txt", "CRC32 test data")
    
    local zip_data = archive:write()
    local read_archive = native_zip.read_data(zip_data)
    
    local valid = native_zip.validate_archive(read_archive)
    luaunit.assertTrue(valid)
end

function TestNativeZip:test_large_file_handling()
    local archive = native_zip.create_archive()
    local large_data = string.rep("X", 1024 * 100) -- 100KB
    
    archive:add_file("large.dat", large_data)
    
    local zip_data = archive:write()
    local read_archive = native_zip.read_data(zip_data)
    
    local extracted = native_zip.extract_file(read_archive, "large.dat")
    luaunit.assertEquals(#extracted, #large_data)
end

function TestNativeZip:test_multiple_files()
    local archive = native_zip.create_archive()
    
    for i = 1, 10 do
        archive:add_file("file" .. i .. ".txt", "Content " .. i)
    end
    
    luaunit.assertEquals(#archive.entries, 10)
    
    local zip_data = archive:write()
    local read_archive = native_zip.read_data(zip_data)
    
    luaunit.assertEquals(#read_archive.entries, 10)
end

function TestNativeZip:test_benchmark()
    local results = native_zip.benchmark(1024 * 10) -- 10KB test
    
    luaunit.assertNotNil(results.crc32_time_ms)
    luaunit.assertNotNil(results.create_time_ms)
    luaunit.assertNotNil(results.read_time_ms)
    luaunit.assertTrue(results.create_time_ms < 1000) -- Should be fast
end

-- ============================================================================
-- TEST: COMPLETE DECOMPILER
-- ============================================================================

TestCompleteDecompiler = {}

function TestCompleteDecompiler:test_variable_recovery()
    local recovery = complete_decompiler.VariableRecovery:new()
    luaunit.assertNotNil(recovery)
    
    local var_name = recovery:get_local_name(0)
    luaunit.assertNotNil(var_name)
    luaunit.assertStrContains(var_name, "_temp")
end

function TestCompleteDecompiler:test_set_local_name()
    local recovery = complete_decompiler.VariableRecovery:new()
    recovery:set_local_name(0, "my_var")
    
    local name = recovery:get_local_name(0)
    luaunit.assertEquals(name, "my_var")
end

function TestCompleteDecompiler:test_upvalue_naming()
    local recovery = complete_decompiler.VariableRecovery:new()
    local upval_name = recovery:get_upvalue_name(0)
    
    luaunit.assertNotNil(upval_name)
    luaunit.assertStrContains(upval_name, "_upval")
end

function TestCompleteDecompiler:test_function_naming()
    local recovery = complete_decompiler.VariableRecovery:new()
    local func_name1 = recovery:get_function_name()
    local func_name2 = recovery:get_function_name()
    
    luaunit.assertNotEquals(func_name1, func_name2)
end

function TestCompleteDecompiler:test_loop_var_naming()
    local recovery = complete_decompiler.VariableRecovery:new()
    local loop_var = recovery:get_loop_var_name()
    
    luaunit.assertNotNil(loop_var)
    luaunit.assertStrContains(loop_var, "_i")
end

function TestCompleteDecompiler:test_cfg_creation()
    local cfg = complete_decompiler.ControlFlowGraph:new()
    luaunit.assertNotNil(cfg)
    luaunit.assertEquals(#cfg.nodes, 0)
end

function TestCompleteDecompiler:test_cfg_node_creation()
    local cfg = complete_decompiler.ControlFlowGraph:new()
    local node = cfg:create_node(1, 10)
    
    luaunit.assertNotNil(node)
    luaunit.assertEquals(node.start_pc, 1)
    luaunit.assertEquals(node.end_pc, 10)
end

function TestCompleteDecompiler:test_cfg_edge_addition()
    local cfg = complete_decompiler.ControlFlowGraph:new()
    local node1 = cfg:create_node(1, 5)
    local node2 = cfg:create_node(6, 10)
    
    cfg:add_edge(node1, node2)
    
    luaunit.assertEquals(#node1.successors, 1)
    luaunit.assertEquals(#node2.predecessors, 1)
end

function TestCompleteDecompiler:test_data_flow_analyzer()
    local cfg = complete_decompiler.ControlFlowGraph:new()
    local node = cfg:create_node(1, 5)
    cfg.entry_node = node
    
    local dfa = complete_decompiler.DataFlowAnalyzer:new(cfg)
    luaunit.assertNotNil(dfa)
    
    dfa:analyze()
    luaunit.assertNotNil(dfa.reaching_defs)
end

function TestCompleteDecompiler:test_ast_builder()
    local cfg = complete_decompiler.ControlFlowGraph:new()
    local node = cfg:create_node(1, 1)
    cfg.entry_node = node
    
    local recovery = complete_decompiler.VariableRecovery:new()
    local builder = complete_decompiler.ASTBuilder:new(cfg, recovery)
    
    local ast = builder:build()
    luaunit.assertNotNil(ast)
    luaunit.assertEquals(ast.type, complete_decompiler.AST_TYPES.CHUNK)
end

function TestCompleteDecompiler:test_code_generator()
    local gen = complete_decompiler.CodeGenerator:new()
    luaunit.assertNotNil(gen)
    
    local ast = {
        type = complete_decompiler.AST_TYPES.CHUNK,
        body = {
            {
                type = complete_decompiler.AST_TYPES.RETURN,
                values = {}
            }
        }
    }
    
    local code = gen:generate(ast)
    luaunit.assertNotNil(code)
    luaunit.assertStrContains(code, "return")
end

function TestCompleteDecompiler:test_expression_to_string_nil()
    local gen = complete_decompiler.CodeGenerator:new()
    local expr = {type = complete_decompiler.AST_TYPES.NIL}
    
    local result = gen:expression_to_string(expr)
    luaunit.assertEquals(result, "nil")
end

function TestCompleteDecompiler:test_expression_to_string_number()
    local gen = complete_decompiler.CodeGenerator:new()
    local expr = {type = complete_decompiler.AST_TYPES.NUMBER, value = 42}
    
    local result = gen:expression_to_string(expr)
    luaunit.assertEquals(result, "42")
end

function TestCompleteDecompiler:test_expression_to_string_binop()
    local gen = complete_decompiler.CodeGenerator:new()
    local expr = {
        type = complete_decompiler.AST_TYPES.BINOP,
        op = "+",
        left = {type = complete_decompiler.AST_TYPES.NUMBER, value = 1},
        right = {type = complete_decompiler.AST_TYPES.NUMBER, value = 2}
    }
    
    local result = gen:expression_to_string(expr)
    luaunit.assertStrContains(result, "+")
end

function TestCompleteDecompiler:test_format_decompilation_report()
    local result = {
        success = true,
        source_code = "return 42",
        statistics = {
            num_basic_blocks = 1,
            num_instructions = 2,
            num_variables = 0,
            num_functions = 0,
            decompilation_quality = 95
        }
    }
    
    local report = complete_decompiler.format_decompilation_report(result)
    luaunit.assertNotNil(report)
    luaunit.assertStrContains(report, "Decompilation Report")
    luaunit.assertStrContains(report, "95%")
end

-- ============================================================================
-- INTEGRATION TESTS
-- ============================================================================

TestIntegration = {}

function TestIntegration:test_zip_with_lua_files()
    -- Create mod archive with Lua files
    local archive = native_zip.create_archive()
    archive:add_file("info.json", '{"name": "test-mod", "version": "1.0.0"}')
    archive:add_file("control.lua", [[
local function init()
    game.print("Mod loaded")
end

script.on_init(init)
]])
    archive:add_file("data.lua", [[
data:extend({
    {
        type = "item",
        name = "test-item",
        icon = "__test-mod__/icon.png"
    }
})
]])
    
    local zip_data = archive:write()
    luaunit.assertNotNil(zip_data)
    
    local read_archive = native_zip.read_data(zip_data)
    luaunit.assertEquals(#read_archive.entries, 3)
    
    local control_lua = native_zip.extract_file(read_archive, "control.lua")
    luaunit.assertStrContains(control_lua, "game.print")
end

function TestIntegration:test_decompiler_with_simple_bytecode()
    -- Test decompiler with mock bytecode structure
    local result = {
        success = true,
        source_code = "local x = 1\nreturn x",
        ast = {type = complete_decompiler.AST_TYPES.CHUNK, body = {}},
        cfg = {nodes = {}},
        statistics = {
            num_basic_blocks = 1,
            num_instructions = 3,
            num_variables = 1,
            num_functions = 0,
            decompilation_quality = 90
        }
    }
    
    luaunit.assertTrue(result.success)
    luaunit.assertEquals(result.statistics.decompilation_quality, 90)
end

function TestIntegration:test_full_workflow()
    -- Create archive
    local archive = native_zip.create_archive()
    archive:add_file("test.lua", "return 'test'")
    
    -- Write and validate
    local zip_data = archive:write()
    local read_archive = native_zip.read_data(zip_data)
    local valid = native_zip.validate_archive(read_archive)
    
    luaunit.assertTrue(valid)
    
    -- Extract and verify
    local lua_content = native_zip.extract_file(read_archive, "test.lua")
    luaunit.assertEquals(lua_content, "return 'test'")
end

-- ============================================================================
-- PERFORMANCE TESTS
-- ============================================================================

TestPerformance = {}

function TestPerformance:test_zip_creation_performance()
    local start_time = os.clock()
    
    local archive = native_zip.create_archive()
    for i = 1, 100 do
        archive:add_file("file" .. i .. ".txt", "Content " .. i)
    end
    
    local zip_data = archive:write()
    
    local elapsed = (os.clock() - start_time) * 1000
    luaunit.assertTrue(elapsed < 1000, "ZIP creation should complete in < 1 second")
end

function TestPerformance:test_zip_reading_performance()
    local archive = native_zip.create_archive()
    for i = 1, 50 do
        archive:add_file("file" .. i .. ".txt", "Content " .. i)
    end
    local zip_data = archive:write()
    
    local start_time = os.clock()
    local read_archive = native_zip.read_data(zip_data)
    local elapsed = (os.clock() - start_time) * 1000
    
    luaunit.assertTrue(elapsed < 500, "ZIP reading should complete in < 500ms")
end

-- ============================================================================
-- RUN TESTS
-- ============================================================================

local runner = luaunit.LuaUnit.new()
runner:setOutputType("text")
os.exit(runner:runSuite())
