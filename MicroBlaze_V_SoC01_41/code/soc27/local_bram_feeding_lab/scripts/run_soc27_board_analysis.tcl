# SoC 27 · Basys3 board-demo implementation

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set rtl_dir    [file join $root_dir "rtl"]
set xdc_dir    [file join $root_dir "constraints"]
set out_dir    [file normalize [file join $root_dir "reports" "board_demo"]]

file mkdir $out_dir

create_project -in_memory -part xc7a35tcpg236-1

read_verilog [file join $rtl_dir "reset_active_high_to_active_low.v"]
read_verilog [file join $rtl_dir "mul_s8_dsp.v"]
read_verilog [file join $rtl_dir "pe4_dot_accum_pipelined.v"]
read_verilog [file join $rtl_dir "vector_dot_controller_pe4.v"]
read_verilog [file join $rtl_dir "vector_bram_sdp.v"]
read_verilog [file join $rtl_dir "bram_vector_feeder.v"]
read_verilog [file join $rtl_dir "local_bram_dot_accelerator.v"]
read_verilog [file join $rtl_dir "local_bram_demo_loader_len10.v"]
read_verilog [file join $rtl_dir "local_bram_result_sink.v"]
read_verilog [file join $rtl_dir "local_bram_dot_basys3_top.v"]

synth_design \
    -top local_bram_dot_basys3_top \
    -part xc7a35tcpg236-1

read_xdc [file join $xdc_dir "basys3_local_bram_lab.xdc"]

create_clock \
    -name sys_clk \
    -period 10.000 \
    [get_ports clk]

report_utilization \
    -hierarchical \
    -file [file join $out_dir "01_utilization_post_synth.rpt"]

report_ram_utilization \
    -include_lutram \
    -file [file join $out_dir "02_ram_utilization_post_synth.rpt"]

opt_design
place_design
phys_opt_design
route_design

report_utilization \
    -hierarchical \
    -file [file join $out_dir "03_utilization_post_route.rpt"]

report_ram_utilization \
    -include_lutram \
    -file [file join $out_dir "04_ram_utilization_post_route.rpt"]

report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -max_paths 20 \
    -file [file join $out_dir "05_timing_summary_post_route.rpt"]

report_design_analysis \
    -max_paths 50 \
    -setup \
    -logic_level_distribution \
    -file [file join $out_dir "06_design_analysis_post_route.rpt"]

set_switching_activity \
    -default_static_probability 0.5 \
    -default_toggle_rate 12.5

report_power \
    -file [file join $out_dir "07_power_normalized_activity.rpt"] \
    -rpx  [file join $out_dir "07_power_normalized_activity.rpx"]

report_methodology \
    -file [file join $out_dir "08_methodology_post_route.rpt"]

write_checkpoint -force \
    [file join $out_dir "soc27_board_demo_post_route.dcp"]

puts ""
puts "SoC 27 board implementation complete."
puts "Expected demo result: raw 55, LED 0x0037."
