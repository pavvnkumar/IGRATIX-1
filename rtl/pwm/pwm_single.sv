`timescale 1ns/1ps

module pwm_single (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [15:0] pwm_div,
    input  logic [11:0] duty_active,
    input  logic        output_enable,

    output logic        pwm_out
);

    logic [11:0] pwm_count;
    logic        pwm_boundary_unused;

    pwm_counter u_pwm_counter (
        .clk       (clk),
        .rst_n     (rst_n),
        .pwm_div   (pwm_div),
        .pwm_count (pwm_count),
        .pwm_boundary (pwm_boundary_unused)
    );

    pwm_channel u_pwm_channel (
        .clk           (clk),
        .rst_n         (rst_n),
        .duty_active   (duty_active),
        .pwm_count     (pwm_count),
        .output_enable (output_enable),
        .pwm_out       (pwm_out)
    );

endmodule

