`timescale 1ns / 1ps

module type_eff (
    input wire [4:0] atk_type,
    input wire [4:0] def_type,
    output reg [1:0] eff // 0=immune, 1=resist(0.5x), 2=neutral(1x), 3=super(2x)
);

    localparam NORMAL   = 5'd0,  FIRE     = 5'd1,  WATER  = 5'd2,
               GRASS    = 5'd3,  ELECTRIC = 5'd4,  ICE    = 5'd5,
               FIGHTING = 5'd6,  POISON   = 5'd7,  GROUND = 5'd8,
               FLYING   = 5'd9,  PSYCHIC  = 5'd10, BUG    = 5'd11,
               ROCK     = 5'd12, GHOST    = 5'd13, DRAGON = 5'd14,
               NONE     = 5'd31;

    always @(*) begin
        eff = 2'd2;
        if (def_type == NONE) begin
            eff = 2'd2;
        end else begin
            case ({atk_type, def_type})
                // NORMAL attacks
                {NORMAL, ROCK}:     eff = 2'd1;
                {NORMAL, GHOST}:    eff = 2'd0;
                // FIRE attacks
                {FIRE, FIRE}:       eff = 2'd1;
                {FIRE, WATER}:      eff = 2'd1;
                {FIRE, GRASS}:      eff = 2'd3;
                {FIRE, ICE}:        eff = 2'd3;
                {FIRE, BUG}:        eff = 2'd3;
                {FIRE, ROCK}:       eff = 2'd1;
                {FIRE, DRAGON}:     eff = 2'd1;
                // WATER attacks
                {WATER, FIRE}:      eff = 2'd3;
                {WATER, WATER}:     eff = 2'd1;
                {WATER, GRASS}:     eff = 2'd1;
                {WATER, GROUND}:    eff = 2'd3;
                {WATER, ROCK}:      eff = 2'd3;
                {WATER, DRAGON}:    eff = 2'd1;
                // ELECTRIC attacks
                {ELECTRIC, WATER}:  eff = 2'd3;
                {ELECTRIC, ELECTRIC}: eff = 2'd1;
                {ELECTRIC, GRASS}:  eff = 2'd1;
                {ELECTRIC, GROUND}: eff = 2'd0;
                {ELECTRIC, FLYING}: eff = 2'd3;
                {ELECTRIC, DRAGON}: eff = 2'd1;
                // GRASS attacks
                {GRASS, FIRE}:      eff = 2'd1;
                {GRASS, WATER}:     eff = 2'd3;
                {GRASS, GRASS}:     eff = 2'd1;
                {GRASS, POISON}:    eff = 2'd1;
                {GRASS, GROUND}:    eff = 2'd3;
                {GRASS, FLYING}:    eff = 2'd1;
                {GRASS, BUG}:       eff = 2'd1;
                {GRASS, ROCK}:      eff = 2'd3;
                {GRASS, DRAGON}:    eff = 2'd1;
                // ICE attacks
                {ICE, WATER}:       eff = 2'd1;
                {ICE, GRASS}:       eff = 2'd3;
                {ICE, ICE}:         eff = 2'd1;
                {ICE, GROUND}:      eff = 2'd3;
                {ICE, FLYING}:      eff = 2'd3;
                {ICE, DRAGON}:      eff = 2'd3;
                // FIGHTING attacks
                {FIGHTING, NORMAL}: eff = 2'd3;
                {FIGHTING, ICE}:    eff = 2'd3;
                {FIGHTING, POISON}: eff = 2'd1;
                {FIGHTING, FLYING}: eff = 2'd1;
                {FIGHTING, PSYCHIC}: eff = 2'd1;
                {FIGHTING, BUG}:    eff = 2'd1;
                {FIGHTING, ROCK}:   eff = 2'd3;
                {FIGHTING, GHOST}:  eff = 2'd0;
                // POISON attacks
                {POISON, GRASS}:    eff = 2'd3;
                {POISON, POISON}:   eff = 2'd1;
                {POISON, GROUND}:   eff = 2'd1;
                {POISON, ROCK}:     eff = 2'd1;
                {POISON, GHOST}:    eff = 2'd1;
                // GROUND attacks
                {GROUND, FIRE}:     eff = 2'd3;
                {GROUND, ELECTRIC}: eff = 2'd3;
                {GROUND, GRASS}:    eff = 2'd1;
                {GROUND, POISON}:   eff = 2'd3;
                {GROUND, FLYING}:   eff = 2'd0;
                {GROUND, BUG}:      eff = 2'd1;
                {GROUND, ROCK}:     eff = 2'd3;
                // FLYING attacks
                {FLYING, ELECTRIC}: eff = 2'd1;
                {FLYING, GRASS}:    eff = 2'd3;
                {FLYING, FIGHTING}: eff = 2'd3;
                {FLYING, BUG}:      eff = 2'd3;
                {FLYING, ROCK}:     eff = 2'd1;
                // PSYCHIC attacks
                {PSYCHIC, FIGHTING}: eff = 2'd3;
                {PSYCHIC, POISON}:  eff = 2'd3;
                {PSYCHIC, PSYCHIC}: eff = 2'd1;
                // BUG attacks (Gen 1)
                {BUG, FIRE}:        eff = 2'd1;
                {BUG, GRASS}:       eff = 2'd3;
                {BUG, FIGHTING}:    eff = 2'd1;
                {BUG, POISON}:      eff = 2'd3;
                {BUG, FLYING}:      eff = 2'd1;
                {BUG, PSYCHIC}:     eff = 2'd3;
                {BUG, GHOST}:       eff = 2'd1;
                // GHOST attacks (Gen 1: Ghost doesn't affect Psychic)
                {GHOST, NORMAL}:    eff = 2'd0;
                {GHOST, GHOST}:     eff = 2'd3;
                {GHOST, PSYCHIC}:   eff = 2'd0;
                // DRAGON attacks
                {DRAGON, DRAGON}:   eff = 2'd3;
                default:            eff = 2'd2;
            endcase
        end
    end
endmodule
