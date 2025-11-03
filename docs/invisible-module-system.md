# Invisible Module System - Technical Documentation

## Overview
This document describes the parallel invisible module infrastructure added to the Factory Levels mod as part of the performance optimization initiative.

## Purpose
The invisible module system provides an alternative implementation for machine leveling that uses hidden modules instead of entity replacements. This infrastructure runs in parallel with the existing entity-based system to allow controlled testing before migration.

## Components

### 1. Configuration Toggle
**Setting:** `factory-levels-use-invisible-modules`
- **Type:** Startup setting (boolean)
- **Default:** `false` (disabled by default)
- **Location:** `settings.lua`

### 2. Invisible Module Prototypes
**File:** `prototypes/item/invisible-modules.lua`

Creates hidden module items for each machine type and level combination:
- **Naming:** `factory-levels-hidden-{machine-name}-level-{level}`
- **Category:** `factory-levels-hidden`
- **Properties:** Hidden, not stackable, only in cursor
- **Effects:** Productivity, speed, consumption, pollution, quality bonuses

**Supported Machines:**
- Assembling machines (tiers 1-3)
- Furnaces (stone, steel, electric)
- Refineries (chemical plant, oil refinery, centrifuge)
- Space Age machines (electromagnetic-plant, biochamber)
- Recycler

### 3. Level Tracking Data Structure
**Storage:** `global.machine_levels[entity_unit_number]`

Each tracked machine stores:
```lua
{
    level = <number>,                -- Current level
    bonuses = {                      -- Calculated bonuses
        productivity = <number>,
        speed = <number>,
        consumption = <number>,
        pollution = <number>,
        quality = <number>
    },
    machine_name = <string>,         -- Entity name
    surface_index = <number>,        -- Surface reference
    position = <table>               -- Position {x, y}
}
```

### 4. Bonus Calculation Formulas
**Location:** `control.lua` - `bonus_formulas` table

Lookup table with functions for each bonus type:
```lua
{
    productivity = function(level) return 0.0025 * level end,
    speed = function(level) return 0.01 * level end,
    consumption = function(level) return 0.02 * level end,
    pollution = function(level) return 0.04 * level end,
    quality = function(level) return 0.002 * level end
}
```

### 5. Core Functions

#### `init_invisible_module_system()`
Initializes the global storage for machine level tracking. Called during `on_init` and `on_configuration_changed`.

#### `calculate_bonuses(level)`
Calculates all bonus values for a given level using the formula lookup table.

**Parameters:**
- `level` (number): Machine level

**Returns:**
- Table with all calculated bonuses

#### `track_machine_level(entity, level)`
Tracks a machine's level in the global storage without applying any changes to the entity.

**Parameters:**
- `entity` (LuaEntity): Machine entity
- `level` (number): Level to track

#### `untrack_machine_level(unit_number)`
Removes machine tracking data.

**Parameters:**
- `unit_number` (number): Entity unit number

#### `get_machine_level(unit_number)`
Retrieves the tracked level for a machine.

**Parameters:**
- `unit_number` (number): Entity unit number

**Returns:**
- Level (number) or `nil` if not tracked

### 6. Event Handler Skeletons

#### `on_machine_built_invisible(entity)`
Skeleton handler for machine placement events. Currently inactive (empty implementation).

**Future Use:** Will handle automatic level tracking and module application when a machine is placed.

#### `on_machine_mined_invisible(entity)`
Skeleton handler for machine mining events. Currently inactive (empty implementation).

**Future Use:** Will handle cleanup of level tracking data when a machine is removed.

## Integration Points

The invisible module system integrates with existing event handlers:

1. **`on_built_entity`**: Calls `on_machine_built_invisible()` before existing logic
2. **`on_mined_entity`**: Calls `on_machine_mined_invisible()` before cleanup

These integrations are non-invasive and do not affect existing functionality when the system is disabled.

## Testing Status

Current implementation status:
- ✅ Configuration toggle
- ✅ Module prototypes created
- ✅ Global data structure
- ✅ Bonus formulas
- ✅ Event handler registration
- ✅ Basic tracking functions
- ⏸️ Level application (deferred to next phase)
- ⏸️ UI integration (deferred to next phase)
- ⏸️ Migration tools (deferred to next phase)

## Performance Considerations

With the setting disabled (default):
- **Runtime overhead:** Minimal (single boolean check per function)
- **Memory overhead:** None (no storage allocation)
- **Expected performance impact:** < 0.1%

With the setting enabled:
- **Runtime overhead:** Minimal (function calls return immediately)
- **Memory overhead:** ~100 bytes per tracked machine
- **Expected performance impact:** < 1%

## Next Steps

Subsequent phases will implement:
1. **Level Application System**: Apply tracked levels to machines via invisible modules
2. **UI System**: Display current level and progress
3. **Migration System**: Convert existing entity-based machines to invisible module system
4. **Deprecation System**: Phase out old entity replacement system

## Compatibility

- **Backward Compatible:** Yes - disabled by default
- **Save Compatible:** Yes - existing saves unaffected when disabled
- **Mod Conflicts:** None expected - runs parallel to existing system

## References

- Issue: Grundintegration: Parallel-Infrastruktur für unsichtbare Module
- Related Systems: Entity replacement system (control.lua)
- Settings: factory-levels-use-invisible-modules
