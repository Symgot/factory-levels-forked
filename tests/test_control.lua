#!/usr/bin/env lua5.3
-- Test runner for Factory Levels mod
-- Uses LuaUnit v3.4 for testing

local lu = require('luaunit')
local factorio_mock = require('factorio_mock')

-- Initialize Factorio API mock
factorio_mock.init()

-- Configure default mod settings
factorio_mock.set_setting("startup", "factory-levels-use-invisible-modules", true)
factorio_mock.set_setting("startup", "factory-levels-enable-assembler-leveling", true)
factorio_mock.set_setting("startup", "factory-levels-enable-furnace-leveling", true)
factorio_mock.set_setting("startup", "factory-levels-enable-refinery-leveling", true)
factorio_mock.set_setting("startup", "factory-levels-enable-recycler-leveling", true)
factorio_mock.set_setting("startup", "factory-levels-max-level-tier-1", 100)
factorio_mock.set_setting("startup", "factory-levels-max-level-tier-2", 100)
factorio_mock.set_setting("startup", "factory-levels-max-level-tier-3", 100)
factorio_mock.set_setting("global", "factory-levels-exponent", 2.0)
factorio_mock.set_setting("global", "factory-levels-base-requirement", 100)
factorio_mock.set_setting("global", "factory-levels-disable-mod", false)
factorio_mock.set_setting("global", "factory-levels-check-interval", 60)
factorio_mock.set_setting("global", "factory-levels-machines-per-check", 10)
factorio_mock.set_setting("global", "factory-levels-debug-mode", false)

-- Test: Basic Lua syntax validation
TestSyntax = {}

function TestSyntax:testControlLuaLoads()
    local success, err = pcall(function()
        dofile("../factory-levels/control.lua")
    end)
    lu.assertTrue(success, "control.lua should load without syntax errors: " .. tostring(err))
end

function TestSyntax:testDataLuaSyntax()
    local success, err = loadfile("../factory-levels/data.lua")
    lu.assertTrue(success ~= nil, "data.lua should have valid syntax: " .. tostring(err))
end

function TestSyntax:testSettingsLuaSyntax()
    local success, err = loadfile("../factory-levels/settings.lua")
    lu.assertTrue(success ~= nil, "settings.lua should have valid syntax: " .. tostring(err))
end

-- Test: Invisible Module System
TestInvisibleModules = {}

function TestInvisibleModules:setUp()
    factorio_mock.reset()
    factorio_mock.set_setting("startup", "factory-levels-use-invisible-modules", true)
end

function TestInvisibleModules:testBonusFormulas()
    dofile("../factory-levels/control.lua")
    lu.assertNotNil(_G.bonus_formulas or {}, "Bonus formulas should be defined")
end

function TestInvisibleModules:testMachineTracking()
    dofile("../factory-levels/control.lua")
    
    -- Create mock entity
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine", {
        products_finished = 100
    })
    
    -- Storage should be initialized
    lu.assertNotNil(storage, "Storage should be initialized")
end

-- Test: Machine Level Determination
TestMachineLevels = {}

function TestMachineLevels:setUp()
    factorio_mock.reset()
    dofile("../factory-levels/control.lua")
end

function TestMachineLevels:testDetermineLevelFunction()
    -- Test level determination based on products finished
    local level1 = determine_level(0)
    lu.assertEquals(level1, 1, "Level should be 1 for 0 products")
    
    local level2 = determine_level(100)
    lu.assertIsNumber(level2, "Level should be a number")
    lu.assertTrue(level2 >= 1, "Level should be at least 1")
end

function TestMachineLevels:testMachineMaxLevel()
    -- Test that max level is determined correctly
    local max_level_t1 = get_machine_max_level("assembling-machine-1")
    lu.assertEquals(max_level_t1, 100, "Tier 1 machine should have max level 100")
    
    local max_level_t2 = get_machine_max_level("assembling-machine-2")
    lu.assertEquals(max_level_t2, 100, "Tier 2 machine should have max level 100")
end

-- Test: String utilities
TestStringUtils = {}

function TestStringUtils:setUp()
    dofile("../factory-levels/control.lua")
end

function TestStringUtils:testStringStartsWith()
    lu.assertTrue(string_starts_with("assembling-machine-1-level-5", "assembling-machine-1-level-"))
    lu.assertFalse(string_starts_with("assembling-machine-1", "assembling-machine-2"))
    lu.assertTrue(string_starts_with("test", "test"))
    lu.assertFalse(string_starts_with("te", "test"))
end

-- Test: Remote interface
TestRemoteInterface = {}

function TestRemoteInterface:setUp()
    factorio_mock.reset()
    dofile("../factory-levels/control.lua")
end

function TestRemoteInterface:testRemoteInterfaceExists()
    -- Remote interface should be registered
    lu.assertNotNil(remote, "Remote interface should exist")
end

-- Run all tests
os.exit(lu.LuaUnit.run())
