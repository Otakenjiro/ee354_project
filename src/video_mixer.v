`timescale 1ns / 1ps

module video_mixer (
    input wire clk,
    input wire bright,
    input wire [9:0] hCount, vCount,
    input wire [11:0] bg_color,

    output reg [6:0] p_sprite_row, p_sprite_col,
    output reg [6:0] c_sprite_row, c_sprite_col,
    input wire [11:0] p_sprite_color,
    input wire [11:0] c_sprite_color,
    input wire p_sprite_transparent,
    input wire c_sprite_transparent,

    input wire [3:0] game_state,
    input wire [1:0] cursor_pos,
    input wire [9:0] player_hp_cur, player_hp_max,
    input wire [9:0] cpu_hp_cur, cpu_hp_max,
    input wire       user_won,

    input wire trigger_player_atk,
    input wire trigger_cpu_atk,
    output reg anim_done,

    input wire [4:0] p_move0, p_move1, p_move2, p_move3,

    input wire [9:0] p_hp0, p_hp1, p_hp2,
    input wire [1:0] p_active_idx,

    input wire [2:0] player_active_id,
    input wire [2:0] cpu_active_id,

    output reg [11:0] rgb
);

    localparam S_START      = 4'd0;
    localparam S_IDLE       = 4'd1;
    localparam S_FIGHT_SEL  = 4'd2;
    localparam S_SWITCH_SEL = 4'd3;
    localparam S_END        = 4'd11;

    localparam SPRITE_SIZE = 10'd80;
    localparam H_OFFSET    = 10'd144;
    localparam V_OFFSET    = 10'd35;

    localparam P1_HOME_X = H_OFFSET + 10'd60;
    localparam P1_HOME_Y = V_OFFSET + 10'd280;
    localparam P2_HOME_X = H_OFFSET + 10'd500;
    localparam P2_HOME_Y = V_OFFSET + 10'd80;

    localparam HP_BAR_W  = 10'd200;
    localparam HP_BAR_H  = 10'd10;
    localparam P1_HP_X   = 10'd30;
    localparam P1_HP_Y   = 10'd370;
    localparam P2_HP_X   = 10'd410;
    localparam P2_HP_Y   = 10'd60;

    localparam MENU_Y    = 10'd420;
    localparam MENU_H    = 10'd35;

    localparam BLACK     = 12'h000;
    localparam WHITE     = 12'hFFF;
    localparam RED       = 12'hF00;
    localparam GREEN     = 12'h0D0;
    localparam BLUE      = 12'h33F;
    localparam DARK_GRAY = 12'h333;
    localparam MED_GRAY  = 12'h777;
    localparam HP_GREEN  = 12'h2E2;
    localparam HP_YELLOW = 12'hED2;
    localparam HP_RED    = 12'hE22;
    localparam MENU_FIGHT  = 12'h33A;
    localparam MENU_SWITCH = 12'h3A3;
    localparam MENU_SEL    = 12'hFFA;
    localparam NAVY       = 12'h112;
    localparam WIN_BG     = 12'h132;
    localparam LOSE_BG    = 12'h311;
    localparam WIN_COLOR  = 12'h2F4;
    localparam LOSE_COLOR = 12'hF44;
    localparam BACK_COLOR = 12'h555;

    wire [9:0] px = hCount - H_OFFSET;
    wire [9:0] py = vCount - V_OFFSET;

    localparam CH_A=6'd0,  CH_B=6'd1,  CH_C=6'd2,  CH_D=6'd3,  CH_E=6'd4;
    localparam CH_F=6'd5,  CH_G=6'd6,  CH_H=6'd7,  CH_I=6'd8,  CH_J=6'd9;
    localparam CH_K=6'd10, CH_L=6'd11, CH_M=6'd12, CH_N=6'd13, CH_O=6'd14;
    localparam CH_P=6'd15, CH_Q=6'd16, CH_R=6'd17, CH_S=6'd18, CH_T=6'd19;
    localparam CH_U=6'd20, CH_V=6'd21, CH_W=6'd22, CH_X=6'd23, CH_Y=6'd24;
    localparam CH_Z=6'd25;
    localparam CH_0=6'd26, CH_1=6'd27, CH_2=6'd28, CH_3=6'd29, CH_4=6'd30;
    localparam CH_5=6'd31, CH_6=6'd32, CH_7=6'd33, CH_8=6'd34, CH_9=6'd35;
    localparam CH_SPC=6'd36, CH_SLASH=6'd37, CH_BANG=6'd38;

    function [4:0] font_row;
        input [5:0] ch;
        input [2:0] row;
        begin
            font_row = 5'b00000;
            case (ch)
            CH_A: case(row)
                3'd0: font_row=5'b01110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b11111;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b10001; default:;
            endcase
            CH_B: case(row)
                3'd0: font_row=5'b11110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b11110;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b11110; default:;
            endcase
            CH_C: case(row)
                3'd0: font_row=5'b01110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10000; 3'd3: font_row=5'b10000;
                3'd4: font_row=5'b10000; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_D: case(row)
                3'd0: font_row=5'b11110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b10001;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b11110; default:;
            endcase
            CH_E: case(row)
                3'd0: font_row=5'b11111; 3'd1: font_row=5'b10000;
                3'd2: font_row=5'b10000; 3'd3: font_row=5'b11110;
                3'd4: font_row=5'b10000; 3'd5: font_row=5'b10000;
                3'd6: font_row=5'b11111; default:;
            endcase
            CH_F: case(row)
                3'd0: font_row=5'b11111; 3'd1: font_row=5'b10000;
                3'd2: font_row=5'b10000; 3'd3: font_row=5'b11110;
                3'd4: font_row=5'b10000; 3'd5: font_row=5'b10000;
                3'd6: font_row=5'b10000; default:;
            endcase
            CH_G: case(row)
                3'd0: font_row=5'b01110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10000; 3'd3: font_row=5'b10111;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_H: case(row)
                3'd0: font_row=5'b10001; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b11111;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b10001; default:;
            endcase
            CH_I: case(row)
                3'd0: font_row=5'b11111; 3'd1: font_row=5'b00100;
                3'd2: font_row=5'b00100; 3'd3: font_row=5'b00100;
                3'd4: font_row=5'b00100; 3'd5: font_row=5'b00100;
                3'd6: font_row=5'b11111; default:;
            endcase
            CH_J: case(row)
                3'd0: font_row=5'b00111; 3'd1: font_row=5'b00010;
                3'd2: font_row=5'b00010; 3'd3: font_row=5'b00010;
                3'd4: font_row=5'b00010; 3'd5: font_row=5'b10010;
                3'd6: font_row=5'b01100; default:;
            endcase
            CH_K: case(row)
                3'd0: font_row=5'b10001; 3'd1: font_row=5'b10010;
                3'd2: font_row=5'b10100; 3'd3: font_row=5'b11000;
                3'd4: font_row=5'b10100; 3'd5: font_row=5'b10010;
                3'd6: font_row=5'b10001; default:;
            endcase
            CH_L: case(row)
                3'd0: font_row=5'b10000; 3'd1: font_row=5'b10000;
                3'd2: font_row=5'b10000; 3'd3: font_row=5'b10000;
                3'd4: font_row=5'b10000; 3'd5: font_row=5'b10000;
                3'd6: font_row=5'b11111; default:;
            endcase
            CH_M: case(row)
                3'd0: font_row=5'b10001; 3'd1: font_row=5'b11011;
                3'd2: font_row=5'b10101; 3'd3: font_row=5'b10001;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b10001; default:;
            endcase
            CH_N: case(row)
                3'd0: font_row=5'b10001; 3'd1: font_row=5'b11001;
                3'd2: font_row=5'b10101; 3'd3: font_row=5'b10011;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b10001; default:;
            endcase
            CH_O: case(row)
                3'd0: font_row=5'b01110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b10001;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_P: case(row)
                3'd0: font_row=5'b11110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b11110;
                3'd4: font_row=5'b10000; 3'd5: font_row=5'b10000;
                3'd6: font_row=5'b10000; default:;
            endcase
            CH_Q: case(row)
                3'd0: font_row=5'b01110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b10001;
                3'd4: font_row=5'b10101; 3'd5: font_row=5'b10010;
                3'd6: font_row=5'b01101; default:;
            endcase
            CH_R: case(row)
                3'd0: font_row=5'b11110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b11110;
                3'd4: font_row=5'b10100; 3'd5: font_row=5'b10010;
                3'd6: font_row=5'b10001; default:;
            endcase
            CH_S: case(row)
                3'd0: font_row=5'b01110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10000; 3'd3: font_row=5'b01110;
                3'd4: font_row=5'b00001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_T: case(row)
                3'd0: font_row=5'b11111; 3'd1: font_row=5'b00100;
                3'd2: font_row=5'b00100; 3'd3: font_row=5'b00100;
                3'd4: font_row=5'b00100; 3'd5: font_row=5'b00100;
                3'd6: font_row=5'b00100; default:;
            endcase
            CH_U: case(row)
                3'd0: font_row=5'b10001; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b10001;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_V: case(row)
                3'd0: font_row=5'b10001; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b10001;
                3'd4: font_row=5'b01010; 3'd5: font_row=5'b01010;
                3'd6: font_row=5'b00100; default:;
            endcase
            CH_W: case(row)
                3'd0: font_row=5'b10001; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b10101;
                3'd4: font_row=5'b10101; 3'd5: font_row=5'b01010;
                3'd6: font_row=5'b01010; default:;
            endcase
            CH_X: case(row)
                3'd0: font_row=5'b10001; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b01010; 3'd3: font_row=5'b00100;
                3'd4: font_row=5'b01010; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b10001; default:;
            endcase
            CH_Y: case(row)
                3'd0: font_row=5'b10001; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b01010; 3'd3: font_row=5'b00100;
                3'd4: font_row=5'b00100; 3'd5: font_row=5'b00100;
                3'd6: font_row=5'b00100; default:;
            endcase
            CH_Z: case(row)
                3'd0: font_row=5'b11111; 3'd1: font_row=5'b00001;
                3'd2: font_row=5'b00010; 3'd3: font_row=5'b00100;
                3'd4: font_row=5'b01000; 3'd5: font_row=5'b10000;
                3'd6: font_row=5'b11111; default:;
            endcase
            CH_0: case(row)
                3'd0: font_row=5'b01110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10011; 3'd3: font_row=5'b10101;
                3'd4: font_row=5'b11001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_1: case(row)
                3'd0: font_row=5'b00100; 3'd1: font_row=5'b01100;
                3'd2: font_row=5'b00100; 3'd3: font_row=5'b00100;
                3'd4: font_row=5'b00100; 3'd5: font_row=5'b00100;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_2: case(row)
                3'd0: font_row=5'b01110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b00001; 3'd3: font_row=5'b00110;
                3'd4: font_row=5'b01000; 3'd5: font_row=5'b10000;
                3'd6: font_row=5'b11111; default:;
            endcase
            CH_3: case(row)
                3'd0: font_row=5'b11111; 3'd1: font_row=5'b00001;
                3'd2: font_row=5'b00010; 3'd3: font_row=5'b00110;
                3'd4: font_row=5'b00001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_4: case(row)
                3'd0: font_row=5'b00010; 3'd1: font_row=5'b00110;
                3'd2: font_row=5'b01010; 3'd3: font_row=5'b10010;
                3'd4: font_row=5'b11111; 3'd5: font_row=5'b00010;
                3'd6: font_row=5'b00010; default:;
            endcase
            CH_5: case(row)
                3'd0: font_row=5'b11111; 3'd1: font_row=5'b10000;
                3'd2: font_row=5'b11110; 3'd3: font_row=5'b00001;
                3'd4: font_row=5'b00001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_6: case(row)
                3'd0: font_row=5'b00110; 3'd1: font_row=5'b01000;
                3'd2: font_row=5'b10000; 3'd3: font_row=5'b11110;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_7: case(row)
                3'd0: font_row=5'b11111; 3'd1: font_row=5'b00001;
                3'd2: font_row=5'b00010; 3'd3: font_row=5'b00100;
                3'd4: font_row=5'b01000; 3'd5: font_row=5'b01000;
                3'd6: font_row=5'b01000; default:;
            endcase
            CH_8: case(row)
                3'd0: font_row=5'b01110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b01110;
                3'd4: font_row=5'b10001; 3'd5: font_row=5'b10001;
                3'd6: font_row=5'b01110; default:;
            endcase
            CH_9: case(row)
                3'd0: font_row=5'b01110; 3'd1: font_row=5'b10001;
                3'd2: font_row=5'b10001; 3'd3: font_row=5'b01111;
                3'd4: font_row=5'b00001; 3'd5: font_row=5'b00010;
                3'd6: font_row=5'b01100; default:;
            endcase
            CH_SPC: font_row = 5'b00000;
            CH_SLASH: case(row)
                3'd0: font_row=5'b00000; 3'd1: font_row=5'b00001;
                3'd2: font_row=5'b00010; 3'd3: font_row=5'b00100;
                3'd4: font_row=5'b01000; 3'd5: font_row=5'b10000;
                3'd6: font_row=5'b00000; default:;
            endcase
            CH_BANG: case(row)
                3'd0: font_row=5'b00100; 3'd1: font_row=5'b00100;
                3'd2: font_row=5'b00100; 3'd3: font_row=5'b00100;
                3'd4: font_row=5'b00100; 3'd5: font_row=5'b00000;
                3'd6: font_row=5'b00100; default:;
            endcase
            default: font_row = 5'b00000;
            endcase
        end
    endfunction

    function font_pixel;
        input [5:0] ch;
        input [2:0] frow;
        input [2:0] fcol;
        reg [4:0] row_bits;
        begin
            row_bits = font_row(ch, frow);
            font_pixel = row_bits[3'd4 - fcol];
        end
    endfunction

    function [5:0] move_name_char;
        input [4:0] mid;
        input [3:0] idx;
        begin
            move_name_char = CH_SPC;
            case (mid)
            5'd1: case(idx)
                4'd0:move_name_char=CH_F; 4'd1:move_name_char=CH_L; 4'd2:move_name_char=CH_A;
                4'd3:move_name_char=CH_M; 4'd4:move_name_char=CH_E; 4'd5:move_name_char=CH_T;
                4'd6:move_name_char=CH_H; 4'd7:move_name_char=CH_R; 4'd8:move_name_char=CH_O;
                4'd9:move_name_char=CH_W; 4'd10:move_name_char=CH_E; 4'd11:move_name_char=CH_R;
                default:;
            endcase
            5'd2: case(idx)
                4'd0:move_name_char=CH_F; 4'd1:move_name_char=CH_I; 4'd2:move_name_char=CH_R;
                4'd3:move_name_char=CH_E; 4'd4:move_name_char=CH_SPC; 4'd5:move_name_char=CH_B;
                4'd6:move_name_char=CH_L; 4'd7:move_name_char=CH_A; 4'd8:move_name_char=CH_S;
                4'd9:move_name_char=CH_T;
                default:;
            endcase
            5'd3: case(idx)
                4'd0:move_name_char=CH_S; 4'd1:move_name_char=CH_L; 4'd2:move_name_char=CH_A;
                4'd3:move_name_char=CH_S; 4'd4:move_name_char=CH_H;
                default:;
            endcase
            5'd4: case(idx)
                4'd0:move_name_char=CH_R; 4'd1:move_name_char=CH_A; 4'd2:move_name_char=CH_Z;
                4'd3:move_name_char=CH_O; 4'd4:move_name_char=CH_R; 4'd5:move_name_char=CH_SPC;
                4'd6:move_name_char=CH_L; 4'd7:move_name_char=CH_E; 4'd8:move_name_char=CH_A;
                4'd9:move_name_char=CH_F;
                default:;
            endcase
            5'd5: case(idx)
                4'd0:move_name_char=CH_S; 4'd1:move_name_char=CH_O; 4'd2:move_name_char=CH_L;
                4'd3:move_name_char=CH_A; 4'd4:move_name_char=CH_R; 4'd5:move_name_char=CH_SPC;
                4'd6:move_name_char=CH_B; 4'd7:move_name_char=CH_E; 4'd8:move_name_char=CH_A;
                4'd9:move_name_char=CH_M;
                default:;
            endcase
            5'd6: case(idx)
                4'd0:move_name_char=CH_S; 4'd1:move_name_char=CH_L; 4'd2:move_name_char=CH_U;
                4'd3:move_name_char=CH_D; 4'd4:move_name_char=CH_G; 4'd5:move_name_char=CH_E;
                4'd6:move_name_char=CH_SPC; 4'd7:move_name_char=CH_B; 4'd8:move_name_char=CH_O;
                4'd9:move_name_char=CH_M; 4'd10:move_name_char=CH_B;
                default:;
            endcase
            5'd7: case(idx)
                4'd0:move_name_char=CH_S; 4'd1:move_name_char=CH_U; 4'd2:move_name_char=CH_R;
                4'd3:move_name_char=CH_F;
                default:;
            endcase
            5'd8: case(idx)
                4'd0:move_name_char=CH_H; 4'd1:move_name_char=CH_Y; 4'd2:move_name_char=CH_D;
                4'd3:move_name_char=CH_R; 4'd4:move_name_char=CH_O; 4'd5:move_name_char=CH_SPC;
                4'd6:move_name_char=CH_P; 4'd7:move_name_char=CH_U; 4'd8:move_name_char=CH_M;
                4'd9:move_name_char=CH_P;
                default:;
            endcase
            5'd9: case(idx)
                4'd0:move_name_char=CH_I; 4'd1:move_name_char=CH_C; 4'd2:move_name_char=CH_E;
                4'd3:move_name_char=CH_SPC; 4'd4:move_name_char=CH_B; 4'd5:move_name_char=CH_E;
                4'd6:move_name_char=CH_A; 4'd7:move_name_char=CH_M;
                default:;
            endcase
            5'd15: case(idx)
                4'd0:move_name_char=CH_T; 4'd1:move_name_char=CH_H; 4'd2:move_name_char=CH_U;
                4'd3:move_name_char=CH_N; 4'd4:move_name_char=CH_D; 4'd5:move_name_char=CH_E;
                4'd6:move_name_char=CH_R; 4'd7:move_name_char=CH_B; 4'd8:move_name_char=CH_O;
                4'd9:move_name_char=CH_L; 4'd10:move_name_char=CH_T;
                default:;
            endcase
            5'd16: case(idx)
                4'd0:move_name_char=CH_T; 4'd1:move_name_char=CH_H; 4'd2:move_name_char=CH_U;
                4'd3:move_name_char=CH_N; 4'd4:move_name_char=CH_D; 4'd5:move_name_char=CH_E;
                4'd6:move_name_char=CH_R;
                default:;
            endcase
            5'd18: case(idx)
                4'd0:move_name_char=CH_W; 4'd1:move_name_char=CH_I; 4'd2:move_name_char=CH_N;
                4'd3:move_name_char=CH_G; 4'd4:move_name_char=CH_SPC; 4'd5:move_name_char=CH_A;
                4'd6:move_name_char=CH_T; 4'd7:move_name_char=CH_T; 4'd8:move_name_char=CH_A;
                4'd9:move_name_char=CH_C; 4'd10:move_name_char=CH_K;
                default:;
            endcase
            5'd19: case(idx)
                4'd0:move_name_char=CH_D; 4'd1:move_name_char=CH_R; 4'd2:move_name_char=CH_I;
                4'd3:move_name_char=CH_L; 4'd4:move_name_char=CH_L; 4'd5:move_name_char=CH_SPC;
                4'd6:move_name_char=CH_P; 4'd7:move_name_char=CH_E; 4'd8:move_name_char=CH_C;
                4'd9:move_name_char=CH_K;
                default:;
            endcase
            5'd20: case(idx)
                4'd0:move_name_char=CH_B; 4'd1:move_name_char=CH_L; 4'd2:move_name_char=CH_I;
                4'd3:move_name_char=CH_Z; 4'd4:move_name_char=CH_Z; 4'd5:move_name_char=CH_A;
                4'd6:move_name_char=CH_R; 4'd7:move_name_char=CH_D;
                default:;
            endcase
            5'd21: case(idx)
                4'd0:move_name_char=CH_S; 4'd1:move_name_char=CH_M; 4'd2:move_name_char=CH_O;
                4'd3:move_name_char=CH_K; 4'd4:move_name_char=CH_E; 4'd5:move_name_char=CH_S;
                4'd6:move_name_char=CH_C; 4'd7:move_name_char=CH_R; 4'd8:move_name_char=CH_E;
                4'd9:move_name_char=CH_E; 4'd10:move_name_char=CH_N;
                default:;
            endcase
            5'd22: case(idx)
                4'd0:move_name_char=CH_S; 4'd1:move_name_char=CH_L; 4'd2:move_name_char=CH_E;
                4'd3:move_name_char=CH_E; 4'd4:move_name_char=CH_P; 4'd5:move_name_char=CH_SPC;
                4'd6:move_name_char=CH_P; 4'd7:move_name_char=CH_O; 4'd8:move_name_char=CH_W;
                4'd9:move_name_char=CH_D; 4'd10:move_name_char=CH_R;
                default:;
            endcase
            5'd23: case(idx)
                4'd0:move_name_char=CH_W; 4'd1:move_name_char=CH_I; 4'd2:move_name_char=CH_T;
                4'd3:move_name_char=CH_H; 4'd4:move_name_char=CH_D; 4'd5:move_name_char=CH_R;
                4'd6:move_name_char=CH_A; 4'd7:move_name_char=CH_W;
                default:;
            endcase
            5'd26: case(idx)
                4'd0:move_name_char=CH_T; 4'd1:move_name_char=CH_H; 4'd2:move_name_char=CH_N;
                4'd3:move_name_char=CH_D; 4'd4:move_name_char=CH_R; 4'd5:move_name_char=CH_SPC;
                4'd6:move_name_char=CH_W; 4'd7:move_name_char=CH_A; 4'd8:move_name_char=CH_V;
                4'd9:move_name_char=CH_E;
                default:;
            endcase
            5'd27: case(idx)
                4'd0:move_name_char=CH_A; 4'd1:move_name_char=CH_G; 4'd2:move_name_char=CH_I;
                4'd3:move_name_char=CH_L; 4'd4:move_name_char=CH_I; 4'd5:move_name_char=CH_T;
                4'd6:move_name_char=CH_Y;
                default:;
            endcase
            5'd28: case(idx)
                4'd0:move_name_char=CH_M; 4'd1:move_name_char=CH_I; 4'd2:move_name_char=CH_S;
                4'd3:move_name_char=CH_T;
                default:;
            endcase
            default:;
            endcase
        end
    endfunction

    function [5:0] pokemon_name_char;
        input [2:0] pid;
        input [3:0] idx;
        begin
            pokemon_name_char = CH_SPC;
            case (pid)
            3'd1: case(idx)
                4'd0:pokemon_name_char=CH_C; 4'd1:pokemon_name_char=CH_H;
                4'd2:pokemon_name_char=CH_A; 4'd3:pokemon_name_char=CH_R;
                4'd4:pokemon_name_char=CH_I; 4'd5:pokemon_name_char=CH_Z;
                4'd6:pokemon_name_char=CH_A; 4'd7:pokemon_name_char=CH_R;
                4'd8:pokemon_name_char=CH_D; default:;
            endcase
            3'd2: case(idx)
                4'd0:pokemon_name_char=CH_V; 4'd1:pokemon_name_char=CH_E;
                4'd2:pokemon_name_char=CH_N; 4'd3:pokemon_name_char=CH_U;
                4'd4:pokemon_name_char=CH_S; 4'd5:pokemon_name_char=CH_A;
                4'd6:pokemon_name_char=CH_U; 4'd7:pokemon_name_char=CH_R;
                default:;
            endcase
            3'd3: case(idx)
                4'd0:pokemon_name_char=CH_B; 4'd1:pokemon_name_char=CH_L;
                4'd2:pokemon_name_char=CH_A; 4'd3:pokemon_name_char=CH_S;
                4'd4:pokemon_name_char=CH_T; 4'd5:pokemon_name_char=CH_O;
                4'd6:pokemon_name_char=CH_I; 4'd7:pokemon_name_char=CH_S;
                4'd8:pokemon_name_char=CH_E; default:;
            endcase
            3'd4: case(idx)
                4'd0:pokemon_name_char=CH_M; 4'd1:pokemon_name_char=CH_O;
                4'd2:pokemon_name_char=CH_L; 4'd3:pokemon_name_char=CH_T;
                4'd4:pokemon_name_char=CH_R; 4'd5:pokemon_name_char=CH_E;
                4'd6:pokemon_name_char=CH_S; default:;
            endcase
            3'd5: case(idx)
                4'd0:pokemon_name_char=CH_Z; 4'd1:pokemon_name_char=CH_A;
                4'd2:pokemon_name_char=CH_P; 4'd3:pokemon_name_char=CH_D;
                4'd4:pokemon_name_char=CH_O; 4'd5:pokemon_name_char=CH_S;
                default:;
            endcase
            3'd6: case(idx)
                4'd0:pokemon_name_char=CH_A; 4'd1:pokemon_name_char=CH_R;
                4'd2:pokemon_name_char=CH_T; 4'd3:pokemon_name_char=CH_I;
                4'd4:pokemon_name_char=CH_C; 4'd5:pokemon_name_char=CH_U;
                4'd6:pokemon_name_char=CH_N; 4'd7:pokemon_name_char=CH_O;
                default:;
            endcase
            default:;
            endcase
        end
    endfunction

    reg [3:0] p1_hp_h, p1_hp_t, p1_hp_o;
    reg [3:0] p1_mx_h, p1_mx_t, p1_mx_o;
    reg [3:0] p2_hp_h, p2_hp_t, p2_hp_o;
    reg [3:0] p2_mx_h, p2_mx_t, p2_mx_o;

    always @(posedge clk) begin
        p1_hp_h <= player_hp_cur / 100;
        p1_hp_t <= (player_hp_cur / 10) % 10;
        p1_hp_o <= player_hp_cur % 10;
        p1_mx_h <= player_hp_max / 100;
        p1_mx_t <= (player_hp_max / 10) % 10;
        p1_mx_o <= player_hp_max % 10;
        p2_hp_h <= cpu_hp_cur / 100;
        p2_hp_t <= (cpu_hp_cur / 10) % 10;
        p2_hp_o <= cpu_hp_cur % 10;
        p2_mx_h <= cpu_hp_max / 100;
        p2_mx_t <= (cpu_hp_max / 10) % 10;
        p2_mx_o <= cpu_hp_max % 10;
    end

    function [5:0] digit_char;
        input [3:0] d;
        digit_char = CH_0 + {2'd0, d};
    endfunction

    localparam FPW = 10'd20;
    localparam FPH = 10'd28;

    localparam S0_X = 10'd262; localparam S1_X = 10'd286;
    localparam S2_X = 10'd310; localparam S3_X = 10'd334;
    localparam S4_X = 10'd358; localparam START_Y = 10'd200;

    localparam W0_X = 10'd286; localparam W1_X = 10'd310;
    localparam W2_X = 10'd334; localparam WIN_Y = 10'd180;

    localparam L0_X = 10'd274; localparam L1_X = 10'd298;
    localparam L2_X = 10'd322; localparam L3_X = 10'd346;
    localparam LOSE_Y = 10'd180;

    localparam RESTART_BOX_X = 10'd270;
    localparam RESTART_BOX_W = 10'd100;
    localparam RESTART_BOX_Y = 10'd260;
    localparam RESTART_BOX_H = 10'd30;

    reg        text_on;
    reg [2:0]  text_frow;
    always @(*) begin
        text_on   = 1'b0;
        text_frow = 3'd0;

        if (game_state == S_START &&
            py >= START_Y && py < START_Y + FPH) begin
            text_frow = (py - START_Y) >> 2;
            if      (px >= S0_X && px < S0_X + FPW)
                text_on = font_pixel(CH_S, text_frow, (px - S0_X) >> 2);
            else if (px >= S1_X && px < S1_X + FPW)
                text_on = font_pixel(CH_T, text_frow, (px - S1_X) >> 2);
            else if (px >= S2_X && px < S2_X + FPW)
                text_on = font_pixel(CH_A, text_frow, (px - S2_X) >> 2);
            else if (px >= S3_X && px < S3_X + FPW)
                text_on = font_pixel(CH_R, text_frow, (px - S3_X) >> 2);
            else if (px >= S4_X && px < S4_X + FPW)
                text_on = font_pixel(CH_T, text_frow, (px - S4_X) >> 2);
        end
        else if (game_state == S_END && user_won &&
                 py >= WIN_Y && py < WIN_Y + FPH) begin
            text_frow = (py - WIN_Y) >> 2;
            if      (px >= W0_X && px < W0_X + FPW)
                text_on = font_pixel(CH_W, text_frow, (px - W0_X) >> 2);
            else if (px >= W1_X && px < W1_X + FPW)
                text_on = font_pixel(CH_I, text_frow, (px - W1_X) >> 2);
            else if (px >= W2_X && px < W2_X + FPW)
                text_on = font_pixel(CH_N, text_frow, (px - W2_X) >> 2);
        end
        else if (game_state == S_END && !user_won &&
                 py >= LOSE_Y && py < LOSE_Y + FPH) begin
            text_frow = (py - LOSE_Y) >> 2;
            if      (px >= L0_X && px < L0_X + FPW)
                text_on = font_pixel(CH_L, text_frow, (px - L0_X) >> 2);
            else if (px >= L1_X && px < L1_X + FPW)
                text_on = font_pixel(CH_O, text_frow, (px - L1_X) >> 2);
            else if (px >= L2_X && px < L2_X + FPW)
                text_on = font_pixel(CH_S, text_frow, (px - L2_X) >> 2);
            else if (px >= L3_X && px < L3_X + FPW)
                text_on = font_pixel(CH_E, text_frow, (px - L3_X) >> 2);
        end
    end

    wire in_restart_box = (px >= RESTART_BOX_X) &&
                          (px <  RESTART_BOX_X + RESTART_BOX_W) &&
                          (py >= RESTART_BOX_Y) &&
                          (py <  RESTART_BOX_Y + RESTART_BOX_H);
    wire restart_border = in_restart_box &&
                          (px < RESTART_BOX_X + 10'd3 ||
                           px >= RESTART_BOX_X + RESTART_BOX_W - 10'd3 ||
                           py < RESTART_BOX_Y + 10'd3 ||
                           py >= RESTART_BOX_Y + RESTART_BOX_H - 10'd3);

    localparam TEXT_MX     = 10'd4;
    localparam TEXT_MY     = 10'd10;
    localparam TEXT_2X_H   = 10'd14;
    localparam TEXT_STRIDE = 8'd11;

    localparam [2:0] PT0 = 3'd1, PT1 = 3'd2, PT2 = 3'd3;

    wire [9:0] box0_x = 10'd30;
    wire [9:0] box1_x = 10'd180;
    wire [9:0] box2_x = 10'd330;
    wire [9:0] box3_x = 10'd480;
    localparam BOX_W = 10'd140;

    reg        in_box_text;
    reg [1:0]  which_box;
    reg [7:0]  box_text_dx;

    always @(*) begin
        in_box_text = 0;
        which_box = 0;
        box_text_dx = 0;

        if (py >= MENU_Y + TEXT_MY && py < MENU_Y + TEXT_MY + TEXT_2X_H) begin
            if (px >= box0_x + TEXT_MX && px < box0_x + BOX_W - TEXT_MX) begin
                in_box_text = 1; which_box = 0; box_text_dx = px - box0_x - TEXT_MX;
            end else if (px >= box1_x + TEXT_MX && px < box1_x + BOX_W - TEXT_MX) begin
                in_box_text = 1; which_box = 1; box_text_dx = px - box1_x - TEXT_MX;
            end else if (px >= box2_x + TEXT_MX && px < box2_x + BOX_W - TEXT_MX) begin
                in_box_text = 1; which_box = 2; box_text_dx = px - box2_x - TEXT_MX;
            end else if (px >= box3_x + TEXT_MX && px < box3_x + BOX_W - TEXT_MX) begin
                in_box_text = 1; which_box = 3; box_text_dx = px - box3_x - TEXT_MX;
            end
        end
    end

    reg [3:0] mt_cidx;
    reg [3:0] mt_cpix;
    always @(*) begin
        if      (box_text_dx >= 121) begin mt_cidx=11; mt_cpix=box_text_dx-121; end
        else if (box_text_dx >= 110) begin mt_cidx=10; mt_cpix=box_text_dx-110; end
        else if (box_text_dx >= 99)  begin mt_cidx=9;  mt_cpix=box_text_dx-99;  end
        else if (box_text_dx >= 88)  begin mt_cidx=8;  mt_cpix=box_text_dx-88;  end
        else if (box_text_dx >= 77)  begin mt_cidx=7;  mt_cpix=box_text_dx-77;  end
        else if (box_text_dx >= 66)  begin mt_cidx=6;  mt_cpix=box_text_dx-66;  end
        else if (box_text_dx >= 55)  begin mt_cidx=5;  mt_cpix=box_text_dx-55;  end
        else if (box_text_dx >= 44)  begin mt_cidx=4;  mt_cpix=box_text_dx-44;  end
        else if (box_text_dx >= 33)  begin mt_cidx=3;  mt_cpix=box_text_dx-33;  end
        else if (box_text_dx >= 22)  begin mt_cidx=2;  mt_cpix=box_text_dx-22;  end
        else if (box_text_dx >= 11)  begin mt_cidx=1;  mt_cpix=box_text_dx-11;  end
        else                         begin mt_cidx=0;  mt_cpix=box_text_dx;      end
    end

    wire [2:0] mt_fcol = mt_cpix[3:1];
    wire [2:0] mt_frow = (py - MENU_Y - TEXT_MY) >> 1;
    wire mt_in_font = (mt_cpix < 4'd10);

    reg [5:0] mt_char;
    always @(*) begin
        mt_char = CH_SPC;
        case (game_state)
        S_IDLE: begin
            case (which_box)
            2'd0: case(mt_cidx)
                4'd0:mt_char=CH_F; 4'd1:mt_char=CH_I; 4'd2:mt_char=CH_G;
                4'd3:mt_char=CH_H; 4'd4:mt_char=CH_T; default:;
            endcase
            2'd1: case(mt_cidx)
                4'd0:mt_char=CH_S; 4'd1:mt_char=CH_W; 4'd2:mt_char=CH_I;
                4'd3:mt_char=CH_T; 4'd4:mt_char=CH_C; 4'd5:mt_char=CH_H;
                default:;
            endcase
            default:;
            endcase
        end
        S_FIGHT_SEL: begin
            case (which_box)
            2'd0: mt_char = move_name_char(p_move0, mt_cidx);
            2'd1: mt_char = move_name_char(p_move1, mt_cidx);
            2'd2: mt_char = move_name_char(p_move2, mt_cidx);
            2'd3: mt_char = move_name_char(p_move3, mt_cidx);
            endcase
        end
        S_SWITCH_SEL: begin
            case (which_box)
            2'd0: mt_char = (p_hp0 == 0) ?
                (mt_cidx==0?CH_F:mt_cidx==1?CH_A:mt_cidx==2?CH_I:mt_cidx==3?CH_N:
                 mt_cidx==4?CH_T:mt_cidx==5?CH_E:mt_cidx==6?CH_D:CH_SPC) :
                pokemon_name_char(PT0, mt_cidx);
            2'd1: mt_char = (p_hp1 == 0) ?
                (mt_cidx==0?CH_F:mt_cidx==1?CH_A:mt_cidx==2?CH_I:mt_cidx==3?CH_N:
                 mt_cidx==4?CH_T:mt_cidx==5?CH_E:mt_cidx==6?CH_D:CH_SPC) :
                pokemon_name_char(PT1, mt_cidx);
            2'd2: mt_char = (p_hp2 == 0) ?
                (mt_cidx==0?CH_F:mt_cidx==1?CH_A:mt_cidx==2?CH_I:mt_cidx==3?CH_N:
                 mt_cidx==4?CH_T:mt_cidx==5?CH_E:mt_cidx==6?CH_D:CH_SPC) :
                pokemon_name_char(PT2, mt_cidx);
            2'd3:
                case(mt_cidx)
                    4'd0:mt_char=CH_B; 4'd1:mt_char=CH_A;
                    4'd2:mt_char=CH_C; 4'd3:mt_char=CH_K;
                    default:;
                endcase
            endcase
        end
        default:;
        endcase
    end

    wire menu_text_on = in_box_text && mt_in_font && font_pixel(mt_char, mt_frow, mt_fcol);

    localparam HP_TXT_DY = 10'd4;
    localparam P1_HPT_X  = P1_HP_X;
    localparam P1_HPT_Y  = P1_HP_Y + HP_BAR_H + HP_TXT_DY;
    localparam P2_HPT_X  = P2_HP_X;
    localparam P2_HPT_Y  = P2_HP_Y + HP_BAR_H + HP_TXT_DY;

    reg        hp_txt_on;
    always @(*) begin
        hp_txt_on = 0;
        if (py >= P1_HPT_Y && py < P1_HPT_Y + TEXT_2X_H) begin : p1_hp_txt
            reg [7:0] tdx;
            reg [3:0] ci, cp;
            reg [2:0] fc, fr;
            reg [5:0] ch;
            tdx = px - P1_HPT_X;
            if (px >= P1_HPT_X && px < P1_HPT_X + 8'd77) begin
                if      (tdx>=66) begin ci=6; cp=tdx-66; end
                else if (tdx>=55) begin ci=5; cp=tdx-55; end
                else if (tdx>=44) begin ci=4; cp=tdx-44; end
                else if (tdx>=33) begin ci=3; cp=tdx-33; end
                else if (tdx>=22) begin ci=2; cp=tdx-22; end
                else if (tdx>=11) begin ci=1; cp=tdx-11; end
                else              begin ci=0; cp=tdx;     end
                fc = cp[3:1]; fr = (py - P1_HPT_Y) >> 1;
                if (cp < 10) begin
                    case (ci)
                        0: ch = (p1_hp_h==0) ? CH_SPC : digit_char(p1_hp_h);
                        1: ch = (p1_hp_h==0 && p1_hp_t==0) ? CH_SPC : digit_char(p1_hp_t);
                        2: ch = digit_char(p1_hp_o);
                        3: ch = CH_SLASH;
                        4: ch = (p1_mx_h==0) ? CH_SPC : digit_char(p1_mx_h);
                        5: ch = (p1_mx_h==0 && p1_mx_t==0) ? CH_SPC : digit_char(p1_mx_t);
                        6: ch = digit_char(p1_mx_o);
                        default: ch = CH_SPC;
                    endcase
                    hp_txt_on = font_pixel(ch, fr, fc);
                end
            end
        end
        else if (py >= P2_HPT_Y && py < P2_HPT_Y + TEXT_2X_H) begin : p2_hp_txt
            reg [7:0] tdx;
            reg [3:0] ci, cp;
            reg [2:0] fc, fr;
            reg [5:0] ch;
            tdx = px - P2_HPT_X;
            if (px >= P2_HPT_X && px < P2_HPT_X + 8'd77) begin
                if      (tdx>=66) begin ci=6; cp=tdx-66; end
                else if (tdx>=55) begin ci=5; cp=tdx-55; end
                else if (tdx>=44) begin ci=4; cp=tdx-44; end
                else if (tdx>=33) begin ci=3; cp=tdx-33; end
                else if (tdx>=22) begin ci=2; cp=tdx-22; end
                else if (tdx>=11) begin ci=1; cp=tdx-11; end
                else              begin ci=0; cp=tdx;     end
                fc = cp[3:1]; fr = (py - P2_HPT_Y) >> 1;
                if (cp < 10) begin
                    case (ci)
                        0: ch = (p2_hp_h==0) ? CH_SPC : digit_char(p2_hp_h);
                        1: ch = (p2_hp_h==0 && p2_hp_t==0) ? CH_SPC : digit_char(p2_hp_t);
                        2: ch = digit_char(p2_hp_o);
                        3: ch = CH_SLASH;
                        4: ch = (p2_mx_h==0) ? CH_SPC : digit_char(p2_mx_h);
                        5: ch = (p2_mx_h==0 && p2_mx_t==0) ? CH_SPC : digit_char(p2_mx_t);
                        6: ch = digit_char(p2_mx_o);
                        default: ch = CH_SPC;
                    endcase
                    hp_txt_on = font_pixel(ch, fr, fc);
                end
            end
        end
    end

    localparam NAME_DY   = 10'd18;
    localparam P1_NM_X   = P1_HP_X;
    localparam P1_NM_Y   = P1_HP_Y - NAME_DY;
    localparam P2_NM_X   = P2_HP_X;
    localparam P2_NM_Y   = P2_HP_Y - NAME_DY;

    reg name_txt_on;
    always @(*) begin
        name_txt_on = 0;
        if (py >= P1_NM_Y && py < P1_NM_Y + TEXT_2X_H) begin : p1_name
            reg [7:0] tdx;
            reg [3:0] ci, cp;
            reg [2:0] fc, fr;
            reg [5:0] ch;
            tdx = px - P1_NM_X;
            if (px >= P1_NM_X && px < P1_NM_X + 10'd110) begin
                if      (tdx>=99)  begin ci=9;  cp=tdx-99;  end
                else if (tdx>=88)  begin ci=8;  cp=tdx-88;  end
                else if (tdx>=77)  begin ci=7;  cp=tdx-77;  end
                else if (tdx>=66)  begin ci=6;  cp=tdx-66;  end
                else if (tdx>=55)  begin ci=5;  cp=tdx-55;  end
                else if (tdx>=44)  begin ci=4;  cp=tdx-44;  end
                else if (tdx>=33)  begin ci=3;  cp=tdx-33;  end
                else if (tdx>=22)  begin ci=2;  cp=tdx-22;  end
                else if (tdx>=11)  begin ci=1;  cp=tdx-11;  end
                else               begin ci=0;  cp=tdx;      end
                fc = cp[3:1]; fr = (py - P1_NM_Y) >> 1;
                if (cp < 10) begin
                    ch = pokemon_name_char(player_active_id, ci);
                    name_txt_on = font_pixel(ch, fr, fc);
                end
            end
        end
        else if (py >= P2_NM_Y && py < P2_NM_Y + TEXT_2X_H) begin : p2_name
            reg [7:0] tdx;
            reg [3:0] ci, cp;
            reg [2:0] fc, fr;
            reg [5:0] ch;
            tdx = px - P2_NM_X;
            if (px >= P2_NM_X && px < P2_NM_X + 10'd110) begin
                if      (tdx>=99)  begin ci=9;  cp=tdx-99;  end
                else if (tdx>=88)  begin ci=8;  cp=tdx-88;  end
                else if (tdx>=77)  begin ci=7;  cp=tdx-77;  end
                else if (tdx>=66)  begin ci=6;  cp=tdx-66;  end
                else if (tdx>=55)  begin ci=5;  cp=tdx-55;  end
                else if (tdx>=44)  begin ci=4;  cp=tdx-44;  end
                else if (tdx>=33)  begin ci=3;  cp=tdx-33;  end
                else if (tdx>=22)  begin ci=2;  cp=tdx-22;  end
                else if (tdx>=11)  begin ci=1;  cp=tdx-11;  end
                else               begin ci=0;  cp=tdx;      end
                fc = cp[3:1]; fr = (py - P2_NM_Y) >> 1;
                if (cp < 10) begin
                    ch = pokemon_name_char(cpu_active_id, ci);
                    name_txt_on = font_pixel(ch, fr, fc);
                end
            end
        end
    end

    localparam A_IDLE    = 3'd0;
    localparam A_LUNGE   = 3'd1;
    localparam A_RETURN  = 3'd2;
    localparam A_HIT1    = 3'd3;
    localparam A_HIT2    = 3'd4;
    localparam A_DONE    = 3'd5;

    localparam ANIM_TICK_MAX  = 24'd150000;
    localparam SHAKE_TICK_MAX = 24'd500000;
    localparam LUNGE_SPEED    = 10'd4;

    reg [2:0]  anim_state;
    reg [9:0]  p1_x, p1_y, p2_x, p2_y;
    reg [3:0]  shake_counter;
    reg        p1_flash, p2_flash;
    reg        attacking_is_p1;

    reg [23:0] anim_tick_cnt;
    reg        anim_tick;
    reg [23:0] shake_tick_cnt;
    reg        shake_tick;

    reg [24:0] flash_cnt;
    wire       flash_bit = flash_cnt[23];

    wire [9:0] p1_lunge_x = P2_HOME_X - SPRITE_SIZE;
    wire [9:0] p1_lunge_y = P2_HOME_Y + SPRITE_SIZE - 10'd20;
    wire [9:0] p2_lunge_x = P1_HOME_X + SPRITE_SIZE;
    wire [9:0] p2_lunge_y = P1_HOME_Y - SPRITE_SIZE + 10'd20;

    initial begin
        anim_state = A_IDLE;
        p1_x = P1_HOME_X; p1_y = P1_HOME_Y;
        p2_x = P2_HOME_X; p2_y = P2_HOME_Y;
        shake_counter = 0;
        p1_flash = 0; p2_flash = 0;
        anim_done = 0;
        anim_tick_cnt = 0; anim_tick = 0;
        shake_tick_cnt = 0; shake_tick = 0;
        flash_cnt = 0;
        attacking_is_p1 = 0;
    end

    always @(posedge clk) begin
        flash_cnt <= flash_cnt + 25'd1;
        if (anim_tick_cnt >= ANIM_TICK_MAX - 1) begin
            anim_tick_cnt <= 0; anim_tick <= 1;
        end else begin
            anim_tick_cnt <= anim_tick_cnt + 1; anim_tick <= 0;
        end
        if (shake_tick_cnt >= SHAKE_TICK_MAX - 1) begin
            shake_tick_cnt <= 0; shake_tick <= 1;
        end else begin
            shake_tick_cnt <= shake_tick_cnt + 1; shake_tick <= 0;
        end
    end

    always @(posedge clk) begin
        anim_done <= 0;
        case (anim_state)
        A_IDLE: begin
            p1_x <= P1_HOME_X; p1_y <= P1_HOME_Y;
            p2_x <= P2_HOME_X; p2_y <= P2_HOME_Y;
            p1_flash <= 0; p2_flash <= 0;
            shake_counter <= 0;
            if (trigger_player_atk) begin
                attacking_is_p1 <= 1; anim_state <= A_LUNGE;
            end else if (trigger_cpu_atk) begin
                attacking_is_p1 <= 0; anim_state <= A_LUNGE;
            end
        end
        A_LUNGE: begin
            if (anim_tick) begin
                if (attacking_is_p1) begin
                    if (p1_x < p1_lunge_x) p1_x <= p1_x + LUNGE_SPEED;
                    else                    p1_x <= p1_lunge_x;
                    if (p1_y > p1_lunge_y) p1_y <= p1_y - LUNGE_SPEED;
                    else                    p1_y <= p1_lunge_y;
                    if (p1_x >= p1_lunge_x && p1_y <= p1_lunge_y)
                        anim_state <= A_RETURN;
                end else begin
                    if (p2_x > p2_lunge_x) p2_x <= p2_x - LUNGE_SPEED;
                    else                    p2_x <= p2_lunge_x;
                    if (p2_y < p2_lunge_y) p2_y <= p2_y + LUNGE_SPEED;
                    else                    p2_y <= p2_lunge_y;
                    if (p2_x <= p2_lunge_x && p2_y >= p2_lunge_y)
                        anim_state <= A_RETURN;
                end
            end
        end
        A_RETURN: begin
            if (anim_tick) begin
                if (attacking_is_p1) begin
                    if (p1_x > P1_HOME_X) p1_x <= p1_x - LUNGE_SPEED;
                    else                   p1_x <= P1_HOME_X;
                    if (p1_y < P1_HOME_Y) p1_y <= p1_y + LUNGE_SPEED;
                    else                   p1_y <= P1_HOME_Y;
                    if (p1_x <= P1_HOME_X && p1_y >= P1_HOME_Y) begin
                        anim_state <= A_HIT1; shake_counter <= 0; p2_flash <= 1;
                    end
                end else begin
                    if (p2_x < P2_HOME_X) p2_x <= p2_x + LUNGE_SPEED;
                    else                   p2_x <= P2_HOME_X;
                    if (p2_y > P2_HOME_Y) p2_y <= p2_y - LUNGE_SPEED;
                    else                   p2_y <= P2_HOME_Y;
                    if (p2_x >= P2_HOME_X && p2_y <= P2_HOME_Y) begin
                        anim_state <= A_HIT1; shake_counter <= 0; p1_flash <= 1;
                    end
                end
            end
        end
        A_HIT1: begin
            if (shake_tick) begin
                shake_counter <= shake_counter + 1;
                if (attacking_is_p1) begin
                    p2_flash <= ~p2_flash;
                    p2_x <= shake_counter[0] ? (P2_HOME_X + 10'd4) : (P2_HOME_X - 10'd4);
                end else begin
                    p1_flash <= ~p1_flash;
                    p1_x <= shake_counter[0] ? (P1_HOME_X + 10'd4) : (P1_HOME_X - 10'd4);
                end
                if (shake_counter >= 4'd4) begin
                    anim_state <= A_HIT2; shake_counter <= 0;
                end
            end
        end
        A_HIT2: begin
            if (shake_tick) begin
                shake_counter <= shake_counter + 1;
                if (attacking_is_p1) begin
                    p2_flash <= ~p2_flash;
                    p2_x <= shake_counter[0] ? (P2_HOME_X - 10'd4) : (P2_HOME_X + 10'd4);
                end else begin
                    p1_flash <= ~p1_flash;
                    p1_x <= shake_counter[0] ? (P1_HOME_X - 10'd4) : (P1_HOME_X + 10'd4);
                end
                if (shake_counter >= 4'd4) begin
                    anim_state <= A_DONE;
                    p1_flash <= 0; p2_flash <= 0;
                    p1_x <= P1_HOME_X; p2_x <= P2_HOME_X;
                end
            end
        end
        A_DONE: begin
            anim_done <= 1; anim_state <= A_IDLE;
        end
        endcase
    end

    wire in_p1 = (hCount >= p1_x) && (hCount < p1_x + SPRITE_SIZE)
              && (vCount >= p1_y) && (vCount < p1_y + SPRITE_SIZE);
    wire in_p2 = (hCount >= p2_x) && (hCount < p2_x + SPRITE_SIZE)
              && (vCount >= p2_y) && (vCount < p2_y + SPRITE_SIZE);

    always @(*) begin
        p_sprite_row = vCount - p1_y;
        p_sprite_col = hCount - p1_x;
        c_sprite_row = vCount - p2_y;
        c_sprite_col = hCount - p2_x;
    end

    wire [9:0] hp_dx_p = px - P1_HP_X;
    wire [9:0] hp_dx_c = px - P2_HP_X;

    wire in_p1_hp_border = (px >= P1_HP_X - 10'd2) && (px < P1_HP_X + HP_BAR_W + 10'd2)
                         && (py >= P1_HP_Y - 10'd2) && (py < P1_HP_Y + HP_BAR_H + 10'd2);
    wire in_p1_hp_bg     = (px >= P1_HP_X) && (px < P1_HP_X + HP_BAR_W)
                         && (py >= P1_HP_Y) && (py < P1_HP_Y + HP_BAR_H);
    wire [19:0] hp_fill_lhs_p = hp_dx_p * player_hp_max;
    wire [19:0] hp_fill_rhs_p = player_hp_cur * HP_BAR_W;
    wire in_p1_hp_fill   = in_p1_hp_bg && (player_hp_max > 0) &&
                           (hp_fill_lhs_p < hp_fill_rhs_p);

    wire in_p2_hp_border = (px >= P2_HP_X - 10'd2) && (px < P2_HP_X + HP_BAR_W + 10'd2)
                         && (py >= P2_HP_Y - 10'd2) && (py < P2_HP_Y + HP_BAR_H + 10'd2);
    wire in_p2_hp_bg     = (px >= P2_HP_X) && (px < P2_HP_X + HP_BAR_W)
                         && (py >= P2_HP_Y) && (py < P2_HP_Y + HP_BAR_H);
    wire [19:0] hp_fill_lhs_c = hp_dx_c * cpu_hp_max;
    wire [19:0] hp_fill_rhs_c = cpu_hp_cur * HP_BAR_W;
    wire in_p2_hp_fill   = in_p2_hp_bg && (cpu_hp_max > 0) &&
                           (hp_fill_lhs_c < hp_fill_rhs_c);

    wire p1_green  = ({player_hp_cur, 1'b0} > player_hp_max);
    wire p1_yellow = ({player_hp_cur, 2'b00} > player_hp_max);
    wire [11:0] p1_hp_color = p1_green ? HP_GREEN : (p1_yellow ? HP_YELLOW : HP_RED);

    wire p2_green  = ({cpu_hp_cur, 1'b0} > cpu_hp_max);
    wire p2_yellow = ({cpu_hp_cur, 2'b00} > cpu_hp_max);
    wire [11:0] p2_hp_color = p2_green ? HP_GREEN : (p2_yellow ? HP_YELLOW : HP_RED);

    wire in_menu_area = (py >= MENU_Y) && (py < MENU_Y + MENU_H);

    wire in_box0 = in_menu_area && (px >= box0_x) && (px < box0_x + BOX_W);
    wire in_box1 = in_menu_area && (px >= box1_x) && (px < box1_x + BOX_W);
    wire in_box2 = in_menu_area && (px >= box2_x) && (px < box2_x + BOX_W);
    wire in_box3 = in_menu_area && (px >= box3_x) && (px < box3_x + BOX_W);

    wire box0_border = in_box0 && (px < box0_x+3 || px >= box0_x+BOX_W-3 ||
                                   py < MENU_Y+3 || py >= MENU_Y+MENU_H-3);
    wire box1_border = in_box1 && (px < box1_x+3 || px >= box1_x+BOX_W-3 ||
                                   py < MENU_Y+3 || py >= MENU_Y+MENU_H-3);
    wire box2_border = in_box2 && (px < box2_x+3 || px >= box2_x+BOX_W-3 ||
                                   py < MENU_Y+3 || py >= MENU_Y+MENU_H-3);
    wire box3_border = in_box3 && (px < box3_x+3 || px >= box3_x+BOX_W-3 ||
                                   py < MENU_Y+3 || py >= MENU_Y+MENU_H-3);

    reg [11:0] menu_pixel;
    reg        menu_active;

    always @(*) begin
        menu_pixel  = 12'd0;
        menu_active = 0;

        case (game_state)
        S_IDLE: begin
            if (in_box0) begin
                menu_active = 1;
                menu_pixel = (cursor_pos == 2'd0) ?
                    (box0_border ? WHITE : MENU_SEL) :
                    (box0_border ? MED_GRAY : MENU_FIGHT);
            end
            if (in_box1) begin
                menu_active = 1;
                menu_pixel = (cursor_pos == 2'd1) ?
                    (box1_border ? WHITE : MENU_SEL) :
                    (box1_border ? MED_GRAY : MENU_SWITCH);
            end
        end

        S_FIGHT_SEL: begin
            if (in_box0) begin
                menu_active = 1;
                menu_pixel = (cursor_pos == 2'd0) ?
                    (box0_border ? WHITE : MENU_SEL) : (box0_border ? MED_GRAY : BLUE);
            end
            if (in_box1) begin
                menu_active = 1;
                menu_pixel = (cursor_pos == 2'd1) ?
                    (box1_border ? WHITE : MENU_SEL) : (box1_border ? MED_GRAY : BLUE);
            end
            if (in_box2) begin
                menu_active = 1;
                menu_pixel = (cursor_pos == 2'd2) ?
                    (box2_border ? WHITE : MENU_SEL) : (box2_border ? MED_GRAY : BLUE);
            end
            if (in_box3) begin
                menu_active = 1;
                menu_pixel = (cursor_pos == 2'd3) ?
                    (box3_border ? WHITE : MENU_SEL) : (box3_border ? MED_GRAY : BLUE);
            end
        end

        S_SWITCH_SEL: begin
            if (in_box0) begin
                menu_active = 1;
                menu_pixel = (cursor_pos == 2'd0) ?
                    (box0_border ? WHITE : MENU_SEL) : (box0_border ? MED_GRAY : GREEN);
            end
            if (in_box1) begin
                menu_active = 1;
                menu_pixel = (cursor_pos == 2'd1) ?
                    (box1_border ? WHITE : MENU_SEL) : (box1_border ? MED_GRAY : GREEN);
            end
            if (in_box2) begin
                menu_active = 1;
                menu_pixel = (cursor_pos == 2'd2) ?
                    (box2_border ? WHITE : MENU_SEL) : (box2_border ? MED_GRAY : GREEN);
            end
            if (in_box3) begin
                menu_active = 1;
                menu_pixel = box3_border ? MED_GRAY : BACK_COLOR;
            end
        end

        default: menu_active = 0;
        endcase
    end

    wire [11:0] menu_txt_clr = (menu_pixel == MENU_SEL) ? BLACK : WHITE;

    localparam BACK_X = 10'd540;
    localparam BACK_Y = 10'd390;
    localparam BACK_W = 10'd90;
    localparam BACK_H = 10'd25;

    wire in_back_btn = (game_state == S_FIGHT_SEL) &&
                       (px >= BACK_X) && (px < BACK_X + BACK_W) &&
                       (py >= BACK_Y) && (py < BACK_Y + BACK_H);
    wire back_border = in_back_btn &&
                       (px < BACK_X+3 || px >= BACK_X+BACK_W-3 ||
                        py < BACK_Y+3 || py >= BACK_Y+BACK_H-3);

    reg back_txt_on;
    always @(*) begin
        back_txt_on = 0;
        if (in_back_btn && !back_border &&
            py >= BACK_Y + 10'd5 && py < BACK_Y + 10'd5 + TEXT_2X_H &&
            px >= BACK_X + 10'd23 && px < BACK_X + 10'd23 + 8'd44) begin : back_txt_blk
            reg [7:0] tdx;
            reg [3:0] ci, cp;
            reg [2:0] fc, fr;
            reg [5:0] ch;
            tdx = px - BACK_X - 10'd23;
            if      (tdx>=33) begin ci=3; cp=tdx-33; end
            else if (tdx>=22) begin ci=2; cp=tdx-22; end
            else if (tdx>=11) begin ci=1; cp=tdx-11; end
            else              begin ci=0; cp=tdx;     end
            fc = cp[3:1]; fr = (py - BACK_Y - 10'd5) >> 1;
            if (cp < 10) begin
                case (ci)
                    0: ch=CH_B; 1: ch=CH_A; 2: ch=CH_C; 3: ch=CH_K;
                    default: ch=CH_SPC;
                endcase
                back_txt_on = font_pixel(ch, fr, fc);
            end
        end
    end

    wire in_battle = (game_state != S_START) && (game_state != S_END);

    always @(*) begin
        if (~bright) begin
            rgb = BLACK;

        end else if (game_state == S_START) begin
            if (text_on)
                rgb = flash_bit ? WHITE : MED_GRAY;
            else if (in_restart_box) begin
                if (restart_border)
                    rgb = WHITE;
                else
                    rgb = flash_bit ? BLUE : NAVY;
            end else
                rgb = NAVY;

        end else if (game_state == S_END) begin
            if (text_on)
                rgb = WHITE;
            else if (in_restart_box) begin
                if (restart_border)
                    rgb = WHITE;
                else
                    rgb = flash_bit ? MED_GRAY : DARK_GRAY;
            end else
                rgb = user_won ? WIN_BG : LOSE_BG;

        end else begin
            if (in_p1_hp_border) begin
                if (in_p1_hp_fill)       rgb = p1_hp_color;
                else if (in_p1_hp_bg)    rgb = DARK_GRAY;
                else                     rgb = WHITE;
            end
            else if (in_p2_hp_border) begin
                if (in_p2_hp_fill)       rgb = p2_hp_color;
                else if (in_p2_hp_bg)    rgb = DARK_GRAY;
                else                     rgb = WHITE;
            end

            else if (hp_txt_on)
                rgb = WHITE;

            else if (name_txt_on)
                rgb = WHITE;

            else if (menu_active) begin
                if (menu_text_on && !box0_border && !box1_border && !box2_border && !box3_border)
                    rgb = menu_txt_clr;
                else
                    rgb = menu_pixel;
            end

            else if (in_back_btn) begin
                if (back_txt_on)
                    rgb = WHITE;
                else if (back_border)
                    rgb = MED_GRAY;
                else
                    rgb = BACK_COLOR;
            end

            else if (in_p1 && !p_sprite_transparent)
                rgb = p1_flash ? RED : p_sprite_color;

            else if (in_p2 && !c_sprite_transparent)
                rgb = p2_flash ? RED : c_sprite_color;

            else
                rgb = bg_color;
        end
    end

endmodule
