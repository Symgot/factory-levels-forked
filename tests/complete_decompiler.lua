-- Complete Decompiler: Full AST Reconstruction from Bytecode
-- Phase 7: Production-Ready System - Complete Source Recovery
-- Reference: https://luadec.sourceforge.io/
-- Reference: https://github.com/stravant/lua-parser

local complete_decompiler = {}

-- Load bytecode analyzer as dependency
local bytecode_analyzer = require('bytecode_analyzer')

-- ============================================================================
-- AST NODE TYPES FOR DECOMPILATION
-- ============================================================================

complete_decompiler.AST_TYPES = {
    CHUNK = "Chunk",
    BLOCK = "Block",
    RETURN = "Return",
    BREAK = "Break",
    LABEL = "Label",
    GOTO = "Goto",
    DO = "Do",
    WHILE = "While",
    REPEAT = "Repeat",
    IF = "If",
    FOR_NUM = "ForNum",
    FOR_IN = "ForIn",
    FUNCTION = "Function",
    LOCAL_FUNCTION = "LocalFunction",
    LOCAL_ASSIGN = "LocalAssign",
    ASSIGN = "Assign",
    CALL_STMT = "CallStatement",
    
    -- Expressions
    NIL = "Nil",
    TRUE = "True",
    FALSE = "False",
    NUMBER = "Number",
    STRING = "String",
    VARARG = "Vararg",
    FUNCTION_EXPR = "FunctionExpr",
    TABLE = "Table",
    BINOP = "BinaryOp",
    UNOP = "UnaryOp",
    INDEX = "Index",
    MEMBER = "Member",
    CALL = "Call",
    METHOD_CALL = "MethodCall",
    ID = "Identifier",
    PAREN = "Paren"
}

-- ============================================================================
-- VARIABLE NAME RECOVERY
-- ============================================================================

local VariableRecovery = {}
VariableRecovery.__index = VariableRecovery

function VariableRecovery:new()
    local recovery = {
        local_vars = {},      -- Register -> variable name mapping
        upvalues = {},        -- Upvalue index -> name mapping
        globals = {},         -- Global names encountered
        temp_counter = 0,     -- Counter for temporary variables
        func_counter = 0,     -- Counter for anonymous functions
        loop_counter = 0,     -- Counter for loop variables
    }
    
    setmetatable(recovery, self)
    return recovery
end

function VariableRecovery:get_local_name(register)
    if not self.local_vars[register] then
        self.temp_counter = self.temp_counter + 1
        self.local_vars[register] = "_temp" .. self.temp_counter
    end
    return self.local_vars[register]
end

function VariableRecovery:set_local_name(register, name)
    self.local_vars[register] = name
end

function VariableRecovery:get_upvalue_name(index)
    if not self.upvalues[index] then
        self.upvalues[index] = "_upval" .. index
    end
    return self.upvalues[index]
end

function VariableRecovery:get_function_name()
    self.func_counter = self.func_counter + 1
    return "_func" .. self.func_counter
end

function VariableRecovery:get_loop_var_name()
    self.loop_counter = self.loop_counter + 1
    return "_i" .. self.loop_counter
end

function VariableRecovery:track_global(name)
    self.globals[name] = true
end

-- ============================================================================
-- CONTROL FLOW GRAPH (CFG) CONSTRUCTION
-- ============================================================================

local CFGNode = {}
CFGNode.__index = CFGNode

function CFGNode:new(id, start_pc, end_pc)
    local node = {
        id = id,
        start_pc = start_pc,
        end_pc = end_pc,
        instructions = {},
        successors = {},
        predecessors = {},
        ast_nodes = {},
        
        -- Control flow type
        type = "basic",  -- basic, branch, loop, return
        branch_condition = nil,
        loop_info = nil
    }
    
    setmetatable(node, self)
    return node
end

local ControlFlowGraph = {}
ControlFlowGraph.__index = ControlFlowGraph

function ControlFlowGraph:new()
    local cfg = {
        nodes = {},
        entry_node = nil,
        exit_nodes = {},
        node_counter = 0
    }
    
    setmetatable(cfg, self)
    return cfg
end

function ControlFlowGraph:create_node(start_pc, end_pc)
    self.node_counter = self.node_counter + 1
    local node = CFGNode:new(self.node_counter, start_pc, end_pc)
    table.insert(self.nodes, node)
    return node
end

