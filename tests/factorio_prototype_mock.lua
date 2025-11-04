-- Factorio Prototype Stage API Mock
-- Reference: https://lua-api.factorio.com/latest/index-prototype.html
-- Reference: https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html

local prototype_mock = {}

-- Data table structure - holds all prototype definitions
prototype_mock.data = {
    raw = {
        -- Entity prototypes
        ["furnace"] = {},
        ["assembling-machine"] = {},
        ["mining-drill"] = {},
        ["lab"] = {},
        ["beacon"] = {},
        ["rocket-silo"] = {},
        ["roboport"] = {},
        ["electric-pole"] = {},
        ["pipe"] = {},
        ["storage-tank"] = {},
        ["transport-belt"] = {},
        ["underground-belt"] = {},
        ["splitter"] = {},
        ["inserter"] = {},
        ["electric-energy-interface"] = {},
        ["boiler"] = {},
        ["generator"] = {},
        ["solar-panel"] = {},
        ["accumulator"] = {},
        ["reactor"] = {},
        ["heat-pipe"] = {},
        ["wall"] = {},
        ["gate"] = {},
        ["turret"] = {},
        ["radar"] = {},
        ["lamp"] = {},
        ["land-mine"] = {},
        ["rail"] = {},
        ["train-stop"] = {},
        ["rail-signal"] = {},
        ["rail-chain-signal"] = {},
        ["locomotive"] = {},
        ["cargo-wagon"] = {},
        ["fluid-wagon"] = {},
        ["artillery-wagon"] = {},
        ["car"] = {},
        ["spider-vehicle"] = {},
        ["tree"] = {},
        ["simple-entity"] = {},
        ["simple-entity-with-owner"] = {},
        ["simple-entity-with-force"] = {},
        ["resource"] = {},
        ["cliff"] = {},
        ["fish"] = {},
        ["character"] = {},
        ["unit"] = {},
        ["unit-spawner"] = {},
        ["turret"] = {},
        ["projectile"] = {},
        ["explosion"] = {},
        ["particle"] = {},
        ["corpse"] = {},
        ["item-entity"] = {},
        ["container"] = {},
        ["logistic-container"] = {},
        ["infinity-container"] = {},
        
        -- Space Age entities
        ["recycler"] = {},
        ["space-platform-hub"] = {},
        ["asteroid-collector"] = {},
        ["cargo-bay"] = {},
        ["elevated-straight-rail"] = {},
        ["elevated-curved-rail"] = {},
        ["rail-ramp"] = {},
        ["rail-support"] = {},
        ["agricultural-tower"] = {},
        ["captive-biter-spawner"] = {},
        ["fusion-reactor"] = {},
        ["fusion-generator"] = {},
        ["lightning-attractor"] = {},
        ["heating-tower"] = {},
        
        -- Item prototypes
        ["item"] = {},
        ["ammo"] = {},
        ["capsule"] = {},
        ["gun"] = {},
        ["item-with-entity-data"] = {},
        ["item-with-label"] = {},
        ["item-with-inventory"] = {},
        ["blueprint-book"] = {},
        ["item-with-tags"] = {},
        ["selection-tool"] = {},
        ["blueprint"] = {},
        ["deconstruction-item"] = {},
        ["upgrade-item"] = {},
        ["module"] = {},
        ["rail-planner"] = {},
        ["spidertron-remote"] = {},
        ["tool"] = {},
        ["armor"] = {},
        ["repair-tool"] = {},
        
        -- Space Age items
        ["space-platform-starter-pack"] = {},
        ["quality-module"] = {},
        
        -- Recipe prototypes
        ["recipe"] = {},
        
        -- Fluid prototypes
        ["fluid"] = {},
        
        -- Technology prototypes
        ["technology"] = {},
        
        -- Equipment prototypes
        ["equipment"] = {},
        ["roboport-equipment"] = {},
        ["belt-immunity-equipment"] = {},
        ["energy-shield-equipment"] = {},
        ["battery-equipment"] = {},
        ["solar-panel-equipment"] = {},
        ["generator-equipment"] = {},
        ["movement-bonus-equipment"] = {},
        ["night-vision-equipment"] = {},
        ["active-defense-equipment"] = {},
        
        -- Tile prototypes
        ["tile"] = {},
        
        -- Virtual signal prototypes
        ["virtual-signal"] = {},
        
        -- Achievement prototypes
        ["achievement"] = {},
        
        -- Sound prototypes
        ["sound"] = {},
        
        -- Space Age specific
        ["quality"] = {},
        ["space-location"] = {},
        ["surface-property"] = {},
        ["planet"] = {},
        ["asteroid-chunk"] = {}
    },
    
    -- Extend function - adds prototypes to data.raw
    extend = function(self, prototypes)
        if type(prototypes) ~= "table" then
            error("data:extend() requires a table", 2)
        end
        
        for _, prototype in ipairs(prototypes) do
            if type(prototype) ~= "table" then
                error("Each prototype must be a table", 2)
            end
            
            if not prototype.type then
                error("Prototype missing 'type' field: " .. tostring(prototype.name), 2)
            end
            
            if not prototype.name then
                error("Prototype missing 'name' field for type: " .. tostring(prototype.type), 2)
            end
            
            -- Ensure the category exists
            if not self.raw[prototype.type] then
                self.raw[prototype.type] = {}
            end
            
            -- Add or overwrite the prototype
            self.raw[prototype.type][prototype.name] = prototype
        end
    end
}

