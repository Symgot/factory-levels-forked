-- Bytecode Analyzer for Lua Bytecode Reverse Engineering
-- Phase 6: Bytecode Analysis and Decompilation
-- Reference: https://the-ravi-programming-language.readthedocs.io/en/latest/lua_bytecode_reference.html
-- Reference: https://par.nsf.gov/servlets/purl/10540556

local bytecode_analyzer = {}

-- ============================================================================
-- LUA BYTECODE CONSTANTS
-- ============================================================================

-- Lua 5.4 Opcodes
bytecode_analyzer.OPCODES = {
    [0]  = "MOVE",
    [1]  = "LOADI",
    [2]  = "LOADF",
    [3]  = "LOADK",
    [4]  = "LOADKX",
    [5]  = "LOADFALSE",
    [6]  = "LFALSESKIP",
    [7]  = "LOADTRUE",
    [8]  = "LOADNIL",
    [9]  = "GETUPVAL",
    [10] = "SETUPVAL",
    [11] = "GETTABUP",
    [12] = "GETTABLE",
    [13] = "GETI",
    [14] = "GETFIELD",
    [15] = "SETTABUP",
    [16] = "SETTABLE",
    [17] = "SETI",
    [18] = "SETFIELD",
    [19] = "NEWTABLE",
    [20] = "SELF",
    [21] = "ADDI",
    [22] = "ADDK",
    [23] = "SUBK",
    [24] = "MULK",
    [25] = "MODK",
    [26] = "POWK",
    [27] = "DIVK",
    [28] = "IDIVK",
    [29] = "BANDK",
    [30] = "BORK",
    [31] = "BXORK",
    [32] = "SHRI",
    [33] = "SHLI",
    [34] = "ADD",
    [35] = "SUB",
    [36] = "MUL",
    [37] = "MOD",
    [38] = "POW",
    [39] = "DIV",
    [40] = "IDIV",
    [41] = "BAND",
    [42] = "BOR",
    [43] = "BXOR",
    [44] = "SHL",
    [45] = "SHR",
    [46] = "MMBIN",
    [47] = "MMBINI",
    [48] = "MMBINK",
    [49] = "UNM",
    [50] = "BNOT",
    [51] = "NOT",
    [52] = "LEN",
    [53] = "CONCAT",
    [54] = "CLOSE",
    [55] = "TBC",
    [56] = "JMP",
    [57] = "EQ",
    [58] = "LT",
    [59] = "LE",
    [60] = "EQK",
    [61] = "EQI",
    [62] = "LTI",
    [63] = "LEI",
    [64] = "GTI",
    [65] = "GEI",
    [66] = "TEST",
    [67] = "TESTSET",
    [68] = "CALL",
    [69] = "TAILCALL",
    [70] = "RETURN",
    [71] = "RETURN0",
    [72] = "RETURN1",
    [73] = "FORLOOP",
    [74] = "FORPREP",
    [75] = "TFORPREP",
    [76] = "TFORCALL",
    [77] = "TFORLOOP",
    [78] = "SETLIST",
    [79] = "CLOSURE",
    [80] = "VARARG",
    [81] = "VARARGPREP",
    [82] = "EXTRAARG"
}

-- Lua header signature
bytecode_analyzer.LUA_SIGNATURE = "\x1bLua"
bytecode_analyzer.LUAC_VERSION = 0x54  -- Lua 5.4
bytecode_analyzer.LUAC_FORMAT = 0

-- ============================================================================
-- BYTECODE LOADING
-- ============================================================================

-- Load Lua bytecode file
-- @param filepath string: Path to .luac file
-- @return table: Bytecode structure
-- @return string: Error message if failed
function bytecode_analyzer.load_luac_file(filepath)
    local file, err = io.open(filepath, "rb")
    if not file then
        return nil, "Failed to open file: " .. tostring(err)
    end
    
    local content = file:read("*all")
    file:close()
    
    if #content < 4 then
        return nil, "File too small to be valid Lua bytecode"
    end
    
    -- Check signature
    local signature = content:sub(1, 4)
    if signature ~= bytecode_analyzer.LUA_SIGNATURE then
        return nil, "Invalid Lua bytecode signature"
    end
    
    local bytecode = {
        raw = content,
        signature = signature,
        version = content:byte(5),
        format = content:byte(6),
        data = content:sub(7),
        valid = true
    }
    
    return bytecode, nil
end

-- ============================================================================
-- BYTECODE ANALYSIS
-- ============================================================================

