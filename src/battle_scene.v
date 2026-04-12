`timescale 1ns / 1ps

module battle_scene(
    input clk,
    input bright,
    input btnR,
    input btnL,
    input [9:0] hCount, vCount,
    input [11:0] bg_color,
    output reg [11:0] rgb,
    output reg [6:0] p1_row, p1_col,
    output reg [6:0] p2_row, p2_col,
    input [11:0] p1_color,
    input [11:0] p2_color
);

    localparam SPRITE_SIZE = 10'd80;

    // Player 1 (Charizard, bottom-left) home position
    localparam P1_HOME_X = 10'd144 + 10'd60;
    localparam P1_HOME_Y = 10'd35  + 10'd320;

    // Player 2 (Pikachu, top-right) home position
    localparam P2_HOME_X = 10'd144 + 10'd500;
    localparam P2_HOME_Y = 10'd35  + 10'd80;

    localparam BLACK    = 12'h000;
    localparam RED_TINT = 12'hF00;

    // ----------------------------------------------------------------
    //  Animation parameters & state  (4-bit to hold 10 states)
    // ----------------------------------------------------------------
    localparam STATE_IDLE         = 4'd0;
    localparam STATE_P1_LUNGE     = 4'd1;
    localparam STATE_P1_RETURN    = 4'd2;
    localparam STATE_P2_HIT1      = 4'd3;
    localparam STATE_P2_HIT2      = 4'd4;
    localparam STATE_COOLDOWN     = 4'd5;
    localparam STATE_P2_LUNGE     = 4'd6;
    localparam STATE_P2_RETURN    = 4'd7;
    localparam STATE_P1_HIT1      = 4'd8;
    localparam STATE_P1_HIT2      = 4'd9;

    reg [3:0] state;
    reg [9:0] p1_x, p1_y;
    reg [9:0] p2_x, p2_y;
    reg [23:0] anim_timer;
    reg [3:0] shake_counter;
    reg p1_flash, p2_flash;
    reg btnR_prev, btnL_prev;

    localparam ANIM_TICK   = 24'd150000;
    localparam SHAKE_TICK  = 24'd500000;
    localparam LUNGE_SPEED = 10'd4;

    // P1 lunge target (near P2)
    wire [9:0] p1_lunge_x = P2_HOME_X - SPRITE_SIZE;
    wire [9:0] p1_lunge_y = P2_HOME_Y + SPRITE_SIZE - 10'd20;

    // P2 lunge target (near P1)
    wire [9:0] p2_lunge_x = P1_HOME_X + SPRITE_SIZE;
    wire [9:0] p2_lunge_y = P1_HOME_Y - SPRITE_SIZE + 10'd20;

    initial begin
        state = STATE_IDLE;
        p1_x = P1_HOME_X;
        p1_y = P1_HOME_Y;
        p2_x = P2_HOME_X;
        p2_y = P2_HOME_Y;
        anim_timer = 0;
        shake_counter = 0;
        p1_flash = 0;
        p2_flash = 0;
        btnR_prev = 0;
        btnL_prev = 0;
    end

    wire btnR_rising = btnR & ~btnR_prev;
    wire btnL_rising = btnL & ~btnL_prev;

    // ----------------------------------------------------------------
    //  Animation state machine
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        btnR_prev <= btnR;
        btnL_prev <= btnL;
        anim_timer <= anim_timer + 1;

        case (state)
            // ----- idle: wait for either button -----
            STATE_IDLE: begin
                p1_x <= P1_HOME_X;
                p1_y <= P1_HOME_Y;
                p2_x <= P2_HOME_X;
                p2_y <= P2_HOME_Y;
                p1_flash <= 0;
                p2_flash <= 0;
                shake_counter <= 0;
                if (btnR_rising)
                    state <= STATE_P1_LUNGE;
                else if (btnL_rising)
                    state <= STATE_P2_LUNGE;
            end

            // ===== Charizard attacks (BtnR) =====
            STATE_P1_LUNGE: begin
                if (anim_timer % ANIM_TICK == 0) begin
                    if (p1_x < p1_lunge_x)
                        p1_x <= p1_x + LUNGE_SPEED;
                    else if (p1_x > p1_lunge_x)
                        p1_x <= p1_lunge_x;

                    if (p1_y > p1_lunge_y)
                        p1_y <= p1_y - LUNGE_SPEED;
                    else if (p1_y < p1_lunge_y)
                        p1_y <= p1_lunge_y;

                    if (p1_x >= p1_lunge_x && p1_y <= p1_lunge_y)
                        state <= STATE_P1_RETURN;
                end
            end

            STATE_P1_RETURN: begin
                if (anim_timer % ANIM_TICK == 0) begin
                    if (p1_x > P1_HOME_X)
                        p1_x <= p1_x - LUNGE_SPEED;
                    else if (p1_x < P1_HOME_X)
                        p1_x <= P1_HOME_X;

                    if (p1_y < P1_HOME_Y)
                        p1_y <= p1_y + LUNGE_SPEED;
                    else if (p1_y > P1_HOME_Y)
                        p1_y <= P1_HOME_Y;

                    if (p1_x <= P1_HOME_X && p1_y >= P1_HOME_Y) begin
                        state <= STATE_P2_HIT1;
                        anim_timer <= 0;
                        shake_counter <= 0;
                        p2_flash <= 1;
                    end
                end
            end

            STATE_P2_HIT1: begin
                if (anim_timer % SHAKE_TICK == 0) begin
                    shake_counter <= shake_counter + 1;
                    p2_flash <= ~p2_flash;
                    p2_x <= shake_counter[0] ? (P2_HOME_X + 10'd4)
                                             : (P2_HOME_X - 10'd4);
                    if (shake_counter >= 4'd4) begin
                        state <= STATE_P2_HIT2;
                        shake_counter <= 0;
                        p2_flash <= 1;
                    end
                end
            end

            STATE_P2_HIT2: begin
                if (anim_timer % SHAKE_TICK == 0) begin
                    shake_counter <= shake_counter + 1;
                    p2_flash <= ~p2_flash;
                    p2_x <= shake_counter[0] ? (P2_HOME_X - 10'd4)
                                             : (P2_HOME_X + 10'd4);
                    if (shake_counter >= 4'd4) begin
                        state <= STATE_COOLDOWN;
                        anim_timer <= 0;
                        p2_flash <= 0;
                        p2_x <= P2_HOME_X;
                    end
                end
            end

            // ===== Pikachu attacks (BtnL) =====
            STATE_P2_LUNGE: begin
                if (anim_timer % ANIM_TICK == 0) begin
                    if (p2_x > p2_lunge_x)
                        p2_x <= p2_x - LUNGE_SPEED;
                    else if (p2_x < p2_lunge_x)
                        p2_x <= p2_lunge_x;

                    if (p2_y < p2_lunge_y)
                        p2_y <= p2_y + LUNGE_SPEED;
                    else if (p2_y > p2_lunge_y)
                        p2_y <= p2_lunge_y;

                    if (p2_x <= p2_lunge_x && p2_y >= p2_lunge_y)
                        state <= STATE_P2_RETURN;
                end
            end

            STATE_P2_RETURN: begin
                if (anim_timer % ANIM_TICK == 0) begin
                    if (p2_x < P2_HOME_X)
                        p2_x <= p2_x + LUNGE_SPEED;
                    else if (p2_x > P2_HOME_X)
                        p2_x <= P2_HOME_X;

                    if (p2_y > P2_HOME_Y)
                        p2_y <= p2_y - LUNGE_SPEED;
                    else if (p2_y < P2_HOME_Y)
                        p2_y <= P2_HOME_Y;

                    if (p2_x >= P2_HOME_X && p2_y <= P2_HOME_Y) begin
                        state <= STATE_P1_HIT1;
                        anim_timer <= 0;
                        shake_counter <= 0;
                        p1_flash <= 1;
                    end
                end
            end

            STATE_P1_HIT1: begin
                if (anim_timer % SHAKE_TICK == 0) begin
                    shake_counter <= shake_counter + 1;
                    p1_flash <= ~p1_flash;
                    p1_x <= shake_counter[0] ? (P1_HOME_X + 10'd4)
                                             : (P1_HOME_X - 10'd4);
                    if (shake_counter >= 4'd4) begin
                        state <= STATE_P1_HIT2;
                        shake_counter <= 0;
                        p1_flash <= 1;
                    end
                end
            end

            STATE_P1_HIT2: begin
                if (anim_timer % SHAKE_TICK == 0) begin
                    shake_counter <= shake_counter + 1;
                    p1_flash <= ~p1_flash;
                    p1_x <= shake_counter[0] ? (P1_HOME_X - 10'd4)
                                             : (P1_HOME_X + 10'd4);
                    if (shake_counter >= 4'd4) begin
                        state <= STATE_COOLDOWN;
                        anim_timer <= 0;
                        p1_flash <= 0;
                        p1_x <= P1_HOME_X;
                    end
                end
            end

            // ===== shared cooldown =====
            STATE_COOLDOWN: begin
                p1_x <= P1_HOME_X;
                p2_x <= P2_HOME_X;
                p1_flash <= 0;
                p2_flash <= 0;
                if (anim_timer >= 24'd5000000)
                    state <= STATE_IDLE;
            end
        endcase
    end

    // ----------------------------------------------------------------
    //  Sprite region checks
    // ----------------------------------------------------------------
    wire in_p1 = (hCount >= p1_x) && (hCount < p1_x + SPRITE_SIZE)
              && (vCount >= p1_y) && (vCount < p1_y + SPRITE_SIZE);

    wire in_p2 = (hCount >= p2_x) && (hCount < p2_x + SPRITE_SIZE)
              && (vCount >= p2_y) && (vCount < p2_y + SPRITE_SIZE);

    always @(*) begin
        p1_row = (vCount - p1_y);
        p1_col = (hCount - p1_x);
        p2_row = (vCount - p2_y);
        p2_col = (hCount - p2_x);
    end

    // ----------------------------------------------------------------
    //  Sprite transparency detection
    //  Charizard bg: 0x0FA, 0x0FB, 0x0FC, 0x1FB  (R<=1, G=F, B>=A)
    //  Pikachu  bg: 0x04F, 0x05E, 0x05F, 0x15F   (R<=1, G=4|5, B>=E)
    // ----------------------------------------------------------------
    wire p1_is_bg = (p1_color[11:8] <= 4'h1)
                  && (p1_color[7:4] == 4'hF)
                  && (p1_color[3:0] >= 4'hA);

    wire p2_is_bg = (p2_color[11:8] <= 4'h1)
                  && (p2_color[7:4] == 4'h4 || p2_color[7:4] == 4'h5)
                  && (p2_color[3:0] >= 4'hE);

    // ----------------------------------------------------------------
    //  Pixel output mux
    // ----------------------------------------------------------------
    always @(*) begin
        if (~bright) begin
            rgb = BLACK;
        end else if (in_p1 && !p1_is_bg) begin
            rgb = p1_flash ? RED_TINT : p1_color;
        end else if (in_p2 && !p2_is_bg) begin
            rgb = p2_flash ? RED_TINT : p2_color;
        end else begin
            rgb = bg_color;
        end
    end

endmodule
