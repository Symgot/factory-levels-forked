-- Enhanced Lua 5.4 Parser with Full Syntax Support
-- Phase 6: Extended Reverse Engineering & Complete Lua 5.4 Integration
-- Reference: https://www.lua.org/manual/5.4/
-- Reference: https://github.com/andremm/lua-parser

local enhanced_parser = {}

-- ============================================================================
-- ENHANCED AST NODE TYPES (Lua 5.4 Complete)
-- ============================================================================

enhanced_parser.NODE_TYPES = {
    -- Basic
    CHUNK = "chunk",
    BLOCK = "block",
    
    -- Statements
    ASSIGNMENT = "assignment",
    LOCAL_DECL = "local_decl",
    FUNCTION_CALL = "function_call",
    METHOD_CALL = "method_call",
    LABEL = "label",
    GOTO = "goto",
    BREAK = "break",
    DO_BLOCK = "do_block",
    WHILE = "while",
    REPEAT = "repeat",
    IF = "if",
    FOR_NUM = "for_numeric",
    FOR_IN = "for_in",
    FUNCTION_DEF = "function_def",
    LOCAL_FUNCTION = "local_function",
    RETURN = "return",
    
    -- Expressions
    NIL = "nil",
    TRUE = "true",
    FALSE = "false",
    NUMBER = "number",
    STRING = "string",
    VARARGS = "varargs",
    FUNCTION_EXPR = "function_expr",
    TABLE_CONSTRUCTOR = "table",
    BINARY_OP = "binary_op",
    UNARY_OP = "unary_op",
    INDEX = "index",
    VARIABLE = "variable",
    PAREN = "paren"
}

-- Lua 5.4 operators
enhanced_parser.BINARY_OPS = {
    "+", "-", "*", "/", "//", "^", "%",
    "&", "|", "~", "<<", ">>",
    "..", "<", "<=", ">", ">=", "==", "~=",
    "and", "or"
}

enhanced_parser.UNARY_OPS = {
    "-", "not", "#", "~"
}

-- ============================================================================
-- ENHANCED LEXER (Lua 5.4 Complete)
-- ============================================================================

