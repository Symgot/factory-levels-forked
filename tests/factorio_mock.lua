-- Factorio API Mock for testing
-- Reference: https://lua-api.factorio.com/latest/index.html

local factorio_mock = {}

-- Mock storage table (equivalent to global in Factorio runtime)
factorio_mock.storage = {}

-- Mock script object
factorio_mock.script = {
    on_init = function(callback) end,
    on_load = function(callback) end,
    on_configuration_changed = function(callback) end,
    on_event = function(event, callback, filters) end,
    on_nth_tick = function(tick, callback) end,
    raise_event = function(event, data) end
}

-- Mock defines with complete event system and Space Age features
factorio_mock.defines = {
    events = {
        -- Entity lifecycle events
        on_player_mined_entity = 1,
        on_robot_mined_entity = 2,
        on_robot_built_entity = 3,
        on_built_entity = 4,
        on_runtime_mod_setting_changed = 5,
        on_entity_died = 6,
        on_entity_damaged = 7,
        on_entity_destroyed = 8,
        on_entity_spawned = 9,
        on_entity_cloned = 10,
        on_entity_renamed = 11,
        on_entity_settings_pasted = 12,
        on_pre_entity_settings_pasted = 13,
        
        -- Space Age events
        on_space_platform_built = 101,
        on_space_platform_destroyed = 102,
        on_space_platform_changed_state = 103,
        on_asteroid_chunk_collision = 104,
        on_elevated_rail_built = 105,
        on_quality_item_created = 106,
        on_entity_frozen = 107,
        on_entity_spoiled = 108,
        on_space_location_changed = 109,
        on_platform_moved = 110,
        on_cargo_pod_delivered = 120,
        on_cargo_pod_departed = 121,
        
        -- Extended events from Phase 4
        CustomInputEvent = 200,
        on_achievement_gained = 201,
        on_area_cloned = 202,
        on_biter_base_built = 203,
        on_brush_cloned = 204,
        on_build_base_arrived = 205,
        on_cancelled_deconstruction = 206,
        on_cancelled_upgrade = 207,
        on_cargo_pod_delivered_cargo = 208,
        on_cargo_pod_finished_ascending = 209,
        on_cargo_pod_finished_descending = 210,
        on_cargo_pod_started_ascending = 211,
        on_character_corpse_expired = 212,
        on_chart_tag_added = 213,
        on_chart_tag_modified = 214,
        on_chart_tag_removed = 215,
        on_console_chat = 216,
        on_console_command = 217,
        on_cutscene_cancelled = 218,
        on_cutscene_finished = 219,
        on_cutscene_started = 220,
        on_cutscene_waypoint_reached = 221,
        on_entity_color_changed = 222,
        on_entity_logistic_slot_changed = 223,
        on_equipment_inserted = 224,
        on_equipment_removed = 225,
        on_force_cease_fire_changed = 226,
        on_force_created = 227,
        on_force_friends_changed = 228,
        on_force_reset = 229,
        on_forces_merged = 230,
        on_forces_merging = 231,
        on_game_created_from_scenario = 232,
        on_gui_confirmed = 233,
        on_gui_hover = 234,
        on_gui_leave = 235,
        on_gui_location_changed = 236,
        on_gui_selected_tab_changed = 237,
        on_gui_switch_state_changed = 238,
        on_land_mine_armed = 239,
        on_lua_shortcut = 240,
        on_marked_for_deconstruction = 241,
        on_marked_for_upgrade = 242,
        on_market_item_purchased = 243,
        on_mod_item_opened = 244,
        on_multiplayer_init = 245,
        on_object_destroyed = 246,
        on_permission_group_added = 247,
        on_permission_group_deleted = 248,
        on_permission_group_edited = 249,
        on_permission_string_imported = 250,
        on_picked_up_item = 251,
        on_player_alt_reverse_selected_area = 252,
        on_player_ammo_inventory_changed = 253,
        on_player_armor_inventory_changed = 254,
        on_player_banned = 255,
        on_player_built_tile = 256,
        on_player_changed_force = 257,
        on_player_cheat_mode_disabled = 258,
        on_player_cheat_mode_enabled = 259,
        on_player_clicked_gps_tag = 260,
        on_player_configured_blueprint = 261,
        on_player_controller_changed = 262,
        on_player_cursor_stack_changed = 263,
        on_player_deconstructed_area = 264,
        on_player_demoted = 265,
        on_player_display_density_scale_changed = 266,
        on_player_display_resolution_changed = 267,
        on_player_display_scale_changed = 268,
        on_player_dropped_item = 269,
        on_player_dropped_item_into_entity = 270,
        on_player_fast_transferred = 271,
        on_player_flipped_entity = 272,
        on_player_flushed_fluid = 273,
        on_player_gun_inventory_changed = 274,
        on_player_input_method_changed = 275,
        on_player_kicked = 276,
        on_player_locale_changed = 277,
        on_player_main_inventory_changed = 278,
        on_player_mined_tile = 279,
        on_player_muted = 280,
        on_player_pipette = 281,
        on_player_placed_equipment = 282,
        on_player_promoted = 283,
        on_player_removed = 284,
        on_player_removed_equipment = 285,
        on_player_reverse_selected_area = 286,
        on_player_rotated_entity = 287,
        on_player_set_quick_bar_slot = 288,
        on_player_setup_blueprint = 289,
        on_player_toggled_alt_mode = 290,
        on_player_toggled_map_editor = 291,
        on_player_trash_inventory_changed = 292,
        on_player_unbanned = 293,
        on_player_unmuted = 294,
        on_player_used_capsule = 295,
        on_player_used_spidertron_remote = 296,
        on_post_entity_died = 297,
        on_post_segmented_unit_died = 298,
        on_pre_build = 299,
        on_pre_chunk_deleted = 300,
        on_pre_ghost_deconstructed = 301,
        on_pre_ghost_upgraded = 302,
        on_pre_permission_group_deleted = 303,
        on_pre_permission_string_imported = 304,
        on_pre_player_died = 305,
        on_pre_player_left_game = 306,
        on_pre_player_mined_item = 307,
        on_pre_player_removed = 308,
        on_pre_player_toggled_map_editor = 309,
        on_pre_robot_exploded_cliff = 310,
        on_pre_scenario_finished = 311,
        on_pre_script_inventory_resized = 312,
        on_pre_surface_deleted = 313,
        on_redo_applied = 314,
        on_research_moved = 315,
        on_research_queued = 316,
        on_robot_built_tile = 317,
        on_robot_exploded_cliff = 318,
        on_robot_mined_tile = 319,
        on_robot_pre_mined = 320,
        on_rocket_launch_ordered = 321,
        on_rocket_launched = 322,
        on_script_inventory_resized = 323,
        on_script_path_request_finished = 324,
        on_script_trigger_effect = 325,
        on_segment_entity_created = 326,
        on_segmented_unit_created = 327,
        on_segmented_unit_damaged = 328,
        on_segmented_unit_died = 329,
        on_selected_entity_changed = 330,
        on_singleplayer_init = 331,
        on_space_platform_built_entity = 332,
        on_space_platform_built_tile = 333,
        on_space_platform_mined_entity = 334,
        on_space_platform_mined_item = 335,
        on_space_platform_mined_tile = 336,
        on_space_platform_pre_mined = 337,
        on_spider_command_completed = 338,
        on_string_translated = 339,
        on_surface_imported = 340,
        on_surface_renamed = 341,
        on_technology_effects_reset = 342,
        on_territory_created = 343,
        on_territory_destroyed = 344,
        on_tower_mined_plant = 345,
        on_tower_planted_seed = 346,
        on_tower_pre_mined_plant = 347,
        on_trigger_created_entity = 348,
        on_trigger_fired_artillery = 349,
        on_udp_packet_received = 350,
        on_undo_applied = 351,
        on_unit_added_to_group = 352,
        on_unit_removed_from_group = 353,
        on_worker_robot_expired = 354,
        script_raised_built = 355,
        script_raised_destroy = 356,
        script_raised_destroy_segmented_unit = 357,
        script_raised_revive = 358,
        script_raised_set_tiles = 359,
        script_raised_teleported = 360,
        
        -- Crafting and production events
        on_player_crafted_item = 20,
        on_robot_crafted_item = 21,
        on_pre_player_crafted_item = 22,
        on_pre_robot_crafted_item = 23,
        on_player_cancelled_crafting = 24,
        
        -- Resource events
        on_resource_depleted = 30,
        on_player_mined_item = 31,
        on_robot_mined = 32,
        on_player_repaired_entity = 33,
        
        -- Research events
        on_research_started = 40,
        on_research_finished = 41,
        on_research_reversed = 42,
        on_research_cancelled = 43,
        on_technology_effects_reset = 44,
        
        -- Player events
        on_player_created = 50,
        on_player_joined_game = 51,
        on_player_left_game = 52,
        on_player_died = 53,
        on_player_respawned = 54,
        on_player_changed_position = 55,
        on_player_changed_surface = 56,
        on_player_driving_changed_state = 57,
        on_player_cursor_stack_changed = 58,
        on_player_main_inventory_changed = 59,
        
        -- GUI events
        on_gui_click = 60,
        on_gui_opened = 61,
        on_gui_closed = 62,
        on_gui_text_changed = 63,
        on_gui_elem_changed = 64,
        on_gui_selection_state_changed = 65,
        on_gui_checked_state_changed = 66,
        on_gui_value_changed = 67,
        on_gui_location_changed = 68,
        on_gui_switch_state_changed = 69,
        
        -- Combat events
        on_sector_scanned = 70,
        on_combat_robot_expired = 71,
        on_unit_group_finished_gathering = 72,
        on_unit_group_created = 73,
        on_ai_command_completed = 74,
        
        -- Train events
        on_train_changed_state = 80,
        on_train_created = 81,
        on_train_schedule_changed = 82,
        
        -- Misc events
        on_tick = 90,
        on_player_selected_area = 91,
        on_player_alt_selected_area = 92,
        on_chunk_generated = 93,
        on_surface_created = 94,
        on_surface_deleted = 95,
        on_pre_surface_cleared = 96,
        on_surface_cleared = 97,
        on_chunk_charted = 98,
        on_chunk_deleted = 99
    },
    direction = {
        north = 0,
        northeast = 1,
        east = 2,
        southeast = 3,
        south = 4,
        southwest = 5,
        west = 6,
        northwest = 7
    },
    inventory = {
        fuel = 1,
        burnt_result = 2,
        chest = 3,
        furnace_source = 4,
        furnace_result = 5,
        furnace_modules = 6,
        assembling_machine_input = 7,
        assembling_machine_output = 8,
        assembling_machine_modules = 9,
        lab_input = 10,
        lab_modules = 11,
        -- Extended inventory types from Phase 4
        agricultural_tower_input = 12,
        agricultural_tower_output = 13,
        artillery_turret_ammo = 14,
        artillery_wagon_ammo = 15,
        assembling_machine_dump = 16,
        assembling_machine_trash = 17,
        asteroid_collector_arm = 18,
        asteroid_collector_output = 19,
        beacon_modules = 20,
        car_ammo = 21,
        car_trash = 22,
        car_trunk = 23,
        cargo_landing_pad_main = 24,
        cargo_landing_pad_trash = 25,
        cargo_unit = 26,
        cargo_wagon = 27,
        character_ammo = 28,
        character_armor = 29,
        character_corpse = 30,
        character_guns = 31,
        character_main = 32,
        character_trash = 33,
        character_vehicle = 34,
        crafter_input = 35,
        crafter_modules = 36,
        crafter_output = 37,
        crafter_trash = 38,
        editor_ammo = 39,
        editor_armor = 40,
        editor_guns = 41,
        editor_main = 42,
        furnace_trash = 43,
        god_main = 44,
        hub_main = 45,
        hub_trash = 46,
        item_main = 47,
        lab_trash = 48,
        linked_container_main = 49,
        logistic_container_trash = 50,
        mining_drill_modules = 51,
        proxy_main = 52,
        roboport_material = 53,
        roboport_robot = 54,
        robot_cargo = 55,
        robot_repair = 56,
        rocket_silo_input = 57,
        rocket_silo_modules = 58,
        rocket_silo_output = 59,
        rocket_silo_rocket = 60,
        rocket_silo_trash = 61,
        spider_ammo = 62,
        spider_trash = 63,
        spider_trunk = 64,
        turret_ammo = 65
    },
    flow_precision_index = {
        fifty_hours = 0,
        ten_hours = 1,
        two_hours = 2,
        one_hour = 3,
        ten_minutes = 4,
        one_minute = 5,
        five_seconds = 6,
        one_thousand_hours = 7,
        two_hundred_fifty_hours = 8
    },
    -- Extended defines from Phase 4
    alert_type = {
        collector_path_blocked = 1,
        custom = 2,
        entity_destroyed = 3,
        entity_under_attack = 4,
        no_material_for_construction = 5,
        no_platform_storage = 6,
        no_roboport_storage = 7,
        no_storage = 8,
        not_enough_construction_robots = 9,
        not_enough_repair_packs = 10,
        pipeline_overextended = 11,
        platform_tile_building_blocked = 12,
        train_no_path = 13,
        train_out_of_fuel = 14,
        turret_fire = 15,
        turret_out_of_ammo = 16,
        unclaimed_cargo = 17
    },
    behavior_result = {
        deleted = 1,
        fail = 2,
        in_progress = 3,
        success = 4
    },
    build_check_type = {
        blueprint_ghost = 1,
        ghost_revive = 2,
        manual = 3,
        manual_ghost = 4,
        script = 5,
        script_ghost = 6
    },
    build_mode = {
        forced = 1,
        normal = 2,
        superforced = 3
    },
    cargo_destination = {
        invalid = 1,
        orbit = 2,
        space_platform = 3,
        station = 4,
        surface = 5
    },
    chain_signal_state = {
        all_open = 1,
        none = 2,
        none_open = 3,
        partially_open = 4
    },
    chunk_generated_status = {
        basic_tiles = 1,
        corrected_tiles = 2,
        custom_tiles = 3,
        entities = 4,
        nothing = 5,
        tiles = 6
    },
    command = {
        attack = 1,
        attack_area = 2,
        build_base = 3,
        compound = 4,
        flee = 5,
        go_to_location = 6,
        group = 7,
        stop = 8,
        wander = 9
    },
    compound_command = {
        logical_and = 1,
        logical_or = 2,
        return_last = 3
    },
    controllers = {
        character = 1,
        cutscene = 2,
        editor = 3,
        ghost = 4,
        god = 5,
        remote = 6,
        spectator = 7
    },
    difficulty = {
        easy = 1,
        hard = 2,
        normal = 3
    },
    disconnect_reason = {
        afk = 1,
        banned = 2,
        cannot_keep_up = 3,
        desync_limit_reached = 4,
        dropped = 5,
        kicked = 6,
        kicked_and_deleted = 7,
        quit = 8,
        reconnect = 9,
        switching_servers = 10,
        wrong_input = 11
    },
    distraction = {
        by_anything = 1,
        by_damage = 2,
        by_enemy = 3,
        none = 4
    },
    entity_status = {
        broken = 1,
        cant_divide_segments = 2,
        charging = 3,
        closed_by_circuit_network = 4,
        computing_navigation = 5,
        destination_stop_full = 6,
        disabled = 7,
        disabled_by_control_behavior = 8,
        disabled_by_script = 9,
        discharging = 10,
        fluid_ingredient_shortage = 11,
        frozen = 12,
        full_burnt_result_output = 13,
        full_output = 14,
        fully_charged = 15,
        ghost = 16,
        item_ingredient_shortage = 17,
        launching_rocket = 18,
        low_input_fluid = 19,
        low_power = 20,
        low_temperature = 21,
        marked_for_deconstruction = 22,
        missing_required_fluid = 23,
        missing_science_packs = 24,
        networks_connected = 25,
        networks_disconnected = 26,
        no_ammo = 27,
        no_filter = 28,
        no_fuel = 29,
        no_ingredients = 30,
        no_input_fluid = 31,
        no_minable_resources = 32,
        no_modules_to_transmit = 33,
        no_path = 34,
        no_power = 35,
        no_recipe = 36,
        no_research_in_progress = 37,
        no_spot_seedable_by_inputs = 38,
        normal = 39,
        not_connected_to_hub_or_pad = 40,
        not_connected_to_rail = 41,
        not_enough_space_in_output = 42,
        not_enough_thrust = 43,
        not_plugged_in_electric_network = 44,
        on_the_way = 45,
        opened_by_circuit_network = 46,
        out_of_logistic_network = 47,
        paused = 48,
        pipeline_overextended = 49,
        preparing_rocket_for_launch = 50,
        recharging_after_power_outage = 51,
        recipe_is_parameter = 52,
        recipe_not_researched = 53,
        thrust_not_required = 54,
        turned_off_during_daytime = 55,
        waiting_at_stop = 56,
        waiting_for_more_items = 57,
        waiting_for_plants_to_grow = 58,
        waiting_for_rockets_to_arrive = 59,
        waiting_for_source_items = 60,
        waiting_for_space_in_destination = 61,
        waiting_for_space_in_platform_hub = 62,
        waiting_for_target_to_be_built = 63,
        waiting_for_train = 64,
        waiting_in_orbit = 65,
        waiting_to_launch_rocket = 66,
        working = 67
    },
    entity_status_diode = {
        green = 1,
        red = 2,
        yellow = 3
    },
    game_controller_interaction = {
        always = 1,
        never = 2,
        normal = 3
    },
    group_state = {
        attacking_distraction = 1,
        attacking_target = 2,
        finished = 3,
        gathering = 4,
        moving = 5,
        pathfinding = 6,
        wander_in_group = 7
    },
    gui_type = {
        achievement = 1,
        blueprint_library = 2,
        bonus = 3,
        controller = 4,
        custom = 5,
        entity = 6,
        equipment = 7,
        global_electric_network = 8,
        item = 9,
        logistic = 10,
        none = 11,
        opened_entity_grid = 12,
        other_player = 13,
        permissions = 14,
        player_management = 15,
        production = 16,
        script_inventory = 17,
        server_management = 18,
        tile = 19,
        trains = 20
    },
    input_method = {
        game_controller = 1,
        keyboard_and_mouse = 2
    },
    logistic_member_index = {
        car_provider = 1,
        car_requester = 2,
        character_provider = 3,
        character_requester = 4,
        character_storage = 5,
        generic_on_off_behavior = 6,
        logistic_container = 7,
        logistic_container_trash_provider = 8,
        roboport_provider = 9,
        roboport_requester = 10,
        rocket_silo_provider = 11,
        rocket_silo_requester = 12,
        rocket_silo_trash_provider = 13,
        space_platform_hub_provider = 14,
        space_platform_hub_requester = 15,
        spidertron_provider = 16,
        spidertron_requester = 17,
        vehicle_storage = 18
    },
    logistic_mode = {
        active_provider = 1,
        buffer = 2,
        none = 3,
        passive_provider = 4,
        requester = 5,
        storage = 6
    },
    logistic_section_type = {
        circuit_controlled = 1,
        manual = 2,
        request_missing_materials_controlled = 3,
        transitional_request_controlled = 4
    },
    mouse_button_type = {
        left = 1,
        middle = 2,
        none = 3,
        right = 4
    },
    moving_state = {
        adaptive = 1,
        moving = 2,
        stale = 3,
        stuck = 4
    },
    print_skip = {
        if_redundant = 1,
        if_visible = 2,
        never = 3
    },
    print_sound = {
        always = 1,
        never = 2,
        use_player_settings = 3
    },
    rail_connection_direction = {
        left = 1,
        none = 2,
        right = 3,
        straight = 4
    },
    rail_direction = {
        back = 1,
        front = 2
    },
    rail_layer = {
        elevated = 1,
        ground = 2
    },
    relative_gui_position = {
        bottom = 1,
        left = 2,
        right = 3,
        top = 4
    },
    render_mode = {
        chart = 1,
        chart_zoomed_in = 2,
        game = 3
    },
    rich_text_setting = {
        disabled = 1,
        enabled = 2,
        highlight = 3
    },
    robot_order_type = {
        construct = 1,
        deconstruct = 2,
        deliver = 3,
        deliver_items = 4,
        explode_cliff = 5,
        pickup = 6,
        pickup_items = 7,
        repair = 8,
        upgrade = 9
    },
    rocket_silo_status = {
        arms_advance = 1,
        arms_retract = 2,
        building_rocket = 3,
        create_rocket = 4,
        doors_closing = 5,
        doors_opened = 6,
        doors_opening = 7,
        engine_starting = 8,
        launch_started = 9,
        launch_starting = 10,
        lights_blinking_close = 11,
        lights_blinking_open = 12,
        rocket_flying = 13,
        rocket_ready = 14,
        rocket_rising = 15
    },
    selection_mode = {
        alt_reverse_select = 1,
        alt_select = 2,
        reverse_select = 3,
        select = 4
    },
    shooting = {
        not_shooting = 1,
        shooting_enemies = 2,
        shooting_selected = 3
    },
    signal_state = {
        closed = 1,
        open = 2,
        reserved = 3,
        reserved_by_circuit_network = 4
    },
    space_platform_state = {
        no_path = 1,
        no_schedule = 2,
        on_the_path = 3,
        paused = 4,
        starter_pack_on_the_way = 5,
        starter_pack_requested = 6,
        waiting_at_station = 7,
        waiting_for_departure = 8,
        waiting_for_starter_pack = 9
    },
    train_state = {
        arrive_signal = 1,
        arrive_station = 2,
        destination_full = 3,
        manual_control = 4,
        manual_control_stop = 5,
        no_path = 6,
        no_schedule = 7,
        on_the_path = 8,
        wait_signal = 9,
        wait_station = 10
    },
    transport_line = {
        left_line = 1,
        left_split_line = 2,
        left_underground_line = 3,
        right_line = 4,
        right_split_line = 5,
        right_underground_line = 6,
        secondary_left_line = 7,
        secondary_left_split_line = 8,
        secondary_right_line = 9,
        secondary_right_split_line = 10
    },
    wire_connector_id = {
        circuit_green = 1,
        circuit_red = 2,
        combinator_input_green = 3,
        combinator_input_red = 4,
        combinator_output_green = 5,
        combinator_output_red = 6,
        pole_copper = 7,
        power_switch_left_copper = 8,
        power_switch_right_copper = 9
    },
    wire_origin = {
        player = 1,
        radars = 2,
        script = 3
    },
    wire_type = {
        copper = 1,
        green = 2,
        red = 3
    }
}

