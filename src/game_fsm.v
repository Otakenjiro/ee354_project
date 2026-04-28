`timescale 1ns / 1ps

module game_fsm (
    input wire clk,
    input wire rst,

    input wire btn_c,
    input wire btn_u,
    input wire btn_d,
    input wire btn_l,

    input wire [15:0] rng,

    input wire [9:0] p_max_hp,
    input wire [8:0] p_atk, p_def, p_spd,
    input wire [3:0] p_type1, p_type2,
    input wire [4:0] p_move0, p_move1, p_move2, p_move3,

    input wire [9:0] c_max_hp,
    input wire [8:0] c_atk, c_def, c_spd,
    input wire [3:0] c_type1, c_type2,
    input wire [4:0] c_move0, c_move1, c_move2, c_move3,

    input wire [9:0] calc_damage,

    input wire [12:0] move_data,

    input wire anim_done,

    output wire [2:0] player_active_id,
    output wire [2:0] cpu_active_id,

    output reg [4:0] move_id,

    output reg [8:0]  be_atk,
    output reg [7:0]  be_power,
    output reg [3:0]  be_move_type,
    output reg [8:0]  be_def,
    output reg [3:0]  be_def_type1,
    output reg [3:0]  be_def_type2,
    output reg [3:0]  be_rng,
    output reg        be_is_status,

    output reg [3:0]  game_state,
    output reg [1:0]  cursor_pos,
    output reg [9:0]  player_hp_cur,
    output reg [9:0]  player_hp_max,
    output reg [9:0]  cpu_hp_cur,
    output reg [9:0]  cpu_hp_max,
    output reg        trigger_player_atk,
    output reg        trigger_cpu_atk,
    output reg        user_won,

    output wire [9:0] p_hp0, p_hp1, p_hp2,
    output wire [9:0] c_hp0, c_hp1, c_hp2,
    output wire [1:0] p_active_idx, c_active_idx
);

    localparam S_START       = 4'd0;
    localparam S_IDLE        = 4'd1;
    localparam S_FIGHT_SEL   = 4'd2;
    localparam S_SWITCH_SEL  = 4'd3;
    localparam S_CPU_THINK   = 4'd4;
    localparam S_TURN_EXEC   = 4'd5;
    localparam S_ANIM1       = 4'd6;
    localparam S_APPLY1      = 4'd7;
    localparam S_ANIM2       = 4'd8;
    localparam S_APPLY2      = 4'd9;
    localparam S_CHECK       = 4'd10;
    localparam S_END         = 4'd11;

    localparam [2:0] PT0 = 3'd1, PT1 = 3'd2, PT2 = 3'd3;
    localparam [2:0] CT0 = 3'd4, CT1 = 3'd5, CT2 = 3'd6;

    reg [1:0] p_active, c_active;
    assign p_active_idx = p_active;
    assign c_active_idx = c_active;

    assign player_active_id = (p_active == 2'd0) ? PT0 :
                              (p_active == 2'd1) ? PT1 : PT2;
    assign cpu_active_id    = (c_active == 2'd0) ? CT0 :
                              (c_active == 2'd1) ? CT1 : CT2;

    reg [9:0] p_hp [0:2];
    reg [9:0] c_hp [0:2];
    assign p_hp0 = p_hp[0]; assign p_hp1 = p_hp[1]; assign p_hp2 = p_hp[2];
    assign c_hp0 = c_hp[0]; assign c_hp1 = c_hp[1]; assign c_hp2 = c_hp[2];

    reg        player_fights;
    reg [1:0]  player_move_sel;
    reg [1:0]  player_switch_to;

    reg        cpu_fights;
    reg [1:0]  cpu_move_sel;

    reg        first_is_player;
    reg        phase2_needed;
    reg [1:0]  turn_phase;

    reg btn_c_prev, btn_u_prev, btn_d_prev, btn_l_prev;
    wire btn_c_rise = btn_c & ~btn_c_prev;
    wire btn_u_rise = btn_u & ~btn_u_prev;
    wire btn_d_rise = btn_d & ~btn_d_prev;
    wire btn_l_rise = btn_l & ~btn_l_prev;

    reg [3:0] apply_delay;

    reg current_is_player;

    reg [4:0] selected_p_move;
    always @(*) begin
        case (player_move_sel)
            2'd0: selected_p_move = p_move0;
            2'd1: selected_p_move = p_move1;
            2'd2: selected_p_move = p_move2;
            2'd3: selected_p_move = p_move3;
        endcase
    end
    reg [4:0] selected_c_move;
    always @(*) begin
        case (cpu_move_sel)
            2'd0: selected_c_move = c_move0;
            2'd1: selected_c_move = c_move1;
            2'd2: selected_c_move = c_move2;
            2'd3: selected_c_move = c_move3;
        endcase
    end

    wire [3:0] mv_type   = move_data[12:9];
    wire [7:0] mv_power  = move_data[0] ? 8'd0 : move_data[8:1];
    wire       mv_status = move_data[0];

    wire [1:0] p_next1 = (p_active == 2'd2) ? 2'd0 : p_active + 2'd1;
    wire [1:0] p_next2 = (p_active == 2'd0) ? 2'd2 : p_active - 2'd1;
    wire [1:0] c_next1 = (c_active == 2'd2) ? 2'd0 : c_active + 2'd1;
    wire [1:0] c_next2 = (c_active == 2'd0) ? 2'd2 : c_active - 2'd1;

    reg [9:0] p_hp_active, p_hp_n1, p_hp_n2;
    reg [9:0] c_hp_active, c_hp_next1, c_hp_next2;
    always @(*) begin
        case (p_active)
            2'd0: p_hp_active = p_hp[0];
            2'd1: p_hp_active = p_hp[1];
            default: p_hp_active = p_hp[2];
        endcase
        case (p_next1)
            2'd0: p_hp_n1 = p_hp[0];
            2'd1: p_hp_n1 = p_hp[1];
            default: p_hp_n1 = p_hp[2];
        endcase
        case (p_next2)
            2'd0: p_hp_n2 = p_hp[0];
            2'd1: p_hp_n2 = p_hp[1];
            default: p_hp_n2 = p_hp[2];
        endcase
        case (c_active)
            2'd0: c_hp_active = c_hp[0];
            2'd1: c_hp_active = c_hp[1];
            default: c_hp_active = c_hp[2];
        endcase
        case (c_next1)
            2'd0: c_hp_next1 = c_hp[0];
            2'd1: c_hp_next1 = c_hp[1];
            default: c_hp_next1 = c_hp[2];
        endcase
        case (c_next2)
            2'd0: c_hp_next2 = c_hp[0];
            2'd1: c_hp_next2 = c_hp[1];
            default: c_hp_next2 = c_hp[2];
        endcase
    end

    reg [1:0] cpu_next_alive;
    always @(*) begin
        if (c_hp_next1 > 0)
            cpu_next_alive = c_next1;
        else if (c_hp_next2 > 0)
            cpu_next_alive = c_next2;
        else
            cpu_next_alive = c_active;
    end

    wire player_all_fainted = (p_hp[0] == 0) && (p_hp[1] == 0) && (p_hp[2] == 0);
    wire cpu_all_fainted    = (c_hp[0] == 0) && (c_hp[1] == 0) && (c_hp[2] == 0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            game_state <= S_START;
            p_active <= 0; c_active <= 0;
            cursor_pos <= 0;
            trigger_player_atk <= 0;
            trigger_cpu_atk <= 0;
            user_won <= 0;
            btn_c_prev <= 0; btn_u_prev <= 0;
            btn_d_prev <= 0; btn_l_prev <= 0;
            apply_delay <= 0;
            p_hp[0] <= 0; p_hp[1] <= 0; p_hp[2] <= 0;
            c_hp[0] <= 0; c_hp[1] <= 0; c_hp[2] <= 0;
            be_atk <= 0; be_def <= 0; be_power <= 0;
            be_move_type <= 0; be_def_type1 <= 0; be_def_type2 <= 0;
            be_rng <= 0; be_is_status <= 1;
            move_id <= 0;
        end else begin
            btn_c_prev <= btn_c;
            btn_u_prev <= btn_u;
            btn_d_prev <= btn_d;
            btn_l_prev <= btn_l;

            trigger_player_atk <= 0;
            trigger_cpu_atk <= 0;

            case (game_state)

            S_START: begin
                cursor_pos <= 0;
                p_active <= 0;
                c_active <= 0;
                user_won <= 0;
                if (btn_c_rise) begin
                    game_state <= S_IDLE;
                    p_hp[0] <= 10'd138;
                    p_hp[1] <= 10'd140;
                    p_hp[2] <= 10'd139;
                    c_hp[0] <= 10'd150;
                    c_hp[1] <= 10'd150;
                    c_hp[2] <= 10'd150;
                end
            end

            S_IDLE: begin
                if (btn_u_rise || btn_d_rise)
                    cursor_pos <= cursor_pos[0] ? 2'd0 : 2'd1;
                if (btn_c_rise) begin
                    if (cursor_pos == 2'd0) begin
                        game_state <= S_FIGHT_SEL;
                        cursor_pos <= 0;
                    end else begin
                        game_state <= S_SWITCH_SEL;
                        cursor_pos <= 0;
                    end
                end
            end

            S_FIGHT_SEL: begin
                if (btn_d_rise)
                    cursor_pos <= (cursor_pos == 2'd3) ? 2'd0 : cursor_pos + 2'd1;
                if (btn_u_rise)
                    cursor_pos <= (cursor_pos == 2'd0) ? 2'd3 : cursor_pos - 2'd1;
                if (btn_l_rise) begin
                    game_state <= S_IDLE;
                    cursor_pos <= 0;
                end
                if (btn_c_rise) begin
                    player_fights <= 1;
                    player_move_sel <= cursor_pos;
                    game_state <= S_CPU_THINK;
                end
            end

            S_SWITCH_SEL: begin
                if (btn_d_rise)
                    cursor_pos <= (cursor_pos == 2'd3) ? 2'd0 : cursor_pos + 2'd1;
                if (btn_u_rise)
                    cursor_pos <= (cursor_pos == 2'd0) ? 2'd3 : cursor_pos - 2'd1;
                if (btn_l_rise) begin
                    game_state <= S_IDLE;
                    cursor_pos <= 0;
                end
                if (btn_c_rise) begin
                    if (cursor_pos == 2'd3) begin
                        game_state <= S_IDLE;
                        cursor_pos <= 0;
                    end else if (cursor_pos != p_active && (
                        (cursor_pos == 2'd0 && p_hp[0] > 0) ||
                        (cursor_pos == 2'd1 && p_hp[1] > 0) ||
                        (cursor_pos == 2'd2 && p_hp[2] > 0)
                    )) begin
                        player_fights <= 0;
                        player_switch_to <= cursor_pos;
                        game_state <= S_CPU_THINK;
                    end
                end
            end

            S_CPU_THINK: begin
                if (rng[3:0] < 4'd2 && cpu_next_alive != c_active) begin
                    cpu_fights <= 0;
                end else begin
                    cpu_fights <= 1;
                    cpu_move_sel <= rng[5:4];
                end
                game_state <= S_TURN_EXEC;
            end

            S_TURN_EXEC: begin
                if (!player_fights && cpu_fights) begin
                    p_active <= player_switch_to;
                    first_is_player <= 0;
                    phase2_needed <= 0;
                end else if (player_fights && !cpu_fights) begin
                    c_active <= cpu_next_alive;
                    first_is_player <= 1;
                    phase2_needed <= 0;
                end else if (!player_fights && !cpu_fights) begin
                    p_active <= player_switch_to;
                    c_active <= cpu_next_alive;
                    first_is_player <= 1;
                    phase2_needed <= 0;
                end else begin
                    first_is_player <= (p_spd >= c_spd) ? 1'b1 : 1'b0;
                    phase2_needed <= 1;
                end
                turn_phase <= 0;
                game_state <= S_ANIM1;
            end

            S_ANIM1: begin
                if (turn_phase == 0) begin
                    if (!player_fights && !cpu_fights) begin
                        game_state <= S_CHECK;
                    end else begin
                        if (first_is_player)
                            trigger_player_atk <= 1;
                        else
                            trigger_cpu_atk <= 1;
                        current_is_player <= first_is_player;
                        turn_phase <= 1;
                    end
                end else begin
                    if (anim_done) begin
                        game_state <= S_APPLY1;
                        apply_delay <= 0;
                    end
                end
            end

            S_APPLY1: begin
                apply_delay <= apply_delay + 1;

                if (apply_delay == 4'd1) begin
                    if (current_is_player) begin
                        be_atk      <= p_atk;
                        be_def      <= c_def;
                        be_def_type1 <= c_type1;
                        be_def_type2 <= c_type2;
                        move_id     <= selected_p_move;
                    end else begin
                        be_atk      <= c_atk;
                        be_def      <= p_def;
                        be_def_type1 <= p_type1;
                        be_def_type2 <= p_type2;
                        move_id     <= selected_c_move;
                    end
                    be_rng <= rng[7:4];
                end

                if (apply_delay == 4'd3) begin
                    be_power     <= mv_power;
                    be_move_type <= mv_type;
                    be_is_status <= mv_status;
                end

                if (apply_delay == 4'd10) begin
                    if (current_is_player) begin
                        case (c_active)
                            2'd0: c_hp[0] <= (calc_damage >= c_hp[0]) ? 10'd0 : c_hp[0] - calc_damage;
                            2'd1: c_hp[1] <= (calc_damage >= c_hp[1]) ? 10'd0 : c_hp[1] - calc_damage;
                            2'd2: c_hp[2] <= (calc_damage >= c_hp[2]) ? 10'd0 : c_hp[2] - calc_damage;
                        endcase
                    end else begin
                        case (p_active)
                            2'd0: p_hp[0] <= (calc_damage >= p_hp[0]) ? 10'd0 : p_hp[0] - calc_damage;
                            2'd1: p_hp[1] <= (calc_damage >= p_hp[1]) ? 10'd0 : p_hp[1] - calc_damage;
                            2'd2: p_hp[2] <= (calc_damage >= p_hp[2]) ? 10'd0 : p_hp[2] - calc_damage;
                        endcase
                    end

                    if (phase2_needed) begin
                        game_state <= S_ANIM2;
                        turn_phase <= 0;
                    end else begin
                        game_state <= S_CHECK;
                    end
                end
            end

            S_ANIM2: begin
                if (turn_phase == 0) begin
                    if (!first_is_player)
                        trigger_player_atk <= 1;
                    else
                        trigger_cpu_atk <= 1;
                    current_is_player <= !first_is_player;
                    turn_phase <= 1;
                end else begin
                    if (anim_done) begin
                        game_state <= S_APPLY2;
                        apply_delay <= 0;
                    end
                end
            end

            S_APPLY2: begin
                apply_delay <= apply_delay + 1;

                if (apply_delay == 4'd1) begin
                    if (current_is_player) begin
                        be_atk       <= p_atk;
                        be_def       <= c_def;
                        be_def_type1 <= c_type1;
                        be_def_type2 <= c_type2;
                        move_id      <= selected_p_move;
                    end else begin
                        be_atk       <= c_atk;
                        be_def       <= p_def;
                        be_def_type1 <= p_type1;
                        be_def_type2 <= p_type2;
                        move_id      <= selected_c_move;
                    end
                    be_rng <= rng[11:8];
                end

                if (apply_delay == 4'd3) begin
                    be_power     <= mv_power;
                    be_move_type <= mv_type;
                    be_is_status <= mv_status;
                end

                if (apply_delay == 4'd10) begin
                    if (current_is_player) begin
                        case (c_active)
                            2'd0: c_hp[0] <= (calc_damage >= c_hp[0]) ? 10'd0 : c_hp[0] - calc_damage;
                            2'd1: c_hp[1] <= (calc_damage >= c_hp[1]) ? 10'd0 : c_hp[1] - calc_damage;
                            2'd2: c_hp[2] <= (calc_damage >= c_hp[2]) ? 10'd0 : c_hp[2] - calc_damage;
                        endcase
                    end else begin
                        case (p_active)
                            2'd0: p_hp[0] <= (calc_damage >= p_hp[0]) ? 10'd0 : p_hp[0] - calc_damage;
                            2'd1: p_hp[1] <= (calc_damage >= p_hp[1]) ? 10'd0 : p_hp[1] - calc_damage;
                            2'd2: p_hp[2] <= (calc_damage >= p_hp[2]) ? 10'd0 : p_hp[2] - calc_damage;
                        endcase
                    end
                    game_state <= S_CHECK;
                end
            end

            S_CHECK: begin
                if (cpu_all_fainted) begin
                    user_won <= 1;
                    game_state <= S_END;
                end else if (player_all_fainted) begin
                    user_won <= 0;
                    game_state <= S_END;
                end else begin
                    if (p_hp_active == 0) begin
                        if (p_hp_n1 > 0)
                            p_active <= p_next1;
                        else
                            p_active <= p_next2;
                    end
                    if (c_hp_active == 0) begin
                        if (c_hp_next1 > 0)
                            c_active <= c_next1;
                        else
                            c_active <= c_next2;
                    end
                    cursor_pos <= 0;
                    game_state <= S_IDLE;
                end
            end

            S_END: begin
                if (btn_c_rise)
                    game_state <= S_START;
            end

            endcase

            player_hp_cur <= p_hp_active;
            player_hp_max <= p_max_hp;
            cpu_hp_cur    <= c_hp_active;
            cpu_hp_max    <= c_max_hp;
        end
    end

endmodule
