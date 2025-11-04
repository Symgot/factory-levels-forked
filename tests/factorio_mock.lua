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

-- Mock defines
factorio_mock.defines = {
    events = {
        on_player_mined_entity = 1,
        on_robot_mined_entity = 2,
        on_robot_built_entity = 3,
        on_built_entity = 4,
        on_runtime_mod_setting_changed = 5
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
    print = function(msg) print("[GAME] " .. tostring(msg)) end
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
factorio_mock.util = {}

-- Mock entity prototype
local function create_mock_entity(name, entity_type)
    return {
        name = name,
        type = entity_type or "assembling-machine",
        valid = true,
        unit_number = math.random(1, 999999),
        products_finished = 0,
        position = { x = 0, y = 0 },
        direction = 0,
        force = "player",
        surface = {
            index = 1,
            name = "nauvis",
            create_entity = function(params) 
                return create_mock_entity(params.name, params.type or "assembling-machine")
            end,
            find_entities_filtered = function(filter) return {} end,
            find_entity = function(name, pos) return nil end
        },
        quality = "normal",
        bounding_box = {
            left_top = { x = -1, y = -1 },
            right_bottom = { x = 1, y = 1 }
        },
        mirroring = false,
        effects = {
            productivity = 0,
            speed = 0,
            consumption = 0,
            pollution = 0,
            quality = 0
        },
        get_inventory = function(inventory_type) return nil end,
        destroy = function() end
    }
end

-- Mock surface
local function create_mock_surface()
    return {
        index = 1,
        name = "nauvis",
        create_entity = function(params)
            return create_mock_entity(params.name, params.type or "assembling-machine")
        end,
        find_entities_filtered = function(filter)
            return {}
        end,
        find_entity = function(name, pos)
            return nil
        end
    }
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
