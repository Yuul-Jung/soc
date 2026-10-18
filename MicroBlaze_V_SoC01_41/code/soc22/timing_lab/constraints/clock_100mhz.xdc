## Normal Basys3 timing baseline: 100 MHz
create_clock -name sys_clk -period 10.000 -waveform {0.000 5.000} [get_ports clk]
