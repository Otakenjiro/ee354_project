`timescale 1ns / 1ps

module background_gen(
    input [9:0] hCount,
    input [9:0] vCount,
    output reg [11:0] bg_color
);

    // Palette
    localparam SKY_DARK    = 12'h012;
    localparam SKY_MID     = 12'h013;
    localparam CANOPY_DARK = 12'h142;
    localparam CANOPY_MED  = 12'h253;
    localparam CANOPY_LT   = 12'h364;
    localparam TRUNK_COLOR = 12'h321;
    localparam GRASS_A     = 12'h4A4;
    localparam GRASS_B     = 12'h393;
    localparam ELEV_A      = 12'h4B4;
    localparam ELEV_B      = 12'h3A3;
    localparam PATH_A      = 12'h543;
    localparam PATH_B      = 12'h432;
    localparam STAR_COLOR  = 12'hCCE;

    // Screen-space pixel coordinates (0-indexed from active area)
    wire [9:0] px = hCount - 10'd144;
    wire [9:0] py = vCount - 10'd35;

    // Wavy tree-line top (varies by 40px horizontal section)
    reg [9:0] tree_top;
    always @(*) begin
        if      (px < 10'd40)  tree_top = 10'd100;
        else if (px < 10'd80)  tree_top = 10'd85;
        else if (px < 10'd120) tree_top = 10'd68;
        else if (px < 10'd160) tree_top = 10'd75;
        else if (px < 10'd200) tree_top = 10'd58;
        else if (px < 10'd240) tree_top = 10'd64;
        else if (px < 10'd280) tree_top = 10'd78;
        else if (px < 10'd320) tree_top = 10'd88;
        else if (px < 10'd360) tree_top = 10'd92;
        else if (px < 10'd400) tree_top = 10'd76;
        else if (px < 10'd440) tree_top = 10'd68;
        else if (px < 10'd480) tree_top = 10'd56;
        else if (px < 10'd520) tree_top = 10'd65;
        else if (px < 10'd560) tree_top = 10'd80;
        else if (px < 10'd600) tree_top = 10'd62;
        else                   tree_top = 10'd88;
    end

    // Grass/canopy boundary
    localparam [9:0] GRASS_LINE = 10'd190;

    // Tree trunks
    wire in_trunk =
        (px >= 10'd82  && px <= 10'd98  && py >= 10'd145 && py < GRASS_LINE) ||
        (px >= 10'd175 && px <= 10'd195 && py >= 10'd135 && py < GRASS_LINE) ||
        (px >= 10'd310 && px <= 10'd325 && py >= 10'd150 && py < GRASS_LINE) ||
        (px >= 10'd455 && px <= 10'd475 && py >= 10'd138 && py < GRASS_LINE) ||
        (px >= 10'd573 && px <= 10'd588 && py >= 10'd142 && py < GRASS_LINE);

    // Diagonal slope on the right side:
    // line from (350, 190) to (640, 380)  =>  3*py + 120 < 2*px for elevated
    wire [11:0] diag_lhs = {2'b0, py} + {2'b0, py} + {2'b0, py} + 12'd120;
    wire [11:0] diag_rhs = {2'b0, px} + {2'b0, px};
    wire in_diag_zone = (px >= 10'd350) && (py >= GRASS_LINE);
    wire in_elevated  = in_diag_zone && (diag_lhs < diag_rhs);

    wire [11:0] diag_abs = (diag_lhs >= diag_rhs)
                          ? (diag_lhs - diag_rhs)
                          : (diag_rhs - diag_lhs);
    wire on_path_border = in_diag_zone && (diag_abs < 12'd18);

    // Stars in sky
    wire is_star =
        (px >= 10'd448 && px <= 10'd452 && py >= 10'd20 && py <= 10'd24) ||
        (px >= 10'd518 && px <= 10'd522 && py >= 10'd10 && py <= 10'd14) ||
        (px >= 10'd383 && px <= 10'd387 && py >= 10'd34 && py <= 10'd38) ||
        (px >= 10'd270 && px <= 10'd273 && py >= 10'd15 && py <= 10'd18) ||
        (px >= 10'd588 && px <= 10'd591 && py >= 10'd42 && py <= 10'd45);

    // Canopy depth (distance from top of canopy)
    wire [9:0] canopy_depth = py - tree_top;

    // Background color selection
    always @(*) begin
        if (py < 10'd50) begin
            bg_color = is_star ? STAR_COLOR : SKY_DARK;
        end else if (py < tree_top) begin
            bg_color = is_star ? STAR_COLOR : SKY_MID;
        end else if (py < GRASS_LINE) begin
            if (in_trunk)
                bg_color = TRUNK_COLOR;
            else if (canopy_depth < 10'd16)
                bg_color = CANOPY_LT;
            else if (canopy_depth < 10'd42)
                bg_color = (px[2] ^ py[1]) ? CANOPY_MED : CANOPY_LT;
            else
                bg_color = (px[1] ^ py[2]) ? CANOPY_DARK : CANOPY_MED;
        end else begin
            if (on_path_border)
                bg_color = (px[3] ^ py[3]) ? PATH_A : PATH_B;
            else if (in_elevated)
                bg_color = (py[2] ^ px[2]) ? ELEV_A : ELEV_B;
            else
                bg_color = (py[3] ^ px[3]) ? GRASS_A : GRASS_B;
        end
    end

endmodule
