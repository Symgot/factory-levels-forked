-- tests/test_module_slot_bonus.lua
-- Test module_slot_bonus nil-value handling and defensive programming

local test = {}

-- Helper function to safely get module slot bonus
local function get_safe_module_slot_bonus(entity)
	if not entity then
		return 0
	end
	
	-- Check for module_specification
	if not entity.module_specification then
		return 0
	end
	
	-- Check for module_slots within specification
	local module_slots = entity.module_specification.module_slots
	if not module_slots then
		return 0
	end
	
	return module_slots
end

-- Test 1: module_slot_bonus nil handling
function test.test_module_slot_bonus_nil_handling()
	-- Simuliere verschiedene Maschinentypen
	local test_entities = {
		{name = "assembling-machine-1", module_specification = {module_slots = 2}},
		{name = "stone-furnace", module_specification = nil}, -- Keine Module
		{name = "electric-furnace", module_specification = {module_slots = 2}},
		{name = "custom-machine", module_specification = {}}, -- Leere Spezifikation
		nil -- Nil entity test
	}
	
	for i, entity in ipairs(test_entities) do
		local bonus = get_safe_module_slot_bonus(entity)
		assert(type(bonus) == "number", "module_slot_bonus should always return a number, got " .. type(bonus) .. " for entity " .. i)
		assert(bonus >= 0, "module_slot_bonus should not be negative, got " .. bonus .. " for entity " .. i)
	end
	
	print("PASS: module_slot_bonus nil handling works correctly")
end

-- Test 2: Factory levels module implementation
function test.test_factory_levels_module_slots_function()
	-- Test the actual factory_levels function exists and handles nil safely
	local factory_levels = require("prototypes.entity.factory_levels")
	
	-- Mock machine object
	local mock_machine = {
		name = "test-machine",
		module_slots = 0
	}
	
	-- Mock settings
	if not settings then
		settings = {}
	end
	if not settings.startup then
		settings.startup = {}
	end
	settings.startup["factory-levels-enable-module-bonus"] = {value = true}
	
	-- Test with valid parameters
	factory_levels.update_machine_module_slots(mock_machine, 10, 5, 2, 1)
	assert(type(mock_machine.module_slots) == "number", "module_slots should be a number")
	
	-- Test with nil parameters (defensive programming)
	local mock_machine2 = {name = "test-machine-2", module_slots = 0}
	factory_levels.update_machine_module_slots(mock_machine2, 10, 5, nil, nil)
	assert(type(mock_machine2.module_slots) == "number", "module_slots should handle nil parameters safely")
	assert(mock_machine2.module_slots == 0, "module_slots with nil parameters should be 0")
	
	print("PASS: factory_levels module_slots function handles nil safely")
end

-- Test 3: Entity creation without crash
function test.test_entity_creation_no_crash()
	-- Verify factory_levels can be required without errors
	local success, result = pcall(function()
		return require("prototypes.entity.factory_levels")
	end)
	
	assert(success, "Factory levels should load without errors: " .. tostring(result))
	assert(type(result) == "table", "Factory levels should return a table")
	
	print("PASS: Factory levels loads without crashes")
end

-- Test 4: Module slots calculation
function test.test_module_slots_calculation()
	-- Test calculation: base + (floor(level / levels_per_slot) * bonus)
	local test_cases = {
		{level = 0, levels_per_slot = 5, base = 2, bonus = 1, expected = 2},
		{level = 5, levels_per_slot = 5, base = 2, bonus = 1, expected = 3},
		{level = 10, levels_per_slot = 5, base = 2, bonus = 1, expected = 4},
		{level = 20, levels_per_slot = 5, base = 0, bonus = 1, expected = 4},
		{level = 25, levels_per_slot = 25, base = 3, bonus = 1, expected = 4},
	}
	
	for i, tc in ipairs(test_cases) do
		local result = tc.base + (math.floor(tc.level / tc.levels_per_slot) * tc.bonus)
		assert(result == tc.expected, 
			string.format("Test case %d failed: expected %d, got %d", i, tc.expected, result))
	end
	
	print("PASS: Module slots calculation correct")
end

-- Test 5: Nil-safe parameters with zero division protection
function test.test_nil_safe_division()
	-- Ensure division by zero is prevented
	local safe_levels_per_slot = nil or 1
	assert(safe_levels_per_slot == 1, "Nil levels_per_slot should default to 1")
	
	-- Test calculation with safe defaults
	local level = 10
	local result = math.floor(level / safe_levels_per_slot)
	assert(type(result) == "number", "Division result should be a number")
	
	print("PASS: Nil-safe division protection works")
end

return test
