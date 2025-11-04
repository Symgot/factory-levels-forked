#!/usr/bin/env lua5.3
-- API Validation Suite - Automated completeness checking against official Factorio API
-- Reference: https://lua-api.factorio.com/latest/

local factorio_mock = require('factorio_mock')
local prototype_mock = require('factorio_prototype_mock')

local validation = {}

-- Official Factorio API structure definitions for validation
validation.official_api = {
    runtime_classes = {
        -- Core classes
        "LuaGameScript", "LuaPlayer", "LuaForce", "LuaSurface", "LuaEntity",
        -- GUI classes
        "LuaGui", "LuaGuiElement", "LuaStyle", "LuaFont",
        -- Logistic classes
        "LuaLogisticNetwork", "LuaLogisticPoint", "LuaLogisticCell", "LuaLogisticSection",
        -- Transport classes
        "LuaTrain", "LuaRailPath", "LuaTransportLine", "LuaTrainSchedule",
        -- Circuit classes
        "LuaCircuitNetwork", "LuaWireConnector", "LuaControlBehavior",
        -- Equipment classes
        "LuaEquipment", "LuaEquipmentGrid", "LuaEquipmentCategory", "LuaEquipmentPrototype",
        -- Inventory classes
        "LuaInventory", "LuaItemStack", "LuaItemPrototype",
        -- Recipe classes
        "LuaRecipe", "LuaRecipePrototype", "LuaTechnology", "LuaTechnologyPrototype",
        -- Space Age classes
        "LuaSpacePlatform", "LuaPlanet", "LuaSpaceConnection", "LuaSpaceLocation",
        "LuaAsteroidChunk", "LuaCargoPod", "LuaQuality",
        -- Additional runtime classes
        "LuaFluidBox", "LuaFlowStatistics", "LuaGroup", "LuaPermissionGroup",
        "LuaCustomTable", "LuaLazyLoadedValue", "LuaProfiler"
    },
    
    entity_properties = {
        -- Basic properties
        "name", "type", "valid", "unit_number", "position", "direction", "force",
        "surface", "health", "prototype", "backer_name", "color",
        -- Mining properties
        "mining_progress", "mining_target", "resource_amount", "products_finished",
        -- Circuit properties
        "circuit_connected_entities", "wire_connectors", "get_circuit_network",
        "connect_neighbour", "disconnect_neighbour",
        -- Inventory properties
        "get_inventory", "get_output_inventory", "get_module_inventory", 
        "get_fuel_inventory", "get_burnt_result_inventory",
        -- Transport properties
        "transport_lines", "loader_filter", "splitter_filter", "splitter_input_priority",
        "splitter_output_priority", "belt_to_ground_type",
        -- Recipe properties
        "get_recipe", "set_recipe", "previous_recipe", "recipe_locked",
        -- Effects properties
        "effects", "get_beacons", "get_module_effects",
        -- Quality properties
        "quality", "quality_prototype", "get_quality_multiplier", "recipe_quality",
        -- Space Age properties
        "space_location", "platform_id", "cargo_pod_entity", "spoil_percent", "frozen",
        -- Additional entity properties
        "active", "destructible", "minable", "rotatable", "operable", "selected",
        "energy", "temperature", "fluidbox", "request_slot_count", "filter_slot_count"
    },
    
    events = {
        -- Entity lifecycle
        "on_player_mined_entity", "on_robot_mined_entity", "on_robot_built_entity",
        "on_built_entity", "on_entity_died", "on_entity_damaged", "on_entity_destroyed",
        "on_entity_spawned", "on_entity_cloned", "on_entity_renamed",
        "on_entity_settings_pasted", "on_pre_entity_settings_pasted",
        -- GUI events
        "on_gui_click", "on_gui_opened", "on_gui_closed", "on_gui_text_changed",
        "on_gui_elem_changed", "on_gui_selection_state_changed", 
        "on_gui_checked_state_changed", "on_gui_value_changed",
        "on_gui_location_changed", "on_gui_switch_state_changed",
        -- Player events
        "on_player_created", "on_player_joined_game", "on_player_left_game",
        "on_player_died", "on_player_respawned", "on_player_changed_position",
        "on_player_changed_surface", "on_player_driving_changed_state",
        "on_player_cursor_stack_changed", "on_player_main_inventory_changed",
        -- Research events
        "on_research_started", "on_research_finished", "on_research_reversed",
        "on_research_cancelled", "on_technology_effects_reset",
        -- Crafting events
        "on_player_crafted_item", "on_robot_crafted_item", 
        "on_pre_player_crafted_item", "on_pre_robot_crafted_item",
        "on_player_cancelled_crafting",
        -- Combat events
        "on_sector_scanned", "on_combat_robot_expired", "on_unit_group_finished_gathering",
        "on_unit_group_created", "on_ai_command_completed",
        -- Space Age events
        "on_space_platform_built", "on_space_platform_destroyed",
        "on_space_platform_changed_state", "on_asteroid_chunk_collision",
        "on_cargo_pod_delivered", "on_cargo_pod_departed",
        "on_space_location_changed", "on_platform_moved"
    },
    
    prototype_categories = {
        -- Entity prototypes
        "assembling-machine", "furnace", "mining-drill", "lab", "beacon",
        "rocket-silo", "roboport", "electric-pole", "inserter",
        "transport-belt", "underground-belt", "splitter", "loader",
        "container", "logistic-container", "storage-tank", "pump",
        "boiler", "generator", "solar-panel", "accumulator",
        "reactor", "heat-pipe", "wall", "gate", "turret",
        -- Space Age entities
        "recycler", "space-platform-hub", "asteroid-collector",
        "agricultural-tower", "fusion-reactor", "fusion-generator",
        "lightning-attractor", "heating-tower", "cargo-bay", "cargo-pod",
        -- Item prototypes
        "item", "module", "ammo", "gun", "armor", "tool", "repair-tool",
        -- Recipe and technology
        "recipe", "technology", "fluid",
        -- Equipment
        "equipment", "roboport-equipment", "energy-shield-equipment",
        "battery-equipment", "solar-panel-equipment",
        -- Other
        "tile", "virtual-signal", "quality", "planet", "space-location"
    }
}

