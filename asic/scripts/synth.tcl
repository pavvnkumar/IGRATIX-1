read_verilog -sv \
rtl/common/update_sync.sv \
rtl/i2c/i2c_slave.sv \
rtl/pwm/pwm_counter.sv \
rtl/pwm/pwm_channel.sv \
rtl/pwm/pwm_controller.sv \
rtl/registers/register_bank.sv \
rtl/top/pwm16_top.sv


hierarchy -check -top pwm16_top

proc
opt

fsm
opt

memory
opt

techmap
opt

flatten

opt_clean
opt

hierarchy -check
check

clean
rename -enumerate

write_verilog \
-noattr \
-noexpr \
-nodec \
-simple-lhs \
asic/netlist/pwm16_top_flat.v
