from ply import lex
from typing import List, Dict, Any

tokens = [
    'IDENTIFIER', 'CONSTANT', 'RIGHT_OP', 'LEFT_OP', 'AND_OP', 'OR_OP', 
    'LE_OP', 'GE_OP', 'EQ_OP', 'NE_OP', 'SEMICOLON', 'LBRACE', 'RBRACE', 
    'COMMA', 'COLON', 'ASSIGN', 'LPAREN', 'RPAREN', 'LBRACKET', 'RBRACKET', 
    'DOT', 'BITAND_OP', 'NOT_OP', 'BITINV_OP', 'MINUS', 'PLUS', 'MULTIPLY', 
    'SLASH', 'PERCENT', 'LT_OP', 'GT_OP', 'BITXOR_OP', 'BITOR_OP', 'DOLLAR', 
    'STRING_LITERAL'
]

reserved = {
    'break': 'BREAK',
    'continue': 'CONTINUE',
    'if': 'IF',
    'int': 'INT',
    'string': 'STRING',
    'return': 'RETURN',
    'void': 'VOID',
    'while': 'WHILE',
}

# 将保留字添加到tokens列表
tokens = list(reserved.values()) + tokens

t_RIGHT_OP    = r'>>'
t_LEFT_OP     = r'<<'
t_AND_OP      = r'&&'
t_OR_OP       = r'\|\|'
t_LE_OP       = r'<='
t_GE_OP       = r'>='
t_EQ_OP       = r'=='
t_NE_OP       = r'!='
t_SEMICOLON   = r';'
t_LBRACE      = r'\{'
t_RBRACE      = r'\}'
t_COMMA       = r','
t_COLON       = r':'
t_ASSIGN      = r'='
t_LPAREN      = r'\('
t_RPAREN      = r'\)'
t_LBRACKET    = r'\['
t_RBRACKET    = r'\]'
t_DOT         = r'\.'
t_BITAND_OP   = r'&'
t_NOT_OP      = r'!'
t_BITINV_OP   = r'~'
t_MINUS       = r'-'
t_PLUS        = r'\+'
t_MULTIPLY    = r'\*'
t_SLASH       = r'/'
t_PERCENT     = r'%'
t_LT_OP       = r'<'
t_GT_OP       = r'>'
t_BITXOR_OP   = r'\^'
t_BITOR_OP    = r'\|'
t_DOLLAR      = r'\$'

def t_IDENTIFIER(t):
    r'[a-zA-Z_][a-zA-Z0-9_]*'
    # Check for reserved words
    t.type = reserved.get(t.value, 'IDENTIFIER')
    return t

def t_CONSTANT(t):
    r'0x[a-fA-F0-9]+|[1-9][0-9]*|0'
    return t

def t_STRING_LITERAL(t):
    r'"[^"\n]*"'
    return t

# Comments
def t_COMMENT(t):
    r'//.*'
    pass  # Ignore comments

# Ignored characters (whitespace)
t_ignore  = ' \t\r'

# Newline handling
def t_newline(t):
    r'\n+'
    t.lexer.lineno += len(t.value)

# Error handling
def t_error(t):
    print(f"Illegal character '{t.value[0]}'")
    t.lexer.skip(1)


# 构建词法分析器
lexer = lex.lex()

def tokenize(data: str) -> List[Dict[str, Any]]:
    """词法分析,返回token列表"""
    lexer.input(data)
    tokens = []
    while True:
        tok = lexer.token()
        if not tok:
            break
        tokens.append({
            'name': tok.type,
            'literal': str(tok.value)
        })
    return tokens

if __name__ == "__main__":
    with open('test.c', 'r', encoding='utf-8') as f:
        source = f.read()
    tokens = tokenize(source)
    print(tokens)