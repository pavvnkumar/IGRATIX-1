`timescale 1ns/1ps

module pwm_controller (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [15:0]  pwm_div,

    input  logic [11:0]  active_duty [0:15],

    input  logic         output_enable,

    output logic [15:0]  pwm_out,
    output logic         pwm_boundary
);

    logic [11:0] pwm_count;

    pwm_counter u_pwm_counter (
        .clk          (clk),
        .rst_n        (rst_n),
        .pwm_div      (pwm_div),
        .pwm_count    (pwm_count),
        .pwm_boundary (pwm_boundary)
    );

    genvar ch;

    generate
        for (ch = 0; ch < 16; ch = ch + 1) begin : gen_pwm_channel

            pwm_channel u_pwm_channel (
                .clk           (clk),
                .rst_n         (rst_n),
                .duty_active   (active_duty[ch]),
                .pwm_count     (pwm_count),
                .output_enable (output_enable),
                .pwm_out       (pwm_out[ch])
            );

        end
    endgenerate

endmodule

