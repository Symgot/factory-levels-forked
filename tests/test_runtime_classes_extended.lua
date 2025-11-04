#!/usr/bin/env lua5.3
-- Test suite for Phase 4: Extended Runtime Classes (148 classes)
-- Reference: https://lua-api.factorio.com/latest/classes.html

local lu = require('luaunit')
local factorio_mock = require('factorio_mock')

TestRuntimeClassesExtended = {}

-- Test LuaBootstrap
function TestRuntimeClassesExtended:testLuaBootstrap()
    local bootstrap = factorio_mock.runtime_classes.LuaBootstrap
    lu.assertNotNil(bootstrap)
    lu.assertIsFunction(bootstrap.on_init)
    lu.assertIsFunction(bootstrap.on_load)
    lu.assertIsFunction(bootstrap.on_configuration_changed)
    lu.assertIsFunction(bootstrap.on_event)
    lu.assertIsFunction(bootstrap.on_nth_tick)
    lu.assertIsFunction(bootstrap.raise_event)
    lu.assertIsFunction(bootstrap.register_on_entity_destroyed)
    lu.assertIsFunction(bootstrap.generate_event_name)
end

-- Test LuaControl
function TestRuntimeClassesExtended:testLuaControl()
    local control = factorio_mock.runtime_classes.LuaControl
    lu.assertNotNil(control)
    lu.assertNotNil(control.position)
    lu.assertIsFunction(control.teleport)
    lu.assertIsFunction(control.can_reach_entity)
    lu.assertIsFunction(control.clear_items_inside)
end

-- Test LuaBurner
function TestRuntimeClassesExtended:testLuaBurner()
    local burner = factorio_mock.runtime_classes.LuaBurner
    lu.assertNotNil(burner)
    lu.assertNotNil(burner.fuel_categories)
    lu.assertNotNil(burner.inventory)
    lu.assertNotNil(burner.burnt_result_inventory)
    lu.assertEquals(burner.remaining_burning_fuel, 0)
    lu.assertEquals(burner.heat, 0)
    lu.assertEquals(burner.heat_capacity, 1000)
end

-- Test LuaFluidBox
function TestRuntimeClassesExtended:testLuaFluidBox()
    local fluidbox = factorio_mock.runtime_classes.LuaFluidBox
    lu.assertNotNil(fluidbox)
    lu.assertIsFunction(fluidbox.get_prototype)
    lu.assertIsFunction(fluidbox.get_capacity)
    lu.assertIsFunction(fluidbox.get_connections)
    lu.assertIsFunction(fluidbox.get_filter)
    lu.assertIsFunction(fluidbox.set_filter)
    lu.assertIsFunction(fluidbox.get_flow)
    lu.assertIsFunction(fluidbox.get_locked_fluid)
    lu.assertIsFunction(fluidbox.get_fluid_system_id)
    lu.assertIsFunction(fluidbox.get_fluid_system_contents)
end

-- Test LuaCircuitNetwork
function TestRuntimeClassesExtended:testLuaCircuitNetwork()
    local network = factorio_mock.runtime_classes.LuaCircuitNetwork
    lu.assertNotNil(network)
    lu.assertTrue(network.valid)
    lu.assertEquals(network.network_id, 0)
    lu.assertNotNil(network.signals)
end

-- Test LuaWireConnector
function TestRuntimeClassesExtended:testLuaWireConnector()
    local connector = factorio_mock.runtime_classes.LuaWireConnector
    lu.assertNotNil(connector)
    lu.assertTrue(connector.valid)
    lu.assertEquals(connector.wire_connector_id, 1)
    lu.assertNotNil(connector.connections)
end

