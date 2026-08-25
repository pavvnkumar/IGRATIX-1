`timescale 1ns/1ps

module pwm16_top (

    input  logic        clk,
    input  logic        rst_n,

    // I2C pins
    input  logic        scl,
    inout  wire         sda,

    // Open drain slave drive
    output logic        sda_drive_low,

    // PWM outputs
    output logic [15:0] pwm_out

);


    // ============================================================
    // I2C <-> REGISTER BANK
    // ============================================================

    logic        write_en;
    logic [7:0]  write_addr;
    logic [31:0] write_data;

    logic        read_req;
    logic [7:0]  read_addr;
    logic [7:0]  read_data;


    // ============================================================
    // REGISTER BANK
    // ============================================================

    logic [15:0] pwm_div;

    logic [15:0][11:0] duty_shadow;

    logic        output_enable;

    logic        global_update;
    logic [3:0]  group_update;

    logic        software_reset_pulse;



    // ============================================================
    // UPDATE SYNC
    // ============================================================

    logic [15:0][11:0] active_duty;

    logic        pwm_boundary;
    logic update_done;



    // ============================================================
    // I2C SLAVE
    // ============================================================

    i2c_slave #(
        .DEVICE_ADDR(7'h40)
    ) u_i2c_slave (

        .clk           (clk),
        .rst_n         (rst_n),

        .scl           (scl),
        .sda           (sda),

        .sda_drive_low (sda_drive_low),

        .write_en      (write_en),
        .write_addr    (write_addr),
        .write_data    (write_data),

        .read_data     (read_data),
        .read_addr     (read_addr),
        .read_req      (read_req)

    );



    // ============================================================
    // REGISTER BANK
    // ============================================================

    register_bank u_register_bank (

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



    // ============================================================
    // SHADOW -> ACTIVE UPDATE ENGINE
    // ============================================================

    update_sync u_update_sync (

    .clk           (clk),
    .rst_n         (rst_n),

    .pwm_boundary  (pwm_boundary),

    .shadow_duty   (duty_shadow),

    .global_update (global_update),
    .group_update  (group_update),

    .active_duty   (active_duty),

    .update_done   (update_done)

    );



    // ============================================================
    // PWM ENGINE
    // ============================================================

    pwm_controller u_pwm_controller (

        .clk           (clk),
        .rst_n         (rst_n),

        .pwm_div       (pwm_div),

        .active_duty   (active_duty),

        .output_enable (output_enable),

        .pwm_out       (pwm_out),

        .pwm_boundary  (pwm_boundary)

    );


endmodule
