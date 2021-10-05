create_clock -name CLK -period 20.000 [get_ports {CLK}]
create_clock -name IO_CLK -period 20.000
derive_pll_clocks
derive_clock_uncertainty
create_generated_clock -name SDRAM_CLK -source [get_pins {PLL|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] [get_ports {sdram_clock}]
set_input_delay -clock { SDRAM_CLK } -max [expr 5.4 + 0] [get_ports {sdram_dq[0] sdram_dq[1] sdram_dq[2] sdram_dq[3] sdram_dq[4] sdram_dq[5] sdram_dq[6] sdram_dq[7] sdram_dq[8] sdram_dq[9] sdram_dq[10] sdram_dq[11] sdram_dq[12] sdram_dq[13] sdram_dq[14] sdram_dq[15]}]
set_input_delay -clock { SDRAM_CLK } -min [expr 2.5 + 0] [get_ports {sdram_dq[0] sdram_dq[1] sdram_dq[2] sdram_dq[3] sdram_dq[4] sdram_dq[5] sdram_dq[6] sdram_dq[7] sdram_dq[8] sdram_dq[9] sdram_dq[10] sdram_dq[11] sdram_dq[12] sdram_dq[13] sdram_dq[14] sdram_dq[15]}]
set_output_delay -clock { SDRAM_CLK } -max [expr 1.5 + 0] [get_ports {sdram_we sdram_address[0] sdram_address[1] sdram_address[2] sdram_address[3] sdram_address[4] sdram_address[5] sdram_address[6] sdram_address[7] sdram_address[8] sdram_address[9] sdram_address[10] sdram_address[11] sdram_address[12] sdram_ba[0] sdram_ba[1] sdram_cas sdram_cke sdram_cs sdram_dq[0] sdram_dq[1] sdram_dq[2] sdram_dq[3] sdram_dq[4] sdram_dq[5] sdram_dq[6] sdram_dq[7] sdram_dq[8] sdram_dq[9] sdram_dq[10] sdram_dq[11] sdram_dq[12] sdram_dq[13] sdram_dq[14] sdram_dq[15] sdram_ras}]
set_output_delay -clock { SDRAM_CLK } -min [expr -0.8 + 0] [get_ports {sdram_we sdram_address[0] sdram_address[1] sdram_address[2] sdram_address[3] sdram_address[4] sdram_address[5] sdram_address[6] sdram_address[7] sdram_address[8] sdram_address[9] sdram_address[10] sdram_address[11] sdram_address[12] sdram_ba[0] sdram_ba[1] sdram_cas sdram_cke sdram_cs sdram_dq[0] sdram_dq[1] sdram_dq[2] sdram_dq[3] sdram_dq[4] sdram_dq[5] sdram_dq[6] sdram_dq[7] sdram_dq[8] sdram_dq[9] sdram_dq[10] sdram_dq[11] sdram_dq[12] sdram_dq[13] sdram_dq[14] sdram_dq[15] sdram_ras}]

set_output_delay -clock { IO_CLK } -max 0 [get_ports {HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]
set_output_delay -clock { IO_CLK } -min 0 [get_ports {HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]

