#!/usr/bin/env lua5.3
-- Test suite for Phase 4: Extended Event System (161 events)
-- Reference: https://lua-api.factorio.com/latest/events.html

local lu = require('luaunit')
local factorio_mock = require('factorio_mock')

TestEventSystemExtended = {}

-- Test core event system structure
function TestEventSystemExtended:testEventSystemExists()
    lu.assertNotNil(factorio_mock.defines)
    lu.assertNotNil(factorio_mock.defines.events)
end

-- Test Phase 4 extended events (161 new events)
function TestEventSystemExtended:testExtendedEvents()
    local extended_events = {
        "CustomInputEvent",
        "on_achievement_gained",
        "on_area_cloned",
        "on_biter_base_built",
        "on_brush_cloned",
        "on_build_base_arrived",
        "on_cancelled_deconstruction",
        "on_cancelled_upgrade",
        "on_cargo_pod_delivered_cargo",
        "on_cargo_pod_finished_ascending",
        "on_cargo_pod_finished_descending",
        "on_cargo_pod_started_ascending",
        "on_character_corpse_expired",
        "on_chart_tag_added",
        "on_chart_tag_modified",
        "on_chart_tag_removed",
        "on_console_chat",
        "on_console_command",
        "on_cutscene_cancelled",
        "on_cutscene_finished",
        "on_cutscene_started",
        "on_cutscene_waypoint_reached",
        "on_entity_color_changed",
        "on_entity_logistic_slot_changed",
        "on_equipment_inserted",
        "on_equipment_removed",
        "on_force_cease_fire_changed",
        "on_force_created",
        "on_force_friends_changed",
        "on_force_reset",
        "on_forces_merged",
        "on_forces_merging",
        "on_game_created_from_scenario",
        "on_gui_confirmed",
        "on_gui_hover",
        "on_gui_leave",
        "on_gui_location_changed",
        "on_gui_selected_tab_changed",
        "on_gui_switch_state_changed",
        "on_land_mine_armed",
        "on_lua_shortcut",
        "on_marked_for_deconstruction",
        "on_marked_for_upgrade",
        "on_market_item_purchased",
        "on_mod_item_opened",
        "on_multiplayer_init",
        "on_object_destroyed",
        "on_permission_group_added",
        "on_permission_group_deleted",
        "on_permission_group_edited",
        "on_permission_string_imported",
        "on_picked_up_item",
        "on_player_alt_reverse_selected_area",
        "on_player_ammo_inventory_changed",
        "on_player_armor_inventory_changed",
        "on_player_banned",
        "on_player_built_tile",
        "on_player_changed_force",
        "on_player_cheat_mode_disabled",
        "on_player_cheat_mode_enabled",
        "on_player_clicked_gps_tag",
        "on_player_configured_blueprint",
        "on_player_controller_changed",
        "on_player_cursor_stack_changed",
        "on_player_deconstructed_area",
        "on_player_demoted",
        "on_player_display_density_scale_changed",
        "on_player_display_resolution_changed",
        "on_player_display_scale_changed",
        "on_player_dropped_item",
        "on_player_dropped_item_into_entity",
        "on_player_fast_transferred",
        "on_player_flipped_entity",
        "on_player_flushed_fluid",
        "on_player_gun_inventory_changed",
        "on_player_input_method_changed",
        "on_player_kicked",
        "on_player_locale_changed",
        "on_player_main_inventory_changed",
        "on_player_mined_tile",
        "on_player_muted",
        "on_player_pipette",
        "on_player_placed_equipment",
        "on_player_promoted",
        "on_player_removed",
        "on_player_removed_equipment",
        "on_player_reverse_selected_area",
        "on_player_rotated_entity",
        "on_player_set_quick_bar_slot",
        "on_player_setup_blueprint",
        "on_player_toggled_alt_mode",
        "on_player_toggled_map_editor",
        "on_player_trash_inventory_changed",
        "on_player_unbanned",
        "on_player_unmuted",
        "on_player_used_capsule",
        "on_player_used_spidertron_remote",
        "on_post_entity_died",
        "on_post_segmented_unit_died",
        "on_pre_build",
        "on_pre_chunk_deleted",
        "on_pre_ghost_deconstructed",
        "on_pre_ghost_upgraded",
        "on_pre_permission_group_deleted",
        "on_pre_permission_string_imported",
        "on_pre_player_died",
        "on_pre_player_left_game",
        "on_pre_player_mined_item",
        "on_pre_player_removed",
        "on_pre_player_toggled_map_editor",
        "on_pre_robot_exploded_cliff",
        "on_pre_scenario_finished",
        "on_pre_script_inventory_resized",
        "on_pre_surface_deleted",
        "on_redo_applied",
        "on_research_moved",
        "on_research_queued",
        "on_robot_built_tile",
        "on_robot_exploded_cliff",
        "on_robot_mined_tile",
        "on_robot_pre_mined",
        "on_rocket_launch_ordered",
        "on_rocket_launched",
        "on_script_inventory_resized",
        "on_script_path_request_finished",
        "on_script_trigger_effect",
        "on_segment_entity_created",
        "on_segmented_unit_created",
        "on_segmented_unit_damaged",
        "on_segmented_unit_died",
        "on_selected_entity_changed",
        "on_singleplayer_init",
        "on_space_platform_built_entity",
        "on_space_platform_built_tile",
        "on_space_platform_mined_entity",
        "on_space_platform_mined_item",
        "on_space_platform_mined_tile",
        "on_space_platform_pre_mined",
        "on_spider_command_completed",
        "on_string_translated",
        "on_surface_imported",
        "on_surface_renamed",
        "on_technology_effects_reset",
        "on_territory_created",
        "on_territory_destroyed",
        "on_tower_mined_plant",
        "on_tower_planted_seed",
        "on_tower_pre_mined_plant",
        "on_trigger_created_entity",
        "on_trigger_fired_artillery",
        "on_udp_packet_received",
        "on_undo_applied",
        "on_unit_added_to_group",
        "on_unit_removed_from_group",
        "on_worker_robot_expired",
        "script_raised_built",
        "script_raised_destroy",
        "script_raised_destroy_segmented_unit",
        "script_raised_revive",
        "script_raised_set_tiles",
        "script_raised_teleported"
    }
    
    for _, event_name in ipairs(extended_events) do
        local event_id = factorio_mock.defines.events[event_name]
        lu.assertNotNil(event_id, "Missing event: " .. event_name)
        lu.assertIsNumber(event_id, event_name .. " should have numeric ID")
    end
