#!/usr/bin/env lua5.3
-- Test suite for Phase 4: Extended Prototype Classes (154 types)
-- Reference: https://lua-api.factorio.com/latest/prototypes.html

local lu = require('luaunit')
local prototype_mock = require('factorio_prototype_mock')

TestPrototypeClassesExtended = {}

-- Test prototype mock structure
function TestPrototypeClassesExtended:testPrototypeMockExists()
    lu.assertNotNil(prototype_mock)
    lu.assertNotNil(prototype_mock.data)
    lu.assertNotNil(prototype_mock.data.raw)
end

-- Test Phase 4 extended prototype types (154 new types)
function TestPrototypeClassesExtended:testExtendedPrototypeTypes()
    local extended_types = {
        "airborne-pollutant",
        "ambient-sound",
        "ammo-category",
        "ammo-turret",
        "animation",
        "arithmetic-combinator",
        "arrow",
        "artillery-flare",
        "artillery-projectile",
        "artillery-turret",
        "asteroid",
        "autoplace-control",
        "beam",
        "build-entity-achievement",
        "burner-generator",
        "burner-usage",
        "capture-robot",
        "cargo-landing-pad",
        "chain-active-trigger",
        "change-surface-achievement",
        "character-corpse",
        "collision-layer",
        "combat-robot",
        "combat-robot-count-achievement",
        "complete-objective-achievement",
        "constant-combinator",
        "construct-with-robots-achievement",
        "construction-robot",
        "copy-paste-tool",
        "create-platform-achievement",
        "curved-rail-a",
        "curved-rail-b",
        "custom-event",
        "custom-input",
        "damage-type",
        "decider-combinator",
        "deconstruct-with-robots-achievement",
        "deconstructible-tile-proxy",
        "delayed-active-trigger",
        "deliver-by-robots-achievement",
        "deliver-category",
        "deliver-impact-combination",
        "deplete-resource-achievement",
        "destroy-cliff-achievement",
        "display-panel",
        "dont-build-entity-achievement",
        "dont-craft-manually-achievement",
        "dont-kill-manually-achievement",
        "dont-research-before-researching-achievement",
        "dont-use-entity-in-energy-production-achievement",
        "editor-controller",
        "electric-turret",
        "elevated-curved-rail-a",
        "elevated-curved-rail-b",
        "elevated-half-diagonal-rail",
        "entity-ghost",
        "equip-armor-achievement",
        "equipment-category",
        "equipment-ghost",
        "equipment-grid",
        "fire",
        "fluid-turret",
        "font",
        "fuel-category",
        "god-controller",
        "group-attack-achievement",
        "gui-style",
        "half-diagonal-rail",
        "heat-interface",
        "highlight-box",
        "impact-category",
        "infinity-cargo-wagon",
        "infinity-pipe",
        "inventory-bonus-equipment",
        "item-group",
        "item-request-proxy",
        "item-subgroup",
        "kill-achievement",
        "lane-splitter",
        "legacy-curved-rail",
        "legacy-straight-rail",
        "lightning",
        "linked-belt",
        "linked-container",
        "loader",
        "loader-1x1",
        "logistic-robot",
        "map-gen-presets",
        "map-settings",
        "market",
        "mod-data",
        "module-category",
        "module-transfer-achievement",
        "mouse-cursor",
        "noise-expression",
        "noise-function",
        "offshore-pump",
        "optimized-decorative",
        "optimized-particle",
        "particle-source",
        "pipe-to-ground",
        "place-equipment-achievement",
        "plant",
        "player-damaged-achievement",
        "player-port",
        "power-switch",
        "procession",
        "procession-layer-inheritance-group",
        "produce-achievement",
        "produce-per-hour-achievement",
        "programmable-speaker",
        "proxy-container",
        "pump",
        "rail-remnants",
        "recipe-category",
        "remote-controller",
        "research-achievement",
        "research-with-science-pack-achievement",
        "resource-category",
        "rocket-silo-rocket",
        "rocket-silo-rocket-shadow",
        "segment",
        "segmented-unit",
        "selector-combinator",
        "shoot-achievement",
        "shortcut",
        "smoke-with-trigger",
        "space-connection",
        "space-connection-distance-traveled-achievement",
        "spectator-controller",
        "speech-bubble",
        "spider-leg",
        "spider-unit",
        "sprite",
        "sticker",
        "straight-rail",
        "stream",
        "surface",
        "temporary-container",
        "thruster",
        "tile-effect",
        "tile-ghost",
        "tips-and-tricks-item",
        "tips-and-tricks-item-category",
        "train-path-achievement",
        "trigger-target-type",
        "trivial-smoke",
        "tutorial",
        "use-entity-in-energy-production-achievement",
        "use-item-achievement",
        "utility-constants",
        "utility-sounds",
        "utility-sprites",
        "valve"
    }
    
    for _, prototype_type in ipairs(extended_types) do
        local type_table = prototype_mock.data.raw[prototype_type]
        lu.assertNotNil(type_table, "Missing prototype type: " .. prototype_type)
        lu.assertIsTable(type_table, prototype_type .. " should be a table")
    end