-- Test LuaControlBehavior and derivatives
function TestRuntimeClassesExtended:testControlBehaviors()
    local behaviors = {
        "LuaControlBehavior",
        "LuaAccumulatorControlBehavior",
        "LuaArithmeticCombinatorControlBehavior",
        "LuaDeciderCombinatorControlBehavior",
        "LuaConstantCombinatorControlBehavior",
        "LuaGenericOnOffControlBehavior",
        "LuaInserterControlBehavior",
        "LuaLampControlBehavior",
        "LuaContainerControlBehavior",
        "LuaStorageTankControlBehavior",
        "LuaTransportBeltControlBehavior",
        "LuaMiningDrillControlBehavior",
        "LuaWallControlBehavior",
        "LuaProgrammableSpeakerControlBehavior",
        "LuaRoboportControlBehavior",
        "LuaTrainStopControlBehavior",
        "LuaRailSignalBaseControlBehavior",
        "LuaSplitterControlBehavior",
        "LuaAssemblingMachineControlBehavior",
        "LuaFurnaceControlBehavior",
        "LuaReactorControlBehavior",
        "LuaRadarControlBehavior",
        "LuaPumpControlBehavior",
        "LuaRocketSiloControlBehavior",
        "LuaLoaderControlBehavior",
        "LuaLogisticContainerControlBehavior",
        "LuaProxyContainerControlBehavior",
        "LuaTurretControlBehavior",
        "LuaArtilleryTurretControlBehavior",
        "LuaDisplayPanelControlBehavior",
        "LuaSelectorCombinatorControlBehavior",
        "LuaCombinatorControlBehavior",
        "LuaAgriculturalTowerControlBehavior",
        "LuaAsteroidCollectorControlBehavior",
        "LuaCargoLandingPadControlBehavior",
        "LuaSpacePlatformHubControlBehavior"
    }
    
    for _, behavior_name in ipairs(behaviors) do
        local behavior = factorio_mock.runtime_classes[behavior_name]
        lu.assertNotNil(behavior, "Missing runtime class: " .. behavior_name)
        lu.assertTrue(behavior.valid, behavior_name .. " should be valid")
    end
end

-- Test LuaLogisticNetwork
function TestRuntimeClassesExtended:testLuaLogisticNetwork()
    local network = factorio_mock.runtime_classes.LuaLogisticNetwork
    lu.assertNotNil(network)
    lu.assertTrue(network.valid)
    lu.assertEquals(network.available_logistic_robots, 0)
    lu.assertEquals(network.all_logistic_robots, 0)
    lu.assertEquals(network.available_construction_robots, 0)
    lu.assertEquals(network.all_construction_robots, 0)
end

-- Test LuaLogisticPoint
function TestRuntimeClassesExtended:testLuaLogisticPoint()
    local point = factorio_mock.runtime_classes.LuaLogisticPoint
    lu.assertNotNil(point)
    lu.assertTrue(point.valid)
    lu.assertEquals(point.mode, 1)
end

-- Test LuaLogisticCell
function TestRuntimeClassesExtended:testLuaLogisticCell()
    local cell = factorio_mock.runtime_classes.LuaLogisticCell
    lu.assertNotNil(cell)
    lu.assertTrue(cell.valid)
    lu.assertFalse(cell.mobile)
end

-- Test LuaLogisticSection
function TestRuntimeClassesExtended:testLuaLogisticSection()
    local section = factorio_mock.runtime_classes.LuaLogisticSection
    lu.assertNotNil(section)
    lu.assertTrue(section.valid)
    lu.assertEquals(section.index, 1)
end

-- Test LuaLogisticSections
function TestRuntimeClassesExtended:testLuaLogisticSections()
    local sections = factorio_mock.runtime_classes.LuaLogisticSections
    lu.assertNotNil(sections)
    lu.assertTrue(sections.valid)
    lu.assertNotNil(sections.sections)
end

-- Test LuaTrain
function TestRuntimeClassesExtended:testLuaTrain()
    local train = factorio_mock.runtime_classes.LuaTrain
    lu.assertNotNil(train)
    lu.assertTrue(train.valid)
    lu.assertEquals(train.id, 1)
    lu.assertEquals(train.state, 8)
    lu.assertEquals(train.speed, 0)
end

-- Test LuaRailPath
function TestRuntimeClassesExtended:testLuaRailPath()
    local path = factorio_mock.runtime_classes.LuaRailPath
    lu.assertNotNil(path)
    lu.assertTrue(path.valid)
    lu.assertEquals(path.size, 0)
    lu.assertEquals(path.current, 1)
end

-- Test LuaTrainManager
function TestRuntimeClassesExtended:testLuaTrainManager()
    local manager = factorio_mock.runtime_classes.LuaTrainManager
    lu.assertNotNil(manager)
    lu.assertIsFunction(manager.get_train_by_id)
