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
        .clk            (clk),
        .rst_n          (rst_n),
        .pwm_div        (pwm_div),
        .duty_shadow    (duty_shadow),
        .update         (update),
        .output_enable  (output_enable),
        .pwm_out        (pwm_out)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst_n         = 1'b0;
        pwm_div       = 16'h0000;
        update        = 1'b0;
        output_enable = 1'b0;

        for (i = 0; i < 16; i = i + 1)
            duty_shadow[i] = 12'(i) * 12'h100;

        #20;
        rst_n = 1'b1;

        // Reset/OE verification.
        repeat (10) begin
            @(posedge clk);
            #1;

            if (pwm_out !== 16'h0000) begin
                $display("FAIL: outputs not LOW after reset/OE");
                $fatal(1);
            end
        end

        // Program all 16 channels with different duty values.
        duty_shadow[0]  = 12'h000;
        duty_shadow[1]  = 12'h100;
        duty_shadow[2]  = 12'h200;
        duty_shadow[3]  = 12'h300;
        duty_shadow[4]  = 12'h400;
        duty_shadow[5]  = 12'h500;
        duty_shadow[6]  = 12'h600;
        duty_shadow[7]  = 12'h700;
        duty_shadow[8]  = 12'h800;
        duty_shadow[9]  = 12'h900;
        duty_shadow[10] = 12'hA00;
        duty_shadow[11] = 12'hB00;
        duty_shadow[12] = 12'hC00;
        duty_shadow[13] = 12'hD00;
        duty_shadow[14] = 12'hE00;
        duty_shadow[15] = 12'hF00;

        // Explicit global update.
        @(posedge clk);
        update = 1'b1;

        @(posedge clk);
        #1;
        update = 1'b0;

        // Enable outputs.
        output_enable = 1'b1;

        // Observe all channels for one PWM period.
        for (i = 0; i < 16; i = i + 1) begin
            high_count[i] = 0;
            low_count[i]  = 0;
        end

        repeat (4096) begin
            @(posedge clk);
            #1;

            for (i = 0; i < 16; i = i + 1) begin
                if (pwm_out[i])
                    high_count[i] = high_count[i] + 1;
                else
                    low_count[i] = low_count[i] + 1;
            end
        end

        // Channel 0 = 0%.
        if (high_count[0] != 0) begin
            $display("FAIL: channel 0 not 0%%");
            $fatal(1);
        end

        // Channels 1..14 must produce both states.
        for (i = 1; i < 15; i = i + 1) begin
            if (high_count[i] == 0 || low_count[i] == 0) begin
                $display(
                    "FAIL: channel %0d did not produce both states: H=%0d L=%0d",
                    i,
                    high_count[i],
                    low_count[i]
                );
                $fatal(1);
            end
        end

        // Channel 15 receives 0xF00, so it must also produce both states.
        if (high_count[15] == 0 || low_count[15] == 0) begin
            $display("FAIL: channel 15 invalid PWM behavior");
            $fatal(1);
        end

        // OE must force all outputs LOW.
        output_enable = 1'b0;

        repeat (20) begin
            @(posedge clk);
            #1;

            if (pwm_out !== 16'h0000) begin
                $display("FAIL: OE did not disable all channels");
                $fatal(1);
            end
        end

        $display("PASS: pwm_controller");

        for (i = 0; i < 16; i = i + 1)
            $display(
                "CH%0d HIGH=%0d LOW=%0d",
                i,
                high_count[i],
                low_count[i]
            );

        $finish;
    end

endmodule
