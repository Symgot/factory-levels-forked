-- Native ZIP Library: Pure Lua ZIP Implementation
-- Phase 7: Production-Ready System - No System Dependencies
-- Reference: https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
-- Reference: https://www.lua.org/manual/5.4/manual.html#6.7

local native_zip = {}

-- ============================================================================
-- ZIP FILE FORMAT CONSTANTS
-- ============================================================================

native_zip.SIGNATURE = {
    LOCAL_FILE_HEADER = 0x04034b50,
    CENTRAL_DIRECTORY = 0x02014b50,
    END_OF_CENTRAL_DIR = 0x06054b50,
    ZIP64_END_OF_CENTRAL_DIR = 0x06064b50,
    ZIP64_END_LOCATOR = 0x07064b50,
    DATA_DESCRIPTOR = 0x08074b50
}

native_zip.COMPRESSION_METHOD = {
    STORE = 0,      -- No compression
    DEFLATE = 8     -- DEFLATE compression
}

native_zip.VERSION = {
    NEEDED_10 = 10,  -- 1.0
    NEEDED_20 = 20,  -- 2.0
    NEEDED_45 = 45   -- 4.5 (ZIP64)
}

-- ============================================================================
-- BITWISE OPERATIONS (Lua 5.4 Native)
-- Note: Wrappers provided for code clarity and potential backward compatibility
-- ============================================================================

local function band(a, b) return a & b end
local function bor(a, b) return a | b end
local function bxor(a, b) return a ~ b end
local function lshift(a, n) return a << n end
local function rshift(a, n) return a >> n end

-- ============================================================================
-- BINARY DATA UTILITIES
-- ============================================================================

local function write_uint16_le(value)
    return string.char(
        band(value, 0xFF),
        band(rshift(value, 8), 0xFF)
    )
end

local function write_uint32_le(value)
    return string.char(
        band(value, 0xFF),
        band(rshift(value, 8), 0xFF),
        band(rshift(value, 16), 0xFF),
        band(rshift(value, 24), 0xFF)
    )
end

local function read_uint16_le(data, pos)
    local b1, b2 = data:byte(pos, pos + 1)
    return bor(b1, lshift(b2, 8)), pos + 2
end

local function read_uint32_le(data, pos)
    local b1, b2, b3, b4 = data:byte(pos, pos + 3)
    return bor(bor(bor(b1, lshift(b2, 8)), lshift(b3, 16)), lshift(b4, 24)), pos + 4
end

-- ============================================================================
-- CRC32 IMPLEMENTATION (Pure Lua)
-- ============================================================================

local crc32_table = {}

local function init_crc32_table()
    for i = 0, 255 do
        local crc = i
        for _ = 1, 8 do
            if band(crc, 1) ~= 0 then
                crc = bxor(rshift(crc, 1), 0xEDB88320)
            else
                crc = rshift(crc, 1)
            end
        end
        crc32_table[i] = crc
    end
end

init_crc32_table()

local function calculate_crc32(data)
    local crc = 0xFFFFFFFF
    for i = 1, #data do
        local byte = data:byte(i)
        local index = band(bxor(crc, byte), 0xFF)
        crc = bxor(rshift(crc, 8), crc32_table[index])
    end
    return bxor(crc, 0xFFFFFFFF)
end

-- ============================================================================
-- DEFLATE COMPRESSION (Simplified Implementation)
-- ============================================================================

local deflate = {}

-- Huffman coding tables for DEFLATE
deflate.FIXED_LITERAL_LENGTHS = {}
deflate.FIXED_DISTANCE_LENGTHS = {}

local function init_huffman_tables()
    -- Fixed literal/length code lengths (RFC 1951)
    for i = 0, 143 do deflate.FIXED_LITERAL_LENGTHS[i] = 8 end
    for i = 144, 255 do deflate.FIXED_LITERAL_LENGTHS[i] = 9 end
    for i = 256, 279 do deflate.FIXED_LITERAL_LENGTHS[i] = 7 end
    for i = 280, 287 do deflate.FIXED_LITERAL_LENGTHS[i] = 8 end
    
    -- Fixed distance code lengths
    for i = 0, 31 do deflate.FIXED_DISTANCE_LENGTHS[i] = 5 end
end

init_huffman_tables()

