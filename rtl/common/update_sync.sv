`timescale 1ns/1ps

module update_sync (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        pwm_boundary,

    input  logic [11:0] shadow_duty [0:15],

    input  logic        global_update,
    input  logic [3:0]  group_update,

    output logic [11:0] active_duty [0:15],

    output logic update_done
);


    integer i;


    logic pending_global;
    logic [3:0] pending_group;


    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            pending_global <= 1'b0;
            pending_group  <= 4'b0000;

            update_done <= 1'b0;

            for(i=0;i<16;i=i+1)
                active_duty[i] <= 12'h000;

        end


        else begin


            update_done <= 1'b0;


            // Capture software request
            if(global_update)
                pending_global <= 1'b1;


            if(|group_update)
                pending_group <= pending_group | group_update;



            // Apply only at PWM boundary
            if(pwm_boundary) begin


                if(pending_global) begin

                    for(i=0;i<16;i=i+1)
                        active_duty[i] <= shadow_duty[i];

                end


                else begin


                    if(pending_group[0])
                        for(i=0;i<4;i=i+1)
                            active_duty[i] <= shadow_duty[i];


                    if(pending_group[1])
                        for(i=4;i<8;i=i+1)
                            active_duty[i] <= shadow_duty[i];


                    if(pending_group[2])
                        for(i=8;i<12;i=i+1)
                            active_duty[i] <= shadow_duty[i];


                    if(pending_group[3])
                        for(i=12;i<16;i=i+1)
                            active_duty[i] <= shadow_duty[i];

                end


                pending_global <= 1'b0;
                pending_group  <= 4'b0000;

                update_done <= 1'b1;


            end

        end

    end


endmodule
