# SoC 29 · Prepare self-checking simulation project

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set work_dir   [file normalize [file join $root_dir "_vivado_soc29_sim"]]

file delete -force $work_dir

create_project -force soc29_sim \
    $work_dir \
    -part xc7a35tcpg236-1

set rtl_dir [file join $root_dir "rtl"]
set tb_dir  [file join $root_dir "testbench"]

add_files -norecurse [list \
    [file join $rtl_dir "mul_s8_dsp.v"] \
    [file join $rtl_dir "ws_dual_pe4_datapath.v"] \
    [file join $rtl_dir "ws_tiled_batch_engine.v"] \
]

add_files -fileset sim_1 -norecurse [list \
    [file join $tb_dir "tb_ws_tiled_batch_engine.sv"] \
]

set_property file_type SystemVerilog \
    [get_files [file join $tb_dir "tb_ws_tiled_batch_engine.sv"]]

set_property top tb_ws_tiled_batch_engine [get_filesets sim_1]
update_compile_order -fileset sim_1

puts ""
puts "SoC 29 simulation project prepared."
puts "Simulation top: tb_ws_tiled_batch_engine"
