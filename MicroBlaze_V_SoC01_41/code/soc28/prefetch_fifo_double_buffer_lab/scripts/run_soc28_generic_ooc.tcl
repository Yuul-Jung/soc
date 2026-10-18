# SoC 28 · Generic Prefetch/FIFO/Double-Buffer inference check
#
# This flow keeps the accelerator generic so that synthesis can be used
# to inspect the complete two-bank memory subsystem, FIFO, and PE4.

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set rtl_dir    [file join $root_dir "rtl"]
set out_dir    [file normalize [file join $root_dir "reports" "generic_ooc"]]

file mkdir $out_dir

create_project -in_memory -part xc7a35tcpg236-1

read_verilog [file join $rtl_dir "mul_s8_dsp.v"]
read_verilog [file join $rtl_dir "pe4_dot_accum_pipelined.v"]
read_verilog [file join $rtl_dir "vector_dot_controller_pe4.v"]
read_verilog [file join $rtl_dir "vector_bram_sdp.v"]
read_verilog [file join $rtl_dir "stream_fifo_64x4.v"]
read_verilog [file join $rtl_dir "bram_prefetch_fifo_feeder.v"]
read_verilog [file join $rtl_dir "pingpong_vector_memory.v"]
read_verilog [file join $rtl_dir "prefetch_double_buffer_dot_accelerator.v"]

synth_design \
    -mode out_of_context \
    -top prefetch_double_buffer_dot_accelerator \
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
    -max_paths 20 \
    -file [file join $out_dir "05_timing_summary_ooc.rpt"]

report_design_analysis \
    -max_paths 50 \
    -setup \
    -logic_level_distribution \
    -file [file join $out_dir "06_design_analysis_ooc.rpt"]

puts ""
puts "SoC 28 generic OOC synthesis complete."
puts "Check:"
puts "  - four local memory arrays"
puts "  - RAMB mapping"
puts "  - small FIFO implementation"
puts "  - DSP48 mapping"
puts "Do not claim primitive counts until these reports are generated."
