# SoC 20 - CDC / Reset analysis helper
#
# Run after synthesis or on an opened synthesized design.

report_cdc -details -file soc20_report_cdc.rpt
report_clock_interaction -file soc20_clock_interaction.rpt

puts ""
puts "Review:"
puts "  1. No unknown/unsafe direct multi-bit CDC"
puts "  2. Single-bit crossings recognized as synchronizers"
puts "  3. Reset crossings recognized as asynchronous reset synchronizers"
puts "  4. XPM_CDC_HANDSHAKE paths understood/reviewed"
puts "  5. No combinational logic before synchronizer inputs"
