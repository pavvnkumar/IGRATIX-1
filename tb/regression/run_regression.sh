#!/bin/bash

set -e

echo "================================="
echo " IGRATIX-1 RTL REGRESSION"
echo "================================="

ROOT=$(pwd)

run_test()
{
    NAME=$1
    TOP=$2
    FILES=$3

    echo ""
    echo "---------------------------------"
    echo "RUNNING: $NAME"
    echo "---------------------------------"

    verilator \
    --binary \
    --timing \
    --Wall \
    -Wno-UNUSEDSIGNAL \
    --top-module $TOP \
    $FILES \
    -o $TOP

    ./obj_dir/$TOP

    echo "$NAME : PASS"
}


run_test \
"I2C Slave" \
"i2c_slave_tb" \
"rtl/i2c/i2c_slave.sv tb/directed/i2c_slave_tb.sv"


run_test \
"Register Bank" \
"register_bank_tb" \
"rtl/registers/register_bank.sv tb/directed/register_bank_tb.sv"


run_test \
"PWM Counter" \
"pwm_counter_tb" \
"rtl/pwm/pwm_counter.sv tb/directed/pwm_counter_tb.sv"


run_test \
"PWM Channel" \
"pwm_channel_tb" \
"rtl/pwm/pwm_channel.sv tb/directed/pwm_channel_tb.sv"


run_test \
"PWM Single" \
"pwm_single_tb" \
"rtl/pwm/pwm_counter.sv rtl/pwm/pwm_channel.sv rtl/pwm/pwm_single.sv tb/directed/pwm_single_tb.sv"


run_test \
"PWM Controller" \
"pwm_controller_tb" \
"rtl/pwm/pwm_counter.sv rtl/pwm/pwm_channel.sv rtl/pwm/pwm_controller.sv tb/directed/pwm_controller_tb.sv"


run_test \
"Update Sync" \
"update_sync_tb" \
"rtl/common/update_sync.sv tb/directed/update_sync_tb.sv"


run_test \
"IGRATIX-1 Top Integration" \
"pwm16_top_tb" \
"rtl/pwm/pwm_counter.sv rtl/pwm/pwm_channel.sv rtl/pwm/pwm_controller.sv rtl/common/update_sync.sv rtl/registers/register_bank.sv rtl/i2c/i2c_slave.sv rtl/top/pwm16_top.sv tb/directed/pwm16_top_tb.sv"


echo ""
echo "================================="
echo " IGRATIX-1 REGRESSION PASS"
echo "================================="