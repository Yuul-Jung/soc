# SoC 30 · Prepare two self-checking simulation sets

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set rtl_dir    [file join $root_dir "rtl"]
set tb_dir     [file join $root_dir "testbench"]

set work_core [file normalize [file join $root_dir "_vivado_soc30_core_sim"]]
file delete -force $work_core

create_project -force soc30_core_sim \
    $work_core \
    -part xc7a35tcpg236-1

add_files -norecurse [list \
    [file join $rtl_dir "requantize_s32_to_s8.v"] \
]

add_files -fileset sim_1 -norecurse [list \
    [file join $tb_dir "tb_requantize_s32_to_s8.sv"] \
]

set_property file_type SystemVerilog \
    [get_files [file join $tb_dir "tb_requantize_s32_to_s8.sv"]]

set_property top tb_requantize_s32_to_s8 [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "Core simulation project prepared: $work_core"

set work_batch [file normalize [file join $root_dir "_vivado_soc30_batch_sim"]]
file delete -force $work_batch

create_project -force soc30_batch_sim \
    $work_batch \
    -part xc7a35tcpg236-1

add_files -norecurse [list \
    [file join $rtl_dir "requantize_s32_to_s8.v"] \
    [file join $rtl_dir "requantize_batch2x4_serial.v"] \
]

add_files -fileset sim_1 -norecurse [list \
    [file join $tb_dir "tb_requantize_batch2x4_serial.sv"] \
]

set_property file_type SystemVerilog \
    [get_files [file join $tb_dir "tb_requantize_batch2x4_serial.sv"]]

set_property top tb_requantize_batch2x4_serial [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "Batch simulation project prepared: $work_batch"