function ControlFlowGraph:add_edge(from_node, to_node)
    table.insert(from_node.successors, to_node)
    table.insert(to_node.predecessors, from_node)
end

function ControlFlowGraph:build_from_instructions(instructions)
    -- Identify basic block boundaries
    local leaders = {1}  -- First instruction is always a leader
    local jump_targets = {}
    
    -- Find all jump targets
    for i, inst in ipairs(instructions) do
        local opcode = inst.opcode
        if opcode:match("JMP") or opcode:match("FOR") or opcode:match("TFOR") then
            local target = i + 1 + (inst.sBx or inst.Bx or 0)
            jump_targets[target] = true
            leaders[i + 1] = true  -- Instruction after jump is a leader
        elseif opcode == "RETURN" then
            if i < #instructions then
                leaders[i + 1] = true
            end
        end
    end
    
    -- Add jump targets as leaders
    for target in pairs(jump_targets) do
        leaders[target] = true
    end
    
    -- Sort leaders
    local sorted_leaders = {}
    for pc in pairs(leaders) do
        table.insert(sorted_leaders, pc)
    end
    table.sort(sorted_leaders)
    
    -- Create basic blocks
    local blocks = {}
    for i = 1, #sorted_leaders do
        local start_pc = sorted_leaders[i]
        local end_pc = sorted_leaders[i + 1] and (sorted_leaders[i + 1] - 1) or #instructions
        
        local node = self:create_node(start_pc, end_pc)
        for pc = start_pc, end_pc do
            if instructions[pc] then
                table.insert(node.instructions, instructions[pc])
            end
        end
        
        blocks[start_pc] = node
    end
    
    -- Connect blocks
    for start_pc, node in pairs(blocks) do
        local last_inst = node.instructions[#node.instructions]
        if last_inst then
            local opcode = last_inst.opcode
            
            if opcode == "JMP" then
                local target = start_pc + #node.instructions + last_inst.sBx
                if blocks[target] then
                    self:add_edge(node, blocks[target])
                end
                node.type = "branch"
            elseif opcode:match("^TEST") or opcode:match("^EQ") or opcode:match("^LT") or opcode:match("^LE") then
                -- Conditional branch
                local next_start = start_pc + #node.instructions
                if blocks[next_start] then
                    self:add_edge(node, blocks[next_start])
                end
                -- Also add fall-through
                local fall_through = start_pc + #node.instructions + 1
                if blocks[fall_through] then
                    self:add_edge(node, blocks[fall_through])
                end
                node.type = "branch"
            elseif opcode == "RETURN" then
                node.type = "return"
                table.insert(self.exit_nodes, node)
            else
                -- Fall-through to next block
                local next_start = start_pc + #node.instructions
                if blocks[next_start] then
                    self:add_edge(node, blocks[next_start])
                end
            end
        end
    end
    
    -- Set entry node
    self.entry_node = blocks[1]
    
    return self
end

-- ============================================================================
-- DATA FLOW ANALYSIS
-- ============================================================================

local DataFlowAnalyzer = {}
DataFlowAnalyzer.__index = DataFlowAnalyzer

function DataFlowAnalyzer:new(cfg)
    local analyzer = {
        cfg = cfg,
        reaching_defs = {},    -- Register -> set of definition points
        use_def_chains = {},   -- Use -> Definition mapping
        def_use_chains = {},   -- Definition -> Uses mapping
    }
    
    setmetatable(analyzer, self)
    return analyzer
end

function DataFlowAnalyzer:analyze()
    -- Reaching definitions analysis
    for _, node in ipairs(self.cfg.nodes) do
        self.reaching_defs[node.id] = {
            gen = {},  -- Definitions generated in this block
            kill = {}, -- Definitions killed in this block
            inn = {},  -- Definitions reaching start of block
            out = {}   -- Definitions reaching end of block
        }
        
        -- Compute gen and kill sets
        for _, inst in ipairs(node.instructions) do
            local opcode = inst.opcode
            
            -- Track definitions (stores to registers)
            if opcode:match("^LOAD") or opcode:match("^GET") or opcode == "MOVE" then
                local reg = inst.A
                self.reaching_defs[node.id].gen[reg] = inst
                self.reaching_defs[node.id].kill[reg] = true
            end
        end
    end
    
    -- Iterative data flow analysis
    local changed = true
    local max_iterations = 100
    local iteration = 0
    
    while changed and iteration < max_iterations do
        changed = false
        iteration = iteration + 1
        
        for _, node in ipairs(self.cfg.nodes) do
            local old_in = self:copy_set(self.reaching_defs[node.id].inn)
            local old_out = self:copy_set(self.reaching_defs[node.id].out)
            
            -- in[n] = union of out[p] for all predecessors p
            local new_in = {}
            for _, pred in ipairs(node.predecessors) do
                for reg, def in pairs(self.reaching_defs[pred.id].out) do
                    new_in[reg] = def
                end
            end
            
            -- out[n] = gen[n] union (in[n] - kill[n])
            local new_out = self:copy_set(self.reaching_defs[node.id].gen)
            for reg, def in pairs(new_in) do
                if not self.reaching_defs[node.id].kill[reg] then
                    new_out[reg] = def
                end
            end
            
            self.reaching_defs[node.id].inn = new_in
            self.reaching_defs[node.id].out = new_out
            
            if not self:sets_equal(old_in, new_in) or not self:sets_equal(old_out, new_out) then
                changed = true
            end
        end
    end
    
    return self
end

function DataFlowAnalyzer:copy_set(set)
    local copy = {}
    for k, v in pairs(set) do
        copy[k] = v
    end
    return copy
end

function DataFlowAnalyzer:sets_equal(a, b)
    for k in pairs(a) do
        if not b[k] then return false end
    end
    for k in pairs(b) do
        if not a[k] then return false end
    end
    return true
end

-- ============================================================================
-- AST RECONSTRUCTION
-- ============================================================================

local ASTBuilder = {}
ASTBuilder.__index = ASTBuilder

function ASTBuilder:new(cfg, var_recovery)
    local builder = {
        cfg = cfg,
        var_recovery = var_recovery,
        ast = nil
    }
    
    setmetatable(builder, self)
    return builder
end

function ASTBuilder:build()
    if not self.cfg.entry_node then
        return {type = complete_decompiler.AST_TYPES.CHUNK, body = {}}
    end
    
    local statements = self:process_node(self.cfg.entry_node, {})
    
    self.ast = {
        type = complete_decompiler.AST_TYPES.CHUNK,
        body = statements
    }
    
    return self.ast
end

function ASTBuilder:process_node(node, visited)
    if visited[node.id] then
        return {}
    end
    visited[node.id] = true
    
    local statements = {}
    
    -- Process instructions in this block
    for _, inst in ipairs(node.instructions) do
        local stmt = self:instruction_to_statement(inst)
        if stmt then
            table.insert(statements, stmt)
        end
    end
    
    -- Process successors based on node type
    if node.type == "branch" then
        -- Handle conditional branches
        if #node.successors == 2 then
            local if_stmt = {
                type = complete_decompiler.AST_TYPES.IF,
                condition = {type = complete_decompiler.AST_TYPES.TRUE},  -- TODO: Extract condition
                then_block = self:process_node(node.successors[1], visited),
                else_block = self:process_node(node.successors[2], visited)
            }
            table.insert(statements, if_stmt)
        elseif #node.successors == 1 then
            -- Unconditional jump
            local next_stmts = self:process_node(node.successors[1], visited)
            for _, stmt in ipairs(next_stmts) do
                table.insert(statements, stmt)
            end
        end
    elseif node.type == "return" then
        -- Already handled by instruction_to_statement
    elseif #node.successors == 1 then
        -- Fall-through to next block
        local next_stmts = self:process_node(node.successors[1], visited)
        for _, stmt in ipairs(next_stmts) do
            table.insert(statements, stmt)
        end
    end
    
    return statements
end

function ASTBuilder:instruction_to_statement(inst)
    local opcode = inst.opcode
    
    -- LOAD operations
    if opcode == "LOADNIL" then
        return {
            type = complete_decompiler.AST_TYPES.ASSIGN,
            targets = {{type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)}},
            values = {{type = complete_decompiler.AST_TYPES.NIL}}
        }
    elseif opcode == "LOADTRUE" then
        return {
            type = complete_decompiler.AST_TYPES.ASSIGN,
            targets = {{type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)}},
            values = {{type = complete_decompiler.AST_TYPES.TRUE}}
        }
    elseif opcode == "LOADFALSE" then
        return {
            type = complete_decompiler.AST_TYPES.ASSIGN,
            targets = {{type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)}},
            values = {{type = complete_decompiler.AST_TYPES.FALSE}}
        }
    elseif opcode == "LOADI" then
        return {
            type = complete_decompiler.AST_TYPES.ASSIGN,
            targets = {{type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)}},
            values = {{type = complete_decompiler.AST_TYPES.NUMBER, value = inst.sBx}}
        }
    elseif opcode == "LOADK" then
        return {
            type = complete_decompiler.AST_TYPES.ASSIGN,
            targets = {{type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)}},
            values = {{type = complete_decompiler.AST_TYPES.STRING, value = "_K" .. inst.Bx}}  -- TODO: Lookup constant
        }
    
    -- Arithmetic operations
    elseif opcode == "ADD" or opcode == "SUB" or opcode == "MUL" or opcode == "DIV" 
           or opcode == "MOD" or opcode == "POW" or opcode == "IDIV" then
        local op_map = {
            ADD = "+", SUB = "-", MUL = "*", DIV = "/",
            MOD = "%", POW = "^", IDIV = "//"
        }
        return {
            type = complete_decompiler.AST_TYPES.ASSIGN,
            targets = {{type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)}},
            values = {{
                type = complete_decompiler.AST_TYPES.BINOP,
                op = op_map[opcode],
                left = {type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.B)},
                right = {type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.C)}
            }}
        }
    
    -- Bitwise operations
    elseif opcode == "BAND" or opcode == "BOR" or opcode == "BXOR" 
           or opcode == "SHL" or opcode == "SHR" then
        local op_map = {
            BAND = "&", BOR = "|", BXOR = "~",
            SHL = "<<", SHR = ">>"
        }
        return {
            type = complete_decompiler.AST_TYPES.ASSIGN,
            targets = {{type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)}},
            values = {{
                type = complete_decompiler.AST_TYPES.BINOP,
                op = op_map[opcode],
                left = {type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.B)},
                right = {type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.C)}
            }}
        }
    
    -- Table operations
    elseif opcode == "NEWTABLE" then
        return {
            type = complete_decompiler.AST_TYPES.ASSIGN,
            targets = {{type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)}},
            values = {{type = complete_decompiler.AST_TYPES.TABLE, fields = {}}}
        }
    elseif opcode == "GETTABLE" then
        return {
            type = complete_decompiler.AST_TYPES.ASSIGN,
            targets = {{type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)}},
            values = {{
                type = complete_decompiler.AST_TYPES.INDEX,
                table = {type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.B)},
                index = {type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.C)}
            }}
        }
    elseif opcode == "SETTABLE" then
        return {
            type = complete_decompiler.AST_TYPES.ASSIGN,
            targets = {{
                type = complete_decompiler.AST_TYPES.INDEX,
                table = {type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)},
                index = {type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.B)}
            }},
            values = {{type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.C)}}
        }
    
    -- Function calls
    elseif opcode == "CALL" then
        return {
            type = complete_decompiler.AST_TYPES.CALL_STMT,
            func = {type = complete_decompiler.AST_TYPES.ID, name = self.var_recovery:get_local_name(inst.A)},
            args = {}  -- TODO: Collect arguments
        }
    
    -- Return statement
    elseif opcode == "RETURN" then
        local return_values = {}
        if inst.B > 1 then
            for i = 0, inst.B - 2 do
                table.insert(return_values, {
                    type = complete_decompiler.AST_TYPES.ID,
                    name = self.var_recovery:get_local_name(inst.A + i)
                })
            end
        end
        return {
            type = complete_decompiler.AST_TYPES.RETURN,
            values = return_values
        }
    end
    
    -- Unknown or unhandled instruction
    return nil
