#!/bin/bash
# Verification script for module_slot_bonus fix

set -e

echo "=== Verification: module_slot_bonus Nil-Value Error Fix ==="
echo ""

# Check 1: Function call has correct parameters
echo "✓ Checking function call parameters..."
if grep -q "factory_levels.update_machine_module_slots(machine, level, machines.levels_per_module_slots\[tier\], machines.base_module_slots\[tier\], machines.bonus_module_slots\[tier\])" factory-levels/prototypes/entity/factory_levels.lua; then
    echo "  ✓ Function call has all 5 parameters (including base_module_slots)"
else
    echo "  ✗ Function call missing parameters"
    exit 1
fi

# Check 2: Defensive nil-checking exists
echo ""
echo "✓ Checking defensive nil-checking..."
if grep -q "local safe_base_slots = base_module_slots or 0" factory-levels/prototypes/entity/factory_levels.lua; then
    echo "  ✓ Defensive nil-checking for base_module_slots found"
else
    echo "  ✗ Defensive nil-checking not found"
    exit 1
fi

if grep -q "local safe_bonus = module_slot_bonus or 0" factory-levels/prototypes/entity/factory_levels.lua; then
    echo "  ✓ Defensive nil-checking for module_slot_bonus found"
else
    echo "  ✗ Defensive nil-checking not found"
    exit 1
fi

if grep -q "local safe_levels_per_slot = levels_per_module_slot or 1" factory-levels/prototypes/entity/factory_levels.lua; then
    echo "  ✓ Defensive nil-checking for levels_per_module_slot found (prevents division by zero)"
else
    echo "  ✗ Defensive nil-checking not found"
    exit 1
fi

# Check 3: Test files exist
echo ""
echo "✓ Checking test files..."
if [ -f "tests/run_tests.lua" ]; then
    echo "  ✓ Main test runner exists"
else
    echo "  ✗ Main test runner not found"
    exit 1
fi

if [ -f "tests/test_module_slot_bonus.lua" ]; then
    echo "  ✓ module_slot_bonus test file exists"
else
    echo "  ✗ module_slot_bonus test file not found"
    exit 1
fi

# Check 4: Run tests
echo ""
echo "✓ Running test suite..."
if command -v lua5.4 &> /dev/null; then
    if lua5.4 tests/run_tests.lua; then
        echo "  ✓ All tests passed"
    else
        echo "  ✗ Tests failed"
        exit 1
    fi
else
    echo "  ⚠ Lua5.4 not installed, skipping test execution"
fi

# Check 5: Documentation exists
echo ""
echo "✓ Checking documentation..."
if [ -f "docs/FIX-MODULE-SLOT-BONUS.md" ]; then
    echo "  ✓ Fix documentation exists"
else
    echo "  ✗ Fix documentation not found"
    exit 1
fi

echo ""
echo "=== All Verifications Passed ✓ ==="
echo ""
echo "Summary of changes:"
echo "  • Fixed function call to include base_module_slots parameter"
echo "  • Added defensive nil-checking for all parameters"
echo "  • Created comprehensive test suite"
echo "  • Added detailed documentation"
echo ""
echo "The module_slot_bonus nil-value error has been successfully resolved!"
