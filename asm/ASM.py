from dataclasses import dataclass
from typing import Set, Optional

@dataclass
class RegisterDescriptor:
    """寄存器描述符"""
    usable: bool
    variables: Set[str]

@dataclass
class AddressDescriptor:
    """地址描述符"""
    current_addresses: Set[str]
    bound_mem_address: Optional[str]  # temporary variables should not have mem locations

@dataclass
class StackFrameInfo:
    """栈帧信息"""
    is_leaf: bool  # A non-leaf function is one that calls other function(s)
    word_size: int
    outgoing_slots: int
    local_data: int
    num_gprs_2_save: int
    num_return_add: int 