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

    wire btn_c, btn_u, btn_d, btn_l, btn_r;

    btn_debounce db_c(.clk(ClkPort), .btn_in(BtnC), .btn_out(btn_c));
    btn_debounce db_u(.clk(ClkPort), .btn_in(BtnU), .btn_out(btn_u));
    btn_debounce db_d(.clk(ClkPort), .btn_in(BtnD), .btn_out(btn_d));
    btn_debounce db_l(.clk(ClkPort), .btn_in(BtnL), .btn_out(btn_l));
    btn_debounce db_r(.clk(ClkPort), .btn_in(BtnR), .btn_out(btn_r));

    wire sys_rst;
    reset_sync rst_sync(
        .clk(ClkPort),
        .async_rst_in(btn_r),
        .sync_rst_out(sys_rst)
    );

    wire bright;
    wire [9:0] hc, vc;
    display_controller dc(
        .clk(ClkPort),
        .hSync(hSync), .vSync(vSync),
        .bright(bright),
        .hCount(hc), .vCount(vc)
    );

    wire [9:0] px = hc - 10'd144;
    wire [8:0] py = vc - 10'd35;

    wire [11:0] bg_color;
    battle_rom bg_rom(
        .clk(ClkPort),
        .row(py),
        .col(px),
        .color_data(bg_color)
    );

    wire [15:0] rng;
    lfsr rng_gen(
        .clk(ClkPort),
        .rst(sys_rst),
        .rnd(rng)
    );

    wire [2:0] player_active_id, cpu_active_id;
    wire [3:0] game_state;
    wire [1:0] cursor_pos;
    wire [9:0] player_hp_cur, player_hp_max;
    wire [9:0] cpu_hp_cur, cpu_hp_max;
    wire       trigger_player_atk, trigger_cpu_atk;
    wire       user_won;
    wire       anim_done;
    wire [4:0] move_id;

    wire [8:0] be_atk, be_def;
    wire [7:0] be_power;
    wire [3:0] be_move_type, be_def_type1, be_def_type2;
    wire [3:0] be_rng;
    wire       be_is_status;

    wire [9:0] p_max_hp;
    wire [8:0] p_atk, p_def, p_spd;
    wire [3:0] p_type1, p_type2;
    wire [4:0] p_move0, p_move1, p_move2, p_move3;

    pokemon_stat_rom p_stats(
        .pokemon_id(player_active_id),
        .max_hp(p_max_hp),
        .atk(p_atk), .def_stat(p_def), .spd(p_spd),
        .type1(p_type1), .type2(p_type2),
        .move0(p_move0), .move1(p_move1), .move2(p_move2), .move3(p_move3)
    );

    wire [9:0] c_max_hp;
    wire [8:0] c_atk, c_def, c_spd;
    wire [3:0] c_type1, c_type2;
    wire [4:0] c_move0, c_move1, c_move2, c_move3;

    pokemon_stat_rom c_stats(
        .pokemon_id(cpu_active_id),
        .max_hp(c_max_hp),
        .atk(c_atk), .def_stat(c_def), .spd(c_spd),
        .type1(c_type1), .type2(c_type2),
        .move0(c_move0), .move1(c_move1), .move2(c_move2), .move3(c_move3)
    );

    wire [12:0] move_data;
    move_rom move_lut(
        .move_id(move_id),
        .move_data(move_data)
    );

    wire [9:0] calc_damage;
    wire       calc_super, calc_not_eff, calc_immune;

    battle_engine calc(
        .atk(be_atk),
        .power(be_power),
        .move_type(be_move_type),
        .def_stat(be_def),
        .def_type1(be_def_type1),
        .def_type2(be_def_type2),
        .rng(be_rng),
        .is_status(be_is_status),
        .damage(calc_damage),
        .super_effective(calc_super),
        .not_effective(calc_not_eff),
        .immune(calc_immune)
    );

    wire [9:0] p_hp0, p_hp1, p_hp2, c_hp0, c_hp1, c_hp2;
    wire [1:0] p_active_idx, c_active_idx;

    game_fsm fsm(
        .clk(ClkPort),
        .rst(sys_rst),
        .btn_c(btn_c), .btn_u(btn_u), .btn_d(btn_d), .btn_l(btn_l),
        .rng(rng),
        .p_max_hp(p_max_hp),
        .p_atk(p_atk), .p_def(p_def), .p_spd(p_spd),
        .p_type1(p_type1), .p_type2(p_type2),
        .p_move0(p_move0), .p_move1(p_move1), .p_move2(p_move2), .p_move3(p_move3),
        .c_max_hp(c_max_hp),
        .c_atk(c_atk), .c_def(c_def), .c_spd(c_spd),
        .c_type1(c_type1), .c_type2(c_type2),
        .c_move0(c_move0), .c_move1(c_move1), .c_move2(c_move2), .c_move3(c_move3),
        .calc_damage(calc_damage),
        .move_data(move_data),
        .anim_done(anim_done),
        .player_active_id(player_active_id),
        .cpu_active_id(cpu_active_id),
        .move_id(move_id),
        .be_atk(be_atk), .be_power(be_power), .be_move_type(be_move_type),
        .be_def(be_def), .be_def_type1(be_def_type1), .be_def_type2(be_def_type2),
        .be_rng(be_rng), .be_is_status(be_is_status),
        .game_state(game_state),
        .cursor_pos(cursor_pos),
        .player_hp_cur(player_hp_cur), .player_hp_max(player_hp_max),
        .cpu_hp_cur(cpu_hp_cur), .cpu_hp_max(cpu_hp_max),
        .trigger_player_atk(trigger_player_atk),
        .trigger_cpu_atk(trigger_cpu_atk),
        .user_won(user_won),
        .p_hp0(p_hp0), .p_hp1(p_hp1), .p_hp2(p_hp2),
        .c_hp0(c_hp0), .c_hp1(c_hp1), .c_hp2(c_hp2),
        .p_active_idx(p_active_idx), .c_active_idx(c_active_idx)
    );

    wire [6:0] p_sprite_row, p_sprite_col;
    wire [6:0] c_sprite_row, c_sprite_col;
    wire [11:0] p_sprite_color, c_sprite_color;
    wire p_sprite_transparent, c_sprite_transparent;

    sprite_mux sprites(
        .clk(ClkPort),
        .player_id(player_active_id),
        .cpu_id(cpu_active_id),
        .p_row(p_sprite_row), .p_col(p_sprite_col),
        .c_row(c_sprite_row), .c_col(c_sprite_col),
        .player_color(p_sprite_color),
        .cpu_color(c_sprite_color),
        .player_transparent(p_sprite_transparent),
        .cpu_transparent(c_sprite_transparent)
    );

    wire [11:0] rgb;

    video_mixer display(
        .clk(ClkPort),
        .bright(bright),
        .hCount(hc), .vCount(vc),
        .bg_color(bg_color),
        .p_sprite_row(p_sprite_row), .p_sprite_col(p_sprite_col),
        .c_sprite_row(c_sprite_row), .c_sprite_col(c_sprite_col),
        .p_sprite_color(p_sprite_color),
        .c_sprite_color(c_sprite_color),
        .p_sprite_transparent(p_sprite_transparent),
        .c_sprite_transparent(c_sprite_transparent),
        .game_state(game_state),
        .cursor_pos(cursor_pos),
        .player_hp_cur(player_hp_cur), .player_hp_max(player_hp_max),
        .cpu_hp_cur(cpu_hp_cur), .cpu_hp_max(cpu_hp_max),
        .user_won(user_won),
        .trigger_player_atk(trigger_player_atk),
        .trigger_cpu_atk(trigger_cpu_atk),
        .anim_done(anim_done),
        .p_move0(p_move0), .p_move1(p_move1),
        .p_move2(p_move2), .p_move3(p_move3),
        .p_hp0(p_hp0), .p_hp1(p_hp1), .p_hp2(p_hp2),
        .p_active_idx(p_active_idx),
        .player_active_id(player_active_id),
        .cpu_active_id(cpu_active_id),
        .rgb(rgb)
    );

    assign vgaR = rgb[11:8];
    assign vgaG = rgb[7:4];
    assign vgaB = rgb[3:0];

    assign Dp = 1;
    assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = 7'b1111111;
    assign {An7, An6, An5, An4, An3, An2, An1, An0} = 8'b11111111;

    assign QuadSpiFlashCS = 1'b1;

endmodule
