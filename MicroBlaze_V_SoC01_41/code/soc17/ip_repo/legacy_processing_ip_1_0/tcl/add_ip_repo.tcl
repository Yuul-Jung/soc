# SoC 17 - Add the packaged legacy RTL IP repository
set script_dir [file dirname [file normalize [info script]]]
set repo_path [file normalize [file join $script_dir ".." ".."]]

puts "Adding IP repository:"
puts "  $repo_path"

set_property IP_REPO_PATHS $repo_path [current_fileset]
update_ip_catalog -rebuild

puts "Search IP Catalog for: Legacy Processing AXI4-Lite IP"
