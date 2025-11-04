-- Mod Archive Validator for ZIP Archive Validation
-- Phase 5: Extended Syntax Validation & Reverse Engineering System

local mod_archive_validator = {}

-- Dependencies
local validation_engine

-- Lazy load dependencies
local function ensure_dependencies()
    if not validation_engine then
        validation_engine = require('validation_engine')
    end
end

-- ============================================================================
-- ARCHIVE STRUCTURE VALIDATION
-- ============================================================================

-- Expected structure for Factorio mod
mod_archive_validator.REQUIRED_FILES = {
    "info.json"
}

mod_archive_validator.OPTIONAL_FILES = {
    "control.lua",
    "data.lua",
    "data-updates.lua",
    "data-final-fixes.lua",
    "settings.lua",
    "settings-updates.lua",
    "settings-final-fixes.lua",
    "thumbnail.png",
    "changelog.txt",
    "LICENSE",
    "README.md"
}

-- ============================================================================
-- ZIP VALIDATION
-- ============================================================================

-- Validate mod archive structure
-- @param zip_path string: Path to .zip archive
-- @return table: Validation report
function mod_archive_validator.validate_mod_archive(zip_path)
    local report = {
        success = false,
        mod_name = nil,
        version = nil,
        files_found = {},
        files_validated = 0,
        errors = {},
        warnings = {},
        structure_valid = false,
        info_json_valid = false
    }
    
    -- Check if file exists
    local file = io.open(zip_path, "rb")
    if not file then
        table.insert(report.errors, "Cannot open archive: " .. zip_path)
        return report
    end
    file:close()
    
    -- Extract archive (simplified - would need real ZIP library)
    local extract_dir = "/tmp/mod_validation_" .. os.time()
    local extract_ok = mod_archive_validator.extract_archive(zip_path, extract_dir)
    
    if not extract_ok then
        table.insert(report.errors, "Failed to extract archive")
        return report
    end
    
    -- Validate structure
    local struct_ok, struct_issues = mod_archive_validator.validate_structure(extract_dir)
    report.structure_valid = struct_ok
    
    for _, issue in ipairs(struct_issues) do
        table.insert(report.errors, issue)
    end
    
    -- Parse info.json
    local info_data, info_err = mod_archive_validator.parse_info_json(extract_dir .. "/info.json")
    if info_data then
        report.info_json_valid = true
        report.mod_name = info_data.name
        report.version = info_data.version
    else
        table.insert(report.errors, "Invalid info.json: " .. tostring(info_err))
    end
    
    -- Validate Lua files
    ensure_dependencies()
    local lua_files = validation_engine.find_lua_files(extract_dir, true)
    report.files_found = lua_files
    
    for _, lua_file in ipairs(lua_files) do
        local file_report = validation_engine.validate_file(lua_file)
        if file_report.success then
            report.files_validated = report.files_validated + 1
        else
            for _, err in ipairs(file_report.errors) do
                table.insert(report.errors, lua_file .. ": " .. err)
            end
        end
    end
    
    -- Cleanup
    os.execute("rm -rf " .. extract_dir)
    
    report.success = #report.errors == 0
    
    return report
end

-- Extract ZIP archive (placeholder - requires ZIP library)
-- @param zip_path string: Path to ZIP
-- @param extract_dir string: Extract destination
-- @return boolean: Success status
function mod_archive_validator.extract_archive(zip_path, extract_dir)
    -- Create extraction directory
    os.execute("mkdir -p " .. extract_dir)
    
    -- Try to extract using unzip command
    local cmd = string.format('unzip -q "%s" -d "%s" 2>/dev/null', zip_path, extract_dir)
    local result = os.execute(cmd)
    
    return result == 0 or result == true
end

-- ============================================================================
-- STRUCTURE VALIDATION
-- ============================================================================

-- Validate mod directory structure
-- @param mod_dir string: Path to mod directory
-- @return boolean: True if valid
-- @return table: List of issues
function mod_archive_validator.validate_structure(mod_dir)
    local issues = {}
    
    -- Check for required files
    for _, required_file in ipairs(mod_archive_validator.REQUIRED_FILES) do
        local file_path = mod_dir .. "/" .. required_file
        local file = io.open(file_path, "r")
        if not file then
            table.insert(issues, "Missing required file: " .. required_file)
        else
            file:close()
        end
    end
    
    return #issues == 0, issues
end

-- ============================================================================
-- INFO.JSON VALIDATION
-- ============================================================================

