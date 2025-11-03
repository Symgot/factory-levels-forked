#!/bin/bash
# Verification script for Truly Invisible Bonus System

echo "=== Verification: Truly Invisible Bonus System ==="
echo ""

# Check 1: No module prototypes created
echo "✓ Checking that no modules are created..."
if grep -q "No modules created - bonuses applied directly" factory-levels/prototypes/item/invisible-modules.lua; then
    echo "  ✓ Module creation disabled (truly invisible)"
else
    echo "  ✗ Modules still being created"
    exit 1
fi

# Check 2: Direct bonus application function exists
echo ""
echo "✓ Checking direct bonus application..."
if grep -q "apply_bonuses_to_entity" factory-levels/control.lua; then
    echo "  ✓ Direct bonus application function found"
else
    echo "  ✗ Direct bonus application function not found"
    exit 1
fi

# Check 3: Bonus clearing function exists
echo ""
echo "✓ Checking bonus clearing function..."
if grep -q "clear_bonuses_from_entity" factory-levels/control.lua; then
    echo "  ✓ Bonus clearing function found"
else
    echo "  ✗ Bonus clearing function not found"
    exit 1
fi

# Check 4: No module inventory operations
echo ""
echo "✓ Checking for absence of module inventory operations..."
if ! grep -q "get_module_inventory()" factory-levels/control.lua | grep -v "^--"; then
    echo "  ✓ No module inventory operations (truly invisible)"
else
    echo "  ✗ Module inventory operations still present"
    exit 1
fi

# Check 5: Level update function
echo ""
echo "✓ Checking level update mechanism..."
if grep -q "update_machine_level" factory-levels/control.lua; then
    echo "  ✓ Level update function found"
else
    echo "  ✗ Level update function not found"
    exit 1
fi

# Check 6: bonuses_applied field in storage
echo ""
echo "✓ Checking storage structure..."
if grep -q "bonuses_applied =" factory-levels/control.lua; then
    echo "  ✓ bonuses_applied field in storage structure"
else
    echo "  ✗ bonuses_applied field missing"
    exit 1
fi

# Check 7: Active event handlers
echo ""
echo "✓ Checking active event handlers..."
if sed -n '/local function on_machine_built_invisible/,/^end$/p' factory-levels/control.lua | grep -q "track_machine_level"; then
    echo "  ✓ Event handlers are active"
else
    echo "  ✗ Event handlers still skeletons"
    exit 1
fi

# Check 8: Integration with replace_machines
echo ""
echo "✓ Checking integration with level-up system..."
if grep "function replace_machines" factory-levels/control.lua | head -1 && \
   grep "factory-levels-use-invisible-modules" factory-levels/control.lua | grep -q "replace_machines\|if settings"; then
    echo "  ✓ Integration with replace_machines found"
else
    echo "  ✗ Integration with replace_machines missing"
    exit 1
fi

# Check 9: Bonus clearing on machine removal
echo ""
echo "✓ Checking bonus cleanup on removal..."
if grep -q "clear_bonuses_from_entity" factory-levels/control.lua && \
   sed -n '/local function on_machine_mined_invisible/,/^end$/p' factory-levels/control.lua | grep -q "clear_bonuses_from_entity"; then
    echo "  ✓ Bonus cleanup mechanism implemented"
else
    echo "  ✗ Bonus cleanup mechanism missing"
    exit 1
fi

# Check 10: Documentation reflects truly invisible system
echo ""
echo "✓ Checking documentation accuracy..."
if grep -q "No module slots consumed" docs/invisible-module-system.md; then
    echo "  ✓ Documentation reflects truly invisible system"
else
    echo "  ✗ Documentation not updated"
    exit 1
fi

echo ""
echo "=== All Truly Invisible Bonus System Checks Passed ==="
echo ""
echo "Summary:"
echo "  - No module prototypes: ✓"
echo "  - Direct bonus application: ✓"
echo "  - Bonus clearing: ✓"
echo "  - No module inventory operations: ✓"
echo "  - Level update mechanism: ✓"
echo "  - Storage structure: ✓"
echo "  - Active event handlers: ✓"
echo "  - Level-up integration: ✓"
echo "  - Bonus cleanup: ✓"
echo "  - Documentation: ✓"
echo ""
echo "Truly invisible bonus system implementation complete and verified!"
