`timescale 1ns/1ps
module pwm_counter (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [15:0] pwm_div,

    output logic [11:0] pwm_count
);

    logic [15:0] div_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_count <= 16'h0000;
            pwm_count <= 12'h000;
        end
        else begin
            if (div_count >= pwm_div) begin
                div_count <= 16'h0000;

                if (pwm_count == 12'hFFF)
                    pwm_count <= 12'h000;
                else
                    pwm_count <= pwm_count + 12'h001;
            end
            else begin
                div_count <= div_count + 16'h0001;
            end
        end
    end

endmodule