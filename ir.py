# ir.py
class Quad:
    """四元式 (op, arg1, arg2, res)"""
    def __init__(self, op: str, arg1: str, arg2: str, res: str):
        self.op = op
        self.arg1 = arg1 
        self.arg2 = arg2
        self.res = res
        
    def __str__(self):
        pad_end = 12
        return f"({self.op:<{pad_end}}, {self.arg1:<{pad_end}}, {self.arg2:<{pad_end}}, {self.res:<{pad_end+8}})"

class IRVar:
    """IR阶段变量信息存储"""
    def __init__(self, id: str, name: str, type: str, scope: list, inited: bool = False):
        self.id = id
        self.name = name
        self.type = type
        self.scope = scope.copy()
        self.inited = inited

class IRArray:
    """IR阶段数组信息存储"""
    def __init__(self, id: str, type: str, name: str, len: int, scope: list):
        self.id = id
        self.type = type
        self.name = name
        self.len = len
        self.scope = scope.copy()

class IRFunc:
    """IR阶段函数信息存储"""
    def __init__(self, name: str, ret_type: str, param_list: list,
                 entry_label: str, exit_label: str, scope_path: list, has_return: bool = False):
        self.name = name
        self.ret_type = ret_type
        self.param_list = param_list
        self.entry_label = entry_label
        self.exit_label = exit_label
        self.local_vars = []
        self.child_funcs = []
        self.scope_path = scope_path.copy()
        self.has_return = has_return

class BasicBlock:
    """基本块"""
    def __init__(self, id: int, content: list):
        self.id = id
        self.content = content