-- Mock settings
factorio_mock.settings = {
    startup = {},
    global = {}
}

-- Mock game object
factorio_mock.game = {
    surfaces = {},
    players = {},
    forces = {},
    entity_prototypes = {},
    item_prototypes = {},
    recipe_prototypes = {},
    technology_prototypes = {},
    tick = 0,
    ticks_played = 0,
    finished = false,
    speed = 1.0,
    
    -- Methods
    print = function(msg) print("[GAME] " .. tostring(msg)) end,
    
    get_surface = function(surface_id)
        if type(surface_id) == "number" then
            return factorio_mock.game.surfaces[surface_id]
        elseif type(surface_id) == "string" then
            for _, surface in pairs(factorio_mock.game.surfaces) do
                if surface.name == surface_id then
                    return surface
                end
            end
        end
        return nil
    end,
    
    create_surface = function(name, settings)
        error("create_surface must be called after factorio_mock.init()", 2)
    end,
    
    delete_surface = function(surface)
        local idx = type(surface) == "number" and surface or surface.index
        factorio_mock.game.surfaces[idx] = nil
        return true
    end,
    
    get_player = function(player_id)
        return factorio_mock.game.players[player_id]
    end,
    
    -- Space Age: Quality system
    quality_prototypes = {},
    
    -- Space Age: Space platforms
    space_platforms = {}
}

