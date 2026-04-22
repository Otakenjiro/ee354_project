`timescale 1ns / 1ps

module sprite_mux (
    input wire clk,
    input wire [3:0] player_id, // 1-3, 7-9
    input wire [3:0] cpu_id,    // 1-3, 7-9
    input wire [6:0] p_row, p_col,
    input wire [6:0] c_row, c_col,
    output reg [11:0] player_color,
    output reg [11:0] cpu_color,
    output reg player_transparent,
    output reg cpu_transparent
);

    // Each ROM gets coordinates based on which side uses it.
    wire [6:0] r1_row, r1_col, r2_row, r2_col, r3_row, r3_col;
    wire [6:0] r7_row, r7_col, r8_row, r8_col, r9_row, r9_col;

    assign r1_row = (player_id == 4'd1) ? p_row : c_row;
    assign r1_col = (player_id == 4'd1) ? p_col : c_col;
    assign r2_row = (player_id == 4'd2) ? p_row : c_row;
    assign r2_col = (player_id == 4'd2) ? p_col : c_col;
    assign r3_row = (player_id == 4'd3) ? p_row : c_row;
    assign r3_col = (player_id == 4'd3) ? p_col : c_col;
    assign r7_row = (player_id == 4'd7) ? p_row : c_row;
    assign r7_col = (player_id == 4'd7) ? p_col : c_col;
    assign r8_row = (player_id == 4'd8) ? p_row : c_row;
    assign r8_col = (player_id == 4'd8) ? p_col : c_col;
    assign r9_row = (player_id == 4'd9) ? p_row : c_row;
    assign r9_col = (player_id == 4'd9) ? p_col : c_col;

    wire [11:0] out1, out2, out3, out7, out8, out9;

    charizard_rom rom1(.clk(clk), .row(r1_row), .col(r1_col), .color_data(out1));
    venusaur_rom  rom2(.clk(clk), .row(r2_row), .col(r2_col), .color_data(out2));
    blastoise_rom rom3(.clk(clk), .row(r3_row), .col(r3_col), .color_data(out3));
    moltres_rom   rom7(.clk(clk), .row(r7_row), .col(r7_col), .color_data(out7));
    zapdos_rom    rom8(.clk(clk), .row(r8_row), .col(r8_col), .color_data(out8));
    articuno_rom  rom9(.clk(clk), .row(r9_row), .col(r9_col), .color_data(out9));

    // Output mux for player color
    always @(*) begin
        case (player_id)
            4'd1: player_color = out1;
            4'd2: player_color = out2;
            4'd3: player_color = out3;
            4'd7: player_color = out7;
            4'd8: player_color = out8;
            4'd9: player_color = out9;
            default: player_color = 12'h000;
        endcase
    end

    // Output mux for CPU color
    always @(*) begin
        case (cpu_id)
            4'd1: cpu_color = out1;
            4'd2: cpu_color = out2;
            4'd3: cpu_color = out3;
            4'd7: cpu_color = out7;
            4'd8: cpu_color = out8;
            4'd9: cpu_color = out9;
            default: cpu_color = 12'h000;
        endcase
    end

    // Transparency detection per Pokemon (based on sprite sheet background colors)
    function is_bg;
        input [3:0] pid;
        input [11:0] c;
        reg [3:0] r, g, b;
        begin
            r = c[11:8]; g = c[7:4]; b = c[3:0];
            case (pid)
                4'd1: is_bg = (r <= 4'h1) && (g >= 4'hE) && (b >= 4'h9); // Charizard 0x0FB
                4'd2: is_bg = (r >= 4'hA) && (g <= 4'h1) && (b >= 4'hD); // Venusaur  0xC0F
                4'd3: is_bg = (r <= 4'h1) && (g >= 4'hE) && (b <= 4'h3); // Blastoise 0x0F1
                4'd7: is_bg = (r <= 4'h1) && (g >= 4'hE) && (b <= 4'h2); // Moltres   0x0F0
                4'd8: is_bg = (r <= 4'h2) && (g <= 4'h2) && (b >= 4'hD); // Zapdos    0x10F
                4'd9: is_bg = (r >= 4'hA) && (g >= 4'hD) && (b <= 4'h2); // Articuno  0xCF0
                default: is_bg = 1'b0;
            endcase
        end
    endfunction

    always @(*) begin
        player_transparent = is_bg(player_id, player_color);
        cpu_transparent    = is_bg(cpu_id, cpu_color);
    end

endmodule
