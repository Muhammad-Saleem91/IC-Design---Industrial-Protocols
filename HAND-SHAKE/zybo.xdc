

##Switches
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L19N_T3_VREF_35 Sch=sw[0]
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { rst_n}]; #IO_L24P_T3_34 Sch=sw[1]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw_valid}]; #IO_L4N_T0_34 Sch=sw[2]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { btn_ready }]; #IO_L9P_T1_DQS_34 Sch=sw[3]

##LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { leds[0]}]; #IO_L23P_T3_35 Sch=led[0]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { leds[1]}]; #IO_L23N_T3_35 Sch=led[1]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { leds[2]}]; #IO_0_35 Sch=led[2]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { leds[3]}]; #IO_L3N_T0_DQS_AD1N_35 Sch=led[3]

##Buttons
# set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { b[0] }]; #IO_L12N_T1_MRCC_35 Sch=btn[0]
# set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { b[1] }]; #IO_L24N_T3_34 Sch=btn[1]
# set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { b[2] }]; #IO_L10P_T1_AD11P_35 Sch=btn[2]
# set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { b[3] }]; #IO_L7P_T1_34 Sch=btn[3]







