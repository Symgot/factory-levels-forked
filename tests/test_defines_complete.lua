#!/usr/bin/env lua5.3
-- Test suite for Phase 4: Complete Defines Categories (56 categories)
-- Reference: https://lua-api.factorio.com/latest/defines.html

local lu = require('luaunit')
local factorio_mock = require('factorio_mock')

TestDefinesComplete = {}

-- Test defines structure exists
function TestDefinesComplete:testDefinesExists()
    lu.assertNotNil(factorio_mock.defines)
end

-- Test original defines categories
function TestDefinesComplete:testOriginalDefines()
    lu.assertNotNil(factorio_mock.defines.events)
    lu.assertNotNil(factorio_mock.defines.direction)
    lu.assertNotNil(factorio_mock.defines.inventory)
    lu.assertNotNil(factorio_mock.defines.flow_precision_index)
end

-- Test alert_type
function TestDefinesComplete:testAlertType()
    local alert_type = factorio_mock.defines.alert_type
    lu.assertNotNil(alert_type)
    lu.assertNotNil(alert_type.collector_path_blocked)
    lu.assertNotNil(alert_type.custom)
    lu.assertNotNil(alert_type.entity_destroyed)
    lu.assertNotNil(alert_type.entity_under_attack)
    lu.assertNotNil(alert_type.no_material_for_construction)
    lu.assertNotNil(alert_type.no_platform_storage)
    lu.assertNotNil(alert_type.train_no_path)
    lu.assertNotNil(alert_type.turret_fire)
end

-- Test behavior_result
function TestDefinesComplete:testBehaviorResult()
    local result = factorio_mock.defines.behavior_result
    lu.assertNotNil(result)
    lu.assertNotNil(result.deleted)
    lu.assertNotNil(result.fail)
    lu.assertNotNil(result.in_progress)
    lu.assertNotNil(result.success)
end

-- Test build_check_type
function TestDefinesComplete:testBuildCheckType()
    local build_check = factorio_mock.defines.build_check_type
    lu.assertNotNil(build_check)
    lu.assertNotNil(build_check.blueprint_ghost)
    lu.assertNotNil(build_check.ghost_revive)
    lu.assertNotNil(build_check.manual)
    lu.assertNotNil(build_check.script)
end

-- Test build_mode
function TestDefinesComplete:testBuildMode()
    local build_mode = factorio_mock.defines.build_mode
    lu.assertNotNil(build_mode)
    lu.assertNotNil(build_mode.forced)
    lu.assertNotNil(build_mode.normal)
    lu.assertNotNil(build_mode.superforced)
end

-- Test cargo_destination
function TestDefinesComplete:testCargoDestination()
    local cargo_dest = factorio_mock.defines.cargo_destination
    lu.assertNotNil(cargo_dest)
    lu.assertNotNil(cargo_dest.invalid)
    lu.assertNotNil(cargo_dest.orbit)
    lu.assertNotNil(cargo_dest.space_platform)
    lu.assertNotNil(cargo_dest.station)
    lu.assertNotNil(cargo_dest.surface)
end

-- Test chain_signal_state
function TestDefinesComplete:testChainSignalState()
    local chain_signal = factorio_mock.defines.chain_signal_state
    lu.assertNotNil(chain_signal)
    lu.assertNotNil(chain_signal.all_open)
    lu.assertNotNil(chain_signal.none)
    lu.assertNotNil(chain_signal.none_open)
    lu.assertNotNil(chain_signal.partially_open)
end

-- Test chunk_generated_status
function TestDefinesComplete:testChunkGeneratedStatus()
    local chunk_status = factorio_mock.defines.chunk_generated_status
    lu.assertNotNil(chunk_status)
    lu.assertNotNil(chunk_status.basic_tiles)
    lu.assertNotNil(chunk_status.entities)
    lu.assertNotNil(chunk_status.nothing)
end

-- Test command
function TestDefinesComplete:testCommand()
    local command = factorio_mock.defines.command
    lu.assertNotNil(command)
    lu.assertNotNil(command.attack)
    lu.assertNotNil(command.go_to_location)
    lu.assertNotNil(command.stop)
    lu.assertNotNil(command.wander)
end

-- Test compound_command
function TestDefinesComplete:testCompoundCommand()
    local compound = factorio_mock.defines.compound_command
    lu.assertNotNil(compound)
    lu.assertNotNil(compound.logical_and)
    lu.assertNotNil(compound.logical_or)
    lu.assertNotNil(compound.return_last)
end

