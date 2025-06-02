set CLK_PERIOD 25
create_clock -name CLK -period $CLK_PERIOD [get_ports {CLK}]
set_clock_uncertainty 0.1000 [get_clocks {CLK}]
set_propagated_clock [get_clocks {CLK}]

set_input_delay 2.0000 -clock [get_clocks {CLK}] [all_inputs]
set_output_delay 2.0000 -clock [get_clocks {CLK}] [all_outputs]
set_load -pin_load 0.1 [all_outputs]

set_max_transition 0.5 [current_design]
set_max_fanout 10 [current_design]
set derate 0.05
puts "\[INFO\]: Setting timing derate to: [expr {$derate * 100}] %"
set_timing_derate -early [expr 1-$derate]
set_timing_derate -late [expr 1+$derate]