-- Helper function to validate prototype fields
function prototype_mock.validate_prototype(prototype)
    local required_fields = { "type", "name" }
    
    for _, field in ipairs(required_fields) do
        if not prototype[field] then
            return false, "Missing required field: " .. field
        end
    end
    
    return true
end

-- Helper to get a prototype by type and name
function prototype_mock.get_prototype(prototype_type, name)
    if not prototype_mock.data.raw[prototype_type] then
        return nil
    end
    return prototype_mock.data.raw[prototype_type][name]
end

-- Helper to check if a prototype exists
function prototype_mock.prototype_exists(prototype_type, name)
    return prototype_mock.get_prototype(prototype_type, name) ~= nil
end

-- Initialize the global data object
function prototype_mock.init()
    _G.data = prototype_mock.data
    
    -- Add some commonly used base game prototypes for testing
    prototype_mock.data:extend({
        {
            type = "assembling-machine",
            name = "assembling-machine-1",
            crafting_speed = 0.5,
            energy_usage = "75kW",
            module_specification = { module_slots = 2 }
        },
        {
            type = "assembling-machine",
            name = "assembling-machine-2",
            crafting_speed = 0.75,
            energy_usage = "150kW",
            module_specification = { module_slots = 2 }
        },
        {
            type = "assembling-machine",
            name = "assembling-machine-3",
            crafting_speed = 1.25,
            energy_usage = "375kW",
            module_specification = { module_slots = 4 }
        },
        {
            type = "furnace",
            name = "stone-furnace",
            crafting_speed = 1,
            energy_usage = "90kW",
            module_specification = { module_slots = 0 }
        },
        {
            type = "furnace",
            name = "steel-furnace",
            crafting_speed = 2,
            energy_usage = "90kW",
            module_specification = { module_slots = 0 }
        },
        {
            type = "furnace",
            name = "electric-furnace",
            crafting_speed = 2,
            energy_usage = "180kW",
            module_specification = { module_slots = 2 }
        }
    })
    
    -- Space Age entities
    if prototype_mock.space_age_enabled then
        prototype_mock.data:extend({
            {
                type = "recycler",
                name = "recycler",
                crafting_speed = 0.5,
                energy_usage = "250kW",
                module_specification = { module_slots = 4 }
            },
            {
                type = "assembling-machine",
                name = "electromagnetic-plant",
                crafting_speed = 2,
                energy_usage = "2MW",
                module_specification = { module_slots = 5 }
            },
            {
                type = "assembling-machine",
                name = "biochamber",
                crafting_speed = 2,
                energy_usage = "500kW",
                module_specification = { module_slots = 4 }
            }
        })
    end
end

-- Settings for Space Age features
prototype_mock.space_age_enabled = true

-- Reset the prototype database
function prototype_mock.reset()
    for prototype_type, _ in pairs(prototype_mock.data.raw) do
        prototype_mock.data.raw[prototype_type] = {}
    end
end

return prototype_mock
