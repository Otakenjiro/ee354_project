`timescale 1ns / 1ps

module pokemon_stat_rom (
    input wire [2:0] pokemon_id, // 1-6
    output reg [9:0] max_hp,
    output reg [8:0] atk,
    output reg [8:0] def_stat,
    output reg [8:0] spd,
    output reg [3:0] type1,
    output reg [3:0] type2,
    output reg [4:0] move0,
    output reg [4:0] move1,
    output reg [4:0] move2,
    output reg [4:0] move3
);
    // Level 50 stat formulas:
    //   HP  = base_hp  + 60
    //   ATK = base_atk + 5
    //   DEF = base_def + 5
    //   SPD = base_spd + 5

    // DEFENSE TYPES: fire, flying, grass, poison, water, electric, ice

    localparam FIRE = 4'd1, WATER = 4'd2, GRASS = 4'd3, ELECTRIC = 4'd4,
               ICE = 4'd5, POISON = 4'd6, GROUND = 4'd7, FLYING = 4'd8,
               PSYCHIC = 4'd9, GHOST = 4'd10, TNONE = 4'd15;

    always @(*) begin
        case (pokemon_id)
            3'd1: begin // Charizard
                max_hp = 10'd138; atk = 9'd89; def_stat = 9'd83; spd = 9'd105;
                type1 = FIRE; type2 = FLYING;
                move0 = 5'd1; move1 = 5'd2; move2 = 5'd3; move3 = 5'd21;
            end
            3'd2: begin // Venusaur
                max_hp = 10'd140; atk = 9'd87; def_stat = 9'd88; spd = 9'd85;
                type1 = GRASS; type2 = POISON;
                move0 = 5'd4; move1 = 5'd5; move2 = 5'd6; move3 = 5'd22;
            end
            3'd3: begin // Blastoise
                max_hp = 10'd139; atk = 9'd88; def_stat = 9'd105; spd = 9'd83;
                type1 = WATER; type2 = TNONE;
                move0 = 5'd7; move1 = 5'd8; move2 = 5'd9; move3 = 5'd23;
            end
            3'd4: begin // Moltres
                max_hp = 10'd150; atk = 9'd105; def_stat = 9'd95; spd = 9'd95;
                type1 = FIRE; type2 = FLYING;
                move0 = 5'd2; move1 = 5'd1; move2 = 5'd18; move3 = 5'd27;
            end
            3'd5: begin // Zapdos
                max_hp = 10'd150; atk = 9'd95; def_stat = 9'd90; spd = 9'd105;
                type1 = ELECTRIC; type2 = FLYING;
                move0 = 5'd15; move1 = 5'd16; move2 = 5'd19; move3 = 5'd26;
            end
            3'd6: begin // Articuno
                max_hp = 10'd150; atk = 9'd90; def_stat = 9'd105; spd = 9'd90;
                type1 = ICE; type2 = FLYING;
                move0 = 5'd9; move1 = 5'd20; move2 = 5'd18; move3 = 5'd28;
            end
            default: begin
                max_hp = 10'd100; atk = 9'd50; def_stat = 9'd50; spd = 9'd50; // generic stats
                type1 = 4'd0; type2 = TNONE; // default init: empty type and NONE
                move0 = 5'd0; move1 = 5'd0; move2 = 5'd0; move3 = 5'd0; // init moveset
            end
        endcase
    end
endmodule
