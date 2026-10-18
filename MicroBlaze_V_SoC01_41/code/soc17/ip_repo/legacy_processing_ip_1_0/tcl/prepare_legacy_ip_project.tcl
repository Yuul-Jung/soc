# SoC 17 - Prepare a Vivado project for packaging existing Verilog RTL as AXI IP
#
# The original legacy_processing_core.v is intentionally reused unchanged.
# Adapter and AXI/register wrappers are separate files.
#
# After this script:
#   Tools > Create and Package New IP
#   -> Package your current project
#
# Do not hand-create component.xml.

set script_dir [file dirname [file normalize [info script]]]
set ip_root    [file normalize [file join $script_dir ".."]]
set work_dir   [file normalize [file join $ip_root "_vivado_packaging_work"]]

file delete -force $work_dir

create_project -force soc17_legacy_rtl_ip \
    $work_dir \
    -part xc7a35tcpg236-1

set hdl_dir [file join $ip_root "hdl"]
set tb_dir  [file join $ip_root "testbench"]

add_files -norecurse [list \
    [file join $hdl_dir "legacy_processing_core.v"] \
    [file join $hdl_dir "axi4lite_slave_adapter.v"] \
    [file join $hdl_dir "custom_register_bank.v"] \
    [file join $hdl_dir "custom_axi4lite_ip.v"] \
    [file join $hdl_dir "legacy_core_controller_adapter.v"] \
    [file join $hdl_dir "custom_axi4lite_legacy_ip.v"] \
]

set_property top custom_axi4lite_legacy_ip [current_fileset]
update_compile_order -fileset sources_1

add_files -fileset sim_1 -norecurse [list \
    [file join $tb_dir "tb_legacy_processing_core.v"] \
    [file join $tb_dir "tb_custom_axi4lite_legacy_ip.v"] \
]

set_property top tb_custom_axi4lite_legacy_ip [get_filesets sim_1]
update_compile_order -fileset sim_1

puts ""
puts "SoC 17 project prepared."
puts "Packaging top: custom_axi4lite_legacy_ip"
puts "Original legacy RTL was not modified."