-- Parse and validate info.json
-- @param info_json_path string: Path to info.json
-- @return table: Parsed data
-- @return string: Error message if failed
function mod_archive_validator.parse_info_json(info_json_path)
    local file = io.open(info_json_path, "r")
    if not file then
        return nil, "Cannot open info.json"
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Simple JSON parsing (simplified - would need real JSON library)
    local info_data = mod_archive_validator.simple_json_parse(content)
    
    if not info_data then
        return nil, "Failed to parse JSON"
    end
    
    -- Validate required fields
    local required_fields = {"name", "version", "title", "author", "factorio_version"}
    for _, field in ipairs(required_fields) do
        if not info_data[field] then
            return nil, "Missing required field: " .. field
        end
    end
    
    return info_data, nil
end

-- Simple JSON parser (very basic, for demonstration)
-- @param json_str string: JSON string
-- @return table: Parsed data
function mod_archive_validator.simple_json_parse(json_str)
    -- This is a placeholder - real implementation would use a proper JSON library
    local data = {}
    
    -- Extract name
    local name = json_str:match('"name"%s*:%s*"([^"]+)"')
    if name then data.name = name end
    
    -- Extract version
    local version = json_str:match('"version"%s*:%s*"([^"]+)"')
    if version then data.version = version end
    
    -- Extract title
    local title = json_str:match('"title"%s*:%s*"([^"]+)"')
    if title then data.title = title end
    
    -- Extract author
    local author = json_str:match('"author"%s*:%s*"([^"]+)"')
    if author then data.author = author end
    
    -- Extract factorio_version
    local factorio_version = json_str:match('"factorio_version"%s*:%s*"([^"]+)"')
    if factorio_version then data.factorio_version = factorio_version end
    
    return data
end

-- ============================================================================
-- DEPENDENCY VALIDATION
-- ============================================================================

-- Validate mod dependencies
-- @param info_data table: Parsed info.json
-- @return boolean: True if valid
-- @return table: List of issues
function mod_archive_validator.validate_dependencies(info_data)
    local issues = {}
    
    if not info_data.dependencies then
        return true, issues  -- No dependencies is valid
    end
    
    -- Check dependency format
    for _, dep in ipairs(info_data.dependencies) do
        if type(dep) ~= "string" then
            table.insert(issues, "Invalid dependency format: " .. tostring(dep))
        else
            -- Check dependency string format
            if not dep:match("^[!?~]?%s*[%w_-]+") then
                table.insert(issues, "Invalid dependency string: " .. dep)
            end
        end
    end
    
    return #issues == 0, issues
end

-- ============================================================================
-- BATCH VALIDATION
-- ============================================================================

-- Validate multiple mod archives
-- @param zip_paths table: List of ZIP file paths
-- @return table: Aggregated results
function mod_archive_validator.validate_multiple(zip_paths)
    local results = {
        total_archives = #zip_paths,
        validated = 0,
        failed = 0,
        reports = {}
    }
    
    for _, zip_path in ipairs(zip_paths) do
        local report = mod_archive_validator.validate_mod_archive(zip_path)
        table.insert(results.reports, report)
        
        if report.success then
            results.validated = results.validated + 1
        else
            results.failed = results.failed + 1
        end
    end
    
    return results
end

-- ============================================================================
-- REPORT GENERATION
-- ============================================================================

-- Generate validation report
-- @param report table: Validation report
-- @return string: Formatted report
function mod_archive_validator.generate_report(report)
    local lines = {}
    
    table.insert(lines, "Mod Archive Validation Report")
    table.insert(lines, "==============================")
    table.insert(lines, "")
    
    if report.mod_name then
        table.insert(lines, "Mod: " .. report.mod_name)
    end
    
    if report.version then
        table.insert(lines, "Version: " .. report.version)
    end
    
    table.insert(lines, "")
    table.insert(lines, string.format("Status: %s", report.success and "VALID" or "INVALID"))
    table.insert(lines, string.format("Files validated: %d", report.files_validated))
    table.insert(lines, "")
    
    if #report.errors > 0 then
        table.insert(lines, "ERRORS:")
        for i, err in ipairs(report.errors) do
            table.insert(lines, string.format("  [%d] %s", i, err))
        end
        table.insert(lines, "")
    end
    
    if #report.warnings > 0 then
        table.insert(lines, "WARNINGS:")
        for i, warn in ipairs(report.warnings) do
            table.insert(lines, string.format("  [%d] %s", i, warn))
        end
        table.insert(lines, "")
    end
    
    return table.concat(lines, "\n")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return mod_archive_validator
