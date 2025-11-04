-- Syntax Validator for Lua Code
-- Phase 5: Extended Syntax Validation & Reverse Engineering System
-- Reference: https://www.lua.org/manual/5.4/

local syntax_validator = {}

-- ============================================================================
-- VALIDATION RULES
-- ============================================================================

-- Lua 5.4 keywords that cannot be used as identifiers
syntax_validator.KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false",
    "for", "function", "goto", "if", "in", "local", "nil",
    "not", "or", "repeat", "return", "then", "true", "until", "while"
}

-- Reserved identifiers in Factorio context
syntax_validator.FACTORIO_RESERVED = {
    "game", "script", "defines", "remote", "settings",
    "storage", "global", "rendering", "rcon", "commands"
}

-- ============================================================================
-- CORE VALIDATION
-- ============================================================================

-- Validate syntax of AST
-- @param ast table: Abstract Syntax Tree
-- @return boolean: True if syntax is valid
-- @return table: List of syntax issues
function syntax_validator.validate_syntax(ast)
    local issues = {}
    
    if not ast then
        table.insert(issues, "AST is nil")
        return false, issues
    end
    
    -- Validate AST structure
    local struct_valid, struct_issues = syntax_validator.validate_structure(ast)
    if not struct_valid then
        for _, issue in ipairs(struct_issues) do
            table.insert(issues, issue)
        end
    end
    
    -- Validate tokens
    if ast.tokens then
        local token_valid, token_issues = syntax_validator.validate_tokens(ast.tokens)
        if not token_valid then
            for _, issue in ipairs(token_issues) do
                table.insert(issues, issue)
            end
        end
    end
    
    -- Validate variable names
    local var_valid, var_issues = syntax_validator.validate_variables(ast)
    if not var_valid then
        for _, issue in ipairs(var_issues) do
            table.insert(issues, issue)
        end
    end
    
    -- Validate function definitions
    local func_valid, func_issues = syntax_validator.validate_functions(ast)
    if not func_valid then
        for _, issue in ipairs(func_issues) do
            table.insert(issues, issue)
        end
    end
    
    return #issues == 0, issues
end

-- Validate AST structure
-- @param ast table: Abstract Syntax Tree
-- @return boolean: True if structure is valid
-- @return table: List of structural issues
function syntax_validator.validate_structure(ast)
    local issues = {}
    
    if not ast.type then
        table.insert(issues, "AST missing 'type' field")
    end
    
    if not ast.body then
        table.insert(issues, "AST missing 'body' field")
    elseif type(ast.body) ~= "table" then
        table.insert(issues, "AST 'body' must be a table")
    end
    
    return #issues == 0, issues
end

-- Validate tokens
-- @param tokens table: List of tokens
-- @return boolean: True if tokens are valid
-- @return table: List of token issues
function syntax_validator.validate_tokens(tokens)
    local issues = {}
    
    if not tokens or type(tokens) ~= "table" then
        table.insert(issues, "Invalid token list")
        return false, issues
    end
    
    -- Check for unclosed strings
    local string_open = false
    for i, token in ipairs(tokens) do
        if token.type == "string" then
            -- Strings should be properly closed by tokenizer
            if not token.value then
                table.insert(issues, string.format("Unclosed string at token %d", i))
            end
        end
    end
    
    -- Check for balanced parentheses/brackets
    local balance = {
        ["("] = 0,
        ["["] = 0,
        ["{"] = 0
    }
    local closing = {
        [")"] = "(",
        ["]"] = "[",
        ["}"] = "{"
    }
    
    for i, token in ipairs(tokens) do
        if token.type == "operator" then
            if balance[token.value] then
                balance[token.value] = balance[token.value] + 1
            elseif closing[token.value] then
                local open = closing[token.value]
                balance[open] = balance[open] - 1
                if balance[open] < 0 then
                    table.insert(issues, string.format(
                        "Unbalanced '%s' at token %d", token.value, i))
                end
            end
        end
    end
    
    -- Check final balance
    for bracket, count in pairs(balance) do
        if count ~= 0 then
            table.insert(issues, string.format("Unbalanced '%s' (count: %d)", bracket, count))
        end
    end
    
    return #issues == 0, issues
