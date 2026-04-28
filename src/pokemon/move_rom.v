`include "types.vh"

module move_rom (
    input  wire [4:0]  move_id,
    output reg  [12:0] move_data
);

    always @(*) begin
        case (move_id)
        5'd1:  move_data = {`TYPE_FIRE,     8'd90,  1'b0};
        5'd2:  move_data = {`TYPE_FIRE,     8'd110, 1'b0};
        5'd3:  move_data = {`TYPE_NORMAL,   8'd70,  1'b0};
        5'd4:  move_data = {`TYPE_GRASS,    8'd55,  1'b0};
        5'd5:  move_data = {`TYPE_GRASS,    8'd120, 1'b0};
        5'd6:  move_data = {`TYPE_POISON,   8'd90,  1'b0};
        5'd7:  move_data = {`TYPE_WATER,    8'd90,  1'b0};
        5'd8:  move_data = {`TYPE_WATER,    8'd110, 1'b0};
        5'd9:  move_data = {`TYPE_ICE,      8'd90,  1'b0};
        5'd15: move_data = {`TYPE_ELECTRIC, 8'd90,  1'b0};
        5'd16: move_data = {`TYPE_ELECTRIC, 8'd110, 1'b0};
        5'd18: move_data = {`TYPE_FLYING,   8'd60,  1'b0};
        5'd19: move_data = {`TYPE_FLYING,   8'd80,  1'b0};
        5'd20: move_data = {`TYPE_ICE,      8'd110, 1'b0};
        5'd21: move_data = {`TYPE_NORMAL,   8'd0, 1'b1};
        5'd22: move_data = {`TYPE_GRASS,    8'd0, 1'b1};
        5'd23: move_data = {`TYPE_WATER,    8'd0, 1'b1};
        5'd26: move_data = {`TYPE_ELECTRIC, 8'd0, 1'b1};
        5'd27: move_data = {`TYPE_PSYCHIC,  8'd0, 1'b1};
        5'd28: move_data = {`TYPE_ICE,      8'd0, 1'b1};
        default: move_data = 13'd0;
        endcase
    end
endmodule