end

-- Test LuaTransportLine
function TestRuntimeClassesExtended:testLuaTransportLine()
    local line = factorio_mock.runtime_classes.LuaTransportLine
    lu.assertNotNil(line)
    lu.assertTrue(line.valid)
    lu.assertIsFunction(line.get_contents)
end

-- Test LuaEquipmentGrid
function TestRuntimeClassesExtended:testLuaEquipmentGrid()
    local grid = factorio_mock.runtime_classes.LuaEquipmentGrid
    lu.assertNotNil(grid)
    lu.assertTrue(grid.valid)
    lu.assertEquals(grid.width, 10)
    lu.assertEquals(grid.height, 10)
end

-- Test LuaEquipment
function TestRuntimeClassesExtended:testLuaEquipment()
    local equipment = factorio_mock.runtime_classes.LuaEquipment
    lu.assertNotNil(equipment)
    lu.assertTrue(equipment.valid)
    lu.assertEquals(equipment.name, "")
    lu.assertEquals(equipment.energy, 0)
end

-- Test LuaRecipe
function TestRuntimeClassesExtended:testLuaRecipe()
    local recipe = factorio_mock.runtime_classes.LuaRecipe
    lu.assertNotNil(recipe)
    lu.assertTrue(recipe.valid)
    lu.assertTrue(recipe.enabled)
    lu.assertEquals(recipe.category, "crafting")
end

-- Test LuaTechnology
function TestRuntimeClassesExtended:testLuaTechnology()
    local tech = factorio_mock.runtime_classes.LuaTechnology
    lu.assertNotNil(tech)
    lu.assertTrue(tech.valid)
    lu.assertFalse(tech.researched)
    lu.assertEquals(tech.level, 1)
end

-- Test LuaCustomTable
function TestRuntimeClassesExtended:testLuaCustomTable()
    local custom_table = factorio_mock.runtime_classes.LuaCustomTable
    lu.assertNotNil(custom_table)
end

-- Test LuaLazyLoadedValue
function TestRuntimeClassesExtended:testLuaLazyLoadedValue()
    local lazy = factorio_mock.runtime_classes.LuaLazyLoadedValue
    lu.assertNotNil(lazy)
    lu.assertTrue(lazy.valid)
    lu.assertIsFunction(lazy.get)
end

-- Test LuaProfiler
function TestRuntimeClassesExtended:testLuaProfiler()
    local profiler = factorio_mock.runtime_classes.LuaProfiler
    lu.assertNotNil(profiler)
    lu.assertTrue(profiler.valid)
    lu.assertIsFunction(profiler.reset)
end

-- Test LuaFlowStatistics
function TestRuntimeClassesExtended:testLuaFlowStatistics()
    local stats = factorio_mock.runtime_classes.LuaFlowStatistics
    lu.assertNotNil(stats)
    lu.assertTrue(stats.valid)
    lu.assertIsFunction(stats.get_input_count)
end

-- Test LuaPermissionGroup
function TestRuntimeClassesExtended:testLuaPermissionGroup()
    local group = factorio_mock.runtime_classes.LuaPermissionGroup
    lu.assertNotNil(group)
    lu.assertTrue(group.valid)
    lu.assertEquals(group.group_id, 1)
end

-- Test LuaPermissionGroups
function TestRuntimeClassesExtended:testLuaPermissionGroups()
    local groups = factorio_mock.runtime_classes.LuaPermissionGroups
    lu.assertNotNil(groups)
    lu.assertIsFunction(groups.get_group)
end

-- Test LuaGui
function TestRuntimeClassesExtended:testLuaGui()
    local gui = factorio_mock.runtime_classes.LuaGui
    lu.assertNotNil(gui)
    lu.assertTrue(gui.valid)
    lu.assertNotNil(gui.top)
    lu.assertNotNil(gui.left)
    lu.assertNotNil(gui.center)
end

-- Test LuaGuiElement
function TestRuntimeClassesExtended:testLuaGuiElement()
    local element = factorio_mock.runtime_classes.LuaGuiElement
    lu.assertNotNil(element)
    lu.assertTrue(element.valid)
    lu.assertEquals(element.type, "button")
    lu.assertTrue(element.visible)
