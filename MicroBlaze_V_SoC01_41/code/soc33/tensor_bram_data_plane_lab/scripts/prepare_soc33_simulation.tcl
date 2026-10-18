# SoC 33 · Prepare Tensor BRAM data-plane simulation

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set work_dir   [file normalize [file join $root_dir "_vivado_soc33_sim"]]

file delete -force $work_dir

create_project -force soc33_sim \
    $work_dir \
    -part xc7a35tcpg236-1

set rtl_dir [file join $root_dir "rtl"]
set tb_dir  [file join $root_dir "testbench"]

add_files -norecurse [list \
    [file join $rtl_dir "requantize_s32_to_s8.v"] \
    [file join $rtl_dir "requantize_batch2x4_serial.v"] \
    [file join $rtl_dir "tensor_bram_tdp_4k_model.v"] \
    [file join $rtl_dir "tensor_bram_data_plane_engine.v"] \
    [file join $rtl_dir "tensor_bram_data_plane_demo_top.v"] \
]

add_files -fileset sim_1 -norecurse [list \
    [file join $tb_dir "tb_tensor_bram_data_plane.sv"] \
]

set_property file_type SystemVerilog \
    [get_files [file join $tb_dir "tb_tensor_bram_data_plane.sv"]]

set_property top tb_tensor_bram_data_plane [get_filesets sim_1]
update_compile_order -fileset sim_1

puts ""
puts "SoC 33 simulation project prepared."
puts "Simulation top: tb_tensor_bram_data_plane"