end

-- Validate variable names
-- @param ast table: Abstract Syntax Tree
-- @return boolean: True if variables are valid
-- @return table: List of variable issues
function syntax_validator.validate_variables(ast)
    local issues = {}
    
    if not ast.tokens then
        return true, issues
    end
    
    for i, token in ipairs(ast.tokens) do
        if token.type == "identifier" then
            local name = token.value
            
            -- Check if identifier is a keyword
            for _, keyword in ipairs(syntax_validator.KEYWORDS) do
                if name == keyword then
                    table.insert(issues, string.format(
                        "Identifier '%s' at token %d is a reserved keyword", name, i))
                end
            end
            
            -- Check for valid identifier syntax
            if not syntax_validator.is_valid_identifier(name) then
                table.insert(issues, string.format(
                    "Invalid identifier '%s' at token %d", name, i))
            end
        end
    end
    
    return #issues == 0, issues
end

-- Validate function definitions
-- @param ast table: Abstract Syntax Tree
-- @return boolean: True if functions are valid
-- @return table: List of function issues
function syntax_validator.validate_functions(ast)
    local issues = {}
    
    if not ast.body then
        return true, issues
    end
    
    local function check_function(node)
        if not node or node.type ~= "function_def" then
            return
        end
        
        -- Check function name if present
        if node.name then
            if not syntax_validator.is_valid_identifier(node.name) then
                table.insert(issues, string.format(
                    "Invalid function name '%s'", node.name))
            end
        end
        
        -- Check parameter names
        if node.params then
            for _, param in ipairs(node.params) do
                if type(param) == "string" then
                    if not syntax_validator.is_valid_identifier(param) then
                        table.insert(issues, string.format(
                            "Invalid parameter name '%s' in function '%s'", 
                            param, node.name or "anonymous"))
                    end
                end
            end
        end
    end
    
    -- Traverse AST to find functions
    local function traverse(node)
        if not node then return end
        check_function(node)
        if node.body and type(node.body) == "table" then
            for _, child in ipairs(node.body) do
                traverse(child)
            end
        end
    end
    
    traverse(ast)
    
    return #issues == 0, issues
end

-- ============================================================================
-- IDENTIFIER VALIDATION
-- ============================================================================

-- Check if string is a valid Lua identifier
-- @param name string: Identifier name
-- @return boolean: True if valid
function syntax_validator.is_valid_identifier(name)
    if not name or type(name) ~= "string" or #name == 0 then
        return false
    end
    
    -- Must start with letter or underscore
    if not name:sub(1,1):match("[%a_]") then
        return false
    end
    
    -- Rest must be letters, digits, or underscores
    if not name:match("^[%a_][%w_]*$") then
        return false
    end
    
    -- Must not be a keyword
    for _, keyword in ipairs(syntax_validator.KEYWORDS) do
        if name == keyword then
            return false
        end
    end
    
    return true
end

-- ============================================================================
-- EXPRESSION VALIDATION
-- ============================================================================

-- Validate Lua expression
-- @param expr string: Expression to validate
-- @return boolean: True if valid
-- @return string: Error message if invalid
function syntax_validator.validate_expression(expr)
    if not expr or type(expr) ~= "string" then
        return false, "Expression must be a string"
    end
    
    -- Try to parse as Lua code
    local chunk, err = load("return " .. expr)
    if not chunk then
        return false, "Invalid expression: " .. tostring(err)
    end
    
    return true, nil
end

-- ============================================================================
-- TABLE CONSTRUCTOR VALIDATION
-- ============================================================================

-- Validate table constructor syntax
-- @param ast table: AST node for table constructor
-- @return boolean: True if valid
-- @return table: List of issues
function syntax_validator.validate_table_constructor(ast)
    local issues = {}
    
    if not ast or ast.type ~= "table_constructor" then
        table.insert(issues, "Not a table constructor node")
        return false, issues
    end
    
    -- Check for balanced braces
    -- (This is typically handled by token validation)
    
    return #issues == 0, issues
end