end

-- Test original prototype types still exist
function TestPrototypeClassesExtended:testOriginalPrototypeTypes()
    local original_types = {
        "furnace",
        "assembling-machine",
        "mining-drill",
        "lab",
        "beacon",
        "rocket-silo",
        "roboport",
        "electric-pole",
        "transport-belt",
        "inserter",
        "container",
        "item",
        "fluid",
        "recipe",
        "technology",
        "module"
    }
    
    for _, prototype_type in ipairs(original_types) do
        local type_table = prototype_mock.data.raw[prototype_type]
        lu.assertNotNil(type_table, "Original prototype type missing: " .. prototype_type)
    end
end

-- Test Space Age prototype types
function TestPrototypeClassesExtended:testSpaceAgePrototypeTypes()
    local space_age_types = {
        "recycler",
        "space-platform-hub",
        "asteroid-collector",
        "cargo-bay",
        "cargo-pod",
        "elevated-straight-rail",
        "elevated-curved-rail",
        "rail-ramp",
        "rail-support",
        "agricultural-tower",
        "captive-biter-spawner",
        "fusion-reactor",
        "fusion-generator",
        "lightning-attractor",
        "heating-tower"
    }
    
    for _, prototype_type in ipairs(space_age_types) do
        local type_table = prototype_mock.data.raw[prototype_type]
        lu.assertNotNil(type_table, "Space Age prototype type missing: " .. prototype_type)
    end
end

-- Test prototype data.extend function
function TestPrototypeClassesExtended:testDataExtend()
    lu.assertIsFunction(prototype_mock.data.extend)
    
    -- Test extending with new prototype
    local test_prototype = {
        type = "item",
        name = "test-item",
        stack_size = 100
    }
    
    prototype_mock.data:extend({test_prototype})
    
    -- Verify it was added
    lu.assertNotNil(prototype_mock.data.raw["item"]["test-item"])
end

-- Test achievement prototype categories
function TestPrototypeClassesExtended:testAchievementTypes()
    local achievement_types = {
        "build-entity-achievement",
        "change-surface-achievement",
        "combat-robot-count-achievement",
        "complete-objective-achievement",
        "construct-with-robots-achievement",
        "create-platform-achievement",
        "deconstruct-with-robots-achievement",
        "deliver-by-robots-achievement",
        "deplete-resource-achievement",
        "destroy-cliff-achievement",
        "dont-build-entity-achievement",
        "dont-craft-manually-achievement",
        "dont-kill-manually-achievement",
        "dont-research-before-researching-achievement",
        "dont-use-entity-in-energy-production-achievement",
        "equip-armor-achievement",
        "group-attack-achievement",
        "kill-achievement",
        "module-transfer-achievement",
        "place-equipment-achievement",
        "player-damaged-achievement",
        "produce-achievement",
        "produce-per-hour-achievement",
        "research-achievement",
        "research-with-science-pack-achievement",
        "shoot-achievement",
        "space-connection-distance-traveled-achievement",
        "train-path-achievement",
        "use-entity-in-energy-production-achievement",
        "use-item-achievement"
    }
    
    for _, achievement_type in ipairs(achievement_types) do
        local type_table = prototype_mock.data.raw[achievement_type]
        lu.assertNotNil(type_table, "Achievement type missing: " .. achievement_type)
    end
