onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+multu -L xbip_utils_v3_0_8 -L xbip_pipe_v3_0_4 -L xbip_bram18k_v3_0_4 -L mult_gen_v12_0_13 -L xil_defaultlib -L secureip -O5 xil_defaultlib.multu

do {wave.do}

view wave
view structure

do {multu.udo}

run -all

endsim

quit -force
