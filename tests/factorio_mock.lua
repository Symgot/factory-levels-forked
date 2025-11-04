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
        
        -- Player events
        on_player_created = 50,
        on_player_joined_game = 51,
        on_player_left_game = 52,
        on_player_died = 53,
        on_player_respawned = 54,
        on_player_changed_position = 55,
        on_player_changed_surface = 56,
        on_player_driving_changed_state = 57,
        
        -- GUI events
        on_gui_click = 60,
        on_gui_opened = 61,
        on_gui_closed = 62,
        on_gui_text_changed = 63,
        on_gui_elem_changed = 64,
        on_gui_selection_state_changed = 65,
        on_gui_checked_state_changed = 66,
        on_gui_value_changed = 67,
        
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
        lab_modules = 11
    },
    flow_precision_index = {
        fifty_hours = 0,
        ten_hours = 1,
        two_hours = 2,
        one_hour = 3,
        ten_minutes = 4,
        one_minute = 5,
        five_seconds = 6
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
        space_location = nil,
        platform_id = nil,
        
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
        recipe = nil,
        recipe_quality = "normal",
        previous_recipe = nil,
        
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
        
        -- Surface reference
        surface = nil, -- Will be set during initialization
        
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
        
        -- Methods: Quality system
        get_quality = function()
            return entity_ref.quality_prototype
        end,
        set_quality = function(quality_name)
            entity_ref.quality = quality_name
            entity_ref.quality_prototype = factorio_mock.quality_prototypes[quality_name] or { name = quality_name, level = 0 }
            return true
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
        
        -- Methods: Direction
        supports_direction = function()
            return entity_ref.rotatable
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
        end,
        
        get_burnt_result_inventory = function()
            return mock_inventories[factorio_mock.defines.inventory.burnt_result]
        end
    }
    
    return entity_ref
end

-- Mock surface with complete API
local function create_mock_surface()
    local surface_entities = {}
    
    local surface_ref = {
        index = 1,
        name = "nauvis",
        platform = nil, -- Space Age: nil for planets, object for space platforms
        
        -- Methods: Entity creation
        create_entity = function(params)
            if not params then
                error("create_entity called with nil params", 2)
            end
            if not params.name then
                error("create_entity called without name parameter", 2)
            end
            local entity = create_mock_entity(params.name, params.type or "assembling-machine")
            -- Debug: Check if surface_ref is available
            if not surface_ref then
                error("surface_ref is nil in create_entity!", 2)
            end
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
        end,
        
        -- Methods: Entity finding
        find_entities_filtered = function(filter)
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
        end,
        
        find_entity = function(name, pos)
            for _, entity in pairs(surface_entities) do
                if entity.valid and entity.name == name then
                    if pos == nil or (entity.position.x == pos.x and entity.position.y == pos.y) then
                        return entity
                    end
                end
            end
            return nil
        end,
        
        find_entities = function(area)
            return surface_ref.find_entities_filtered({ area = area })
        end,
        
        -- Methods: Terrain manipulation
        get_tile = function(x, y)
            return { name = "grass-1", position = { x = x, y = y } }
        end,
        
        set_tiles = function(tiles, params)
            return true
        end,
        
        -- Methods: Chunks
        is_chunk_generated = function(position)
            return true
        end,
        
        request_to_generate_chunks = function(position, radius)
        end,
        
        force_generate_chunk_requests = function()
        end,
        
        -- Methods: Pollution
        get_pollution = function(position)
            return 0
        end,
        
        pollute = function(position, amount)
        end,
        
        -- Methods: Misc
        get_connected_tiles = function(position, tiles)
            return {}
        end,
        
        count_entities_filtered = function(filter)
            return #surface_ref.find_entities_filtered(filter)
        end,
        
        can_place_entity = function(params)
            return true
        end,
        
        spill_item_stack = function(position, items, params)
            return {}
        end,
        
        -- Space Age: Platform specific methods
        request_to_generate_chunks = function(position, radius)
        end
    }
    
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

return factorio_mock