-- Quality system prototypes (Space Age)
factorio_mock.quality_prototypes = {
    normal = { name = "normal", level = 0, next = "uncommon", color = { r = 1, g = 1, b = 1 } },
    uncommon = { name = "uncommon", level = 1, next = "rare", color = { r = 0, g = 1, b = 0 } },
    rare = { name = "rare", level = 2, next = "epic", color = { r = 0, g = 0.5, b = 1 } },
    epic = { name = "epic", level = 3, next = "legendary", color = { r = 0.7, g = 0, b = 1 } },
    legendary = { name = "legendary", level = 4, next = nil, color = { r = 1, g = 0.8, b = 0 } }
}

-- Space Age: Space platforms
factorio_mock.space_platforms = {}
factorio_mock.space_connection_manager = {}
factorio_mock.space_locations = {
    nauvis = { name = "nauvis", type = "planet", solar_power_in_space = 150 },
    vulcanus = { name = "vulcanus", type = "planet", solar_power_in_space = 300 },
    gleba = { name = "gleba", type = "planet", solar_power_in_space = 75 },
    fulgora = { name = "fulgora", type = "planet", solar_power_in_space = 200 },
    aquilo = { name = "aquilo", type = "planet", solar_power_in_space = 50 }
}

-- Mock remote interface
factorio_mock.remote = {
    add_interface = function(name, functions) end,
    call = function(interface, func, ...) end
}

