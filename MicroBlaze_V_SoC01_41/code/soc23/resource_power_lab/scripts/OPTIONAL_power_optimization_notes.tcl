# Optional SoC 23 experiment:
# power_opt_design is NOT part of the baseline comparison.
#
# AMD allows power optimization pre-place or post-place, not both.
# If timing preservation is the priority, post-place optimization is
# generally the safer comparison point.

# Example flow fragment:
#
# opt_design
# place_design
# power_opt_design
# route_design
# report_timing_summary -file timing_after_power_opt.rpt
# report_power -file power_after_power_opt.rpt
#
# Always compare timing and function again after changing optimization flow.
