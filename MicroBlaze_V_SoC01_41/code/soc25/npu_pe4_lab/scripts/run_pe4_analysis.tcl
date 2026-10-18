# SoC 25 · 4-Lane PE / Parallel MAC analysis
#
# Usage:
#   vivado -mode batch -source scripts/run_pe4_analysis.tcl \
#          -tclargs basic
#
#   vivado -mode batch -source scripts/run_pe4_analysis.tcl \
#          -tclargs pipelined

if {$argc < 1} {
    puts "ERROR: usage: run_pe4_analysis.tcl <basic|pipelined>"
    exit 1
}

set variant [lindex $argv 0]

if {$variant eq "basic"} {
    set top_name pe4_basic_basys3_top
    set pe_file pe4_dot_accum_basic.v
    set board_file pe4_basic_basys3_top.v
} elseif {$variant eq "pipelined"} {
    set top_name pe4_pipelined_basys3_top
    set pe_file pe4_dot_accum_pipelined.v
    set board_file pe4_pipelined_basys3_top.v
} else {
    puts "ERROR: unknown variant '$variant'"
    exit 1
}

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set rtl_dir [file join $root_dir "rtl"]
set xdc_dir [file join $root_dir "constraints"]
set out_dir [file normalize [file join $root_dir "reports" $variant]]

file mkdir $out_dir

create_project -in_memory -part xc7a35tcpg236-1

read_verilog [file join $rtl_dir "reset_active_high_to_active_low.v"]
read_verilog [file join $rtl_dir "mul_s8_dsp.v"]
read_verilog [file join $rtl_dir "pe4_pattern_source.v"]
read_verilog [file join $rtl_dir "pe4_result_sink.v"]
read_verilog [file join $rtl_dir $pe_file]
read_verilog [file join $rtl_dir $board_file]

synth_design \
    -top $top_name \
    -part xc7a35tcpg236-1

read_xdc [file join $xdc_dir "basys3_pe4_lab.xdc"]

create_clock \
    -name sys_clk \
    -period 10.000 \
    [get_ports clk]

report_utilization \
    -hierarchical \
    -file [file join $out_dir "01_utilization_post_synth.rpt"]

redirect -file [file join $out_dir "02_dsp48_cells_post_synth.rpt"] {
    set dsp_cells [get_cells -hier -filter {REF_NAME =~ DSP48*}]
    puts "DSP48 cell count: [llength $dsp_cells]"

    foreach cell $dsp_cells {
        puts $cell
    }
}

report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -max_paths 10 \
    -file [file join $out_dir "03_timing_summary_post_synth.rpt"]

opt_design
place_design
phys_opt_design
route_design

report_utilization \
    -hierarchical \
    -file [file join $out_dir "04_utilization_post_route.rpt"]

report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -max_paths 20 \
    -file [file join $out_dir "05_timing_summary_post_route.rpt"]

report_timing \
    -delay_type max \
    -max_paths 20 \
    -nworst 1 \
    -sort_by group \
    -input_pins \
    -file [file join $out_dir "06_worst_setup_paths.rpt"]

report_design_analysis \
    -max_paths 50 \
    -setup \
    -logic_level_distribution \
    -file [file join $out_dir "07_design_analysis_post_route.rpt"]

# Same What-If activity assumption used in SoC 23/24.
set_switching_activity \
    -default_static_probability 0.5 \
    -default_toggle_rate 12.5

report_power \
    -file [file join $out_dir "08_power_normalized_activity.rpt"] \
    -rpx  [file join $out_dir "08_power_normalized_activity.rpx"]

report_methodology \
    -file [file join $out_dir "09_methodology_post_route.rpt"]

write_checkpoint -force \
    [file join $out_dir "${variant}_pe4_post_route.dcp"]

puts ""
puts "SoC 25 PE4 analysis complete."
puts "Variant : $variant"
puts "Reports : $out_dir"
puts ""
puts "DSP count must be read from actual synthesis reports."
