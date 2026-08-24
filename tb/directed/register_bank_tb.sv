`timescale 1ns/1ps

module register_bank_tb;

    logic        clk;
    logic        rst_n;

    logic        write_en;
    logic [7:0]  write_addr;
    logic [31:0] write_data;

    logic [15:0] pwm_div;
    logic [11:0] duty_shadow [0:15];
    logic        output_enable;
    logic        update_pulse;
    logic        software_reset_pulse;

    integer i;

    register_bank dut (
        .clk                  (clk),
        .rst_n                (rst_n),
        .write_en             (write_en),
        .write_addr           (write_addr),
        .write_data           (write_data),
        .pwm_div              (pwm_div),
        .duty_shadow          (duty_shadow),
        .output_enable        (output_enable),
        .update_pulse         (update_pulse),
        .software_reset_pulse (software_reset_pulse)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic write_reg(
        input logic [7:0]  addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk);
            write_addr = addr;
            write_data = data;
            write_en   = 1'b1;

            @(negedge clk);
            write_en   = 1'b0;
            write_addr = 8'h00;
            write_data = 32'h00000000;
        end
    endtask

    initial begin
        rst_n    = 1'b0;
        write_en = 1'b0;
        write_addr = 8'h00;
        write_data = 32'h00000000;

        #20;
        rst_n = 1'b1;

        // Reset defaults.
        if (pwm_div !== 16'h0000) begin
            $display("FAIL: PWM_DIV reset value");
            $fatal(1);
        end

        if (output_enable !== 1'b0) begin
            $display("FAIL: OE reset value");
            $fatal(1);
        end

        for (i = 0; i < 16; i = i + 1) begin
            if (duty_shadow[i] !== 12'h000) begin
                $display("FAIL: DUTY%0d reset value", i);
                $fatal(1);
            end
        end

        // PWM divider.
        write_reg(8'h04, 32'h00001234);

        if (pwm_div !== 16'h1234) begin
            $display("FAIL: PWM_DIV write");
            $fatal(1);
        end

        // OE.
        write_reg(8'h00, 32'h00000001);

        if (output_enable !== 1'b1) begin
            $display("FAIL: OE write");
            $fatal(1);
        end

        // All 16 duty registers.
        write_reg(8'h10, 32'h00000001);
        write_reg(8'h14, 32'h00000123);
        write_reg(8'h18, 32'h00000234);
        write_reg(8'h1C, 32'h00000345);
        write_reg(8'h20, 32'h00000456);
        write_reg(8'h24, 32'h00000567);
        write_reg(8'h28, 32'h00000678);
        write_reg(8'h2C, 32'h00000789);
        write_reg(8'h30, 32'h0000089A);
        write_reg(8'h34, 32'h000009AB);
        write_reg(8'h38, 32'h00000ABC);
        write_reg(8'h3C, 32'h00000BCD);
        write_reg(8'h40, 32'h00000CDE);
        write_reg(8'h44, 32'h00000DEF);
        write_reg(8'h48, 32'h00000EFA);
        write_reg(8'h4C, 32'h00000FFF);

        if (duty_shadow[0]  !== 12'h001 ||
            duty_shadow[1]  !== 12'h123 ||
            duty_shadow[2]  !== 12'h234 ||
            duty_shadow[3]  !== 12'h345 ||
            duty_shadow[4]  !== 12'h456 ||
            duty_shadow[5]  !== 12'h567 ||
            duty_shadow[6]  !== 12'h678 ||
            duty_shadow[7]  !== 12'h789 ||
            duty_shadow[8]  !== 12'h89A ||
            duty_shadow[9]  !== 12'h9AB ||
            duty_shadow[10] !== 12'hABC ||
            duty_shadow[11] !== 12'hBCD ||
            duty_shadow[12] !== 12'hCDE ||
            duty_shadow[13] !== 12'hDEF ||
            duty_shadow[14] !== 12'hEFA ||
            duty_shadow[15] !== 12'hFFF) begin

            $display("FAIL: duty register values");
            $fatal(1);
        end

        // UPDATE pulse must assert for exactly one clock cycle.
        @(negedge clk);
        write_addr = 8'h00;
        write_data = 32'h00000003;
        write_en   = 1'b1;

        @(posedge clk);
        #1;

        if (update_pulse !== 1'b1) begin
            $display("FAIL: update pulse was not generated");
            $fatal(1);
        end

        @(negedge clk);
        write_en   = 1'b0;
        write_addr = 8'h00;
        write_data = 32'h00000000;

        @(posedge clk);
        #1;

        if (update_pulse !== 1'b0) begin
            $display("FAIL: update pulse was not one clock wide");
            $fatal(1);
        end

        // SOFTWARE RESET pulse must assert for exactly one clock cycle.
        @(negedge clk);
        write_addr = 8'h00;
        write_data = 32'h00000005;
        write_en   = 1'b1;
        
        @(posedge clk);
        #1;
        
        if (software_reset_pulse !== 1'b1) begin
            $display("FAIL: software reset pulse was not generated");
            $fatal(1);
        end
        
        @(negedge clk);
        write_en   = 1'b0;
        write_addr = 8'h00;
        write_data = 32'h00000000;
        
        @(posedge clk);
        #1;
        
        if (software_reset_pulse !== 1'b0) begin
            $display("FAIL: software reset pulse was not one clock wide");
            $fatal(1);
        end

        // Invalid address must not alter known registers.
        write_reg(8'hFF, 32'hFFFFFFFF);

        if (pwm_div !== 16'h1234) begin
            $display("FAIL: invalid address modified PWM_DIV");
            $fatal(1);
        end

        $display("PASS: register_bank");
        $finish;
    end

endmodule
