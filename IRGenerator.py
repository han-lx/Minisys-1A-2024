# ir_generator.py
from typing import List, Optional, Union
from ast_node import ASTNode
from ir import Quad, IRVar, IRArray, IRFunc, BasicBlock

GLOBAL_SCOPE = [0]  # 0号作用域是全局作用域
LABEL_PREFIX = '_label_'
VAR_PREFIX = '_var_'

class IRGenerator:
    def __init__(self, root: ASTNode):
        self.func_pool: List[IRFunc] = []  # 所有函数
        self.var_pool: List[Union[IRVar, IRArray]] = []  # 所有变量
        self.quads: List[Quad] = []  # 所有四元式
        self.basic_blocks: List[BasicBlock] = []  # 基本块
        
        self.var_count = 0  # 变量计数
        self.label_count = 0  # 标号计数
        self.scope_count = 0  # 作用域计数
        self.scope_path = GLOBAL_SCOPE.copy()  # 当前作用域路径
        
        self.loop_stack = []  # break、continue辅助栈
        self.post_checks = []  # 后置检查
        self.calls_in_scope = []  # 各个作用域下进行的函数调用
        
        # 开始遍历
        self.start(root)
        
        # 添加内置函数__asm
        self.push_scope()
        self.func_pool.append(
            IRFunc('__asm', 'void',
                  [IRVar(self.new_var_id(), 'asm', 'string', self.scope_path, True)],
                  self.new_label('__asm_entry'),
                  self.new_label('__asm_exit'),
                  self.scope_path,
                  True)
        )
        self.pop_scope()
        
        # 后置检查与处理
        self.post_process1()
        self.post_check()
        self.post_process2()
        self.to_basic_blocks()

    def new_var_id(self) -> str:
        """分配一个新的变量id"""
        var_id = f"{VAR_PREFIX}{self.var_count}"
        self.var_count += 1
        return var_id
    
    def new_label(self, desc: str = '') -> str:
        """分配一个新标号"""
        label = f"{LABEL_PREFIX}{self.label_count}_{desc}"
        self.label_count += 1
        return label
    
    def new_quad(self, op: str, arg1: str, arg2: str, res: str) -> Quad:
        """新增一条四元式并返回"""
        quad = Quad(op, arg1, arg2, res)
        self.quads.append(quad)
        return quad
    
    def new_var(self, v: Union[IRVar, IRArray]):
        """新增一个变量"""
        self.var_pool.append(v)
    
    def push_scope(self):
        """进一层作用域"""
        self.scope_count += 1
        self.scope_path.append(self.scope_count)
    
    def pop_scope(self):
        """退出当前作用域"""
        return self.scope_path.pop()
    
    @staticmethod
    def same_scope(scope1: list, scope2: list) -> bool:
        """判断两个作用域是否相同"""
        return '/'.join(map(str, scope1)) == '/'.join(map(str, scope2))
    
    @staticmethod
    def in_scope(big_scope: list, small_scope: list) -> bool:
        """判断作用域包含关系"""
        if len(big_scope) > len(small_scope):
            return False
        return all(small_scope[i] == big_scope[i] for i in range(len(big_scope)))
    
    def find_var(self, name: str) -> Union[IRVar, IRArray]:
        """结合当前所在的作用域寻找最近的名字相符的变量"""
        valid_scopes = []
        current_scope = self.scope_path.copy()
        while current_scope:
            valid_scopes.append(current_scope.copy())
            current_scope.pop()
            
        # valid_scopes由近及远
        for scope in valid_scopes:
            for v in self.var_pool:
                if v.name == name and self.same_scope(v.scope, scope):
                    return v
        assert False, f"未找到该变量：{name}"
        return IRVar('-1', '', 'none', [], False)
    
    def duplicate_check(self, v1: Union[IRVar, IRArray], v2: Union[IRVar, IRArray]) -> bool:
        """检查变量是否重复"""
        return (v1.name == v2.name and 
                '/'.join(map(str, v1.scope)) == '/'.join(map(str, v2.scope)))

    def to_ir_string(self) -> str:
        """生成IR字符串表示"""
        res = '[FUNCTIONS]\n'
        for func in self.func_pool:
            res += f'\tname: {func.name}\n'
            res += f'\tretType: {func.ret_type}\n'
            res += '\tparamList: ' + '; '.join([f'{p.id}({p.type})' for p in func.param_list]) + '\n\n'
            
        res += '[GLOBALVARS]\n'
        for v in self.var_pool:
            if self.same_scope(v.scope, GLOBAL_SCOPE):
                var_type = 'arr' if isinstance(v, IRArray) else 'var'
                res += f'\t{v.id}({v.type}, {var_type})\n'
        res += '\n'
        
        res += '[VARPOOL]\n'
        for v in self.var_pool:
            var_type = 'arr' if isinstance(v, IRArray) else 'var'
            res += f'\t{v.id}, {v.name}, {v.type}, {var_type}, {"/".join(map(str,v.scope))}\n'
        res += '\n'
        
        res += '[QUADS]\n'
        for quad in self.quads:
            res += f'\t{quad}\n'
        res += '\n'
        
        return res

    def start(self, node: ASTNode):
        """开始遍历AST"""
        if not node:
            assert False, 'AST根节点为null'
        self.parse_program(node)

    def parse_program(self, node: ASTNode):
        """解析程序入口"""
        self.parse_decl_list(node[1])

    def parse_decl_list(self, node: ASTNode):
        """解析声明列表"""
        if node[1].name == 'decl_list':
            self.parse_decl_list(node[1])
            self.parse_decl(node[2])
        elif node[1].name == 'decl':
            self.parse_decl(node[1])

    def parse_decl(self, node: ASTNode):
        """解析声明"""
        if node[1].name == 'var_decl':
            self.parse_var_decl(node[1])
        elif node[1].name == 'fun_decl':
            self.parse_fun_decl(node[1])

    def parse_var_decl(self, node: ASTNode):
        """解析变量声明"""
        # 全局变量声明
        if node.match('type_spec IDENTIFIER'):
            type_ = self.parse_type_spec(node[1])
            name = node[2].literal
            assert type_ != 'void', f'不可以声明void型变量：{name}'
            self.scope_path = GLOBAL_SCOPE
            assert not any(self.same_scope(v.scope, GLOBAL_SCOPE) and v.name == name 
                          for v in self.var_pool), f'全局变量重复声明：{name}'
            self.new_var(IRVar(self.new_var_id(), name, type_, self.scope_path, False))
        
        # 全局数组声明
        elif node.match('type_spec IDENTIFIER CONSTANT'):
            type_ = self.parse_type_spec(node[1])
            name = node[2].literal
            len_ = int(node[3].literal)
            self.scope_path = GLOBAL_SCOPE
            assert not isnan(len_) and len_ > 0 and floor(len_) == len_, \
                f'数组长度必须为正整数字面量，但取到 {node[3].literal}'
            self.new_var(IRArray(self.new_var_id(), type_, name, len_, self.scope_path))

    def parse_type_spec(self, node: ASTNode) -> str:
        """解析类型说明符"""
        return node[1].literal

    def parse_fun_decl(self, node: ASTNode):
        """解析函数声明"""
        # 规定所有的函数都在全局作用域
        ret_type = self.parse_type_spec(node[1])
        func_name = node[2].literal
        assert not any(f.name == func_name for f in self.func_pool), \
            f'函数重复定义：{func_name}'
        
        # 参数列表在parse_params时会填上
        entry_label = self.new_label(func_name + '_entry')
        exit_label = self.new_label(func_name + '_exit')
        
        # 进一层作用域
        self.push_scope()
        
        # 添加新函数
        self.func_pool.append(
            IRFunc(func_name, ret_type, [], entry_label, exit_label, 
                   self.scope_path.copy())
        )
        self.new_quad('set_label', '', '', entry_label)  # 函数入口
        
        # 解析函数参数
        self.parse_params(node[3], func_name)
        
        # 解析函数体
        if len(node.children) == 5:
            self.parse_local_decls(node[4])
            self.parse_stmt_list(node[5], {
                'entryLabel': entry_label,
                'exitLabel': exit_label,
                'funcName': func_name
            })
        elif len(node.children) == 4:
            # 没有局部变量
            self.parse_stmt_list(node[4], {
                'entryLabel': entry_label,
                'exitLabel': exit_label,
                'funcName': func_name
            })
        
        self.new_quad('set_label', '', '', exit_label)  # 函数出口
        
        # 退一层作用域
        self.pop_scope()

    def parse_params(self, node: ASTNode, func_name: str):
        """解析函数参数"""
        if node[1].name == 'VOID':
            next(f for f in self.func_pool if f.name == func_name).param_list = []
        elif node[1].name == 'param_list':
            self.parse_param_list(node[1], func_name)

    def parse_param_list(self, node: ASTNode, func_name: str):
        """解析参数列表"""
        if node[1].name == 'param_list':
            # 左递归文法加上这里的递归顺序使得参数列表保序
            self.parse_param_list(node[1], func_name)
            self.parse_param(node[2], func_name)
        elif node[1].name == 'param':
            self.parse_param(node[1], func_name)

    def parse_param(self, node: ASTNode, func_name: str):
        """解析单个参数"""
        type_ = self.parse_type_spec(node[1])
        assert type_ != 'void', '不可以用void作参数类型。函数：' + func_name
        name = node[2].literal
        var_ = IRVar(self.new_var_id(), name, type_, self.scope_path, True)
        self.new_var(var_)
        # 将形参送给函数
        next(f for f in self.func_pool if f.name == func_name).param_list.append(var_)

    def parse_stmt_list(self, node: ASTNode, context: dict = None):
        """解析语句列表"""
        if node[1].name == 'stmt_list':
            self.parse_stmt_list(node[1], context)
            self.parse_stmt(node[2], context)
        elif node[1].name == 'stmt':
            self.parse_stmt(node[1], context)

    def parse_stmt(self, node: ASTNode, context: dict = None):
        """解析语句"""
        if node[1].name == 'expr_stmt':
            self.parse_expr_stmt(node[1])
        elif node[1].name == 'compound_stmt':
            self.parse_compound_stmt(node[1], context)
        elif node[1].name == 'if_stmt':
            self.parse_if_stmt(node[1], context)
        elif node[1].name == 'while_stmt':
            self.parse_while_stmt(node[1], context)
        elif node[1].name == 'return_stmt':
            self.parse_return_stmt(node[1], context)
        elif node[1].name == 'continue_stmt':
            self.parse_continue_stmt(node[1])
        elif node[1].name == 'break_stmt':
            self.parse_break_stmt(node[1])

    def parse_compound_stmt(self, node: ASTNode, context: dict = None):
        """解析复合语句"""
        self.push_scope()
        if len(node.children) == 2:
            self.parse_local_decls(node[1])
            self.parse_stmt_list(node[2], context)
        elif len(node.children) == 1:
            # 没有局部变量
            self.parse_stmt_list(node[1], context)
        self.pop_scope()

    def parse_if_stmt(self, node: ASTNode, context: dict = None):
        """解析if语句"""
        expr = self.parse_expr(node[1])
        true_label = self.new_label('true')  # 真入口标号
        false_label = self.new_label('false')  # 假入口标号
        self.new_quad('set_label', '', '', true_label)
        self.new_quad('j_false', expr, '', false_label)
        self.parse_stmt(node[2], context)
        self.new_quad('set_label', '', '', false_label)

    def parse_while_stmt(self, node: ASTNode, context: dict = None):
        """解析while语句"""
        loop_label = self.new_label('loop')  # 入口标号
        break_label = self.new_label('break')  # 出口标号
        self.loop_stack.append({'loopLabel': loop_label, 'breakLabel': break_label})
        self.new_quad('set_label', '', '', loop_label)
        expr = self.parse_expr(node[1])
        self.new_quad('j_false', expr, '', break_label)
        self.parse_stmt(node[2], context)
        self.new_quad('j', '', '', loop_label)
        self.new_quad('set_label', '', '', break_label)
        self.loop_stack.pop()

    def parse_continue_stmt(self, node: ASTNode):
        """解析continue语句"""
        assert len(self.loop_stack) > 0, '产生continue时没有足够的上下文'
        self.new_quad('j', '', '', self.loop_stack[-1]['loopLabel'])

    def parse_break_stmt(self, node: ASTNode):
        """解析break语句"""
        assert len(self.loop_stack) > 0, '产生break时没有足够的上下文'
        self.new_quad('j', '', '', self.loop_stack[-1]['breakLabel'])

    def parse_expr_stmt(self, node: ASTNode):
        """解析表达式语句"""
        # 变量赋值
        if node.match('IDENTIFIER ASSIGN expr'):
            lhs = self.find_var(node[1].literal)
            if isinstance(lhs, IRVar):
                lhs.inited = True
            rhs = self.parse_expr(node[3])
            self.new_quad('=var', rhs, '', lhs.id)
        
        # 读数组
        elif node.match('IDENTIFIER expr ASSIGN expr'):
            arr = self.find_var(node[1].literal)
            index = self.parse_expr(node[2])
            rhs = self.parse_expr(node[4])
            self.new_quad('=[]', index, rhs, arr.id)
        
        # 访地址
        elif node.match('DOLLAR expr ASSIGN expr'):
            addr = self.parse_expr(node[2])
            rhs = self.parse_expr(node[4])
            self.new_quad('=$', addr, rhs, '')
        
        # 调函数(有参)
        elif node.match('IDENTIFIER args'):
            args = self.parse_args(node[2])
            func_name = node[1].literal
            assert func_name != 'main', '禁止手动或递归调用main函数'
            
            self.post_checks.append({
                'checker': lambda: any(f.name == func_name for f in self.func_pool),
                'hint': f'未声明就调用了函数 {func_name}'
            })
            
            self.post_checks.append({
                'checker': lambda: len(args) == len(next(f for f in self.func_pool 
                                                       if f.name == func_name).param_list),
                'hint': f'函数 {func_name} 调用参数数量不匹配'
            })
            
            self.new_quad('call', func_name, '&'.join(args), '')
            self.calls_in_scope.append({
                'scopePath': self.scope_path.copy(),
                'funcName': func_name
            })
        
        # 调函数(无参)
        elif node.match('IDENTIFIER LPAREN RPAREN'):
            func_name = node[1].literal
            assert func_name != 'main', '禁止手动或递归调用main函数'
            
            self.post_checks.append({
                'checker': lambda: any(f.name == func_name for f in self.func_pool),
                'hint': f'未声明就调用了函数 {func_name}'
            })
            
            self.post_checks.append({
                'checker': lambda: len(next(f for f in self.func_pool 
                                          if f.name == func_name).param_list) == 0,
                'hint': f'函数 {func_name} 调用参数数量不匹配'
            })
            
            self.new_quad('call', func_name, '', '')
            self.calls_in_scope.append({
                'scopePath': self.scope_path.copy(),
                'funcName': func_name
            })

    def parse_local_decls(self, node: ASTNode):
        """解析局部声明"""
        if node[1].name == 'local_decls':
            self.parse_local_decls(node[1])
            self.parse_local_decl(node[2])
        elif node[1].name == 'local_decl':
            self.parse_local_decl(node[1])

    def parse_local_decl(self, node: ASTNode):
        """解析局部声明"""
        if len(node.children) == 2:
            # 单个变量声明
            type_ = self.parse_type_spec(node[1])
            name = node[2].literal
            var_ = IRVar(self.new_var_id(), name, type_, self.scope_path, False)
            assert not any(self.duplicate_check(v, var_) for v in self.var_pool), \
                '局部变量重复声明：' + name
            self.new_var(var_)
        elif len(node.children) == 3:
            # 数组声明
            assert False, f'数组只能声明在全局作用域，而 {node[2].literal} 不符合。'

    def parse_return_stmt(self, node: ASTNode, context: dict):
        """解析return语句"""
        next(f for f in self.func_pool if f.name == context['funcName']).has_return = True
        
        # return;
        if len(node.children) == 0:
            self.post_checks.append({
                'checker': lambda: next(f for f in self.func_pool 
                                      if f.name == context['funcName']).ret_type == 'void',
                'hint': f'函数 {context["funcName"]} 没有返回值'
            })
            self.new_quad('return_void', '', '', context['exitLabel'])
        
        # return expr;
        elif len(node.children) == 1:
            self.post_checks.append({
                'checker': lambda: next(f for f in self.func_pool 
                                      if f.name == context['funcName']).ret_type != 'void',
                'hint': f'函数 {context["funcName"]} 声明返回值类型是 void，却有返回值'
            })
            expr = self.parse_expr(node[1])
            self.new_quad('return_expr', expr, '', context['exitLabel'])

    def parse_expr(self, node: ASTNode) -> str:
        """处理expr，返回指代expr结果的IRVar的id"""
        # 处理特殊情况
        if node.match('LPAREN expr RPAREN'):
            # 括号表达式
            oprand = self.parse_expr(node[2])
            res = self.new_var_id()
            self.new_quad('=var', oprand, '', res)
            return res
        
        if node.match('IDENTIFIER'):
            # 访问变量
            var_ = self.find_var(node[1].literal)
            if isinstance(var_, IRVar):
                assert var_.inited, f'在初始化前使用了变量：{var_.name}'
            return var_.id
        
        if node.match('IDENTIFIER expr'):
            # 访问数组元素
            index = self.parse_expr(node[2])
            name = node[1].literal
            res = self.new_var_id()
            self.new_quad('[]', self.find_var(name).id, index, res)
            return res
        
        if node.match('IDENTIFIER args'):
            # 调用函数（有参）
            func_name = node[1].literal
            assert func_name != 'main', '禁止手动或递归调用main函数'
            # 作为表达式的函数调用应该有返回值
            self.post_checks.append({
                'checker': lambda: next(f for f in self.func_pool 
                                      if f.name == func_name).ret_type != 'void',
                'hint': f'函数 {func_name} 没有返回值，其调用不能作为表达式'
            })
            args = self.parse_args(node[2])
            res = self.new_var_id()
            assert len(args) == len(next(f for f in self.func_pool 
                                       if f.name == func_name).param_list), \
                f'函数 {func_name} 调用参数数量不匹配'
            self.new_quad('call', func_name, '&'.join(args), res)
            self.calls_in_scope.append({
                'scopePath': self.scope_path.copy(),
                'funcName': func_name
            })
            return res
        
        if node.match('IDENTIFIER LPAREN RPAREN'):
            # 调用函数（无参）
            func_name = node[1].literal
            assert func_name != 'main', '禁止手动或递归调用main函数'
            # 作为表达式的函数调用应该有返回值
            self.post_checks.append({
                'checker': lambda: next(f for f in self.func_pool 
                                      if f.name == func_name).ret_type != 'void',
                'hint': f'函数 {func_name} 没有返回值，其调用不能作为表达式'
            })
            res = self.new_var_id()
            self.new_quad('call', func_name, '', res)
            self.calls_in_scope.append({
                'scopePath': self.scope_path.copy(),
                'funcName': func_name
            })
            return res
        
        if node.match('CONSTANT'):
            # 常量
            res = self.new_var_id()
            self.new_quad('=const', node[1].literal, '', res)
            return res
        
        if node.match('STRING_LITERAL'):
            # 字符串字面
            res = self.new_var_id()
            self.new_quad('=string', node[1].literal, '', res)
            return res
        
        # 处理所有二元表达式 expr op expr
        if (len(node.children) == 3 and 
            node[1].name == 'expr' and node[3].name == 'expr'):
            oprand1 = self.parse_expr(node[1])
            oprand2 = self.parse_expr(node[3])
            res = self.new_var_id()
            self.new_quad(node[2].name, oprand1, oprand2, res)
            return res
        
        # 处理所有一元表达式 op expr
        if len(node.children) == 2:
            # NOT_OP, MINUS, PLUS, DOLLAR, BITINV_OP
            oprand = self.parse_expr(node[2])
            res = self.new_var_id()
            self.new_quad(node[1].name, oprand, '', res)
            return res
        
        assert False, 'parse_expr兜底失败'
        return '-1'

    def parse_args(self, node: ASTNode) -> List[str]:
        """按参数顺序返回IRVar.id[]"""
        if node[1].name == 'args':
            return [*self.parse_args(node[1]), self.parse_expr(node[2])]
        elif node[1].name == 'expr':
            return [self.parse_expr(node[1])]
        return []

    def post_check(self):
        """后检查"""
        for check in self.post_checks:
            assert check['checker'](), check['hint']
        assert any(f.name == 'main' for f in self.func_pool), '程序没有 main 函数'
        for func in self.func_pool:
            # 有可能通过内联汇编自行处理了return
            assert func.has_return or 'asm' in func.child_funcs, \
                f'函数 {func.name} 没有 return 语句'

    def post_process1(self):
        """后处理1"""
        # 补充函数信息，供汇编生成使用
        for func in self.func_pool:
            # 填充函数的局部变量
            func.local_vars.extend(
                v for v in self.var_pool 
                if self.in_scope(func.scope_path, v.scope)
            )
            # 填充函数内部调用的其他函数
            func.child_funcs.extend(
                list(set(
                    call['funcName'] for call in self.calls_in_scope
                    if self.in_scope(func.scope_path, call['scopePath'])
                ))
            )

    def post_process2(self):
        """后处理2"""
        # 折叠 __asm
        # (=const, "str", , _var_0), (call, __asm, _var_0, ) --> (out_asm, "str", ,)
        for i in range(len(self.quads)):
            quad = self.quads[i]
            if quad.op == 'call' and quad.arg1 == '__asm':
                assert i >= 1, '对 __asm 的调用出现在不正确的位置'
                prev = self.quads[i - 1]
                assert len(quad.arg2.split('&')) == 1, '__asm 只接受一个字符串字面参数'
                assert (prev.op == '=string' and prev.res == quad.arg2), \
                    '未找到 __asm 的调用参数'
                assert prev.arg1.startswith('"') and prev.arg1.endswith('"'), \
                    '__asm 只接受一个字符串字面参数'
                self.quads[i] = Quad('out_asm', prev.arg1, '', '')
                self.quads[i - 1] = None
        
        self.quads = [q for q in self.quads if q is not None]

    def to_basic_blocks(self):
        """对四元式进行基本块划分
        龙书算法8.5
        """
        leaders = []  # 首指令下标
        next_flag = False
        
        for i in range(len(self.quads)):
            if i == 0:
                # 中间代码的第一个四元式是一个首指令
                leaders.append(i)
                continue
            
            if (self.quads[i].op == 'set_label' and 
                self.quads[i].res.endswith('entry')):
                leaders.append(i)
                continue
            
            if self.quads[i].op in ('j', 'j_false'):
                # 条件或无条件转移指令的目标指令是一个首指令
                leaders.append(next(
                    j for j, q in enumerate(self.quads)
                    if q.op == 'set_label' and q.res == self.quads[i].res
                ))
                next_flag = True
                continue
            
            if next_flag:
                # 紧跟在一个条件或无条件转移指令之后的指令是一个首指令
                leaders.append(i)
                next_flag = False
                continue
            
        leaders = sorted(set(leaders))
        if leaders[-1] != len(self.quads):
            leaders.append(len(self.quads))
        
        # 每个首指令左闭右开地划分了四元式
        res = []
        id_ = 0
        for i in range(len(leaders) - 1):
            res.append(BasicBlock(
                id_,
                self.quads[leaders[i]:leaders[i + 1]]
            ))
            id_ += 1
        
        self.basic_blocks = res