end

-- Test controller types
function TestPrototypeClassesExtended:testControllerTypes()
    local controller_types = {
        "editor-controller",
        "god-controller",
        "remote-controller",
        "spectator-controller"
    }
    
    for _, controller_type in ipairs(controller_types) do
        local type_table = prototype_mock.data.raw[controller_type]
        lu.assertNotNil(type_table, "Controller type missing: " .. controller_type)
    end
end

-- Test rail types
function TestPrototypeClassesExtended:testRailTypes()
    local rail_types = {
        "curved-rail-a",
        "curved-rail-b",
        "straight-rail",
        "elevated-curved-rail-a",
        "elevated-curved-rail-b",
        "elevated-half-diagonal-rail",
        "half-diagonal-rail",
        "legacy-curved-rail",
        "legacy-straight-rail",
        "rail-remnants"
    }
    
    for _, rail_type in ipairs(rail_types) do
        local type_table = prototype_mock.data.raw[rail_type]
        lu.assertNotNil(type_table, "Rail type missing: " .. rail_type)
    end
end

-- Test combinator types
function TestPrototypeClassesExtended:testCombinatorTypes()
    local combinator_types = {
        "arithmetic-combinator",
        "decider-combinator",
        "constant-combinator",
        "selector-combinator"
    }
    
    for _, combinator_type in ipairs(combinator_types) do
        local type_table = prototype_mock.data.raw[combinator_type]
        lu.assertNotNil(type_table, "Combinator type missing: " .. combinator_type)
    end
end

-- Test robot types
function TestPrototypeClassesExtended:testRobotTypes()
    local robot_types = {
        "combat-robot",
        "construction-robot",
        "logistic-robot",
        "capture-robot"
    }
    
    for _, robot_type in ipairs(robot_types) do
        local type_table = prototype_mock.data.raw[robot_type]
        lu.assertNotNil(type_table, "Robot type missing: " .. robot_type)
    end
end

-- Test utility prototype types
function TestPrototypeClassesExtended:testUtilityTypes()
    local utility_types = {
        "utility-constants",
        "utility-sounds",
        "utility-sprites",
        "gui-style",
        "font",
        "mouse-cursor",
        "custom-input"
    }
    
    for _, utility_type in ipairs(utility_types) do
        local type_table = prototype_mock.data.raw[utility_type]
        lu.assertNotNil(type_table, "Utility type missing: " .. utility_type)
    end
end

-- Test category prototype types
function TestPrototypeClassesExtended:testCategoryTypes()
    local category_types = {
        "ammo-category",
        "equipment-category",
        "fuel-category",
        "module-category",
        "recipe-category",
        "resource-category",
        "deliver-category",
        "impact-category"
    }
    
    for _, category_type in ipairs(category_types) do
        local type_table = prototype_mock.data.raw[category_type]
        lu.assertNotNil(type_table, "Category type missing: " .. category_type)
    end
end

-- Test effect/trigger types
function TestPrototypeClassesExtended:testEffectTriggerTypes()
    local effect_trigger_types = {
        "chain-active-trigger",
        "delayed-active-trigger",
        "custom-event",
        "trigger-target-type"
    }
    
    for _, type_name in ipairs(effect_trigger_types) do
        local type_table = prototype_mock.data.raw[type_name]
        lu.assertNotNil(type_table, "Effect/trigger type missing: " .. type_name)
    end
end