-- ============================================================================
-- CONTROL STRUCTURE VALIDATION
-- ============================================================================

-- Validate if statement structure
-- @param ast table: AST node for if statement
-- @return boolean: True if valid
-- @return table: List of issues
function syntax_validator.validate_if_statement(ast)
    local issues = {}
    
    if not ast or ast.type ~= "if_statement" then
        table.insert(issues, "Not an if statement node")
        return false, issues
    end
    
    -- Should have condition and body
    if not ast.condition then
        table.insert(issues, "If statement missing condition")
    end
    
    if not ast.body then
        table.insert(issues, "If statement missing body")
    end
    
    return #issues == 0, issues
end

-- Validate loop structure
-- @param ast table: AST node for loop
-- @return boolean: True if valid
-- @return table: List of issues
function syntax_validator.validate_loop(ast)
    local issues = {}
    
    if not ast then
        table.insert(issues, "Nil loop node")
        return false, issues
    end
    
    if ast.type ~= "while_loop" and ast.type ~= "for_loop" then
        table.insert(issues, "Not a loop node")
        return false, issues
    end
    
    -- Should have body
    if not ast.body then
        table.insert(issues, "Loop missing body")
    end
    
    -- For loops should have iterator
    if ast.type == "for_loop" and not ast.iterator then
        table.insert(issues, "For loop missing iterator")
    end
    
    return #issues == 0, issues
end

-- ============================================================================
-- FACTORIO-SPECIFIC VALIDATION
-- ============================================================================

-- Validate Factorio API usage
-- @param ast table: Abstract Syntax Tree
-- @return boolean: True if API usage is valid
-- @return table: List of API usage issues
function syntax_validator.validate_factorio_api(ast)
    local issues = {}
    
    if not ast or not ast.tokens then
        return true, issues
    end
    
    -- Check for deprecated API usage (exact matches only)
    local deprecated_apis = {
        ["^global%."] = true,  -- Match 'global.' at start
        ["^game%.player$"] = true,  -- Exact match 'game.player'
    }
    
    local source = ast.source or ""
    for pattern, _ in pairs(deprecated_apis) do
        if source:find(pattern) then
            local api_name = pattern:gsub("%^", ""):gsub("%$", ""):gsub("%%.", ".")
            table.insert(issues, string.format(
                "Deprecated API usage: %s (consider alternatives)", api_name))
        end
    end
    
    return #issues == 0, issues
end

-- Validate event handler structure
-- @param ast table: AST node
-- @return boolean: True if valid event handler
-- @return table: List of issues
function syntax_validator.validate_event_handler(ast)
    local issues = {}
    
    if not ast then
        table.insert(issues, "Nil event handler node")
        return false, issues
    end
    
    -- Event handlers should be functions
    if ast.type ~= "function_def" then
        table.insert(issues, "Event handler must be a function")
        return false, issues
    end
    
    -- Should have at least one parameter (event data)
    if not ast.params or #ast.params == 0 then
        table.insert(issues, "Event handler should accept event parameter")
    end
    
    return #issues == 0, issues
end

-- ============================================================================
-- CODE STYLE VALIDATION
-- ============================================================================