-- Validation functions
function validation.validate_runtime_classes()
    local results = {
        missing = {},
        implemented = {},
        total = #validation.official_api.runtime_classes
    }
    
    for _, class_name in ipairs(validation.official_api.runtime_classes) do
        -- Check if class exists in mock implementation
        local exists = false
        
        -- Check global namespace and factorio_mock
        if _G[class_name] or factorio_mock[class_name] then
            exists = true
        end
        
        if exists then
            table.insert(results.implemented, class_name)
        else
            table.insert(results.missing, class_name)
        end
    end
    
    results.coverage = (#results.implemented / results.total) * 100
    return results
end

function validation.validate_entity_properties()
    local results = {
        missing = {},
        implemented = {},
        total = #validation.official_api.entity_properties
    }
    
    -- Create test entity to check properties
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    for _, property in ipairs(validation.official_api.entity_properties) do
        -- Check if property exists (as property or method)
        -- Use rawget to check if key exists in table, even if value is nil
        local exists = false
        if type(entity[property]) == "function" then
            exists = true
        else
            -- Check if the key exists in the entity table (even if nil)
            local mt = getmetatable(entity)
            local found_in_table = false
            for k, _ in pairs(entity) do
                if k == property then
                    found_in_table = true
                    break
                end
            end
            exists = found_in_table
        end
        
        if exists then
            table.insert(results.implemented, property)
        else
            table.insert(results.missing, property)
        end
    end
    
    results.coverage = (#results.implemented / results.total) * 100
    return results
end

function validation.validate_events()
    local results = {
        missing = {},
        implemented = {},
        total = #validation.official_api.events
    }
    
    for _, event_name in ipairs(validation.official_api.events) do
        -- Check if event exists in defines.events
        if factorio_mock.defines.events[event_name] ~= nil then
            table.insert(results.implemented, event_name)
        else
            table.insert(results.missing, event_name)
        end
    end
    
    results.coverage = (#results.implemented / results.total) * 100
    return results
end

function validation.validate_prototype_categories()
    local results = {
        missing = {},
        implemented = {},
        total = #validation.official_api.prototype_categories
    }
    
    for _, category in ipairs(validation.official_api.prototype_categories) do
        -- Check if prototype category exists in data.raw
        if prototype_mock.data.raw[category] ~= nil then
            table.insert(results.implemented, category)
        else
            table.insert(results.missing, category)
        end
    end
    
    results.coverage = (#results.implemented / results.total) * 100
    return results
end

function validation.generate_report()
    local report = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        runtime_classes = validation.validate_runtime_classes(),
        entity_properties = validation.validate_entity_properties(),
        events = validation.validate_events(),
        prototype_categories = validation.validate_prototype_categories()
    }
    
    -- Calculate overall coverage
    local total_items = report.runtime_classes.total + 
                       report.entity_properties.total + 
                       report.events.total + 
                       report.prototype_categories.total
    
    local total_implemented = #report.runtime_classes.implemented + 
                             #report.entity_properties.implemented + 
                             #report.events.implemented + 
                             #report.prototype_categories.implemented
    
    report.overall_coverage = (total_implemented / total_items) * 100
    
    return report
end

function validation.print_report(report)
    print("\n=== Factorio API Validation Report ===")
    print("Generated: " .. report.timestamp)
    print("\n--- Runtime Classes ---")
    print(string.format("Coverage: %.1f%% (%d/%d)", 
        report.runtime_classes.coverage,
        #report.runtime_classes.implemented,
        report.runtime_classes.total))
    
    if #report.runtime_classes.missing > 0 then
        print("Missing classes: " .. #report.runtime_classes.missing)
        for i = 1, math.min(10, #report.runtime_classes.missing) do
            print("  - " .. report.runtime_classes.missing[i])
        end
        if #report.runtime_classes.missing > 10 then
            print("  ... and " .. (#report.runtime_classes.missing - 10) .. " more")
        end
    end
    
    print("\n--- Entity Properties ---")
    print(string.format("Coverage: %.1f%% (%d/%d)", 
        report.entity_properties.coverage,
        #report.entity_properties.implemented,
        report.entity_properties.total))
    
    if #report.entity_properties.missing > 0 then
        print("Missing properties: " .. #report.entity_properties.missing)
        for i = 1, math.min(10, #report.entity_properties.missing) do
            print("  - " .. report.entity_properties.missing[i])
        end
        if #report.entity_properties.missing > 10 then
            print("  ... and " .. (#report.entity_properties.missing - 10) .. " more")
        end
    end
    
    print("\n--- Events ---")
    print(string.format("Coverage: %.1f%% (%d/%d)", 
        report.events.coverage,
        #report.events.implemented,
        report.events.total))
    
    if #report.events.missing > 0 then
        print("Missing events: " .. #report.events.missing)
        for i = 1, math.min(10, #report.events.missing) do
            print("  - " .. report.events.missing[i])
        end
        if #report.events.missing > 10 then
            print("  ... and " .. (#report.events.missing - 10) .. " more")
        end
    end
    
    print("\n--- Prototype Categories ---")
    print(string.format("Coverage: %.1f%% (%d/%d)", 
        report.prototype_categories.coverage,
        #report.prototype_categories.implemented,
        report.prototype_categories.total))
    
    if #report.prototype_categories.missing > 0 then
        print("Missing categories: " .. #report.prototype_categories.missing)
        for i = 1, math.min(10, #report.prototype_categories.missing) do
            print("  - " .. report.prototype_categories.missing[i])
        end
        if #report.prototype_categories.missing > 10 then
            print("  ... and " .. (#report.prototype_categories.missing - 10) .. " more")
        end
    end
    
    print("\n=== Overall Coverage ===")
    print(string.format("Total API Coverage: %.1f%%", report.overall_coverage))
    
    local status = report.overall_coverage >= 80 and "✅ GOOD" or 
                   report.overall_coverage >= 60 and "⚠️  NEEDS IMPROVEMENT" or 
                   "❌ CRITICAL"
    print("Status: " .. status)
    print("\n")
end

-- Main execution if run as script
if not pcall(debug.getlocal, 4, 1) then
    factorio_mock.init()
    prototype_mock.init()
    
    local report = validation.generate_report()
    validation.print_report(report)
    
    -- Exit with error if coverage is below 80%
    if report.overall_coverage < 80 then
        os.exit(1)
    end
end

return validation
