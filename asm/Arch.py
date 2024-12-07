# 架构相关常量定义
WORD_LENGTH_BIT = 32
WORD_LENGTH_BYTE = 4
RAM_SIZE = 65536  # bytes
ROM_SIZE = 65536  # bytes
IO_MAX_ADDR = 0xffffffff

# 寄存器定义
ALL_REGS = [
    '$zero', '$at',
    '$v0', '$v1',
    '$a0', '$a1', '$a2', '$a3',
    '$t0', '$t1', '$t2', '$t3', '$t4', '$t5', '$t6', '$t7', '$t8', '$t9',
    '$s0', '$s1', '$s2', '$s3', '$s4', '$s5', '$s6', '$s7',
    '$k0', '$k1',
    '$gp', '$sp', '$fp',
    '$ra',
]

USEFUL_REGS = [
    '$t0', '$t1', '$t2', '$t3', '$t4', '$t5', '$t6', '$t7', '$t8', '$t9',  # 子程序可以破坏其中的值
    '$s0', '$s1', '$s2', '$s3', '$s4', '$s5', '$s6', '$s7',  # 子程序必须保持前后的值
]