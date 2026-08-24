`timescale 1ns/1ps

module pwm_controller_tb;

    logic        clk;
    logic        rst_n;

    logic [15:0] pwm_div;
    logic [11:0] duty_shadow [0:15];
    logic        update;
    logic        output_enable;

    logic [15:0] pwm_out;

    integer i;
    integer high_count [0:15];
    integer low_count  [0:15];

    pwm_controller dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .pwm_div       (pwm_div),
        .duty_shadow   (duty_shadow),
        .update        (update),
        .output_enable (output_enable),
        .pwm_out       (pwm_out)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst_n         = 1'b0;
        pwm_div       = 16'h0000;
        update        = 1'b0;
        output_enable = 1'b0;

        for (i = 0; i < 16; i = i + 1)
            duty_shadow[i] = 12'h000;

        #20;
        rst_n = 1'b1;

        // ------------------------------------------------------------
        // Initial configuration: channel 0 = 0%, channel 1 = 25%.
        // ------------------------------------------------------------

        duty_shadow[0] = 12'h000;
        duty_shadow[1] = 12'h400;

        @(posedge clk);
        update = 1'b1;

        @(posedge clk);
        #1;
        update = 1'b0;

        output_enable = 1'b1;

        // Allow the PWM engine to run.
        repeat (20) begin
            @(posedge clk);
            #1;
        end

        // ------------------------------------------------------------
        // Change channel 1 shadow value to 100%.
        //
        // IMPORTANT:
        // No update pulse is generated yet.
        // The currently active PWM configuration must remain unchanged.
        // ------------------------------------------------------------

        duty_shadow[1] = 12'hFFF;

        // Observe enough cycles to cross the old 25% duty region.
        // The output should still eventually go LOW because the active
        // value is still 0x400.
        repeat (1000) begin
            @(posedge clk);
            #1;
        end

        // ------------------------------------------------------------
        // Now commit the shadow value.
        // ------------------------------------------------------------

        @(posedge clk);
        update = 1'b1;

        @(posedge clk);
        #1;
        update = 1'b0;

        // After the synchronized update, channel 1 must be HIGH
        // because its active duty is now 100%.
        repeat (20) begin
            @(posedge clk);
            #1;

            if (pwm_out[1] !== 1'b1) begin
                $display(
                    "FAIL: channel 1 did not become 100%% after update"
                );
                $fatal(1);
            end
        end

        // Channel 0 remains 0%.
        repeat (20) begin
            @(posedge clk);
            #1;

            if (pwm_out[0] !== 1'b0) begin
                $display(
                    "FAIL: channel 0 changed unexpectedly"
                );
                $fatal(1);
            end
        end

        // ------------------------------------------------------------
        // Verify OE still overrides all channels.
        // ------------------------------------------------------------

        output_enable = 1'b0;

        repeat (20) begin
            @(posedge clk);
            #1;

            if (pwm_out !== 16'h0000) begin
                $display(
                    "FAIL: OE did not force all outputs LOW"
                );
                $fatal(1);
            end
        end

        $display("PASS: pwm_controller");
        $finish;
    end

endmodule