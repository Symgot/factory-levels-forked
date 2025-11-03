-- tests/run_tests.lua
-- Haupt-Test-Entrypoint für Faketorio CI
local function assert_eq(a,b,msg)
  if a ~= b then
    error("Assertion failed: "..(msg or "").." expected "..tostring(b).." got "..tostring(a))
  end
end

local function test_game_present()
  if type(game) ~= "table" then
    error("Expected global 'game' table to be available")
  end
end

local function test_factory_levels_mod_loaded()
  -- Test factory-levels mod loading
  if not remote.interfaces["factory-levels"] then
    error("factory-levels mod interface not available")
  end
end

local function test_multi_level_building()
  -- Test multi-level factory mechanics
  local surface = game.create_surface("test")
  local pos = {x=0, y=0}
  
  -- Create a factory building
  local entity = surface.create_entity{
    name="factory-building",
    position=pos,
    force="player"
  }
  
  assert_eq(entity.name, "factory-building", "Factory building creation")
  
  -- Test level mechanics
  local level = remote.call("factory-levels", "get_level", entity)
  assert_eq(type(level), "number", "Level should be numeric")
end

local function run_all()
  local tests = {
    test_game_present,
    test_factory_levels_mod_loaded,
    test_multi_level_building
  }
  
  print("Running factory-levels mod tests...")
  
  for i,t in ipairs(tests) do
    local ok, err = pcall(t)
    if not ok then
      print("TEST-FAIL: "..tostring(err))
      os.exit(1)
    else
      print("TEST-PASS: Test "..i.." completed")
    end
  end
  
  print("ALL TESTS PASSED")
  os.exit(0)
end

run_all()
```