-- Analyze bytecode structure
-- @param bytecode table: Loaded bytecode
-- @return table: Analysis results
function bytecode_analyzer.analyze_bytecode(bytecode)
    if not bytecode or not bytecode.valid then
        return {
            valid = false,
            error = "Invalid bytecode"
        }
    end
    
    local analysis = {
        valid = true,
        version = bytecode.version,
        format = bytecode.format,
        size = #bytecode.raw,
        header = {
            signature = bytecode.signature,
            version = bytecode.version,
            format = bytecode.format
        },
        functions = {},
        constants = {},
        upvalues = {},
        instructions = {},
        statistics = {
            num_functions = 0,
            num_constants = 0,
            num_upvalues = 0,
            num_instructions = 0
        }
    }
    
    -- Parse header information
    if bytecode.version ~= bytecode_analyzer.LUAC_VERSION then
        analysis.warnings = analysis.warnings or {}
        table.insert(analysis.warnings, string.format("Bytecode version mismatch: expected 0x%02X, got 0x%02X", 
            bytecode_analyzer.LUAC_VERSION, bytecode.version))
    end
    
    -- Simplified instruction extraction (actual parsing would be much more complex)
    local data = bytecode.data
    if data and #data > 0 then
        local pos = 1
        
        -- Extract instructions (simplified - real implementation would decode full format)
        while pos <= #data do
            if pos + 4 <= #data then
                local instr = string.unpack("<I4", data, pos)
                local opcode = instr & 0x7F
                local opname = bytecode_analyzer.OPCODES[opcode] or "UNKNOWN"
                
                table.insert(analysis.instructions, {
                    offset = pos - 1,
                    opcode = opcode,
                    opname = opname,
                    raw = instr
                })
                
                analysis.statistics.num_instructions = analysis.statistics.num_instructions + 1
                pos = pos + 4
            else
                break
            end
        end
    end
    
    return analysis
end

-- ============================================================================
-- OBFUSCATION DETECTION
-- ============================================================================

-- Obfuscation detection thresholds
-- Based on empirical analysis of obfuscated vs clean Lua bytecode
local OBFUSCATION_THRESHOLDS = {
    -- High instruction entropy indicates randomized or encrypted opcodes
    -- Normal code: 2-4 bits, obfuscated: >4.5 bits
    ENTROPY_THRESHOLD = 4.5,
    
    -- Jump ratio > 30% suggests control flow obfuscation
    -- Normal code: 10-20%, obfuscated: >30%
    JUMP_RATIO_THRESHOLD = 0.3,
    
    -- Confidence levels for final determination
    MIN_CONFIDENCE = 50  -- 50% confidence to flag as obfuscated
}

-- Detect obfuscation in bytecode
-- @param bytecode table: Loaded bytecode
-- @return boolean: Likely obfuscated
-- @return table: Detection details
function bytecode_analyzer.analyze_obfuscation(bytecode)
    local detection = {
        likely_obfuscated = false,
        confidence = 0,
        indicators = {},
        techniques = {}
    }
    
    if not bytecode or not bytecode.valid then
        detection.error = "Invalid bytecode"
        return false, detection
    end
    
    local analysis = bytecode_analyzer.analyze_bytecode(bytecode)
    
    -- Check for unusual instruction patterns
    local instruction_entropy = 0
    local opcode_counts = {}
    
    for _, instr in ipairs(analysis.instructions) do
        opcode_counts[instr.opcode] = (opcode_counts[instr.opcode] or 0) + 1
    end
    
    -- Calculate Shannon entropy of instruction distribution
    local total_instructions = #analysis.instructions
    if total_instructions > 0 then
        for opcode, count in pairs(opcode_counts) do
            local p = count / total_instructions
            instruction_entropy = instruction_entropy - (p * math.log(p, 2))
        end
    end
    
    -- High entropy suggests obfuscation
    if instruction_entropy > OBFUSCATION_THRESHOLDS.ENTROPY_THRESHOLD then
        detection.likely_obfuscated = true
        detection.confidence = detection.confidence + 30
        table.insert(detection.indicators, "High instruction entropy: " .. string.format("%.2f", instruction_entropy))
    end
    
    -- Check for excessive jumps (control flow obfuscation)
    local jump_opcodes = {56, 73, 74, 75, 77}  -- JMP, FORLOOP, FORPREP, TFORPREP, TFORLOOP
    local jump_count = 0
    for _, instr in ipairs(analysis.instructions) do
        for _, jmp_op in ipairs(jump_opcodes) do
            if instr.opcode == jmp_op then
                jump_count = jump_count + 1
                break
            end
        end
    end
    
    local jump_ratio = total_instructions > 0 and (jump_count / total_instructions) or 0
    if jump_ratio > OBFUSCATION_THRESHOLDS.JUMP_RATIO_THRESHOLD then
        detection.likely_obfuscated = true
        detection.confidence = detection.confidence + 25
        table.insert(detection.indicators, string.format("High jump ratio: %.2f%%", jump_ratio * 100))
        table.insert(detection.techniques, "Control flow obfuscation")
    end
    
    -- Check for unusual constant patterns
    if analysis.statistics.num_constants > analysis.statistics.num_instructions * 2 then
        detection.confidence = detection.confidence + 15
        table.insert(detection.indicators, "Excessive constants")
        table.insert(detection.techniques, "String/constant encryption")
    end
    
    -- Check file size anomalies (padding or embedded data)
    local expected_size = analysis.statistics.num_instructions * 4 + 100  -- 4 bytes per instruction + header
    local bytecode_size = bytecode.size or #(bytecode.raw or "")
    if bytecode_size > expected_size * 3 then  -- 3x larger than expected
        detection.confidence = detection.confidence + 20
        table.insert(detection.indicators, "Unusually large file size")
        table.insert(detection.techniques, "Data padding or embedded resources")
    end
    
    -- Determine if obfuscated based on confidence threshold
    detection.likely_obfuscated = detection.confidence >= OBFUSCATION_THRESHOLDS.MIN_CONFIDENCE
    
    return detection.likely_obfuscated, detection
