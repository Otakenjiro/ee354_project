`include "types.vh"

module move_rom (
    input  wire [4:0]  move_id,
    output reg  [31:0] move_data
);
    // move_id[31:27], type[26:22], power/effect_id[21:14], accuracy[13:7], pp_max[6:3], UNUSED[2:1] unused, is_status[0] is_status
    // id[4:0], type[4:0], power_or_fx[7:0], accuracy[6:0], pp[3:0], 2'b00, is_status[0]
    always @(*) begin
        case (move_id)

        // Attack moves (is_status = 0)
        5'd0: move_data = {5'd0, `TYPE_NORMAL,     8'd40,  7'd100, 4'd9,  2'b00, 1'b0}; // Tackle
        5'd1: move_data = {5'd1, `TYPE_FIRE,       8'd90,  7'd100, 4'd7,  2'b00, 1'b0}; // Flamethrower
        5'd2: move_data = {5'd2, `TYPE_FIRE,       8'd110, 7'd85,  4'd2,  2'b00, 1'b0}; // Fire Blast
        5'd3: move_data = {5'd3, `TYPE_NORMAL,     8'd70,  7'd100, 4'd10, 2'b00, 1'b0}; // Slash
        5'd4: move_data = {5'd4, `TYPE_GRASS,      8'd55,  7'd95,  4'd12, 2'b00, 1'b0}; // Razor Leaf
        5'd5: move_data = {5'd5, `TYPE_GRASS,      8'd120, 7'd100, 4'd5,  2'b00, 1'b0}; // Solar Beam
        5'd6: move_data = {5'd6, `TYPE_POISON,     8'd90,  7'd100, 4'd5,  2'b00, 1'b0}; // Sludge Bomb
        5'd7: move_data = {5'd7, `TYPE_WATER,      8'd90,  7'd100, 4'd7,  2'b00, 1'b0}; // Surf
        5'd8: move_data = {5'd8, `TYPE_WATER,      8'd110, 7'd80,  4'd2,  2'b00, 1'b0}; // Hydro Pump
        5'd9: move_data = {5'd9, `TYPE_ICE,        8'd90,  7'd100, 4'd5,  2'b00, 1'b0}; // Ice Beam
        5'd10: move_data = {5'd10, `TYPE_GROUND,   8'd100, 7'd100, 4'd5,  2'b00, 1'b0}; // Earthquake
        5'd11: move_data = {5'd11, `TYPE_POISON,   8'd80,  7'd100, 4'd10, 2'b00, 1'b0}; // Poison Jab
        5'd12: move_data = {5'd12, `TYPE_BUG,      8'd120, 7'd85,  4'd5,  2'b00, 1'b0}; // Megahorn
        5'd13: move_data = {5'd13, `TYPE_GHOST,    8'd80,  7'd100, 4'd7,  2'b00, 1'b0}; // Shadow Ball
        5'd14: move_data = {5'd14, `TYPE_PSYCHIC,  8'd100, 7'd100, 4'd7,  2'b00, 1'b0}; // Dream Eater
        5'd15: move_data = {5'd15, `TYPE_ELECTRIC, 8'd90,  7'd100, 4'd7,  2'b00, 1'b0}; // Thunderbolt
        5'd16: move_data = {5'd16, `TYPE_ELECTRIC, 8'd110, 7'd70,  4'd5,  2'b00, 1'b0}; // Thunder
        5'd17: move_data = {5'd17, `TYPE_NORMAL,   8'd40,  7'd100, 4'd15, 2'b00, 1'b0}; // Quick Attack
        5'd18: move_data = {5'd18, `TYPE_FLYING,   8'd60,  7'd100, 4'd15, 2'b00, 1'b0}; // Wing Attack
        5'd19: move_data = {5'd19, `TYPE_FLYING,   8'd80,  7'd100, 4'd10, 2'b00, 1'b0}; // Drill Peck
        5'd20: move_data = {5'd20, `TYPE_ICE,      8'd110, 7'd70,  4'd2,  2'b00, 1'b0}; // Blizzard

        // Status moves (is_status = 1, power field = effect_id)
        5'd21: move_data = {5'd21, `TYPE_NORMAL,   `FX_LOWER_ACC,   7'd100, 4'd10, 2'b00, 1'b1}; // Smokescreen
        5'd22: move_data = {5'd22, `TYPE_GRASS,    `FX_SLEEP,       7'd75,  4'd7,  2'b00, 1'b1}; // Sleep Powder
        5'd23: move_data = {5'd23, `TYPE_WATER,    `FX_RAISE_DEF,   7'd100, 4'd10, 2'b00, 1'b1}; // Withdraw
        5'd24: move_data = {5'd24, `TYPE_NORMAL,   `FX_LOWER_SPD,   7'd100, 4'd5,  2'b00, 1'b1}; // Scary Face
        5'd25: move_data = {5'd25, `TYPE_PSYCHIC,  `FX_SLEEP,       7'd60,  4'd10, 2'b00, 1'b1}; // Hypnosis
        5'd26: move_data = {5'd26, `TYPE_ELECTRIC, `FX_PARALYZE,    7'd90,  4'd10, 2'b00, 1'b1}; // Thunder Wave
        5'd27: move_data = {5'd27, `TYPE_PSYCHIC,  `FX_RAISE_SPD,   7'd100, 4'd15, 2'b00, 1'b1}; // Agility
        5'd28: move_data = {5'd28, `TYPE_ICE,      `FX_BLOCK_DROPS, 7'd100, 4'd15, 2'b00, 1'b1}; // Mist

        default: move_data = 32'd0;
        endcase
    end
endmodule