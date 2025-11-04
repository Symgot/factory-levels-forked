-- Native Library Integration: ZIP and JSON
-- Phase 6: Native Libraries for Cross-Platform Support
-- Reference: https://github.com/rxi/json.lua
-- Reference: https://github.com/mpx/lua-ziplib

local native_libs = {}

-- ============================================================================
-- JSON LIBRARY (Pure Lua Implementation)
-- ============================================================================

local json = {}

json.null = {}

local function kind_of(obj)
    if type(obj) ~= 'table' then return type(obj) end
    local i = 1
    for _ in pairs(obj) do
        if obj[i] ~= nil then i = i + 1 else return 'table' end
    end
    if i == 1 then return 'table' else return 'array' end
end

local function escape_str(s)
    local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
    local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
    for i, c in ipairs(in_char) do
        s = s:gsub(c, '\\' .. out_char[i])
    end
    return s
end

local function skip_delim(str, pos, delim, err_if_missing)
    pos = pos + #str:match('^%s*', pos)
    if str:sub(pos, pos) ~= delim then
        if err_if_missing then
            error('Expected ' .. delim .. ' near position ' .. pos)
        end
        return pos, false
    end
    return pos + 1, true
end

local function parse_str_val(str, pos, val)
    val = val or ''
    local early_end_error = 'End of input found while parsing string.'
    if pos > #str then error(early_end_error) end
    local c = str:sub(pos, pos)
    if c == '"'  then return val, pos + 1 end
    if c ~= '\\' then return parse_str_val(str, pos + 1, val .. c) end
    local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
    local nextc = str:sub(pos + 1, pos + 1)
    if not nextc then error(early_end_error) end
    return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

local function parse_num_val(str, pos)
    local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
    local val = tonumber(num_str)
    if not val then error('Error parsing number at position ' .. pos .. '.') end
    return val, pos + #num_str
end