end

-- ============================================================================
-- DECOMPILATION
-- ============================================================================

-- Decompile bytecode to pseudo-Lua source
-- @param bytecode table: Loaded bytecode
-- @return string: Decompiled source
-- @return string: Error message if failed
function bytecode_analyzer.decompile_bytecode(bytecode)
    if not bytecode or not bytecode.valid then
        return nil, "Invalid bytecode"
    end
    
    local analysis = bytecode_analyzer.analyze_bytecode(bytecode)
    local source_lines = {
        "-- Decompiled from Lua 5.4 bytecode",
        "-- This is a simplified representation",
        ""
    }
    
    -- Generate pseudo-source from instructions
    table.insert(source_lines, "function main()")
    
    for i, instr in ipairs(analysis.instructions) do
        local line = string.format("  -- [%04d] %s (0x%02X)", i - 1, instr.opname, instr.opcode)
        table.insert(source_lines, line)
        
        -- Generate simplified Lua equivalent for common opcodes
        if instr.opname == "LOADK" then
            table.insert(source_lines, "  -- local var = constant")
        elseif instr.opname == "GETTABUP" then
            table.insert(source_lines, "  -- var = _ENV[key]")
        elseif instr.opname == "CALL" then
            table.insert(source_lines, "  -- result = func(args)")
        elseif instr.opname == "RETURN" then
            table.insert(source_lines, "  -- return values")
        elseif instr.opname == "JMP" then
            table.insert(source_lines, "  -- goto label")
        end
    end
    
    table.insert(source_lines, "end")
    table.insert(source_lines, "")
    table.insert(source_lines, "main()")
    
    return table.concat(source_lines, "\n"), nil
end

-- ============================================================================
-- INTEGRITY VERIFICATION
-- ============================================================================

-- Verify bytecode integrity
-- @param bytecode table: Loaded bytecode
-- @return boolean: Valid
-- @return table: Verification details
function bytecode_analyzer.verify_integrity(bytecode)
    local verification = {
        valid = false,
        checks = {},
        errors = {},
        warnings = {}
    }
    
    if not bytecode then
        table.insert(verification.errors, "Bytecode is nil")
        return false, verification
    end
    
    -- Check signature
    if bytecode.signature == bytecode_analyzer.LUA_SIGNATURE then
        table.insert(verification.checks, "✓ Valid Lua signature")
    else
        table.insert(verification.errors, "✗ Invalid Lua signature")
        return false, verification
    end
    
    -- Check version
    if bytecode.version == bytecode_analyzer.LUAC_VERSION then
        table.insert(verification.checks, "✓ Lua 5.4 bytecode")
    else
        table.insert(verification.warnings, string.format("⚠ Version mismatch: 0x%02X (expected 0x%02X)", 
            bytecode.version, bytecode_analyzer.LUAC_VERSION))
    end
    
    -- Check format
    if bytecode.format == bytecode_analyzer.LUAC_FORMAT then
        table.insert(verification.checks, "✓ Standard format")
    else
        table.insert(verification.warnings, "⚠ Non-standard format")
    end
    
    -- Check minimum size
    if #bytecode.raw >= 12 then
        table.insert(verification.checks, "✓ Sufficient size")
    else
        table.insert(verification.errors, "✗ File too small")
        return false, verification
    end
    
    -- Analyze structure
    local analysis = bytecode_analyzer.analyze_bytecode(bytecode)
    if analysis.valid then
        table.insert(verification.checks, string.format("✓ %d instructions decoded", 
            analysis.statistics.num_instructions))
    else
        table.insert(verification.errors, "✗ Failed to analyze bytecode structure")
        return false, verification
    end
    
    verification.valid = #verification.errors == 0
    return verification.valid, verification
