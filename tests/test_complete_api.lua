#!/usr/bin/env lua5.3
-- Comprehensive API Test Suite - Validates complete Factorio API mock
-- Tests Space Age features, Quality system, complete entity API, and events

local lu = require('luaunit')
local factorio_mock = require('factorio_mock')
local prototype_mock = require('factorio_prototype_mock')

-- Initialize both mocks
factorio_mock.init()
prototype_mock.init()

-- Test: Complete Entity API
TestCompleteEntityAPI = {}

function TestCompleteEntityAPI:setUp()
    factorio_mock.reset()
end

function TestCompleteEntityAPI:testAllBasicEntityProperties()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    -- Basic properties
    lu.assertNotNil(entity.name)
    lu.assertNotNil(entity.type)
    lu.assertNotNil(entity.valid)
    lu.assertNotNil(entity.unit_number)
    lu.assertNotNil(entity.position)
    lu.assertNotNil(entity.direction)
    lu.assertNotNil(entity.force)
end

function TestCompleteEntityAPI:testSpaceAgeProperties()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    -- Space Age properties
    lu.assertNotNil(entity.quality)
    lu.assertNotNil(entity.quality_prototype)
    lu.assertEquals(entity.spoil_percent, 0)
    lu.assertEquals(entity.frozen, false)
    lu.assertTrue(entity.space_location == false or entity.space_location == nil)
    lu.assertTrue(entity.platform_id == false or entity.platform_id == nil)
end

function TestCompleteEntityAPI:testEffectsSystem()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    -- Effects structure
    lu.assertNotNil(entity.effects)
    lu.assertNotNil(entity.effects.productivity)
    lu.assertNotNil(entity.effects.speed)
    lu.assertNotNil(entity.effects.consumption)
    lu.assertNotNil(entity.effects.pollution)
    lu.assertNotNil(entity.effects.quality)
    
    -- Effects have bonus and base
    lu.assertNotNil(entity.effects.productivity.bonus)
    lu.assertNotNil(entity.effects.productivity.base)
end

function TestCompleteEntityAPI:testInventoryMethods()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    -- Inventory methods exist
    lu.assertNotNil(entity.get_inventory)
    lu.assertNotNil(entity.get_output_inventory)
    lu.assertNotNil(entity.get_module_inventory)
    lu.assertNotNil(entity.get_fuel_inventory)
    
    -- Can get inventories
    local output_inv = entity.get_output_inventory()
    lu.assertNotNil(output_inv)
    lu.assertNotNil(output_inv.get_contents)
end

function TestCompleteEntityAPI:testEntityMethods()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    -- Destruction methods
    lu.assertNotNil(entity.destroy)
    lu.assertNotNil(entity.die)
    lu.assertNotNil(entity.damage)
    lu.assertNotNil(entity.mine)
    
    -- Recipe methods
    lu.assertNotNil(entity.set_recipe)
    lu.assertNotNil(entity.get_recipe)
    
    -- Rotation methods
    lu.assertNotNil(entity.rotate)
    lu.assertNotNil(entity.supports_direction)
    
    -- Order methods
    lu.assertNotNil(entity.order_deconstruction)
    lu.assertNotNil(entity.cancel_deconstruction)
    lu.assertNotNil(entity.order_upgrade)
    lu.assertNotNil(entity.cancel_upgrade)
end

function TestCompleteEntityAPI:testQualityMethods()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    lu.assertNotNil(entity.get_quality)
    lu.assertNotNil(entity.set_quality)
    
    -- Test quality setting
    local quality = entity.get_quality()
    lu.assertEquals(quality.name, "normal")
    
    entity.set_quality("legendary")
    lu.assertEquals(entity.quality, "legendary")
end

function TestCompleteEntityAPI:testSpaceAgeMethods()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    -- Freeze/unfreeze
    lu.assertNotNil(entity.freeze)
    lu.assertNotNil(entity.unfreeze)
    
    entity.freeze()
    lu.assertTrue(entity.frozen)
    
    entity.unfreeze()
    lu.assertFalse(entity.frozen)
end

-- Test: Quality System
TestQualitySystem = {}

function TestQualitySystem:testQualityPrototypesExist()
    lu.assertNotNil(factorio_mock.quality_prototypes)
    lu.assertNotNil(factorio_mock.quality_prototypes.normal)
    lu.assertNotNil(factorio_mock.quality_prototypes.uncommon)
    lu.assertNotNil(factorio_mock.quality_prototypes.rare)
    lu.assertNotNil(factorio_mock.quality_prototypes.epic)
    lu.assertNotNil(factorio_mock.quality_prototypes.legendary)