-- Mock table.deepcopy
factorio_mock.table = {
    deepcopy = function(tbl)
        if type(tbl) ~= "table" then return tbl end
        local result = {}
        for k, v in pairs(tbl) do
            result[k] = factorio_mock.table.deepcopy(v)
        end
        return result
    end
}

-- Mock util module
factorio_mock.util = {
    -- Util functions from Factorio
    table = {
        deepcopy = function(tbl)
            if type(tbl) ~= "table" then return tbl end
            local result = {}
            for k, v in pairs(tbl) do
                result[k] = factorio_mock.util.table.deepcopy(v)
            end
            return result
        end
    },
    
    format_number = function(number, append_suffix)
        return tostring(number)
    end,
    
    distance = function(position1, position2)
        local dx = position1.x - position2.x
        local dy = position1.y - position2.y
        return math.sqrt(dx * dx + dy * dy)
    end,
    
    moveposition = function(position, direction, distance)
        local dir_vectors = {
            [0] = {0, -1}, [1] = {1, -1}, [2] = {1, 0}, [3] = {1, 1},
            [4] = {0, 1}, [5] = {-1, 1}, [6] = {-1, 0}, [7] = {-1, -1}
        }
        local vec = dir_vectors[direction] or {0, 0}
        return {
            x = position.x + vec[1] * distance,
            y = position.y + vec[2] * distance
        }
    end
}

-- Mock log function
factorio_mock.log = function(msg)
    print("[LOG] " .. tostring(msg))
