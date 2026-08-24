`timescale 1ns/1ps

module pwm_counter_tb;

    logic        clk;
    logic        rst_n;
    logic [15:0] pwm_div;
    logic [11:0] pwm_count;

    pwm_counter dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .pwm_div   (pwm_div),
        .pwm_count (pwm_count)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst_n   = 1'b0;
        pwm_div = 16'h0000;

        #20;

        if (pwm_count !== 12'h000) begin
            $display("FAIL: reset count = %h", pwm_count);
            $fatal(1);
        end

        rst_n = 1'b1;

        // Divider = 0:
        // counter advances every clock.
        @(posedge clk);
        #1;

        if (pwm_count !== 12'h001) begin
            $display("FAIL: divider=0 expected count=001 got=%h",
                     pwm_count);
            $fatal(1);
        end

        @(posedge clk);
        #1;

        if (pwm_count !== 12'h002) begin
            $display("FAIL: divider=0 expected count=002 got=%h",
                     pwm_count);
            $fatal(1);
        end

        // Divider = 1:
        // counter advances every 2 clocks.
        pwm_div = 16'h0001;

        @(posedge clk);
        #1;

        if (pwm_count !== 12'h002) begin
            $display("FAIL: divider=1 advanced too early: %h",
                     pwm_count);
            $fatal(1);
        end

        @(posedge clk);
        #1;

        if (pwm_count !== 12'h003) begin
            $display("FAIL: divider=1 expected count=003 got=%h",
                     pwm_count);
            $fatal(1);
        end

        // The counter is a DUT output, so we cannot directly force it
        // from the testbench.
        //
        // Instead, verify wrap by running until 0xFFF -> 0x000.
        pwm_div = 16'h0000;

        while (pwm_count !== 12'hFFF) begin
            @(posedge clk);
            #1;
        end

        @(posedge clk);
        #1;

        if (pwm_count !== 12'h000) begin
            $display("FAIL: expected wrap to 000 got=%h",
                     pwm_count);
            $fatal(1);
        end

        $display("PASS: pwm_counter");
        $finish;
    end

endmodule