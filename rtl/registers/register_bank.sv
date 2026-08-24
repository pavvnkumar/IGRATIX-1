`timescale 1ns/1ps

module register_bank (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        write_en,
    input  logic [7:0]  write_addr,
    input  logic [31:0] write_data,

    output logic [15:0] pwm_div,
    output logic [11:0] duty_shadow [0:15],
    output logic        output_enable,

    output logic        update_pulse,
    output logic        software_reset_pulse
);

    integer i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_div              <= 16'h0000;
            output_enable        <= 1'b0;
            update_pulse         <= 1'b0;
            software_reset_pulse <= 1'b0;

            for (i = 0; i < 16; i = i + 1)
                duty_shadow[i] <= 12'h000;
        end
        else begin
            // Pulses are one clock wide.
            update_pulse         <= 1'b0;
            software_reset_pulse <= 1'b0;

            if (write_en) begin
                case (write_addr)

                    8'h00: begin
                        output_enable <= write_data[0];

                        if (write_data[1])
                            update_pulse <= 1'b1;

                        if (write_data[2])
                            software_reset_pulse <= 1'b1;
                    end

                    8'h04: begin
                        pwm_div <= write_data[15:0];
                    end

                    8'h10: duty_shadow[0]  <= write_data[11:0];
                    8'h14: duty_shadow[1]  <= write_data[11:0];
                    8'h18: duty_shadow[2]  <= write_data[11:0];
                    8'h1C: duty_shadow[3]  <= write_data[11:0];
                    8'h20: duty_shadow[4]  <= write_data[11:0];
                    8'h24: duty_shadow[5]  <= write_data[11:0];
                    8'h28: duty_shadow[6]  <= write_data[11:0];
                    8'h2C: duty_shadow[7]  <= write_data[11:0];
                    8'h30: duty_shadow[8]  <= write_data[11:0];
                    8'h34: duty_shadow[9]  <= write_data[11:0];
                    8'h38: duty_shadow[10] <= write_data[11:0];
                    8'h3C: duty_shadow[11] <= write_data[11:0];
                    8'h40: duty_shadow[12] <= write_data[11:0];
                    8'h44: duty_shadow[13] <= write_data[11:0];
                    8'h48: duty_shadow[14] <= write_data[11:0];
                    8'h4C: duty_shadow[15] <= write_data[11:0];

                    default: begin
                        // Ignore invalid addresses.
                    end

                endcase
            end
        end
    end

endmodule
