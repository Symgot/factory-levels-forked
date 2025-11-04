#!/usr/bin/env lua5.3
-- Comprehensive syntax validation for all Lua files in the mod

local lu = require('luaunit')

-- Test suite for all Lua files
TestAllLuaFiles = {}

-- Define all Lua files to check
local lua_files = {
    "../factory-levels/control.lua",
    "../factory-levels/data.lua",
    "../factory-levels/data-final-fixes.lua",
    "../factory-levels/settings.lua",
    "../factory-levels/prototypes/entity/entity.lua",
    "../factory-levels/prototypes/entity/factory_levels.lua",
    "../factory-levels/prototypes/item/item.lua",
    "../factory-levels/prototypes/item/invisible-modules.lua"
}

-- Test each file for syntax validity
for _, filepath in ipairs(lua_files) do
    local test_name = filepath:gsub("[^%w]+", "_")
    TestAllLuaFiles["testSyntax_" .. test_name] = function()
        local chunk, err = loadfile(filepath)
        lu.assertNotNil(chunk, "Syntax error in " .. filepath .. ": " .. tostring(err))
    end
end

-- Run all tests
os.exit(lu.LuaUnit.run())