end

-- Make log global
if not _G.log then
    _G.log = factorio_mock.log
end

-- Helper to infer entity type from name
local function infer_entity_type(name)
    if name:find("furnace") then
        return "furnace"
    elseif name:find("assembling%-machine") or name:find("biochamber") or name:find("electromagnetic%-plant") then
        return "assembling-machine"
    elseif name:find("recycler") then
        return "recycler"
    else
        return "assembling-machine"  -- Default
    end
end

-- Mock inventory
local function create_mock_inventory()
    local contents = {}
    return {
        get_contents = function()
            return contents
        end,
        get_item_count = function(item_name)
            return contents[item_name] or 0
        end,
        insert = function(item_stack)
            local name = type(item_stack) == "table" and item_stack.name or item_stack
            local count = type(item_stack) == "table" and item_stack.count or 1
            contents[name] = (contents[name] or 0) + count
            return count
        end,
        remove = function(item_stack)
            local name = type(item_stack) == "table" and item_stack.name or item_stack
            local count = type(item_stack) == "table" and item_stack.count or 1
            local available = contents[name] or 0
            local removed = math.min(available, count)
            contents[name] = available - removed
            if contents[name] <= 0 then contents[name] = nil end
            return removed
        end,
        clear = function()
            contents = {}
        end,
        is_empty = function()
            return next(contents) == nil
        end
    }
end

-- Mock entity prototype with complete API
local function create_mock_entity(name, entity_type)
    local entity_ref
    local mock_inventories = {
        [factorio_mock.defines.inventory.fuel] = create_mock_inventory(),
        [factorio_mock.defines.inventory.furnace_source] = create_mock_inventory(),
        [factorio_mock.defines.inventory.furnace_result] = create_mock_inventory(),
        [factorio_mock.defines.inventory.furnace_modules] = create_mock_inventory(),
        [factorio_mock.defines.inventory.assembling_machine_input] = create_mock_inventory(),
        [factorio_mock.defines.inventory.assembling_machine_output] = create_mock_inventory(),
        [factorio_mock.defines.inventory.assembling_machine_modules] = create_mock_inventory()
    }
    
    entity_ref = {
        -- Basic properties
        name = name,
        type = entity_type or "assembling-machine",
        valid = true,
        unit_number = math.random(1, 999999),
        products_finished = 0,
        position = { x = 0, y = 0 },
        direction = 0,
        force = "player",
        
        -- Quality and Space Age properties
        quality = "normal",
        quality_prototype = { name = "normal", level = 0 },
        spoil_percent = 0,
        frozen = false,
        space_location = false, -- false = not set, allows key detection in validation
        platform_id = false, -- false = not set, allows key detection in validation
        
        -- Priority targets and display panels (2.0.64+)
        priority_targets = false, -- false = not set, allows key detection in validation
        panel_text = "",
        
        -- Cargo pod properties (Space Age)
        cargo_pod_entity = false, -- false = not set, allows key detection in validation
        
        -- Visual properties
        mirroring = false,
        orientation = 0,
        
        -- Bounding box
        bounding_box = {
            left_top = { x = -1, y = -1 },
            right_bottom = { x = 1, y = 1 }
        },
        selection_box = {
            left_top = { x = -1, y = -1 },
            right_bottom = { x = 1, y = 1 }
        },
        
        -- Effects system (Space Age quality system)
        effects = {
            productivity = { bonus = 0, base = 0 },
            speed = { bonus = 0, base = 0 },
            consumption = { bonus = 0, base = 0 },
            pollution = { bonus = 0, base = 0 },
            quality = { bonus = 0, base = 0 }
        },
        
        -- Production properties
        crafting_speed = 1.0,
        crafting_progress = 0,
        bonus_mining_progress = 0,
        bonus_progress = 0,
        productivity_bonus = 0,
        consumption_bonus = 0,
        speed_bonus = 0,
        pollution_bonus = 0,
        
        -- Recipe and crafting
        recipe = false,
        recipe_quality = "normal",
        previous_recipe = false,
        
        -- Energy
        energy = 0,
        electric_buffer_size = 0,
        electric_drain = 0,
        electric_emissions = 0,
        electric_input_flow_limit = 0,
        electric_output_flow_limit = 0,
        
        -- Health and damage
        health = 100,
        prototype = {
            max_health = 100,
            name = name,
            type = entity_type or "assembling-machine"
        },
        
        -- Status
        status = 1, -- working
        is_military_target = false,
        destructible = true,
        operable = true,
        rotatable = true,
        
        -- Module slots
        module_inventory_size = 4,
        
        -- Temperature
        temperature = 0,
        
        -- Fluid boxes (for assembling machines with fluid recipes)
        fluidbox = {},
        
        -- Surface reference (will be set during initialization)
        surface = false, -- false indicates not yet set
        
        -- Visual properties (additional)
        backer_name = false,
        color = false,
        
        -- Mining properties
        mining_progress = 0,
        mining_target = false,
        resource_amount = false,
        
        -- Circuit network properties
        circuit_connected_entities = {},
        wire_connectors = {},
        
        -- Transport properties
        transport_lines = {},
        loader_filter = false,
        splitter_filter = false,
        splitter_input_priority = "left",
        splitter_output_priority = "left",
        belt_to_ground_type = "input",
        
        -- Additional state properties
        active = true,
        minable = true,
        selected = false,
        request_slot_count = 0,
        filter_slot_count = 0,
        recipe_locked = false,
        
        -- Methods: Inventory management
        get_inventory = function(inventory_type)
            return mock_inventories[inventory_type]
        end,
        get_output_inventory = function()
            return mock_inventories[factorio_mock.defines.inventory.assembling_machine_output]
        end,
        get_module_inventory = function()
            return mock_inventories[factorio_mock.defines.inventory.assembling_machine_modules]
        end,
        get_fuel_inventory = function()
            return mock_inventories[factorio_mock.defines.inventory.fuel]
        end,
        get_burnt_result_inventory = function()
            return create_mock_inventory()
        end,
        
        -- Methods: Entity manipulation
        destroy = function(params)
            entity_ref.valid = false
            return true
        end,
        die = function(force, cause)
            entity_ref.health = 0
            entity_ref.valid = false
            return true
        end,
        damage = function(damage, force, damage_type, source, cause)
            entity_ref.health = math.max(0, entity_ref.health - damage)
            if entity_ref.health <= 0 then
                entity_ref.valid = false
            end
            return damage
        end,
        
        -- Methods: Recipe and crafting
        set_recipe = function(recipe_name, quality)
            entity_ref.recipe = recipe_name
            entity_ref.recipe_quality = quality or "normal"
            return true
        end,
        get_recipe = function()
            return entity_ref.recipe
        end,
        
        -- Methods: Rotation
        rotate = function(params)
            local reverse = params and params.reverse or false
            local by_player = params and params.by_player or nil
            if reverse then
                entity_ref.direction = (entity_ref.direction - 1) % 8
            else
                entity_ref.direction = (entity_ref.direction + 1) % 8
            end
            return true
        end,
        
        -- Methods: Mining
        mine = function(params)
            local force = params and params.force or nil
            local ignore_minable = params and params.ignore_minable or false
            entity_ref.valid = false
            return true
        end,
        
        -- Methods: Order
        order_deconstruction = function(force, player)
            return true
        end,
        cancel_deconstruction = function(force, player)
            return true
        end,
        order_upgrade = function(params)
            return true
        end,
        cancel_upgrade = function(force, player)
            return true
        end,
        
        -- Methods: State checks
        can_insert = function(item_stack)
            return true
        end,
        insert = function(item_stack)
            return 1
        end,
        
        -- Methods: Module effects
        get_module_effects = function()
            return {
                productivity = entity_ref.effects.productivity.bonus,
                speed = entity_ref.effects.speed.bonus,
                consumption = entity_ref.effects.consumption.bonus,
                pollution = entity_ref.effects.pollution.bonus,
                quality = entity_ref.effects.quality.bonus
            }
        end,
        get_beacons = function()
            return {}
        end,
        
        -- Methods: Quality system
        get_quality = function()
            return entity_ref.quality_prototype
        end,
        set_quality = function(quality_name)
            entity_ref.quality = quality_name
            entity_ref.quality_prototype = factorio_mock.quality_prototypes[quality_name] or { name = quality_name, level = 0 }
            return true
        end,
        get_quality_multiplier = function()
            local quality_level = entity_ref.quality_prototype.level or 0
            return 1.0 + (quality_level * 0.3)
        end,
        
        -- Methods: Space Age specific
        freeze = function()
            entity_ref.frozen = true
            return true
        end,
        unfreeze = function()
            entity_ref.frozen = false
            return true
        end,
        
        -- Methods: Agricultural Tower (Space Age)
        register_tree_to_agricultural_tower = function(tree_entity)
            if entity_ref.type == "agricultural-tower" then
                return true
            end
            return false
        end,
        
        -- Methods: Logistic Sections (Space Age 2.0+)
        get_logistic_sections = function()
            return {}
        end,
        set_logistic_section = function(section_index, section_data)
            return true
        end,
        
        -- Methods: Direction
        supports_direction = function()
            return entity_ref.rotatable
        end,
        
        -- Methods: Circuit network (added for completeness)
        get_circuit_network = function(wire_type, circuit_connector)
            return {
                connected = false,
                network_id = 0,
                signals = {},
                get_signal = function(signal)
                    return 0
                end
            }
        end,
        connect_neighbour = function(params)
            return true
        end,
        disconnect_neighbour = function(params)
            return true
        end,
        
        -- Methods: Misc
        copy_settings = function(source_entity, by_player)
            if source_entity.recipe then
                entity_ref.recipe = source_entity.recipe
                entity_ref.recipe_quality = source_entity.recipe_quality
            end
            return true
        end,
        
        teleport = function(position, surface)
            entity_ref.position = position
            if surface then
                entity_ref.surface = surface
            end
            return true
        end,
        
        clear_items_inside = function()
            for _, inv in pairs(mock_inventories) do
                inv.clear()
            end
        end,
        
        get_connected_rails = function()
            return {}
        end
    }
    
    return entity_ref