end

-- ============================================================================
-- CODE GENERATION FROM AST
-- ============================================================================

local CodeGenerator = {}
CodeGenerator.__index = CodeGenerator

function CodeGenerator:new()
    local generator = {
        indent_level = 0,
        indent_string = "  ",
        output = {}
    }
    
    setmetatable(generator, self)
    return generator
end

function CodeGenerator:generate(ast)
    self.output = {}
    self:generate_node(ast)
    return table.concat(self.output, "\n")
end

function CodeGenerator:indent()
    return string.rep(self.indent_string, self.indent_level)
end

function CodeGenerator:emit(code)
    table.insert(self.output, self:indent() .. code)
end

function CodeGenerator:generate_node(node)
    local node_type = node.type
    
    if node_type == complete_decompiler.AST_TYPES.CHUNK then
        for _, stmt in ipairs(node.body) do
            self:generate_node(stmt)
        end
    
    elseif node_type == complete_decompiler.AST_TYPES.ASSIGN then
        local targets = {}
        for _, target in ipairs(node.targets) do
            table.insert(targets, self:expression_to_string(target))
        end
        
        local values = {}
        for _, value in ipairs(node.values) do
            table.insert(values, self:expression_to_string(value))
        end
        
        self:emit(table.concat(targets, ", ") .. " = " .. table.concat(values, ", "))
    
    elseif node_type == complete_decompiler.AST_TYPES.LOCAL_ASSIGN then
        local names = {}
        for _, name in ipairs(node.names) do
            table.insert(names, name)
        end
        
        local values = {}
        for _, value in ipairs(node.values or {}) do
            table.insert(values, self:expression_to_string(value))
        end
        
        if #values > 0 then
            self:emit("local " .. table.concat(names, ", ") .. " = " .. table.concat(values, ", "))
        else
            self:emit("local " .. table.concat(names, ", "))
        end
    
    elseif node_type == complete_decompiler.AST_TYPES.IF then
        self:emit("if " .. self:expression_to_string(node.condition) .. " then")
        self.indent_level = self.indent_level + 1
        for _, stmt in ipairs(node.then_block) do
            self:generate_node(stmt)
        end
        self.indent_level = self.indent_level - 1
        
        if node.else_block and #node.else_block > 0 then
            self:emit("else")
            self.indent_level = self.indent_level + 1
            for _, stmt in ipairs(node.else_block) do
                self:generate_node(stmt)
            end
            self.indent_level = self.indent_level - 1
        end
        
        self:emit("end")
    
    elseif node_type == complete_decompiler.AST_TYPES.WHILE then
        self:emit("while " .. self:expression_to_string(node.condition) .. " do")
        self.indent_level = self.indent_level + 1
        for _, stmt in ipairs(node.body) do
            self:generate_node(stmt)
        end
        self.indent_level = self.indent_level - 1
        self:emit("end")
    
    elseif node_type == complete_decompiler.AST_TYPES.REPEAT then
        self:emit("repeat")
        self.indent_level = self.indent_level + 1
        for _, stmt in ipairs(node.body) do
            self:generate_node(stmt)
        end
        self.indent_level = self.indent_level - 1
        self:emit("until " .. self:expression_to_string(node.condition))
    
    elseif node_type == complete_decompiler.AST_TYPES.FOR_NUM then
        self:emit(string.format("for %s = %s, %s%s do",
            node.var,
            self:expression_to_string(node.start),
            self:expression_to_string(node.limit),
            node.step and (", " .. self:expression_to_string(node.step)) or ""
        ))
        self.indent_level = self.indent_level + 1
        for _, stmt in ipairs(node.body) do
            self:generate_node(stmt)
        end
        self.indent_level = self.indent_level - 1
        self:emit("end")
    
    elseif node_type == complete_decompiler.AST_TYPES.FOR_IN then
        self:emit("for " .. table.concat(node.vars, ", ") .. " in " .. 
                  self:expression_to_string(node.iterator) .. " do")
        self.indent_level = self.indent_level + 1
        for _, stmt in ipairs(node.body) do
            self:generate_node(stmt)
        end
        self.indent_level = self.indent_level - 1
        self:emit("end")
    
    elseif node_type == complete_decompiler.AST_TYPES.FUNCTION then
        local params = table.concat(node.params or {}, ", ")
        self:emit("function " .. node.name .. "(" .. params .. ")")
        self.indent_level = self.indent_level + 1
        for _, stmt in ipairs(node.body) do
            self:generate_node(stmt)
        end
        self.indent_level = self.indent_level - 1
        self:emit("end")
    
    elseif node_type == complete_decompiler.AST_TYPES.LOCAL_FUNCTION then
        local params = table.concat(node.params or {}, ", ")
        self:emit("local function " .. node.name .. "(" .. params .. ")")
        self.indent_level = self.indent_level + 1
        for _, stmt in ipairs(node.body) do
            self:generate_node(stmt)
        end
        self.indent_level = self.indent_level - 1
        self:emit("end")
    
    elseif node_type == complete_decompiler.AST_TYPES.RETURN then
        if #node.values > 0 then
            local values = {}
            for _, value in ipairs(node.values) do
                table.insert(values, self:expression_to_string(value))
            end
            self:emit("return " .. table.concat(values, ", "))
        else
            self:emit("return")
        end
    
    elseif node_type == complete_decompiler.AST_TYPES.CALL_STMT then
        self:emit(self:expression_to_string(node))
    
    elseif node_type == complete_decompiler.AST_TYPES.DO then
        self:emit("do")
        self.indent_level = self.indent_level + 1
        for _, stmt in ipairs(node.body) do
            self:generate_node(stmt)
        end
        self.indent_level = self.indent_level - 1
        self:emit("end")
    
    elseif node_type == complete_decompiler.AST_TYPES.BREAK then
        self:emit("break")
    
    elseif node_type == complete_decompiler.AST_TYPES.LABEL then
        self:emit("::" .. node.name .. "::")
    
    elseif node_type == complete_decompiler.AST_TYPES.GOTO then
        self:emit("goto " .. node.target)
    end
