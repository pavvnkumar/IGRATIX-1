`timescale 1ns/1ps

module register_bank (
    input  logic        clk,
    input  logic        rst_n,

    // I2C write interface
    input  logic        write_en,
    input  logic [7:0]  write_addr,
    input  logic [31:0] write_data,

    // I2C read interface
    input  logic        read_req,
    input  logic [7:0]  read_addr,
    output logic [7:0]  read_data,

    // PWM configuration
    output logic [15:0] pwm_div,
    output logic [11:0] duty_shadow [0:15],

    // Control
    output logic        output_enable,

    // Synchronized update requests
    output logic        global_update,
    output logic [3:0]  group_update,

    // Software reset request
    output logic        software_reset_pulse
);

    integer i;

    // ============================================================
    // Readback
    //
    // Read data is combinational from the current register state.
    // I2C controls the timing of read_req/read_addr.
    // ============================================================

    always_comb begin

        read_data = 8'h00;

        case (read_addr)

            // ----------------------------------------------------
            // CONTROL
            // ----------------------------------------------------
            8'h00: begin
                read_data[0] = output_enable;
            end

            // ----------------------------------------------------
            // STATUS
            //
            // No status bits are currently defined.
            // Reserved bits read as zero.
            // ----------------------------------------------------
            8'h01: begin
                read_data = 8'h00;
            end

            // ----------------------------------------------------
            // PWM divider
            // ----------------------------------------------------
            8'h02: begin
                read_data = pwm_div[7:0];
            end

            8'h03: begin
                read_data = pwm_div[15:8];
            end

            // ----------------------------------------------------
            // UPDATE
            //
            // Update requests are pulses and therefore read as 0.
            // ----------------------------------------------------
            8'h04: begin
                read_data = 8'h00;
            end

            // ----------------------------------------------------
            // OE control
            // ----------------------------------------------------
            8'h05: begin
                read_data[0] = output_enable;
            end

            // ----------------------------------------------------
            // Software reset
            // ----------------------------------------------------
            8'h06: begin
                read_data = 8'h00;
            end

            // ----------------------------------------------------
            // Device ID
            //
            // Final ID value remains an integration decision.
            // Current deterministic implementation returns 0.
            // ----------------------------------------------------
            8'h07: begin
                read_data = 8'h00;
            end

            // ----------------------------------------------------
            // PWM channel registers
            //
            // CH0 = 10/11
            // CH1 = 12/13
            // ...
            // CH15 = 2E/2F
            //
            // Bits [11:0] contain duty.
            // Upper nibble is reserved and reads as zero.
            // ----------------------------------------------------
            8'h10: read_data = duty_shadow[0][7:0];
            8'h11: read_data = {4'h0, duty_shadow[0][11:8]};

            8'h12: read_data = duty_shadow[1][7:0];
            8'h13: read_data = {4'h0, duty_shadow[1][11:8]};

            8'h14: read_data = duty_shadow[2][7:0];
            8'h15: read_data = {4'h0, duty_shadow[2][11:8]};

            8'h16: read_data = duty_shadow[3][7:0];
            8'h17: read_data = {4'h0, duty_shadow[3][11:8]};

            8'h18: read_data = duty_shadow[4][7:0];
            8'h19: read_data = {4'h0, duty_shadow[4][11:8]};

            8'h1A: read_data = duty_shadow[5][7:0];
            8'h1B: read_data = {4'h0, duty_shadow[5][11:8]};

            8'h1C: read_data = duty_shadow[6][7:0];
            8'h1D: read_data = {4'h0, duty_shadow[6][11:8]};

            8'h1E: read_data = duty_shadow[7][7:0];
            8'h1F: read_data = {4'h0, duty_shadow[7][11:8]};

            8'h20: read_data = duty_shadow[8][7:0];
            8'h21: read_data = {4'h0, duty_shadow[8][11:8]};

            8'h22: read_data = duty_shadow[9][7:0];
            8'h23: read_data = {4'h0, duty_shadow[9][11:8]};

            8'h24: read_data = duty_shadow[10][7:0];
            8'h25: read_data = {4'h0, duty_shadow[10][11:8]};

            8'h26: read_data = duty_shadow[11][7:0];
            8'h27: read_data = {4'h0, duty_shadow[11][11:8]};

            8'h28: read_data = duty_shadow[12][7:0];
            8'h29: read_data = {4'h0, duty_shadow[12][11:8]};

            8'h2A: read_data = duty_shadow[13][7:0];
            8'h2B: read_data = {4'h0, duty_shadow[13][11:8]};

            8'h2C: read_data = duty_shadow[14][7:0];
            8'h2D: read_data = {4'h0, duty_shadow[14][11:8]};

            8'h2E: read_data = duty_shadow[15][7:0];
            8'h2F: read_data = {4'h0, duty_shadow[15][11:8]};

            default: begin
                read_data = 8'h00;
            end

        endcase
    end


    // ============================================================
    // Register write logic
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            pwm_div              <= 16'h0000;
            output_enable        <= 1'b0;

            global_update        <= 1'b0;
            group_update         <= 4'b0000;

            software_reset_pulse <= 1'b0;

            for (i = 0; i < 16; i = i + 1)
                duty_shadow[i] <= 12'h000;

        end

        else begin

            // ----------------------------------------------------
            // All request outputs are one-clock pulses.
            // ----------------------------------------------------

            global_update        <= 1'b0;
            group_update         <= 4'b0000;
            software_reset_pulse <= 1'b0;


            if (write_en) begin

                case (write_addr)

                    // =================================================
                    // CONTROL
                    //
                    // No control bits are currently defined.
                    // Reserved bits are ignored.
                    // =================================================

                    8'h00: begin
                        // Reserved until CONTROL bit definitions
                        // are explicitly frozen.
                    end


                    // =================================================
                    // STATUS
                    // =================================================

                    8'h01: begin
                        // Read-only.
                        // Writes are ignored.
                    end


                    // =================================================
                    // PWM DIVIDER
                    // =================================================

                    8'h02: begin
                        pwm_div[7:0] <= write_data[7:0];
                    end

                    8'h03: begin
                        pwm_div[15:8] <= write_data[7:0];
                    end


                    // =================================================
                    // UPDATE
                    //
                    // bit 0 = global
                    // bit 1 = group 0
                    // bit 2 = group 1
                    // bit 3 = group 2
                    // bit 4 = group 3
                    // =================================================

                    8'h04: begin

                        if (write_data[0])
                            global_update <= 1'b1;

                        group_update <= write_data[4:1];

                    end


                    // =================================================
                    // OE CONTROL
                    //
                    // bit 0 = output enable
                    // =================================================

                    8'h05: begin
                        output_enable <= write_data[0];
                    end


                    // =================================================
                    // SOFTWARE RESET
                    //
                    // A write with bit 0 set generates a pulse.
                    // =================================================

                    8'h06: begin

                        if (write_data[0])
                            software_reset_pulse <= 1'b1;

                    end


                    // =================================================
                    // DEVICE ID
                    //
                    // Read-only.
                    // =================================================

                    8'h07: begin
                        // Writes ignored.
                    end


                    // =================================================
                    // PWM SHADOW DUTY REGISTERS
                    //
                    // Low byte:
                    //   bits [7:0] = duty [7:0]
                    //
                    // High byte:
                    //   bits [3:0] = duty [11:8]
                    //   bits [7:4] = reserved
                    // =================================================

                    8'h10: duty_shadow[0][7:0]   <= write_data[7:0];
                    8'h11: duty_shadow[0][11:8]  <= write_data[3:0];

                    8'h12: duty_shadow[1][7:0]   <= write_data[7:0];
                    8'h13: duty_shadow[1][11:8]  <= write_data[3:0];

                    8'h14: duty_shadow[2][7:0]   <= write_data[7:0];
                    8'h15: duty_shadow[2][11:8]  <= write_data[3:0];

                    8'h16: duty_shadow[3][7:0]   <= write_data[7:0];
                    8'h17: duty_shadow[3][11:8]  <= write_data[3:0];

                    8'h18: duty_shadow[4][7:0]   <= write_data[7:0];
                    8'h19: duty_shadow[4][11:8]  <= write_data[3:0];

                    8'h1A: duty_shadow[5][7:0]   <= write_data[7:0];
                    8'h1B: duty_shadow[5][11:8]  <= write_data[3:0];

                    8'h1C: duty_shadow[6][7:0]   <= write_data[7:0];
                    8'h1D: duty_shadow[6][11:8]  <= write_data[3:0];

                    8'h1E: duty_shadow[7][7:0]   <= write_data[7:0];
                    8'h1F: duty_shadow[7][11:8]  <= write_data[3:0];

                    8'h20: duty_shadow[8][7:0]   <= write_data[7:0];
                    8'h21: duty_shadow[8][11:8]  <= write_data[3:0];

                    8'h22: duty_shadow[9][7:0]   <= write_data[7:0];
                    8'h23: duty_shadow[9][11:8]  <= write_data[3:0];

                    8'h24: duty_shadow[10][7:0]  <= write_data[7:0];
                    8'h25: duty_shadow[10][11:8] <= write_data[3:0];

                    8'h26: duty_shadow[11][7:0]  <= write_data[7:0];
                    8'h27: duty_shadow[11][11:8] <= write_data[3:0];

                    8'h28: duty_shadow[12][7:0]  <= write_data[7:0];
                    8'h29: duty_shadow[12][11:8] <= write_data[3:0];

                    8'h2A: duty_shadow[13][7:0]  <= write_data[7:0];
                    8'h2B: duty_shadow[13][11:8] <= write_data[3:0];

                    8'h2C: duty_shadow[14][7:0]  <= write_data[7:0];
                    8'h2D: duty_shadow[14][11:8] <= write_data[3:0];

                    8'h2E: duty_shadow[15][7:0]  <= write_data[7:0];
                    8'h2F: duty_shadow[15][11:8] <= write_data[3:0];


                    // =================================================
                    // Invalid / reserved address
                    // =================================================

                    default: begin
                        // Ignore.
                    end

                endcase
            end
        end
    end

endmodule

