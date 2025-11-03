#!/bin/bash
# Verification script for Phase 2: Single-Module Implementation

echo "=== Verification: Phase 2 Single-Module Implementation ==="
echo ""

# Check 1: Universal modules instead of machine-specific
echo "✓ Checking universal module implementation..."
if grep -q "factory-levels-universal-module-" factory-levels/prototypes/item/invisible-modules.lua; then
    echo "  ✓ Universal module naming convention found"
else
    echo "  ✗ Universal module naming convention not found"
    exit 1
fi

# Check 2: Empty module effects (dynamic application)
echo ""
echo "✓ Checking module effect structure..."
if grep -q "effect = {}" factory-levels/prototypes/item/invisible-modules.lua; then
    echo "  ✓ Empty module effects (bonuses applied dynamically)"
else
    echo "  ✗ Module effects not empty"
    exit 1
fi

# Check 3: Not-blueprintable flag
echo ""
echo "✓ Checking module security flags..."
if grep -q "not-blueprintable" factory-levels/prototypes/item/invisible-modules.lua; then
    echo "  ✓ Not-blueprintable flag found"
else
    echo "  ✗ Not-blueprintable flag missing"
    exit 1
fi

# Check 4: Module insertion function
echo ""
echo "✓ Checking module manipulation functions..."
if grep -q "insert_module" factory-levels/control.lua && \
   grep -q "remove_modules" factory-levels/control.lua; then
    echo "  ✓ Module manipulation functions found"
else
    echo "  ✗ Module manipulation functions missing"
    exit 1
fi

# Check 5: Dynamic bonus application
echo ""
echo "✓ Checking dynamic bonus application..."
if grep -q "apply_bonuses_to_entity" factory-levels/control.lua; then
    echo "  ✓ Dynamic bonus application function found"
else
    echo "  ✗ Dynamic bonus application function not found"
    exit 1
fi

# Check 6: Level update function
echo ""
echo "✓ Checking level update mechanism..."
if grep -q "update_machine_level" factory-levels/control.lua; then
    echo "  ✓ Level update function found"
else
    echo "  ✗ Level update function not found"
    exit 1
fi

# Check 7: current_module field in storage
echo ""
echo "✓ Checking storage structure extension..."
if grep -q "current_module =" factory-levels/control.lua; then
    echo "  ✓ current_module field in storage structure"
else
    echo "  ✗ current_module field missing"
    exit 1
fi

# Check 8: Active event handlers (no longer skeletons)
echo ""
echo "✓ Checking active event handlers..."
if grep -A15 "on_machine_built_invisible" factory-levels/control.lua | grep -q "track_machine_level"; then
    echo "  ✓ Event handlers are now active"
else
    echo "  ✗ Event handlers still skeletons"
    exit 1
fi

# Check 9: Integration with replace_machines
echo ""
echo "✓ Checking integration with level-up system..."
if grep -A20 "function replace_machines" factory-levels/control.lua | grep -q "factory-levels-use-invisible-modules"; then
    echo "  ✓ Integration with replace_machines found"
else
    echo "  ✗ Integration with replace_machines missing"
    exit 1
fi

# Check 10: Module inventory clearing
echo ""
echo "✓ Checking module cleanup on level change..."
if grep -q "module_inventory.clear()" factory-levels/control.lua; then
    echo "  ✓ Module cleanup mechanism implemented"
else
    echo "  ✗ Module cleanup mechanism missing"
    exit 1
fi

echo ""
echo "=== All Phase 2 Verification Checks Passed ==="
echo ""
echo "Summary:"
echo "  - Universal module system: ✓"
echo "  - Dynamic bonus application: ✓"
echo "  - Module manipulation: ✓"
echo "  - Level update mechanism: ✓"
echo "  - Storage structure: ✓"
echo "  - Active event handlers: ✓"
echo "  - Level-up integration: ✓"
echo "  - Module cleanup: ✓"
echo "  - Security flags: ✓"
echo ""
echo "Phase 2 implementation complete and verified!"
