`timescale 1ns / 1ps

module battle_scene(
    input clk,
    input bright,
    input btnR,
    input [9:0] hCount, vCount,
    output reg [11:0] rgb,
    output reg [6:0] p1_row, p1_col,
    output reg [6:0] p2_row, p2_col,
    input [11:0] p1_color,
    input [11:0] p2_color
);

    localparam SPRITE_SIZE = 10'd80;

    // Player 1 (bottom-left) home position
    localparam P1_HOME_X = 10'd144 + 10'd60;   // ~60px from left edge
    localparam P1_HOME_Y = 10'd35  + 10'd320;   // lower area

    // Player 2 (top-right) home position
    localparam P2_HOME_X = 10'd144 + 10'd500;   // right side
    localparam P2_HOME_Y = 10'd35  + 10'd80;    // upper area

    localparam BLACK       = 12'h000;
    localparam RED_TINT    = 12'hF00;

    // Transparent (background) colors per sprite
    localparam P1_TRANSPARENT = 12'b0000_1111_1010;  // Charizard bg
    localparam P2_TRANSPARENT = 12'b0000_0100_1111;  // Pikachu bg

    // Animation state machine
    localparam STATE_IDLE       = 3'd0;
    localparam STATE_P1_LUNGE   = 3'd1;  // P1 moves toward P2
    localparam STATE_P1_RETURN  = 3'd2;  // P1 returns home
    localparam STATE_P2_HIT1    = 3'd3;  // P2 flash+shake 1
    localparam STATE_P2_HIT2    = 3'd4;  // P2 flash+shake 2
    localparam STATE_COOLDOWN   = 3'd5;

    reg [2:0] state;
    reg [9:0] p1_x, p1_y;
    reg [9:0] p2_x, p2_y;
    reg [23:0] anim_timer;
    reg [3:0] shake_counter;
    reg flash_red;
    reg btnR_prev;

    // Speed divider for animation (controls how fast sprites move)
    localparam ANIM_TICK = 24'd150000;  // ~60 fps at 100MHz/4
    localparam SHAKE_TICK = 24'd500000;
    localparam LUNGE_SPEED = 10'd4;

    // Target position for lunge (near P2)
    wire [9:0] lunge_target_x = P2_HOME_X - SPRITE_SIZE;
    wire [9:0] lunge_target_y = P2_HOME_Y + SPRITE_SIZE - 10'd20;

    initial begin
        state = STATE_IDLE;
        p1_x = P1_HOME_X;
        p1_y = P1_HOME_Y;
        p2_x = P2_HOME_X;
        p2_y = P2_HOME_Y;
        anim_timer = 0;
        shake_counter = 0;
        flash_red = 0;
        btnR_prev = 0;
    end

    // Edge detect on btnR
    wire btnR_rising = btnR & ~btnR_prev;

    always @(posedge clk) begin
        btnR_prev <= btnR;
        anim_timer <= anim_timer + 1;

        case (state)
            STATE_IDLE: begin
                p1_x <= P1_HOME_X;
                p1_y <= P1_HOME_Y;
                p2_x <= P2_HOME_X;
                p2_y <= P2_HOME_Y;
                flash_red <= 0;
                shake_counter <= 0;
                if (btnR_rising)
                    state <= STATE_P1_LUNGE;
            end

            STATE_P1_LUNGE: begin
                if (anim_timer % ANIM_TICK == 0) begin
                    if (p1_x < lunge_target_x)
                        p1_x <= p1_x + LUNGE_SPEED;
                    else if (p1_x > lunge_target_x)
                        p1_x <= lunge_target_x;

                    if (p1_y > lunge_target_y)
                        p1_y <= p1_y - LUNGE_SPEED;
                    else if (p1_y < lunge_target_y)
                        p1_y <= lunge_target_y;

                    if (p1_x >= lunge_target_x && p1_y <= lunge_target_y) begin
                        state <= STATE_P1_RETURN;
                    end
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
                        flash_red <= 1;
                    end
                end
            end

            STATE_P2_HIT1: begin
                if (anim_timer % SHAKE_TICK == 0) begin
                    shake_counter <= shake_counter + 1;
                    flash_red <= ~flash_red;
                    // Shake P2 left/right
                    if (shake_counter[0])
                        p2_x <= P2_HOME_X + 10'd4;
                    else
                        p2_x <= P2_HOME_X - 10'd4;

                    if (shake_counter >= 4'd4) begin
                        state <= STATE_P2_HIT2;
                        shake_counter <= 0;
                        flash_red <= 1;
                    end
                end
            end

            STATE_P2_HIT2: begin
                if (anim_timer % SHAKE_TICK == 0) begin
                    shake_counter <= shake_counter + 1;
                    flash_red <= ~flash_red;
                    if (shake_counter[0])
                        p2_x <= P2_HOME_X - 10'd4;
                    else
                        p2_x <= P2_HOME_X + 10'd4;

                    if (shake_counter >= 4'd4) begin
                        state <= STATE_COOLDOWN;
                        anim_timer <= 0;
                        flash_red <= 0;
                        p2_x <= P2_HOME_X;
                    end
                end
            end

            STATE_COOLDOWN: begin
                p2_x <= P2_HOME_X;
                flash_red <= 0;
                if (anim_timer >= 24'd5000000)
                    state <= STATE_IDLE;
            end
        endcase
    end

    // Sprite region checks
    wire in_p1 = (hCount >= p1_x) && (hCount < p1_x + SPRITE_SIZE)
              && (vCount >= p1_y) && (vCount < p1_y + SPRITE_SIZE);

    wire in_p2 = (hCount >= p2_x) && (hCount < p2_x + SPRITE_SIZE)
              && (vCount >= p2_y) && (vCount < p2_y + SPRITE_SIZE);

    // Compute ROM addresses
    always @(*) begin
        p1_row = (vCount - p1_y);
        p1_col = (hCount - p1_x);
        p2_row = (vCount - p2_y);
        p2_col = (hCount - p2_x);
    end

    // Pixel output mux
    always @(*) begin
        if (~bright) begin
            rgb = BLACK;
        end else if (in_p1 && p1_color != P1_TRANSPARENT) begin
            rgb = p1_color;
        end else if (in_p2 && p2_color != P2_TRANSPARENT) begin
            if (flash_red)
                rgb = RED_TINT;
            else
                rgb = p2_color;
        end else begin
            rgb = BLACK;
        end
    end

endmodule
