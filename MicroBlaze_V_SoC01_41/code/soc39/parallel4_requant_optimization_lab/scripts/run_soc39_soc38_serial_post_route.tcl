# SoC 39 · SoC38 fast-read + serial requant post-route comparison
# Same device, 100 MHz target, flow, and report set.

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set rtl_dir [file join $root_dir "rtl"]
set out_dir [file normalize [file join $root_dir "reports" "soc38_serial"]]

file mkdir $out_dir

create_project -in_memory -part xc7a35tcpg236-1

foreach f {
    requantize_s32_to_s8.v
    requantize_batch2x4_serial.v
    tensor_job_engine_pipelined_read.v
    npu_full_control_irq.v
    axi4lite_reg_bridge.v
    bram_clock_reset_adapter.v
    npu_full_accelerator_fastread_ip.v
} {
    read_verilog [file join $rtl_dir $f]
}

synth_design \
    -mode out_of_context \
    -top npu_full_accelerator_fastread_ip \
    -part xc7a35tcpg236-1

create_clock \
    -name s_axi_aclk \
    -period 10.000 \
    [get_ports s_axi_aclk]

redirect -file [file join $out_dir "01_requant_instances.rpt"] {
    set cells [get_cells -hier -filter {REF_NAME == requantize_s32_to_s8}]
    puts "requantize_s32_to_s8 instance count: [llength $cells]"
    foreach cell $cells {
        puts $cell
    }
}

redirect -file [file join $out_dir "02_dsp48_cells_post_synth.rpt"] {
    set cells [get_cells -hier -filter {REF_NAME =~ DSP48*}]
    puts "DSP48 primitive count after synthesis: [llength $cells]"
    foreach cell $cells {
        puts "[get_property REF_NAME $cell]  $cell"
    }
}

report_utilization \
    -hierarchical \
    -file [file join $out_dir "03_utilization_post_synth.rpt"]

report_methodology \
    -file [file join $out_dir "04_methodology_post_synth.rpt"]

opt_design
place_design
phys_opt_design
route_design

report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -max_paths 50 \
    -file [file join $out_dir "05_timing_summary_post_route.rpt"]

report_utilization \
    -hierarchical \
    -file [file join $out_dir "06_utilization_post_route.rpt"]

report_design_analysis \
    -setup \
    -max_paths 50 \
    -logic_level_distribution \
    -file [file join $out_dir "07_design_analysis_post_route.rpt"]

report_methodology \
    -file [file join $out_dir "08_methodology_post_route.rpt"]

report_drc \
    -file [file join $out_dir "09_drc_post_route.rpt"]

report_power \
    -file [file join $out_dir "10_power_vectorless_post_route.rpt"]

puts ""
puts "SoC 39 SoC38 fast-read + serial requant post-route run complete."
puts "Do not infer exact DSP cost from source instance count."
