`timescale 1ns / 1ps

module pokemon_vga_top(
    input ClkPort,
    input BtnC,
    input BtnU,
    input BtnD,
    input BtnL,
    input BtnR,

    output hSync, vSync,
    output [3:0] vgaR, vgaG, vgaB,

    output An0, An1, An2, An3, An4, An5, An6, An7,
    output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,

    output QuadSpiFlashCS
);

    wire bright;
    wire [9:0] hc, vc;
    wire [11:0] rgb;

    // VGA timing
    display_controller dc(
        .clk(ClkPort),
        .hSync(hSync), .vSync(vSync),
        .bright(bright),
        .hCount(hc), .vCount(vc)
    );

    // Sprite ROM wiring
    wire [6:0] p1_row, p1_col;
    wire [6:0] p2_row, p2_col;
    wire [11:0] p1_color, p2_color;

    // Player 1: Charizard (bottom-left)
    charizard_rom p1_rom(
        .clk(ClkPort),
        .row(p1_row),
        .col(p1_col),
        .color_data(p1_color)
    );

    // Player 2: Pikachu (top-right)
    pikachu_rom p2_rom(
        .clk(ClkPort),
        .row(p2_row),
        .col(p2_col),
        .color_data(p2_color)
    );

    // Battle scene controller
    battle_scene bs(
        .clk(ClkPort),
        .bright(bright),
        .btnR(BtnR),
        .hCount(hc), .vCount(vc),
        .rgb(rgb),
        .p1_row(p1_row), .p1_col(p1_col),
        .p2_row(p2_row), .p2_col(p2_col),
        .p1_color(p1_color),
        .p2_color(p2_color)
    );

    assign vgaR = rgb[11:8];
    assign vgaG = rgb[7:4];
    assign vgaB = rgb[3:0];

    // Tie off unused SSD
    assign Dp = 1;
    assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = 7'b1111111;
    assign {An7, An6, An5, An4, An3, An2, An1, An0} = 8'b11111111;

    assign QuadSpiFlashCS = 1'b1;

endmodule
