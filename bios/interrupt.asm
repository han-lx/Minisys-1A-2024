.data 0x0000
.text 0x0000 
start:  # 四种内部异常和外部异常
     addi  $t0,$zero,12         # Status 寄存器的号码是 12
     mfc0  $t1,$t0,0            # 将t0内容读出存入t1中
     andi  $t2,$t1,0xfffffffe   # 保留其他值，IE位置为0，关中断
     mtc0  $t0,$t2,0            # 将t2中内容写回t0
     addi  $t3,$zero,13         # Cause寄存器的号码是 13
     mfc0  $t4,$t3,0            # 读出t3中的信息
     andi  $t5,$t4,0x007c       # 0111 1100 取2-6位ExCode，其他位置零
     
     addi  $t6,$zero,0x0000     # 外部中断
     beq   $t5,$t6,handle_ext_int 
     addi  $t6,$zero,0x0008     # syscall异常
     beq   $t5,$t6,handle_syscall_exc  
     addi  $t6,$zero,0x0009     # break异常
     beq   $t5,$t6,handle_break_exc   
     addi  $t6,$zero,0x000a     # 保留异常
     beq   $t5,$t6,reserved_inst_exc
     addi  $t6,$zero,0x000c     # 加减异常
     beq   $t5,$t6,arith_overflow_exc   
     addi  $t6,$zero,0x0007     # 除0异常
     beq   $t5,$t6,divide_zero_exc   
     
          
handle_ext_int:
    addi  $t6,$zero,0x02        # 外部异常，输出02
    sw   $t6,0xfc00($zero)
    j     exit

     
arith_overflow_exc:
    addi  $t6,$zero,0x0f        # 溢出后，数码管输出0f
    sw   $t6,0xfc00($zero)
    j     exit
    
reserved_inst_exc:
    addi  $t6,$zero,0x01        # 溢出后，数码管输出01    
    sw   $t6,0xfc00($zero)
    j     exit
    
handle_syscall_exc:
    addi  $t6,$zero,0x05        # 溢出后，数码管输出05    
    sw   $t6,0xfc00($zero)
    j     exit 
              
handle_break_exc:
    addi  $t6,$zero,0x0b        # 溢出后，数码管输出0b    
    sw   $t6,0xfc00($zero)
    j     exit

divide_zero_exc:
    addi  $t6,$zero,0x5b
    sw   $t6,0xfc00($zero)
    j     exit

exit:
     ori  $t1,$t1,0x0001        # IE位置1
     mtc0 $t0,$t1,0             # 开中断
     eret
            
