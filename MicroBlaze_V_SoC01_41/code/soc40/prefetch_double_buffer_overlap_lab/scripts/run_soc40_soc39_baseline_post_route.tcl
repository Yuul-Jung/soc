# SoC 40 · SoC39 sequential read/compute post-route comparison
set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set rtl_dir [file join $root_dir "rtl"]
set out_dir [file normalize [file join $root_dir "reports" "soc39_baseline"]]
file mkdir $out_dir

create_project -in_memory -part xc7a35tcpg236-1

foreach f {
    requantize_s32_to_s8.v
    requantize_batch2x4_parallel4.v
    tensor_job_engine_parallel4_requant.v
    npu_full_control_irq.v
    axi4lite_reg_bridge.v
    bram_clock_reset_adapter.v
    npu_full_accelerator_parallel4_ip.v
} {
    read_verilog [file join $rtl_dir $f]
}

synth_design -mode out_of_context -top npu_full_accelerator_parallel4_ip -part xc7a35tcpg236-1
create_clock -name s_axi_aclk -period 10.000 [get_ports s_axi_aclk]

report_utilization -hierarchical     -file [file join $out_dir "01_utilization_post_synth.rpt"]
report_methodology     -file [file join $out_dir "02_methodology_post_synth.rpt"]

opt_design
place_design
phys_opt_design
route_design

report_timing_summary -delay_type min_max -report_unconstrained -max_paths 50     -file [file join $out_dir "03_timing_summary_post_route.rpt"]
report_utilization -hierarchical     -file [file join $out_dir "04_utilization_post_route.rpt"]
report_design_analysis -setup -max_paths 50 -logic_level_distribution     -file [file join $out_dir "05_design_analysis_post_route.rpt"]
report_methodology     -file [file join $out_dir "06_methodology_post_route.rpt"]
report_drc     -file [file join $out_dir "07_drc_post_route.rpt"]
report_power     -file [file join $out_dir "08_power_vectorless_post_route.rpt"]

puts "SoC 40 SoC39 sequential read/compute post-route run complete."