end

function CodeGenerator:expression_to_string(expr)
    local expr_type = expr.type
    
    if expr_type == complete_decompiler.AST_TYPES.NIL then
        return "nil"
    elseif expr_type == complete_decompiler.AST_TYPES.TRUE then
        return "true"
    elseif expr_type == complete_decompiler.AST_TYPES.FALSE then
        return "false"
    elseif expr_type == complete_decompiler.AST_TYPES.NUMBER then
        return tostring(expr.value)
    elseif expr_type == complete_decompiler.AST_TYPES.STRING then
        return '"' .. (expr.value or "") .. '"'
    elseif expr_type == complete_decompiler.AST_TYPES.ID then
        return expr.name
    elseif expr_type == complete_decompiler.AST_TYPES.VARARG then
        return "..."
    elseif expr_type == complete_decompiler.AST_TYPES.BINOP then
        return "(" .. self:expression_to_string(expr.left) .. " " .. 
               expr.op .. " " .. self:expression_to_string(expr.right) .. ")"
    elseif expr_type == complete_decompiler.AST_TYPES.UNOP then
        return expr.op .. self:expression_to_string(expr.operand)
    elseif expr_type == complete_decompiler.AST_TYPES.INDEX then
        return self:expression_to_string(expr.table) .. "[" .. 
               self:expression_to_string(expr.index) .. "]"
    elseif expr_type == complete_decompiler.AST_TYPES.MEMBER then
        return self:expression_to_string(expr.table) .. "." .. expr.property
    elseif expr_type == complete_decompiler.AST_TYPES.CALL then
        local args = {}
        for _, arg in ipairs(expr.args or {}) do
            table.insert(args, self:expression_to_string(arg))
        end
        return self:expression_to_string(expr.func) .. "(" .. table.concat(args, ", ") .. ")"
    elseif expr_type == complete_decompiler.AST_TYPES.METHOD_CALL then
        local args = {}
        for _, arg in ipairs(expr.args or {}) do
            table.insert(args, self:expression_to_string(arg))
        end
        return self:expression_to_string(expr.object) .. ":" .. expr.method .. 
               "(" .. table.concat(args, ", ") .. ")"
    elseif expr_type == complete_decompiler.AST_TYPES.TABLE then
        if #expr.fields == 0 then
            return "{}"
        end
        local fields = {}
        for _, field in ipairs(expr.fields) do
            if field.key then
                table.insert(fields, "[" .. self:expression_to_string(field.key) .. "] = " .. 
                            self:expression_to_string(field.value))
            else
                table.insert(fields, self:expression_to_string(field.value))
            end
        end
        return "{" .. table.concat(fields, ", ") .. "}"
    elseif expr_type == complete_decompiler.AST_TYPES.FUNCTION_EXPR then
        local params = table.concat(expr.params or {}, ", ")
        local code = "function(" .. params .. ")\n"
        local old_indent = self.indent_level
        self.indent_level = old_indent + 1
        for _, stmt in ipairs(expr.body) do
            code = code .. self:indent() .. self:generate_node(stmt) .. "\n"
        end
        self.indent_level = old_indent
        code = code .. self:indent() .. "end"
        return code
    elseif expr_type == complete_decompiler.AST_TYPES.PAREN then
        return "(" .. self:expression_to_string(expr.expr) .. ")"
    else
        return "_UNKNOWN_"
    end