end

-- Mock surface with complete API
local function create_mock_surface()
    local surface_entities = {}
    local surface_ref = {}
    
    -- Basic properties
    surface_ref.index = 1
    surface_ref.name = "nauvis"
    surface_ref.platform = nil
    
    -- Method: Entity creation
    surface_ref.create_entity = function(params)
        if not params then
            error("create_entity called with nil params", 2)
        end
        if not params.name then
            error("create_entity called without name parameter", 2)
        end
        local entity_type = params.type or infer_entity_type(params.name)
        local entity = create_mock_entity(params.name, entity_type)
        entity.surface = surface_ref
        if params.position then entity.position = params.position end
        if params.direction then entity.direction = params.direction end
        if params.force then entity.force = params.force end
        if params.quality then 
            entity.quality = params.quality
            entity.quality_prototype = factorio_mock.quality_prototypes[params.quality] or { name = params.quality, level = 0 }
        end
        
        surface_entities[entity.unit_number] = entity
        return entity
    end
    
    -- Method: Entity finding
    surface_ref.find_entities_filtered = function(filter)
        local results = {}
        for _, entity in pairs(surface_entities) do
            if entity.valid then
                local matches = true
                
                if filter.type then
                    local types = type(filter.type) == "table" and filter.type or { filter.type }
                    local type_match = false
                    for _, t in ipairs(types) do
                        if entity.type == t then
                            type_match = true
                            break
                        end
                    end
                    matches = matches and type_match
                end
                
                if filter.name and entity.name ~= filter.name then
                    matches = false
                end
                
                if filter.force and entity.force ~= filter.force then
                    matches = false
                end
                
                if filter.area then
                    local x, y = entity.position.x, entity.position.y
                    local area = filter.area
                    if x < area.left_top.x or x > area.right_bottom.x or
                       y < area.left_top.y or y > area.right_bottom.y then
                        matches = false
                    end
                end
                
                if matches then
                    table.insert(results, entity)
                end
            end
        end
        return results
    end
    
    surface_ref.find_entity = function(name, pos)
        for _, entity in pairs(surface_entities) do
            if entity.valid and entity.name == name then
                if pos == nil or (entity.position.x == pos.x and entity.position.y == pos.y) then
                    return entity
                end
            end
        end
        return nil
    end
    
    surface_ref.find_entities = function(area)
        return surface_ref.find_entities_filtered({ area = area })
    end
    
    -- Method: Terrain
    surface_ref.get_tile = function(x, y)
        return { name = "grass-1", position = { x = x, y = y } }
    end
    
    surface_ref.set_tiles = function(tiles, params)
        return true
    end
    
    -- Method: Chunks
    surface_ref.is_chunk_generated = function(position)
        return true
    end
    
    surface_ref.request_to_generate_chunks = function(position, radius)
    end
    
    surface_ref.force_generate_chunk_requests = function()
    end
    
    -- Method: Pollution
    surface_ref.get_pollution = function(position)
        return 0
    end
    
    surface_ref.pollute = function(position, amount)
    end
    
    -- Method: Misc
    surface_ref.get_connected_tiles = function(position, tiles)
        return {}
    end
    
    surface_ref.count_entities_filtered = function(filter)
        return #surface_ref.find_entities_filtered(filter)
    end
    
    surface_ref.can_place_entity = function(params)
        return true
    end
    
    surface_ref.spill_item_stack = function(position, items, params)
        return {}
    end
    
    return surface_ref
