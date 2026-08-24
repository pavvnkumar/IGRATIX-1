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


    // ============================================================
    // Open-drain SDA model
    // ============================================================

    assign sda =
        (!sda_master || sda_slave_low) ? 1'b0 : 1'b1;


    // ============================================================
    // DUT
    // ============================================================

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


    // ============================================================
    // Clock
    // ============================================================

    initial clk = 1'b0;

    always #5 clk <= ~clk;


    // ============================================================
    // System-clock settling
    // ============================================================

    task automatic wait_clk;
        begin
            repeat (4) @(posedge clk);
        end
    endtask


    // ============================================================
    // START
    // ============================================================

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


    // ============================================================
    // STOP
    // ============================================================

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


    // ============================================================
    // Write one I2C bit
    // ============================================================

    task automatic i2c_write_bit(
        input logic bit_value
    );
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


    // ============================================================
    // Write one byte MSB first
    // ============================================================

    task automatic i2c_write_byte(
        input logic [7:0] value
    );

        integer b;

        begin

            for (b = 7; b >= 0; b = b - 1)
                i2c_write_bit(value[b]);

        end
    endtask


    // ============================================================
    // Release master SDA
    // ============================================================

    task automatic release_master;
        begin
            sda_master = 1'b1;
        end
    endtask


    // ============================================================
    // Address ACK/NACK check
    // ============================================================

    task automatic i2c_check_address_ack(
        input logic expected_ack
    );

        begin

            release_master();

            scl = 1'b0;

            wait_clk();

            scl = 1'b1;

            repeat (3) @(posedge clk);


            if (expected_ack) begin

                if (sda !== 1'b0) begin

                    $display(
                        "FAIL: expected address ACK, SDA=%b slave_drive=%b state=%0d",
                        sda,
                        sda_slave_low,
                        dut.state
                    );

                    $fatal(1);

                end

            end
            else begin

                if (sda !== 1'b1) begin

                    $display(
                        "FAIL: expected address NACK, SDA=%b slave_drive=%b state=%0d",
                        sda,
                        sda_slave_low,
                        dut.state
                    );

                    $fatal(1);

                end

            end


            scl = 1'b0;

            wait_clk();

        end
    endtask


    // ============================================================
    // Write-byte ACK + write-event check
    // ============================================================

    task automatic i2c_check_write_ack(
        input logic [7:0]  expected_addr,
        input logic [31:0] expected_data
    );

        integer cycles;
        logic   found;

        begin

            found = 1'b0;

            release_master();

            scl = 1'b0;

            wait_clk();

            scl = 1'b1;

            repeat (3) @(posedge clk);


            if (sda !== 1'b0) begin

                $display(
                    "FAIL: expected write ACK, SDA=%b slave_drive=%b state=%0d",
                    sda,
                    sda_slave_low,
                    dut.state
                );

                $fatal(1);

            end


            // Complete ACK cycle.
            scl = 1'b0;


            // Monitor write event.
            for (cycles = 0; cycles < 6; cycles = cycles + 1) begin

                @(posedge clk);

                if (write_en) begin

                    found = 1'b1;

                    $display(
                        "WRITE EVENT: addr=%02h data=%08h",
                        write_addr,
                        write_data
                    );


                    if (write_addr !== expected_addr) begin

                        $display(
                            "FAIL: write_addr=%02h expected=%02h",
                            write_addr,
                            expected_addr
                        );

                        $fatal(1);

                    end


                    if (write_data !== expected_data) begin

                        $display(
                            "FAIL: write_data=%08h expected=%08h",
                            write_data,
                            expected_data
                        );

                        $fatal(1);

                    end

                end

            end


            if (!found) begin

                $display(
                    "FAIL: write_en pulse not detected state=%0d addr=%02h data=%08h",
                    dut.state,
                    write_addr,
                    write_data
                );

                $fatal(1);

            end

        end
    endtask


    // ============================================================
    // Read address ACK + read request check
    // ============================================================

    task automatic i2c_check_read_address;

        integer cycles;
        logic   found;

        begin

            found = 1'b0;

            release_master();

            scl = 1'b0;

            wait_clk();

            scl = 1'b1;

            repeat (3) @(posedge clk);


            // Valid read address must ACK.
            if (sda !== 1'b0) begin

                $display(
                    "FAIL: valid read address was not ACKed, SDA=%b slave_drive=%b state=%0d",
                    sda,
                    sda_slave_low,
                    dut.state
                );

                $fatal(1);

            end


            // ACK completes on falling edge.
            scl = 1'b0;


            // Monitor read request event.
            for (cycles = 0; cycles < 6; cycles = cycles + 1) begin

                @(posedge clk);

                if (read_req) begin

                    found = 1'b1;

                    $display(
                        "READ REQUEST: addr=%02h data=%02h",
                        read_addr,
                        read_data
                    );


                    if (read_addr !== 8'h00) begin

                        $display(
                            "FAIL: read_addr=%02h expected=00",
                            read_addr
                        );

                        $fatal(1);

                    end

                end

            end


            if (!found) begin

                $display(
                    "FAIL: read_req pulse not detected state=%0d read_addr=%02h",
                    dut.state,
                    read_addr
                );

                $fatal(1);

            end

        end
    endtask


    // ============================================================
    // Read one byte from slave.
    //
    // Master releases SDA.
    // Slave drives each bit while SCL is LOW.
    // Master samples each bit while SCL is HIGH.
    // ============================================================

    task automatic i2c_read_byte(
        output logic [7:0] value
    );

        integer b;

        begin

            value = 8'h00;

            // Master must release SDA for slave transmission.
            sda_master = 1'b1;


            for (b = 7; b >= 0; b = b - 1) begin

                // Start each data bit with SCL LOW.
                scl = 1'b0;

                wait_clk();


                // Raise SCL and sample the slave bit.
                scl = 1'b1;

                repeat (3) @(posedge clk);

                value[b] = sda;


                // Return SCL LOW.
                scl = 1'b0;

                wait_clk();

            end

        end
    endtask


    // ============================================================
    // Master NACK after read byte.
    //
    // NACK = SDA released HIGH while SCL HIGH.
    // ============================================================

    task automatic i2c_master_nack;
        begin

            sda_master = 1'b1;

            scl = 1'b0;

            wait_clk();

            scl = 1'b1;

            repeat (3) @(posedge clk);


            if (sda !== 1'b1) begin

                $display(
                    "FAIL: expected NACK after read, SDA=%b slave_drive=%b state=%0d",
                    sda,
                    sda_slave_low,
                    dut.state
                );

                $fatal(1);

            end


            scl = 1'b0;

            wait_clk();

        end
    endtask


    // ============================================================
    // Main test
    // ============================================================

    initial begin

        logic [7:0] received_data;


        rst_n      = 1'b0;

        scl        = 1'b1;
        sda_master = 1'b1;

        read_data  = 8'hA5;


        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        #50;

        rst_n = 1'b1;

        wait_clk();


        // ========================================================
        // TEST 1
        // Valid address + WRITE
        // ========================================================

        $display("TEST 1: valid address ACK");

        i2c_start();

        i2c_write_byte(8'h80);

        i2c_check_address_ack(1'b1);


        // ========================================================
        // TEST 2
        // Register address
        // ========================================================

        $display("TEST 2: register address ACK");

        i2c_write_byte(8'h10);

        i2c_check_address_ack(1'b1);


        // ========================================================
        // TEST 3
        // Register data + write event
        // ========================================================

        $display("TEST 3: register data ACK + write");

        i2c_write_byte(8'hAB);

        i2c_check_write_ack(
            8'h10,
            32'h000000AB
        );


        i2c_stop();


        // ========================================================
        // TEST 4
        // Invalid address must NACK
        // ========================================================

        $display("TEST 4: invalid address NACK");

        i2c_start();

        i2c_write_byte(8'h82);

        i2c_check_address_ack(1'b0);

        i2c_stop();


        // ========================================================
        // TEST 5
        // Valid address + READ
        // ========================================================

        $display("TEST 5: valid read address ACK");

        i2c_start();

        i2c_write_byte(8'h81);

        i2c_check_read_address();


        // ========================================================
        // TEST 6
        // Read actual data byte.
        //
        // read_data = A5 = 1010_0101
        // ========================================================

        $display("TEST 6: read data transmission");

        i2c_read_byte(received_data);


        $display(
            "READ DATA: received=%02h expected=%02h",
            received_data,
            read_data
        );


        if (received_data !== read_data) begin

            $display(
                "FAIL: read data mismatch received=%02h expected=%02h",
                received_data,
                read_data
            );

            $fatal(1);

        end


        // --------------------------------------------------------
        // Master terminates the read with NACK.
        // --------------------------------------------------------

        i2c_master_nack();

        i2c_stop();


        // ========================================================
        // FINAL
        // ========================================================

        $display("");
        $display("==============================================");
        $display("PASS: i2c_slave address/register/read data");
        $display("==============================================");

        $finish;

    end

endmodule
