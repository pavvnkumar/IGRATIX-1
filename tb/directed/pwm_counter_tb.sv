`timescale 1ns/1ps

module pwm_counter_tb;

    logic        clk;
    logic        rst_n;

    logic [15:0] pwm_div;

    logic [11:0] pwm_count;
    logic        pwm_boundary;


    pwm_counter dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .pwm_div      (pwm_div),
        .pwm_count    (pwm_count),
        .pwm_boundary (pwm_boundary)
    );


    initial clk = 1'b0;
    always #5 clk <= ~clk;


    initial begin

        rst_n   = 1'b0;
        pwm_div = 16'h0000;


        #20;


        if (pwm_count !== 12'h000) begin
            $display("FAIL: reset count=%h", pwm_count);
            $fatal(1);
        end


        rst_n = 1'b1;


        // ---------------------------------------------------------
        // Divider 0
        // Counter increments every clock
        // ---------------------------------------------------------

        @(posedge clk);
        #1;

        if (pwm_count !== 12'h001) begin
            $display(
                "FAIL: divider=0 expected 001 got %h",
                pwm_count
            );
            $fatal(1);
        end


        @(posedge clk);
        #1;

        if (pwm_count !== 12'h002) begin
            $display(
                "FAIL: divider=0 expected 002 got %h",
                pwm_count
            );
            $fatal(1);
        end


        // ---------------------------------------------------------
        // Divider 1
        // Counter increments every 2 clocks
        // ---------------------------------------------------------

        pwm_div = 16'h0001;


        @(posedge clk);
        #1;

        if (pwm_count !== 12'h002) begin
            $display(
                "FAIL: divider=1 advanced early %h",
                pwm_count
            );
            $fatal(1);
        end


        @(posedge clk);
        #1;

        if (pwm_count !== 12'h003) begin
            $display(
                "FAIL: divider=1 expected 003 got %h",
                pwm_count
            );
            $fatal(1);
        end



        // ---------------------------------------------------------
        // Boundary generation
        // ---------------------------------------------------------

        pwm_div = 16'h0000;


        while (pwm_count !== 12'hFFF) begin
            @(posedge clk);
            #1;
        end


        @(posedge clk);
        #1;


        if (pwm_count !== 12'h000) begin
            $display(
                "FAIL: counter did not wrap"
            );
            $fatal(1);
        end


        if (pwm_boundary !== 1'b1) begin
            $display(
                "FAIL: pwm_boundary not asserted"
            );
            $fatal(1);
        end


        @(posedge clk);
        #1;


        if (pwm_boundary !== 1'b0) begin
            $display(
                "FAIL: pwm_boundary not one cycle"
            );
            $fatal(1);
        end



        $display("PASS: pwm_counter");
        $finish;

    end

endmodule

