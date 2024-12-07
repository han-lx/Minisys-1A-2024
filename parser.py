from ply import yacc
from typing import Optional, Dict, Any
from lexer import tokens
from ast_node import ASTNode

# 定义优先级和结合性
precedence = (
    ('left', 'OR_OP'),
    ('left', 'AND_OP'),
    ('left', 'BITOR_OP'),
    ('left', 'BITXOR_OP'),
    ('left', 'BITAND_OP'),
    ('left', 'EQ_OP', 'NE_OP'),
    ('left', 'GT_OP', 'LT_OP', 'GE_OP', 'LE_OP'),
    ('left', 'LEFT_OP', 'RIGHT_OP'),
    ('left', 'PLUS', 'MINUS'),
    ('left', 'MULTIPLY', 'SLASH', 'PERCENT'),
    ('right', 'NOT_OP', 'BITINV_OP'),
)

# 语法规则定义
def p_program(p):
    '''program : decl_list'''
    p[0] = ASTNode('program', 'nonterminal', '')
    p[0].add_child(p[1])

def p_decl_list(p):
    '''decl_list : decl_list decl
                 | decl'''
    p[0] = ASTNode('decl_list', 'nonterminal', '')
    if len(p) == 3:
        p[0].add_child(p[1])
        p[0].add_child(p[2])
    else:
        p[0].add_child(p[1])

def p_decl(p):
    '''decl : var_decl
            | fun_decl'''
    p[0] = ASTNode('decl', 'nonterminal', '')
    p[0].add_child(p[1])

