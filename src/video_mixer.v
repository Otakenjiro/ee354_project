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

    output reg [11:0] rgb
);

    // ================================================================
    //  Constants
    // ================================================================
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

    wire [9:0] px = hCount - H_OFFSET;
    wire [9:0] py = vCount - V_OFFSET;

    // ================================================================
    //  5×7 pixel font (14 characters: A C E F G H I L N O R S T W)
    // ================================================================
    localparam CH_A = 4'd0,  CH_C = 4'd1,  CH_E = 4'd2,  CH_F = 4'd3;
    localparam CH_G = 4'd4,  CH_H = 4'd5,  CH_I = 4'd6,  CH_L = 4'd7;
    localparam CH_N = 4'd8,  CH_O = 4'd9,  CH_R = 4'd10, CH_S = 4'd11;
    localparam CH_T = 4'd12, CH_W = 4'd13;

    function [4:0] font_row;
        input [3:0] ch;
        input [2:0] row;
        begin
            font_row = 5'b00000;
            case (ch)
            CH_A: case (row)
                3'd0: font_row = 5'b01110; 3'd1: font_row = 5'b10001;
                3'd2: font_row = 5'b10001; 3'd3: font_row = 5'b11111;
                3'd4: font_row = 5'b10001; 3'd5: font_row = 5'b10001;
                3'd6: font_row = 5'b10001; default: font_row = 5'b00000;
            endcase
            CH_C: case (row)
                3'd0: font_row = 5'b01110; 3'd1: font_row = 5'b10001;
                3'd2: font_row = 5'b10000; 3'd3: font_row = 5'b10000;
                3'd4: font_row = 5'b10000; 3'd5: font_row = 5'b10001;
                3'd6: font_row = 5'b01110; default: font_row = 5'b00000;
            endcase
            CH_E: case (row)
                3'd0: font_row = 5'b11111; 3'd1: font_row = 5'b10000;
                3'd2: font_row = 5'b10000; 3'd3: font_row = 5'b11110;
                3'd4: font_row = 5'b10000; 3'd5: font_row = 5'b10000;
                3'd6: font_row = 5'b11111; default: font_row = 5'b00000;
            endcase
            CH_F: case (row)
                3'd0: font_row = 5'b11111; 3'd1: font_row = 5'b10000;
                3'd2: font_row = 5'b10000; 3'd3: font_row = 5'b11110;
                3'd4: font_row = 5'b10000; 3'd5: font_row = 5'b10000;
                3'd6: font_row = 5'b10000; default: font_row = 5'b00000;
            endcase
            CH_G: case (row)
                3'd0: font_row = 5'b01110; 3'd1: font_row = 5'b10001;
                3'd2: font_row = 5'b10000; 3'd3: font_row = 5'b10111;
                3'd4: font_row = 5'b10001; 3'd5: font_row = 5'b10001;
                3'd6: font_row = 5'b01110; default: font_row = 5'b00000;
            endcase
            CH_H: case (row)
                3'd0: font_row = 5'b10001; 3'd1: font_row = 5'b10001;
                3'd2: font_row = 5'b10001; 3'd3: font_row = 5'b11111;
                3'd4: font_row = 5'b10001; 3'd5: font_row = 5'b10001;
                3'd6: font_row = 5'b10001; default: font_row = 5'b00000;
            endcase
            CH_I: case (row)
                3'd0: font_row = 5'b11111; 3'd1: font_row = 5'b00100;
                3'd2: font_row = 5'b00100; 3'd3: font_row = 5'b00100;
                3'd4: font_row = 5'b00100; 3'd5: font_row = 5'b00100;
                3'd6: font_row = 5'b11111; default: font_row = 5'b00000;
            endcase
            CH_L: case (row)
                3'd0: font_row = 5'b10000; 3'd1: font_row = 5'b10000;
                3'd2: font_row = 5'b10000; 3'd3: font_row = 5'b10000;
                3'd4: font_row = 5'b10000; 3'd5: font_row = 5'b10000;
                3'd6: font_row = 5'b11111; default: font_row = 5'b00000;
            endcase
            CH_N: case (row)
                3'd0: font_row = 5'b10001; 3'd1: font_row = 5'b11001;
                3'd2: font_row = 5'b10101; 3'd3: font_row = 5'b10011;
                3'd4: font_row = 5'b10001; 3'd5: font_row = 5'b10001;
                3'd6: font_row = 5'b10001; default: font_row = 5'b00000;
            endcase
            CH_O: case (row)
                3'd0: font_row = 5'b01110; 3'd1: font_row = 5'b10001;
                3'd2: font_row = 5'b10001; 3'd3: font_row = 5'b10001;
                3'd4: font_row = 5'b10001; 3'd5: font_row = 5'b10001;
                3'd6: font_row = 5'b01110; default: font_row = 5'b00000;
            endcase
            CH_R: case (row)
                3'd0: font_row = 5'b11110; 3'd1: font_row = 5'b10001;
                3'd2: font_row = 5'b10001; 3'd3: font_row = 5'b11110;
                3'd4: font_row = 5'b10100; 3'd5: font_row = 5'b10010;
                3'd6: font_row = 5'b10001; default: font_row = 5'b00000;
            endcase
            CH_S: case (row)
                3'd0: font_row = 5'b01110; 3'd1: font_row = 5'b10001;
                3'd2: font_row = 5'b10000; 3'd3: font_row = 5'b01110;
                3'd4: font_row = 5'b00001; 3'd5: font_row = 5'b10001;
                3'd6: font_row = 5'b01110; default: font_row = 5'b00000;
            endcase
            CH_T: case (row)
                3'd0: font_row = 5'b11111; 3'd1: font_row = 5'b00100;
                3'd2: font_row = 5'b00100; 3'd3: font_row = 5'b00100;
                3'd4: font_row = 5'b00100; 3'd5: font_row = 5'b00100;
                3'd6: font_row = 5'b00100; default: font_row = 5'b00000;
            endcase
            CH_W: case (row)
                3'd0: font_row = 5'b10001; 3'd1: font_row = 5'b10001;
                3'd2: font_row = 5'b10001; 3'd3: font_row = 5'b10101;
                3'd4: font_row = 5'b10101; 3'd5: font_row = 5'b01010;
                3'd6: font_row = 5'b01010; default: font_row = 5'b00000;
            endcase
            default: font_row = 5'b00000;
            endcase
        end
    endfunction

    // Returns 1 if pixel at (frow, fcol) is lit for character ch
    function font_pixel;
        input [3:0] ch;
        input [2:0] frow;
        input [2:0] fcol;
        begin
            font_pixel = font_row(ch, frow)[3'd4 - fcol];
        end
    endfunction

    // ================================================================
    //  Text hit-test: check if current px/py falls on any text pixel.
    //  4× scale: each font dot = 4×4 screen pixels.
    //  Character is 20px wide, 28px tall, 4px gap = 24px stride.
    // ================================================================
    localparam FPW = 10'd20;  // font pixel width  (5 * 4)
    localparam FPH = 10'd28;  // font pixel height  (7 * 4)

    // "START" character x-positions  (total width 116, centered at 262)
    localparam S0_X = 10'd262;  // S
    localparam S1_X = 10'd286;  // T
    localparam S2_X = 10'd310;  // A
    localparam S3_X = 10'd334;  // R
    localparam S4_X = 10'd358;  // T
    localparam START_Y = 10'd200;

    // "WIN" character x-positions  (total width 68, centered at 286)
    localparam W0_X = 10'd286;  // W
    localparam W1_X = 10'd310;  // I
    localparam W2_X = 10'd334;  // N
    localparam WIN_Y = 10'd180;

    // "LOSE" character x-positions (total width 92, centered at 274)
    localparam L0_X = 10'd274;  // L
    localparam L1_X = 10'd298;  // O
    localparam L2_X = 10'd322;  // S
    localparam L3_X = 10'd346;  // E
    localparam LOSE_Y = 10'd180;

    // Restart prompt box (below text)
    localparam RESTART_BOX_X = 10'd270;
    localparam RESTART_BOX_W = 10'd100;
    localparam RESTART_BOX_Y = 10'd260;
    localparam RESTART_BOX_H = 10'd30;

    // Helper: check if px is within [x, x+FPW) and extract font column
    // Returns 1 if hit, sets fcol via output. Scale factor = 4, so >> 2.
    reg        text_on;
    reg [2:0]  text_frow;
    always @(*) begin
        text_on   = 1'b0;
        text_frow = (py >= START_Y) ? (py - START_Y) >> 2 :
                    (py >= WIN_Y)   ? (py - WIN_Y)   >> 2 : 3'd0;

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

    // Restart box region
    wire in_restart_box = (px >= RESTART_BOX_X) &&
                          (px <  RESTART_BOX_X + RESTART_BOX_W) &&
                          (py >= RESTART_BOX_Y) &&
                          (py <  RESTART_BOX_Y + RESTART_BOX_H);
    wire restart_border = in_restart_box &&
                          (px < RESTART_BOX_X + 10'd3 ||
                           px >= RESTART_BOX_X + RESTART_BOX_W - 10'd3 ||
                           py < RESTART_BOX_Y + 10'd3 ||
                           py >= RESTART_BOX_Y + RESTART_BOX_H - 10'd3);

    // ================================================================
    //  Animation state machine  (tick counters instead of modulo)
    // ================================================================
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

    // Dedicated tick counters (no modulo)
    reg [23:0] anim_tick_cnt;
    reg        anim_tick;
    reg [23:0] shake_tick_cnt;
    reg        shake_tick;

    // UI flash counter (~3 Hz)
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

    // Tick generators
    always @(posedge clk) begin
        flash_cnt <= flash_cnt + 25'd1;

        if (anim_tick_cnt >= ANIM_TICK_MAX - 1) begin
            anim_tick_cnt <= 0;
            anim_tick <= 1;
        end else begin
            anim_tick_cnt <= anim_tick_cnt + 1;
            anim_tick <= 0;
        end

        if (shake_tick_cnt >= SHAKE_TICK_MAX - 1) begin
            shake_tick_cnt <= 0;
            shake_tick <= 1;
        end else begin
            shake_tick_cnt <= shake_tick_cnt + 1;
            shake_tick <= 0;
        end
    end

    // Animation FSM
    always @(posedge clk) begin
        anim_done <= 0;

        case (anim_state)
        A_IDLE: begin
            p1_x <= P1_HOME_X; p1_y <= P1_HOME_Y;
            p2_x <= P2_HOME_X; p2_y <= P2_HOME_Y;
            p1_flash <= 0; p2_flash <= 0;
            shake_counter <= 0;

            if (trigger_player_atk) begin
                attacking_is_p1 <= 1;
                anim_state <= A_LUNGE;
            end else if (trigger_cpu_atk) begin
                attacking_is_p1 <= 0;
                anim_state <= A_LUNGE;
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
                        anim_state <= A_HIT1;
                        shake_counter <= 0;
                        p2_flash <= 1;
                    end
                end else begin
                    if (p2_x < P2_HOME_X) p2_x <= p2_x + LUNGE_SPEED;
                    else                   p2_x <= P2_HOME_X;
                    if (p2_y > P2_HOME_Y) p2_y <= p2_y - LUNGE_SPEED;
                    else                   p2_y <= P2_HOME_Y;
                    if (p2_x >= P2_HOME_X && p2_y <= P2_HOME_Y) begin
                        anim_state <= A_HIT1;
                        shake_counter <= 0;
                        p1_flash <= 1;
                    end
                end
            end
        end

        A_HIT1: begin
            if (shake_tick) begin
                shake_counter <= shake_counter + 1;
                if (attacking_is_p1) begin
                    p2_flash <= ~p2_flash;
                    p2_x <= shake_counter[0] ? (P2_HOME_X + 10'd4)
                                             : (P2_HOME_X - 10'd4);
                end else begin
                    p1_flash <= ~p1_flash;
                    p1_x <= shake_counter[0] ? (P1_HOME_X + 10'd4)
                                             : (P1_HOME_X - 10'd4);
                end
                if (shake_counter >= 4'd4) begin
                    anim_state <= A_HIT2;
                    shake_counter <= 0;
                end
            end
        end

        A_HIT2: begin
            if (shake_tick) begin
                shake_counter <= shake_counter + 1;
                if (attacking_is_p1) begin
                    p2_flash <= ~p2_flash;
                    p2_x <= shake_counter[0] ? (P2_HOME_X - 10'd4)
                                             : (P2_HOME_X + 10'd4);
                end else begin
                    p1_flash <= ~p1_flash;
                    p1_x <= shake_counter[0] ? (P1_HOME_X - 10'd4)
                                             : (P1_HOME_X + 10'd4);
                end
                if (shake_counter >= 4'd4) begin
                    anim_state <= A_DONE;
                    p1_flash <= 0; p2_flash <= 0;
                    p1_x <= P1_HOME_X; p2_x <= P2_HOME_X;
                end
            end
        end

        A_DONE: begin
            anim_done <= 1;
            anim_state <= A_IDLE;
        end
        endcase
    end

    // ================================================================
    //  Sprite region checks
    // ================================================================
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

    // ================================================================
    //  HP bars  (division-free: compare offset*max vs cur*width)
    // ================================================================
    wire [9:0] hp_dx_p = px - P1_HP_X;
    wire [9:0] hp_dx_c = px - P2_HP_X;

    wire in_p1_hp_border = (px >= P1_HP_X - 10'd2) && (px < P1_HP_X + HP_BAR_W + 10'd2)
                         && (py >= P1_HP_Y - 10'd2) && (py < P1_HP_Y + HP_BAR_H + 10'd2);
    wire in_p1_hp_bg     = (px >= P1_HP_X) && (px < P1_HP_X + HP_BAR_W)
                         && (py >= P1_HP_Y) && (py < P1_HP_Y + HP_BAR_H);
    wire in_p1_hp_fill   = in_p1_hp_bg && (player_hp_max > 0) &&
                           (hp_dx_p * player_hp_max < player_hp_cur * HP_BAR_W);

    wire in_p2_hp_border = (px >= P2_HP_X - 10'd2) && (px < P2_HP_X + HP_BAR_W + 10'd2)
                         && (py >= P2_HP_Y - 10'd2) && (py < P2_HP_Y + HP_BAR_H + 10'd2);
    wire in_p2_hp_bg     = (px >= P2_HP_X) && (px < P2_HP_X + HP_BAR_W)
                         && (py >= P2_HP_Y) && (py < P2_HP_Y + HP_BAR_H);
    wire in_p2_hp_fill   = in_p2_hp_bg && (cpu_hp_max > 0) &&
                           (hp_dx_c * cpu_hp_max < cpu_hp_cur * HP_BAR_W);

    // HP color: >50% green, >25% yellow, else red
    wire p1_green  = ({player_hp_cur, 1'b0} > player_hp_max);
    wire p1_yellow = ({player_hp_cur, 2'b00} > player_hp_max);
    wire [11:0] p1_hp_color = p1_green ? HP_GREEN : (p1_yellow ? HP_YELLOW : HP_RED);

    wire p2_green  = ({cpu_hp_cur, 1'b0} > cpu_hp_max);
    wire p2_yellow = ({cpu_hp_cur, 2'b00} > cpu_hp_max);
    wire [11:0] p2_hp_color = p2_green ? HP_GREEN : (p2_yellow ? HP_YELLOW : HP_RED);

    // ================================================================
    //  Menu box rendering
    // ================================================================
    wire [9:0] box0_x = 10'd30;
    wire [9:0] box1_x = 10'd180;
    wire [9:0] box2_x = 10'd330;
    wire [9:0] box3_x = 10'd480;
    localparam BOX_W = 10'd140;

    wire in_menu_area = (py >= MENU_Y) && (py < MENU_Y + MENU_H);

    wire in_box0 = in_menu_area && (px >= box0_x) && (px < box0_x + BOX_W);
    wire in_box1 = in_menu_area && (px >= box1_x) && (px < box1_x + BOX_W);
    wire in_box2 = in_menu_area && (px >= box2_x) && (px < box2_x + BOX_W);
    wire in_box3 = in_menu_area && (px >= box3_x) && (px < box3_x + BOX_W);

    wire box0_border = in_box0 && (px < box0_x + 10'd3 || px >= box0_x + BOX_W - 10'd3 ||
                                   py < MENU_Y + 10'd3 || py >= MENU_Y + MENU_H - 10'd3);
    wire box1_border = in_box1 && (px < box1_x + 10'd3 || px >= box1_x + BOX_W - 10'd3 ||
                                   py < MENU_Y + 10'd3 || py >= MENU_Y + MENU_H - 10'd3);
    wire box2_border = in_box2 && (px < box2_x + 10'd3 || px >= box2_x + BOX_W - 10'd3 ||
                                   py < MENU_Y + 10'd3 || py >= MENU_Y + MENU_H - 10'd3);
    wire box3_border = in_box3 && (px < box3_x + 10'd3 || px >= box3_x + BOX_W - 10'd3 ||
                                   py < MENU_Y + 10'd3 || py >= MENU_Y + MENU_H - 10'd3);

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
        end

        default: menu_active = 0;
        endcase
    end

    // ================================================================
    //  Battle-state flag
    // ================================================================
    wire in_battle = (game_state != S_START) && (game_state != S_END);

    // ================================================================
    //  Pixel priority encoder
    // ================================================================
    always @(*) begin
        if (~bright) begin
            rgb = BLACK;

        // ---------- START screen ----------
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

        // ---------- END screen ----------
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

        // ---------- Battle states ----------
        // Layer 1: HP bars
        end else if (in_p1_hp_border) begin
            if (in_p1_hp_fill)       rgb = p1_hp_color;
            else if (in_p1_hp_bg)    rgb = DARK_GRAY;
            else                     rgb = WHITE;

        end else if (in_p2_hp_border) begin
            if (in_p2_hp_fill)       rgb = p2_hp_color;
            else if (in_p2_hp_bg)    rgb = DARK_GRAY;
            else                     rgb = WHITE;

        // Layer 2: Menu UI
        end else if (menu_active) begin
            rgb = menu_pixel;

        // Layer 3: Player sprite
        end else if (in_p1 && !p_sprite_transparent) begin
            rgb = p1_flash ? RED : p_sprite_color;

        // Layer 4: CPU sprite
        end else if (in_p2 && !c_sprite_transparent) begin
            rgb = p2_flash ? RED : c_sprite_color;

        // Layer 5: Background
        end else begin
            rgb = bg_color;
        end
    end

endmodule
