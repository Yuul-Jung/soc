# SoC 20 - Prepare dual-clock CDC demo project
set script_dir [file dirname [file normalize [info script]]]
set ip_root [file normalize [file join $script_dir ".."]]
set work_dir [file normalize [file join $ip_root "_vivado_cdc_work"]]

file delete -force $work_dir

create_project -force soc20_dual_clock_bridge \
    $work_dir \
    -part xc7a35tcpg236-1

set hdl_dir [file join $ip_root "hdl"]
set tb_dir  [file join $ip_root "testbench"]

add_files -norecurse [list \
    [file join $hdl_dir "axi4lite_slave_adapter.v"] \
    [file join $hdl_dir "control_status_bridge_core.v"] \
    [file join $hdl_dir "axi_control_status_bridge_ip.v"] \
    [file join $hdl_dir "xpm_reset_sync_active_low.v"] \
    [file join $hdl_dir "xpm_single_bit_sync.v"] \
    [file join $hdl_dir "xpm_pulse_sync.v"] \
    [file join $hdl_dir "xpm_ready_valid_bus_bridge.v"] \
    [file join $hdl_dir "dual_clock_bridge_cdc_adapter.v"] \
    [file join $hdl_dir "dual_clock_example_core.v"] \
    [file join $hdl_dir "dual_clock_control_status_bridge_demo.v"] \
]

set_property top dual_clock_control_status_bridge_demo [current_fileset]
update_compile_order -fileset sources_1

add_files -fileset sim_1 -norecurse [list \
    [file join $tb_dir "tb_dual_clock_control_status_bridge_demo.v"] \
]

set_property top tb_dual_clock_control_status_bridge_demo [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "SoC 20 CDC demo project prepared."
puts "Run simulation, synthesis, then source tcl/run_cdc_reports.tcl."
