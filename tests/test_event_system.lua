#!/usr/bin/env lua5.3
-- Test suite for Event System validation
-- Tests all events are properly defined with correct IDs

local lu = require('luaunit')
local factorio_mock = require('factorio_mock')

factorio_mock.init()

-- Test: Event ID Consistency
TestEventIDConsistency = {}

function TestEventIDConsistency:testUniqueEventIDs()
    local defines = factorio_mock.defines
    local ids_seen = {}
    local duplicates = {}
    
    for event_name, event_id in pairs(defines.events) do
        if ids_seen[event_id] then
            table.insert(duplicates, {id = event_id, name1 = ids_seen[event_id], name2 = event_name})
        else
            ids_seen[event_id] = event_name
        end
    end
    
    lu.assertEquals(#duplicates, 0, "Found duplicate event IDs")
end

function TestEventIDConsistency:testEventIDsAreNumbers()
    local defines = factorio_mock.defines
    
    for event_name, event_id in pairs(defines.events) do
        lu.assertEquals(type(event_id), "number", event_name .. " has non-numeric ID")
    end
end

-- Test: Entity Events
TestEntityEvents = {}

function TestEntityEvents:testEntityLifecycleEvents()
    local defines = factorio_mock.defines
    
    local lifecycle_events = {
        "on_player_mined_entity",
        "on_robot_mined_entity",
        "on_robot_built_entity",
        "on_built_entity",
        "on_entity_died",
        "on_entity_damaged",
        "on_entity_destroyed",
        "on_entity_spawned",
        "on_entity_cloned",
        "on_entity_renamed"
    }
    
    for _, event_name in ipairs(lifecycle_events) do
        lu.assertNotNil(defines.events[event_name], event_name .. " is missing")
    end
end

function TestEntityEvents:testEntitySettingsEvents()
    local defines = factorio_mock.defines
    
    lu.assertNotNil(defines.events.on_entity_settings_pasted)
    lu.assertNotNil(defines.events.on_pre_entity_settings_pasted)
end

-- Test: GUI Events
TestGUIEvents = {}

function TestGUIEvents:testBasicGUIEvents()
    local defines = factorio_mock.defines
    
    local gui_events = {
        "on_gui_click",
        "on_gui_opened",
        "on_gui_closed",
        "on_gui_text_changed",
        "on_gui_elem_changed",
        "on_gui_selection_state_changed",
        "on_gui_checked_state_changed",
        "on_gui_value_changed"
    }
    
    for _, event_name in ipairs(gui_events) do
        lu.assertNotNil(defines.events[event_name], event_name .. " is missing")
    end
end

function TestGUIEvents:testExtendedGUIEvents()
    local defines = factorio_mock.defines
    
    -- Phase 3 additions
    lu.assertNotNil(defines.events.on_gui_location_changed)
    lu.assertNotNil(defines.events.on_gui_switch_state_changed)
end

-- Test: Player Events
TestPlayerEvents = {}

function TestPlayerEvents:testBasicPlayerEvents()
    local defines = factorio_mock.defines
    
    local player_events = {
        "on_player_created",
        "on_player_joined_game",
        "on_player_left_game",
        "on_player_died",
        "on_player_respawned",
        "on_player_changed_position",
        "on_player_changed_surface",
        "on_player_driving_changed_state"
    }
    
    for _, event_name in ipairs(player_events) do
        lu.assertNotNil(defines.events[event_name], event_name .. " is missing")
    end
end

function TestPlayerEvents:testExtendedPlayerEvents()
    local defines = factorio_mock.defines
    
    -- Phase 3 additions
    lu.assertNotNil(defines.events.on_player_cursor_stack_changed)
    lu.assertNotNil(defines.events.on_player_main_inventory_changed)
end

-- Test: Research Events
TestResearchEvents = {}

function TestResearchEvents:testResearchEvents()
    local defines = factorio_mock.defines
    
    local research_events = {
        "on_research_started",
        "on_research_finished",
        "on_research_reversed",
        "on_research_cancelled",
        "on_technology_effects_reset" -- Phase 3 addition
    }
    
    for _, event_name in ipairs(research_events) do
        lu.assertNotNil(defines.events[event_name], event_name .. " is missing")
    end
end

-- Test: Crafting Events
TestCraftingEvents = {}

function TestCraftingEvents:testCraftingEvents()
    local defines = factorio_mock.defines
    
    local crafting_events = {
        "on_player_crafted_item",
        "on_robot_crafted_item",
        "on_pre_player_crafted_item",
        "on_pre_robot_crafted_item",
        "on_player_cancelled_crafting"
    }
    
    for _, event_name in ipairs(crafting_events) do
        lu.assertNotNil(defines.events[event_name], event_name .. " is missing")
    end
end

-- Test: Combat Events
TestCombatEvents = {}

function TestCombatEvents:testCombatEvents()
    local defines = factorio_mock.defines
    
    local combat_events = {
        "on_sector_scanned",
        "on_combat_robot_expired",
        "on_unit_group_finished_gathering",
        "on_unit_group_created",
        "on_ai_command_completed"
    }
    
    for _, event_name in ipairs(combat_events) do
        lu.assertNotNil(defines.events[event_name], event_name .. " is missing")
    end
end

-- Test: Space Age Events
TestSpaceAgeEvents = {}

function TestSpaceAgeEvents:testSpacePlatformEvents()
    local defines = factorio_mock.defines
    
    local space_events = {
        "on_space_platform_built",
        "on_space_platform_destroyed",
        "on_space_platform_changed_state",
        "on_asteroid_chunk_collision",
        "on_space_location_changed",
        "on_platform_moved"
    }
    
    for _, event_name in ipairs(space_events) do
        lu.assertNotNil(defines.events[event_name], event_name .. " is missing")
    end
end

function TestSpaceAgeEvents:testCargoPodEvents()
    local defines = factorio_mock.defines
    
    lu.assertNotNil(defines.events.on_cargo_pod_delivered)
    lu.assertNotNil(defines.events.on_cargo_pod_departed)
    
    -- Verify specific IDs match Phase 2 implementation
    lu.assertEquals(defines.events.on_cargo_pod_delivered, 120)
    lu.assertEquals(defines.events.on_cargo_pod_departed, 121)
end

-- Test: Train Events
TestTrainEvents = {}

function TestTrainEvents:testTrainEvents()
    local defines = factorio_mock.defines
    
    local train_events = {
        "on_train_changed_state",
        "on_train_created",
        "on_train_schedule_changed"
    }
    
    for _, event_name in ipairs(train_events) do
        lu.assertNotNil(defines.events[event_name], event_name .. " is missing")
    end
end

-- Test: Misc Events
TestMiscEvents = {}

function TestMiscEvents:testResourceEvents()
    local defines = factorio_mock.defines
    
    local resource_events = {
        "on_resource_depleted",
        "on_player_mined_item",
        "on_robot_mined",
        "on_player_repaired_entity"
    }
    
    for _, event_name in ipairs(resource_events) do
        lu.assertNotNil(defines.events[event_name], event_name .. " is missing")
    end
end

function TestMiscEvents:testTickAndSurfaceEvents()
    local defines = factorio_mock.defines
    
    local misc_events = {
        "on_tick",
        "on_chunk_generated",
        "on_surface_created",
        "on_surface_deleted",
        "on_chunk_charted"
    }
    
    for _, event_name in ipairs(misc_events) do
        lu.assertNotNil(defines.events[event_name], event_name .. " is missing")
    end
end

-- Run all tests
os.exit(lu.LuaUnit.run())
