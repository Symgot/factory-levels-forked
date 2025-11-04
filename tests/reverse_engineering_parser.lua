-- Reverse Engineering Parser for Lua Code Analysis
-- Phase 5: Extended Syntax Validation & Reverse Engineering System
-- Reference: https://www.lua.org/manual/5.4/

local reverse_parser = {}

-- ============================================================================
-- AST NODE TYPES
-- ============================================================================

reverse_parser.NODE_TYPES = {
    CHUNK = "chunk",
    FUNCTION_DEF = "function_def",
    FUNCTION_CALL = "function_call",
    VARIABLE = "variable",
    ASSIGNMENT = "assignment",
    IF_STATEMENT = "if_statement",
    WHILE_LOOP = "while_loop",
    FOR_LOOP = "for_loop",
    RETURN = "return",
    TABLE_CONSTRUCTOR = "table_constructor",
    BINARY_OP = "binary_op",
    UNARY_OP = "unary_op",
    LOCAL_DECL = "local_decl",
    LITERAL = "literal",
    INDEX = "index",
    METHOD_CALL = "method_call"
}

-- ============================================================================
-- LEXER - Tokenization
-- ============================================================================

-- Tokenize Lua source code
-- @param source string: Lua source code
-- @return table: List of tokens
function reverse_parser.tokenize(source)
    local tokens = {}
    local pos = 1
    local len = #source
    
    while pos <= len do
        local char = source:sub(pos, pos)
        
        -- Skip whitespace
        if char:match("%s") then
            pos = pos + 1
        
        -- Comments
        elseif char == "-" and source:sub(pos, pos+1) == "--" then
            local comment_end = source:find("\n", pos) or len
            local comment_text = source:sub(pos+2, comment_end-1)
            table.insert(tokens, {type = "comment", value = comment_text, pos = pos})
            pos = comment_end + 1
        
        -- Strings
        elseif char == '"' or char == "'" then
            local quote = char
            local string_end = pos + 1
            local escaped = false
            while string_end <= len do
                local current = source:sub(string_end, string_end)
                if current == "\\" then
                    escaped = not escaped
                    string_end = string_end + 1
                elseif current == quote and not escaped then
                    break
                else
                    escaped = false
                    string_end = string_end + 1
                end
            end
            local string_value = source:sub(pos+1, string_end-1)
            table.insert(tokens, {type = "string", value = string_value, pos = pos})
            pos = string_end + 1
        
        -- Numbers
        elseif char:match("%d") then
            local num_end = pos
            while num_end <= len and source:sub(num_end, num_end):match("[%d%.]") do
                num_end = num_end + 1
            end
            local num_value = source:sub(pos, num_end-1)
            table.insert(tokens, {type = "number", value = tonumber(num_value), pos = pos})
            pos = num_end
        
        -- Identifiers and keywords
        elseif char:match("[%a_]") then
            local id_end = pos
            while id_end <= len and source:sub(id_end, id_end):match("[%w_]") do
                id_end = id_end + 1
            end
            local identifier = source:sub(pos, id_end-1)
            
            -- Check if keyword
            local keywords = {
                "and", "break", "do", "else", "elseif", "end", "false",
                "for", "function", "if", "in", "local", "nil", "not",
                "or", "repeat", "return", "then", "true", "until", "while"
            }
            local is_keyword = false
            for _, kw in ipairs(keywords) do
                if identifier == kw then
                    is_keyword = true
                    break
                end
            end
            
            table.insert(tokens, {
                type = is_keyword and "keyword" or "identifier",
                value = identifier,
                pos = pos
            })
            pos = id_end
        
        -- Operators and punctuation
        else
            local operators = {
                "==", "~=", "<=", ">=", "..", "//",
                "+", "-", "*", "/", "%", "^",
                "=", "<", ">", "#",
                "(", ")", "{", "}", "[", "]",
                ";", ":", ",", "."
            }
            
            local matched = false
            for _, op in ipairs(operators) do
                if source:sub(pos, pos + #op - 1) == op then
                    table.insert(tokens, {type = "operator", value = op, pos = pos})
                    pos = pos + #op
                    matched = true
                    break
                end
            end
            
            if not matched then
                pos = pos + 1
            end
        end
    end
    
    return tokens
end

-- ============================================================================
-- PARSER - AST Construction (Simplified)
-- ============================================================================

-- Build Abstract Syntax Tree from Lua code
-- @param lua_code string: Lua source code
-- @return table: AST root node
-- @return string: Error message if parse failed
function reverse_parser.build_ast(lua_code)
    if not lua_code or #lua_code == 0 then
        return nil, "Empty source code"
    end
    
    -- Tokenize first
    local tokens = reverse_parser.tokenize(lua_code)
    
    -- Build simplified AST
    local ast = {
        type = reverse_parser.NODE_TYPES.CHUNK,
        body = {},
        tokens = tokens,
        source = lua_code
    }
    
    -- Parse tokens into statements (simplified)
    local i = 1
    while i <= #tokens do
        local token = tokens[i]
        
        -- Function definition
        if token.type == "keyword" and token.value == "function" then
            local func_node = reverse_parser.parse_function(tokens, i)
            if func_node then
                table.insert(ast.body, func_node)
                i = func_node.end_pos or (i + 1)
            else
                i = i + 1
            end
        
        -- Local declaration
        elseif token.type == "keyword" and token.value == "local" then
            local local_node = reverse_parser.parse_local(tokens, i)
            if local_node then
                table.insert(ast.body, local_node)
                i = local_node.end_pos or (i + 1)
            else
                i = i + 1
            end
        
        -- Return statement
        elseif token.type == "keyword" and token.value == "return" then
            local return_node = {
                type = reverse_parser.NODE_TYPES.RETURN,
                pos = token.pos,
                end_pos = i + 1
            }
            table.insert(ast.body, return_node)
            i = i + 1
        
        else
            i = i + 1
        end
    end
    
    return ast, nil
end

-- Parse function definition from tokens
-- @param tokens table: Token list
-- @param start_pos number: Starting position
-- @return table: Function node
function reverse_parser.parse_function(tokens, start_pos)
    local node = {
        type = reverse_parser.NODE_TYPES.FUNCTION_DEF,
        name = nil,
        params = {},
        body = {},
        pos = tokens[start_pos].pos,
        end_pos = start_pos + 1
    }
    
    local i = start_pos + 1
    
    -- Get function name if present
    if i <= #tokens and tokens[i].type == "identifier" then
        node.name = tokens[i].value
        i = i + 1
    end
    
    -- Find matching 'end' keyword
    local depth = 1
    while i <= #tokens do
        local token = tokens[i]
        if token.type == "keyword" then
            if token.value == "function" or token.value == "if" or 
               token.value == "for" or token.value == "while" then
                depth = depth + 1
            elseif token.value == "end" then
                depth = depth - 1
                if depth == 0 then
                    node.end_pos = i + 1
                    break
                end
            end
        end
        i = i + 1
    end
    
    return node
end

-- Parse local declaration from tokens
-- @param tokens table: Token list
-- @param start_pos number: Starting position
-- @return table: Local declaration node
function reverse_parser.parse_local(tokens, start_pos)
    local node = {
        type = reverse_parser.NODE_TYPES.LOCAL_DECL,
        variables = {},
        values = {},
        pos = tokens[start_pos].pos,
        end_pos = start_pos + 1
    }
    
    local i = start_pos + 1
    
    -- Get variable names
    while i <= #tokens do
        local token = tokens[i]
        if token.type == "identifier" then
            table.insert(node.variables, token.value)
            i = i + 1
            
            -- Check for comma
            if i <= #tokens and tokens[i].type == "operator" and tokens[i].value == "," then
                i = i + 1
            else
                break
            end
        else
            break
        end
    end
    
    -- Find end of statement (newline, semicolon, or another statement)
    while i <= #tokens do
        local token = tokens[i]
        if token.type == "keyword" and 
           (token.value == "local" or token.value == "function" or 
            token.value == "return" or token.value == "if") then
            node.end_pos = i
            break
        end
        i = i + 1
    end
    
    return node
end

-- ============================================================================
-- FUNCTION EXTRACTION
-- ============================================================================

-- Extract all function definitions from AST
-- @param ast table: Abstract Syntax Tree
-- @return table: List of function definitions
function reverse_parser.extract_functions(ast)
    local functions = {}
    
    if not ast or not ast.body then
        return functions
    end
    
    -- Traverse AST and collect function nodes
    local function traverse(node)
        if not node then return end
        
        if node.type == reverse_parser.NODE_TYPES.FUNCTION_DEF then
            table.insert(functions, {
                name = node.name,
                params = node.params or {},
                pos = node.pos
            })
        end
        
        -- Recursively traverse body
        if node.body and type(node.body) == "table" then
            for _, child in ipairs(node.body) do
                traverse(child)
            end
        end
    end
    
    traverse(ast)
    
    return functions
end

-- ============================================================================
-- VARIABLE TRACKING
-- ============================================================================

-- Track variables through AST
-- @param ast table: Abstract Syntax Tree
-- @return table: Variable usage map
function reverse_parser.track_variables(ast)
    local variables = {
        local_vars = {},
        global_vars = {},
        usage = {}
    }
    
    if not ast or not ast.body then
        return variables
    end
    
    -- Track local declarations
    for _, node in ipairs(ast.body) do
        if node.type == reverse_parser.NODE_TYPES.LOCAL_DECL then
            for _, var_name in ipairs(node.variables or {}) do
                variables.local_vars[var_name] = {
                    declared_at = node.pos,
                    used_count = 0
                }
            end
        end
    end
    
    -- Scan tokens for variable usage
    if ast.tokens then
        for _, token in ipairs(ast.tokens) do
            if token.type == "identifier" then
                local var_name = token.value
                if not variables.usage[var_name] then
                    variables.usage[var_name] = 0
                end
                variables.usage[var_name] = variables.usage[var_name] + 1
                
                -- Track usage for local vars
                if variables.local_vars[var_name] then
                    variables.local_vars[var_name].used_count = 
                        variables.local_vars[var_name].used_count + 1
                end
            end
        end
    end
    
    return variables
end

-- ============================================================================
-- CONTROL FLOW ANALYSIS
-- ============================================================================

-- Analyze control flow through AST
-- @param ast table: Abstract Syntax Tree
-- @return table: Control flow information
function reverse_parser.analyze_control_flow(ast)
    local flow = {
        branches = 0,
        loops = 0,
        returns = 0,
        complexity = 1  -- Base complexity
    }
    
    if not ast or not ast.body then
        return flow
    end
    
    local function traverse(node)
        if not node then return end
        
        if node.type == reverse_parser.NODE_TYPES.IF_STATEMENT then
            flow.branches = flow.branches + 1
            flow.complexity = flow.complexity + 1
        elseif node.type == reverse_parser.NODE_TYPES.WHILE_LOOP or 
               node.type == reverse_parser.NODE_TYPES.FOR_LOOP then
            flow.loops = flow.loops + 1
            flow.complexity = flow.complexity + 1
        elseif node.type == reverse_parser.NODE_TYPES.RETURN then
            flow.returns = flow.returns + 1
        end
        
        if node.body and type(node.body) == "table" then
            for _, child in ipairs(node.body) do
                traverse(child)
            end
        end
    end
    
    traverse(ast)
    
    return flow
end

-- ============================================================================
-- API USAGE DETECTION
-- ============================================================================

-- Detect Factorio API usage in AST
-- @param ast table: Abstract Syntax Tree
-- @return table: List of API calls with metadata
function reverse_parser.detect_api_usage(ast)
    local api_calls = {}
    
    if not ast or not ast.tokens then
        return api_calls
    end
    
    -- Known Factorio API namespaces
    local api_namespaces = {
        "game", "script", "defines", "remote", "settings",
        "storage", "global", "rendering", "rcon", "commands"
    }
    
    -- Scan tokens for API patterns
    local i = 1
    while i <= #ast.tokens do
        local token = ast.tokens[i]
        
        if token.type == "identifier" then
            -- Check if it's an API namespace
            for _, ns in ipairs(api_namespaces) do
                if token.value == ns then
                    -- Look for member access
                    if i + 1 <= #ast.tokens and 
                       ast.tokens[i+1].type == "operator" and 
                       ast.tokens[i+1].value == "." then
                        
                        if i + 2 <= #ast.tokens and 
                           ast.tokens[i+2].type == "identifier" then
                            
                            local api_call = {
                                namespace = ns,
                                member = ast.tokens[i+2].value,
                                full_name = ns .. "." .. ast.tokens[i+2].value,
                                pos = token.pos,
                                type = "property"
                            }
                            
                            -- Check if it's a method call
                            if i + 3 <= #ast.tokens and
                               ast.tokens[i+3].type == "operator" and
                               (ast.tokens[i+3].value == "(" or ast.tokens[i+3].value == ":") then
                                api_call.type = "method"
                            end
                            
                            table.insert(api_calls, api_call)
                        end
                    end
                    break
                end
            end
        end
        
        i = i + 1
    end
    
    return api_calls
end

-- ============================================================================
-- DEPENDENCY ANALYSIS
-- ============================================================================

-- Analyze dependencies between mod components
-- @param ast table: Abstract Syntax Tree
-- @return table: Dependency graph
function reverse_parser.analyze_dependencies(ast)
    local dependencies = {
        requires = {},
        imports = {},
        exports = {}
    }
    
    if not ast or not ast.tokens then
        return dependencies
    end
    
    -- Scan for require() calls
    local i = 1
    while i <= #ast.tokens do
        local token = ast.tokens[i]
        
        if token.type == "identifier" and token.value == "require" then
            -- Look for string argument
            if i + 2 <= #ast.tokens and
               ast.tokens[i+1].type == "operator" and
               ast.tokens[i+1].value == "(" and
               ast.tokens[i+2].type == "string" then
                
                table.insert(dependencies.requires, {
                    module = ast.tokens[i+2].value,
                    pos = token.pos
                })
            end
        end
        
        i = i + 1
    end
    
    return dependencies
end

-- ============================================================================
-- CODE METRICS
-- ============================================================================

-- Calculate code metrics for AST
-- @param ast table: Abstract Syntax Tree
-- @return table: Code metrics
function reverse_parser.calculate_metrics(ast)
    local metrics = {
        total_lines = 0,
        code_lines = 0,
        comment_lines = 0,
        blank_lines = 0,
        functions = 0,
        complexity = 0
    }
    
    if not ast then
        return metrics
    end
    
    -- Count lines
    if ast.source then
        local lines = {}
        for line in ast.source:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        metrics.total_lines = #lines
        
        for _, line in ipairs(lines) do
            local trimmed = line:match("^%s*(.-)%s*$")
            if trimmed == "" then
                metrics.blank_lines = metrics.blank_lines + 1
            elseif trimmed:match("^%-%-") then
                metrics.comment_lines = metrics.comment_lines + 1
            else
                metrics.code_lines = metrics.code_lines + 1
            end
        end
    end
    
    -- Count functions
    local functions = reverse_parser.extract_functions(ast)
    metrics.functions = #functions
    
    -- Calculate complexity
    local flow = reverse_parser.analyze_control_flow(ast)
    metrics.complexity = flow.complexity
    
    return metrics
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Pretty print AST for debugging
-- @param ast table: Abstract Syntax Tree
-- @param indent number: Indentation level
-- @return string: Formatted AST
function reverse_parser.print_ast(ast, indent)
    indent = indent or 0
    local lines = {}
    local prefix = string.rep("  ", indent)
    
    if not ast then
        return "nil"
    end
    
    table.insert(lines, prefix .. "type: " .. tostring(ast.type))
    
    if ast.name then
        table.insert(lines, prefix .. "name: " .. tostring(ast.name))
    end
    
    if ast.body and type(ast.body) == "table" and #ast.body > 0 then
        table.insert(lines, prefix .. "body:")
        for _, child in ipairs(ast.body) do
            table.insert(lines, reverse_parser.print_ast(child, indent + 1))
        end
    end
    
    return table.concat(lines, "\n")
end

-- Get statistics about AST
-- @param ast table: Abstract Syntax Tree
-- @return table: Statistics
function reverse_parser.get_statistics(ast)
    local stats = {
        nodes = 0,
        depth = 0,
        functions = 0,
        variables = 0,
        api_calls = 0
    }
    
    if not ast then
        return stats
    end
    
    local function count_nodes(node, depth)
        if not node then return end
        
        stats.nodes = stats.nodes + 1
        stats.depth = math.max(stats.depth, depth)
        
        if node.type == reverse_parser.NODE_TYPES.FUNCTION_DEF then
            stats.functions = stats.functions + 1
        end
        
        if node.body and type(node.body) == "table" then
            for _, child in ipairs(node.body) do
                count_nodes(child, depth + 1)
            end
        end
    end
    
    count_nodes(ast, 0)
    
    -- Count variables
    local vars = reverse_parser.track_variables(ast)
    for _ in pairs(vars.usage) do
        stats.variables = stats.variables + 1
    end
    
    -- Count API calls
    local api_calls = reverse_parser.detect_api_usage(ast)
    stats.api_calls = #api_calls
    
    return stats
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return reverse_parser