end

-- Space Age: Platform helpers (defined after create_mock_surface)
function factorio_mock.create_space_platform(name)
    local platform = {}
    platform.name = name
    platform.index = #factorio_mock.space_platforms + 1
    platform.surface = create_mock_surface()
    platform.space_location = nil
    platform.speed = 0
    platform.state = "waiting_at_station"
    platform.valid = true
    
    platform.get_surface = function()
        return platform.surface
    end
    
    platform.destroy = function()
        platform.valid = false
        return true
    end
    
    platform.surface.platform = platform
    table.insert(factorio_mock.space_platforms, platform)
    return platform
end

-- Space Age: Asteroid chunks
factorio_mock.asteroid_chunks = {}
function factorio_mock.create_asteroid_chunk(chunk_type)
    return {
        name = chunk_type .. "-asteroid-chunk",
        type = "asteroid-chunk",
        valid = true,
        chunk_type = chunk_type,
        health = 100
    }
end

-- Space Age: Elevated rails
factorio_mock.elevated_rails = {}
factorio_mock.rail_ramps = {}
factorio_mock.rail_support = {}

-- Redefine game.create_surface now that create_mock_surface is available
factorio_mock.game.create_surface = function(name, settings)
    local new_surface = create_mock_surface()
    new_surface.name = name
    new_surface.index = #factorio_mock.game.surfaces + 1
    factorio_mock.game.surfaces[new_surface.index] = new_surface
    return new_surface
end

-- Initialize mock environment
function factorio_mock.init()
    -- Setup global environment
    _G.storage = factorio_mock.storage
    _G.script = factorio_mock.script
    _G.defines = factorio_mock.defines
    _G.settings = factorio_mock.settings
    _G.game = factorio_mock.game
    _G.remote = factorio_mock.remote
    _G.log = factorio_mock.log
    
    -- Setup table.deepcopy
    if not table.deepcopy then
        table.deepcopy = factorio_mock.table.deepcopy
    end
    
    -- Mock require for "util"
    package.preload["util"] = function()
        return factorio_mock.util
    end
    
    -- Add default surface
    factorio_mock.game.surfaces[1] = create_mock_surface()
    factorio_mock.game.surfaces[1].name = "nauvis"
    
    -- Initialize quality prototypes in game
    factorio_mock.game.quality_prototypes = factorio_mock.quality_prototypes
end

-- Reset mock state
function factorio_mock.reset()
    factorio_mock.storage = {}
    _G.storage = factorio_mock.storage
    factorio_mock.game.surfaces = {}
    factorio_mock.game.surfaces[1] = create_mock_surface()
end

-- Helper to create mock settings
function factorio_mock.set_setting(setting_type, name, value)
    if setting_type == "startup" then
        factorio_mock.settings.startup[name] = { value = value }
    elseif setting_type == "global" then
        factorio_mock.settings.global[name] = { value = value }
    end
end

-- Helper to create mock entity for testing
function factorio_mock.create_entity(name, entity_type, properties)
    local entity = create_mock_entity(name, entity_type)
    if properties then
        for k, v in pairs(properties) do
            entity[k] = v
        end
    end
    return entity
end

-- Phase 4: Extended Runtime Classes (148 missing classes)
factorio_mock.runtime_classes = {}

-- LuaBootstrap - Main script interface
factorio_mock.runtime_classes.LuaBootstrap = {
    on_init = function(callback) end,
    on_load = function(callback) end,
    on_configuration_changed = function(callback) end,
    on_event = function(event, callback, filters) end,
    on_nth_tick = function(tick, callback) end,
    raise_event = function(event, data) end,
    register_on_entity_destroyed = function(entity) return 1 end,
    generate_event_name = function() return 1000 end
}

-- LuaControl - Base class for LuaPlayer and LuaEntity behaviors
factorio_mock.runtime_classes.LuaControl = {
    surface = nil,
    position = {x = 0, y = 0},
    force = nil,
    teleport = function(self, position, surface) return true end,
    can_reach_entity = function(self, entity) return true end,
    clear_items_inside = function(self) return 0 end
}

-- LuaBurner - Burner energy source
factorio_mock.runtime_classes.LuaBurner = {
    currently_burning = nil,
    fuel_categories = {},
    inventory = {},
    burnt_result_inventory = {},
    remaining_burning_fuel = 0,
    heat = 0,
    heat_capacity = 1000
}

-- LuaFluidBox - Fluid box interface
factorio_mock.runtime_classes.LuaFluidBox = {
    get_prototype = function(self, index) return {} end,
    get_capacity = function(self, index) return 1000 end,
    get_connections = function(self, index) return {} end,
    get_filter = function(self, index) return nil end,
    set_filter = function(self, index, filter) return true end,
    get_flow = function(self, index) return 0 end,
    get_locked_fluid = function(self, index) return nil end,
    get_fluid_system_id = function(self, index) return 0 end,
    get_fluid_system_contents = function(self, index) return {} end
}

-- Additional runtime classes for comprehensive coverage
factorio_mock.runtime_classes.LuaCircuitNetwork = {valid = true, network_id = 0, signals = {}}
factorio_mock.runtime_classes.LuaWireConnector = {valid = true, wire_connector_id = 1, connections = {}}
factorio_mock.runtime_classes.LuaControlBehavior = {valid = true, entity = nil, type = nil}

