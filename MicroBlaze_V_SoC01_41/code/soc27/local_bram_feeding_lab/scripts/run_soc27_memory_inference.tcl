# SoC 27 · Generic local-buffer memory inference check
#
# This flow synthesizes the generic accelerator out-of-context so the
# local memories are not reduced to the fixed three-word board demo.

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set rtl_dir    [file join $root_dir "rtl"]
set out_dir    [file normalize [file join $root_dir "reports" "memory_inference"]]

file mkdir $out_dir

create_project -in_memory -part xc7a35tcpg236-1

read_verilog [file join $rtl_dir "mul_s8_dsp.v"]
read_verilog [file join $rtl_dir "pe4_dot_accum_pipelined.v"]
read_verilog [file join $rtl_dir "vector_dot_controller_pe4.v"]
read_verilog [file join $rtl_dir "vector_bram_sdp.v"]
read_verilog [file join $rtl_dir "bram_vector_feeder.v"]
read_verilog [file join $rtl_dir "local_bram_dot_accelerator.v"]

synth_design \
    -mode out_of_context \
    -top local_bram_dot_accelerator \
    -part xc7a35tcpg236-1

report_utilization \
    -hierarchical \
    -file [file join $out_dir "01_utilization_ooc.rpt"]

report_ram_utilization \
    -include_lutram \
    -file [file join $out_dir "02_ram_utilization_ooc.rpt"] \
    -csv [file join $out_dir "02_ram_utilization_ooc.csv"]

redirect -file [file join $out_dir "03_ramb_cells_ooc.rpt"] {
    set ramb_cells [get_cells -hier -filter {REF_NAME =~ RAMB*}]
    puts "RAMB primitive count: [llength $ramb_cells]"

    foreach cell $ramb_cells {
        puts "[get_property REF_NAME $cell]  $cell"
    }
}

redirect -file [file join $out_dir "04_dsp_cells_ooc.rpt"] {
    set dsp_cells [get_cells -hier -filter {REF_NAME =~ DSP48*}]
    puts "DSP48 primitive count: [llength $dsp_cells]"

    foreach cell $dsp_cells {
        puts "[get_property REF_NAME $cell]  $cell"
    }
}

report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -max_paths 10 \
    -file [file join $out_dir "05_timing_summary_ooc.rpt"]

puts ""
puts "SoC 27 OOC memory-inference check complete."
puts "Verify BRAM mapping in 02_ram_utilization_ooc.rpt / CSV."
puts "Do not claim RAMB18/RAMB36 counts until this report is generated."