-- Test controllers
function TestDefinesComplete:testControllers()
    local controllers = factorio_mock.defines.controllers
    lu.assertNotNil(controllers)
    lu.assertNotNil(controllers.character)
    lu.assertNotNil(controllers.editor)
    lu.assertNotNil(controllers.god)
    lu.assertNotNil(controllers.spectator)
end

-- Test difficulty
function TestDefinesComplete:testDifficulty()
    local difficulty = factorio_mock.defines.difficulty
    lu.assertNotNil(difficulty)
    lu.assertNotNil(difficulty.easy)
    lu.assertNotNil(difficulty.normal)
    lu.assertNotNil(difficulty.hard)
end

-- Test disconnect_reason
function TestDefinesComplete:testDisconnectReason()
    local disconnect = factorio_mock.defines.disconnect_reason
    lu.assertNotNil(disconnect)
    lu.assertNotNil(disconnect.banned)
    lu.assertNotNil(disconnect.kicked)
    lu.assertNotNil(disconnect.quit)
end

-- Test distraction
function TestDefinesComplete:testDistraction()
    local distraction = factorio_mock.defines.distraction
    lu.assertNotNil(distraction)
    lu.assertNotNil(distraction.by_anything)
    lu.assertNotNil(distraction.by_damage)
    lu.assertNotNil(distraction.none)
end

-- Test entity_status
function TestDefinesComplete:testEntityStatus()
    local status = factorio_mock.defines.entity_status
    lu.assertNotNil(status)
    lu.assertNotNil(status.working)
    lu.assertNotNil(status.no_power)
    lu.assertNotNil(status.no_fuel)
    lu.assertNotNil(status.disabled)
    lu.assertNotNil(status.frozen)
    lu.assertNotNil(status.normal)
end

-- Test entity_status_diode
function TestDefinesComplete:testEntityStatusDiode()
    local diode = factorio_mock.defines.entity_status_diode
    lu.assertNotNil(diode)
    lu.assertNotNil(diode.green)
    lu.assertNotNil(diode.red)
    lu.assertNotNil(diode.yellow)
end

-- Test game_controller_interaction
function TestDefinesComplete:testGameControllerInteraction()
    local interaction = factorio_mock.defines.game_controller_interaction
    lu.assertNotNil(interaction)
    lu.assertNotNil(interaction.always)
    lu.assertNotNil(interaction.never)
    lu.assertNotNil(interaction.normal)
end

-- Test group_state
function TestDefinesComplete:testGroupState()
    local group_state = factorio_mock.defines.group_state
    lu.assertNotNil(group_state)
    lu.assertNotNil(group_state.attacking_target)
    lu.assertNotNil(group_state.finished)
    lu.assertNotNil(group_state.gathering)
end

-- Test gui_type
function TestDefinesComplete:testGuiType()
    local gui_type = factorio_mock.defines.gui_type
    lu.assertNotNil(gui_type)
    lu.assertNotNil(gui_type.entity)
    lu.assertNotNil(gui_type.custom)
    lu.assertNotNil(gui_type.logistic)
    lu.assertNotNil(gui_type.production)
end

-- Test input_method
function TestDefinesComplete:testInputMethod()
    local input_method = factorio_mock.defines.input_method
    lu.assertNotNil(input_method)
    lu.assertNotNil(input_method.game_controller)
    lu.assertNotNil(input_method.keyboard_and_mouse)
end

-- Test logistic_member_index
function TestDefinesComplete:testLogisticMemberIndex()
    local logistic_member = factorio_mock.defines.logistic_member_index
    lu.assertNotNil(logistic_member)
    lu.assertNotNil(logistic_member.character_provider)
    lu.assertNotNil(logistic_member.logistic_container)
    lu.assertNotNil(logistic_member.roboport_provider)
end

-- Test logistic_mode
function TestDefinesComplete:testLogisticMode()
    local logistic_mode = factorio_mock.defines.logistic_mode
    lu.assertNotNil(logistic_mode)
    lu.assertNotNil(logistic_mode.active_provider)
    lu.assertNotNil(logistic_mode.passive_provider)
    lu.assertNotNil(logistic_mode.requester)
    lu.assertNotNil(logistic_mode.storage)
end

-- Test logistic_section_type
function TestDefinesComplete:testLogisticSectionType()
    local section_type = factorio_mock.defines.logistic_section_type
    lu.assertNotNil(section_type)
    lu.assertNotNil(section_type.circuit_controlled)
    lu.assertNotNil(section_type.manual)
end