end

function TestQualitySystem:testQualityLevels()
    lu.assertEquals(factorio_mock.quality_prototypes.normal.level, 0)
    lu.assertEquals(factorio_mock.quality_prototypes.uncommon.level, 1)
    lu.assertEquals(factorio_mock.quality_prototypes.rare.level, 2)
    lu.assertEquals(factorio_mock.quality_prototypes.epic.level, 3)
    lu.assertEquals(factorio_mock.quality_prototypes.legendary.level, 4)
end

function TestQualitySystem:testQualityChain()
    lu.assertEquals(factorio_mock.quality_prototypes.normal.next, "uncommon")
    lu.assertEquals(factorio_mock.quality_prototypes.uncommon.next, "rare")
    lu.assertEquals(factorio_mock.quality_prototypes.rare.next, "epic")
    lu.assertEquals(factorio_mock.quality_prototypes.epic.next, "legendary")
    lu.assertNil(factorio_mock.quality_prototypes.legendary.next)
end

-- Test: Space Age Features
TestSpaceAge = {}

function TestSpaceAge:testSpaceLocationsList()
    lu.assertNotNil(factorio_mock.space_locations)
    lu.assertNotNil(factorio_mock.space_locations.nauvis)
    lu.assertNotNil(factorio_mock.space_locations.vulcanus)
    lu.assertNotNil(factorio_mock.space_locations.gleba)
    lu.assertNotNil(factorio_mock.space_locations.fulgora)
    lu.assertNotNil(factorio_mock.space_locations.aquilo)
end

function TestSpaceAge:testSpacePlatformCreation()
    local platform = factorio_mock.create_space_platform("test-platform")
    
    lu.assertNotNil(platform)
    lu.assertEquals(platform.name, "test-platform")
    lu.assertNotNil(platform.surface)
    lu.assertTrue(platform.valid)
    lu.assertNotNil(platform.get_surface)
end

function TestSpaceAge:testSpacePlatformSurface()
    local platform = factorio_mock.create_space_platform("test-platform-2")
    local surface = platform.get_surface()
    
    lu.assertNotNil(surface)
    lu.assertNotNil(surface.platform)
    lu.assertEquals(surface.platform.name, "test-platform-2")
end

function TestSpaceAge:testAsteroidChunkCreation()
    local asteroid = factorio_mock.create_asteroid_chunk("metallic")
    
    lu.assertNotNil(asteroid)
    lu.assertEquals(asteroid.chunk_type, "metallic")
    lu.assertTrue(asteroid.valid)
    lu.assertEquals(asteroid.type, "asteroid-chunk")
end

-- Test: Complete Event System
TestCompleteEventSystem = {}

function TestCompleteEventSystem:testBasicEvents()
    lu.assertNotNil(defines.events.on_player_mined_entity)
    lu.assertNotNil(defines.events.on_robot_mined_entity)
    lu.assertNotNil(defines.events.on_robot_built_entity)
    lu.assertNotNil(defines.events.on_built_entity)
    lu.assertNotNil(defines.events.on_runtime_mod_setting_changed)
end

function TestCompleteEventSystem:testEntityLifecycleEvents()
    lu.assertNotNil(defines.events.on_entity_died)
    lu.assertNotNil(defines.events.on_entity_damaged)
    lu.assertNotNil(defines.events.on_entity_destroyed)
    lu.assertNotNil(defines.events.on_entity_spawned)
    lu.assertNotNil(defines.events.on_entity_cloned)
end

function TestCompleteEventSystem:testSpaceAgeEvents()
    lu.assertNotNil(defines.events.on_space_platform_built)
    lu.assertNotNil(defines.events.on_space_platform_destroyed)
    lu.assertNotNil(defines.events.on_space_platform_changed_state)
    lu.assertNotNil(defines.events.on_asteroid_chunk_collision)
    lu.assertNotNil(defines.events.on_elevated_rail_built)
    lu.assertNotNil(defines.events.on_quality_item_created)
    lu.assertNotNil(defines.events.on_entity_frozen)
    lu.assertNotNil(defines.events.on_entity_spoiled)
end

