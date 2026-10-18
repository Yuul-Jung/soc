# SoC 41 · Group-8 full sign-off report collector
#
# Usage:
#   open_project <your_project.xpr>
#   open_run impl_1
#   source collect_soc41_signoff_reports.tcl
#
# The script only reports the currently opened implemented design.
# It does not fabricate PASS/FAIL values.

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set out_dir [file normalize [file join $root_dir "reports" "signoff"]]

file mkdir $out_dir

if {[llength [get_cells -quiet]] == 0} {
    error "No implemented design is open. Run open_run impl_1 first."
}

# ------------------------------------------------------------
# 1. Timing / constraints
# ------------------------------------------------------------
check_timing \
    -verbose \
    -file [file join $out_dir "01_check_timing.rpt"]

report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -max_paths 100 \
    -file [file join $out_dir "02_timing_summary.rpt"]

# report_timing_summary does not cover bus-skew constraints.
# If the design has relevant bus-skew constraints, record them too.
if {[catch {
    report_bus_skew \
        -file [file join $out_dir "03_bus_skew.rpt"]
} bus_skew_error]} {
    set fh [open [file join $out_dir "03_bus_skew_NOT_AVAILABLE.txt"] w]
    puts $fh $bus_skew_error
    close $fh
}

# ------------------------------------------------------------
# 2. Methodology / DRC / CDC
# ------------------------------------------------------------
report_methodology \
    -file [file join $out_dir "04_methodology.rpt"]

report_drc \
    -file [file join $out_dir "05_drc.rpt"]

if {[catch {
    report_cdc \
        -details \
        -file [file join $out_dir "06_cdc.rpt"]
} cdc_error]} {
    set fh [open [file join $out_dir "06_cdc_NOT_AVAILABLE.txt"] w]
    puts $fh $cdc_error
    close $fh
}

# ------------------------------------------------------------
# 3. Resource / clock / QoR
# ------------------------------------------------------------
report_utilization \
    -hierarchical \
    -file [file join $out_dir "07_utilization_hierarchical.rpt"]

report_clock_utilization \
    -file [file join $out_dir "08_clock_utilization.rpt"]

report_design_analysis \
    -setup \
    -max_paths 100 \
    -logic_level_distribution \
    -file [file join $out_dir "09_design_analysis_setup.rpt"]

if {[catch {
    report_qor_assessment \
        -file [file join $out_dir "10_qor_assessment.rpt"]
} qor_error]} {
    set fh [open [file join $out_dir "10_qor_assessment_NOT_AVAILABLE.txt"] w]
    puts $fh $qor_error
    close $fh
}

# ------------------------------------------------------------
# 4. Power / thermal
# ------------------------------------------------------------
# Before using this report for sign-off, record:
# - activity source
# - voltage
# - ambient
# - airflow / thermal environment
#
# Post-route power is the preferred implementation-stage estimate.
report_power \
    -file [file join $out_dir "11_power_post_route.rpt"]

# ------------------------------------------------------------
# 5. Checkpoint
# ------------------------------------------------------------
write_checkpoint \
    -force \
    [file join $out_dir "soc41_signoff_snapshot.dcp"]

puts ""
puts "SoC 41 sign-off reports collected."
puts "Fill data/soc41_signoff_input.json from the actual reports/board run."
puts "Then run:"
puts "  python3 scripts/evaluate_soc41_signoff.py data/soc41_signoff_input.json"
