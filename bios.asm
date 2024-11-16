.data 0x0000
.text 0x0000
    start:
        addi  $sp,$zero,0x5499   # 鍫嗘爤鎸囬拡鍒濆鍖�
        addi  $s0,$zero,0x5000   # 瀹氫箟妫€娴嬬┖闂撮鍦板潃
        addi  $s1,$zero,0xefff   # 妫€娴嬬┖闂寸殑缁撴潫浣嶇疆
        addi  $s2,$zero,0xffff   # 瀹氫箟涓€涓啓鍏ュ瘎瀛樺櫒鐨勬暟鎹劧鍚庤鍑�
        addi  $s3,$zero,0x0001   # 瀵勫瓨鍣╯3鍌ㄥ瓨閿欒鐮侊紝棰勫厛瀛樺叆ram閿欒鐮�
        addi  $t2,$zero,0x0000   # 娴嬭瘯鏁扮爜绠�
        addi  $t4,$zero,0x0000   # 鏁扮爜绠℃樉绀烘儏鍐�
        addi  $t3,$zero,0xffff
    ram锛� # 妫€娴媌ios鍖哄煙锛屼腑鏂尯鍩熶箣澶栫殑鍖哄煙
        lw    $t0,0($s0)         # 淇濆瓨mem棣栧湴鍧€
        sw    $s2,0($s0)         # 灏唖2鍐欏叆鍦板潃涓簊0鐨勫瘎瀛樺櫒涓�
        lw    $t1,0($s0)         # 璇诲彇褰撳墠鍦板潃s0涓暟鍊�
        bne   $t1,$s2,error      # 鑻ヤ笉鐩哥瓑锛宮em瀛樺偍鍑虹幇閿欒
        sw    $t0,0($s0)         # 鎭㈠s0棣栧湴鍧€
        beq   $s0,$s1,ram_done       # 鑻0=s1锛屾娴嬪畬姣�
        addi  $s0,$s0,0x0004     # s0+4
        j     ram                # 璺宠浆鍒皉am
    ram_done:
        addi  $v0,$zero,1   # ram妫€娴嬪畬姣�
        jal   done 
    digitalTube:
        sw    $t2,0xfc00($zero)   # 鏁扮爜绠″叆鍙ｅ熀鍦板潃
        sw    $t4,0xfc04($zero)   # 鏁扮爜绠″皬鏁扮偣
        addiu   $t2,$t2,0x1111    # 鏁扮爜绠℃暟鍊煎悇浣�+1
        bne   $t2,$t3,digitalTube  # 鑻ユ暟鐮佺鍊间笉绛変簬0xffff锛岀户缁娴�
        addi  $v0,$zero,2   # 鏁扮爜绠℃娴嬪畬姣�
        jal   done
    keyboard:
        addi  $s3,$zero,0x0002   # 閿洏閿欒鐮�
    timer:
    pwm:
    watchdog:
    led:
    switch2:
    buzzer:
    error: # 楂樹綅鏄剧ず閿欒鐮�
        addi   $t9,$zero锛�0xff00     
        sw     $t9,0xfc04($zero)     # 璁剧疆8涓暟鐮佺鍧囨樉绀烘暟鎹�
        sw     $s3,0xfc02($zero)     # 鏄剧ず閿欒鐮�
    done: # 浣庝綅鏄剧ず妫€娴嬪畬姣�
        addi   $s0,$zero锛�0xff00
        sw     $s0,0xfc04($zero)     # 璁剧疆8涓暟鐮佺鍧囨樉绀烘暟鎹�
        sw     $v0,0xfc00($zero)     # 鏄剧ず妫€娴嬪畬姣�
        jr     $ra


    
    
    
    