data:extend({
    -- Existing settings
    {
        type = "bool-setting",
        name = "factory-levels-enable-productivity-bonus",
        order = "a",
        setting_type = "startup",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "factory-levels-enable-module-bonus",
        order = "aa",
        setting_type = "startup",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "factory-levels-enable-speed-bonus",
        order = "b",
        setting_type = "startup",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "factory-levels-enable-energy-usage",
        order = "c",
        setting_type = "startup",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "factory-levels-enable-emissions",
        order = "d",
        setting_type = "startup",
        default_value = true
    },
    {
        type = "double-setting",
        name = "factory-levels-exponent",
        order = "e",
        minimum_value = 1.5, maximum_value = 5,
        setting_type = "runtime-global",
        default_value = 3
    },
    {
        type = "bool-setting",
        name = "factory-levels-disable-mod",
        order = "f",
        setting_type = "runtime-global",
        default_value = false
    },
    {
        type = "bool-setting",
        name = "factory-levels-enable-quality-bonus",
        order = "g",
        setting_type = "startup",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "factory-levels-enable-recycler-leveling",
        order = "g",
        setting_type = "startup",
        default_value = false
    },

    -- New Advanced Settings
    -- Machine Level Configuration
    {
        type = "int-setting",
        name = "factory-levels-max-level-tier-1",
        order = "h1",
        setting_type = "startup",
        default_value = 25,
        minimum_value = 5,
        maximum_value = 500
    },
    {
        type = "int-setting",
        name = "factory-levels-max-level-tier-2",
        order = "h2",
        setting_type = "startup",
        default_value = 50,
        minimum_value = 10,
        maximum_value = 500
    },
    {
        type = "int-setting",
        name = "factory-levels-max-level-tier-3",
        order = "h3",
        setting_type = "startup",
        default_value = 100,
        minimum_value = 25,
        maximum_value = 500
    },

    -- Performance Settings
    {
        type = "int-setting",
        name = "factory-levels-check-interval",
        order = "i1",
        setting_type = "runtime-global",
        default_value = 6,
        minimum_value = 1,
        maximum_value = 60
    },
    {
        type = "int-setting",
        name = "factory-levels-machines-per-check",
        order = "i2",
        setting_type = "runtime-global",
        default_value = 100,
        minimum_value = 10,
        maximum_value = 1000
    },

    -- Leveling Configuration
    {
        type = "int-setting",
        name = "factory-levels-base-requirement",
        order = "j",
        setting_type = "runtime-global",
        default_value = 1,
        minimum_value = 1,
        maximum_value = 100
    },

    -- Debug Settings
    {
        type = "bool-setting",
        name = "factory-levels-debug-mode",
        order = "k",
        setting_type = "runtime-global",
        default_value = false
    },

    -- Machine Type Specific Settings
    {
        type = "bool-setting",
        name = "factory-levels-enable-assembler-leveling",
        order = "l1",
        setting_type = "startup",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "factory-levels-enable-furnace-leveling",
        order = "l2",
        setting_type = "startup",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "factory-levels-enable-refinery-leveling",
        order = "l3",
        setting_type = "startup",
        default_value = true
    },

    -- Invisible Module System (Parallel Infrastructure)
    {
        type = "bool-setting",
        name = "factory-levels-use-invisible-modules",
        order = "m1",
        setting_type = "startup",
        default_value = false
    }
})