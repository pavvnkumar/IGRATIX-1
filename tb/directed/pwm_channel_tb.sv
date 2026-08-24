`timescale 1ns/1ps

module pwm_channel_tb;

    logic        clk;
    logic        rst_n;
    logic [11:0] duty_active;
    logic [11:0] pwm_count;
    logic        output_enable;
    logic        pwm_out;

    pwm_channel dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .duty_active   (duty_active),
        .pwm_count     (pwm_count),
        .output_enable (output_enable),
        .pwm_out       (pwm_out)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check_pwm(
        input logic [11:0] count,
        input logic        expected
    );
        begin
            pwm_count = count;
            #1;

            if (pwm_out !== expected) begin
                $display(
                    "FAIL: count=%h duty=%h enable=%b expected=%b got=%b",
                    pwm_count,
                    duty_active,
                    output_enable,
                    expected,
                    pwm_out
                );
                $fatal(1);
            end
        end
    endtask

    initial begin
        rst_n         = 1'b0;
        duty_active   = 12'h000;
        pwm_count     = 12'h000;
        output_enable = 1'b0;

        #20;

        rst_n = 1'b1;

        // OE disabled must force output LOW.
        duty_active = 12'h800;
        check_pwm(12'h000, 1'b0);
        check_pwm(12'h400, 1'b0);
        check_pwm(12'hFFF, 1'b0);

        // 0% duty.
        output_enable = 1'b1;
        duty_active   = 12'h000;

        check_pwm(12'h000, 1'b0);
        check_pwm(12'h400, 1'b0);
        check_pwm(12'hFFF, 1'b0);

        // 100% duty.
        duty_active = 12'hFFF;

        check_pwm(12'h000, 1'b1);
        check_pwm(12'h400, 1'b1);
        check_pwm(12'hFFE, 1'b1);
        check_pwm(12'hFFF, 1'b1);

        // 50% duty.
        duty_active = 12'h800;

        check_pwm(12'h000, 1'b1);
        check_pwm(12'h7FF, 1'b1);
        check_pwm(12'h800, 1'b0);
        check_pwm(12'hFFF, 1'b0);

        // Boundary test around duty transition.
        duty_active = 12'h123;

        check_pwm(12'h122, 1'b1);
        check_pwm(12'h123, 1'b0);
        check_pwm(12'h124, 1'b0);

        $display("PASS: pwm_channel");
        $finish;
    end

endmodule