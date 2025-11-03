local invisible_modules = {}

function invisible_modules.create_all_invisible_modules()
    -- No modules created - bonuses applied directly via entity.effects
    -- This function kept for compatibility but does nothing
    if not settings.startup["factory-levels-use-invisible-modules"].value then
        return
    end
end

return invisible_modules
