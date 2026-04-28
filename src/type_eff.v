`timescale 1ns / 1ps

module type_eff (
    input wire [3:0] atk_type,
    input wire [3:0] def_type,
    output reg [1:0] eff
);

    localparam NORMAL   = 4'd0,  FIRE     = 4'd1,  WATER  = 4'd2,
               GRASS    = 4'd3,  ELECTRIC = 4'd4,  ICE    = 4'd5,
               POISON   = 4'd6,  GROUND   = 4'd7,  FLYING = 4'd8,
               NONE     = 4'd15;

    always @(*) begin
        eff = 2'd2;
        if (def_type == NONE) begin
            eff = 2'd2;
        end else begin
            case ({atk_type, def_type})
                {FIRE, FIRE}:       eff = 2'd1;
                {FIRE, WATER}:      eff = 2'd1;
                {FIRE, GRASS}:      eff = 2'd3;
                {FIRE, ICE}:        eff = 2'd3;
                {WATER, FIRE}:      eff = 2'd3;
                {WATER, WATER}:     eff = 2'd1;
                {WATER, GRASS}:     eff = 2'd1;
                {ELECTRIC, WATER}:  eff = 2'd3;
                {ELECTRIC, ELECTRIC}: eff = 2'd1;
                {ELECTRIC, GRASS}:  eff = 2'd1;
                {ELECTRIC, FLYING}: eff = 2'd3;
                {GRASS, FIRE}:      eff = 2'd1;
                {GRASS, WATER}:     eff = 2'd3;
                {GRASS, GRASS}:     eff = 2'd1;
                {GRASS, POISON}:    eff = 2'd1;
                {GRASS, GROUND}:    eff = 2'd3;
                {GRASS, FLYING}:    eff = 2'd1;
                {ICE, WATER}:       eff = 2'd1;
                {ICE, GRASS}:       eff = 2'd3;
                {ICE, ICE}:         eff = 2'd1;
                {ICE, FLYING}:      eff = 2'd3;
                {POISON, GRASS}:    eff = 2'd3;
                {POISON, POISON}:   eff = 2'd1;
                {FLYING, ELECTRIC}: eff = 2'd1;
                {FLYING, GRASS}:    eff = 2'd3;

                default:            eff = 2'd2;
            endcase
        end
    end
endmodule