-- Validate code style conventions
-- @param ast table: Abstract Syntax Tree
-- @return table: List of style warnings
function syntax_validator.validate_style(ast)
    local warnings = {}
    
    if not ast then
        return warnings
    end
    
    -- Check for too long lines
    if ast.source then
        local max_line_length = 120
        local line_num = 1
        for line in ast.source:gmatch("[^\r\n]+") do
            if #line > max_line_length then
                table.insert(warnings, string.format(
                    "Line %d exceeds %d characters (%d)", 
                    line_num, max_line_length, #line))
            end
            line_num = line_num + 1
        end
    end
    
    -- Check for trailing whitespace
    if ast.source then
        local line_num = 1
        for line in ast.source:gmatch("[^\r\n]+") do
            if line:match("%s+$") then
                table.insert(warnings, string.format(
                    "Line %d has trailing whitespace", line_num))
            end
            line_num = line_num + 1
        end
    end
    
    -- Check for mixed tabs and spaces (prefer spaces)
    if ast.source and ast.source:find("\t") then
        table.insert(warnings, "File contains tabs (prefer spaces)")
    end
    
    return warnings
end

-- ============================================================================
-- COMPLEXITY VALIDATION
-- ============================================================================

-- Validate code complexity
-- @param ast table: Abstract Syntax Tree
-- @return boolean: True if complexity is acceptable
-- @return table: Complexity warnings
function syntax_validator.validate_complexity(ast)
    local warnings = {}
    local max_complexity = 20
    
    if not ast then
        return true, warnings
    end
    
    -- Calculate cyclomatic complexity
    local complexity = 1
    
    local function traverse(node)
        if not node then return end
        
        if node.type == "if_statement" or 
           node.type == "while_loop" or 
           node.type == "for_loop" then
            complexity = complexity + 1
        end
        
        if node.body and type(node.body) == "table" then
            for _, child in ipairs(node.body) do
                traverse(child)
            end
        end
    end
    
    traverse(ast)
    
    if complexity > max_complexity then
        table.insert(warnings, string.format(
            "Cyclomatic complexity (%d) exceeds maximum (%d)", 
            complexity, max_complexity))
    end
    
    return #warnings == 0, warnings
end

-- ============================================================================
-- COMPREHENSIVE VALIDATION
-- ============================================================================

-- Run all validators on AST
-- @param ast table: Abstract Syntax Tree
-- @param options table: Validation options
-- @return table: Comprehensive validation report
function syntax_validator.validate_all(ast, options)
    options = options or {}
    
    local report = {
        syntax_valid = false,
        errors = {},
        warnings = {},
        style_warnings = {},
        complexity_warnings = {}
    }
    
    -- Syntax validation
    local syntax_ok, syntax_issues = syntax_validator.validate_syntax(ast)
    report.syntax_valid = syntax_ok
    for _, issue in ipairs(syntax_issues) do
        table.insert(report.errors, issue)
    end
    
    -- Factorio API validation
    if options.validate_factorio ~= false then
        local api_ok, api_issues = syntax_validator.validate_factorio_api(ast)
        for _, issue in ipairs(api_issues) do
            table.insert(report.warnings, issue)
        end
    end
    
    -- Style validation
    if options.validate_style ~= false then
        local style_warnings = syntax_validator.validate_style(ast)
        for _, warning in ipairs(style_warnings) do
            table.insert(report.style_warnings, warning)
        end
    end
    
    -- Complexity validation
    if options.validate_complexity ~= false then
        local complexity_ok, complexity_warnings = syntax_validator.validate_complexity(ast)
        for _, warning in ipairs(complexity_warnings) do
            table.insert(report.complexity_warnings, warning)
        end
    end
    
    return report
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get validation statistics
-- @param report table: Validation report
-- @return table: Statistics
function syntax_validator.get_statistics(report)
    local stats = {
        total_errors = #(report.errors or {}),
        total_warnings = #(report.warnings or {}) + 
                         #(report.style_warnings or {}) + 
                         #(report.complexity_warnings or {}),
        is_valid = report.syntax_valid and #(report.errors or {}) == 0
    }
    
    return stats
end

-- Format validation report as string
-- @param report table: Validation report
-- @return string: Formatted report
function syntax_validator.format_report(report)
    local lines = {}
    
    table.insert(lines, "Syntax Validation Report")
    table.insert(lines, "========================")
    table.insert(lines, "")
    
    table.insert(lines, string.format("Valid: %s", 
        report.syntax_valid and "YES" or "NO"))
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
    
    if #report.style_warnings > 0 then
        table.insert(lines, "STYLE WARNINGS:")
        for i, warn in ipairs(report.style_warnings) do
            table.insert(lines, string.format("  [%d] %s", i, warn))
        end
        table.insert(lines, "")
    end
    
    if #report.complexity_warnings > 0 then
        table.insert(lines, "COMPLEXITY WARNINGS:")
        for i, warn in ipairs(report.complexity_warnings) do
            table.insert(lines, string.format("  [%d] %s", i, warn))
        end
        table.insert(lines, "")
    end
    
    return table.concat(lines, "\n")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return syntax_validator
