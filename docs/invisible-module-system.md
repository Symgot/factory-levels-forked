# Invisible Module System - Technical Documentation

## Overview
This document describes the truly invisible bonus system added to the Factory Levels mod. Unlike traditional module systems, this implementation applies bonuses directly without consuming any module slots or showing any GUI elements.

## Purpose
The invisible bonus system provides an alternative implementation for machine leveling that uses direct effect application instead of entity replacements. Bonuses are applied completely invisibly via the entity.effects API, with no module slots consumed and no GUI visibility.

## Components

### 1. Configuration Toggle
**Setting:** `factory-levels-use-invisible-modules`
- **Type:** Startup setting (boolean)
- **Default:** `false` (disabled by default)
- **Location:** `settings.lua`

### 2. Direct Bonus Application
No module prototypes are created. Bonuses are applied directly via `entity.effects` API.

**Key Difference from Module-Based Systems:**
- **No modules created or inserted**
- **No module slots consumed**
- **Completely invisible in GUI**
- **No module inventory access needed**
- **Works on machines without module slots**

**Bonus Application Method:**
```lua
entity.effects.productivity = 0.0025 * level
entity.effects.speed = 0.01 * level
entity.effects.consumption = 0.02 * level
entity.effects.pollution = 0.04 * level
entity.effects.quality = 0.002 * level
```

### 3. Level Tracking Data Structure
**Storage:** `storage.machine_levels[entity_unit_number]`

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
    bonuses_applied = <boolean>,     -- Whether bonuses successfully applied
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

#### `apply_bonuses_to_entity(entity, level)`
Applies calculated bonuses directly to entity's effect receiver without using modules.

**Parameters:**
- `entity` (LuaEntity): Machine entity
- `level` (number): Level to apply

**Returns:**
- `true` if bonuses successfully applied
- `false` if entity has no effects API

#### `clear_bonuses_from_entity(entity)`
Resets all bonuses on an entity to zero.

**Parameters:**
- `entity` (LuaEntity): Machine entity

#### `track_machine_level(entity, level)`
Tracks a machine's level and applies bonuses directly without modules.

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

### 6. Event Handler Functions

#### `on_machine_built_invisible(entity)`
Handler for machine placement events. Applies level 1 bonuses directly.

**Process:**
1. Validate entity type (assembling-machine or furnace)
2. Track at level 1
3. Apply level-1 bonuses via entity.effects

#### `on_machine_mined_invisible(entity)`
Handler for machine mining events. Clears bonuses before removal.

**Process:**
1. Clear bonuses from entity
2. Untrack machine level

## Integration Points

The invisible bonus system integrates with existing event handlers:

1. **`on_built_entity`**: Calls `on_machine_built_invisible()` to apply initial bonuses
2. **`on_mined_entity`**: Calls `on_machine_mined_invisible()` to clear bonuses

These integrations are non-invasive and do not affect existing functionality when the system is disabled.

## Key Advantages Over Module-Based Systems

1. **No Module Slots Consumed**: Works even on machines with zero module slots
2. **Completely Invisible**: No GUI clutter, no visible modules
3. **Universal Compatibility**: Works with any machine that has an effects receiver
4. **Better Performance**: No module inventory operations needed
5. **Simpler Implementation**: No module prototypes to create or manage

## Testing Status

Current implementation status:
- ✅ Configuration toggle
- ✅ Direct bonus application via entity.effects
- ✅ Global data structure
- ✅ Bonus formulas
- ✅ Event handler registration
- ✅ Bonus tracking functions
- ✅ Bonus clearing on removal
- ✅ Level application active
- ⏸️ UI integration (deferred to next phase)
- ⏸️ Migration tools (deferred to next phase)

## Performance Considerations

With the setting disabled (default):
- **Runtime overhead:** Minimal (single boolean check per function)
- **Memory overhead:** None (no storage allocation)
- **Expected performance impact:** < 0.1%

With the setting enabled:
- **Runtime overhead:** Minimal (direct effect setting, no module operations)
- **Memory overhead:** ~120 bytes per tracked machine
- **Expected performance impact:** < 0.5%

## Next Steps

Subsequent phases will implement:
1. **UI System**: Display current level and progress overlays
2. **Migration System**: Convert existing entity-based machines to invisible bonus system
3. **Deprecation System**: Phase out old entity replacement system

## Compatibility

- **Backward Compatible:** Yes - disabled by default
- **Save Compatible:** Yes - existing saves unaffected when disabled
- **Mod Conflicts:** None expected - runs parallel to existing system
- **Module Slot Independence:** Works on machines with or without module slots

## References

- Issue: Implement dedicated invisible module slot system with custom compatibility
- Related Systems: Entity replacement system (control.lua)
- Settings: factory-levels-use-invisible-modules
