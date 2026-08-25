`timescale 1ns/1ps

module register_bank_tb;

    logic        clk;
    logic        rst_n;

    logic        write_en;
    logic [7:0]  write_addr;
    logic [31:0] write_data;

    logic        read_req;
    logic [7:0]  read_addr;
    logic [7:0]  read_data;

    logic [15:0] pwm_div;
    logic [15:0][11:0] duty_shadow;
    logic        output_enable;

    logic        global_update;
    logic [3:0]  group_update;

    logic        software_reset_pulse;

    integer i;

    register_bank dut (
        .clk                  (clk),
        .rst_n                (rst_n),

        .write_en             (write_en),
        .write_addr           (write_addr),
        .write_data           (write_data),

        .read_req             (read_req),
        .read_addr            (read_addr),
        .read_data            (read_data),

        .pwm_div              (pwm_div),
        .duty_shadow          (duty_shadow),

        .output_enable        (output_enable),

        .global_update        (global_update),
        .group_update         (group_update),

        .software_reset_pulse (software_reset_pulse)
    );


    initial clk = 1'b0;

    always #5 clk <= ~clk;


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


    task automatic check_read(
        input logic [7:0] addr,
        input logic [7:0] expected
    );
        begin

            @(negedge clk);

            read_addr = addr;
            read_req  = 1'b1;

            @(posedge clk);
            #1;

            if (read_data !== expected) begin

                $display(
                    "FAIL: read addr=%02h data=%02h expected=%02h",
                    addr,
                    read_data,
                    expected
                );

                $fatal(1);

            end

            @(negedge clk);

            read_req  = 1'b0;
            read_addr = 8'h00;

        end
    endtask


    initial begin

        rst_n     = 1'b0;

        write_en  = 1'b0;
        write_addr = 8'h00;
        write_data = 32'h00000000;

        read_req  = 1'b0;
        read_addr = 8'h00;


        // ========================================================
        // RESET
        // ========================================================

        #20;

        rst_n = 1'b1;

        #1;


        if (pwm_div !== 16'h0000) begin
            $display("FAIL: PWM divider reset");
            $fatal(1);
        end

        if (output_enable !== 1'b0) begin
            $display("FAIL: OE reset");
            $fatal(1);
        end

        for (i = 0; i < 16; i = i + 1) begin

            if (duty_shadow[i] !== 12'h000) begin
                $display("FAIL: CH%0d reset", i);
                $fatal(1);
            end

        end


        // ========================================================
        // PWM DIVIDER
        // ========================================================

        write_reg(8'h02, 32'h00000034);
        write_reg(8'h03, 32'h00000012);

        if (pwm_div !== 16'h1234) begin

            $display(
                "FAIL: PWM divider=%04h expected=1234",
                pwm_div
            );

            $fatal(1);

        end


        // ========================================================
        // OE
        // ========================================================

        write_reg(8'h05, 32'h00000001);

        if (output_enable !== 1'b1) begin
            $display("FAIL: OE enable");
            $fatal(1);
        end

        write_reg(8'h05, 32'h00000000);

        if (output_enable !== 1'b0) begin
            $display("FAIL: OE disable");
            $fatal(1);
        end


        // ========================================================
        // ALL 16 PWM CHANNELS
        // ========================================================

        write_reg(8'h10, 32'h00000001);
        write_reg(8'h11, 32'h00000000);

        write_reg(8'h12, 32'h00000023);
        write_reg(8'h13, 32'h00000001);

        write_reg(8'h14, 32'h00000045);
        write_reg(8'h15, 32'h00000002);

        write_reg(8'h16, 32'h00000067);
        write_reg(8'h17, 32'h00000003);

        write_reg(8'h18, 32'h00000089);
        write_reg(8'h19, 32'h00000004);

        write_reg(8'h1A, 32'h000000AB);
        write_reg(8'h1B, 32'h00000005);

        write_reg(8'h1C, 32'h000000CD);
        write_reg(8'h1D, 32'h00000006);

        write_reg(8'h1E, 32'h000000EF);
        write_reg(8'h1F, 32'h00000007);

        write_reg(8'h20, 32'h00000012);
        write_reg(8'h21, 32'h00000008);

        write_reg(8'h22, 32'h00000034);
        write_reg(8'h23, 32'h00000009);

        write_reg(8'h24, 32'h00000056);
        write_reg(8'h25, 32'h0000000A);

        write_reg(8'h26, 32'h00000078);
        write_reg(8'h27, 32'h0000000B);

        write_reg(8'h28, 32'h0000009A);
        write_reg(8'h29, 32'h0000000C);

        write_reg(8'h2A, 32'h000000BC);
        write_reg(8'h2B, 32'h0000000D);

        write_reg(8'h2C, 32'h000000DE);
        write_reg(8'h2D, 32'h0000000E);

        write_reg(8'h2E, 32'h000000FF);
        write_reg(8'h2F, 32'h0000000F);


        if (duty_shadow[0]  !== 12'h001 ||
            duty_shadow[1]  !== 12'h123 ||
            duty_shadow[2]  !== 12'h245 ||
            duty_shadow[3]  !== 12'h367 ||
            duty_shadow[4]  !== 12'h489 ||
            duty_shadow[5]  !== 12'h5AB ||
            duty_shadow[6]  !== 12'h6CD ||
            duty_shadow[7]  !== 12'h7EF ||
            duty_shadow[8]  !== 12'h812 ||
            duty_shadow[9]  !== 12'h934 ||
            duty_shadow[10] !== 12'hA56 ||
            duty_shadow[11] !== 12'hB78 ||
            duty_shadow[12] !== 12'hC9A ||
            duty_shadow[13] !== 12'hDBC ||
            duty_shadow[14] !== 12'hEDE ||
            duty_shadow[15] !== 12'hFFF) begin

            $display("FAIL: PWM shadow register values");
            $fatal(1);

        end


        // ========================================================
        // UPDATE REQUESTS
        // ========================================================

        write_reg(8'h04, 32'h00000001);

        if (global_update !== 1'b1) begin
            $display("FAIL: global update");
            $fatal(1);
        end

        @(posedge clk);
        #1;

        if (global_update !== 1'b0) begin
            $display("FAIL: global update pulse width");
            $fatal(1);
        end


        write_reg(8'h04, 32'h0000001E);

        if (group_update !== 4'b1111) begin
            $display("FAIL: group update");
            $fatal(1);
        end

        @(posedge clk);
        #1;

        if (group_update !== 4'b0000) begin
            $display("FAIL: group update pulse width");
            $fatal(1);
        end


        // ========================================================
        // SOFTWARE RESET REQUEST
        // ========================================================

        write_reg(8'h06, 32'h00000001);

        if (software_reset_pulse !== 1'b1) begin
            $display("FAIL: software reset pulse");
            $fatal(1);
        end

        @(posedge clk);
        #1;

        if (software_reset_pulse !== 1'b0) begin
            $display("FAIL: software reset pulse width");
            $fatal(1);
        end


        // ========================================================
        // READBACK
        // ========================================================

        check_read(8'h02, 8'h34);
        check_read(8'h03, 8'h12);

        check_read(8'h05, 8'h00);

        check_read(8'h10, 8'h01);
        check_read(8'h11, 8'h00);

        check_read(8'h12, 8'h23);
        check_read(8'h13, 8'h01);

        check_read(8'h2E, 8'hFF);
        check_read(8'h2F, 8'h0F);


        // ========================================================
        // RESERVED / INVALID WRITE
        // ========================================================

        write_reg(8'hFF, 32'hFFFFFFFF);

        if (pwm_div !== 16'h1234) begin
            $display("FAIL: invalid write modified PWM divider");
            $fatal(1);
        end


        // ========================================================
        // FINAL
        // ========================================================

        $display("");
        $display("==============================================");
        $display("PASS: register_bank register map/read/write");
        $display("==============================================");

        $finish;

    end

endmodule