-- Test visual prototype types
function TestPrototypeClassesExtended:testVisualTypes()
    local visual_types = {
        "animation",
        "sprite",
        "speech-bubble",
        "highlight-box",
        "particle-source",
        "optimized-particle",
        "optimized-decorative"
    }
    
    for _, visual_type in ipairs(visual_types) do
        local type_table = prototype_mock.data.raw[visual_type]
        lu.assertNotNil(type_table, "Visual type missing: " .. visual_type)
    end
end

-- Test projectile types
function TestPrototypeClassesExtended:testProjectileTypes()
    local projectile_types = {
        "projectile",
        "arrow",
        "artillery-flare",
        "artillery-projectile",
        "beam",
        "stream"
    }
    
    for _, projectile_type in ipairs(projectile_types) do
        local type_table = prototype_mock.data.raw[projectile_type]
        lu.assertNotNil(type_table, "Projectile type missing: " .. projectile_type)
    end
end

-- Test smoke/particle types
function TestPrototypeClassesExtended:testSmokeParticleTypes()
    local smoke_types = {
        "trivial-smoke",
        "smoke-with-trigger"
    }
    
    for _, smoke_type in ipairs(smoke_types) do
        local type_table = prototype_mock.data.raw[smoke_type]
        lu.assertNotNil(type_table, "Smoke type missing: " .. smoke_type)
    end
end

-- Test segment types
function TestPrototypeClassesExtended:testSegmentTypes()
    local segment_types = {
        "segment",
        "segmented-unit"
    }
    
    for _, segment_type in ipairs(segment_types) do
        local type_table = prototype_mock.data.raw[segment_type]
        lu.assertNotNil(type_table, "Segment type missing: " .. segment_type)
    end
end

-- Test ghost types
function TestPrototypeClassesExtended:testGhostTypes()
    local ghost_types = {
        "entity-ghost",
        "equipment-ghost",
        "tile-ghost"
    }
    
    for _, ghost_type in ipairs(ghost_types) do
        local type_table = prototype_mock.data.raw[ghost_type]
        lu.assertNotNil(type_table, "Ghost type missing: " .. ghost_type)
    end
end

-- Test special entity types
function TestPrototypeClassesExtended:testSpecialEntityTypes()
    local special_types = {
        "item-request-proxy",
        "deconstructible-tile-proxy",
        "temporary-container",
        "player-port"
    }
    
    for _, special_type in ipairs(special_types) do
        local type_table = prototype_mock.data.raw[special_type]
        lu.assertNotNil(type_table, "Special entity type missing: " .. special_type)
    end
end

-- Test prototype count
function TestPrototypeClassesExtended:testPrototypeTypeCount()
    local count = 0
    for _ in pairs(prototype_mock.data.raw) do
        count = count + 1
    end
    
    -- Should have at least 200 prototype types (original + Space Age + Phase 4)
    lu.assertTrue(count >= 200, string.format("Should have at least 200 prototype types, found %d", count))
end

-- Test Space Age specific prototypes
function TestPrototypeClassesExtended:testSpaceAgeSpecificTypes()
    local space_age_specific = {
        "asteroid",
        "cargo-landing-pad",
        "space-connection",
        "thruster",
        "plant"
    }
    
    for _, type_name in ipairs(space_age_specific) do
        local type_table = prototype_mock.data.raw[type_name]
        lu.assertNotNil(type_table, "Space Age specific type missing: " .. type_name)
    end
end

-- Test tutorial/tips types
function TestPrototypeClassesExtended:testTutorialTypes()
    local tutorial_types = {
        "tutorial",
        "tips-and-tricks-item",
        "tips-and-tricks-item-category"
    }
    
    for _, tutorial_type in ipairs(tutorial_types) do
        local type_table = prototype_mock.data.raw[tutorial_type]
        lu.assertNotNil(type_table, "Tutorial type missing: " .. tutorial_type)
    end
end

os.exit(lu.LuaUnit.run())