end

-- Test LuaStyle
function TestRuntimeClassesExtended:testLuaStyle()
    local style = factorio_mock.runtime_classes.LuaStyle
    lu.assertNotNil(style)
    lu.assertTrue(style.valid)
    lu.assertEquals(style.minimal_width, 0)
end

-- Test LuaGroup
function TestRuntimeClassesExtended:testLuaGroup()
    local group = factorio_mock.runtime_classes.LuaGroup
    lu.assertNotNil(group)
    lu.assertTrue(group.valid)
    lu.assertEquals(group.type, "item")
end

-- Test LuaCommandProcessor
function TestRuntimeClassesExtended:testLuaCommandProcessor()
    local processor = factorio_mock.runtime_classes.LuaCommandProcessor
    lu.assertNotNil(processor)
    lu.assertNotNil(processor.commands)
end

-- Test LuaCommandable
function TestRuntimeClassesExtended:testLuaCommandable()
    local commandable = factorio_mock.runtime_classes.LuaCommandable
    lu.assertNotNil(commandable)
    lu.assertTrue(commandable.valid)
end

-- Test LuaChunkIterator
function TestRuntimeClassesExtended:testLuaChunkIterator()
    local iterator = factorio_mock.runtime_classes.LuaChunkIterator
    lu.assertNotNil(iterator)
end

-- Test LuaRandomGenerator
function TestRuntimeClassesExtended:testLuaRandomGenerator()
    local gen = factorio_mock.runtime_classes.LuaRandomGenerator
    lu.assertNotNil(gen)
    lu.assertTrue(gen.valid)
end

-- Test LuaRendering
function TestRuntimeClassesExtended:testLuaRendering()
    local rendering = factorio_mock.runtime_classes.LuaRendering
    lu.assertNotNil(rendering)
end

-- Test LuaRenderObject
function TestRuntimeClassesExtended:testLuaRenderObject()
    local obj = factorio_mock.runtime_classes.LuaRenderObject
    lu.assertNotNil(obj)
    lu.assertTrue(obj.valid)
    lu.assertEquals(obj.id, 1)
    lu.assertEquals(obj.type, "line")
end

-- Test LuaRemote
function TestRuntimeClassesExtended:testLuaRemote()
    local remote = factorio_mock.runtime_classes.LuaRemote
    lu.assertNotNil(remote)
    lu.assertNotNil(remote.interfaces)
end

-- Test LuaSettings
function TestRuntimeClassesExtended:testLuaSettings()
    local settings = factorio_mock.runtime_classes.LuaSettings
    lu.assertNotNil(settings)
    lu.assertNotNil(settings.startup)
    lu.assertNotNil(settings.global)
    lu.assertNotNil(settings.player)
end

-- Test LuaRCON
function TestRuntimeClassesExtended:testLuaRCON()
    local rcon = factorio_mock.runtime_classes.LuaRCON
    lu.assertNotNil(rcon)
    lu.assertIsFunction(rcon.print)
end

-- Test LuaHelpers
function TestRuntimeClassesExtended:testLuaHelpers()
    local helpers = factorio_mock.runtime_classes.LuaHelpers
    lu.assertNotNil(helpers)
end

-- Test Space Age classes
function TestRuntimeClassesExtended:testLuaPlanet()
    local planet = factorio_mock.runtime_classes.LuaPlanet
    lu.assertNotNil(planet)
    lu.assertTrue(planet.valid)
    lu.assertEquals(planet.name, "nauvis")
end

function TestRuntimeClassesExtended:testLuaSpacePlatform()
    local platform = factorio_mock.runtime_classes.LuaSpacePlatform
    lu.assertNotNil(platform)
    lu.assertTrue(platform.valid)
end

function TestRuntimeClassesExtended:testLuaSpaceConnection()
    local connection = factorio_mock.runtime_classes.LuaSpaceConnection
    lu.assertNotNil(connection)
    lu.assertTrue(connection.valid)
end

function TestRuntimeClassesExtended:testLuaSpaceLocation()
    local location = factorio_mock.runtime_classes.LuaSpaceLocation
    lu.assertNotNil(location)
    lu.assertTrue(location.valid)
    lu.assertEquals(location.type, "planet")