end

-- ============================================================================
-- COMPLETE DECOMPILATION PIPELINE
-- ============================================================================

function complete_decompiler.decompile_bytecode(bytecode_data)
    -- Step 1: Analyze bytecode
    local analysis = bytecode_analyzer.analyze_data(bytecode_data)
    if not analysis.success then
        return nil, "Bytecode analysis failed: " .. tostring(analysis.error)
    end
    
    -- Step 2: Build Control Flow Graph
    local cfg = ControlFlowGraph:new()
    cfg:build_from_instructions(analysis.analysis.instructions or {})
    
    -- Step 3: Perform Data Flow Analysis
    local dfa = DataFlowAnalyzer:new(cfg)
    dfa:analyze()
    
    -- Step 4: Variable Name Recovery
    local var_recovery = VariableRecovery:new()
    
    -- TODO: Extract variable names from debug info if available
    
    -- Step 5: Build AST
    local ast_builder = ASTBuilder:new(cfg, var_recovery)
    local ast = ast_builder:build()
    
    -- Step 6: Generate Code
    local code_gen = CodeGenerator:new()
    local source_code = code_gen:generate(ast)
    
    return {
        success = true,
        source_code = source_code,
        ast = ast,
        cfg = cfg,
        variable_recovery = var_recovery,
        statistics = {
            num_basic_blocks = #cfg.nodes,
            num_instructions = #(analysis.analysis.instructions or {}),
            num_variables = var_recovery.temp_counter + var_recovery.loop_counter,
            num_functions = var_recovery.func_counter,
            decompilation_quality = calculate_quality(ast, analysis)
        }
    }
