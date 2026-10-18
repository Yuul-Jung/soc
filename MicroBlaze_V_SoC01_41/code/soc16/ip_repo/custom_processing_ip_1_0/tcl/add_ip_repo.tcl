# SoC 16 - Add packaged IP repository to the current Vivado project
#
# Usage:
#   1. Edit repo_path if needed.
#   2. Source this file in the Vivado Tcl Console:
#        source add_ip_repo.tcl
#
# The path must point to the repository parent that contains
# packaged IP directories with component.xml files.

set script_dir [file dirname [file normalize [info script]]]
set repo_path [file normalize [file join $script_dir ".." ".."]]

puts "Adding IP repository:"
puts "  $repo_path"

set_property IP_REPO_PATHS $repo_path [current_fileset]
update_ip_catalog -rebuild

puts "IP catalog rebuild requested."
puts "Search the IP Catalog for: Custom Processing AXI4-Lite IP"
