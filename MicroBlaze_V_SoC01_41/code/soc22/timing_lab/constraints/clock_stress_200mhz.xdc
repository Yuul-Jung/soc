## Timing-stress requirement: 200 MHz equivalent timing budget
##
## This is a constraint experiment only.
## It does NOT change the physical Basys3 oscillator from 100 MHz to 200 MHz.
create_clock -name sys_clk -period 5.000 -waveform {0.000 2.500} [get_ports clk]
