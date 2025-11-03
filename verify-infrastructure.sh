#!/bin/bash
# Verification script for parallel invisible module infrastructure

echo "=== Verification: Parallel Invisible Module Infrastructure ==="
echo ""

# Check 1: Configuration toggle exists
echo "✓ Checking configuration toggle..."
if grep -q "factory-levels-use-invisible-modules" factory-levels/settings.lua; then
    echo "  ✓ Configuration toggle 'factory-levels-use-invisible-modules' found"
else
    echo "  ✗ Configuration toggle not found"
    exit 1
fi

# Check 2: Invisible module prototypes file exists
echo ""
echo "✓ Checking invisible module prototypes..."
if [ -f "factory-levels/prototypes/item/invisible-modules.lua" ]; then
    echo "  ✓ Invisible module file exists"
else
    echo "  ✗ Invisible module file not found"
    exit 1
fi

# Check 3: Data.lua includes invisible modules
echo ""
echo "✓ Checking data.lua integration..."
if grep -q "invisible-modules" factory-levels/data.lua; then
    echo "  ✓ Invisible modules loaded in data.lua"
else
    echo "  ✗ Invisible modules not loaded in data.lua"
    exit 1
fi

# Check 4: Control.lua has level tracking data structure
echo ""
echo "✓ Checking global data structure..."
if grep -q "storage.machine_levels" factory-levels/control.lua; then
    echo "  ✓ Global data structure 'storage.machine_levels' found"
else
    echo "  ✗ Global data structure not found"
    exit 1
fi

# Check 5: Bonus formulas exist
echo ""
echo "✓ Checking bonus formulas..."
if grep -q "bonus_formulas" factory-levels/control.lua; then
    echo "  ✓ Bonus formula lookup table found"
else
    echo "  ✗ Bonus formula lookup table not found"
    exit 1
fi

# Check 6: Event handler skeletons exist
echo ""
echo "✓ Checking event handler skeletons..."
if grep -q "on_machine_built_invisible" factory-levels/control.lua && \
   grep -q "on_machine_mined_invisible" factory-levels/control.lua; then
    echo "  ✓ Event handler skeletons found"
else
    echo "  ✗ Event handler skeletons not found"
    exit 1
fi

# Check 7: Basic tracking functions exist
echo ""
echo "✓ Checking tracking functions..."
if grep -q "track_machine_level" factory-levels/control.lua && \
   grep -q "untrack_machine_level" factory-levels/control.lua && \
   grep -q "get_machine_level" factory-levels/control.lua; then
    echo "  ✓ All tracking functions found"
else
    echo "  ✗ Some tracking functions missing"
    exit 1
fi

# Check 8: No modifications to existing entity definitions
echo ""
echo "✓ Checking entity definitions (no changes)..."
if ! git diff HEAD~1 factory-levels/prototypes/entity/entity.lua | grep -q "^[+-]"; then
    echo "  ✓ Entity definitions unchanged"
else
    echo "  ✗ Entity definitions were modified"
    exit 1
fi

# Check 9: Documentation exists
echo ""
echo "✓ Checking documentation..."
if [ -f "docs/invisible-module-system.md" ]; then
    echo "  ✓ Technical documentation exists"
else
    echo "  ✗ Technical documentation not found"
    exit 1
fi

# Check 10: Verify parallel operation (setting disabled by default)
echo ""
echo "✓ Checking default configuration..."
if grep -A5 "factory-levels-use-invisible-modules" factory-levels/settings.lua | grep -q "default_value = false"; then
    echo "  ✓ System disabled by default (parallel operation safe)"
else
    echo "  ✗ System not disabled by default"
    exit 1
fi

echo ""
echo "=== All Verification Checks Passed ==="
echo ""
echo "Summary:"
echo "  - Configuration toggle: ✓"
echo "  - Invisible modules: ✓"
echo "  - Global data structure: ✓"
echo "  - Bonus formulas: ✓"
echo "  - Event handlers: ✓"
echo "  - Tracking functions: ✓"
echo "  - Entity definitions: ✓ (unchanged)"
echo "  - Documentation: ✓"
echo "  - Parallel operation: ✓ (disabled by default)"
echo ""
echo "Infrastructure ready for testing!"
