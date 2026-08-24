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
    // Synchronize external I2C signals
    // ============================================================

    logic scl_meta;
    logic scl_sync;
    logic scl_prev;

    logic sda_meta;
    logic sda_sync;
    logic sda_prev;

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

    wire scl_rise = scl_sync && !scl_prev;
    wire scl_fall = !scl_sync && scl_prev;

    wire start_detect =
        scl_sync && sda_prev && !sda_sync;

    wire stop_detect =
        scl_sync && !sda_prev && sda_sync;


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

    logic [7:0] rx_shift;
    logic [7:0] tx_shift;

    logic [2:0] bit_count;

    logic       address_match;
    logic       rw_bit;

    logic [7:0] current_reg_addr;

    // Tracks the two falling edges surrounding the address ACK.
    //
    // First falling edge:
    //     end of address byte
    //
    // Second falling edge:
    //     end of ACK clock
    //
    logic       ack_phase;


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

            ack_phase        <= 1'b0;

            sda_drive_low    <= 1'b0;

            write_en         <= 1'b0;
            write_addr       <= 8'h00;
            write_data       <= 32'h00000000;

            read_addr        <= 8'h00;
            read_req         <= 1'b0;
        end

        else begin

            // Transaction pulses are one system-clock wide.
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

                ack_phase        <= 1'b0;

                sda_drive_low    <= 1'b0;
            end


            // ----------------------------------------------------
            // STOP
            // ----------------------------------------------------

            else if (stop_detect) begin

                state         <= ST_IDLE;

                bit_count     <= 3'd0;
                rx_shift      <= 8'h00;
                tx_shift      <= 8'h00;

                address_match <= 1'b0;
                rw_bit        <= 1'b0;

                ack_phase     <= 1'b0;

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
                    //
                    // byte[7:1] = slave address
                    // byte[0]   = R/W
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
                                    {rx_shift[6:0], sda_sync}[7:1]
                                    == DEVICE_ADDR
                                ) begin
                                    address_match <= 1'b1;
                                    rw_bit <=
                                        {rx_shift[6:0], sda_sync}[0];
                                end
                                else begin
                                    address_match <= 1'b0;
                                    rw_bit <= 1'b0;
                                end

                                bit_count <= 3'd0;

                                // Enter ACK phase.
                                // ACK must survive the falling edge
                                // terminating the address byte.
                                ack_phase <= 1'b0;

                                state <= ST_ADDRESS_ACK;
                            end
                            else begin
                                bit_count <= bit_count + 3'd1;
                            end
                        end
                    end


                    // =================================================
                    // ADDRESS ACK
                    //
                    // Valid address:
                    //     SDA LOW during ninth clock.
                    //
                    // Invalid address:
                    //     SDA released.
                    // =================================================

                    ST_ADDRESS_ACK: begin

                        if (address_match)
                            sda_drive_low <= 1'b1;
                        else
                            sda_drive_low <= 1'b0;

                        if (scl_fall) begin

                            if (!ack_phase) begin

                                // This falling edge belongs to the
                                // eighth address bit.
                                //
                                // Keep SDA asserted for the actual
                                // ninth ACK clock.
                                ack_phase <= 1'b1;

                            end
                            else begin

                                // This falling edge terminates the
                                // actual ACK clock.
                                sda_drive_low <= 1'b0;
                                ack_phase     <= 1'b0;

                                bit_count <= 3'd0;
                                rx_shift  <= 8'h00;

                                if (address_match) begin

                                    if (rw_bit) begin

                                        state <= ST_READ;

                                        read_addr <= current_reg_addr;
                                        read_req  <= 1'b1;

                                        tx_shift <= read_data;
                                    end
                                    else begin

                                        state <= ST_WRITE;
                                    end

                                end
                                else begin

                                    state <= ST_IDLE;
                                end
                            end
                        end
                    end


                    // =================================================
                    // WRITE DATA
                    // =================================================

                    ST_WRITE: begin

                        sda_drive_low <= 1'b0;

                        if (scl_rise) begin

                            rx_shift <= {
                                rx_shift[6:0],
                                sda_sync
                            };

                            if (bit_count == 3'd7) begin

                                bit_count <= 3'd0;
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

                        sda_drive_low <= 1'b1;

                        if (scl_fall) begin

                            sda_drive_low <= 1'b0;

                            // First byte after address is register
                            // address.
                            if (current_reg_addr == 8'h00) begin

                                current_reg_addr <= rx_shift;

                            end
                            else begin

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
                    // READ
                    // =================================================

                    ST_READ: begin

                        if (scl_fall) begin

                            if (tx_shift[7])
                                sda_drive_low <= 1'b0;
                            else
                                sda_drive_low <= 1'b1;

                            tx_shift <= {
                                tx_shift[6:0],
                                1'b0
                            };

                            if (bit_count == 3'd7) begin

                                bit_count <= 3'd0;
                                state <= ST_READ_ACK;

                            end
                            else begin

                                bit_count <= bit_count + 3'd1;
                            end
                        end
                    end


                    // =================================================
                    // MASTER ACK/NACK AFTER READ
                    // =================================================

                    ST_READ_ACK: begin

                        sda_drive_low <= 1'b0;

                        if (scl_rise) begin

                            if (!sda_sync) begin

                                current_reg_addr <=
                                    current_reg_addr + 8'd1;

                                read_addr <=
                                    current_reg_addr + 8'd1;

                                read_req <= 1'b1;

                                tx_shift <= read_data;

                                state <= ST_READ;
                            end
                            else begin

                                state <= ST_IDLE;
                            end

                            bit_count <= 3'd0;
                        end
                    end


                    // =================================================
                    // SAFETY DEFAULT
                    // =================================================

                    default: begin

                        state         <= ST_IDLE;

                        bit_count     <= 3'd0;
                        rx_shift      <= 8'h00;
                        tx_shift      <= 8'h00;

                        address_match <= 1'b0;
                        rw_bit        <= 1'b0;

                        ack_phase     <= 1'b0;

                        sda_drive_low <= 1'b0;
                    end

                endcase
            end
        end
    end

endmodule
