-makelib ies_lib/xil_defaultlib -sv \
  "E:/vivado/2017.4/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib ies_lib/xpm \
  "E:/vivado/2017.4/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/blk_mem_gen_v8_4_1 \
  "../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../Minisys-1A.srcs/sources_1/ip/instructionROM/sim/instructionROM.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

