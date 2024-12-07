from typing import List, Dict, Set, Optional, Union
from ir import Quad, IRVar, IRArray, IRFunc
from IRGenerator import IRGenerator, GLOBAL_SCOPE
from asm.Arch import USEFUL_REGS, WORD_LENGTH_BIT, WORD_LENGTH_BYTE, RAM_SIZE, ROM_SIZE, IO_MAX_ADDR
from asm.ASM import RegisterDescriptor, AddressDescriptor, StackFrameInfo

class ASMGenerator:
    """汇编代码生成器"""
    
    def __init__(self, ir: IRGenerator):
        self._ir = ir
        self._asm: List[str] = []
        
        # 初始化寄存器和描述符
        self._GPRs = list(USEFUL_REGS)
        self._register_descriptors: Dict[str, RegisterDescriptor] = {}
        self._address_descriptors: Dict[str, AddressDescriptor] = {}
        self._stack_frame_infos: Dict[str, StackFrameInfo] = {}
        
        # 初始化所有通用寄存器
        for reg_name in self._GPRs:
            self._register_descriptors[reg_name] = RegisterDescriptor(
                usable=True,
                variables=set()
            )
            
        # 计算栈帧信息
        self.calc_frame_info()
        
        # 生成代码
        self.new_asm('.data')
        self.initialize_global_vars()
        self.new_asm('.text')
        self.process_text_segment()
        self.peephole_optimize()
        
    def new_asm(self, line: str):
        """添加一行新汇编代码"""
        # 如果是指令(不是标签、段声明或注释)
        if not (line.endswith(':') or line.startswith('.') or '#' in line):
            # 分割指令的操作符和操作数
            parts = line.split(' ', 1)
            if len(parts) > 1:
                # 操作符和第一个操作数之间用tab,操作数之间用空格
                op = parts[0]
                args = parts[1]  # 保留操作数之间的空格
                line = f"{op} {args}"
        
        self._asm.append(line)
        
    def to_assembly(self) -> str:
        """生成汇编代码字符串"""
        return '\n'.join(
            ('' if (line.endswith(':') or line.startswith('.') or '#' in line) else '\t') + 
            # 只将第一个空格(操作符和操作数之间)替换为tab
            line.replace(' ', '\t', 1) if not (line.endswith(':') or line.startswith('.') or '#' in line)
            else line
            for line in self._asm
        )
        
    def to_minisys_type(self, type_: str) -> str:
        """将MiniC类型转换为Minisys汇编类型"""
        table = {
            'int': '.word'
        }
        return table[type_]
        
    def initialize_global_vars(self):
        """生成声明全局变量代码"""
        global_vars = [v for v in self._ir.var_pool 
                      if IRGenerator.same_scope(v.scope, GLOBAL_SCOPE)]
        
        for var_ in global_vars:
            if isinstance(var_, IRVar):
                # 全局变量初始值给0x0
                self.new_asm(f"{var_.name}: {self.to_minisys_type(var_.type)} 0x0")
            else:
                # 全局数组初始值给0x0
                self.new_asm(f"{var_.name}: {self.to_minisys_type(var_.type)} " + 
                           ", ".join(['0x0'] * var_.len))
                           
    def load_var(self, var_id: str, register: str):
        """从内存取变量到寄存器"""
        var_loc = self._address_descriptors[var_id].bound_mem_address
        assert var_loc, f"Cannot get the bound address for this variable: {var_id}"
        
        self.new_asm(f"lw {register}, {var_loc}")
        self.new_asm("nop")
        self.new_asm("nop")
        
        # 更新寄存器描述符,使其只包含这个变量
        self._register_descriptors[register].variables.clear()
        self._register_descriptors[register].variables.add(var_id)
        
        # 更新地址描述符,添加这个寄存器作为额外位置
        self._address_descriptors[var_id].current_addresses.add(register)
        
    def store_var(self, var_id: str, register: str):
        """回写寄存器内容到内存"""
        var_loc = self._address_descriptors[var_id].bound_mem_address
        assert var_loc, f"Cannot get the bound address for this variable: {var_id}"
        
        self.new_asm(f"sw {register}, {var_loc}")
        self._address_descriptors[var_id].current_addresses.add(var_loc)
        
    def calc_frame_info(self):
        """根据IRFunc计算该Procedure所需的Frame大小"""
        for outer in self._ir.func_pool:
            # 如果调用了子函数,需要保存返回地址并分配至少4个outgoing args块
            is_leaf = len(outer.child_funcs) == 0
            max_args = 0
            for inner in self._ir.func_pool:
                if inner.name in outer.child_funcs:
                    max_args = max(max_args, len(inner.param_list))
                    
            outgoing_slots = 0 if is_leaf else max(max_args, 4)
            local_data = 0
            for local_var in outer.local_vars:
                if isinstance(local_var, IRVar):
                    if local_var not in outer.param_list:
                        local_data += 1
                else:
                    local_data += local_var.len
                    
            num_gprs_2_save = 0 if outer.name == 'main' else (
                local_data - 8 if local_data > 18 else 
                local_data if local_data > 10 else 0
            )
            
            # 为所有局部变量分配内存(但不包括临时变量)
            word_size = (0 if is_leaf else 1) + local_data + num_gprs_2_save + outgoing_slots + num_gprs_2_save
            if word_size % 2 != 0:  # padding
                word_size += 1
                
            self._stack_frame_infos[outer.name] = StackFrameInfo(
                is_leaf=is_leaf,
                word_size=word_size,
                outgoing_slots=outgoing_slots,
                local_data=local_data,
                num_gprs_2_save=num_gprs_2_save,
                num_return_add=0 if is_leaf else 1
            )

    def get_regs(self, ir: Quad, block_index: int, ir_index: int) -> List[str]:
        """为一条四元式获取每个变量可用的寄存器"""
        binary_op = bool(ir.arg1.strip() and ir.arg2.strip())  # 是二元表达式
        unary_op = bool(bool(ir.arg1.strip()) ^ bool(ir.arg2.strip()))  # 是一元表达式
        
        if ir.op in ['=$', 'call', 'j_false', '=var', '=const', '=[]', '[]']:
            if ir.op == '=$':
                reg_y = self.allocate_reg(block_index, ir_index, ir.arg1, None, None)
                if reg_y and not self._register_descriptors[reg_y].variables.intersection({ir.arg1}):
                    self.load_var(ir.arg1, reg_y)
                reg_z = self.allocate_reg(block_index, ir_index, ir.arg2, None, None)
                if reg_z and not self._register_descriptors[reg_z].variables.intersection({ir.arg2}):
                    self.load_var(ir.arg2, reg_z)
                return [reg_y or '$t0', reg_z or '$t1']
                
            elif ir.op in ['=const', 'call']:
                reg_x = self.allocate_reg(block_index, ir_index, ir.res, None, None)
                return [reg_x]
                
            elif ir.op == 'j_false':
                reg_y = self.allocate_reg(block_index, ir_index, ir.arg1, None, None)
                if reg_y and not self._register_descriptors[reg_y].variables.intersection({ir.arg1}):
                    self.load_var(ir.arg1, reg_y)
                return [reg_y]
                
            elif ir.op == '=var':
                reg_y = self.allocate_reg(block_index, ir_index, ir.arg1, None, ir.res)
                if reg_y and not self._register_descriptors[reg_y].variables.intersection({ir.arg1}):
                    self.load_var(ir.arg1, reg_y)
                reg_x = reg_y  # always choose RegX = RegY
                return [reg_y, reg_x]
                
            elif ir.op == '=[]':
                reg_y = self.allocate_reg(block_index, ir_index, ir.arg1, None, None)
                if reg_y and not self._register_descriptors[reg_y].variables.intersection({ir.arg1}):
                    self.load_var(ir.arg1, reg_y)
                reg_z = self.allocate_reg(block_index, ir_index, ir.arg2, None, None)
                if reg_z and not self._register_descriptors[reg_z].variables.intersection({ir.arg2}):
                    self.load_var(ir.arg2, reg_z)
                return [reg_y, reg_z]
                
            elif ir.op == '[]':
                reg_z = self.allocate_reg(block_index, ir_index, ir.arg2, None, None)
                if reg_z and not self._register_descriptors[reg_z].variables.intersection({ir.arg2}):
                    self.load_var(ir.arg2, reg_z)
                reg_x = self.allocate_reg(block_index, ir_index, ir.res, None, None)
                return [reg_z, reg_x]
                
        elif binary_op:
            reg_y = self.allocate_reg(block_index, ir_index, ir.arg1, ir.arg2, ir.res)
            if reg_y and not self._register_descriptors[reg_y].variables.intersection({ir.arg1}):
                self.load_var(ir.arg1, reg_y)
                
            reg_z = self.allocate_reg(block_index, ir_index, ir.arg2, ir.arg1, ir.res)
            if reg_z and not self._register_descriptors[reg_z].variables.intersection({ir.arg2}):
                self.load_var(ir.arg2, reg_z)
                
            # 如果结果是arg1或arg2之一,则使用相同的寄存器
            if ir.res == ir.arg1:
                reg_x = reg_y
            elif ir.res == ir.arg2:
                reg_x = reg_z
            else:
                reg_x = self.allocate_reg(block_index, ir_index, ir.res, None, None)
            return [reg_y, reg_z, reg_x]
            
        elif unary_op:
            reg_y = self.allocate_reg(block_index, ir_index, ir.arg1, None, ir.res)
            if reg_y and not self._register_descriptors[reg_y].variables.intersection({ir.arg1}):
                self.load_var(ir.arg1, reg_y)
            reg_x = reg_y if ir.res == ir.arg1 else self.allocate_reg(block_index, ir_index, ir.res, None, None)
            return [reg_y, reg_x]
            
        else:
            assert False, 'Illegal op.'
            
        return []

    def allocate_reg(self, block_index: int, ir_index: int, this_arg: str, 
                    other_arg: Optional[str], res: Optional[str]) -> str:
        """寄存器分配"""
        addr_desc = self._address_descriptors.get(this_arg)
        if not addr_desc:
            # 如果是常量赋值等情况，返回一个可用的临时寄存器
            for reg_name, desc in self._register_descriptors.items():
                if len(desc.variables) == 0 and desc.usable:
                    return reg_name
            # 如果没有可用寄存器，返回第一个临时寄存器
            return '$t0'
        
        final_reg = ''
        already_in_reg = False
        
        # 1. 当前在寄存器中,直接使用该寄存器
        for addr in addr_desc.current_addresses:
            if addr.startswith('$'):
                already_in_reg = True
                final_reg = addr
                break
                
        if not already_in_reg:
            free_reg = ''
            # 2. 寻找空闲寄存器
            for reg_name, desc in self._register_descriptors.items():
                if len(desc.variables) == 0 and desc.usable:
                    free_reg = reg_name
                    break
                    
            if free_reg:
                final_reg = free_reg
            else:
                # 3. 没有空闲寄存器,需要选择一个替换
                basic_block = self._ir.basic_blocks[block_index]
                scores: Dict[str, int] = {}  # 选择该寄存器需要生成的指令数
                
                for reg_name, desc in self._register_descriptors.items():
                    score = 0
                    if not desc.usable:
                        score = float('inf')
                        scores[reg_name] = score
                        continue
                        
                    current_vars = desc.variables
                    for current_var in current_vars:
                        if current_var == res and current_var != other_arg:
                            # 是结果操作数且不是另一个参数操作数,可以替换因为这个值不会再被使用
                            continue
                            
                        reused = False
                        temp_index = ir_index
                        procedure_end = False
                        
                        while not procedure_end and not reused:
                            temp_index += 1
                            if temp_index >= len(basic_block.content):
                                break
                            temp_ir = basic_block.content[temp_index]
                            if (temp_ir.arg1 == current_var or 
                                temp_ir.arg2 == current_var or 
                                temp_ir.res == current_var):
                                reused = True
                                break
                            if temp_ir.op == 'set_label' and temp_ir.res.endswith('_exit'):
                                procedure_end = True
                                
                        if not reused:
                            # 这个变量在后续指令中不会再被用作参数
                            continue
                        else:
                            bound_mem = self._address_descriptors[current_var].bound_mem_address
                            if bound_mem is not None:
                                addrs = self._address_descriptors[current_var].current_addresses
                                if addrs and len(addrs) > 1:
                                    # 有另一个当前地址,可以直接替换这个而不需要生成store指令
                                    continue
                                else:
                                    # 可以替换但需要生成一条store指令
                                    score += 1
                            else:
                                # 这是一个临时变量且没有内存地址,不能被替换!
                                score = float('inf')
                                
                    scores[reg_name] = score
                    
                min_score = float('inf')
                min_key = ''
                for reg_name, score in scores.items():
                    if score < min_score:
                        min_score = score
                        min_key = reg_name
                        
                assert min_score != float('inf'), 'Cannot find a register to replace.'
                final_reg = min_key
                
                if min_score > 0:
                    # 需要生成指令来存回
                    variables = self._register_descriptors[final_reg].variables
                    assert variables, 'Undefined variables'
                    
                    for var_id in variables:
                        temp_addr_desc = self._address_descriptors[var_id]
                        assert temp_addr_desc, 'Undefined address descriptor'
                        assert temp_addr_desc.bound_mem_address, 'Undefined bound address'
                        temp_bound_addr = temp_addr_desc.bound_mem_address
                        
                        if not temp_addr_desc.current_addresses.intersection({temp_bound_addr}):
                            self.store_var(var_id, final_reg)
                            self._register_descriptors[final_reg].variables.remove(var_id)
                            self._address_descriptors[var_id].current_addresses.remove(final_reg)
                            
        return final_reg

    def allocate_proc_memory(self, func: IRFunc):
        """初始化该过程的寄存器和地址描述符"""
        frame_info = self._stack_frame_infos[func.name]
        assert frame_info, 'Function name not in the pool'
        
        # 必须将通过寄存器传递的参数保存到内存,否则可能被破坏
        for index, param in enumerate(func.param_list):
            mem_loc = f"{4 * (frame_info.word_size + index)}($sp)"
            if index < 4:
                self.new_asm(f"sw $a{index}, {mem_loc}")
            self._address_descriptors[param.id] = AddressDescriptor(
                current_addresses=set([mem_loc]),
                bound_mem_address=mem_loc
            )
            
        remaining_lv_slots = frame_info.local_data
        for local_var in func.local_vars:
            if isinstance(local_var, IRVar):
                if local_var in func.param_list:
                    continue
                else:
                    mem_loc = f"{4 * (frame_info.word_size - (0 if frame_info.is_leaf else 1) - frame_info.num_gprs_2_save - remaining_lv_slots)}($sp)"
                    remaining_lv_slots -= 1
                    self._address_descriptors[local_var.id] = AddressDescriptor(
                        current_addresses=set([mem_loc]),
                        bound_mem_address=mem_loc
                    )
            elif isinstance(local_var, IRArray):
                assert False, 'Arrays are only supported as global variables!'
                
        available_rs = 8 if func.name == 'main' else frame_info.num_gprs_2_save
        
        # 分配$s0 ~ $s8
        for index in range(8):
            usable = index < available_rs
            self._register_descriptors[f"$s{index}"] = RegisterDescriptor(
                usable=usable,
                variables=set()
            )
            
        self.allocate_global_memory()

    def allocate_global_memory(self):
        """初始化全局变量的描述符"""
        global_vars = [v for v in self._ir.var_pool 
                      if IRGenerator.same_scope(v.scope, GLOBAL_SCOPE)]
        
        for global_var in global_vars:
            if isinstance(global_var, IRVar):
                self._address_descriptors[global_var.id] = AddressDescriptor(
                    current_addresses=set([global_var.name]),
                    bound_mem_address=f"{global_var.name}($0)"
                )
            else:
                self._address_descriptors[global_var.id] = AddressDescriptor(
                    current_addresses=set([global_var.name]),
                    bound_mem_address=global_var.name
                )

    def deallocate_proc_memory(self):
        """清除只属于该过程的描述符,并在必要时写回寄存器中的变量"""
        for var_id, addr_desc in self._address_descriptors.items():
            bound_mem_address = addr_desc.bound_mem_address
            current_addresses = addr_desc.current_addresses
            if (bound_mem_address is not None and 
                not current_addresses.intersection({bound_mem_address})):
                # 需要写回到绑定的内存位置
                if current_addresses:
                    for addr in current_addresses:
                        if addr.startswith('$'):
                            self.store_var(var_id, addr)
                            break
                else:
                    assert False, f"Attempted to store a ghost variable: {var_id}"
                
        self._address_descriptors.clear()
        for desc in self._register_descriptors.values():
            desc.variables.clear()

    def deallocate_block_memory(self):
        """清除只属于该基本块的描述符,并在必要时写回寄存器中的变量"""
        for var_id, addr_desc in self._address_descriptors.items():
            bound_mem_address = addr_desc.bound_mem_address
            current_addresses = addr_desc.current_addresses
            if (bound_mem_address is not None and 
                not current_addresses.intersection({bound_mem_address})):
                # 需要写回到绑定的内存位置
                if current_addresses:
                    for addr in current_addresses:
                        if addr.startswith('$'):
                            self.store_var(var_id, addr)
                            break
                else:
                    assert False, f"Attempted to store a ghost variable: {var_id}"
                
        for desc in self._register_descriptors.values():
            desc.variables.clear()
        
        for addr_desc in self._address_descriptors.values():
            addr_desc.current_addresses = {
                addr for addr in addr_desc.current_addresses 
                if not addr.startswith('$')
            }

    def manage_res_descriptors(self, reg_x: str, res: str):
        """更新变量被赋值后的相应的描述符"""
        if not reg_x or not res:  # 添加空值检查
            return
        
        # a. 更改寄存器描述符,使其只包含res
        self._register_descriptors[reg_x].variables.clear()
        self._register_descriptors[reg_x].variables.add(res)
        
        if res in self._address_descriptors:
            # b. 从除res外的任何变量的地址描述符中移除reg_x
            for desc in self._address_descriptors.values():
                if reg_x in desc.current_addresses:
                    desc.current_addresses.remove(reg_x)
                    
            # c. 更改res的地址描述符,使其唯一位置为reg_x
            # 注意此时res的内存位置不在其地址描述符中!
            self._address_descriptors[res].current_addresses.clear()
            self._address_descriptors[res].current_addresses.add(reg_x)
        else:
            # 临时变量
            self._address_descriptors[res] = AddressDescriptor(
                current_addresses=set([reg_x]),
                bound_mem_address=None
            )

    def process_text_segment(self):
        """根据中间代码生成MIPS汇编"""
        current_func = None
        current_frame_info = None
        
        for block_index, basic_block in enumerate(self._ir.basic_blocks):
            for ir_index, quad in enumerate(basic_block.content):
                if quad is None:
                    break
                    
                binary_op = bool(quad.arg1.strip() and quad.arg2.strip())  # 是二元表达式
                unary_op = bool(bool(quad.arg1.strip()) ^ bool(quad.arg2.strip()))  # 是一元表达式
                
                if quad.op == 'call':
                    # 解析函数名
                    func = next((f for f in self._ir.func_pool if f.name == quad.arg1), None)
                    assert func, f"Unidentified function:{quad.arg1}"
                    assert func.name != 'main', 'Cannot call main!'
                    
                    # 处理参数
                    if binary_op:  # 有参数
                        actual_arguments = quad.arg2.split('&')
                        for arg_num in range(len(func.param_list)):
                            actual_arg = actual_arguments[arg_num]
                            ad = self._address_descriptors.get(actual_arg)
                            assert ad and ad.current_addresses, 'Actual argument does not have current address'
                            
                            reg_loc = ''
                            mem_loc = ''
                            for addr in ad.current_addresses:
                                if addr.startswith('$'):  # 寄存器优先级更高
                                    reg_loc = addr
                                    break
                                else:
                                    mem_loc = addr
                                    
                            if reg_loc:
                                if arg_num < 4:
                                    self.new_asm(f"move $a{arg_num}, {reg_loc}")
                                else:
                                    self.new_asm(f"sw {reg_loc}, {4 * arg_num}($sp)")
                            else:
                                if arg_num < 4:
                                    self.new_asm(f"lw $a{arg_num}, {mem_loc}")
                                    self.new_asm("nop")
                                    self.new_asm("nop")
                                else:
                                    # 使用$v1作为临时寄存器
                                    self.new_asm(f"lw $v1, {mem_loc}")
                                    self.new_asm("nop")
                                    self.new_asm("nop")
                                    self.new_asm(f"sw $v1, {4 * arg_num}($sp)")
                                    
                    # 保存可能被破坏的寄存器
                    for var_id, addr_desc in self._address_descriptors.items():
                        bound_mem_address = addr_desc.bound_mem_address
                        current_addresses = addr_desc.current_addresses
                        if (bound_mem_address is not None and 
                            not current_addresses.intersection({bound_mem_address})):
                            if current_addresses:
                                for addr in current_addresses:
                                    if addr.startswith('$t'):
                                        self.store_var(var_id, addr)
                                        break
                            else:
                                assert False, f"Attempted to store a ghost variable: {var_id}"
                                
                    self.new_asm(f"jal {quad.arg1}")  # jal会自动保存返回地址到$ra
                    self.new_asm("nop")
                    
                    # 清除临时寄存器因为它们可能被破坏
                    for var_id, addr_desc in self._address_descriptors.items():
                        for addr in list(addr_desc.current_addresses):
                            if addr.startswith('$t'):
                                addr_desc.current_addresses.remove(addr)
                                if addr in self._register_descriptors:
                                    self._register_descriptors[addr].variables.discard(var_id)
                                    
                    if quad.res:  # 有返回值
                        reg_x = self.get_regs(quad, block_index, ir_index)[0]
                        self.new_asm(f"move {reg_x}, $v0")
                        self.manage_res_descriptors(reg_x, quad.res)
                        
                elif binary_op:
                    if quad.op == '=[]':
                        reg_y, reg_z = self.get_regs(quad, block_index, ir_index)
                        self.new_asm(f"move $v1, {reg_y}")
                        self.new_asm("sll $v1, $v1, 2")
                        base_addr = self._address_descriptors[quad.res].bound_mem_address
                        self.new_asm(f"sw {reg_z}, {base_addr}($v1)")
                        
                    elif quad.op == '[]':
                        reg_z, reg_x = self.get_regs(quad, block_index, ir_index)
                        self.new_asm(f"move $v1, {reg_z}")
                        self.new_asm("sll $v1, $v1, 2")
                        base_addr = self._address_descriptors[quad.arg1].bound_mem_address
                        self.new_asm(f"lw {reg_x}, {base_addr}($v1)")
                        self.new_asm("nop")
                        self.new_asm("nop")
                        self.manage_res_descriptors(reg_x, quad.res)
                        
                    elif quad.op == '=$':
                        reg_y, reg_z = self.get_regs(quad, block_index, ir_index)
                        self.new_asm(f"sw {reg_z}, 0({reg_y})")
                        
                    else:  # 二元运算
                        reg_y, reg_z, reg_x = self.get_regs(quad, block_index, ir_index)
                        
                        if quad.op == 'OR_OP' or quad.op == 'BITOR_OP':
                            self.new_asm(f"or {reg_x}, {reg_y}, {reg_z}")
                        elif quad.op == 'AND_OP' or quad.op == 'BITAND_OP':
                            self.new_asm(f"and {reg_x}, {reg_y}, {reg_z}")
                        elif quad.op == 'BITXOR_OP':
                            self.new_asm(f"xor {reg_x}, {reg_y}, {reg_z}")
                        elif quad.op == 'PLUS':
                            self.new_asm(f"add {reg_x}, {reg_y}, {reg_z}")
                        elif quad.op == 'MINUS':
                            self.new_asm(f"sub {reg_x}, {reg_y}, {reg_z}")
                        elif quad.op == 'LEFT_OP':
                            self.new_asm(f"sllv {reg_x}, {reg_y}, {reg_z}")
                        elif quad.op == 'RIGHT_OP':
                            self.new_asm(f"srlv {reg_x}, {reg_y}, {reg_z}")
                        elif quad.op == 'EQ_OP':
                            self.new_asm(f"sub {reg_x}, {reg_y}, {reg_z}")
                            self.new_asm(f"sltu {reg_x}, $zero, {reg_x}")
                            self.new_asm(f"xori {reg_x}, {reg_x}, 1")
                        elif quad.op == 'NE_OP':
                            self.new_asm(f"sub {reg_x}, {reg_y}, {reg_z}")
                        elif quad.op == 'LT_OP':
                            self.new_asm(f"slt {reg_x}, {reg_y}, {reg_z}")
                        elif quad.op == 'GT_OP':
                            self.new_asm(f"slt {reg_x}, {reg_z}, {reg_y}")
                        elif quad.op == 'GE_OP':
                            self.new_asm(f"slt {reg_x}, {reg_y}, {reg_z}")
                            self.new_asm(f"xori {reg_x}, {reg_x}, 1")
                        elif quad.op == 'LE_OP':
                            self.new_asm(f"slt {reg_x}, {reg_z}, {reg_y}")
                            self.new_asm(f"xori {reg_x}, {reg_x}, 1")
                        elif quad.op == 'MULTIPLY':
                            self.new_asm(f"mult {reg_y}, {reg_z}")
                            self.new_asm(f"mflo {reg_x}")
                        elif quad.op == 'SLASH':
                            self.new_asm(f"div {reg_y}, {reg_z}")
                            self.new_asm(f"mflo {reg_x}")
                        elif quad.op == 'PERCENT':
                            self.new_asm(f"div {reg_y}, {reg_z}")
                            self.new_asm(f"mfhi {reg_x}")
                            
                        self.manage_res_descriptors(reg_x, quad.res)
                        
                elif unary_op:
                    if quad.op == 'out_asm':
                        # 直接输出汇编
                        assert quad.arg1.startswith('"') and quad.arg1.endswith('"'), \
                            "out_asm 动作接收到非字符串参数"
                        self.new_asm(quad.arg1[1:-1])
                        
                    elif quad.op == 'j_false':
                        reg_y = self.get_regs(quad, block_index, ir_index)[0]
                        self.deallocate_block_memory()
                        self.new_asm(f"beq {reg_y}, $zero, {quad.res}")
                        self.new_asm("nop")  # delay-slot
                        
                    elif quad.op == '=const':
                        reg_x = self.get_regs(quad, block_index, ir_index)[0]
                        immediate_num = int(quad.arg1, 16 if quad.arg1.startswith('0x') else 10)
                        if -32768 <= immediate_num <= 32767:
                            self.new_asm(f"addiu {reg_x}, $zero, {immediate_num}")
                        else:
                            lower_half = immediate_num & 0xffff
                            higher_half = immediate_num >> 16
                            self.new_asm(f"lui {reg_x}, {higher_half}")
                            self.new_asm(f"ori {reg_x}, {reg_x}, {lower_half}")
                        self.manage_res_descriptors(reg_x, quad.res)
                        
                    elif quad.op == '=var':
                        reg_y = self.get_regs(quad, block_index, ir_index)[0]
                        # 将res添加到reg_y的寄存器描述符
                        self._register_descriptors[reg_y].variables.add(quad.res)
                        # 更改res的地址描述符使其唯一位置为reg_y
                        if quad.res in self._address_descriptors:
                            self._address_descriptors[quad.res].current_addresses.clear()
                            self._address_descriptors[quad.res].current_addresses.add(reg_y)
                        else:
                            self._address_descriptors[quad.res] = AddressDescriptor(
                                current_addresses=set([reg_y]),
                                bound_mem_address=None
                            )
                            
                    elif quad.op == 'return_expr':
                        ad = self._address_descriptors.get(quad.arg1)
                        assert ad and ad.current_addresses, 'Return value does not have current address'
                        
                        reg_loc = ''
                        mem_loc = ''
                        for addr in ad.current_addresses:
                            if addr.startswith('$'):  # 寄存器优先级更高
                                reg_loc = addr
                                break
                            else:
                                mem_loc = addr
                                
                        if reg_loc:
                            self.new_asm(f"move $v0, {reg_loc}")
                        else:
                            self.new_asm(f"lw $v0, {mem_loc}")
                            self.new_asm("nop")
                            self.new_asm("nop")
                            
                        self.deallocate_block_memory()
                        
                        assert current_frame_info, 'Undefined frame info'
                        for i in range(current_frame_info.num_gprs_2_save):
                            self.new_asm(f"lw $s{i}, {4 * (current_frame_info.word_size - current_frame_info.num_gprs_2_save + i)}($sp)")
                            self.new_asm("nop")
                            self.new_asm("nop")
                            
                        if not current_frame_info.is_leaf:
                            self.new_asm(f"lw $ra, {4 * (current_frame_info.word_size - 1)}($sp)")
                            self.new_asm("nop")
                            self.new_asm("nop")
                            
                        self.new_asm(f"addiu $sp, $sp, {4 * current_frame_info.word_size}")
                        self.new_asm("jr $ra")
                        self.new_asm("nop")
                        
                    else:  # 一元运算
                        reg_y, reg_x = self.get_regs(quad, block_index, ir_index)
                        
                        if quad.op == 'NOT_OP':
                            self.new_asm(f"xor {reg_x}, $zero, {reg_y}")
                        elif quad.op == 'MINUS':
                            self.new_asm(f"sub {reg_x}, $zero, {reg_y}")
                        elif quad.op == 'PLUS':
                            self.new_asm(f"move {reg_x}, {reg_y}")
                        elif quad.op == 'BITINV_OP':
                            self.new_asm(f"nor {reg_x}, {reg_y}, {reg_y}")
                        elif quad.op == 'DOLLAR':
                            self.new_asm(f"lw {reg_x}, 0({reg_y})")
                            self.new_asm("nop")
                            self.new_asm("nop")
                            
                        self.manage_res_descriptors(reg_x, quad.res)
                        
                else:  # 无操作数
                    if quad.op == 'set_label':
                        # 解析标签类型
                        label_type = quad.res.split('_')[-1]
                        if label_type == 'entry':
                            current_func = next((f for f in self._ir.func_pool 
                                              if f.entry_label == quad.res), None)
                            assert current_func, f"Function name not in the pool: {quad.res}"
                            current_frame_info = self._stack_frame_infos[current_func.name]
                            assert current_frame_info, f"Function name not in the pool: {quad.res}"
                            
                            self.new_asm(f"{current_func.name}:\t\t # vars = {current_frame_info.local_data}, " + 
                                       f"regs to save($s#) = {current_frame_info.num_gprs_2_save}, " +
                                       f"outgoing args = {current_frame_info.outgoing_slots}, " +
                                       f"{'do not ' if not current_frame_info.num_return_add else ''}need to save return address")
                                       
                            self.new_asm(f"addiu $sp, $sp, -{4 * current_frame_info.word_size}")
                            if not current_frame_info.is_leaf:
                                self.new_asm(f"sw $ra, {4 * (current_frame_info.word_size - 1)}($sp)")
                                
                            for i in range(current_frame_info.num_gprs_2_save):
                                self.new_asm(f"sw $s{i}, {4 * (current_frame_info.word_size - current_frame_info.num_gprs_2_save + i)}($sp)")
                                
                            self.allocate_proc_memory(current_func)
                            
                        elif label_type == 'exit':
                            self.deallocate_proc_memory()
                        else:
                            self.new_asm(f"{quad.res}:")
                            
                    elif quad.op == 'j':
                        self.deallocate_block_memory()
                        self.new_asm(f"j {quad.res}")
                        self.new_asm("nop")  # delay-slot
                        
                    elif quad.op == 'return_void':
                        self.deallocate_block_memory()
                        
                        assert current_frame_info, 'Undefined frame info'
                        for i in range(current_frame_info.num_gprs_2_save):
                            self.new_asm(f"lw $s{i}, {4 * (current_frame_info.word_size - current_frame_info.num_gprs_2_save + i)}($sp)")
                            self.new_asm("nop")
                            self.new_asm("nop")
                            
                        if not current_frame_info.is_leaf:
                            self.new_asm(f"lw $ra, {4 * (current_frame_info.word_size - 1)}($sp)")
                            self.new_asm("nop")
                            self.new_asm("nop")
                            
                        self.new_asm(f"addiu $sp, $sp, {4 * current_frame_info.word_size}")
                        self.new_asm("jr $ra")
                        self.new_asm("nop")
                        
                if (quad.op != 'set_label' and quad.op != 'j' and quad.op != 'j_false' and 
                    ir_index == len(basic_block.content) - 1):
                    self.deallocate_block_memory()

    def peephole_optimize(self):
        """窥孔优化"""
        new_asm = []
        new_asm.append(self._asm[0])
        
        for index in range(1, len(self._asm)):
            asm_elements_this_line = self._asm[index].strip().split(r',\s|\s')
            asm_elements_last_line = self._asm[index - 1].strip().split(r',|\s')
            
            if (asm_elements_this_line[0] == 'move' and 
                index > 0 and 
                not asm_elements_last_line[0] in ['nop', 'sw']):
                
                src_reg_this_line = asm_elements_this_line[2]
                dst_reg_last_line = asm_elements_last_line[1]
                
                if src_reg_this_line == dst_reg_last_line:
                    dst_reg_this_line = asm_elements_this_line[1]
                    new_last_line = self._asm[index - 1].replace(dst_reg_last_line, dst_reg_this_line)
                    new_asm.pop()
                    
                    # 'move $v0, $v0'
                    new_elements = new_last_line.strip().split(r',\s|\s')
                    if new_elements[0] == 'move' and new_elements[1] == new_elements[2]:
                        continue
                    
                    new_asm.append(new_last_line)
                else:
                    new_asm.append(self._asm[index])
            else:
                new_asm.append(self._asm[index])
            
        self._asm = new_asm