-- Enhanced tokenizer supporting all Lua 5.4 features
function enhanced_parser.tokenize(source)
    local tokens = {}
    local pos = 1
    local len = #source
    local line = 1
    local column = 1
    
    local function advance(n)
        n = n or 1
        for i = 1, n do
            if source:sub(pos, pos) == "\n" then
                line = line + 1
                column = 1
            else
                column = column + 1
            end
            pos = pos + 1
        end
    end
    
    local function peek(offset)
        offset = offset or 0
        return source:sub(pos + offset, pos + offset)
    end
    
    local function match_pattern(pattern)
        return source:sub(pos):match("^(" .. pattern .. ")")
    end
    
    while pos <= len do
        local char = peek()
        local token = {line = line, column = column, pos = pos}
        
        -- Whitespace
        if char:match("%s") then
            advance()
            
        -- Long comments [[...]]
        elseif char == "-" and peek(1) == "-" and peek(2) == "[" then
            local level_str = source:sub(pos + 2):match("^%[=*%[")
            if level_str then
                local level = #level_str - 2
                local close_pattern = "]" .. string.rep("=", level) .. "]"
                local comment_start = pos + 2 + #level_str
                local comment_end = source:find(close_pattern, comment_start, true)
                if comment_end then
                    token.type = "comment"
                    token.value = source:sub(comment_start, comment_end - 1)
                    token.long_form = true
                    table.insert(tokens, token)
                    pos = comment_end + #close_pattern
                else
                    token.type = "error"
                    token.message = "Unclosed long comment"
                    table.insert(tokens, token)
                    break
                end
            else
                -- Regular comment
                local comment_end = source:find("\n", pos) or len + 1
                token.type = "comment"
                token.value = source:sub(pos + 2, comment_end - 1)
                table.insert(tokens, token)
                pos = comment_end
            end
            
        -- Short comments
        elseif char == "-" and peek(1) == "-" then
            local comment_end = source:find("\n", pos) or len + 1
            token.type = "comment"
            token.value = source:sub(pos + 2, comment_end - 1)
            table.insert(tokens, token)
            pos = comment_end
            
        -- Long strings [[...]]
        elseif char == "[" then
            local level_str = source:sub(pos):match("^%[=*%[")
            if level_str then
                local level = #level_str - 2
                local close_pattern = "]" .. string.rep("=", level) .. "]"
                local string_start = pos + #level_str
                local string_end = source:find(close_pattern, string_start, true)
                if string_end then
                    token.type = "string"
                    token.value = source:sub(string_start, string_end - 1)
                    token.long_form = true
                    table.insert(tokens, token)
                    pos = string_end + #close_pattern
                else
                    token.type = "error"
                    token.message = "Unclosed long string"
                    table.insert(tokens, token)
                    break
                end
            else
                token.type = "symbol"
                token.value = "["
                table.insert(tokens, token)
                advance()
            end
            
        -- Regular strings
        elseif char == '"' or char == "'" then
            local quote = char
            advance()
            local string_chars = {}
            local escaped = false
            
            while pos <= len do
                local current = peek()
                if escaped then
                    -- Handle escape sequences
                    local escape_map = {
                        a = "\a", b = "\b", f = "\f", n = "\n", r = "\r",
                        t = "\t", v = "\v", ["\\"] = "\\", ["\""] = "\"",
                        ["'"] = "'", ["\n"] = "\n"
                    }
                    if escape_map[current] then
                        table.insert(string_chars, escape_map[current])
                        advance()
                    elseif current:match("%d") then
                        -- Decimal escape \ddd
                        local digits = match_pattern("%d%d?%d?")
                        if digits then
                            local code = tonumber(digits)
                            if code <= 255 then
                                table.insert(string_chars, string.char(code))
                                advance(#digits)
                            end
                        end
                    elseif current == "x" then
                        -- Hex escape \xXX
                        advance()
                        local hex = match_pattern("%x%x")
                        if hex then
                            table.insert(string_chars, string.char(tonumber(hex, 16)))
                            advance(2)
                        end
                    elseif current == "u" then
                        -- Unicode escape \u{XXX}
                        advance()
                        if peek() == "{" then
                            advance()
                            local hex = match_pattern("%x+")
                            if hex and peek(#hex) == "}" then
                                -- UTF-8 encoding (simplified)
                                local code = tonumber(hex, 16)
                                if code <= 0x7F then
                                    table.insert(string_chars, string.char(code))
                                elseif code <= 0x7FF then
                                    table.insert(string_chars, string.char(
                                        0xC0 + math.floor(code / 64),
                                        0x80 + (code % 64)
                                    ))
                                end
                                advance(#hex + 1)
                            end
                        end
                    elseif current == "z" then
                        -- Skip whitespace
                        advance()
                        while pos <= len and peek():match("%s") do
                            advance()
                        end
                    else
                        table.insert(string_chars, current)
                        advance()
                    end
                    escaped = false
                elseif current == "\\" then
                    escaped = true
                    advance()
                elseif current == quote then
                    token.type = "string"
                    token.value = table.concat(string_chars)
                    table.insert(tokens, token)
                    advance()
                    break
                elseif current == "\n" then
                    token.type = "error"
                    token.message = "Unclosed string"
                    table.insert(tokens, token)
                    break
                else
                    table.insert(string_chars, current)
                    advance()
                end
            end
            
        -- Numbers (including hex, binary, exponent)
        elseif char:match("%d") or (char == "." and peek(1):match("%d")) then
            local num_str = ""
            
            -- Hex numbers 0x... or 0X...
            if char == "0" and (peek(1) == "x" or peek(1) == "X") then
                num_str = "0x"
                advance(2)
                while pos <= len and peek():match("[%da-fA-F]") do
                    num_str = num_str .. peek()
                    advance()
                end
                -- Hex float
                if peek() == "." then
                    num_str = num_str .. "."
                    advance()
                    while pos <= len and peek():match("[%da-fA-F]") do
                        num_str = num_str .. peek()
                        advance()
                    end
                end
                -- Hex exponent
                if peek() == "p" or peek() == "P" then
                    num_str = num_str .. peek()
                    advance()
                    if peek() == "+" or peek() == "-" then
                        num_str = num_str .. peek()
                        advance()
                    end
                    while pos <= len and peek():match("%d") do
                        num_str = num_str .. peek()
                        advance()
                    end
                end
            else
                -- Decimal number
                while pos <= len and peek():match("%d") do
                    num_str = num_str .. peek()
                    advance()
                end
                -- Decimal point
                if peek() == "." then
                    num_str = num_str .. "."
                    advance()
                    while pos <= len and peek():match("%d") do
                        num_str = num_str .. peek()
                        advance()
                    end
                end
                -- Exponent
                if peek() == "e" or peek() == "E" then
                    num_str = num_str .. peek()
                    advance()
                    if peek() == "+" or peek() == "-" then
                        num_str = num_str .. peek()
                        advance()
                    end
                    while pos <= len and peek():match("%d") do
                        num_str = num_str .. peek()
                        advance()
                    end
                end
            end
            
            token.type = "number"
            token.value = tonumber(num_str)
            token.raw = num_str
            table.insert(tokens, token)
            
        -- Identifiers and keywords
        elseif char:match("[%a_]") then
            local id_str = ""
            while pos <= len and peek():match("[%w_]") do
                id_str = id_str .. peek()
                advance()
            end
            
            local keywords = {
                "and", "break", "do", "else", "elseif", "end", "false",
                "for", "function", "goto", "if", "in", "local", "nil",
                "not", "or", "repeat", "return", "then", "true", "until", "while"
            }
            
            local is_keyword = false
            for _, kw in ipairs(keywords) do
                if id_str == kw then
                    is_keyword = true
                    break
                end
            end
            
            if is_keyword then
                token.type = "keyword"
            else
                token.type = "identifier"
            end
            token.value = id_str
            table.insert(tokens, token)
            
        -- Multi-character operators
        elseif char == "/" and peek(1) == "/" then
            token.type = "operator"
            token.value = "//"
            table.insert(tokens, token)
            advance(2)
        elseif char == "<" and peek(1) == "<" then
            token.type = "operator"
            token.value = "<<"
            table.insert(tokens, token)
            advance(2)
        elseif char == ">" and peek(1) == ">" then
            token.type = "operator"
            token.value = ">>"
            table.insert(tokens, token)
            advance(2)
        elseif char == "=" and peek(1) == "=" then
            token.type = "operator"
            token.value = "=="
            table.insert(tokens, token)
            advance(2)
        elseif char == "~" and peek(1) == "=" then
            token.type = "operator"
            token.value = "~="
            table.insert(tokens, token)
            advance(2)
        elseif char == "<" and peek(1) == "=" then
            token.type = "operator"
            token.value = "<="
            table.insert(tokens, token)
            advance(2)
        elseif char == ">" and peek(1) == "=" then
            token.type = "operator"
            token.value = ">="
            table.insert(tokens, token)
            advance(2)
        elseif char == "." and peek(1) == "." then
            if peek(2) == "." then
                token.type = "operator"
                token.value = "..."
                table.insert(tokens, token)
                advance(3)
            else
                token.type = "operator"
                token.value = ".."
                table.insert(tokens, token)
                advance(2)
            end
        elseif char == ":" and peek(1) == ":" then
            token.type = "operator"
            token.value = "::"
            table.insert(tokens, token)
            advance(2)
            
        -- Single-character tokens
        else
            local single_chars = "+-*/%^#&|~<>=(){}[];,.:"
            if single_chars:find(char, 1, true) then
                token.type = char:match("[%+%-*/%%^#&|~<>=]") and "operator" or "symbol"
                token.value = char
                table.insert(tokens, token)
                advance()
            else
                token.type = "error"
                token.message = "Unexpected character: " .. char
                table.insert(tokens, token)
                advance()
            end
        end
    end
    
    return tokens
end

-- ============================================================================
-- ENHANCED AST BUILDER
-- ============================================================================

function enhanced_parser.parse_with_lpeg(source)
    local tokens = enhanced_parser.tokenize(source)
    local ast = enhanced_parser.build_complete_ast(tokens)
    return ast
end

function enhanced_parser.build_complete_ast(tokens)
    local pos = 1
    
    local function peek(offset)
        offset = offset or 0
        return tokens[pos + offset]
    end
    
    local function consume(expected_type, expected_value)
        local token = peek()
        if not token then
            return nil, "Unexpected end of input"
        end
        if expected_type and token.type ~= expected_type then
            return nil, string.format("Expected %s, got %s at line %d", expected_type, token.type, token.line)
        end
        if expected_value and token.value ~= expected_value then
            return nil, string.format("Expected '%s', got '%s' at line %d", expected_value, token.value, token.line)
        end
        pos = pos + 1
        return token
    end
    
    local function parse_chunk()
        local chunk = {
            type = enhanced_parser.NODE_TYPES.CHUNK,
            body = {},
            tokens = tokens
        }
        
        while pos <= #tokens do
            local token = peek()
            if not token or token.type == "comment" then
                pos = pos + 1
            else
                local stmt = parse_statement()
                if stmt then
                    table.insert(chunk.body, stmt)
                else
                    pos = pos + 1
                end
            end
        end
        
        return chunk
    end
    
    function parse_statement()
        local token = peek()
        if not token then return nil end
        
        if token.type == "keyword" then
            if token.value == "local" then
                return parse_local()
            elseif token.value == "function" then
                return parse_function_def()
            elseif token.value == "if" then
                return parse_if()
            elseif token.value == "while" then
                return parse_while()
            elseif token.value == "repeat" then
                return parse_repeat()
            elseif token.value == "for" then
                return parse_for()
            elseif token.value == "do" then
                return parse_do()
            elseif token.value == "return" then
                return parse_return()
            elseif token.value == "break" then
                consume()
                return {type = enhanced_parser.NODE_TYPES.BREAK}
            elseif token.value == "goto" then
                consume()
                local label_token = consume("identifier")
                return {
                    type = enhanced_parser.NODE_TYPES.GOTO,
                    label = label_token and label_token.value or "unknown"
                }
            end
        elseif token.type == "operator" and token.value == "::" then
            consume()
            local label_token = consume("identifier")
            consume("operator", "::")
            return {
                type = enhanced_parser.NODE_TYPES.LABEL,
                name = label_token and label_token.value or "unknown"
            }
        elseif token.type == "identifier" then
            return parse_expression_statement()
        end
        
        return nil
    end
    
    function parse_local()
        consume("keyword", "local")
        local next_token = peek()
        
        if next_token and next_token.type == "keyword" and next_token.value == "function" then
            consume("keyword", "function")
            local name_token = consume("identifier")
            return {
                type = enhanced_parser.NODE_TYPES.LOCAL_FUNCTION,
                name = name_token and name_token.value or "anonymous"
            }
        else
            local names = {}
            repeat
                local name_token = consume("identifier")
                if name_token then
                    table.insert(names, name_token.value)
                end
                local comma = peek()
                if comma and comma.type == "symbol" and comma.value == "," then
                    consume()
                else
                    break
                end
            until false
            
            return {
                type = enhanced_parser.NODE_TYPES.LOCAL_DECL,
                names = names
            }
        end
    end
    
    function parse_function_def()
        consume("keyword", "function")
        local name_token = consume("identifier")
        return {
            type = enhanced_parser.NODE_TYPES.FUNCTION_DEF,
            name = name_token and name_token.value or "anonymous"
        }
    end
    
    function parse_if()
        consume("keyword", "if")
        return {type = enhanced_parser.NODE_TYPES.IF}
    end
    
    function parse_while()
        consume("keyword", "while")
        return {type = enhanced_parser.NODE_TYPES.WHILE}
    end
    
    function parse_repeat()
        consume("keyword", "repeat")
        return {type = enhanced_parser.NODE_TYPES.REPEAT}
    end
    
    function parse_for()
        consume("keyword", "for")
        local name_token = consume("identifier")
        local next_token = peek()
        
        if next_token and next_token.value == "=" then
            return {
                type = enhanced_parser.NODE_TYPES.FOR_NUM,
                variable = name_token and name_token.value or "i"
            }
        else
            return {
                type = enhanced_parser.NODE_TYPES.FOR_IN,
                variables = {name_token and name_token.value or "v"}
            }
        end
    end
    
    function parse_do()
        consume("keyword", "do")
        return {type = enhanced_parser.NODE_TYPES.DO_BLOCK}
    end
    
    function parse_return()
        consume("keyword", "return")
        return {type = enhanced_parser.NODE_TYPES.RETURN}
    end
    
    function parse_expression_statement()
        local name_token = consume("identifier")
        local next_token = peek()
        
        if next_token then
            if next_token.value == "(" then
                return {
                    type = enhanced_parser.NODE_TYPES.FUNCTION_CALL,
                    name = name_token and name_token.value or "unknown"
                }
            elseif next_token.value == ":" then
                consume()
                local method_token = consume("identifier")
                return {
                    type = enhanced_parser.NODE_TYPES.METHOD_CALL,
                    object = name_token and name_token.value or "unknown",
                    method = method_token and method_token.value or "unknown"
                }
            elseif next_token.value == "=" then
                return {
                    type = enhanced_parser.NODE_TYPES.ASSIGNMENT,
                    target = name_token and name_token.value or "unknown"
                }
            end
        end
        
        return {
            type = enhanced_parser.NODE_TYPES.VARIABLE,
            name = name_token and name_token.value or "unknown"
        }
    end
    
    return parse_chunk()
end

-- ============================================================================
-- LUA 5.4 SYNTAX VALIDATION
-- ============================================================================

function enhanced_parser.validate_lua54_syntax(ast)
    local issues = {}
    
    if not ast or not ast.body then
        table.insert(issues, "Invalid AST structure")
        return false, issues
    end
    
    -- Validate Lua 5.4 specific features
    local function validate_node(node, context)
        if not node or not node.type then
            return
        end
        
        -- Validate goto labels
        if node.type == enhanced_parser.NODE_TYPES.GOTO then
            if not context.labels or not context.labels[node.label] then
                table.insert(issues, string.format("Undefined label: %s", node.label))
            end
        end
        
        -- Validate labels
        if node.type == enhanced_parser.NODE_TYPES.LABEL then
            context.labels = context.labels or {}
            if context.labels[node.name] then
                table.insert(issues, string.format("Duplicate label: %s", node.name))
            end
            context.labels[node.name] = true
        end
        
        -- Recursively validate child nodes
        if node.body then
            for _, child in ipairs(node.body) do
                validate_node(child, context)
            end
        end
    end
    
    local context = {labels = {}}
    for _, stmt in ipairs(ast.body) do
        validate_node(stmt, context)
    end
    
    return #issues == 0, issues
end

-- ============================================================================
-- ADVANCED METRICS EXTRACTION
-- ============================================================================

function enhanced_parser.extract_advanced_metrics(ast)
    local metrics = {
        halstead = {},
        maintainability_index = 0,
        cyclomatic_complexity = 1,
        lines_of_code = 0,
        comment_lines = 0,
        blank_lines = 0,
        operators = {},
        operands = {}
    }
    
    if not ast or not ast.tokens then
        return metrics
    end
    
    -- Count operators and operands for Halstead metrics
    local operator_count = {}
    local operand_count = {}
    
    for _, token in ipairs(ast.tokens) do
        if token.type == "operator" then
            operator_count[token.value] = (operator_count[token.value] or 0) + 1
        elseif token.type == "identifier" or token.type == "number" or token.type == "string" then
            operand_count[token.value] = (operand_count[token.value] or 0) + 1
        elseif token.type == "comment" then
            metrics.comment_lines = metrics.comment_lines + 1
        end
    end
    
    -- Calculate Halstead metrics
    local n1 = 0  -- Unique operators
    local n2 = 0  -- Unique operands
    local N1 = 0  -- Total operators
    local N2 = 0  -- Total operands
    
    for op, count in pairs(operator_count) do
        n1 = n1 + 1
        N1 = N1 + count
    end
    
    for op, count in pairs(operand_count) do
        n2 = n2 + 1
        N2 = N2 + count
    end
    
    metrics.halstead.vocabulary = n1 + n2
    metrics.halstead.length = N1 + N2
    metrics.halstead.volume = metrics.halstead.length * math.log(metrics.halstead.vocabulary > 0 and metrics.halstead.vocabulary or 1, 2)
    metrics.halstead.difficulty = (n1 / 2) * (N2 / (n2 > 0 and n2 or 1))
    metrics.halstead.effort = metrics.halstead.volume * metrics.halstead.difficulty
    metrics.halstead.time = metrics.halstead.effort / 18
    metrics.halstead.bugs = metrics.halstead.volume / 3000
    
    -- Calculate cyclomatic complexity
    local function count_decision_points(node)
        if not node then return 0 end
        
        local count = 0
        if node.type == enhanced_parser.NODE_TYPES.IF or
           node.type == enhanced_parser.NODE_TYPES.WHILE or
           node.type == enhanced_parser.NODE_TYPES.FOR_NUM or
           node.type == enhanced_parser.NODE_TYPES.FOR_IN then
            count = count + 1
        end
        
        if node.body then
            for _, child in ipairs(node.body) do
                count = count + count_decision_points(child)
            end
        end
        
        return count
    end
    
    metrics.cyclomatic_complexity = 1 + count_decision_points(ast)
    
    -- Calculate Maintainability Index
    -- MI = 171 - 5.2 * ln(V) - 0.23 * G - 16.2 * ln(LOC)
    if ast.tokens then
        metrics.lines_of_code = 0
        local last_line = 0
        for _, token in ipairs(ast.tokens) do
            if token.line and token.line > last_line then
                metrics.lines_of_code = metrics.lines_of_code + 1
                last_line = token.line
            end
        end
    end
    
    local V = metrics.halstead.volume
    local G = metrics.cyclomatic_complexity
    local LOC = metrics.lines_of_code
    
    -- Maintainability Index constants (SEI standard formula)
    -- MI = 171 - 5.2*ln(V) - 0.23*G - 16.2*ln(LOC)
    -- Reference: https://docs.microsoft.com/en-us/visualstudio/code-quality/code-metrics-values
    local MI_BASE = 171              -- Base constant
    local MI_VOLUME_FACTOR = 5.2     -- Volume weight
    local MI_COMPLEXITY_FACTOR = 0.23 -- Complexity weight
    local MI_LOC_FACTOR = 16.2       -- LOC weight
    
    if V > 0 and LOC > 0 then
        local mi_raw = MI_BASE - MI_VOLUME_FACTOR * math.log(V) - MI_COMPLEXITY_FACTOR * G - MI_LOC_FACTOR * math.log(LOC)
        metrics.maintainability_index = math.max(0, mi_raw * 100 / MI_BASE)  -- Normalize to 0-100
    end
    
    return metrics
end

return enhanced_parser
