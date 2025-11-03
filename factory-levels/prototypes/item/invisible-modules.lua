local invisible_modules = {}

function invisible_modules.create_all_invisible_modules()
    if not settings.startup["factory-levels-use-invisible-modules"].value then
        return
    end
    
    local all_modules = {}
    local max_level = math.max(
        settings.startup["factory-levels-max-level-tier-1"].value,
        settings.startup["factory-levels-max-level-tier-2"].value,
        settings.startup["factory-levels-max-level-tier-3"].value
    )
    
    for level = 1, max_level do
        local module_name = "factory-levels-universal-module-" .. level
        
        table.insert(all_modules, {
            type = "module",
            name = module_name,
            icon = "__base__/graphics/icons/productivity-module.png",
            icon_size = 64,
            subgroup = "module",
            category = "factory-levels-hidden",
            tier = level,
            stack_size = 1,
            effect = {},
            limitation = {},
            flags = { "hidden", "not-stackable", "only-in-cursor", "not-blueprintable" }
        })
    end
    
    data:extend(all_modules)
end

return invisible_modules
