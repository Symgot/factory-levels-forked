#!/usr/bin/env lua5.3
-- Test suite for Runtime Classes validation
-- Tests critical runtime API classes and their interactions

local lu = require('luaunit')
local factorio_mock = require('factorio_mock')
local prototype_mock = require('factorio_prototype_mock')

factorio_mock.init()
prototype_mock.init()

-- Test: Entity Properties Extended Coverage
TestEntityPropertiesExtended = {}

function TestEntityPropertiesExtended:setUp()
    factorio_mock.reset()
end

function TestEntityPropertiesExtended:testMiningProperties()
    local entity = factorio_mock.create_entity("electric-mining-drill", "mining-drill")
    
    lu.assertNotNil(entity.mining_progress)
    lu.assertEquals(entity.mining_progress, 0)
    
    -- Mining target can be set
    entity.mining_target = {x = 10, y = 10}
    lu.assertNotNil(entity.mining_target)
end

function TestEntityPropertiesExtended:testCircuitProperties()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    lu.assertNotNil(entity.circuit_connected_entities)
    lu.assertNotNil(entity.wire_connectors)
    lu.assertNotNil(entity.get_circuit_network)
    
    -- Can call circuit network methods
    local network = entity.get_circuit_network(1, 1)
    lu.assertNotNil(network)
end

function TestEntityPropertiesExtended:testTransportProperties()
    local entity = factorio_mock.create_entity("transport-belt", "transport-belt")
    
    lu.assertNotNil(entity.transport_lines)
    lu.assertTrue(entity.loader_filter == false or entity.loader_filter == nil)
    lu.assertTrue(entity.splitter_filter == false or entity.splitter_filter == nil)
    
    -- Can set filters
    entity.splitter_filter = "iron-ore"
    lu.assertEquals(entity.splitter_filter, "iron-ore")
end

function TestEntityPropertiesExtended:testVisualProperties()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    -- Visual properties exist
    lu.assertTrue(entity.backer_name == false or entity.backer_name == nil)
    lu.assertTrue(entity.color == false or entity.color == nil)
    
    -- Can set visual properties
    entity.backer_name = "My Machine"
    entity.color = {r = 1, g = 0, b = 0, a = 1}
    
    lu.assertEquals(entity.backer_name, "My Machine")
    lu.assertNotNil(entity.color)
end

function TestEntityPropertiesExtended:testStateProperties()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    lu.assertNotNil(entity.active)
    lu.assertNotNil(entity.minable)
    lu.assertNotNil(entity.selected)
    lu.assertNotNil(entity.destructible)
    lu.assertNotNil(entity.operable)
    lu.assertNotNil(entity.rotatable)
    
    -- Default states
    lu.assertEquals(entity.active, true)
    lu.assertEquals(entity.minable, true)
    lu.assertEquals(entity.destructible, true)
end

function TestEntityPropertiesExtended:testResourceProperties()
    local entity = factorio_mock.create_entity("iron-ore", "resource")
    
    -- Resource amount can be set
    entity.resource_amount = 1000
    lu.assertEquals(entity.resource_amount, 1000)
end

-- Test: Extended Events Coverage
TestExtendedEvents = {}

function TestExtendedEvents:testGUIEvents()
    local defines = factorio_mock.defines
    
    lu.assertNotNil(defines.events.on_gui_location_changed)
    lu.assertNotNil(defines.events.on_gui_switch_state_changed)
    
    -- Events have unique IDs
    lu.assertEquals(defines.events.on_gui_location_changed, 68)
    lu.assertEquals(defines.events.on_gui_switch_state_changed, 69)
end

function TestExtendedEvents:testPlayerInventoryEvents()
    local defines = factorio_mock.defines
    
    lu.assertNotNil(defines.events.on_player_cursor_stack_changed)
    lu.assertNotNil(defines.events.on_player_main_inventory_changed)
    
    -- Events have unique IDs
    lu.assertEquals(defines.events.on_player_cursor_stack_changed, 58)
    lu.assertEquals(defines.events.on_player_main_inventory_changed, 59)
end

function TestExtendedEvents:testTechnologyEvents()
    local defines = factorio_mock.defines
    
    lu.assertNotNil(defines.events.on_technology_effects_reset)
    lu.assertEquals(defines.events.on_technology_effects_reset, 44)
end

-- Test: Circuit Network Methods
TestCircuitNetwork = {}

function TestCircuitNetwork:setUp()
    factorio_mock.reset()
end

function TestCircuitNetwork:testGetCircuitNetwork()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    local network = entity.get_circuit_network(1, 1)
    lu.assertNotNil(network)
    lu.assertNotNil(network.network_id)
    lu.assertNotNil(network.signals)
    lu.assertNotNil(network.get_signal)
end

function TestCircuitNetwork:testConnectDisconnect()
    local entity1 = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    local entity2 = factorio_mock.create_entity("assembling-machine-2", "assembling-machine")
    
    lu.assertNotNil(entity1.connect_neighbour)
    lu.assertNotNil(entity1.disconnect_neighbour)
    
    -- Can call methods
    local result = entity1.connect_neighbour({target_entity = entity2, wire = 1})
    lu.assertEquals(result, true)
    
    result = entity1.disconnect_neighbour({target_entity = entity2, wire = 1})
    lu.assertEquals(result, true)
end

-- Test: Inventory Methods Extended
TestInventoryExtended = {}

function TestInventoryExtended:setUp()
    factorio_mock.reset()
end

function TestInventoryExtended:testBurntResultInventory()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    lu.assertNotNil(entity.get_burnt_result_inventory)
    
    local inv = entity.get_burnt_result_inventory()
    lu.assertNotNil(inv)
    lu.assertNotNil(inv.get_contents)
end

function TestInventoryExtended:testAllInventoryTypes()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    local inventories = {
        entity.get_inventory(1),
        entity.get_output_inventory(),
        entity.get_module_inventory(),
        entity.get_fuel_inventory(),
        entity.get_burnt_result_inventory()
    }
    
    for _, inv in ipairs(inventories) do
        lu.assertNotNil(inv)
        lu.assertNotNil(inv.get_contents)
        lu.assertNotNil(inv.insert)
        lu.assertNotNil(inv.remove)
        lu.assertNotNil(inv.clear)
    end
end

-- Test: Beacon Support
TestBeaconSupport = {}

function TestBeaconSupport:setUp()
    factorio_mock.reset()
end

function TestBeaconSupport:testGetBeacons()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    lu.assertNotNil(entity.get_beacons)
    
    local beacons = entity.get_beacons()
    lu.assertNotNil(beacons)
    lu.assertEquals(type(beacons), "table")
end

-- Run all tests
os.exit(lu.LuaUnit.run())