function TestCompleteEventSystem:testCraftingEvents()
    lu.assertNotNil(defines.events.on_player_crafted_item)
    lu.assertNotNil(defines.events.on_robot_crafted_item)
    lu.assertNotNil(defines.events.on_pre_player_crafted_item)
end

function TestCompleteEventSystem:testPlayerEvents()
    lu.assertNotNil(defines.events.on_player_created)
    lu.assertNotNil(defines.events.on_player_joined_game)
    lu.assertNotNil(defines.events.on_player_left_game)
    lu.assertNotNil(defines.events.on_player_died)
    lu.assertNotNil(defines.events.on_player_respawned)
end

function TestCompleteEventSystem:testGUIEvents()
    lu.assertNotNil(defines.events.on_gui_click)
    lu.assertNotNil(defines.events.on_gui_opened)
    lu.assertNotNil(defines.events.on_gui_closed)
    lu.assertNotNil(defines.events.on_gui_text_changed)
end

function TestCompleteEventSystem:testEventIDsAreUnique()
    local seen = {}
    for event_name, event_id in pairs(defines.events) do
        lu.assertIsNumber(event_id, "Event " .. event_name .. " must have numeric ID")
        lu.assertNil(seen[event_id], "Event ID " .. event_id .. " is duplicated")
        seen[event_id] = event_name
    end
end

-- Test: Inventory System
TestInventorySystem = {}

function TestInventorySystem:testInventoryCreation()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    local inv = entity.get_output_inventory()
    
    lu.assertNotNil(inv)
    lu.assertTrue(inv.is_empty())
end

function TestInventorySystem:testInventoryInsert()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    local inv = entity.get_output_inventory()
    
    local inserted = inv.insert("iron-plate")
    lu.assertEquals(inserted, 1)
    lu.assertFalse(inv.is_empty())
end

function TestInventorySystem:testInventoryGetContents()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    local inv = entity.get_output_inventory()
    
    inv.insert({ name = "iron-plate", count = 10 })
    local contents = inv.get_contents()
    
    lu.assertEquals(contents["iron-plate"], 10)
end

function TestInventorySystem:testInventoryRemove()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    local inv = entity.get_output_inventory()
    
    inv.insert({ name = "iron-plate", count = 10 })
    local removed = inv.remove({ name = "iron-plate", count = 5 })
    
    lu.assertEquals(removed, 5)
    lu.assertEquals(inv.get_item_count("iron-plate"), 5)
end

function TestInventorySystem:testInventoryClear()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    local inv = entity.get_output_inventory()
    
    inv.insert({ name = "iron-plate", count = 10 })
    lu.assertFalse(inv.is_empty())
    
    inv.clear()
    lu.assertTrue(inv.is_empty())
end

-- Test: Surface API
TestSurfaceAPI = {}

function TestSurfaceAPI:setUp()
    -- Reset game state completely for each test
    factorio_mock.reset()
end

function TestSurfaceAPI:testSurfaceExists()
    local surface = game.surfaces[1]
    lu.assertNotNil(surface)
    lu.assertEquals(surface.name, "nauvis")
end

function TestSurfaceAPI:testEntityCreationOnSurface()
    local surface = game.surfaces[1]
    local entity = surface.create_entity({
        name = "assembling-machine-1",
        position = { x = 10, y = 20 },
        force = "player"
    })
    
    lu.assertNotNil(entity)
    lu.assertEquals(entity.position.x, 10)
    lu.assertEquals(entity.position.y, 20)
    lu.assertEquals(entity.surface.name, "nauvis")
end

