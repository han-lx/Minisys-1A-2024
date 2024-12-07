from typing import List, Dict, Optional, Union, Set
from ir import Quad, IRVar, IRArray, IRFunc, BasicBlock
from IRGenerator import IRGenerator, VAR_PREFIX
from asm.Arch import IO_MAX_ADDR

class IROptimizer:
    """中间代码优化器"""
    def __init__(self, ir: IRGenerator):
        self._ir = ir
        self._logs: List[str] = []
        
        # 不动点法
        while True:
            unfix = False
            # 死代码消除
            unfix = self.dead_var_eliminate() or unfix
            unfix = self.dead_func_eliminate() or unfix
            unfix = self.dead_var_use_eliminate() or unfix
            # 常量传播和常量折叠
            unfix = self.const_prop_and_fold() or unfix
            # 代数优化
            unfix = self.algebra_optimize() or unfix
            self.early_reject()
            
            if not unfix:
                break
        
        # 重新进行基本块划分
        ir.to_basic_blocks()
        
    def print_logs(self) -> str:
        """打印优化日志"""
        return '\n'.join(self._logs)
        
    def dead_var_use_eliminate(self) -> bool:
        """删除在赋值后从未使用的变量的赋值语句"""
        var_updates: Dict[str, List[int]] = {}  # VarId -> QuadIndex[]，变量更新的地方
        
        # 找出所有变量被更新的所有地方
        for i in range(self._ir.var_count):
            var_updates[VAR_PREFIX + str(i)] = []
        for i, quad in enumerate(self._ir.quads):
            if quad.res.startswith(VAR_PREFIX):
                var_updates[quad.res].append(i)
                
        quads_to_remove: List[int] = []
        for var_, indices in var_updates.items():
            # 变量从未被更新，说明已经是死变量
            if not indices:
                continue
            # 向后寻找该变量是否被使用过
            final_index = sorted(indices, reverse=True)[0]  # 最后一次被更新的地方
            used = False
            for i in range(final_index + 1, len(self._ir.quads)):
                quad = self._ir.quads[i]
                # 只要出现在arg1 / arg2 / res，就是被使用过的活变量
                # 若最后一次被更新后存在跳转操作，放弃对该赋值的优化
                if (quad.arg1 == var_ or 
                    quad.arg2 == var_ or 
                    var_ in quad.arg2.split('&') or
                    quad.res == var_ or
                    quad.op in ('j', 'j_false', 'call', 'return_void', 'return_expr')):
                    used = True
                    break
            # 没被使用过，那么对它的最后一次赋值没有意义
            if not used:
                self._logs.append(f'删除从未被使用的变量 {var_}，对应四元式索引 {indices}')
                quads_to_remove.append(final_index)
                
        # 执行删除
        self._ir.quads = [q for i, q in enumerate(self._ir.quads) if i not in quads_to_remove]
        
        return bool(quads_to_remove)
        
    def dead_var_eliminate(self) -> bool:
        """删除变量池中的死变量（从未出现在任何四元式中的变量）"""
        used_vars: List[str] = []
        for quad in self._ir.quads:
            if quad.op == 'call':
                if quad.arg2.strip():
                    used_vars.extend(quad.arg2.split('&'))
            else:
                if quad.arg2.startswith(VAR_PREFIX):
                    used_vars.append(quad.arg2)
            if quad.arg1.startswith(VAR_PREFIX):
                used_vars.append(quad.arg1)
            if quad.res.startswith(VAR_PREFIX):
                used_vars.append(quad.res)
                
        used_vars = list(set(used_vars))
        unused_vars = [v for v in self._ir.var_pool if v.id not in used_vars]
        if unused_vars:
            self._logs.append(f'消除了死变量：{[v.id for v in unused_vars]}')
            
        self._ir.var_pool = [v for v in self._ir.var_pool if v.id in used_vars]
        return bool(unused_vars)
        
    def dead_func_eliminate(self) -> bool:
        """删除从未成为调用目标的函数"""
        # 寻找所有可能被调用的函数（从main开始深搜）
        j_funcs = ['main']
        while True:
            unfix = False
            for func in j_funcs:
                for target in next(f for f in self._ir.func_pool if f.name == func).child_funcs:
                    if target not in j_funcs:
                        unfix = True
                        j_funcs.append(target)
            if not unfix:
                break
                
        # 找出不可能被调用的函数
        never_j_funcs = [f for f in self._ir.func_pool if f.name not in j_funcs]
        ranges_to_remove = []
        
        # 修改这部分代码，增加错误处理
        for func in never_j_funcs:
            try:
                start_idx = next(i for i, q in enumerate(self._ir.quads) 
                               if q.op == 'set_label' and q.res == func.entry_label)
                end_idx = next(i for i, q in enumerate(self._ir.quads)
                             if q.op == 'set_label' and q.res == func.exit_label)
                ranges_to_remove.append({
                    'start': start_idx,
                    'end': end_idx
                })
                self._logs.append(f'删除从未被调用的函数 {func.name}')
            except StopIteration:
                # 如果找不到标签，跳过这个函数
                continue
        
        # 从函数池中删除这些函数
        self._ir.func_pool = [f for f in self._ir.func_pool if f.name in j_funcs]
        
        # 删除四元式
        if ranges_to_remove:
            new_quads = []
            current_idx = 0
            for quad in self._ir.quads:
                should_keep = True
                for range_ in ranges_to_remove:
                    if range_['start'] <= current_idx <= range_['end']:
                        should_keep = False
                        break
                if should_keep:
                    new_quads.append(quad)
                current_idx += 1
            self._ir.quads = new_quads
        
        return bool(ranges_to_remove)
        
    def const_prop_and_fold(self) -> bool:
        """常量传播和常量折叠"""
        # 找出所有=var的四元式
        eq_vars = [(v, i) for i, v in enumerate(self._ir.quads) if v.op == '=var']
        
        # 处理复杂的常量传播和常量折叠情况
        # 借助回溯法构造表达式树，可以同时完成常量传播和常量折叠
        optimizable_op = ['=var', 'OR_OP', 'AND_OP', 'EQ_OP', 'NE_OP', 'GT_OP', 'LT_OP',
                         'GE_OP', 'LE_OP', 'PLUS', 'MINUS', 'MULTIPLY', 'SLASH',
                         'PERCENT', 'BITAND_OP', 'BITOR_OP', 'LEFT_OP',
                         'RIGHT_OP', 'NOT_OP', 'MINUS', 'PLUS', 'BITINV_OP']
        
        unfix = False
        
        for eq_var in eq_vars:
            const_stk: List[str] = []
            node_stk: List[Dict] = []  # type: List[Dict[str, Union[str, int]]]
            # node类型为op时，i表示该运算涉及的操作数数；node类型为var时，i表示该变量通过第i个四元式被加入到栈中
            optimizable = True
            node_stk.append({'type': 'var', 'name': eq_var[0].arg1, 'i': eq_var[1]})
            
            while node_stk:
                node = node_stk.pop()
                if node['type'] == 'var':
                    for i in range(node['i'] - 1, -1, -1):
                        op = self._ir.quads[i].op
                        if op == 'set_label':
                            optimizable = False
                            break
                        elif self._ir.quads[i].res == node['name']:
                            if op == '=const':
                                const_stk.append(self._ir.quads[i].arg1)
                            elif op in optimizable_op:
                                arg_num = 2 if self._ir.quads[i].arg2.strip() else 1
                                node_stk.append({'type': 'op', 'name': op, 'i': arg_num})
                                node_stk.append({'type': 'var', 'name': self._ir.quads[i].arg1, 'i': i})
                                if arg_num > 1:
                                    node_stk.append({'type': 'var', 'name': self._ir.quads[i].arg2, 'i': i})
                            else:
                                optimizable = False
                            break
                else:
                    args = []
                    for i in range(node['i']):
                        args.append(const_stk.pop())
                    args.reverse()  # 保持操作数顺序
                    
                    # 执行常量折叠
                    if node['name'] == 'OR_OP':
                        const_stk.append('1' if int(args[0]) or int(args[1]) else '0')
                    elif node['name'] == 'AND_OP':
                        const_stk.append('1' if int(args[0]) and int(args[1]) else '0')
                    elif node['name'] == 'EQ_OP':
                        const_stk.append('1' if int(args[0]) == int(args[1]) else '0')
                    elif node['name'] == 'NE_OP':
                        const_stk.append('1' if int(args[0]) != int(args[1]) else '0')
                    elif node['name'] == 'GT_OP':
                        const_stk.append('1' if int(args[0]) > int(args[1]) else '0')
                    elif node['name'] == 'LT_OP':
                        const_stk.append('1' if int(args[0]) < int(args[1]) else '0')
                    elif node['name'] == 'GE_OP':
                        const_stk.append('1' if int(args[0]) >= int(args[1]) else '0')
                    elif node['name'] == 'LE_OP':
                        const_stk.append('1' if int(args[0]) <= int(args[1]) else '0')
                    elif node['name'] == 'PLUS':
                        if node['i'] == 2:
                            const_stk.append(str(int(args[0]) + int(args[1])))
                        else:
                            const_stk.append(str(int(args[0])))
                    elif node['name'] == 'MINUS':
                        if node['i'] == 2:
                            const_stk.append(str(int(args[0]) - int(args[1])))
                        else:
                            const_stk.append(str(-int(args[0])))
                    elif node['name'] == 'MULTIPLY':
                        const_stk.append(str(int(args[0]) * int(args[1])))
                    elif node['name'] == 'SLASH':
                        const_stk.append(str(int(args[0]) // int(args[1])))
                    elif node['name'] == 'PERCENT':
                        const_stk.append(str(int(args[0]) % int(args[1])))
                    elif node['name'] == 'BITAND_OP':
                        const_stk.append(str(int(args[0]) & int(args[1])))
                    elif node['name'] == 'BITOR_OP':
                        const_stk.append(str(int(args[0]) | int(args[1])))
                    elif node['name'] == 'LEFT_OP':
                        const_stk.append(str(int(args[0]) << int(args[1])))
                    elif node['name'] == 'RIGHT_OP':
                        const_stk.append(str(int(args[0]) >> int(args[1])))
                    elif node['name'] == 'NOT_OP':
                        const_stk.append('1' if not int(args[0]) else '0')
                    elif node['name'] == 'BITINV_OP':
                        const_stk.append(str(~int(args[0])))
                        
                if not optimizable:
                    break
                    
            if optimizable:
                new_quad = Quad('=const', const_stk[0], '', eq_var[0].res)
                unfix = True
                self._logs.append(f'常量传播与常量折叠，将位于 {eq_var[1]} 的 {eq_var[0]} 优化为 {new_quad}')
                self._ir.quads[eq_var[1]] = new_quad
                
        return unfix
        
    def algebra_optimize(self) -> bool:
        """代数规则优化
        PLUS: a+0=a
        MINUS: a-0=0; 0-a=-a
        MULTIPLY: a*1=a; a*0=0
        SLASH: 0/a=0; a/1=a
        """
        # 找出所有算术计算四元式
        calc_quads = [(v, i) for i, v in enumerate(self._ir.quads)
                     if v.op in ('PLUS', 'MINUS', 'MULTIPLY', 'SLASH')]
        
        undone = False
        
        # 对每条四元式的arg1、arg2
        for v, i in calc_quads:
            record = {
                'arg1': {'optimizable': None, 'constant': None},
                'arg2': {'optimizable': None, 'constant': None}
            }
            
            # 向上找最近相关的=const，并且过程中不应被作为其他res覆写过，二者间的指令也不应可能被跳转到
            def check_helper(var_id: str, record: Dict):
                for j in range(i - 1, -1, -1):
                    quad = self._ir.quads[j]
                    if quad.op == '=const' and quad.res == var_id:
                        record['optimizable'] = True
                        record['constant'] = quad.arg1
                        return
                    if quad.op == 'set_label' or quad.res == var_id:
                        record['optimizable'] = False
                        return
                record['optimizable'] = False
                return
                
            check_helper(v.arg1, record['arg1'])
            check_helper(v.arg2, record['arg2'])
            
            def modify(to: Quad):
                self._logs.append(f'代数优化，将位于 {i} 的 {self._ir.quads[i]} 优化为 {to}')
                self._ir.quads[i] = to
                nonlocal undone
                undone = True
                
            # 应用规则优化之
            def optim_arg1():
                quad = self._ir.quads[i]
                if record['arg1']['optimizable'] and record['arg1']['constant'] == '0':
                    if v.op == 'PLUS':
                        # 0 + a = a
                        modify(Quad('=var', quad.arg2, '', quad.res))
                    elif v.op == 'MINUS':
                        # 0 - a = -a
                        # Minisys架构没有比较高效的取相反数指令，优化与否区别不大，这里不优化
                        pass
                    elif v.op == 'MULTIPLY':
                        # 0 * a = 0
                        modify(Quad('=const', '0', '', quad.res))
                    elif v.op == 'SLASH':
                        # 0 / a = 0
                        modify(Quad('=const', '0', '', quad.res))
                if record['arg1']['optimizable'] and record['arg1']['constant'] == '1':
                    if v.op == 'MULTIPLY':
                        # 1 * a = a
                        modify(Quad('=var', quad.arg2, '', quad.res))
                        
            def optim_arg2():
                quad = self._ir.quads[i]
                if record['arg2']['optimizable'] and record['arg2']['constant'] == '0':
                    if v.op == 'PLUS':
                        # a + 0 = a
                        modify(Quad('=var', quad.arg1, '', quad.res))
                    elif v.op == 'MINUS':
                        # a - 0 = a
                        modify(Quad('=var', quad.arg1, '', quad.res))
                    elif v.op == 'MULTIPLY':
                        # a * 0 = 0
                        modify(Quad('=const', '0', '', quad.res))
                if record['arg2']['optimizable'] and record['arg2']['constant'] == '1':
                    if v.op == 'MULTIPLY':
                        # a * 1 = a
                        modify(Quad('=var', quad.arg1, '', quad.res))
                        
            optim_arg1()
            optim_arg2()
            
        return undone
        
    def early_reject(self):
        """对不合理的命令立即拒绝"""
        for i, quad in enumerate(self._ir.quads):
            # 编译期可以确定的除以0
            if quad.op in ('SLASH', 'PERCENT'):
                for j in range(i - 1, -1, -1):
                    if (self._ir.quads[j].op == '=const' and 
                        self._ir.quads[j].res == quad.arg2 and 
                        self._ir.quads[j].arg1 == '0'):
                        # 上次赋值确定是常数0
                        assert False, f'位于 {i} 的四元式 {quad} 存在除以0错误'
                        break
                    if (self._ir.quads[j].res == quad.arg2 or 
                        self._ir.quads[j].op == 'set_label'):
                        # 被写入值不能确定的情况
                        break
                        
            # 越界的端口访问
            if quad.op == '=$':
                for j in range(i - 1, -1, -1):
                    if self._ir.quads[j].op == '=const' and self._ir.quads[j].res == quad.arg1:
                        # 上次赋值确定是某常数
                        addr = int(self._ir.quads[j].arg1, 16 if self._ir.quads[j].arg1.startswith('0x') else 10)
                        assert addr <= IO_MAX_ADDR, f'位于 {i} 的四元式 {quad} 存在越界端口访问'
                        break
                    if (self._ir.quads[j].res == quad.arg2 or 
                        self._ir.quads[j].op == 'set_label'):
                        # 被写入值不能确定的情况
                        break