end

function TestRuntimeClassesExtended:testLuaCargoHatch()
    local hatch = factorio_mock.runtime_classes.LuaCargoHatch
    lu.assertNotNil(hatch)
    lu.assertTrue(hatch.valid)
end

function TestRuntimeClassesExtended:testLuaTerritory()
    local territory = factorio_mock.runtime_classes.LuaTerritory
    lu.assertNotNil(territory)
    lu.assertTrue(territory.valid)
end

function TestRuntimeClassesExtended:testLuaSegment()
    local segment = factorio_mock.runtime_classes.LuaSegment
    lu.assertNotNil(segment)
    lu.assertTrue(segment.valid)
    lu.assertEquals(segment.segment_index, 0)
end

function TestRuntimeClassesExtended:testLuaSegmentedUnit()
    local unit = factorio_mock.runtime_classes.LuaSegmentedUnit
    lu.assertNotNil(unit)
    lu.assertTrue(unit.valid)
end

-- Test Prototype classes
function TestRuntimeClassesExtended:testPrototypeClasses()
    local prototype_classes = {
        "LuaAchievementPrototype",
        "LuaActiveTriggerPrototype",
        "LuaAirbornePollutantPrototype",
        "LuaAmmoCategoryPrototype",
        "LuaAsteroidChunkPrototype",
        "LuaAutoplaceControlPrototype",
        "LuaBurnerPrototype",
        "LuaBurnerUsagePrototype",
        "LuaCollisionLayerPrototype",
        "LuaCustomEventPrototype",
        "LuaCustomInputPrototype",
        "LuaDamagePrototype",
        "LuaDecorativePrototype",
        "LuaElectricEnergySourcePrototype",
        "LuaEquipmentCategoryPrototype",
        "LuaEquipmentGridPrototype",
        "LuaEquipmentPrototype",
        "LuaFluidBoxPrototype",
        "LuaFluidEnergySourcePrototype",
        "LuaFluidPrototype",
        "LuaFontPrototype",
        "LuaFuelCategoryPrototype",
        "LuaHeatBufferPrototype",
        "LuaHeatEnergySourcePrototype",
        "LuaItemPrototype",
        "LuaItemCommon",
        "LuaModSettingPrototype",
        "LuaModuleCategoryPrototype",
        "LuaNamedNoiseExpression",
        "LuaNamedNoiseFunction",
        "LuaParticlePrototype",
        "LuaProcessionLayerInheritanceGroupPrototype",
        "LuaProcessionPrototype",
        "LuaPrototypeBase",
        "LuaPrototypes",
        "LuaQualityPrototype",
        "LuaRecipeCategoryPrototype",
        "LuaRecipePrototype",
        "LuaRecord",
        "LuaResourceCategoryPrototype",
        "LuaShortcutPrototype",
        "LuaSimulation",
        "LuaSpaceConnectionPrototype",
        "LuaSpaceLocationPrototype",
        "LuaSurfacePropertyPrototype",
        "LuaSurfacePrototype",
        "LuaTechnologyPrototype",
        "LuaTilePrototype",
        "LuaTrivialSmokePrototype",
        "LuaVirtualSignalPrototype",
        "LuaVoidEnergySourcePrototype"
    }
    
    for _, class_name in ipairs(prototype_classes) do
        local class = factorio_mock.runtime_classes[class_name]
        lu.assertNotNil(class, "Missing prototype class: " .. class_name)
        lu.assertTrue(class.valid, class_name .. " should be valid")
    end
end

-- Test additional missing classes
function TestRuntimeClassesExtended:testAdditionalClasses()
    local additional_classes = {
        "LuaRailEnd",
        "LuaSchedule",
        "LuaAISettings",
        "LuaModData",
        "LuaItem",
        "LuaTile",
        "LuaCustomChartTag",
        "LuaUndoRedoStack",
        "LuaInventory",
        "LuaItemStack"
    }
    
    for _, class_name in ipairs(additional_classes) do
        local class = factorio_mock.runtime_classes[class_name]
        lu.assertNotNil(class, "Missing additional class: " .. class_name)
        lu.assertTrue(class.valid, class_name .. " should be valid")
    end
end

os.exit(lu.LuaUnit.run())
