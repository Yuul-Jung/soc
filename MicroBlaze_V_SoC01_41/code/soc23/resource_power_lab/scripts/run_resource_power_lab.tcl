# SoC 23 - Resource / Power / Thermal Lab
#
# Usage:
#   vivado -mode batch -source scripts/run_resource_power_lab.tcl \
#          -tclargs unpipelined
#
#   vivado -mode batch -source scripts/run_resource_power_lab.tcl \
#          -tclargs pipelined
#
# Comparison policy:
# - Same device
# - Same 100 MHz clock requirement
# - Same pin constraints
# - Same switching-activity assumption
# - Same implementation flow
#
# This keeps the comparison meaningful.

if {$argc < 1} {
    puts "ERROR: usage: run_resource_power_lab.tcl <unpipelined|pipelined>"
    exit 1
}

set variant [lindex $argv 0]

if {$variant eq "unpipelined"} {
    set top_name timing_lab_unpipelined_basys3_top
    set core_file timing_chain_unpipelined.v
    set impl_file timing_lab_unpipelined_impl_top.v
    set board_file timing_lab_unpipelined_basys3_top.v
} elseif {$variant eq "pipelined"} {
    set top_name timing_lab_pipelined_basys3_top
    set core_file timing_chain_pipelined.v
    set impl_file timing_lab_pipelined_impl_top.v
    set board_file timing_lab_pipelined_basys3_top.v
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
read_verilog [file join $rtl_dir "timing_pattern_source.v"]
read_verilog [file join $rtl_dir "timing_result_sink.v"]
read_verilog [file join $rtl_dir $core_file]
read_verilog [file join $rtl_dir $impl_file]
read_verilog [file join $rtl_dir $board_file]

synth_design \
    -top $top_name \
    -part xc7a35tcpg236-1

read_xdc [file join $xdc_dir "basys3_resource_power_pins.xdc"]

# Basys3 board clock baseline.
create_clock \
    -name sys_clk \
    -period 10.000 \
    [get_ports clk]

# Post-synthesis resource baseline.
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

# Final implemented resource reports.
report_utilization \
    -hierarchical \
    -file [file join $out_dir "03_utilization_post_route.rpt"]

report_clock_utilization \
    -file [file join $out_dir "04_clock_utilization_post_route.rpt"]

report_ram_utilization \
    -include_lutram \
    -file [file join $out_dir "05_ram_utilization_post_route.rpt"]

# Keep timing visible: power/resource changes must not hide timing failures.
report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -max_paths 10 \
    -file [file join $out_dir "06_timing_summary_post_route.rpt"]

# Environment/voltage/process assumptions used by Report Power.
report_operating_conditions \
    -file [file join $out_dir "07_operating_conditions.rpt"]

# Power report using Vivado's current/default activity sources.
report_power \
    -file [file join $out_dir "08_power_default_activity.rpt"] \
    -rpx  [file join $out_dir "08_power_default_activity.rpx"]

# Controlled What-If comparison:
# same default activity assumptions for both variants.
set_switching_activity \
    -default_static_probability 0.5 \
    -default_toggle_rate 12.5

report_switching_activity \
    -file [file join $out_dir "09_switching_activity_normalized.rpt"]

report_power \
    -file [file join $out_dir "10_power_normalized_activity.rpt"] \
    -rpx  [file join $out_dir "10_power_normalized_activity.rpx"]

# Power optimization is intentionally not inserted into the baseline
# comparison. First compare equivalent implementations.
report_power_opt \
    -file [file join $out_dir "11_power_optimization_status.rpt"]

report_methodology \
    -file [file join $out_dir "12_methodology_post_route.rpt"]

write_checkpoint -force \
    [file join $out_dir "${variant}_post_route.dcp"]

puts ""
puts "SoC 23 resource/power run complete."
puts "Variant : $variant"
puts "Reports : $out_dir"
puts ""
puts "Compare:"
puts "  03_utilization_post_route.rpt"
puts "  06_timing_summary_post_route.rpt"
puts "  07_operating_conditions.rpt"
puts "  10_power_normalized_activity.rpt"
puts ""
puts "Do not compare power numbers unless activity/environment assumptions match."