function json.parse(str, pos, end_delim)
    pos = pos or 1
    if pos > #str then error('Reached unexpected end of input.') end
    local pos = pos + #str:match('^%s*', pos)
    local first = str:sub(pos, pos)
    if first == '{' then
        local obj, key, delim_found = {}, true, true
        pos = pos + 1
        while true do
            key, pos = json.parse(str, pos, '}')
            if key == nil then return obj, pos end
            if not delim_found then error('Comma missing between object items.') end
            pos = skip_delim(str, pos, ':', true)
            obj[key], pos = json.parse(str, pos)
            pos, delim_found = skip_delim(str, pos, ',')
        end
    elseif first == '[' then
        local arr, val, delim_found = {}, true, true
        pos = pos + 1
        while true do
            val, pos = json.parse(str, pos, ']')
            if val == nil then return arr, pos end
            if not delim_found then error('Comma missing between array items.') end
            arr[#arr + 1] = val
            pos, delim_found = skip_delim(str, pos, ',')
        end
    elseif first == '"' then
        return parse_str_val(str, pos + 1)
    elseif first == '-' or first:match('%d') then
        return parse_num_val(str, pos)
    elseif first == end_delim then
        return nil, pos + 1
    else
        local literals = {['true'] = true, ['false'] = false, ['null'] = json.null}
        for lit_str, lit_val in pairs(literals) do
            local lit_end = pos + #lit_str - 1
            if str:sub(pos, lit_end) == lit_str then
                return lit_val, lit_end + 1
            end
        end
        local pos_info_str = 'position ' .. pos .. ': ' .. str:sub(pos, pos + 10)
        error('Invalid json syntax starting at ' .. pos_info_str)
    end
end

function json.stringify(obj, as_key)
    local s = {}
    local t = type(obj)
    if t == 'table' and obj == json.null then
        return 'null'
    elseif t == 'table' then
        if kind_of(obj) == 'array' then
            if as_key then error('Can\'t encode array as key.') end
            s[#s + 1] = '['
            for i, val in ipairs(obj) do
                if i > 1 then s[#s + 1] = ', ' end
                s[#s + 1] = json.stringify(val)
            end
            s[#s + 1] = ']'
        else
            if as_key then error('Can\'t encode table as key.') end
            s[#s + 1] = '{'
            local first = true
            for k, v in pairs(obj) do
                if not first then s[#s + 1] = ', ' end
                first = false
                s[#s + 1] = json.stringify(k, true)
                s[#s + 1] = ':'
                s[#s + 1] = json.stringify(v)
            end
            s[#s + 1] = '}'
        end
    elseif t == 'string' then
        return '"' .. escape_str(obj) .. '"'
    elseif t == 'number' then
        return tostring(obj)
    elseif t == 'boolean' then
        return tostring(obj)
    elseif t == 'nil' then
        return 'null'
    else
        error('Unjsonifiable type: ' .. t .. '.')
    end
    return table.concat(s)
end

native_libs.json = json

-- ============================================================================
-- ZIP LIBRARY (Simplified Interface)
-- ============================================================================

local zip = {}

-- Check if unzip command is available
function zip.is_available()
    local handle = io.popen("which unzip 2>/dev/null")
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
end

-- Extract ZIP archive
-- @param zip_path string: Path to ZIP file
-- @param extract_to string: Directory to extract to
-- @return boolean: Success
-- @return string: Error message if failed
function zip.extract(zip_path, extract_to)
    if not zip.is_available() then
        return false, "unzip command not available"
    end
    
    -- Create extract directory
    os.execute("mkdir -p " .. extract_to)
    
    -- Extract archive
    local cmd = string.format("unzip -q -o '%s' -d '%s' 2>&1", zip_path, extract_to)
    local handle = io.popen(cmd)
    local output = handle:read("*a")
    local success = handle:close()
    
    if not success then
        return false, "Extraction failed: " .. output
    end
    
    return true, nil
end

-- List files in ZIP archive
-- @param zip_path string: Path to ZIP file
-- @return table: List of filenames
-- @return string: Error message if failed
function zip.list_files(zip_path)
    if not zip.is_available() then
        return nil, "unzip command not available"
    end
    
    local cmd = string.format("unzip -l '%s' 2>&1", zip_path)
    local handle = io.popen(cmd)
    local output = handle:read("*a")
    handle:close()
    
    local files = {}
    for line in output:gmatch("[^\r\n]+") do
        -- Parse unzip -l output format
        local filename = line:match("%d+%s+%d%d%-%d%d%-%d%d%s+%d%d:%d%d%s+(.+)$")
        if filename then
            table.insert(files, filename)
        end
    end
    
    return files, nil
end

-- Read file from ZIP archive
-- @param zip_path string: Path to ZIP file
-- @param filename string: File to read from archive
-- @return string: File content
-- @return string: Error message if failed
function zip.read_file(zip_path, filename)
    if not zip.is_available() then
        return nil, "unzip command not available"
    end
    
    local cmd = string.format("unzip -p '%s' '%s' 2>&1", zip_path, filename)
    local handle = io.popen(cmd)
    local content = handle:read("*a")
    local success = handle:close()
    
    if not success then
        return nil, "Failed to read file from archive"
    end
    
    return content, nil
end

-- Validate ZIP archive
-- @param zip_path string: Path to ZIP file
-- @return boolean: Valid
-- @return string: Error message if invalid
function zip.validate(zip_path)
    if not zip.is_available() then
        return false, "unzip command not available"
    end
    
    local cmd = string.format("unzip -t '%s' 2>&1", zip_path)
    local handle = io.popen(cmd)
    local output = handle:read("*a")
    local success = handle:close()
    
    if not success or output:match("[Ee]rror") then
        return false, "Archive validation failed: " .. output
    end
    
    return true, nil
end

native_libs.zip = zip

-- ============================================================================
-- FILE SYSTEM UTILITIES
-- ============================================================================

local fs = {}

-- Check if file exists
function fs.exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Check if path is directory
function fs.is_directory(path)
    local attr = io.popen("test -d '" .. path .. "' && echo 'true' || echo 'false'")
    local result = attr:read("*a"):match("^%s*(.-)%s*$")
    attr:close()
    return result == "true"
end

-- List files in directory
function fs.list_dir(path)
    local files = {}
    local handle = io.popen("ls -1 '" .. path .. "' 2>/dev/null")
    if handle then
        for file in handle:lines() do
            table.insert(files, file)
        end
        handle:close()
    end
    return files
end

-- Read file content
function fs.read_file(path)
    local file = io.open(path, "r")
    if not file then
        return nil, "Failed to open file: " .. path
    end
    local content = file:read("*all")
    file:close()
    return content, nil
end

-- Write file content
function fs.write_file(path, content)
    local file = io.open(path, "w")
    if not file then
        return false, "Failed to open file for writing: " .. path
    end
    file:write(content)
    file:close()
    return true, nil
end

-- Get file size
function fs.file_size(path)
    local file = io.open(path, "r")
    if not file then
        return nil, "Failed to open file: " .. path
    end
    local size = file:seek("end")
    file:close()
    return size, nil
end

-- Create directory
function fs.mkdir(path)
    local success = os.execute("mkdir -p '" .. path .. "'")
    return success ~= nil and success ~= false
end

-- Remove file or directory
function fs.remove(path)
    local success = os.execute("rm -rf '" .. path .. "'")
    return success ~= nil and success ~= false
end

native_libs.fs = fs

-- ============================================================================
-- PLATFORM DETECTION
-- ============================================================================

local platform = {}

function platform.get_os()
    local handle = io.popen("uname -s 2>/dev/null")
    if not handle then
        return "unknown"
    end
    local os_name = handle:read("*a"):match("^%s*(.-)%s*$")
    handle:close()
    
    if os_name:match("Linux") then
        return "linux"
    elseif os_name:match("Darwin") then
        return "macos"
    elseif os_name:match("MINGW") or os_name:match("MSYS") then
        return "windows"
    else
        return "unknown"
    end
end

function platform.get_arch()
    local handle = io.popen("uname -m 2>/dev/null")
    if not handle then
        return "unknown"
    end
    local arch = handle:read("*a"):match("^%s*(.-)%s*$")
    handle:close()
    return arch
end

native_libs.platform = platform

-- ============================================================================
-- INTEGRATION WITH EXISTING COMPONENTS
-- ============================================================================

-- Enhanced mod archive validator using native ZIP
function native_libs.validate_mod_archive_native(zip_path)
    local report = {
        valid = false,
        archive_valid = false,
        structure_valid = false,
        info_valid = false,
        files = {},
        errors = {},
        warnings = {}
    }
    
    -- Validate ZIP structure
    local valid, err = zip.validate(zip_path)
    if not valid then
        table.insert(report.errors, "Invalid ZIP archive: " .. tostring(err))
        return report
    end
    report.archive_valid = true
    
    -- List files in archive
    local files, err = zip.list_files(zip_path)
    if not files then
        table.insert(report.errors, "Failed to list archive files: " .. tostring(err))
        return report
    end
    report.files = files
    
    -- Check for required files
    local has_info_json = false
    for _, file in ipairs(files) do
        if file:match("info%.json$") then
            has_info_json = true
            break
        end
    end
    
    if not has_info_json then
        table.insert(report.errors, "Missing info.json in archive")
        return report
    end
    report.structure_valid = true
    
    -- Parse info.json
    local info_content, err = zip.read_file(zip_path, "info.json")
    if not info_content then
        table.insert(report.errors, "Failed to read info.json: " .. tostring(err))
        return report
    end
    
    -- Validate JSON syntax
    local success, info_data = pcall(json.parse, info_content)
    if not success then
        table.insert(report.errors, "Invalid JSON in info.json: " .. tostring(info_data))
        return report
    end
    
    -- Validate required fields
    local required_fields = {"name", "version", "title", "author", "factorio_version"}
    for _, field in ipairs(required_fields) do
        if not info_data[field] then
            table.insert(report.warnings, "Missing recommended field in info.json: " .. field)
        end
    end
    
    report.info_valid = true
    report.info_data = info_data
    report.valid = true
    
    return report
end

return native_libs