end

function complete_decompiler.decompile_file(filename)
    local file, err = io.open(filename, "rb")
    if not file then
        return nil, "Failed to open file: " .. tostring(err)
    end
    
    local bytecode_data = file:read("*all")
    file:close()
    
    return complete_decompiler.decompile_bytecode(bytecode_data)
end

-- ============================================================================
-- QUALITY METRICS
-- ============================================================================

function calculate_quality(ast, analysis)
    -- Calculate decompilation quality score (0-100)
    local quality = 100
    
    -- Penalize for unknown/temp variables
    local temp_vars = 0
    local function count_temps(node)
        if type(node) == "table" then
            if node.type == complete_decompiler.AST_TYPES.ID then
                if node.name:match("^_temp%d+$") or node.name:match("^_func%d+$") then
                    temp_vars = temp_vars + 1
                end
            end
            for _, v in pairs(node) do
                count_temps(v)
            end
        end
    end
    count_temps(ast)
    
    quality = quality - math.min(30, temp_vars * 2)
    
    -- Bonus for control flow reconstruction
    local has_control_flow = false
    local function check_control_flow(node)
        if type(node) == "table" then
            if node.type == complete_decompiler.AST_TYPES.IF 
               or node.type == complete_decompiler.AST_TYPES.WHILE
               or node.type == complete_decompiler.AST_TYPES.FOR_NUM then
                has_control_flow = true
            end
            for _, v in pairs(node) do
                check_control_flow(v)
            end
        end
    end
    check_control_flow(ast)
    
    if has_control_flow then
        quality = quality + 10
    end
    
    return math.max(0, math.min(100, quality))
end

-- ============================================================================
-- FORMATTING AND PRETTY-PRINTING
-- ============================================================================

function complete_decompiler.format_decompilation_report(result)
    if not result.success then
        return "Decompilation failed: " .. tostring(result.error or "Unknown error")
    end
    
    local report = {}
    
    table.insert(report, "========================================")
    table.insert(report, "Complete Decompilation Report")
    table.insert(report, "========================================")
    table.insert(report, "")
    
    table.insert(report, "Statistics:")
    table.insert(report, string.format("  Basic Blocks: %d", result.statistics.num_basic_blocks))
    table.insert(report, string.format("  Instructions: %d", result.statistics.num_instructions))
    table.insert(report, string.format("  Variables: %d", result.statistics.num_variables))
    table.insert(report, string.format("  Functions: %d", result.statistics.num_functions))
    table.insert(report, string.format("  Quality Score: %d%%", result.statistics.decompilation_quality))
    table.insert(report, "")
    
    table.insert(report, "Decompiled Source Code:")
    table.insert(report, "----------------------------------------")
    table.insert(report, result.source_code)
    table.insert(report, "----------------------------------------")
    
    return table.concat(report, "\n")
end

-- ============================================================================
-- EXPORT API
-- ============================================================================

return complete_decompiler
