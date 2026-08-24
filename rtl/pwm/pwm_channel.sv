module pwm_channel (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [11:0] duty_active,
    input  logic [11:0] pwm_count,

    input  logic        output_enable,

    output logic        pwm_out
);

    always_comb begin
        if (!output_enable) begin
            pwm_out = 1'b0;
        end
        else if (duty_active == 12'h000) begin
            pwm_out = 1'b0;
        end
        else if (duty_active == 12'hFFF) begin
            pwm_out = 1'b1;
        end
        else begin
            pwm_out = (pwm_count < duty_active);
        end
    end

endmodule

