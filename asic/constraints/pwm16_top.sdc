create_clock \
-period 20 \
-name clk \
[get_ports clk]

set_clock_uncertainty 0.5 [get_clocks clk]

set_input_delay 1 \
-clock clk \
[get_ports *]

set_output_delay 1 \
-clock clk \
[get_ports *]

