`timescale 1ns/1ps

module pwm_controller (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [15:0]  pwm_div,

    input  logic [11:0]  duty_shadow [0:15],
    input  logic         update,

    input  logic         output_enable,

    output logic [15:0]  pwm_out
);

    logic [11:0] duty_active [0:15];
    logic [11:0] pwm_count;

    integer i;

    pwm_counter u_pwm_counter (
        .clk       (clk),
        .rst_n     (rst_n),
        .pwm_div   (pwm_div),
        .pwm_count (pwm_count)
    );

    // Shadow -> active transfer.
    // All channels update together on the same clock edge.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 16; i = i + 1)
                duty_active[i] <= 12'h000;
        end
        else if (update) begin
            for (i = 0; i < 16; i = i + 1)
                duty_active[i] <= duty_shadow[i];
        end
    end

    genvar ch;

    generate
        for (ch = 0; ch < 16; ch = ch + 1) begin : gen_pwm_channel

            pwm_channel u_pwm_channel (
                .clk           (clk),
                .rst_n         (rst_n),
                .duty_active   (duty_active[ch]),
                .pwm_count     (pwm_count),
                .output_enable (output_enable),
                .pwm_out       (pwm_out[ch])
            );

        end
    endgenerate

endmodule