-- LuaLogisticNetwork - Logistic network
factorio_mock.runtime_classes.LuaLogisticNetwork = {valid = true, force = nil, all_logistic_robots = 0, available_logistic_robots = 0, all_construction_robots = 0, available_construction_robots = 0}
factorio_mock.runtime_classes.LuaLogisticPoint = {valid = true, owner = nil, mode = 1}
factorio_mock.runtime_classes.LuaLogisticCell = {valid = true, mobile = false, owner = nil}
factorio_mock.runtime_classes.LuaLogisticSection = {valid = true, owner = nil, index = 1}
factorio_mock.runtime_classes.LuaLogisticSections = {valid = true, owner = nil, sections = {}}
factorio_mock.runtime_classes.LuaTrain = {valid = true, id = 1, state = 8, speed = 0}
factorio_mock.runtime_classes.LuaRailPath = {valid = true, size = 0, current = 1}
factorio_mock.runtime_classes.LuaTrainManager = {get_train_by_id = function(self, id) return nil end}
factorio_mock.runtime_classes.LuaTransportLine = {valid = true, owner = nil, get_contents = function(self) return {} end}
factorio_mock.runtime_classes.LuaEquipmentGrid = {valid = true, width = 10, height = 10, equipment = {}}
factorio_mock.runtime_classes.LuaEquipment = {valid = true, name = "", type = "", energy = 0}
factorio_mock.runtime_classes.LuaRecipe = {valid = true, name = "", enabled = true, category = "crafting"}
factorio_mock.runtime_classes.LuaTechnology = {valid = true, name = "", researched = false, level = 1}
factorio_mock.runtime_classes.LuaCustomTable = {}
factorio_mock.runtime_classes.LuaLazyLoadedValue = {valid = true, get = function(self) return nil end}
factorio_mock.runtime_classes.LuaProfiler = {valid = true, reset = function(self) end}
factorio_mock.runtime_classes.LuaFlowStatistics = {valid = true, get_input_count = function(self, name) return 0 end}
factorio_mock.runtime_classes.LuaPermissionGroup = {valid = true, name = "", group_id = 1, players = {}}
factorio_mock.runtime_classes.LuaPermissionGroups = {groups = {}, get_group = function(self, group) return nil end}
factorio_mock.runtime_classes.LuaGui = {valid = true, top = {}, left = {}, center = {}}
factorio_mock.runtime_classes.LuaGuiElement = {valid = true, name = "", type = "button", visible = true}
factorio_mock.runtime_classes.LuaStyle = {valid = true, name = "", minimal_width = 0}
factorio_mock.runtime_classes.LuaGroup = {valid = true, name = "", type = "item"}
factorio_mock.runtime_classes.LuaCommandProcessor = {commands = {}}
factorio_mock.runtime_classes.LuaCommandable = {valid = true, entity = nil, command = nil}
factorio_mock.runtime_classes.LuaChunkIterator = {}
factorio_mock.runtime_classes.LuaRandomGenerator = {valid = true}
factorio_mock.runtime_classes.LuaRendering = {}
factorio_mock.runtime_classes.LuaRenderObject = {valid = true, id = 1, type = "line"}
factorio_mock.runtime_classes.LuaRemote = {interfaces = {}}
factorio_mock.runtime_classes.LuaSettings = {startup = {}, global = {}, player = {}}
factorio_mock.runtime_classes.LuaRCON = {print = function(msg) print("[RCON] " .. msg) end}
factorio_mock.runtime_classes.LuaHelpers = {}

-- Space Age classes
factorio_mock.runtime_classes.LuaPlanet = {valid = true, name = "nauvis", surface = nil}
factorio_mock.runtime_classes.LuaSpacePlatform = {valid = true, name = "", surface = nil, force = nil}
factorio_mock.runtime_classes.LuaSpaceConnection = {valid = true, name = "", from = nil, to = nil}
factorio_mock.runtime_classes.LuaSpaceLocation = {valid = true, name = "", type = "planet"}
factorio_mock.runtime_classes.LuaCargoHatch = {valid = true, entity = nil, filter = nil}
factorio_mock.runtime_classes.LuaTerritory = {valid = true, name = "", surface = nil}
factorio_mock.runtime_classes.LuaSegment = {valid = true, entity = nil, segment_index = 0}
factorio_mock.runtime_classes.LuaSegmentedUnit = {valid = true, segments = {}}

-- Prototype classes
factorio_mock.runtime_classes.LuaAchievementPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaActiveTriggerPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaAirbornePollutantPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaAmmoCategoryPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaAsteroidChunkPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaAutoplaceControlPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaBurnerPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaBurnerUsagePrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaCollisionLayerPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaCustomEventPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaCustomInputPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaDamagePrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaDecorativePrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaElectricEnergySourcePrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaEquipmentCategoryPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaEquipmentGridPrototype = {valid = true, name = "", width = 10, height = 10}
factorio_mock.runtime_classes.LuaEquipmentPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaFluidBoxPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaFluidEnergySourcePrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaFluidPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaFontPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaFuelCategoryPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaHeatBufferPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaHeatEnergySourcePrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaItemPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaItemCommon = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaModSettingPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaModuleCategoryPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaNamedNoiseExpression = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaNamedNoiseFunction = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaParticlePrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaProcessionLayerInheritanceGroupPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaProcessionPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaPrototypeBase = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaPrototypes = {valid = true, entity = {}, item = {}}
factorio_mock.runtime_classes.LuaQualityPrototype = {valid = true, name = "normal", level = 0}
factorio_mock.runtime_classes.LuaRecipeCategoryPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaRecipePrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaRecord = {valid = true}
factorio_mock.runtime_classes.LuaResourceCategoryPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaShortcutPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaSimulation = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaSpaceConnectionPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaSpaceLocationPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaSurfacePropertyPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaSurfacePrototype = {valid = true, name = "nauvis"}
factorio_mock.runtime_classes.LuaTechnologyPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaTilePrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaTrivialSmokePrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaVirtualSignalPrototype = {valid = true, name = ""}
factorio_mock.runtime_classes.LuaVoidEnergySourcePrototype = {valid = true, name = ""}

-- Additional control behaviors
factorio_mock.runtime_classes.LuaAccumulatorControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaArithmeticCombinatorControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaDeciderCombinatorControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaConstantCombinatorControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaGenericOnOffControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaInserterControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaLampControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaContainerControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaStorageTankControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaTransportBeltControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaMiningDrillControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaWallControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaProgrammableSpeakerControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaRoboportControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaTrainStopControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaRailSignalBaseControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaSplitterControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaAssemblingMachineControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaFurnaceControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaReactorControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaRadarControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaPumpControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaRocketSiloControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaLoaderControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaLogisticContainerControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaProxyContainerControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaTurretControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaArtilleryTurretControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaDisplayPanelControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaSelectorCombinatorControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaCombinatorControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaAgriculturalTowerControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaAsteroidCollectorControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaCargoLandingPadControlBehavior = {valid = true}
factorio_mock.runtime_classes.LuaSpacePlatformHubControlBehavior = {valid = true}

-- Additional missing classes
factorio_mock.runtime_classes.LuaRailEnd = {valid = true, rail = nil, direction = 0}
factorio_mock.runtime_classes.LuaSchedule = {valid = true, records = {}, current = 1}
factorio_mock.runtime_classes.LuaAISettings = {valid = true, allow_destroy_when_commands_fail = true}
factorio_mock.runtime_classes.LuaModData = {valid = true}
factorio_mock.runtime_classes.LuaItem = {valid = true, name = "", count = 1}
factorio_mock.runtime_classes.LuaTile = {valid = true, name = "", position = {x = 0, y = 0}}
factorio_mock.runtime_classes.LuaCustomChartTag = {valid = true, text = ""}
factorio_mock.runtime_classes.LuaUndoRedoStack = {valid = true, can_undo = false}
factorio_mock.runtime_classes.LuaInventory = {valid = true, index = 1, get_item_count = function(self, item) return 0 end}
factorio_mock.runtime_classes.LuaItemStack = {valid = true, name = nil, count = 0}

return factorio_mock
