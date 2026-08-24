`timescale 1ns/1ps

module update_sync_tb;

    logic clk;
    logic rst_n;

    logic pwm_boundary;

    logic [11:0] shadow_duty [0:15];
    logic [11:0] active_duty [0:15];
    logic update_done;

    logic        global_update;
    logic [3:0]  group_update;

    integer i;

    update_sync dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .pwm_boundary (pwm_boundary),

        .shadow_duty  (shadow_duty),

        .global_update(global_update),
        .group_update (group_update),

        .active_duty  (active_duty),
        .update_done(update_done)
    );

    initial clk = 1'b0;
    always #5 clk <= ~clk;


    task automatic wait_clk;
        begin
            @(posedge clk);
        end
    endtask


    task automatic pulse_boundary;
        begin
            pwm_boundary = 1'b1;
            @(posedge clk);
            pwm_boundary = 1'b0;
        end
    endtask


    task automatic check_all_zero;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                if (active_duty[i] !== 12'h000) begin
                    $display(
                        "FAIL: CH%0d active=%03h expected=000",
                        i,
                        active_duty[i]
                    );
                    $fatal(1);
                end
            end
        end
    endtask


    initial begin

        rst_n        = 1'b0;
        pwm_boundary = 1'b0;

        global_update = 1'b0;
        group_update  = 4'b0000;

        for (i = 0; i < 16; i = i + 1)
            shadow_duty[i] = 12'h000;


        // ========================================================
        // RESET
        // ========================================================

        $display("TEST 1: reset");

        repeat (3) wait_clk();

        rst_n = 1'b1;

        wait_clk();

        check_all_zero();


        // ========================================================
        // GROUP 0
        // ========================================================

        $display("TEST 2: group 0 update");

        shadow_duty[0] = 12'h111;
        shadow_duty[1] = 12'h222;
        shadow_duty[2] = 12'h333;
        shadow_duty[3] = 12'h444;

        shadow_duty[4] = 12'h555;

        group_update = 4'b0001;

        // Before boundary nothing may change.
        wait_clk();

        if (active_duty[0] !== 12'h000 ||
            active_duty[4] !== 12'h000) begin

            $display("FAIL: active duty changed before PWM boundary");
            $fatal(1);

        end

        pulse_boundary();

        group_update = 4'b0000;

        if (active_duty[0] !== 12'h111 ||
            active_duty[1] !== 12'h222 ||
            active_duty[2] !== 12'h333 ||
            active_duty[3] !== 12'h444) begin

            $display("FAIL: group 0 update incorrect");
            $fatal(1);

        end

        if (active_duty[4] !== 12'h000) begin

            $display("FAIL: group 0 modified channel 4");
            $fatal(1);

        end


        // ========================================================
        // GROUP 2
        // ========================================================

        $display("TEST 3: group 2 update");

        shadow_duty[8]  = 12'h888;
        shadow_duty[9]  = 12'h999;
        shadow_duty[10] = 12'hAAA;
        shadow_duty[11] = 12'hBBB;

        group_update = 4'b0100;

        pulse_boundary();

        group_update = 4'b0000;

        if (active_duty[8]  !== 12'h888 ||
            active_duty[9]  !== 12'h999 ||
            active_duty[10] !== 12'hAAA ||
            active_duty[11] !== 12'hBBB) begin

            $display("FAIL: group 2 update incorrect");
            $fatal(1);

        end


        // ========================================================
        // GLOBAL
        // ========================================================

        $display("TEST 4: global update");

        shadow_duty[0]  = 12'h001;
        shadow_duty[5]  = 12'h005;
        shadow_duty[10] = 12'h00A;
        shadow_duty[15] = 12'h00F;

        global_update = 1'b1;

        pulse_boundary();

        global_update = 1'b0;

        if (active_duty[0]  !== 12'h001 ||
            active_duty[5]  !== 12'h005 ||
            active_duty[10] !== 12'h00A ||
            active_duty[15] !== 12'h00F) begin

            $display("FAIL: global update incorrect");
            $fatal(1);

        end


        // ========================================================
        // GLOBAL PRIORITY
        // ========================================================

        $display("TEST 5: global update priority");

        shadow_duty[0] = 12'hABC;
        shadow_duty[4] = 12'hDEF;

        global_update = 1'b1;
        group_update  = 4'b0001;

        pulse_boundary();

        global_update = 1'b0;
        group_update  = 4'b0000;

        if (active_duty[0] !== 12'hABC ||
            active_duty[4] !== 12'hDEF) begin

            $display("FAIL: global priority behavior incorrect");
            $fatal(1);

        end


        // ========================================================
        // FINAL
        // ========================================================

        $display("");
        $display("==============================================");
        $display("PASS: update_sync global/group synchronized updates");
        $display("==============================================");

        $finish;

    end

endmodule

