-- API Reference Checker for Factorio API Validation
-- Phase 5: Extended Syntax Validation & Reverse Engineering System
-- Reference: https://lua-api.factorio.com/latest/

local api_reference_checker = {}

-- Load Factorio mock for API reference
local factorio_mock

-- Lazy load factorio_mock
local function ensure_mock()
    if not factorio_mock then
        factorio_mock = require('factorio_mock')
    end
end

-- ============================================================================
-- API REFERENCE DATABASE
-- ============================================================================

-- Known Factorio API namespaces and their expected structure
api_reference_checker.API_NAMESPACES = {
    game = {
        properties = {
            "player", "players", "surfaces", "forces", "item_prototypes",
            "fluid_prototypes", "entity_prototypes", "equipment_prototypes",
            "tick", "ticks_played", "speed", "active_mods"
        },
        methods = {
            "print", "create_surface", "delete_surface", "get_player",
            "get_surface", "is_demo", "is_valid_sound_path", "reload_script"
        }
    },
    script = {
        methods = {
            "on_init", "on_load", "on_configuration_changed", "on_event",
            "on_nth_tick", "raise_event", "register_on_entity_destroyed",
            "generate_event_name", "get_event_handler"
        }
    },
    defines = {
        properties = {
            "events", "direction", "inventory", "difficulty", "controllers",
            "entity_status", "wire_type", "command", "compound_command"
        }
    },
    remote = {
        methods = {
            "add_interface", "remove_interface", "call", "interfaces"
        }
    },
    settings = {
        properties = {
            "startup", "global", "player"
        }
    },
    storage = {
        -- Global storage table (replaces 'global' in Factorio 2.0)
        type = "table"
    },
    rendering = {
        methods = {
            "draw_line", "draw_circle", "draw_arc", "draw_polygon",
            "draw_sprite", "draw_light", "draw_animation", "clear"
        }
    },
    rcon = {
        methods = {
            "print"
        }
    },
    commands = {
        methods = {
            "add_command", "remove_command", "game_commands"
        }
    }
}

-- ============================================================================
-- REFERENCE CHECKING
-- ============================================================================

-- Check if API reference is valid
-- @param api_call table: API call to validate
-- @return boolean: True if valid
-- @return string: Issue description if invalid
function api_reference_checker.check_reference(api_call)
    if not api_call or not api_call.namespace then
        return false, "Invalid API call structure"
    end
    
    local namespace = api_call.namespace
    local member = api_call.member
    
    -- Check if namespace exists
    if not api_reference_checker.API_NAMESPACES[namespace] then
        -- Try to check against mock
        ensure_mock()
        if factorio_mock[namespace] then
            return true, nil  -- Exists in mock
        end
        return false, "Unknown API namespace: " .. namespace
    end
    
    local ns_spec = api_reference_checker.API_NAMESPACES[namespace]
    
    -- Check if member exists
    if member then
        -- Check properties
        if ns_spec.properties then
            for _, prop in ipairs(ns_spec.properties) do
                if prop == member then
                    return true, nil
                end
            end
        end
        
        -- Check methods
        if ns_spec.methods then
            for _, method in ipairs(ns_spec.methods) do
                if method == member then
                    return true, nil
                end
            end
        end
        
        -- Member not found in spec, check mock
        ensure_mock()
        if factorio_mock[namespace] and factorio_mock[namespace][member] then
            return true, nil
        end
        
        return false, string.format("Unknown API member: %s.%s", namespace, member)
    end
    
    -- Namespace access without member is valid
    return true, nil
end

-- Validate API call signature
-- @param api_call table: API call with parameters
-- @return boolean: True if signature is valid
-- @return string: Issue description if invalid
function api_reference_checker.validate_signature(api_call)
    if not api_call then
        return false, "Nil API call"
    end
    
    -- Basic structure validation
    if not api_call.namespace then
        return false, "Missing namespace"
    end
    
    if api_call.type == "method" and not api_call.member then
        return false, "Method call missing member name"
    end
    
    -- Check parameter count (simplified validation)
    if api_call.params and type(api_call.params) ~= "table" then
        return false, "Invalid params structure"
    end
    
    return true, nil
end

-- ============================================================================
-- DEPRECATED API DETECTION
-- ============================================================================

