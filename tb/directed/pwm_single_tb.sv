`timescale 1ns/1ps

module pwm_single_tb;

    logic        clk;
    logic        rst_n;
    logic [15:0] pwm_div;
    logic [11:0] duty_active;
    logic        output_enable;
    logic        pwm_out;

    pwm_single dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .pwm_div       (pwm_div),
        .duty_active   (duty_active),
        .output_enable (output_enable),
        .pwm_out       (pwm_out)
    );

    initial clk = 1'b0;
    always #5 clk <= ~clk;

    initial begin
        rst_n         = 1'b0;
        pwm_div       = 16'h0000;
        duty_active   = 12'h800;
        output_enable = 1'b0;

        #20;
        rst_n = 1'b1;

        // OE disabled.
        repeat (10) begin
            @(posedge clk);
            #1;

            if (pwm_out !== 1'b0) begin
                $display("FAIL: OE disabled, PWM is HIGH");
                $fatal(1);
            end
        end

        // Enable PWM.
        output_enable = 1'b1;

        // 50% duty must produce both HIGH and LOW states.
        begin : pwm_observe
            integer high_count;
            integer low_count;

            high_count = 0;
            low_count  = 0;

            repeat (4096) begin
                @(posedge clk);
                #1;

                if (pwm_out)
                    high_count++;
                else
                    low_count++;
            end

            if (high_count == 0 || low_count == 0) begin
                $display(
                    "FAIL: PWM did not produce both states: HIGH=%0d LOW=%0d",
                    high_count,
                    low_count
                );
                $fatal(1);
            end

            $display(
                "PWM observation: HIGH=%0d LOW=%0d",
                high_count,
                low_count
            );
        end

        // 0% duty.
        duty_active = 12'h000;

        repeat (20) begin
            @(posedge clk);
            #1;

            if (pwm_out !== 1'b0) begin
                $display("FAIL: 0%% duty produced HIGH");
                $fatal(1);
            end
        end

        // 100% duty.
        duty_active = 12'hFFF;

        repeat (20) begin
            @(posedge clk);
            #1;

            if (pwm_out !== 1'b1) begin
                $display("FAIL: 100%% duty produced LOW");
                $fatal(1);
            end
        end

        $display("PASS: pwm_single");
        $finish;
    end

endmodule

