# SoC 40 · Prepare standalone group4 simulation

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set work_dir [file normalize [file join $root_dir "_vivado_soc40_group_sim"]]

file delete -force $work_dir

create_project -force soc40_group_sim $work_dir -part xc7a35tcpg236-1

set rtl_dir [file join $root_dir "rtl"]
set tb_dir [file join $root_dir "testbench"]

add_files -norecurse [file join $rtl_dir "requantize_s32_to_s8.v"]
add_files -norecurse [file join $rtl_dir "requantize_group4_parallel.v"]
add_files -fileset sim_1 -norecurse \
    [file join $tb_dir "tb_requantize_group4_parallel.sv"]

set_property file_type SystemVerilog \
    [get_files [file join $tb_dir "tb_requantize_group4_parallel.sv"]]

set_property top tb_requantize_group4_parallel [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "SoC 40 standalone group4 simulation prepared."