-- List of deprecated APIs in Factorio 2.0
api_reference_checker.DEPRECATED_APIS = {
    ["global"] = {
        replacement = "storage",
        reason = "Replaced by 'storage' in Factorio 2.0",
        since = "2.0.0",
        match_type = "namespace"  -- Match entire namespace
    },
    ["game.player"] = {
        replacement = "game.players (iterate or index)",
        reason = "Direct game.player is unreliable in multiplayer",
        since = "1.0.0",
        match_type = "full_path"  -- Match exact full path
    }
}

-- Check if API is deprecated
-- @param api_call table: API call to check
-- @return boolean: True if deprecated
-- @return table: Deprecation info
function api_reference_checker.is_deprecated(api_call)
    if not api_call then
        return false, nil
    end
    
    local full_name = api_call.full_name or 
                      (api_call.namespace .. "." .. (api_call.member or ""))
    
    for deprecated_api, info in pairs(api_reference_checker.DEPRECATED_APIS) do
        if info.match_type == "namespace" then
            -- Match namespace only
            if api_call.namespace == deprecated_api then
                return true, info
            end
        elseif info.match_type == "full_path" then
            -- Match exact full path
            if full_name == deprecated_api then
                return true, info
            end
        else
            -- Default: try both
            if full_name == deprecated_api or api_call.namespace == deprecated_api then
                return true, info
            end
        end
    end
    
    return false, nil
end

-- ============================================================================
-- API COVERAGE ANALYSIS
-- ============================================================================

-- Get list of all known API elements
-- @return table: List of API elements
function api_reference_checker.get_all_api_elements()
    local elements = {}
    
    for namespace, spec in pairs(api_reference_checker.API_NAMESPACES) do
        -- Add properties
        if spec.properties then
            for _, prop in ipairs(spec.properties) do
                table.insert(elements, {
                    namespace = namespace,
                    member = prop,
                    type = "property",
                    full_name = namespace .. "." .. prop
                })
            end
        end
        
        -- Add methods
        if spec.methods then
            for _, method in ipairs(spec.methods) do
                table.insert(elements, {
                    namespace = namespace,
                    member = method,
                    type = "method",
                    full_name = namespace .. "." .. method
                })
            end
        end
    end
    
    return elements
end

-- Calculate API coverage
-- @param used_apis table: List of used API calls
-- @return table: Coverage statistics
function api_reference_checker.calculate_coverage(used_apis)
    local all_apis = api_reference_checker.get_all_api_elements()
    local used_set = {}
    
    -- Build set of used APIs
    for _, api_call in ipairs(used_apis or {}) do
        local key = api_call.full_name or 
                   (api_call.namespace .. "." .. (api_call.member or ""))
        used_set[key] = true
    end
    
    local coverage = {
        total_apis = #all_apis,
        used_apis = 0,
        unused_apis = {},
        coverage_percentage = 0
    }
    
    -- Count usage
    for _, api_element in ipairs(all_apis) do
        if used_set[api_element.full_name] then
            coverage.used_apis = coverage.used_apis + 1
        else
            table.insert(coverage.unused_apis, api_element.full_name)
        end
    end
    
    if coverage.total_apis > 0 then
        coverage.coverage_percentage = 
            (coverage.used_apis / coverage.total_apis) * 100
    end
    
    return coverage
end

-- ============================================================================
-- API COMPATIBILITY CHECKING
-- ============================================================================

-- Check API compatibility with Factorio version
-- @param api_call table: API call to check
-- @param factorio_version string: Target Factorio version
-- @return boolean: True if compatible
-- @return string: Compatibility note
function api_reference_checker.check_compatibility(api_call, factorio_version)
    if not api_call then
        return false, "Invalid API call"
    end
    
    -- Parse version (simplified)
    local major, minor, patch = factorio_version:match("(%d+)%.(%d+)%.(%d+)")
    if not major then
        return true, "Cannot parse version, assuming compatible"
    end
    
    major = tonumber(major)
    
    -- Check for version-specific APIs
    if major >= 2 then
        -- Factorio 2.0+ specific checks
        if api_call.namespace == "global" then
            return false, "Use 'storage' instead of 'global' in Factorio 2.0+"
        end
    end
    
    return true, "Compatible"
end

-- ============================================================================
-- REFERENCE DOCUMENTATION
-- ============================================================================

