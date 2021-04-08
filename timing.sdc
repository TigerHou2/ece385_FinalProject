## Generated SDC file "lab6.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition"

## DATE    "Sun Mar 21 20:07:38 2021"

##
## DEVICE  "10M50DAF484C7G"
##


set_time_format -unit ns -decimal_places 3


#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name {clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLOCK_50}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock	-source [get_pins {u0|sdram_pll|sd1|pll7|clk[1]}] \
								-name clk_dram_ext [get_ports {DRAM_CLK}] 
#create_generated_clock	-source [get_pins {VGA|clkdiv|clk}] \
#								-master_clock [get_clocks {clk}] \
#								-divide_by 2 \
#								-name clk_vga_clkdiv [get_keepers {vga_controller:VGA|clkdiv}] 
#create_generated_clock	-source [get_pins {VGA|vs|clk}] \
#								-master_clock [get_clocks {clk_vga_clkdiv}] \
#								-edges {1 836800 840001} \
#								-name clk_vga_vs [get_keepers {vga_controller:VGA|vs}] 
							  
derive_pll_clocks

#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -max -clock clk_dram_ext 5.9 [get_ports DRAM_DQ*]
set_input_delay -min -clock clk_dram_ext 3.0 [get_ports DRAM_DQ*]

set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {ARDUINO_IO*}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.500 [get_ports {KEY*}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {SW*}]

set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {altera_reserved_tck}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {altera_reserved_tdi}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {altera_reserved_tms}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -max -clock clk_dram_ext 1.6  [get_ports {DRAM_DQ* DRAM_*DQM}]
set_output_delay -min -clock clk_dram_ext -0.9 [get_ports {DRAM_DQ* DRAM_*DQM}]
set_output_delay -max -clock clk_dram_ext 1.6  [get_ports {DRAM_ADDR* DRAM_BA* DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE DRAM_CS_N}]
set_output_delay -min -clock clk_dram_ext -0.9 [get_ports {DRAM_ADDR* DRAM_BA* DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE DRAM_CS_N}]

set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {ARDUINO_IO*}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {ARDUINO_RESET_N}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {HEX*}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {LEDR*}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {VGA_*}]

set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {altera_reserved_tdo}]

#**************************************************************
# Set Clock Groups
#**************************************************************

#set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 


#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_ports {*}] -to [get_ports {KEY* LEDR* HEX*}]


#**************************************************************
# Set Multicycle Path
#**************************************************************

set_multicycle_path -setup -end -from  [get_clocks {clk_dram_ext}]  -to  [get_clocks {u0|sdram_pll|sd1|pll7|clk[0]}] 2


#**************************************************************
# Set Maximum Delay
#**************************************************************

#set_max_delay -from [get_registers {*altera_avalon_st_clock_crosser:*|in_data_buffer*}] -to [get_registers {*altera_avalon_st_clock_crosser:*|out_data_buffer*}] 100.000
#set_max_delay -from [get_registers *] -to [get_registers {*altera_avalon_st_clock_crosser:*|altera_std_synchronizer_nocut:*|din_s1}] 100.000


#**************************************************************
# Set Minimum Delay
#**************************************************************

#set_min_delay -from [get_registers {*altera_avalon_st_clock_crosser:*|in_data_buffer*}] -to [get_registers {*altera_avalon_st_clock_crosser:*|out_data_buffer*}] -100.000
#set_min_delay -from [get_registers *] -to [get_registers {*altera_avalon_st_clock_crosser:*|altera_std_synchronizer_nocut:*|din_s1}] -100.000


#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************

#set_net_delay -max 2.000 -from [get_registers {*altera_avalon_st_clock_crosser:*|in_data_buffer*}] -to [get_registers {*altera_avalon_st_clock_crosser:*|out_data_buffer*}]
#set_net_delay -max 2.000 -from [get_registers *] -to [get_registers {*altera_avalon_st_clock_crosser:*|altera_std_synchronizer_nocut:*|din_s1}]
