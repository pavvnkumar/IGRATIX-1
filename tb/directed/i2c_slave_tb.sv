`timescale 1ns/1ps

module i2c_slave_tb;

    logic clk;
    logic rst_n;

    logic scl;
    logic sda_master;
    logic sda_slave_low;

    wire sda;

    logic        write_en;
    logic [7:0]  write_addr;
    logic [31:0] write_data;

    logic [7:0]  read_data;
    logic [7:0]  read_addr;
    logic        read_req;

    // I2C open-drain bus model.
    assign sda =
        (!sda_master || sda_slave_low) ? 1'b0 : 1'b1;

    i2c_slave #(
        .DEVICE_ADDR(7'h40)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .scl           (scl),
        .sda           (sda),

        .sda_drive_low (sda_slave_low),

        .write_en      (write_en),
        .write_addr    (write_addr),
        .write_data    (write_data),

        .read_data     (read_data),
        .read_addr     (read_addr),
        .read_req      (read_req)
    );

    // ------------------------------------------------------------
    // System clock
    // ------------------------------------------------------------

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic wait_clk;
        begin
            repeat (4) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // START
    // ------------------------------------------------------------

    task automatic i2c_start;
        begin
            sda_master = 1'b1;
            scl        = 1'b1;
            wait_clk();

            sda_master = 1'b0;
            wait_clk();

            scl = 1'b0;
            wait_clk();
        end
    endtask

    // ------------------------------------------------------------
    // STOP
    // ------------------------------------------------------------

    task automatic i2c_stop;
        begin
            sda_master = 1'b0;
            scl        = 1'b0;
            wait_clk();

            scl = 1'b1;
            wait_clk();

            sda_master = 1'b1;
            wait_clk();
        end
    endtask

    // ------------------------------------------------------------
    // Write one bit.
    // ------------------------------------------------------------

    task automatic i2c_write_bit(input logic bit_value);
        begin
            scl        = 1'b0;
            sda_master = bit_value;
            wait_clk();

            scl = 1'b1;
            wait_clk();

            scl = 1'b0;
            wait_clk();
        end
    endtask

    // ------------------------------------------------------------
    // Write one byte.
    // ------------------------------------------------------------

    task automatic i2c_write_byte(input logic [7:0] value);
        integer b;

        begin
            for (b = 7; b >= 0; b = b - 1)
                i2c_write_bit(value[b]);
        end
    endtask

    // ------------------------------------------------------------
    // Release SDA.
    // ------------------------------------------------------------

    task automatic release_master;
        begin
            sda_master = 1'b1;
        end
    endtask

    // ------------------------------------------------------------
    // Check slave ACK/NACK.
    //
    // expected_ack = 1 -> SDA LOW
    // expected_ack = 0 -> SDA HIGH
    // ------------------------------------------------------------

    task automatic i2c_check_ack(input logic expected_ack);
        logic expected_sda;

        begin
            expected_sda = expected_ack ? 1'b0 : 1'b1;

            // Release master SDA.
            release_master();

            // Start ACK clock from LOW.
            scl = 1'b0;
            wait_clk();

            // Raise SCL for ACK.
            scl = 1'b1;
            wait_clk();

            // Sample ACK while SCL HIGH.
            if (sda !== expected_sda) begin

                if (expected_ack)
                    $display("FAIL: valid address was not ACKed");
                else
                    $display("FAIL: invalid address was ACKed");

                $display(
                    "ACK DEBUG: scl=%0d sda=%b slave_drive=%0d",
                    scl,
                    sda,
                    sda_slave_low
                );

                $fatal(1);
            end

            // Finish ACK clock.
            scl = 1'b0;
            wait_clk();
        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------

    initial begin

        rst_n      = 1'b0;
        scl        = 1'b1;
        sda_master = 1'b1;

        read_data  = 8'hA5;

        // Hardware reset.
        #50;
        rst_n = 1'b1;
        wait_clk();

        // ========================================================
        // Valid address: 0x40 + WRITE
        // 7-bit address = 0x40
        // Address byte  = 0x80
        // ========================================================

        i2c_start();

        i2c_write_byte(8'h80);

        i2c_check_ack(1'b1);

        i2c_stop();

        // ========================================================
        // Invalid address: 0x41
        // Address byte = 0x82
        // Must NOT ACK.
        // ========================================================

        i2c_start();

        i2c_write_byte(8'h82);

        i2c_check_ack(1'b0);

        i2c_stop();

        $display("PASS: i2c_slave address/ACK");

        $finish;
    end

endmodule