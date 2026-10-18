# SoC 37 · Full SoC implemented report collector
#
# Usage:
#   open_project <your_project.xpr>
#   open_run impl_1
#   source collect_soc37_full_system_reports.tcl
#
# This script does not implement the design. It records the currently
# opened implemented design.

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set out_dir [file normalize [file join $root_dir "reports" "full_system"]]

file mkdir $out_dir

if {[llength [get_cells -quiet]] == 0} {
    error "No implemented design is open. Run open_run impl_1 first."
}

report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -max_paths 100 \
    -file [file join $out_dir "01_timing_summary.rpt"]

report_utilization \
    -hierarchical \
    -file [file join $out_dir "02_utilization_hierarchical.rpt"]

report_clock_utilization \
    -file [file join $out_dir "03_clock_utilization.rpt"]

report_design_analysis \
    -setup \
    -max_paths 100 \
    -logic_level_distribution \
    -file [file join $out_dir "04_design_analysis.rpt"]

report_methodology \
    -file [file join $out_dir "05_methodology.rpt"]

report_drc \
    -file [file join $out_dir "06_drc.rpt"]

report_power \
    -file [file join $out_dir "07_power.rpt"]

puts ""
puts "SoC 37 full-system reports collected."
puts "Record the power activity source and environment together with 07_power.rpt."
