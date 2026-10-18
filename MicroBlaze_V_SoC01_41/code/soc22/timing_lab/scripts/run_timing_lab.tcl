# SoC 22 - Basys3 Timing Lab
#
# Usage examples:
#   vivado -mode batch -source scripts/run_timing_lab.tcl \
#          -tclargs unpipelined 10.0
#
#   vivado -mode batch -source scripts/run_timing_lab.tcl \
#          -tclargs pipelined 5.0
#
# arg0 : unpipelined | pipelined
# arg1 : clock period in ns

if {$argc < 2} {
    puts "ERROR: usage: run_timing_lab.tcl <unpipelined|pipelined> <period_ns>"
    exit 1
}

set variant [lindex $argv 0]
set period_ns [lindex $argv 1]

if {$variant eq "unpipelined"} {
    set top_name timing_lab_unpipelined_basys3_top
    set core_file timing_chain_unpipelined.v
} elseif {$variant eq "pipelined"} {
    set top_name timing_lab_pipelined_basys3_top
    set core_file timing_chain_pipelined.v
} else {
    puts "ERROR: unknown variant '$variant'"
    exit 1
}

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set rtl_dir [file join $root_dir "rtl"]
set xdc_dir [file join $root_dir "constraints"]

set run_tag "${variant}_${period_ns}ns"
set out_dir [file normalize [file join $root_dir "reports" $run_tag]]

file mkdir $out_dir

create_project -in_memory -part xc7a35tcpg236-1

read_verilog [file join $rtl_dir "reset_active_high_to_active_low.v"]
read_verilog [file join $rtl_dir "timing_pattern_source.v"]
read_verilog [file join $rtl_dir "timing_result_sink.v"]
read_verilog [file join $rtl_dir $core_file]

if {$variant eq "unpipelined"} {
    read_verilog [file join $rtl_dir "timing_lab_unpipelined_impl_top.v"]
    read_verilog [file join $rtl_dir "timing_lab_unpipelined_basys3_top.v"]
} else {
    read_verilog [file join $rtl_dir "timing_lab_pipelined_impl_top.v"]
    read_verilog [file join $rtl_dir "timing_lab_pipelined_basys3_top.v"]
}

synth_design \
    -top $top_name \
    -part xc7a35tcpg236-1

read_xdc [file join $xdc_dir "basys3_timing_lab_pins.xdc"]

create_clock \
    -name sys_clk \
    -period $period_ns \
    [get_ports clk]

report_methodology \
    -file [file join $out_dir "01_methodology_synth.rpt"]

report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -max_paths 10 \
    -file [file join $out_dir "02_timing_summary_post_synth.rpt"]

report_design_analysis \
    -max_paths 50 \
    -setup \
    -logic_level_distribution \
    -file [file join $out_dir "03_design_analysis_post_synth.rpt"]

opt_design
place_design

report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -max_paths 10 \
    -file [file join $out_dir "04_timing_summary_post_place.rpt"]

phys_opt_design
route_design

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

report_timing \
    -delay_type min \
    -max_paths 20 \
    -nworst 1 \
    -sort_by group \
    -input_pins \
    -file [file join $out_dir "07_worst_hold_paths.rpt"]

report_design_analysis \
    -max_paths 50 \
    -setup \
    -logic_level_distribution \
    -file [file join $out_dir "08_design_analysis_post_route.rpt"]

report_qor_suggestions \
    -file [file join $out_dir "09_qor_suggestions.rpt"]

report_utilization \
    -hierarchical \
    -file [file join $out_dir "10_utilization.rpt"]

report_clock_interaction \
    -file [file join $out_dir "11_clock_interaction.rpt"]

report_methodology \
    -file [file join $out_dir "12_methodology_post_route.rpt"]

write_checkpoint -force \
    [file join $out_dir "${run_tag}_post_route.dcp"]

puts ""
puts "SoC 22 timing run complete."
puts "Variant      : $variant"
puts "Clock period : $period_ns ns"
puts "Reports      : $out_dir"
puts ""
puts "Use the post-route Timing Summary for final comparison."