def p_var_decl(p):
    '''var_decl : type_spec IDENTIFIER SEMICOLON
                | type_spec IDENTIFIER LBRACKET CONSTANT RBRACKET SEMICOLON'''
    p[0] = ASTNode('var_decl', 'nonterminal', '')
    p[0].add_child(p[1])
    id_node = ASTNode('IDENTIFIER', 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
    p[0].add_child(id_node)
    if len(p) > 4:
        const_node = ASTNode('CONSTANT', 'token', str(p[4]),p.slice[4].lineno,p.slice[4].lexpos)
        p[0].add_child(const_node)

def p_type_spec(p):
    '''type_spec : VOID
                 | INT
                 | STRING'''
    p[0] = ASTNode('type_spec', 'nonterminal', '')
    type_node = ASTNode(p.slice[1].type, 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
    p[0].add_child(type_node)

def p_fun_decl(p):
    '''fun_decl : type_spec IDENTIFIER LPAREN params RPAREN LBRACE local_decls stmt_list RBRACE
                | type_spec IDENTIFIER LPAREN params RPAREN LBRACE stmt_list RBRACE'''
    p[0] = ASTNode('fun_decl', 'nonterminal', '')
    p[0].add_child(p[1])
    id_node = ASTNode('IDENTIFIER', 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
    p[0].add_child(id_node)
    p[0].add_child(p[4])
    if len(p) == 10:
        p[0].add_child(p[7])
        p[0].add_child(p[8])
    else:
        p[0].add_child(p[7])

def p_params(p):
    '''params : param_list
              | VOID'''
    p[0] = ASTNode('params', 'nonterminal', '')
    if isinstance(p[1], ASTNode):
        p[0].add_child(p[1])
    else:
        void_node = ASTNode('VOID', 'token', 'void',p.slice[1].lineno,p.slice[1].lexpos)
        p[0].add_child(void_node)

def p_param_list(p):
    '''param_list : param_list COMMA param
                  | param'''
    p[0] = ASTNode('param_list', 'nonterminal', '')
    if len(p) == 4:
        p[0].add_child(p[1])
        p[0].add_child(p[3])
    else:
        p[0].add_child(p[1])

def p_param(p):
    '''param : type_spec IDENTIFIER'''
    p[0] = ASTNode('param', 'nonterminal', '')
    p[0].add_child(p[1])
    id_node = ASTNode('IDENTIFIER', 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
    p[0].add_child(id_node)

def p_stmt_list(p):
    '''stmt_list : stmt_list stmt
                 | stmt'''
    p[0] = ASTNode('stmt_list', 'nonterminal', '')
    if len(p) == 3:
        p[0].add_child(p[1])
        p[0].add_child(p[2])
    else:
        p[0].add_child(p[1])

def p_stmt(p):
    '''stmt : expr_stmt
            | compound_stmt
            | if_stmt
            | while_stmt
            | return_stmt
            | continue_stmt
            | break_stmt'''
    p[0] = ASTNode('stmt', 'nonterminal', '')
    p[0].add_child(p[1])

def p_compound_stmt(p):
    '''compound_stmt : LBRACE local_decls stmt_list RBRACE
                     | LBRACE stmt_list RBRACE'''
    p[0] = ASTNode('compound_stmt', 'nonterminal', '')
    if len(p) == 5:
        p[0].add_child(p[2])
        p[0].add_child(p[3])
    else:
        p[0].add_child(p[2])

def p_if_stmt(p):
    '''if_stmt : IF LPAREN expr RPAREN stmt'''
    p[0] = ASTNode('if_stmt', 'nonterminal', '')
    p[0].add_child(p[3])
    p[0].add_child(p[5])

def p_while_stmt(p):
    '''while_stmt : WHILE LPAREN expr RPAREN stmt'''
    p[0] = ASTNode('while_stmt', 'nonterminal', '')
    p[0].add_child(p[3])
    p[0].add_child(p[5])

def p_continue_stmt(p):
    '''continue_stmt : CONTINUE SEMICOLON'''
    p[0] = ASTNode('continue_stmt', 'nonterminal', '')

def p_break_stmt(p):
    '''break_stmt : BREAK SEMICOLON'''
    p[0] = ASTNode('break_stmt', 'nonterminal', '')

def p_expr_stmt(p):
    '''expr_stmt : IDENTIFIER ASSIGN expr SEMICOLON
                 | IDENTIFIER LBRACKET expr RBRACKET ASSIGN expr SEMICOLON
                 | DOLLAR expr ASSIGN expr SEMICOLON
                 | IDENTIFIER LPAREN args RPAREN SEMICOLON
                 | IDENTIFIER LPAREN RPAREN SEMICOLON'''
    p[0] = ASTNode('expr_stmt', 'nonterminal', '')

    if len(p) == 5 and p.slice[2].type == 'ASSIGN':
        # IDENTIFIER ASSIGN expr SEMICOLON
        id_node = ASTNode('IDENTIFIER', 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
        assign_node = ASTNode('ASSIGN', 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
        p[0].add_child(id_node)
        p[0].add_child(assign_node)
        p[0].add_child(p[3])
    elif len(p) == 8:
        # IDENTIFIER LBRACKET expr RBRACKET ASSIGN expr SEMICOLON
        id_node = ASTNode('IDENTIFIER', 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
        lbracket_node = ASTNode('LBRACKET', 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
        rbracket_node = ASTNode('RBRACKET', 'token', p[4],p.slice[4].lineno,p.slice[4].lexpos)
        assign_node = ASTNode('ASSIGN', 'token', p[5],p.slice[5].lineno,p.slice[5].lexpos)
        p[0].add_child(id_node)
        p[0].add_child(lbracket_node)
        p[0].add_child(p[3])  # Index expression
        p[0].add_child(rbracket_node)
        p[0].add_child(assign_node)
        p[0].add_child(p[6])  # Assigned expression
    elif len(p) == 6 and p.slice[1].type == 'DOLLAR':
        # DOLLAR expr ASSIGN expr SEMICOLON
        dollar_node = ASTNode('DOLLAR', 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
        assign_node = ASTNode('ASSIGN', 'token', p[3],p.slice[3].lineno,p.slice[3].lexpos)
        p[0].add_child(dollar_node)
        p[0].add_child(p[2])
        p[0].add_child(assign_node)
        p[0].add_child(p[4])
    elif len(p) == 6 and p.slice[2].type == 'LPAREN':
        # IDENTIFIER LPAREN args RPAREN SEMICOLON
        id_node = ASTNode('IDENTIFIER', 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
        lparen_node = ASTNode('LPAREN', 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
        args_node = p[3]
        rparen_node = ASTNode('RPAREN', 'token', p[4],p.slice[4].lineno,p.slice[4].lexpos)
        p[0].add_child(id_node)
        p[0].add_child(lparen_node)
        p[0].add_child(args_node)
        p[0].add_child(rparen_node)
    elif len(p) == 5 and p.slice[2].type == 'LPAREN':
        # IDENTIFIER LPAREN RPAREN SEMICOLON
        id_node = ASTNode('IDENTIFIER', 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
        lparen_node = ASTNode('LPAREN', 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
        rparen_node = ASTNode('RPAREN', 'token', p[3],p.slice[3].lineno,p.slice[3].lexpos)
        p[0].add_child(id_node)
        p[0].add_child(lparen_node)
        p[0].add_child(rparen_node)
    else:
        # Should not reach here
        print("Error in expr_stmt parsing")

def p_local_decls(p):
    '''local_decls : local_decls local_decl
                   | local_decl'''
    p[0] = ASTNode('local_decls', 'nonterminal', '')
    if len(p) == 3:
        p[0].add_child(p[1])
        p[0].add_child(p[2])
    else:
        p[0].add_child(p[1])

def p_local_decl(p):
    '''local_decl : type_spec IDENTIFIER SEMICOLON
                  | type_spec IDENTIFIER LBRACKET CONSTANT RBRACKET SEMICOLON'''
    p[0] = ASTNode('local_decl', 'nonterminal', '')
    p[0].add_child(p[1])
    id_node = ASTNode('IDENTIFIER', 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
    p[0].add_child(id_node)
    if len(p) > 4:
        const_node = ASTNode('CONSTANT', 'token', str(p[4]),p.slice[4].lineno,p.slice[4].lexpos)
        p[0].add_child(const_node)

def p_return_stmt(p):
    '''return_stmt : RETURN SEMICOLON
                   | RETURN expr SEMICOLON'''
    p[0] = ASTNode('return_stmt', 'nonterminal', '')
    if len(p) == 4:
        p[0].add_child(p[2])

def p_expr_binary(p):
    '''expr : expr OR_OP expr
            | expr AND_OP expr
            | expr EQ_OP expr
            | expr NE_OP expr
            | expr GT_OP expr
            | expr LT_OP expr
            | expr GE_OP expr
            | expr LE_OP expr
            | expr PLUS expr
            | expr MINUS expr
            | expr MULTIPLY expr
            | expr SLASH expr
            | expr PERCENT expr
            | expr BITAND_OP expr
            | expr BITXOR_OP expr
            | expr LEFT_OP expr
            | expr RIGHT_OP expr
            | expr BITOR_OP expr'''
    p[0] = ASTNode('expr', 'nonterminal', '')
    p[0].add_child(p[1])
    op_node = ASTNode(p.slice[2].type, 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
    p[0].add_child(op_node)
    p[0].add_child(p[3])

def p_expr_unary(p):
    '''expr : NOT_OP expr
            | MINUS expr
            | PLUS expr
            | BITINV_OP expr
            | DOLLAR expr'''
    p[0] = ASTNode('expr', 'nonterminal', '')
    op_node = ASTNode(p.slice[1].type, 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
    p[0].add_child(op_node)
    p[0].add_child(p[2])

def p_expr_group(p):
    '''expr : LPAREN expr RPAREN'''
    p[0] = ASTNode('expr', 'nonterminal', '')
    # Left parenthesis
    lparen_node = ASTNode('LPAREN', 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
    p[0].add_child(lparen_node)
    # Expression inside parentheses
    p[0].add_child(p[2])
    # Right parenthesis
    rparen_node = ASTNode('RPAREN', 'token', p[3],p.slice[3].lineno,p.slice[3].lexpos)
    p[0].add_child(rparen_node)

def p_expr_token(p):
    '''expr : IDENTIFIER
            | CONSTANT
            | STRING_LITERAL'''
    p[0] = ASTNode('expr', 'nonterminal', '')
    token_node = ASTNode(p.slice[1].type, 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
    p[0].add_child(token_node)

def p_expr_array_access(p):
    '''expr : IDENTIFIER LBRACKET expr RBRACKET'''
    p[0] = ASTNode('expr', 'nonterminal', '')
    # Identifier
    id_node = ASTNode('IDENTIFIER', 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
    p[0].add_child(id_node)
    # Left bracket
    lbracket_node = ASTNode('LBRACKET', 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
    p[0].add_child(lbracket_node)
    # Index expression
    p[0].add_child(p[3])
    # Right bracket
    rbracket_node = ASTNode('RBRACKET', 'token', p[4],p.slice[4].lineno,p.slice[4].lexpos)
    p[0].add_child(rbracket_node)

def p_expr_function_call(p):
    '''expr : IDENTIFIER LPAREN args RPAREN
            | IDENTIFIER LPAREN RPAREN'''
    p[0] = ASTNode('expr', 'nonterminal', '')
    # Identifier
    id_node = ASTNode('IDENTIFIER', 'token', p[1],p.slice[1].lineno,p.slice[1].lexpos)
    p[0].add_child(id_node)
    # Left parenthesis
    lparen_node = ASTNode('LPAREN', 'token', p[2],p.slice[2].lineno,p.slice[2].lexpos)
    p[0].add_child(lparen_node)
    if len(p) == 5:
        # Arguments
        p[0].add_child(p[3])
        # Right parenthesis
        rparen_node = ASTNode('RPAREN', 'token', p[4],p.slice[4].lineno,p.slice[4].lexpos)
        p[0].add_child(rparen_node)
    else:
        # Right parenthesis
        rparen_node = ASTNode('RPAREN', 'token', p[3],p.slice[3].lineno,p.slice[3].lexpos)
        p[0].add_child(rparen_node)

def p_args(p):
    '''args : args COMMA expr
            | expr'''
    p[0] = ASTNode('args', 'nonterminal', '')
    if len(p) == 4:
        p[0].add_child(p[1])
        p[0].add_child(p[3])
    else:
        p[0].add_child(p[1])

def p_error(p):
    if p:
        print(f"Syntax error at '{p.value}', line {p.lineno}, position {p.lexpos}")
    else:
        print("Syntax error at EOF")

# 构建语法分析器
parser = yacc.yacc()

def parse(data: str) -> Optional[ASTNode]:
    """语法分析,返回AST根节点"""
    if not data.strip():
        return None
    return parser.parse(data, tracking=True)
   
  