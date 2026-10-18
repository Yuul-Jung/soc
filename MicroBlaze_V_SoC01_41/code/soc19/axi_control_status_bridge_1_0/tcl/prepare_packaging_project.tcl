# SoC 19 - Prepare AXI Control / Status Bridge packaging project
set script_dir [file dirname [file normalize [info script]]]
set ip_root [file normalize [file join $script_dir ".."]]
set work_dir [file normalize [file join $ip_root "_vivado_packaging_work"]]

file delete -force $work_dir

create_project -force soc19_axi_control_status_bridge \
    $work_dir \
    -part xc7a35tcpg236-1

set hdl_dir [file join $ip_root "hdl"]
set tb_dir  [file join $ip_root "testbench"]

add_files -norecurse [list \
    [file join $hdl_dir "axi4lite_slave_adapter.v"] \
    [file join $hdl_dir "control_status_bridge_core.v"] \
    [file join $hdl_dir "axi_control_status_bridge_ip.v"] \
    [file join $hdl_dir "example_ready_valid_core.v"] \
    [file join $hdl_dir "axi_control_status_bridge_demo_top.v"] \
]

# Packaging target is the reusable bridge, not the demo functional core.
set_property top axi_control_status_bridge_ip [current_fileset]
update_compile_order -fileset sources_1

add_files -fileset sim_1 -norecurse [list \
    [file join $tb_dir "tb_axi_control_status_bridge_demo_top.v"] \
]

puts "SoC 19 project prepared."
puts "Packaging top: axi_control_status_bridge_ip"
puts "Demo top is simulation/reference only."
puts "Do not hand-create component.xml."
