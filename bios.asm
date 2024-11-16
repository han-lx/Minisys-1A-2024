.data 0x0000
.text 0x0000
    start:
        addi  $sp,$zero,0xffff   #鍫嗘爤鎸囬拡鍒濆鍖�
        addi  $s0,$zero,0x3000   #瀹氫箟涓€涓亸绉绘寚閽�
        addi  $s1,$zero,0x3fff   #纭畾ram澶у皬,s1=ram鍦板潃鑼冨洿澶у皬,鍒掑垎ram绌洪棿渚沚ios浣跨敤
        addi  $s2,$zero,0x7777   #瀹氫箟涓€涓啓鍏ュ瘎瀛樺櫒鐨勬暟鎹劧鍚庤鍑�
        addi  $s3,$zero,0x0001   #瀛樺偍閿欒鐮�
    ram锛�
    digitalTube:
    keyboard:
    timer:
    pwm:
    watchdog:
    led:
    switch2:
    buzzer:
    error:
    done:


    
    
    
    