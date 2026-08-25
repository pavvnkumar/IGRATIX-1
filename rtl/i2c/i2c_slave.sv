`timescale 1ns/1ps

module i2c_slave #(
    parameter logic [6:0] DEVICE_ADDR = 7'h40
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        scl,
    input  logic        sda,

    output logic        sda_drive_low,

    output logic        write_en,
    output logic [7:0]  write_addr,
    output logic [31:0] write_data,

    input  logic [7:0]  read_data,
    output logic [7:0]  read_addr,
    output logic        read_req
);

    // ============================================================
    // Synchronizers
    // ============================================================

    logic scl_meta;
    logic scl_sync;
    logic scl_prev;

    logic sda_meta;
    logic sda_sync;
    logic sda_prev;

    wire scl_rise = scl_sync && !scl_prev;
    wire scl_fall = !scl_sync && scl_prev;

    wire start_detect =
        scl_sync && sda_prev && !sda_sync;

    wire stop_detect =
        scl_sync && !sda_prev && sda_sync;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_meta <= 1'b1;
            scl_sync <= 1'b1;
            scl_prev <= 1'b1;

            sda_meta <= 1'b1;
            sda_sync <= 1'b1;
            sda_prev <= 1'b1;
        end
        else begin
            scl_meta <= scl;
            scl_sync <= scl_meta;
            scl_prev <= scl_sync;

            sda_meta <= sda;
            sda_sync <= sda_meta;
            sda_prev <= sda_sync;
        end
    end


    // ============================================================
    // State machine
    // ============================================================

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_ADDRESS,
        ST_ADDRESS_ACK,
        ST_WRITE,
        ST_WRITE_ACK,
        ST_READ,
        ST_READ_ACK
    } state_t;

    state_t state;


    // ============================================================
    // Data registers
    // ============================================================

    logic [7:0] rx_shift;
    logic [7:0] tx_shift;

    logic [2:0] bit_count;

    logic       address_match;
    logic       rw_bit;

    logic [7:0] current_reg_addr;
    logic [7:0] rx_byte;

    assign rx_byte = {rx_shift[6:0], sda_sync};


    // ============================================================
    // ACK phase tracking
    //
    // After receiving byte 8:
    //
    //   SCL FALL -> enter ACK
    //   SCL HIGH -> master samples ACK
    //   SCL FALL -> ACK complete
    //
    // ============================================================

    logic ack_low_seen;
    logic ack_high_seen;


    // ============================================================
    // Main controller
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state            <= ST_IDLE;

            rx_shift         <= 8'h00;
            tx_shift         <= 8'h00;

            bit_count        <= 3'd0;

            address_match    <= 1'b0;
            rw_bit           <= 1'b0;

            current_reg_addr <= 8'h00;

            ack_low_seen     <= 1'b0;
            ack_high_seen    <= 1'b0;

            sda_drive_low    <= 1'b0;

            write_en         <= 1'b0;
            write_addr       <= 8'h00;
            write_data       <= 32'h00000000;

            read_addr        <= 8'h00;
            read_req         <= 1'b0;
        end

        else begin

            // ----------------------------------------------------
            // One-clock event pulses.
            // ----------------------------------------------------

            write_en <= 1'b0;
            read_req <= 1'b0;


            // ----------------------------------------------------
            // START / repeated START
            // ----------------------------------------------------

            if (start_detect) begin

                state            <= ST_ADDRESS;

                rx_shift         <= 8'h00;
                tx_shift         <= 8'h00;

                bit_count        <= 3'd0;

                address_match    <= 1'b0;
                rw_bit           <= 1'b0;

                current_reg_addr <= 8'h00;

                ack_low_seen     <= 1'b0;
                ack_high_seen    <= 1'b0;

                sda_drive_low    <= 1'b0;
            end


            // ----------------------------------------------------
            // STOP
            // ----------------------------------------------------

            else if (stop_detect) begin

                state         <= ST_IDLE;

                rx_shift      <= 8'h00;
                tx_shift      <= 8'h00;

                bit_count     <= 3'd0;

                address_match <= 1'b0;
                rw_bit        <= 1'b0;

                ack_low_seen  <= 1'b0;
                ack_high_seen <= 1'b0;

                sda_drive_low <= 1'b0;
            end


            else begin

                case (state)

                    // =================================================
                    // IDLE
                    // =================================================

                    ST_IDLE: begin

                        sda_drive_low <= 1'b0;
                        bit_count     <= 3'd0;

                    end


                    // =================================================
                    // ADDRESS RECEIVE
                    // =================================================

                    ST_ADDRESS: begin

                        sda_drive_low <= 1'b0;

                        if (scl_rise) begin

                            rx_shift <= {
                                rx_shift[6:0],
                                sda_sync
                            };

                            if (bit_count == 3'd7) begin

                                if (
                                    rx_byte[7:1]
                                    == DEVICE_ADDR
                                ) begin

                                    address_match <= 1'b1;

                                    rw_bit <=
                                        rx_byte[0];

                                end
                                else begin

                                    address_match <= 1'b0;
                                    rw_bit        <= 1'b0;

                                end

                                bit_count     <= 3'd0;
                                ack_low_seen  <= 1'b0;
                                ack_high_seen <= 1'b0;

                                state <= ST_ADDRESS_ACK;

                            end
                            else begin

                                bit_count <= bit_count + 3'd1;

                            end
                        end
                    end


                    // =================================================
                    // ADDRESS ACK
                    // =================================================

                    ST_ADDRESS_ACK: begin

                        // Valid address -> ACK.
                        if (address_match)
                            sda_drive_low <= 1'b1;
                        else
                            sda_drive_low <= 1'b0;


                        // First falling edge enters ACK phase.
                        if (scl_fall && !ack_low_seen) begin

                            ack_low_seen  <= 1'b1;
                            ack_high_seen <= 1'b0;

                        end


                        // ACK sampled while SCL is HIGH.
                        if (scl_rise && ack_low_seen) begin

                            ack_high_seen <= 1'b1;

                        end


                        // Final falling edge completes ACK.
                        if (
                            scl_fall &&
                            ack_low_seen &&
                            ack_high_seen
                        ) begin

                            ack_low_seen  <= 1'b0;
                            ack_high_seen <= 1'b0;

                            bit_count <= 3'd0;
                            rx_shift  <= 8'h00;


                            if (address_match) begin

                                if (rw_bit) begin

                                    // --------------------------------
                                    // Valid READ address.
                                    //
                                    // Generate read request and load
                                    // transmit shift register.
                                    //
                                    // IMPORTANT:
                                    // The first data bit is driven NOW,
                                    // during the low phase immediately
                                    // following the address ACK.
                                    // --------------------------------

                                    read_addr <= current_reg_addr;
                                    read_req  <= 1'b1;

                                    tx_shift <= {
                                        read_data[6:0],
                                        1'b0
                                    };

                                    // First transmitted bit is bit 7.
                                    if (read_data[7])
                                        sda_drive_low <= 1'b0;
                                    else
                                        sda_drive_low <= 1'b1;

                                    state <= ST_READ;

                                end
                                else begin

                                    // Valid WRITE address.
                                    sda_drive_low <= 1'b0;

                                    state <= ST_WRITE;

                                end

                            end
                            else begin

                                sda_drive_low <= 1'b0;

                                state <= ST_IDLE;

                            end
                        end
                    end


                    // =================================================
                    // WRITE RECEIVE
                    // =================================================

                    ST_WRITE: begin

                        sda_drive_low <= 1'b0;

                        if (scl_rise) begin

                            rx_shift <= {
                                rx_shift[6:0],
                                sda_sync
                            };

                            if (bit_count == 3'd7) begin

                                bit_count     <= 3'd0;

                                ack_low_seen  <= 1'b0;
                                ack_high_seen <= 1'b0;

                                state <= ST_WRITE_ACK;

                            end
                            else begin

                                bit_count <= bit_count + 3'd1;

                            end
                        end
                    end


                    // =================================================
                    // WRITE ACK
                    // =================================================

                    ST_WRITE_ACK: begin

                        // Always ACK received write bytes.
                        sda_drive_low <= 1'b1;


                        // First falling edge enters ACK phase.
                        if (scl_fall && !ack_low_seen) begin

                            ack_low_seen  <= 1'b1;
                            ack_high_seen <= 1'b0;

                        end


                        // Master samples ACK.
                        if (scl_rise && ack_low_seen) begin

                            ack_high_seen <= 1'b1;

                        end


                        // ACK complete.
                        if (
                            scl_fall &&
                            ack_low_seen &&
                            ack_high_seen
                        ) begin

                            sda_drive_low <= 1'b0;

                            ack_low_seen  <= 1'b0;
                            ack_high_seen <= 1'b0;


                            if (current_reg_addr == 8'h00) begin

                                // First byte = register address.
                                current_reg_addr <= rx_shift;

                            end
                            else begin

                                // Following bytes = register data.
                                write_en   <= 1'b1;
                                write_addr <= current_reg_addr;

                                write_data <= {
                                    24'h000000,
                                    rx_shift
                                };

                                current_reg_addr <=
                                    current_reg_addr + 8'd1;

                            end


                            rx_shift  <= 8'h00;
                            bit_count <= 3'd0;

                            state <= ST_WRITE;

                        end
                    end


                    // =================================================
                    // READ DATA TRANSMIT
                    //
                    // SDA is changed only while SCL is LOW.
                    //
                    // At entry from ADDRESS_ACK, bit 7 has already
                    // been placed on SDA.
                    //
                    // Each subsequent SCL falling edge advances to
                    // the next data bit.
                    // =================================================

                    ST_READ: begin

                        if (scl_fall) begin

                            // Drive current MSB.
                            if (tx_shift[7])
                                sda_drive_low <= 1'b0;
                            else
                                sda_drive_low <= 1'b1;


                            // Advance to next bit.
                            tx_shift <= {
                                tx_shift[6:0],
                                1'b0
                            };


                            if (bit_count == 3'd7) begin

                                bit_count <= 3'd0;

                                // After the eighth data bit,
                                // release SDA for master ACK/NACK.
                                state <= ST_READ_ACK;

                            end
                            else begin

                                bit_count <= bit_count + 3'd1;

                            end
                        end
                    end


                    // =================================================
                    // MASTER ACK/NACK AFTER READ BYTE
                    // =================================================

                    ST_READ_ACK: begin

                        // Slave releases SDA so master can ACK/NACK.
                        sda_drive_low <= 1'b0;

                        if (scl_rise) begin

                            if (!sda_sync) begin

                                // Master ACK -> request next byte.
                                current_reg_addr <=
                                    current_reg_addr + 8'd1;

                                read_addr <=
                                    current_reg_addr + 8'd1;

                                read_req <= 1'b1;

                                tx_shift <= {
                                    read_data[6:0],
                                    1'b0
                                };

                                // Prepare first bit of next byte
                                // immediately after ACK.
                                if (read_data[7])
                                    sda_drive_low <= 1'b0;
                                else
                                    sda_drive_low <= 1'b1;

                                state <= ST_READ;

                            end
                            else begin

                                // Master NACK -> terminate read.
                                state <= ST_IDLE;

                                sda_drive_low <= 1'b0;

                            end

                            bit_count <= 3'd0;

                        end
                    end


                    // =================================================
                    // SAFETY
                    // =================================================

                    default: begin

                        state         <= ST_IDLE;

                        rx_shift      <= 8'h00;
                        tx_shift      <= 8'h00;

                        bit_count     <= 3'd0;

                        address_match <= 1'b0;
                        rw_bit        <= 1'b0;

                        ack_low_seen  <= 1'b0;
                        ack_high_seen <= 1'b0;

                        sda_drive_low <= 1'b0;

                    end

                endcase
            end
        end
    end

endmodule

