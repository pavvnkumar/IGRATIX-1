`timescale 1ns/1ps

module update_sync (
    input  logic        clk,
    input  logic        rst_n,

    // PWM period boundary.
    // One-cycle pulse indicating that the PWM counter has
    // reached the safe update point.
    input  logic        pwm_boundary,

    // Shadow duty values from register_bank.
    input  logic [11:0] shadow_duty [0:15],

    // Update requests from register_bank.
    input  logic        global_update,
    input  logic [3:0]  group_update,

    // Active duty values consumed by pwm_controller.
    output logic [11:0] active_duty [0:15]
);

    integer i;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            for (i = 0; i < 16; i = i + 1)
                active_duty[i] <= 12'h000;

        end

        else if (pwm_boundary) begin

            // ----------------------------------------------------
            // Global update has priority.
            // ----------------------------------------------------

            if (global_update) begin

                for (i = 0; i < 16; i = i + 1)
                    active_duty[i] <= shadow_duty[i];

            end

            // ----------------------------------------------------
            // Otherwise update selected groups.
            // ----------------------------------------------------

            else begin

                if (group_update[0]) begin
                    for (i = 0; i < 4; i = i + 1)
                        active_duty[i] <= shadow_duty[i];
                end

                if (group_update[1]) begin
                    for (i = 4; i < 8; i = i + 1)
                        active_duty[i] <= shadow_duty[i];
                end

                if (group_update[2]) begin
                    for (i = 8; i < 12; i = i + 1)
                        active_duty[i] <= shadow_duty[i];
                end

                if (group_update[3]) begin
                    for (i = 12; i < 16; i = i + 1)
                        active_duty[i] <= shadow_duty[i];
                end

            end
        end
    end

endmodule