end

-- ============================================================================
-- HIGH-LEVEL ANALYSIS FUNCTIONS
-- ============================================================================

-- Complete bytecode analysis workflow
-- @param filepath string: Path to .luac file
-- @return table: Complete analysis report
function bytecode_analyzer.analyze_file(filepath)
    local report = {
        filepath = filepath,
        success = false,
        bytecode = nil,
        analysis = nil,
        obfuscation = nil,
        integrity = nil,
        decompiled = nil,
        errors = {}
    }
    
    -- Load bytecode
    local bytecode, err = bytecode_analyzer.load_luac_file(filepath)
    if not bytecode then
        table.insert(report.errors, err)
        return report
    end
    report.bytecode = bytecode
    
    -- Verify integrity
    local valid, verification = bytecode_analyzer.verify_integrity(bytecode)
    report.integrity = verification
    if not valid then
        table.insert(report.errors, "Integrity verification failed")
        return report
    end
    
    -- Analyze structure
    report.analysis = bytecode_analyzer.analyze_bytecode(bytecode)
    
    -- Check obfuscation
    local obfuscated, detection = bytecode_analyzer.analyze_obfuscation(bytecode)
    report.obfuscation = detection
    
    -- Attempt decompilation
    local source, err = bytecode_analyzer.decompile_bytecode(bytecode)
    if source then
        report.decompiled = source
    else
        table.insert(report.errors, "Decompilation failed: " .. tostring(err))
    end
    
    report.success = #report.errors == 0
    return report
end

-- Generate human-readable report
-- @param report table: Analysis report
-- @return string: Formatted report
function bytecode_analyzer.format_report(report)
    local lines = {
        "=" .. string.rep("=", 78),
        "Lua Bytecode Analysis Report",
        "=" .. string.rep("=", 78),
        "",
        "File: " .. report.filepath,
        "Status: " .. (report.success and "✓ Success" or "✗ Failed"),
        ""
    }
    
    if report.integrity then
        table.insert(lines, "Integrity Verification:")
        for _, check in ipairs(report.integrity.checks) do
            table.insert(lines, "  " .. check)
        end
        for _, warning in ipairs(report.integrity.warnings) do
            table.insert(lines, "  " .. warning)
        end
        for _, error in ipairs(report.integrity.errors) do
            table.insert(lines, "  " .. error)
        end
        table.insert(lines, "")
    end
    
    if report.analysis then
        table.insert(lines, "Bytecode Structure:")
        table.insert(lines, string.format("  Version: 0x%02X (Lua %s)", 
            report.analysis.version, 
            report.analysis.version == 0x54 and "5.4" or "other"))
        table.insert(lines, string.format("  Size: %d bytes", report.analysis.size))
        table.insert(lines, string.format("  Instructions: %d", report.analysis.statistics.num_instructions))
        table.insert(lines, "")
    end
    
    if report.obfuscation then
        table.insert(lines, "Obfuscation Analysis:")
        table.insert(lines, "  Likely Obfuscated: " .. (report.obfuscation.likely_obfuscated and "Yes" or "No"))
        table.insert(lines, string.format("  Confidence: %d%%", report.obfuscation.confidence))
        if #report.obfuscation.indicators > 0 then
            table.insert(lines, "  Indicators:")
            for _, indicator in ipairs(report.obfuscation.indicators) do
                table.insert(lines, "    - " .. indicator)
            end
        end
        if #report.obfuscation.techniques > 0 then
            table.insert(lines, "  Detected Techniques:")
            for _, technique in ipairs(report.obfuscation.techniques) do
                table.insert(lines, "    - " .. technique)
            end
        end
        table.insert(lines, "")
    end
    
    if #report.errors > 0 then
        table.insert(lines, "Errors:")
        for _, error in ipairs(report.errors) do
            table.insert(lines, "  - " .. error)
        end
        table.insert(lines, "")
    end
    
    table.insert(lines, "=" .. string.rep("=", 78))
    
    return table.concat(lines, "\n")
end

return bytecode_analyzer
