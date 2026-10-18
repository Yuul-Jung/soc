# SoC 21 - Run simulation and save coverage
#
# Run after prepare_soc21_project.tcl in Vivado.

launch_simulation

# Run until the testbench calls $finish.
run all

# Save functional + code coverage while simulation is still active.
write_xsim_coverage \
    -cov_db_dir ./coverage \
    -cov_db_name soc21

puts ""
puts "SoC 21 simulation finished."
puts "Coverage database: ./coverage"
puts ""
puts "Generate a report from an OS shell with:"
puts "  xcrg -cov_db_dir ./coverage -cov_db_name soc21 \\"
puts "       -report_dir ./coverage_report -report_format html"
