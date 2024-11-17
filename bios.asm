.data 0x0000
.text 0x0000
    start:
        addi  $sp,$zero,0x5499   # 堆栈指针初始化
        addi  $s0,$zero,0x0500   # 确定ram检测基地址
        addi  $s1,$zero,0xefff   # 确定ram检测结束地址
        addi  $s2,$zero,0xffff   # 定义寄存器写入值
        addi  $s3,$zero,0x0001   # 预先存入ram错误码
        addi  $t2,$zero,0x0000   # 设定数位管检测初始数值
        addi  $t4,$zero,0x0000   # 预先设定数位管检测期间不显示
        addi  $t3,$zero,0xffff
    ram:  # 检测bios后，中断前寄存器
        lw    $t0,0($s0)         # 预存当前检测地址
        sw    $s2,0($s0)         # 将s2内容写入当前检测地址
        lw    $t1,0($s0)         # 将s2内容读出到t1
        bne   $t1,$s2,error      # 如果t1与s2不相等，跳转到error
        sw    $t0,0($s0)         # 将t0内容写回当前检测地址
        beq   $s0,$s1,ram_done       # 如果s0与s1相等，检测结束，跳转到ram_done
        addi  $s0,$s0,0x0004     # s0+4
        j     ram                
    ram_done: # ram检测结束
        addi  $v0,$zero,1   # v0为状态寄存器，1为ram检测成功
        jal   done 
    digitalTube:
        sw    $t2,0xfc00($zero)   # 数位管检测是不显示
        sw    $t4,0xfc04($zero)   # 数位管小数点不显示
        addiu   $t2,$t2,0x1111    # 数位管各位+1
        bne   $t2,$t3,digitalTube  # 如果t2与t3不相等，继续循环
        addi  $v0,$zero,2   # v0为状态寄存器，2为数位管检测成功
        jal   done
    keyboard:
        addi  $s3,$zero,0x0002   # 预存键盘错误码
        addi  $s0,$zero,0        # a0储存键盘状态寄存器的值
        addi  $s1,$zero,0        # a1储存键盘值
        loop_start:
            lw    $s0,0xfc12($zero)  # 将键盘状态寄存器的值存入a0，有键按下为1，无则为0
            bne   $s0,$zero,key_presseed  # 如果状态寄存器的值不为0，跳转到key_presseed
            j     loop_start
        key_presseed:
            lw    $s1,0xfc10($zero)  # 将键盘值存入a1
            slti  $t2,$t1,0x0010     # 判断键盘值是否在正常范围内
            addi  $v0,$zero,3   # v0为状态寄存器，3为键盘检测成功
            bne   $t2,$zero,done      # 如果键盘值在正常范围内，跳转到done
    error: # 检测失败，高位显示错误码
        addi   $t9,$zero,0xff00     
        sw     $t9,0xfc04($zero)     # 小数点不显示
        sw     $s3,0xfc02($zero)     # 显示错误码
    done: # 检测成功，低位显示结果
        addi   $s0,$zero,0xff00
        sw     $s0,0xfc04($zero)     # 小数点不显示
        sw     $v0,0xfc00($zero)     # 显示成功码
        jr     $ra


    
    
    
    