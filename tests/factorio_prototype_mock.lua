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
        ["pump"] = {},
        ["storage-tank"] = {},
        ["transport-belt"] = {},
        ["underground-belt"] = {},
        ["splitter"] = {},
        ["loader"] = {},
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
        
        -- Phase 4: Extended entity prototypes (154 missing types)
        ["airborne-pollutant"] = {},
        ["ambient-sound"] = {},
        ["ammo-category"] = {},
        ["ammo-turret"] = {},
        ["animation"] = {},
        ["arithmetic-combinator"] = {},
        ["arrow"] = {},
        ["artillery-flare"] = {},
        ["artillery-projectile"] = {},
        ["artillery-turret"] = {},
        ["asteroid"] = {},
        ["autoplace-control"] = {},
        ["beam"] = {},
        ["build-entity-achievement"] = {},
        ["burner-generator"] = {},
        ["burner-usage"] = {},
        ["capture-robot"] = {},
        ["cargo-landing-pad"] = {},
        ["chain-active-trigger"] = {},
        ["change-surface-achievement"] = {},
        ["character-corpse"] = {},
        ["collision-layer"] = {},
        ["combat-robot"] = {},
        ["combat-robot-count-achievement"] = {},
        ["complete-objective-achievement"] = {},
        ["constant-combinator"] = {},
        ["construct-with-robots-achievement"] = {},
        ["construction-robot"] = {},
        ["copy-paste-tool"] = {},
        ["create-platform-achievement"] = {},
        ["curved-rail-a"] = {},
        ["curved-rail-b"] = {},
        ["custom-event"] = {},
        ["custom-input"] = {},
        ["damage-type"] = {},
        ["decider-combinator"] = {},
        ["deconstruct-with-robots-achievement"] = {},
        ["deconstructible-tile-proxy"] = {},
        ["delayed-active-trigger"] = {},
        ["deliver-by-robots-achievement"] = {},
        ["deliver-category"] = {},
        ["deliver-impact-combination"] = {},
        ["deplete-resource-achievement"] = {},
        ["destroy-cliff-achievement"] = {},
        ["display-panel"] = {},
        ["dont-build-entity-achievement"] = {},
        ["dont-craft-manually-achievement"] = {},
        ["dont-kill-manually-achievement"] = {},
        ["dont-research-before-researching-achievement"] = {},
        ["dont-use-entity-in-energy-production-achievement"] = {},
        ["editor-controller"] = {},
        ["electric-turret"] = {},
        ["elevated-curved-rail-a"] = {},
        ["elevated-curved-rail-b"] = {},
        ["elevated-half-diagonal-rail"] = {},
        ["entity-ghost"] = {},
        ["equip-armor-achievement"] = {},
        ["equipment-category"] = {},
        ["equipment-ghost"] = {},
        ["equipment-grid"] = {},
        ["fire"] = {},
        ["fluid-turret"] = {},
        ["font"] = {},
        ["fuel-category"] = {},
        ["god-controller"] = {},
        ["group-attack-achievement"] = {},
        ["gui-style"] = {},
        ["half-diagonal-rail"] = {},
        ["heat-interface"] = {},
        ["highlight-box"] = {},
        ["impact-category"] = {},
        ["infinity-cargo-wagon"] = {},
        ["infinity-pipe"] = {},
        ["inventory-bonus-equipment"] = {},
        ["item-group"] = {},
        ["item-request-proxy"] = {},
        ["item-subgroup"] = {},
        ["kill-achievement"] = {},
        ["lane-splitter"] = {},
        ["legacy-curved-rail"] = {},
        ["legacy-straight-rail"] = {},
        ["lightning"] = {},
        ["linked-belt"] = {},
        ["linked-container"] = {},
        ["loader"] = {},
        ["loader-1x1"] = {},
        ["logistic-robot"] = {},
        ["map-gen-presets"] = {},
        ["map-settings"] = {},
        ["market"] = {},
        ["mod-data"] = {},
        ["module-category"] = {},
        ["module-transfer-achievement"] = {},
        ["mouse-cursor"] = {},
        ["noise-expression"] = {},
        ["noise-function"] = {},
        ["offshore-pump"] = {},
        ["optimized-decorative"] = {},
        ["optimized-particle"] = {},
        ["particle-source"] = {},
        ["pipe-to-ground"] = {},
        ["place-equipment-achievement"] = {},
        ["plant"] = {},
        ["player-damaged-achievement"] = {},
        ["player-port"] = {},
        ["power-switch"] = {},
        ["procession"] = {},
        ["procession-layer-inheritance-group"] = {},
        ["produce-achievement"] = {},
        ["produce-per-hour-achievement"] = {},
        ["programmable-speaker"] = {},
        ["proxy-container"] = {},
        ["pump"] = {},
        ["rail-remnants"] = {},
        ["recipe-category"] = {},
        ["remote-controller"] = {},
        ["research-achievement"] = {},
        ["research-with-science-pack-achievement"] = {},
        ["resource-category"] = {},
        ["rocket-silo-rocket"] = {},
        ["rocket-silo-rocket-shadow"] = {},
        ["segment"] = {},
        ["segmented-unit"] = {},
        ["selector-combinator"] = {},
        ["shoot-achievement"] = {},
        ["shortcut"] = {},
        ["smoke-with-trigger"] = {},
        ["space-connection"] = {},
        ["space-connection-distance-traveled-achievement"] = {},
        ["spectator-controller"] = {},
        ["speech-bubble"] = {},
        ["spider-leg"] = {},
        ["spider-unit"] = {},
        ["sprite"] = {},
        ["sticker"] = {},
        ["straight-rail"] = {},
        ["stream"] = {},
        ["surface"] = {},
        ["temporary-container"] = {},
        ["thruster"] = {},
        ["tile-effect"] = {},
        ["tile-ghost"] = {},
        ["tips-and-tricks-item"] = {},
        ["tips-and-tricks-item-category"] = {},
        ["train-path-achievement"] = {},
        ["trigger-target-type"] = {},
        ["trivial-smoke"] = {},
        ["tutorial"] = {},
        ["use-entity-in-energy-production-achievement"] = {},
        ["use-item-achievement"] = {},
        ["utility-constants"] = {},
        ["utility-sounds"] = {},
        ["utility-sprites"] = {},
        ["valve"] = {},
        
        -- Space Age entities
        ["recycler"] = {},
        ["space-platform-hub"] = {},
        ["asteroid-collector"] = {},
        ["cargo-bay"] = {},
        ["cargo-pod"] = {},
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
