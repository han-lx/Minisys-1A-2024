vlib work
vlib riviera

vlib riviera/xil_defaultlib

vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../ipstatic" "+incdir+../../../ipstatic" \
"../../../../Minisys-1A.srcs/sources_1/ip/cpuclk/cpuclk_clk_wiz.v" \
"../../../../Minisys-1A.srcs/sources_1/ip/cpuclk/cpuclk.v" \


vlog -work xil_defaultlib \
"glbl.v"