-- Test mouse_button_type
function TestDefinesComplete:testMouseButtonType()
    local mouse_button = factorio_mock.defines.mouse_button_type
    lu.assertNotNil(mouse_button)
    lu.assertNotNil(mouse_button.left)
    lu.assertNotNil(mouse_button.right)
    lu.assertNotNil(mouse_button.middle)
end

-- Test moving_state
function TestDefinesComplete:testMovingState()
    local moving_state = factorio_mock.defines.moving_state
    lu.assertNotNil(moving_state)
    lu.assertNotNil(moving_state.moving)
    lu.assertNotNil(moving_state.stuck)
end

-- Test print_skip
function TestDefinesComplete:testPrintSkip()
    local print_skip = factorio_mock.defines.print_skip
    lu.assertNotNil(print_skip)
    lu.assertNotNil(print_skip.if_redundant)
    lu.assertNotNil(print_skip.never)
end

-- Test print_sound
function TestDefinesComplete:testPrintSound()
    local print_sound = factorio_mock.defines.print_sound
    lu.assertNotNil(print_sound)
    lu.assertNotNil(print_sound.always)
    lu.assertNotNil(print_sound.never)
end

-- Test rail_connection_direction
function TestDefinesComplete:testRailConnectionDirection()
    local rail_dir = factorio_mock.defines.rail_connection_direction
    lu.assertNotNil(rail_dir)
    lu.assertNotNil(rail_dir.left)
    lu.assertNotNil(rail_dir.right)
    lu.assertNotNil(rail_dir.straight)
end

-- Test rail_direction
function TestDefinesComplete:testRailDirection()
    local rail_dir = factorio_mock.defines.rail_direction
    lu.assertNotNil(rail_dir)
    lu.assertNotNil(rail_dir.front)
    lu.assertNotNil(rail_dir.back)
end

-- Test rail_layer
function TestDefinesComplete:testRailLayer()
    local rail_layer = factorio_mock.defines.rail_layer
    lu.assertNotNil(rail_layer)
    lu.assertNotNil(rail_layer.elevated)
    lu.assertNotNil(rail_layer.ground)
end

-- Test relative_gui_position
function TestDefinesComplete:testRelativeGuiPosition()
    local gui_pos = factorio_mock.defines.relative_gui_position
    lu.assertNotNil(gui_pos)
    lu.assertNotNil(gui_pos.top)
    lu.assertNotNil(gui_pos.bottom)
    lu.assertNotNil(gui_pos.left)
    lu.assertNotNil(gui_pos.right)
end

-- Test render_mode
function TestDefinesComplete:testRenderMode()
    local render_mode = factorio_mock.defines.render_mode
    lu.assertNotNil(render_mode)
    lu.assertNotNil(render_mode.chart)
    lu.assertNotNil(render_mode.game)
end

-- Test rich_text_setting
function TestDefinesComplete:testRichTextSetting()
    local rich_text = factorio_mock.defines.rich_text_setting
    lu.assertNotNil(rich_text)
    lu.assertNotNil(rich_text.enabled)
    lu.assertNotNil(rich_text.disabled)
end

-- Test robot_order_type
function TestDefinesComplete:testRobotOrderType()
    local robot_order = factorio_mock.defines.robot_order_type
    lu.assertNotNil(robot_order)
    lu.assertNotNil(robot_order.construct)
    lu.assertNotNil(robot_order.deconstruct)
    lu.assertNotNil(robot_order.repair)
end

-- Test rocket_silo_status
function TestDefinesComplete:testRocketSiloStatus()
    local silo_status = factorio_mock.defines.rocket_silo_status
    lu.assertNotNil(silo_status)
    lu.assertNotNil(silo_status.building_rocket)
    lu.assertNotNil(silo_status.launch_starting)
    lu.assertNotNil(silo_status.rocket_ready)
end

-- Test selection_mode
function TestDefinesComplete:testSelectionMode()
    local selection = factorio_mock.defines.selection_mode
    lu.assertNotNil(selection)
    lu.assertNotNil(selection.select)
    lu.assertNotNil(selection.alt_select)
end

-- Test shooting
function TestDefinesComplete:testShooting()
    local shooting = factorio_mock.defines.shooting
    lu.assertNotNil(shooting)
    lu.assertNotNil(shooting.not_shooting)
    lu.assertNotNil(shooting.shooting_enemies)
end

-- Test signal_state
function TestDefinesComplete:testSignalState()
    local signal_state = factorio_mock.defines.signal_state
    lu.assertNotNil(signal_state)
    lu.assertNotNil(signal_state.open)
    lu.assertNotNil(signal_state.closed)
end

