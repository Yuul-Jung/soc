## SoC 22 Timing Lab Constraints
##
## Basys3 primary board clock:
##   W5 = 100 MHz
##
## Use the 10 ns clock for the normal Basys3 baseline.
## The 5 ns line is an optional timing-stress experiment.
## Do NOT enable both create_clock commands at the same time.

set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]

## Normal Basys3 clock: 100 MHz
create_clock -name sys_clk -period 10.000 -waveform {0.000 5.000} [get_ports clk]

## Optional stress experiment: 200 MHz timing requirement
## This changes the timing requirement only.
## It does not physically turn the Basys3 100 MHz oscillator into 200 MHz.
# create_clock -name sys_clk -period 5.000 -waveform {0.000 2.500} [get_ports clk]
