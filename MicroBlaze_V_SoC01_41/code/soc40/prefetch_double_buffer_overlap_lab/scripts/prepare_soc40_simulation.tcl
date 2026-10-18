# SoC 40 · Prepare integrated overlap regression

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set work_dir [file normalize [file join $root_dir "_vivado_soc40_sim"]]

file delete -force $work_dir

create_project -force soc40_sim $work_dir -part xc7a35tcpg236-1

set rtl_dir [file join $root_dir "rtl"]
set tb_dir [file join $root_dir "testbench"]

foreach f {
    requantize_s32_to_s8.v
    requantize_group4_parallel.v
    tensor_bram_tdp_4k_model.v
    tensor_job_engine_overlap.v
    npu_full_control_irq.v
    axi4lite_reg_bridge.v
    bram_clock_reset_adapter.v
    npu_full_accelerator_overlap_ip.v
    npu_full_accelerator_overlap_sim_top.v
} {
    add_files -norecurse [file join $rtl_dir $f]
}

add_files -fileset sim_1 -norecurse \
    [file join $tb_dir "tb_soc40_overlap_regression.sv"]

set_property file_type SystemVerilog \
    [get_files [file join $tb_dir "tb_soc40_overlap_regression.sv"]]

set_property top tb_soc40_overlap_regression [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "SoC 40 integrated overlap simulation prepared."