-- Test space_platform_state
function TestDefinesComplete:testSpacePlatformState()
    local platform_state = factorio_mock.defines.space_platform_state
    lu.assertNotNil(platform_state)
    lu.assertNotNil(platform_state.no_path)
    lu.assertNotNil(platform_state.waiting_at_station)
    lu.assertNotNil(platform_state.on_the_path)
end

-- Test train_state
function TestDefinesComplete:testTrainState()
    local train_state = factorio_mock.defines.train_state
    lu.assertNotNil(train_state)
    lu.assertNotNil(train_state.on_the_path)
    lu.assertNotNil(train_state.wait_station)
    lu.assertNotNil(train_state.manual_control)
end

-- Test transport_line
function TestDefinesComplete:testTransportLine()
    local transport = factorio_mock.defines.transport_line
    lu.assertNotNil(transport)
    lu.assertNotNil(transport.left_line)
    lu.assertNotNil(transport.right_line)
end

-- Test wire_connector_id
function TestDefinesComplete:testWireConnectorId()
    local wire_id = factorio_mock.defines.wire_connector_id
    lu.assertNotNil(wire_id)
    lu.assertNotNil(wire_id.circuit_red)
    lu.assertNotNil(wire_id.circuit_green)
end

-- Test wire_origin
function TestDefinesComplete:testWireOrigin()
    local wire_origin = factorio_mock.defines.wire_origin
    lu.assertNotNil(wire_origin)
    lu.assertNotNil(wire_origin.player)
    lu.assertNotNil(wire_origin.script)
end

-- Test wire_type
function TestDefinesComplete:testWireType()
    local wire_type = factorio_mock.defines.wire_type
    lu.assertNotNil(wire_type)
    lu.assertNotNil(wire_type.red)
    lu.assertNotNil(wire_type.green)
    lu.assertNotNil(wire_type.copper)
end

-- Test extended inventory types
function TestDefinesComplete:testExtendedInventory()
    local inventory = factorio_mock.defines.inventory
    lu.assertNotNil(inventory)
    
    -- Extended inventory types
    lu.assertNotNil(inventory.agricultural_tower_input)
    lu.assertNotNil(inventory.asteroid_collector_output)
    lu.assertNotNil(inventory.cargo_landing_pad_main)
    lu.assertNotNil(inventory.character_ammo)
    lu.assertNotNil(inventory.hub_main)
    lu.assertNotNil(inventory.rocket_silo_rocket)
    lu.assertNotNil(inventory.spider_trunk)
end

-- Test extended flow_precision_index
function TestDefinesComplete:testExtendedFlowPrecisionIndex()
    local flow = factorio_mock.defines.flow_precision_index
    lu.assertNotNil(flow)
    
    -- Extended values
    lu.assertNotNil(flow.one_thousand_hours)
    lu.assertNotNil(flow.two_hundred_fifty_hours)
end

-- Test all defines categories present
function TestDefinesComplete:testAllDefinesCategoriesPresent()
    local required_categories = {
        "events",
        "direction",
        "inventory",
        "flow_precision_index",
        "alert_type",
        "behavior_result",
        "build_check_type",
        "build_mode",
        "cargo_destination",
        "chain_signal_state",
        "chunk_generated_status",
        "command",
        "compound_command",
        "controllers",
        "difficulty",
        "disconnect_reason",
        "distraction",
        "entity_status",
        "entity_status_diode",
        "game_controller_interaction",
        "group_state",
        "gui_type",
        "input_method",
        "logistic_member_index",
        "logistic_mode",
        "logistic_section_type",
        "mouse_button_type",
        "moving_state",
        "print_skip",
        "print_sound",
        "rail_connection_direction",
        "rail_direction",
        "rail_layer",
        "relative_gui_position",
        "render_mode",
        "rich_text_setting",
        "robot_order_type",
        "rocket_silo_status",
        "selection_mode",
        "shooting",
        "signal_state",
        "space_platform_state",
        "train_state",
        "transport_line",
        "wire_connector_id",
        "wire_origin",
        "wire_type"
    }
    
    for _, category in ipairs(required_categories) do
        lu.assertNotNil(factorio_mock.defines[category], 
            "Missing defines category: " .. category)
    end
end

-- Test defines category count
function TestDefinesComplete:testDefinesCategoryCount()
    local count = 0
    for category_name, _ in pairs(factorio_mock.defines) do
        if type(factorio_mock.defines[category_name]) == "table" then
            count = count + 1
        end
    end
    
    -- Should have at least 45 categories
    lu.assertTrue(count >= 45, string.format("Should have at least 45 defines categories, found %d", count))
end

os.exit(lu.LuaUnit.run())
