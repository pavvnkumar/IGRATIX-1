`timescale 1ns/1ps

module pwm16_top_tb;

    logic clk;
    logic rst_n;

    logic scl;

    logic sda_master;
    logic sda_slave_low;

    wire sda;

    logic [15:0] pwm_out;
    integer high_count;
    integer low_count;

    wire VPWR = 1'b1;
    wire VGND = 1'b0;


    // ------------------------------------------------------------
    // Open drain I2C bus
    // ------------------------------------------------------------

    assign sda =
        (!sda_master || sda_slave_low) ? 1'b0 : 1'b1;



    pwm16_top dut (

        .clk            (clk),
        .rst_n          (rst_n),

        .scl            (scl),
        .sda            (sda),

        .sda_drive_low  (sda_slave_low),

        .pwm_out        (pwm_out)

    );



    initial clk = 1'b0;
    always #5 clk <= ~clk;



    task automatic wait_clk;
        repeat(4) @(posedge clk);
    endtask



    task automatic i2c_start;
        begin
            scl = 1'b1;
            sda_master = 1'b1;

            wait_clk();

            sda_master = 1'b0;

            wait_clk();

            scl = 1'b0;

            wait_clk();
        end
    endtask



    task automatic i2c_stop;
        begin
            scl = 1'b0;
            sda_master = 1'b0;

            wait_clk();

            scl = 1'b1;

            wait_clk();

            sda_master = 1'b1;

            wait_clk();
        end
    endtask



    task automatic i2c_write_bit(input logic b);
        begin
            scl = 1'b0;

            sda_master = b;

            wait_clk();

            scl = 1'b1;

            wait_clk();

            scl = 1'b0;

            wait_clk();
        end
    endtask



    task automatic i2c_write_byte(input logic [7:0] data);

        integer i;

        begin

            for(i=7;i>=0;i=i-1)
                i2c_write_bit(data[i]);

        end

    endtask



    task automatic release_sda;
        sda_master = 1'b1;
    endtask



    task automatic check_ack;

        begin

            release_sda();

            scl = 1'b0;
            wait_clk();

            scl = 1'b1;

            repeat(3) @(posedge clk);


            if(sda !== 1'b0) begin

                $display(
                    "FAIL: ACK missing SDA=%b",
                    sda
                );

                $fatal(1);

            end


            scl = 1'b0;

            wait_clk();

        end

    endtask



    task automatic i2c_write_reg(
        input logic [7:0] addr,
        input logic [7:0] data
    );

        begin

            i2c_start();


            // device address + write
            i2c_write_byte(8'h80);
            check_ack();


            // register address
            i2c_write_byte(addr);
            check_ack();


            // data
            i2c_write_byte(data);
            check_ack();


            i2c_stop();

        end

    endtask



    initial begin


        rst_n = 1'b0;

        scl = 1'b1;

        sda_master = 1'b1;


        #50;

        rst_n = 1'b1;


        wait_clk();

        // --------------------------------------------------------
        // Set PWM divider
        //
        // Small divider for simulation.
        // pwm_div = 4
        // --------------------------------------------------------

        $display("TEST: PWM divider");

        i2c_write_reg(
            8'h02,
            8'h04
        );

        i2c_write_reg(
            8'h03,
            8'h00
        );



        // --------------------------------------------------------
        // Enable PWM output
        // register 0x05 bit0
        // --------------------------------------------------------

        $display("TEST: Enable PWM");

        i2c_write_reg(
            8'h05,
            8'h01
        );



        // --------------------------------------------------------
        // CH0 duty = 50%
        //
        // 12'h800
        //
        // low byte
        // --------------------------------------------------------

        $display("TEST: CH0 duty");

        i2c_write_reg(
            8'h10,
            8'h00
        );


        i2c_write_reg(
            8'h11,
            8'h08
        );



        // --------------------------------------------------------
        // Global update
        // --------------------------------------------------------

        $display("TEST: Global update");

        i2c_write_reg(
            8'h04,
            8'h01
        );

        wait(dut.update_done);

        #1;

        $display(
            "UPDATE COMPLETE active=%h",
            dut.active_duty[0]
        );

        $display(
            "DEBUG UPDATE: shadow=%03h active=%03h",
            dut.duty_shadow[0],
            dut.active_duty[0]
        );


        // Let PWM run through several complete periods
        repeat(25000)
            @(posedge clk);


        // Measure CH0 PWM duty

        high_count = 0;
        low_count  = 0;


        repeat(30000) begin
        
            @(posedge clk);

            if (pwm_out[0] === 1'b1)
                high_count = high_count + 1;
            else if (pwm_out[0] === 1'b0)
                low_count = low_count + 1;
            else begin
            
                $display(
                    "FAIL: PWM became unknown"
                );

                $fatal(1);

            end

        end

        $display(
            "DEBUG: active_duty=%03h pwm_count=%03h pwm_div=%04h",
            dut.active_duty[0],
            dut.u_pwm_controller.pwm_count,
            dut.pwm_div
        );


        $display(
            "CH0 HIGH=%0d LOW=%0d",
            high_count,
            low_count
        );


        // --------------------------------------------------------
        // 50% duty tolerance check
        // --------------------------------------------------------

        if (high_count < 8000 ||
            low_count  < 8000) begin
            
            $display(
                "FAIL: CH0 duty not near 50%%"
            );

            $fatal(1);

        end


        $display(
            "PASS: CH0 50%% PWM verified"
        );



        $display("");
        $display("==============================");
        $display("PASS: pwm16_top system chain");
        $display("==============================");


        $finish;


    end


endmodule
