# SoC 39 · Prepare standalone 4-lane requant simulation

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set work_dir [file normalize [file join $root_dir "_vivado_soc39_batch_sim"]]

file delete -force $work_dir

create_project -force soc39_batch_sim \
    $work_dir \
    -part xc7a35tcpg236-1

set rtl_dir [file join $root_dir "rtl"]
set tb_dir [file join $root_dir "testbench"]

add_files -norecurse \
    [file join $rtl_dir "requantize_s32_to_s8.v"]

add_files -norecurse \
    [file join $rtl_dir "requantize_batch2x4_parallel4.v"]

add_files -fileset sim_1 -norecurse \
    [file join $tb_dir "tb_requantize_batch2x4_parallel4.sv"]

set_property file_type SystemVerilog \
    [get_files [file join $tb_dir "tb_requantize_batch2x4_parallel4.sv"]]

set_property top tb_requantize_batch2x4_parallel4 [get_filesets sim_1]
update_compile_order -fileset sim_1

puts ""
puts "SoC 39 standalone parallel4 batch simulation prepared."