function TestSurfaceAPI:testFindEntitiesFiltered()
    local surface = game.surfaces[1]
    
    surface.create_entity({ name = "assembling-machine-1", position = { x = 0, y = 0 } })
    surface.create_entity({ name = "assembling-machine-2", position = { x = 5, y = 5 } })
    surface.create_entity({ name = "stone-furnace", position = { x = 10, y = 10 } })
    
    local assemblers = surface.find_entities_filtered({ type = "assembling-machine" })
    lu.assertEquals(#assemblers, 2)
    
    local furnaces = surface.find_entities_filtered({ type = "furnace" })
    lu.assertEquals(#furnaces, 1)
end

function TestSurfaceAPI:testFindEntity()
    local surface = game.surfaces[1]
    
    surface.create_entity({ name = "assembling-machine-1", position = { x = 0, y = 0 } })
    
    local found = surface.find_entity("assembling-machine-1", { x = 0, y = 0 })
    lu.assertNotNil(found)
end

-- Test: Prototype Stage
TestPrototypeStage = {}

function TestPrototypeStage:testDataExists()
    lu.assertNotNil(data)
    lu.assertNotNil(data.raw)
end

function TestPrototypeStage:testDataExtend()
    local test_prototype = {
        type = "assembling-machine",
        name = "test-machine-xyz",
        crafting_speed = 1.5
    }
    
    data:extend({ test_prototype })
    
    lu.assertNotNil(data.raw["assembling-machine"]["test-machine-xyz"])
    lu.assertEquals(data.raw["assembling-machine"]["test-machine-xyz"].crafting_speed, 1.5)
end

function TestPrototypeStage:testBasePrototypesExist()
    lu.assertNotNil(data.raw["assembling-machine"]["assembling-machine-1"])
    lu.assertNotNil(data.raw["assembling-machine"]["assembling-machine-2"])
    lu.assertNotNil(data.raw["assembling-machine"]["assembling-machine-3"])
    lu.assertNotNil(data.raw["furnace"]["stone-furnace"])
    lu.assertNotNil(data.raw["furnace"]["steel-furnace"])
    lu.assertNotNil(data.raw["furnace"]["electric-furnace"])
end

function TestPrototypeStage:testSpaceAgePrototypes()
    if prototype_mock.space_age_enabled then
        lu.assertNotNil(data.raw["recycler"]["recycler"])
        lu.assertNotNil(data.raw["assembling-machine"]["electromagnetic-plant"])
        lu.assertNotNil(data.raw["assembling-machine"]["biochamber"])
    end
end

-- Test: Utility Functions
TestUtilityFunctions = {}

function TestUtilityFunctions:testLogFunction()
    lu.assertNotNil(log)
    lu.assertNotNil(_G.log)
    
    -- Should not error
    log("Test message")
end

function TestUtilityFunctions:testTableDeepCopy()
    local original = {
        a = 1,
        b = { c = 2, d = { e = 3 } }
    }
    
    local copy = table.deepcopy(original)
    
    lu.assertEquals(copy.a, 1)
    lu.assertEquals(copy.b.c, 2)
    lu.assertEquals(copy.b.d.e, 3)
    
    -- Ensure it's a deep copy
    copy.b.d.e = 999
    lu.assertEquals(original.b.d.e, 3)
end

function TestUtilityFunctions:testUtilDistance()
    local pos1 = { x = 0, y = 0 }
    local pos2 = { x = 3, y = 4 }
    
    local dist = factorio_mock.util.distance(pos1, pos2)
    lu.assertEquals(dist, 5)
end

-- Test: Defines completeness
TestDefinesCompleteness = {}

function TestDefinesCompleteness:testInventoryDefines()
    lu.assertNotNil(defines.inventory)
    lu.assertNotNil(defines.inventory.fuel)
    lu.assertNotNil(defines.inventory.furnace_source)
    lu.assertNotNil(defines.inventory.furnace_result)
    lu.assertNotNil(defines.inventory.assembling_machine_input)
    lu.assertNotNil(defines.inventory.assembling_machine_output)
    lu.assertNotNil(defines.inventory.assembling_machine_modules)
end

function TestDefinesCompleteness:testDirectionDefines()
    lu.assertNotNil(defines.direction)
    lu.assertEquals(defines.direction.north, 0)
    lu.assertEquals(defines.direction.east, 2)
    lu.assertEquals(defines.direction.south, 4)
    lu.assertEquals(defines.direction.west, 6)
end

-- Test: Phase 2 - Cargo Pods System (Space Age)
TestCargoPods = {}

function TestCargoPods:setUp()
    factorio_mock.reset()
end

function TestCargoPods:testCargoPodEvents()
    lu.assertNotNil(defines.events.on_cargo_pod_delivered)
    lu.assertNotNil(defines.events.on_cargo_pod_departed)
    lu.assertEquals(defines.events.on_cargo_pod_delivered, 120)
    lu.assertEquals(defines.events.on_cargo_pod_departed, 121)
end

function TestCargoPods:testCargoPodEntityCreation()
    local surface = game.surfaces[1]
    local cargo_pod = surface.create_entity({
        name = "cargo-pod",
        position = {x = 0, y = 0}
    })
    
    lu.assertNotNil(cargo_pod)
    lu.assertTrue(cargo_pod.valid)
    lu.assertEquals(cargo_pod.name, "cargo-pod")
end

function TestCargoPods:testCargoPodProperty()
    local entity = factorio_mock.create_entity("cargo-pod", "cargo-pod")
    
    -- Property exists (can be nil or false)
    lu.assertTrue(entity.cargo_pod_entity == false or entity.cargo_pod_entity == nil)
end

-- Test: Phase 2 - Priority Targets & Military System (2.0.64+)
TestPriorityTargets = {}

function TestPriorityTargets:setUp()
    factorio_mock.reset()
end

function TestPriorityTargets:testPriorityTargetsProperty()
    local entity = factorio_mock.create_entity("gun-turret", "turret")
    
    -- Property exists (initially false or nil)
    lu.assertTrue(entity.priority_targets == false or entity.priority_targets == nil)
    
    -- Set priority targets
    local target_entity = factorio_mock.create_entity("biter-spawner", "unit-spawner")
    entity.priority_targets = {{entity = target_entity, priority = 1}}
    
    lu.assertNotNil(entity.priority_targets)
    lu.assertEquals(#entity.priority_targets, 1)
end

function TestPriorityTargets:testPanelTextProperty()
    local entity = factorio_mock.create_entity("display-panel", "simple-entity")
    
    lu.assertNotNil(entity.panel_text)
    lu.assertEquals(entity.panel_text, "")
    
    -- Set panel text
    entity.panel_text = "Factory Level: 5"
    lu.assertEquals(entity.panel_text, "Factory Level: 5")
end

function TestPriorityTargets:testPanelTextEmpty()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    lu.assertEquals(entity.panel_text, "")
end

-- Test: Phase 2 - Agricultural Tower API (Space Age)
TestAgriculturalTower = {}

function TestAgriculturalTower:setUp()
    factorio_mock.reset()
end

function TestAgriculturalTower:testAgriculturalTowerPrototype()
    lu.assertNotNil(data.raw["agricultural-tower"])
end

function TestAgriculturalTower:testRegisterTreeMethod()
    local ag_tower = factorio_mock.create_entity("agricultural-tower", "agricultural-tower")
    local tree = factorio_mock.create_entity("tree-01", "tree")
    
    lu.assertNotNil(ag_tower.register_tree_to_agricultural_tower)
    
    local result = ag_tower.register_tree_to_agricultural_tower(tree)
    lu.assertTrue(result)
end

function TestAgriculturalTower:testRegisterTreeOnNonTower()
    local assembler = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    local tree = factorio_mock.create_entity("tree-01", "tree")
    
    local result = assembler.register_tree_to_agricultural_tower(tree)
    lu.assertFalse(result)
end

-- Test: Phase 2 - Quality Multiplier System
TestQualityMultiplier = {}

function TestQualityMultiplier:setUp()
    factorio_mock.reset()
end

function TestQualityMultiplier:testGetQualityMultiplier()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    lu.assertNotNil(entity.get_quality_multiplier)
    
    local multiplier = entity.get_quality_multiplier()
    lu.assertEquals(multiplier, 1.0)
end

function TestQualityMultiplier:testQualityMultiplierUncommon()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    entity.set_quality("uncommon")
    
    local multiplier = entity.get_quality_multiplier()
    lu.assertEquals(multiplier, 1.3)
end

function TestQualityMultiplier:testQualityMultiplierLegendary()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    entity.set_quality("legendary")
    
    local multiplier = entity.get_quality_multiplier()
    lu.assertEquals(multiplier, 2.2)
end

function TestQualityMultiplier:testRecipeQualityProperty()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    lu.assertNotNil(entity.recipe_quality)
    lu.assertEquals(entity.recipe_quality, "normal")
    
    entity.set_recipe("iron-plate", "rare")
    lu.assertEquals(entity.recipe_quality, "rare")
end

-- Test: Phase 2 - Logistic Sections API (2.0+)
TestLogisticSections = {}

function TestLogisticSections:setUp()
    factorio_mock.reset()
end

function TestLogisticSections:testGetLogisticSections()
    local entity = factorio_mock.create_entity("logistic-chest-storage", "logistic-container")
    
    lu.assertNotNil(entity.get_logistic_sections)
    
    local sections = entity.get_logistic_sections()
    lu.assertNotNil(sections)
    lu.assertEquals(type(sections), "table")
end

function TestLogisticSections:testSetLogisticSection()
    local entity = factorio_mock.create_entity("logistic-chest-requester", "logistic-container")
    
    lu.assertNotNil(entity.set_logistic_section)
    
    local result = entity.set_logistic_section(1, {
        filters = {{name = "iron-plate", count = 100}}
    })
    lu.assertTrue(result)
end

function TestLogisticSections:testLogisticSectionsOnNonLogisticEntity()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    local sections = entity.get_logistic_sections()
    lu.assertNotNil(sections)
    lu.assertEquals(#sections, 0)
end

-- Test: Phase 2 - Space Age Entity Types
TestSpaceAgeEntityTypes = {}

function TestSpaceAgeEntityTypes:setUp()
    factorio_mock.reset()
    prototype_mock.init()
end

function TestSpaceAgeEntityTypes:testFusionGenerator()
    lu.assertNotNil(data.raw["fusion-generator"])
end

function TestSpaceAgeEntityTypes:testFusionReactor()
    lu.assertNotNil(data.raw["fusion-reactor"])
end

function TestSpaceAgeEntityTypes:testLightningAttractor()
    lu.assertNotNil(data.raw["lightning-attractor"])
end

function TestSpaceAgeEntityTypes:testHeatingTower()
    lu.assertNotNil(data.raw["heating-tower"])
end

function TestSpaceAgeEntityTypes:testCaptiveBiterSpawner()
    lu.assertNotNil(data.raw["captive-biter-spawner"])
end

function TestSpaceAgeEntityTypes:testCargoPodPrototype()
    lu.assertNotNil(data.raw["cargo-pod"])
end

-- Test: Phase 2 - Entity Creation with New Types
TestNewEntityCreation = {}

function TestNewEntityCreation:setUp()
    factorio_mock.reset()
end

function TestNewEntityCreation:testCreateFusionGenerator()
    local surface = game.surfaces[1]
    local entity = surface.create_entity({
        name = "fusion-generator",
        position = {x = 5, y = 5}
    })
    
    lu.assertNotNil(entity)
    lu.assertTrue(entity.valid)
    lu.assertEquals(entity.name, "fusion-generator")
end

function TestNewEntityCreation:testCreateAgriculturalTower()
    local surface = game.surfaces[1]
    local entity = surface.create_entity({
        name = "agricultural-tower",
        position = {x = 10, y = 10}
    })
    
    lu.assertNotNil(entity)
    lu.assertTrue(entity.valid)
    lu.assertEquals(entity.name, "agricultural-tower")
end

function TestNewEntityCreation:testCreateHeatingTower()
    local surface = game.surfaces[1]
    local entity = surface.create_entity({
        name = "heating-tower",
        position = {x = 15, y = 15}
    })
    
    lu.assertNotNil(entity)
    lu.assertTrue(entity.valid)
    lu.assertEquals(entity.name, "heating-tower")
end

-- Test: Phase 2 - Complete Event Coverage
TestCompleteEventCoverage = {}

function TestCompleteEventCoverage:testAllSpaceAgeEvents()
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
        lu.assertNotNil(defines.events[event_name], "Missing event: " .. event_name)
    end
end

function TestCompleteEventCoverage:testEventIDsUnique()
    local seen_ids = {}
    for event_name, event_id in pairs(defines.events) do
        lu.assertNil(seen_ids[event_id], "Duplicate event ID: " .. event_id .. " for " .. event_name)
        seen_ids[event_id] = event_name
    end
end

-- Test: Phase 2 - Effects System Quality Integration
TestEffectsQualityIntegration = {}

function TestEffectsQualityIntegration:setUp()
    factorio_mock.reset()
end

function TestEffectsQualityIntegration:testQualityEffectBonus()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    lu.assertNotNil(entity.effects.quality)
    lu.assertEquals(entity.effects.quality.bonus, 0)
    lu.assertEquals(entity.effects.quality.base, 0)
end

function TestEffectsQualityIntegration:testQualityEffectModification()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    
    entity.effects.quality.bonus = 0.5
    lu.assertEquals(entity.effects.quality.bonus, 0.5)
end

function TestEffectsQualityIntegration:testQualityEffectWithMultiplier()
    local entity = factorio_mock.create_entity("assembling-machine-1", "assembling-machine")
    entity.set_quality("epic")
    
    local multiplier = entity.get_quality_multiplier()
    local effects = entity.get_module_effects()
    
    lu.assertEquals(multiplier, 1.9)
    lu.assertNotNil(effects.quality)
end

-- Run all tests
os.exit(lu.LuaUnit.run())
