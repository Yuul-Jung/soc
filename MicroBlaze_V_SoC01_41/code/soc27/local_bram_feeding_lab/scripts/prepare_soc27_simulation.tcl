# SoC 27 · Prepare self-checking simulation

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set work_dir   [file normalize [file join $root_dir "_vivado_soc27_sim"]]

file delete -force $work_dir

create_project -force soc27_sim \
    $work_dir \
    -part xc7a35tcpg236-1

set rtl_dir [file join $root_dir "rtl"]
set tb_dir  [file join $root_dir "testbench"]

add_files -norecurse [list \
    [file join $rtl_dir "mul_s8_dsp.v"] \
    [file join $rtl_dir "pe4_dot_accum_pipelined.v"] \
    [file join $rtl_dir "vector_dot_controller_pe4.v"] \
    [file join $rtl_dir "vector_bram_sdp.v"] \
    [file join $rtl_dir "bram_vector_feeder.v"] \
    [file join $rtl_dir "local_bram_dot_accelerator.v"] \
]

add_files -fileset sim_1 -norecurse [list \
    [file join $tb_dir "tb_local_bram_dot_accelerator.sv"] \
]

set_property file_type SystemVerilog \
    [get_files [file join $tb_dir "tb_local_bram_dot_accelerator.sv"]]

set_property top tb_local_bram_dot_accelerator [get_filesets sim_1]
update_compile_order -fileset sim_1

puts ""
puts "SoC 27 simulation project prepared."
puts "Simulation top: tb_local_bram_dot_accelerator"
