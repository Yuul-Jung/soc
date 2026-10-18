# SoC 18 packaging helper
set script_dir [file dirname [file normalize [info script]]]
set ip_root [file normalize [file join $script_dir ".."]]
set work_dir [file normalize [file join $ip_root "_vivado_packaging_work"]]

file delete -force $work_dir
create_project -force soc18_pwm_axi4lite_ip $work_dir -part xc7a35tcpg236-1

set hdl_dir [file join $ip_root "hdl"]
set tb_dir  [file join $ip_root "testbench"]

add_files -norecurse [list \
    [file join $hdl_dir "legacy_pwm_core.v"] \
    [file join $hdl_dir "pwm_controller_adapter.v"] \
    [file join $hdl_dir "pwm_register_bank.v"] \
    [file join $hdl_dir "axi4lite_slave_adapter.v"] \
    [file join $hdl_dir "pwm_axi4lite_ip.v"]
]

set_property top pwm_axi4lite_ip [current_fileset]
update_compile_order -fileset sources_1

add_files -fileset sim_1 -norecurse [list \
    [file join $tb_dir "tb_legacy_pwm_core.v"] \
]

puts "Packaging review project created."
puts "Top: pwm_axi4lite_ip"
puts "Next: Tools > Create and Package New IP"
puts "Do not hand-create component.xml."
