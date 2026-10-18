# SoC 21 - Prepare Self-Checking / Assertion / Coverage simulation project
set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set work_dir   [file normalize [file join $root_dir "_vivado_soc21_work"]]

file delete -force $work_dir

create_project -force soc21_verification \
    $work_dir \
    -part xc7a35tcpg236-1

set rtl_dir   [file join $root_dir "rtl"]
set verif_dir [file join $root_dir "verification"]
set tb_dir    [file join $root_dir "testbench"]

add_files -norecurse [list \
    [file join $rtl_dir "axi4lite_slave_adapter.v"] \
    [file join $rtl_dir "control_status_bridge_core.v"] \
    [file join $rtl_dir "axi_control_status_bridge_ip.v"] \
    [file join $rtl_dir "example_ready_valid_core.v"] \
    [file join $rtl_dir "axi_control_status_bridge_demo_top.v"] \
]

add_files -fileset sim_1 -norecurse [list \
    [file join $verif_dir "csb_assertions.sv"] \
    [file join $tb_dir "tb_soc21_csb_verification.sv"] \
]

set_property file_type SystemVerilog \
    [get_files [file join $verif_dir "csb_assertions.sv"]]

set_property file_type SystemVerilog \
    [get_files [file join $tb_dir "tb_soc21_csb_verification.sv"]]

set_property top tb_soc21_csb_verification [get_filesets sim_1]
update_compile_order -fileset sim_1

# sbct = statement/branch/condition/toggle code coverage.
set_property -name {xsim.elaborate.xelab.more_options} \
    -value {-cc_type sbct -cov_db_dir ./coverage -cov_db_name soc21} \
    -objects [get_filesets sim_1]

puts ""
puts "SoC 21 verification project prepared."
puts "Simulation top: tb_soc21_csb_verification"
puts "SystemVerilog assertions: verification/csb_assertions.sv"
puts "Code coverage: sbct"
puts ""
puts "Next:"
puts "  source scripts/run_soc21_verification.tcl"
