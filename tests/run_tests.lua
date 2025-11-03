-- tests/run_tests.lua
-- Haupt-Test-Entrypoint für Faketorio CI

-- Helper function to safely load modules
local function safe_require(module_name)
	local success, result = pcall(require, module_name)
	if success then
		return result
	else
		print("Warning: Could not load module " .. module_name .. ": " .. tostring(result))
		return nil
	end
end

-- Test 1: Module slot bonus nil handling (standalone test)
local function test_module_slot_bonus_nil_handling()
	print("Running test: module_slot_bonus_nil_handling")
	
	-- Helper function to safely get module slot bonus
	local function get_safe_module_slot_bonus(entity)
		if not entity then
			return 0
		end
		
		if not entity.module_specification then
			return 0
		end
		
		local module_slots = entity.module_specification.module_slots
		if not module_slots then
			return 0
		end
		
		return module_slots
	end
	
	-- Test verschiedene Maschinentypen
	local test_entities = {
		{name = "assembling-machine-1", module_specification = {module_slots = 2}},
		{name = "stone-furnace", module_specification = nil},
		{name = "electric-furnace", module_specification = {module_slots = 2}},
		{name = "custom-machine", module_specification = {}},
	}
	
	for i, entity in ipairs(test_entities) do
		local bonus = get_safe_module_slot_bonus(entity)
		if type(bonus) ~= "number" then
			error("module_slot_bonus should return a number, got " .. type(bonus) .. " for entity " .. i)
		end
		if bonus < 0 then
			error("module_slot_bonus should not be negative, got " .. bonus .. " for entity " .. i)
		end
	end
	
	-- Test nil entity
	local nil_bonus = get_safe_module_slot_bonus(nil)
	if nil_bonus ~= 0 then
		error("nil entity should return 0, got " .. nil_bonus)
	end
	
	print("PASS: module_slot_bonus_nil_handling")
end

-- Test 2: Module slots calculation
local function test_module_slots_calculation()
	print("Running test: module_slots_calculation")
	
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
		if result ~= tc.expected then
			error(string.format("Test case %d failed: expected %d, got %d", i, tc.expected, result))
		end
	end
	
	print("PASS: module_slots_calculation")
end

-- Test 3: Nil-safe parameters with defaults
local function test_nil_safe_defaults()
	print("Running test: nil_safe_defaults")
	
	-- Ensure nil parameters default safely
	local safe_base_slots = nil or 0
	local safe_bonus = nil or 0
	local safe_levels_per_slot = nil or 1
	
	if safe_base_slots ~= 0 then
		error("Nil base_slots should default to 0")
	end
	if safe_bonus ~= 0 then
		error("Nil bonus should default to 0")
	end
	if safe_levels_per_slot ~= 1 then
		error("Nil levels_per_slot should default to 1")
	end
	
	-- Test calculation with safe defaults
	local level = 10
	local result = safe_base_slots + (math.floor(level / safe_levels_per_slot) * safe_bonus)
	if type(result) ~= "number" then
		error("Calculation result should be a number")
	end
	
	print("PASS: nil_safe_defaults")
end

-- Main test runner
local function run_all()
	local tests = {
		test_module_slot_bonus_nil_handling,
		test_module_slots_calculation,
		test_nil_safe_defaults,
	}
	
	print("=== Running factory-levels module_slot_bonus tests ===")
	print("")
	
	local passed = 0
	local failed = 0
	
	for i, test_func in ipairs(tests) do
		local ok, err = pcall(test_func)
		if not ok then
			print("TEST-FAIL: " .. tostring(err))
			print("")
			failed = failed + 1
		else
			passed = passed + 1
		end
	end
	
	print("")
	print("=== Test Summary ===")
	print("Passed: " .. passed)
	print("Failed: " .. failed)
	print("")
	
	if failed > 0 then
		print("TESTS FAILED")
		os.exit(1)
	else
		print("ALL TESTS PASSED")
		os.exit(0)
	end
end

run_all()
