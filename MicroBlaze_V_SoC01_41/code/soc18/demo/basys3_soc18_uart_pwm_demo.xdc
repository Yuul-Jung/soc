## SoC 18 Basys3 demo ports
## External port names in the Block Design wrapper must match these names.

## 100 MHz Clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Center Button Reset
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports btnC]

## Custom UART TX -> Basys3 USB-UART RX path
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports uart_tx_o]

## Custom PWM -> LED15
set_property -dict { PACKAGE_PIN L1 IOSTANDARD LVCMOS33 } [get_ports pwm_o]