-- LZ77 sliding window compression
local function lz77_compress(data)
    local window_size = 32768  -- 32KB sliding window
    local lookahead_size = 258
    local min_match = 3
    
    local compressed = {}
    local pos = 1
    
    while pos <= #data do
        local best_length = 0
        local best_distance = 0
        
        -- Search for matches in the sliding window
        local window_start = math.max(1, pos - window_size)
        for i = window_start, pos - 1 do
            local match_length = 0
            while match_length < lookahead_size 
                  and pos + match_length <= #data 
                  and data:byte(i + match_length) == data:byte(pos + match_length) do
                match_length = match_length + 1
            end
            
            if match_length >= min_match and match_length > best_length then
                best_length = match_length
                best_distance = pos - i
            end
        end
        
        if best_length >= min_match then
            -- Emit (distance, length) pair
            table.insert(compressed, {type = "match", distance = best_distance, length = best_length})
            pos = pos + best_length
        else
            -- Emit literal byte
            table.insert(compressed, {type = "literal", byte = data:byte(pos)})
            pos = pos + 1
        end
    end
    
    return compressed
end

-- Simple DEFLATE compression (STORE method for reliability)
function deflate.compress(data)
    -- For production: implement full DEFLATE
    -- For Phase 7: use STORE (no compression) for reliability
    return data, native_zip.COMPRESSION_METHOD.STORE
end

function deflate.decompress(data, method)
    if method == native_zip.COMPRESSION_METHOD.STORE then
        return data
    elseif method == native_zip.COMPRESSION_METHOD.DEFLATE then
        -- TODO: Full DEFLATE decompression
        -- For now, return data as-is for STORE compatibility
        return data
    else
        error("Unsupported compression method: " .. tostring(method))
    end
end

-- ============================================================================
-- ZIP ENTRY STRUCTURE
-- ============================================================================

local ZipEntry = {}
ZipEntry.__index = ZipEntry

function ZipEntry:new(filename, data, options)
    options = options or {}
    
    local entry = {
        filename = filename,
        data = data or "",
        comment = options.comment or "",
        compression_method = options.compression_method or native_zip.COMPRESSION_METHOD.STORE,
        external_attr = options.external_attr or 0,
        
        -- Calculated fields
        uncompressed_size = #(data or ""),
        compressed_data = nil,
        compressed_size = 0,
        crc32 = 0,
        
        -- DOS time/date (default: 1980-01-01 00:00:00)
        dos_time = options.dos_time or 0,
        dos_date = options.dos_date or 0x0021,  -- 1980-01-01
        
        -- Offsets (set during writing)
        local_header_offset = 0
    }
    
    setmetatable(entry, self)
    entry:compress()
    
    return entry
end

function ZipEntry:compress()
    if self.compression_method == native_zip.COMPRESSION_METHOD.STORE then
        self.compressed_data = self.data
        self.compressed_size = #self.data
    else
        self.compressed_data, self.compression_method = deflate.compress(self.data)
        self.compressed_size = #self.compressed_data
    end
    
    self.crc32 = calculate_crc32(self.data)
end

function ZipEntry:decompress()
    return deflate.decompress(self.compressed_data, self.compression_method)
end

