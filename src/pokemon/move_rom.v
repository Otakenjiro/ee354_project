`include "types.vh"

module move_rom (
    input  wire [4:0]  move_id,
    output reg  [13:0] move_data
);
    // Encoding: {type[13:9], power[8:1], is_status[0]}
    // Status moves have power = 0, is_status = 1
    always @(*) begin
        case (move_id)

        // Attack moves (is_status = 0)
        5'd1:  move_data = {`TYPE_FIRE,     8'd90,  1'b0}; // Flamethrower
        5'd2:  move_data = {`TYPE_FIRE,     8'd110, 1'b0}; // Fire Blast
        5'd3:  move_data = {`TYPE_NORMAL,   8'd70,  1'b0}; // Slash
        5'd4:  move_data = {`TYPE_GRASS,    8'd55,  1'b0}; // Razor Leaf
        5'd5:  move_data = {`TYPE_GRASS,    8'd120, 1'b0}; // Solar Beam
        5'd6:  move_data = {`TYPE_POISON,   8'd90,  1'b0}; // Sludge Bomb
        5'd7:  move_data = {`TYPE_WATER,    8'd90,  1'b0}; // Surf
        5'd8:  move_data = {`TYPE_WATER,    8'd110, 1'b0}; // Hydro Pump
        5'd9:  move_data = {`TYPE_ICE,      8'd90,  1'b0}; // Ice Beam
        5'd15: move_data = {`TYPE_ELECTRIC, 8'd90,  1'b0}; // Thunderbolt
        5'd16: move_data = {`TYPE_ELECTRIC, 8'd110, 1'b0}; // Thunder
        5'd18: move_data = {`TYPE_FLYING,   8'd60,  1'b0}; // Wing Attack
        5'd19: move_data = {`TYPE_FLYING,   8'd80,  1'b0}; // Drill Peck
        5'd20: move_data = {`TYPE_ICE,      8'd110, 1'b0}; // Blizzard

        // Status moves (is_status = 1, power = 0)
        5'd21: move_data = {`TYPE_NORMAL,   8'd0, 1'b1}; // Smokescreen
        5'd22: move_data = {`TYPE_GRASS,    8'd0, 1'b1}; // Sleep Powder
        5'd23: move_data = {`TYPE_WATER,    8'd0, 1'b1}; // Withdraw
        5'd26: move_data = {`TYPE_ELECTRIC, 8'd0, 1'b1}; // Thunder Wave
        5'd27: move_data = {`TYPE_PSYCHIC,  8'd0, 1'b1}; // Agility
        5'd28: move_data = {`TYPE_ICE,      8'd0, 1'b1}; // Mist

        default: move_data = 14'd0;
        endcase
    end
endmodule