-- Get documentation URL for API element
-- @param api_call table: API call
-- @return string: Documentation URL
function api_reference_checker.get_documentation_url(api_call)
    if not api_call or not api_call.namespace then
        return "https://lua-api.factorio.com/latest/"
    end
    
    local base_url = "https://lua-api.factorio.com/latest/"
    
    if api_call.namespace == "defines" then
        return base_url .. "defines.html"
    elseif api_call.namespace == "game" then
        return base_url .. "classes/LuaGameScript.html"
    elseif api_call.namespace == "script" then
        return base_url .. "classes/LuaBootstrap.html"
    else
        return base_url .. "index.html"
    end
end

-- ============================================================================
-- BATCH VALIDATION
-- ============================================================================

-- Validate multiple API calls
-- @param api_calls table: List of API calls
-- @return table: Validation results
function api_reference_checker.validate_all(api_calls)
    local results = {
        valid = {},
        invalid = {},
        deprecated = {},
        warnings = {}
    }
    
    if not api_calls or #api_calls == 0 then
        return results
    end
    
    for _, api_call in ipairs(api_calls) do
        -- Check if valid
        local is_valid, issue = api_reference_checker.check_reference(api_call)
        
        if is_valid then
            table.insert(results.valid, api_call)
            
            -- Check if deprecated
            local is_deprecated, dep_info = api_reference_checker.is_deprecated(api_call)
            if is_deprecated then
                table.insert(results.deprecated, {
                    api_call = api_call,
                    info = dep_info
                })
                table.insert(results.warnings, {
                    api_call = api_call,
                    message = "Deprecated: " .. dep_info.reason
                })
            end
        else
            table.insert(results.invalid, {
                api_call = api_call,
                reason = issue
            })
        end
    end
    
    return results
end

-- ============================================================================
-- REPORT GENERATION
-- ============================================================================

-- Generate validation report
-- @param results table: Validation results
-- @return string: Formatted report
function api_reference_checker.generate_report(results)
    local lines = {}
    
    table.insert(lines, "API Reference Validation Report")
    table.insert(lines, "================================")
    table.insert(lines, "")
    
    table.insert(lines, string.format("Valid API calls: %d", #results.valid))
    table.insert(lines, string.format("Invalid API calls: %d", #results.invalid))
    table.insert(lines, string.format("Deprecated API calls: %d", #results.deprecated))
    table.insert(lines, string.format("Warnings: %d", #results.warnings))
    table.insert(lines, "")
    
    if #results.invalid > 0 then
        table.insert(lines, "INVALID API CALLS:")
        for i, invalid in ipairs(results.invalid) do
            local api_call = invalid.api_call
            local full_name = api_call.full_name or 
                            (api_call.namespace .. "." .. (api_call.member or ""))
            table.insert(lines, string.format("  [%d] %s - %s", i, full_name, invalid.reason))
        end
        table.insert(lines, "")
    end
    
    if #results.deprecated > 0 then
        table.insert(lines, "DEPRECATED API CALLS:")
        for i, deprecated in ipairs(results.deprecated) do
            local api_call = deprecated.api_call
            local full_name = api_call.full_name or 
                            (api_call.namespace .. "." .. (api_call.member or ""))
            local info = deprecated.info
            table.insert(lines, string.format("  [%d] %s", i, full_name))
            table.insert(lines, string.format("      Reason: %s", info.reason))
            table.insert(lines, string.format("      Replacement: %s", info.replacement))
            table.insert(lines, string.format("      Since: %s", info.since))
        end
        table.insert(lines, "")
    end
    
    return table.concat(lines, "\n")
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Check if API element exists in mock
-- @param namespace string: API namespace
-- @param member string: API member (optional)
-- @return boolean: True if exists
function api_reference_checker.exists_in_mock(namespace, member)
    ensure_mock()
    
    if not factorio_mock[namespace] then
        return false
    end
    
    if member and not factorio_mock[namespace][member] then
        return false
    end
    
    return true
end

-- Get API statistics
-- @return table: Statistics
function api_reference_checker.get_statistics()
    local stats = {
        total_namespaces = 0,
        total_properties = 0,
        total_methods = 0,
        total_apis = 0
    }
    
    for namespace, spec in pairs(api_reference_checker.API_NAMESPACES) do
        stats.total_namespaces = stats.total_namespaces + 1
        
        if spec.properties then
            stats.total_properties = stats.total_properties + #spec.properties
        end
        
        if spec.methods then
            stats.total_methods = stats.total_methods + #spec.methods
        end
    end
    
    stats.total_apis = stats.total_properties + stats.total_methods
    
    return stats
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return api_reference_checker
