# SoC 16 - Create a Vivado project for reviewing/packaging the Custom IP
#
# This script prepares the RTL and simulation files.
# It does NOT hand-create component.xml.
# After it finishes:
#   Tools > Create and Package New IP
#   -> Package your current project
#
# Vivado 2026.1 target: Basys3 XC7A35T

set script_dir [file dirname [file normalize [info script]]]
set ip_root    [file normalize [file join $script_dir ".."]]
set work_dir   [file normalize [file join $ip_root "_vivado_packaging_work"]]

file delete -force $work_dir

create_project -force soc16_custom_ip_packaging \
    $work_dir \
    -part xc7a35tcpg236-1

set hdl_dir [file join $ip_root "hdl"]
set tb_dir  [file join $ip_root "testbench"]

add_files -norecurse [list \
    [file join $hdl_dir "axi4lite_slave_adapter.v"] \
    [file join $hdl_dir "custom_register_bank.v"] \
    [file join $hdl_dir "custom_axi4lite_ip.v"] \
    [file join $hdl_dir "example_processing_controller.v"] \
    [file join $hdl_dir "custom_axi4lite_controller_ip.v"] \
]

set_property top custom_axi4lite_controller_ip [current_fileset]
update_compile_order -fileset sources_1

add_files -fileset sim_1 -norecurse [list \
    [file join $tb_dir "tb_custom_axi4lite_controller_ip.v"] \
]

set_property top tb_custom_axi4lite_controller_ip [get_filesets sim_1]
update_compile_order -fileset sim_1

puts ""
puts "SoC 16 packaging review project created."
puts "Top: custom_axi4lite_controller_ip"
puts ""
puts "Next GUI step:"
puts "  Tools > Create and Package New IP"
puts "  Package your current project"
puts ""
puts "Do not manually create component.xml."
