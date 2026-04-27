`timescale 1ns / 1ps

// Top-level module wiring the FPGA pins to all internal subsystems
module pokemon_vga_top(
    input ClkPort,                              // 100 MHz board clock
    input BtnC,                                 // confirm / select
    input BtnU,                                 // cursor up
    input BtnD,                                 // cursor down
    input BtnL,                                 // back / cancel
    input BtnR,                                 // reset

    output hSync, vSync,                        // VGA sync signals
    output [3:0] vgaR, vgaG, vgaB,              // 12-bit VGA color out

    output An0, An1, An2, An3, An4, An5, An6, An7,  // 7-seg digit selects (unused)
    output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,      // 7-seg cathodes (unused)

    output QuadSpiFlashCS                       // SPI flash CS, held high to disable
);

    // Button synchronization + debounce
    // 2-FF synchronizer eliminates metastability on async button inputs;
    // debounce counter ignores mechanical bounce
    wire btn_c, btn_u, btn_d, btn_l, btn_r;     // clean 1-cycle pulses

    btn_debounce db_c(.clk(ClkPort), .btn_in(BtnC), .btn_out(btn_c));
    btn_debounce db_u(.clk(ClkPort), .btn_in(BtnU), .btn_out(btn_u));
    btn_debounce db_d(.clk(ClkPort), .btn_in(BtnD), .btn_out(btn_d));
    btn_debounce db_l(.clk(ClkPort), .btn_in(BtnL), .btn_out(btn_l));
    btn_debounce db_r(.clk(ClkPort), .btn_in(BtnR), .btn_out(btn_r));

    // Reset synchronizer
    // Async reset assertion is fine, but de-assertion must be synchronous
    // to the clock to avoid recovery/removal violations
    wire sys_rst;                               // glitch-free system reset
    reset_sync rst_sync(
        .clk(ClkPort),
        .async_rst_in(btn_r),
        .sync_rst_out(sys_rst)
    );

    // VGA timing (single-clock with 25 MHz pixel enable)
    wire bright;                                // high inside active 640x480
    wire [9:0] hc, vc;                          // raw horiz/vert counters
    display_controller dc(
        .clk(ClkPort),
        .hSync(hSync), .vSync(vSync),
        .bright(bright),
        .hCount(hc), .vCount(vc)
    );

    // Pixel coordinates inside the active 640x480 region
    wire [9:0] px = hc - 10'd144;               // 0..639
    wire [8:0] py = vc - 10'd35;                // 0..479

    // Background ROM (battle scene image)
    wire [11:0] bg_color;                       // 12-bit color sampled at (py, px)
    battle_rom bg_rom(
        .clk(ClkPort),
        .row(py),
        .col(px),
        .color_data(bg_color)
    );

    // LFSR pseudo-random number generator (used for damage variance and CPU AI)
    wire [15:0] rng;                            // free-running random bits
    lfsr rng_gen(
        .clk(ClkPort),
        .rst(sys_rst),
        .rnd(rng)
    );

    // Game FSM <-> Datapath wiring
    wire [2:0] player_active_id, cpu_active_id; // currently selected pokemon (1-6)
    wire [3:0] game_state;                      // current FSM state
    wire [1:0] cursor_pos;                      // menu cursor (0-3)
    wire [9:0] player_hp_cur, player_hp_max;    // active player HP for display
    wire [9:0] cpu_hp_cur, cpu_hp_max;          // active CPU HP for display
    wire       trigger_player_atk, trigger_cpu_atk;  // 1-cycle pulses to start attack anim
    wire       user_won;                        // result flag at end of battle
    wire       anim_done;                       // handshake from video mixer when anim finishes
    wire [4:0] move_id;                         // index into move ROM

    // Battle engine I/O
    wire [8:0] be_atk, be_def;                  // attacker ATK and defender DEF stats
    wire [7:0] be_power;                        // move base power
    wire [3:0] be_move_type, be_def_type1, be_def_type2;  // 4-bit type encodings
    wire [3:0] be_rng;                          // 4-bit damage variance
    wire       be_is_status;                    // status moves deal no damage

    // Player stat ROM (looks up active pokemon's stats and moveset)
    wire [9:0] p_max_hp;                        // base HP at level 50
    wire [8:0] p_atk, p_def, p_spd;             // attack / defense / speed
    wire [3:0] p_type1, p_type2;                // dual typing
    wire [4:0] p_move0, p_move1, p_move2, p_move3;  // 4-move moveset

    pokemon_stat_rom p_stats(
        .pokemon_id(player_active_id),
        .max_hp(p_max_hp),
        .atk(p_atk), .def_stat(p_def), .spd(p_spd),
        .type1(p_type1), .type2(p_type2),
        .move0(p_move0), .move1(p_move1), .move2(p_move2), .move3(p_move3)
    );

    // CPU stat ROM (same module, indexed by the CPU's active pokemon)
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

    // Move ROM (returns {type, power, is_status} for a given move_id)
    wire [12:0] move_data;                      // packed move record
    move_rom move_lut(
        .move_id(move_id),
        .move_data(move_data)
    );

    // Battle engine (combinational damage calculator)
    wire [9:0] calc_damage;                     // computed damage value
    wire       calc_super, calc_not_eff, calc_immune;  // type effectiveness flags

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

    // Game FSM (the brain: drives state transitions, HP storage, switching)
    wire [9:0] p_hp0, p_hp1, p_hp2, c_hp0, c_hp1, c_hp2;  // per-slot HP for team display
    wire [1:0] p_active_idx, c_active_idx;      // which team slot (0-2) is active

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

    // Sprite mux (selects the correct pokemon sprite ROM for each side)
    wire [6:0] p_sprite_row, p_sprite_col;      // sample coords driven from video_mixer
    wire [6:0] c_sprite_row, c_sprite_col;
    wire [11:0] p_sprite_color, c_sprite_color; // sprite pixel colors
    wire p_sprite_transparent, c_sprite_transparent;  // background-key transparency

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

    // Video mixer (per-pixel rendering pipeline; merges background, sprites, UI)
    wire [11:0] rgb;                            // final pixel color to VGA

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

    // VGA output (split 12-bit rgb across the three 4-bit DAC channels)
    assign vgaR = rgb[11:8];
    assign vgaG = rgb[7:4];
    assign vgaB = rgb[3:0];

    // 7-segment display tied off (unused on this design)
    assign Dp = 1;                              // decimal point off (active-low)
    assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = 7'b1111111;     // all segments off
    assign {An7, An6, An5, An4, An3, An2, An1, An0} = 8'b11111111;  // all digits disabled

    // SPI flash chip-select held high so it does not respond on shared pins
    assign QuadSpiFlashCS = 1'b1;

endmodule
