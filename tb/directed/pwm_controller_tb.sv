`timescale 1ns/1ps

module pwm_controller_tb;

    logic clk;
    logic rst_n;

    logic [15:0] pwm_div;

    logic [11:0] active_duty [0:15];

    logic output_enable;

    logic [15:0] pwm_out;

    logic pwm_boundary;

    integer i;
    integer high_seen;
    integer low_seen;


    pwm_controller dut (

        .clk           (clk),
        .rst_n         (rst_n),

        .pwm_div       (pwm_div),

        .active_duty   (active_duty),

        .output_enable (output_enable),

        .pwm_out       (pwm_out),

        .pwm_boundary  (pwm_boundary)

    );


    initial clk = 1'b0;
    always #5 clk <= ~clk;


    initial begin

        rst_n         = 1'b0;
        pwm_div       = 16'h0000;

        output_enable = 1'b0;

        for (i = 0; i < 16; i = i + 1)
            active_duty[i] = 12'h000;


        #20;

        rst_n = 1'b1;


        // ---------------------------------------------------------
        // Verify PWM boundary exists and is not X
        // ---------------------------------------------------------

        repeat (100) begin
            @(posedge clk);
            #1;

            if (^pwm_boundary === 1'bx) begin
                $display("FAIL: pwm_boundary unknown");
                $fatal(1);
            end
        end


        // ---------------------------------------------------------
        // Channel 0 = 0%
        // Channel 1 = 25%
        // ---------------------------------------------------------

        active_duty[0] = 12'h000;
        active_duty[1] = 12'h400;


        output_enable = 1'b1;


        repeat (20) begin
            @(posedge clk);
            #1;
        end


        // ---------------------------------------------------------
        // Channel 0 always LOW
        // ---------------------------------------------------------

        repeat (20) begin

            @(posedge clk);
            #1;

            if (pwm_out[0] !== 1'b0) begin

                $display(
                    "FAIL: CH0 not zero duty"
                );

                $fatal(1);

            end

        end



        // ---------------------------------------------------------
        // Channel 1 25% duty waveform check
        // ---------------------------------------------------------

        high_seen = 0;
        low_seen  = 0;


        repeat (5000) begin

            @(posedge clk);
            #1;


            if (pwm_out[1])
                high_seen = high_seen + 1;
            else
                low_seen = low_seen + 1;

        end


        if ((high_seen == 0) || (low_seen == 0)) begin

            $display(
                "FAIL: CH1 PWM waveform missing"
            );

            $fatal(1);

        end



        // ---------------------------------------------------------
        // Change channel 1 to 100%
        // ---------------------------------------------------------

        active_duty[1] = 12'hFFF;


        repeat (20) begin

            @(posedge clk);
            #1;


            if (pwm_out[1] !== 1'b1) begin

                $display(
                    "FAIL: CH1 100%% duty failed"
                );

                $fatal(1);

            end

        end



        // ---------------------------------------------------------
        // Output enable override
        // ---------------------------------------------------------

        output_enable = 1'b0;


        repeat (20) begin

            @(posedge clk);
            #1;


            if (pwm_out !== 16'h0000) begin

                $display(
                    "FAIL: OE did not disable outputs"
                );

                $fatal(1);

            end

        end



        $display("PASS: pwm_controller");
        $finish;


    end

endmodule

