# SoC 38 · Prepare optimized fast-read regression simulation

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set work_dir [file normalize [file join $root_dir "_vivado_soc38_sim"]]

file delete -force $work_dir

create_project -force soc38_sim \
    $work_dir \
    -part xc7a35tcpg236-1

set rtl_dir [file join $root_dir "rtl"]
set tb_dir [file join $root_dir "testbench"]

foreach f {
    requantize_s32_to_s8.v
    requantize_batch2x4_serial.v
    tensor_bram_tdp_4k_model.v
    tensor_job_engine_pipelined_read.v
    npu_full_control_irq.v
    axi4lite_reg_bridge.v
    bram_clock_reset_adapter.v
    npu_full_accelerator_fastread_ip.v
    npu_full_accelerator_fastread_sim_top.v
} {
    add_files -norecurse [file join $rtl_dir $f]
}

add_files -fileset sim_1 -norecurse \
    [file join $tb_dir "tb_soc38_fastread_regression.sv"]

set_property file_type SystemVerilog \
    [get_files [file join $tb_dir "tb_soc38_fastread_regression.sv"]]

set_property top tb_soc38_fastread_regression [get_filesets sim_1]
update_compile_order -fileset sim_1

puts ""
puts "SoC 38 optimized fast-read simulation project prepared."
puts "Simulation top: tb_soc38_fastread_regression"
