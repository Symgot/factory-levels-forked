local invisible_modules = {}

function invisible_modules.create_invisible_module(machine_name, max_level)
    local modules = {}
    
    for level = 1, max_level do
        local module_name = "factory-levels-hidden-" .. machine_name .. "-level-" .. level
        
        table.insert(modules, {
            type = "module",
            name = module_name,
            icon = "__base__/graphics/icons/productivity-module.png",
            icon_size = 64,
            subgroup = "module",
            category = "factory-levels-hidden",
            tier = level,
            stack_size = 1,
            effect = {
                productivity = { bonus = 0.0025 * level },
                speed = { bonus = 0.01 * level },
                consumption = { bonus = 0.02 * level },
                pollution = { bonus = 0.04 * level },
                quality = { bonus = 0.002 * level }
            },
            flags = { "hidden", "not-stackable", "only-in-cursor" }
        })
    end
    
    return modules
end

function invisible_modules.create_all_invisible_modules()
    if not settings.startup["factory-levels-use-invisible-modules"].value then
        return
    end
    
    local all_modules = {}
    
    local machine_configs = {
        ["assembling-machine-1"] = settings.startup["factory-levels-max-level-tier-1"].value,
        ["assembling-machine-2"] = settings.startup["factory-levels-max-level-tier-2"].value,
        ["assembling-machine-3"] = settings.startup["factory-levels-max-level-tier-3"].value,
        ["stone-furnace"] = settings.startup["factory-levels-max-level-tier-1"].value,
        ["steel-furnace"] = settings.startup["factory-levels-max-level-tier-2"].value,
        ["electric-furnace"] = settings.startup["factory-levels-max-level-tier-3"].value,
        ["chemical-plant"] = settings.startup["factory-levels-max-level-tier-3"].value,
        ["oil-refinery"] = settings.startup["factory-levels-max-level-tier-3"].value,
        ["centrifuge"] = settings.startup["factory-levels-max-level-tier-3"].value,
        ["electromagnetic-plant"] = settings.startup["factory-levels-max-level-tier-3"].value,
        ["biochamber"] = settings.startup["factory-levels-max-level-tier-3"].value,
        ["recycler"] = settings.startup["factory-levels-max-level-tier-3"].value
    }
    
    for machine_name, max_level in pairs(machine_configs) do
        local modules = invisible_modules.create_invisible_module(machine_name, max_level)
        for _, module in pairs(modules) do
            table.insert(all_modules, module)
        end
    end
    
    data:extend(all_modules)
end

return invisible_modules