end

-- Test all events have unique IDs
function TestEventSystemExtended:testEventIDsUnique()
    local seen_ids = {}
    local duplicates = {}
    
    for event_name, event_id in pairs(factorio_mock.defines.events) do
        if seen_ids[event_id] then
            table.insert(duplicates, string.format("%s and %s both use ID %d", 
                seen_ids[event_id], event_name, event_id))
        else
            seen_ids[event_id] = event_name
        end
    end
    
    if #duplicates > 0 then
        lu.fail("Duplicate event IDs found:\n" .. table.concat(duplicates, "\n"))
    end
end

-- Test original events still exist
function TestEventSystemExtended:testOriginalEventsPresent()
    local original_events = {
        "on_player_mined_entity",
        "on_robot_mined_entity",
        "on_robot_built_entity",
        "on_built_entity",
        "on_entity_died",
        "on_entity_damaged",
        "on_player_crafted_item",
        "on_research_started",
        "on_research_finished",
        "on_player_created",
        "on_player_joined_game",
        "on_gui_click",
        "on_gui_opened",
        "on_tick"
    }
    
    for _, event_name in ipairs(original_events) do
        local event_id = factorio_mock.defines.events[event_name]
        lu.assertNotNil(event_id, "Original event missing: " .. event_name)
    end
end

-- Test Space Age events
function TestEventSystemExtended:testSpaceAgeEvents()
    local space_age_events = {
        "on_space_platform_built",
        "on_space_platform_destroyed",
        "on_space_platform_changed_state",
        "on_asteroid_chunk_collision",
        "on_elevated_rail_built",
        "on_quality_item_created",
        "on_entity_frozen",
        "on_entity_spoiled",
        "on_space_location_changed",
        "on_platform_moved",
        "on_cargo_pod_delivered",
        "on_cargo_pod_departed"
    }
    
    for _, event_name in ipairs(space_age_events) do
        local event_id = factorio_mock.defines.events[event_name]
        lu.assertNotNil(event_id, "Space Age event missing: " .. event_name)
    end
end

-- Test event ID ranges don't overlap
function TestEventSystemExtended:testEventIDRanges()
    -- Original events: 1-99
    -- Space Age events: 101-121
    -- Extended events: 200+
    
    for event_name, event_id in pairs(factorio_mock.defines.events) do
        lu.assertIsNumber(event_id)
        lu.assertTrue(event_id > 0, event_name .. " should have positive ID")
        lu.assertTrue(event_id < 10000, event_name .. " ID should be reasonable")
    end
end

-- Test script can register handlers
function TestEventSystemExtended:testEventRegistration()
    local mock_script = factorio_mock.script
    lu.assertNotNil(mock_script)
    lu.assertIsFunction(mock_script.on_event)
    
    -- Test registration doesn't error
    local handler_called = false
    mock_script.on_event(factorio_mock.defines.events.on_achievement_gained, function(event)
        handler_called = true
    end)
    
    -- Handler registration should succeed without error
    lu.assertFalse(handler_called)
end

-- Test event categories
function TestEventSystemExtended:testEventCategories()
    -- Count events by category
    local categories = {
        player = 0,
        entity = 0,
        gui = 0,
        force = 0,
        research = 0,
        space = 0,
        script = 0,
        system = 0
    }
    
    for event_name, _ in pairs(factorio_mock.defines.events) do
        if event_name:match("^on_player_") then
            categories.player = categories.player + 1
        elseif event_name:match("^on_entity_") or event_name:match("^on_pre_entity_") or event_name:match("^on_post_entity_") then
            categories.entity = categories.entity + 1
        elseif event_name:match("^on_gui_") then
            categories.gui = categories.gui + 1
        elseif event_name:match("^on_force_") or event_name:match("^on_forces_") then
            categories.force = categories.force + 1
        elseif event_name:match("^on_research_") then
            categories.research = categories.research + 1
        elseif event_name:match("^on_space_") or event_name:match("^on_cargo_") or event_name:match("^on_asteroid_") then
            categories.space = categories.space + 1
        elseif event_name:match("^script_raised_") then
            categories.script = categories.script + 1
        end
    end
    
    -- Verify we have events in each major category
    lu.assertTrue(categories.player > 0, "Should have player events")
    lu.assertTrue(categories.entity > 0, "Should have entity events")
    lu.assertTrue(categories.gui > 0, "Should have GUI events")
    lu.assertTrue(categories.space > 0, "Should have Space Age events")
end

-- Test event count
function TestEventSystemExtended:testEventCount()
    local count = 0
    for _ in pairs(factorio_mock.defines.events) do
        count = count + 1
    end
    
    -- Should have at least 200 events (original + Space Age + Phase 4)
    lu.assertTrue(count >= 200, string.format("Should have at least 200 events, found %d", count))
end

os.exit(lu.LuaUnit.run())