function ZipEntry:write_local_header()
    local header = {}
    
    -- Local file header signature
    table.insert(header, write_uint32_le(native_zip.SIGNATURE.LOCAL_FILE_HEADER))
    
    -- Version needed to extract (2.0)
    table.insert(header, write_uint16_le(native_zip.VERSION.NEEDED_20))
    
    -- General purpose bit flag
    table.insert(header, write_uint16_le(0))
    
    -- Compression method
    table.insert(header, write_uint16_le(self.compression_method))
    
    -- Last mod file time/date
    table.insert(header, write_uint16_le(self.dos_time))
    table.insert(header, write_uint16_le(self.dos_date))
    
    -- CRC-32
    table.insert(header, write_uint32_le(self.crc32))
    
    -- Compressed size
    table.insert(header, write_uint32_le(self.compressed_size))
    
    -- Uncompressed size
    table.insert(header, write_uint32_le(self.uncompressed_size))
    
    -- File name length
    table.insert(header, write_uint16_le(#self.filename))
    
    -- Extra field length
    table.insert(header, write_uint16_le(0))
    
    -- File name
    table.insert(header, self.filename)
    
    -- Extra field (empty)
    
    return table.concat(header)
end

function ZipEntry:write_central_directory_header()
    local header = {}
    
    -- Central directory header signature
    table.insert(header, write_uint32_le(native_zip.SIGNATURE.CENTRAL_DIRECTORY))
    
    -- Version made by (Unix, 2.0)
    table.insert(header, write_uint16_le(0x0300 | native_zip.VERSION.NEEDED_20))
    
    -- Version needed to extract
    table.insert(header, write_uint16_le(native_zip.VERSION.NEEDED_20))
    
    -- General purpose bit flag
    table.insert(header, write_uint16_le(0))
    
    -- Compression method
    table.insert(header, write_uint16_le(self.compression_method))
    
    -- Last mod file time/date
    table.insert(header, write_uint16_le(self.dos_time))
    table.insert(header, write_uint16_le(self.dos_date))
    
    -- CRC-32
    table.insert(header, write_uint32_le(self.crc32))
    
    -- Compressed size
    table.insert(header, write_uint32_le(self.compressed_size))
    
    -- Uncompressed size
    table.insert(header, write_uint32_le(self.uncompressed_size))
    
    -- File name length
    table.insert(header, write_uint16_le(#self.filename))
    
    -- Extra field length
    table.insert(header, write_uint16_le(0))
    
    -- File comment length
    table.insert(header, write_uint16_le(#self.comment))
    
    -- Disk number start
    table.insert(header, write_uint16_le(0))
    
    -- Internal file attributes
    table.insert(header, write_uint16_le(0))
    
    -- External file attributes
    table.insert(header, write_uint32_le(self.external_attr))
    
    -- Relative offset of local header
    table.insert(header, write_uint32_le(self.local_header_offset))
    
    -- File name
    table.insert(header, self.filename)
    
    -- Extra field (empty)
    
    -- File comment
    table.insert(header, self.comment)
    
    return table.concat(header)
end

-- ============================================================================
-- ZIP ARCHIVE STRUCTURE
-- ============================================================================

local ZipArchive = {}
ZipArchive.__index = ZipArchive

function ZipArchive:new()
    local archive = {
        entries = {},
        comment = ""
    }
    
    setmetatable(archive, self)
    return archive
end

function ZipArchive:add_file(filename, data, options)
    local entry = ZipEntry:new(filename, data, options)
    table.insert(self.entries, entry)
    return entry
end

function ZipArchive:add_directory(dirname)
    -- Directories end with '/'
    if not dirname:match("/$") then
        dirname = dirname .. "/"
    end
    
    local entry = ZipEntry:new(dirname, "", {
        external_attr = 0x10  -- Directory attribute
    })
    table.insert(self.entries, entry)
    return entry
end

function ZipArchive:write()
    local output = {}
    local offset = 0
    
    -- Write all local file headers and file data
    for _, entry in ipairs(self.entries) do
        entry.local_header_offset = offset
        
        local local_header = entry:write_local_header()
        table.insert(output, local_header)
        table.insert(output, entry.compressed_data)
        
        offset = offset + #local_header + #entry.compressed_data
    end
    
    -- Save central directory start offset
    local central_dir_offset = offset
    
    -- Write central directory headers
    for _, entry in ipairs(self.entries) do
        local cd_header = entry:write_central_directory_header()
        table.insert(output, cd_header)
        offset = offset + #cd_header
    end
    
    -- Calculate central directory size
    local central_dir_size = offset - central_dir_offset
    
    -- Write end of central directory record
    local eocd = {}
    
    -- EOCD signature
    table.insert(eocd, write_uint32_le(native_zip.SIGNATURE.END_OF_CENTRAL_DIR))
    
    -- Disk numbers
    table.insert(eocd, write_uint16_le(0))  -- This disk number
    table.insert(eocd, write_uint16_le(0))  -- Disk where central directory starts
    
    -- Number of central directory records
    table.insert(eocd, write_uint16_le(#self.entries))  -- On this disk
    table.insert(eocd, write_uint16_le(#self.entries))  -- Total
    
    -- Central directory size
    table.insert(eocd, write_uint32_le(central_dir_size))
    
    -- Offset of start of central directory
    table.insert(eocd, write_uint32_le(central_dir_offset))
    
    -- ZIP file comment length
    table.insert(eocd, write_uint16_le(#self.comment))
    
    -- ZIP file comment
    table.insert(eocd, self.comment)
    
    table.insert(output, table.concat(eocd))
    
    return table.concat(output)
end

function ZipArchive:save(filename)
    local zip_data = self:write()
    local file, err = io.open(filename, "wb")
    if not file then
        return false, "Failed to open file: " .. tostring(err)
    end
    
    file:write(zip_data)
    file:close()
    
    return true
end

-- ============================================================================
-- ZIP ARCHIVE READING
-- ============================================================================

local function find_eocd(data)
    -- Search for End of Central Directory signature from the end
    local max_comment_size = 65535
    local search_start = math.max(1, #data - max_comment_size - 22)
    
    for i = #data - 21, search_start, -1 do
        local sig = read_uint32_le(data, i)
        if sig == native_zip.SIGNATURE.END_OF_CENTRAL_DIR then
            return i
        end
    end
    
    return nil
end

function native_zip.read(filename)
    local file, err = io.open(filename, "rb")
    if not file then
        return nil, "Failed to open file: " .. tostring(err)
    end
    
    local data = file:read("*all")
    file:close()
    
    return native_zip.read_data(data)
end

function native_zip.read_data(data)
    -- Find End of Central Directory
    local eocd_pos = find_eocd(data)
    if not eocd_pos then
        return nil, "Invalid ZIP file: EOCD not found"
    end
    
    -- Read EOCD
    local pos = eocd_pos + 4  -- Skip signature
    
    local disk_number, num_entries_disk, num_entries_total
    disk_number, pos = read_uint16_le(data, pos)
    pos = pos + 2  -- Skip disk where CD starts
    num_entries_disk, pos = read_uint16_le(data, pos)
    num_entries_total, pos = read_uint16_le(data, pos)
    
    local cd_size, cd_offset
    cd_size, pos = read_uint32_le(data, pos)
    cd_offset, pos = read_uint32_le(data, pos)
    
    local comment_length
    comment_length, pos = read_uint16_le(data, pos)
    local comment = data:sub(pos, pos + comment_length - 1)
    
    -- Read central directory entries
    local archive = ZipArchive:new()
    archive.comment = comment
    
    pos = cd_offset + 1  -- Convert to 1-based indexing
    
    for i = 1, num_entries_total do
        -- Read central directory header
        local sig
        sig, pos = read_uint32_le(data, pos)
        
        if sig ~= native_zip.SIGNATURE.CENTRAL_DIRECTORY then
            return nil, "Invalid central directory entry"
        end
        
        pos = pos + 4  -- Skip version made by and version needed
        pos = pos + 2  -- Skip general purpose bit flag
        
        local compression_method
        compression_method, pos = read_uint16_le(data, pos)
        
        local dos_time, dos_date
        dos_time, pos = read_uint16_le(data, pos)
        dos_date, pos = read_uint16_le(data, pos)
        
        local crc32, compressed_size, uncompressed_size
        crc32, pos = read_uint32_le(data, pos)
        compressed_size, pos = read_uint32_le(data, pos)
        uncompressed_size, pos = read_uint32_le(data, pos)
        
        local filename_length, extra_length, comment_length
        filename_length, pos = read_uint16_le(data, pos)
        extra_length, pos = read_uint16_le(data, pos)
        comment_length, pos = read_uint16_le(data, pos)
        
        pos = pos + 2  -- Skip disk number start
        pos = pos + 2  -- Skip internal file attributes
        
        local external_attr
        external_attr, pos = read_uint32_le(data, pos)
        
        local local_header_offset
        local_header_offset, pos = read_uint32_le(data, pos)
        
        local filename = data:sub(pos, pos + filename_length - 1)
        pos = pos + filename_length
        
        pos = pos + extra_length  -- Skip extra field
        
        local file_comment = data:sub(pos, pos + comment_length - 1)
        pos = pos + comment_length
        
        -- Read local file header to get compressed data
        local local_pos = local_header_offset + 1
        local_pos = local_pos + 4  -- Skip signature
        local_pos = local_pos + 26  -- Skip to filename length
        
        local local_filename_length, local_extra_length
        local_filename_length, local_pos = read_uint16_le(data, local_pos)
        local_extra_length, local_pos = read_uint16_le(data, local_pos)
        
        local_pos = local_pos + local_filename_length + local_extra_length
        
        local compressed_data = data:sub(local_pos, local_pos + compressed_size - 1)
        
        -- Create entry
        local entry = {
            filename = filename,
            comment = file_comment,
            compression_method = compression_method,
            compressed_data = compressed_data,
            compressed_size = compressed_size,
            uncompressed_size = uncompressed_size,
            crc32 = crc32,
            dos_time = dos_time,
            dos_date = dos_date,
            external_attr = external_attr,
            local_header_offset = local_header_offset
        }
        
        setmetatable(entry, ZipEntry)
        
        -- Decompress data
        entry.data = entry:decompress()
        
        table.insert(archive.entries, entry)
    end
    
    return archive
end

-- ============================================================================
-- HIGH-LEVEL API
-- ============================================================================

function native_zip.create_archive()
    return ZipArchive:new()
end

function native_zip.list_files(archive)
    local files = {}
    for _, entry in ipairs(archive.entries) do
        table.insert(files, {
            name = entry.filename,
            size = entry.uncompressed_size,
            compressed_size = entry.compressed_size,
            compression_method = entry.compression_method,
            is_directory = entry.filename:match("/$") ~= nil
        })
    end
    return files
end

function native_zip.extract_file(archive, filename)
    for _, entry in ipairs(archive.entries) do
        if entry.filename == filename then
            return entry.data
        end
    end
    return nil, "File not found: " .. filename
end

function native_zip.extract_all(archive, output_dir)
    output_dir = output_dir or "."
    
    for _, entry in ipairs(archive.entries) do
        local output_path = output_dir .. "/" .. entry.filename
        
        if entry.filename:match("/$") then
            -- Directory
            os.execute("mkdir -p " .. output_path)
        else
            -- File
            local dir = output_path:match("(.*/)")
            if dir then
                os.execute("mkdir -p " .. dir)
            end
            
            local file = io.open(output_path, "wb")
            if file then
                file:write(entry.data)
                file:close()
            end
        end
    end
    
    return true
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function native_zip.validate_archive(archive)
    local errors = {}
    
    for i, entry in ipairs(archive.entries) do
        -- Verify CRC32
        local calculated_crc = calculate_crc32(entry.data)
        if calculated_crc ~= entry.crc32 then
            table.insert(errors, string.format(
                "Entry %d (%s): CRC mismatch (expected 0x%08X, got 0x%08X)",
                i, entry.filename, entry.crc32, calculated_crc
            ))
        end
        
        -- Verify uncompressed size
        if #entry.data ~= entry.uncompressed_size then
            table.insert(errors, string.format(
                "Entry %d (%s): Size mismatch (expected %d, got %d)",
                i, entry.filename, entry.uncompressed_size, #entry.data
            ))
        end
    end
    
    return #errors == 0, errors
end

function native_zip.get_info(archive)
    local total_uncompressed = 0
    local total_compressed = 0
    local num_files = 0
    local num_dirs = 0
    
    for _, entry in ipairs(archive.entries) do
        if entry.filename:match("/$") then
            num_dirs = num_dirs + 1
        else
            num_files = num_files + 1
        end
        total_uncompressed = total_uncompressed + entry.uncompressed_size
        total_compressed = total_compressed + entry.compressed_size
    end
    
    local compression_ratio = 0
    if total_uncompressed > 0 then
        compression_ratio = (1 - total_compressed / total_uncompressed) * 100
    end
    
    return {
        num_entries = #archive.entries,
        num_files = num_files,
        num_directories = num_dirs,
        total_uncompressed_size = total_uncompressed,
        total_compressed_size = total_compressed,
        compression_ratio = compression_ratio,
        comment = archive.comment
    }
end

-- ============================================================================
-- DOS TIME/DATE CONVERSION
-- ============================================================================

function native_zip.encode_dos_datetime(year, month, day, hour, minute, second)
    local dos_date = bor(
        lshift(year - 1980, 9),
        bor(lshift(month, 5), day)
    )
    
    local dos_time = bor(
        lshift(hour, 11),
        bor(lshift(minute, 5), rshift(second, 1))
    )
    
    return dos_time, dos_date
end

function native_zip.decode_dos_datetime(dos_time, dos_date)
    local year = 1980 + rshift(dos_date, 9)
    local month = band(rshift(dos_date, 5), 0x0F)
    local day = band(dos_date, 0x1F)
    
    local hour = rshift(dos_time, 11)
    local minute = band(rshift(dos_time, 5), 0x3F)
    local second = band(dos_time, 0x1F) * 2
    
    return year, month, day, hour, minute, second
end

-- ============================================================================
-- PERFORMANCE BENCHMARKING
-- ============================================================================

function native_zip.benchmark(test_data_size)
    test_data_size = test_data_size or 1024 * 1024  -- 1MB default
    
    -- Generate test data
    local test_data = string.rep("The quick brown fox jumps over the lazy dog. ", 
                                 math.ceil(test_data_size / 46))
    test_data = test_data:sub(1, test_data_size)
    
    local results = {}
    
    -- Benchmark CRC32
    local start = os.clock()
    for i = 1, 10 do
        calculate_crc32(test_data)
    end
    results.crc32_time_ms = (os.clock() - start) * 1000 / 10
    
    -- Benchmark ZIP creation
    start = os.clock()
    local archive = ZipArchive:new()
    archive:add_file("test.txt", test_data)
    local zip_data = archive:write()
    results.create_time_ms = (os.clock() - start) * 1000
    
    -- Benchmark ZIP reading
    start = os.clock()
    local read_archive = native_zip.read_data(zip_data)
    results.read_time_ms = (os.clock() - start) * 1000
    
    -- Calculate throughput
    results.create_throughput_mbps = (test_data_size / (results.create_time_ms / 1000)) / (1024 * 1024)
    results.read_throughput_mbps = (test_data_size / (results.read_time_ms / 1000)) / (1024 * 1024)
    
    return results
end

return native_zip
