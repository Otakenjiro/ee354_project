`timescale 1ns / 1ps

module pokemon_vga_top(
    input ClkPort,
    input BtnC,
    input BtnU,
    input BtnD,
    input BtnL,
    input BtnR,

    inout PS2_CLK,
    inout PS2_DATA,

    output hSync, vSync,
    output [3:0] vgaR, vgaG, vgaB,

    output An0, An1, An2, An3, An4, An5, An6, An7,
    output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,

    output QuadSpiFlashCS
);

    // ----------------------------------------------------------------
    //  CDC stage 1: Button synchronization + debounce
    //    (2-FF synchronizer eliminates metastability on async button
    //     inputs; debounce counter ignores mechanical bounce.)
    // ----------------------------------------------------------------
    wire btn_c, btn_u, btn_d, btn_l, btn_r;

    btn_debounce db_c(.clk(ClkPort), .btn_in(BtnC), .btn_out(btn_c));
    btn_debounce db_u(.clk(ClkPort), .btn_in(BtnU), .btn_out(btn_u));
    btn_debounce db_d(.clk(ClkPort), .btn_in(BtnD), .btn_out(btn_d));
    btn_debounce db_l(.clk(ClkPort), .btn_in(BtnL), .btn_out(btn_l));
    btn_debounce db_r(.clk(ClkPort), .btn_in(BtnR), .btn_out(btn_r));

    // ----------------------------------------------------------------
    //  CDC stage 2: Reset synchronizer
    //    Async reset assertion is fine, but de-assertion must be
    //    synchronous to the clock to avoid recovery/removal
    //    violations. This gives a clean, glitch-free reset for all
    //    downstream modules.
    // ----------------------------------------------------------------
    wire sys_rst;
    reset_sync rst_sync(
        .clk(ClkPort),
        .async_rst_in(btn_r),
        .sync_rst_out(sys_rst)
    );

    // ----------------------------------------------------------------
    //  VGA timing  (now uses single clock with 25 MHz enable — no CDC)
    // ----------------------------------------------------------------
    wire bright;
    wire [9:0] hc, vc;
    display_controller dc(
        .clk(ClkPort),
        .hSync(hSync), .vSync(vSync),
        .bright(bright),
        .hCount(hc), .vCount(vc)
    );

    // Pixel coordinates in active 640×480 area
    wire [9:0] px = hc - 10'd144;
    wire [8:0] py = vc - 10'd35;

    // ----------------------------------------------------------------
    //  Background ROM
    // ----------------------------------------------------------------
    wire [11:0] bg_color;
    battle_rom bg_rom(
        .clk(ClkPort),
        .row(py),
        .col(px),
        .color_data(bg_color)
    );

    // ----------------------------------------------------------------
    //  LFSR (random number generator)
    // ----------------------------------------------------------------
    wire [15:0] rng;
    lfsr rng_gen(
        .clk(ClkPort),
        .rst(sys_rst),
        .rnd(rng)
    );

    // ----------------------------------------------------------------
    //  PS/2 Bidirectional Bus (open-drain tri-state)
    // ----------------------------------------------------------------
    wire ps2_clk_oe, ps2_data_oe, ps2_data_out_tx;

    // Open-drain: drive low when OE=1 and output=0, otherwise high-Z (pullup provides idle high)
    assign PS2_CLK  = ps2_clk_oe                       ? 1'b0 : 1'bz;
    assign PS2_DATA = (ps2_data_oe & ~ps2_data_out_tx) ? 1'b0 : 1'bz;

    // ----------------------------------------------------------------
    //  PS/2 Receiver
    // ----------------------------------------------------------------
    wire [7:0] ps2_rx_data;
    wire       ps2_rx_valid;

    ps2_rx ps2(
        .clk(ClkPort),
        .rst(sys_rst),
        .ps2_clk_in(PS2_CLK),
        .ps2_data_in(PS2_DATA),
        .data(ps2_rx_data),
        .data_valid(ps2_rx_valid)
    );

    // ----------------------------------------------------------------
    //  PS/2 Transmitter
    // ----------------------------------------------------------------
    wire [7:0] init_tx_data;
    wire       init_tx_start;
    wire       tx_busy, tx_done, tx_err;

    ps2_tx ps2_transmitter(
        .clk(ClkPort),
        .rst(sys_rst),
        .tx_data(init_tx_data),
        .tx_start(init_tx_start),
        .ps2_clk_in(PS2_CLK),
        .ps2_data_in(PS2_DATA),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .tx_err(tx_err),
        .ps2_clk_oe(ps2_clk_oe),
        .ps2_data_out(ps2_data_out_tx),
        .ps2_data_oe(ps2_data_oe)
    );

    // ----------------------------------------------------------------
    //  PS/2 Mouse Init (sends Reset + Enable Data Reporting)
    // ----------------------------------------------------------------
    wire init_done;

    ps2_mouse_init mouse_init(
        .clk(ClkPort),
        .rst(sys_rst),
        .tx_data(init_tx_data),
        .tx_start(init_tx_start),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .tx_err(tx_err),
        .rx_data(ps2_rx_data),
        .rx_valid(ps2_rx_valid),
        .init_done(init_done)
    );

    // ----------------------------------------------------------------
    //  Mouse Controller (only receives packets after init is done)
    // ----------------------------------------------------------------
    wire [9:0] mouse_x, mouse_y;
    wire       mouse_left, mouse_right;
    wire       mouse_rx_valid = ps2_rx_valid & init_done;

    mouse_ctrl mctrl(
        .clk(ClkPort),
        .rst(sys_rst),
        .rx_data(ps2_rx_data),
        .rx_valid(mouse_rx_valid),
        .mouse_x(mouse_x),
        .mouse_y(mouse_y),
        .mouse_left(mouse_left),
        .mouse_right(mouse_right)
    );

    // ----------------------------------------------------------------
    //  Mouse Click Detection (rising edge + hit-test)
    // ----------------------------------------------------------------
    reg mouse_left_prev;
    always @(posedge ClkPort) mouse_left_prev <= mouse_left;
    wire mouse_click = mouse_left & ~mouse_left_prev;

    // Menu box regions (match video_mixer constants)
    // Box layout: 4 boxes starting at Y=420, height 35
    // Box X positions: 30, 180, 330, 480; each 140px wide
    wire in_menu_y = (mouse_y >= 10'd420) && (mouse_y < 10'd455);
    wire hit_box0  = in_menu_y && (mouse_x >= 10'd30)  && (mouse_x < 10'd170);
    wire hit_box1  = in_menu_y && (mouse_x >= 10'd180) && (mouse_x < 10'd320);
    wire hit_box2  = in_menu_y && (mouse_x >= 10'd330) && (mouse_x < 10'd470);
    wire hit_box3  = in_menu_y && (mouse_x >= 10'd480) && (mouse_x < 10'd620);

    // BACK button for S_FIGHT_SEL: at (540, 390) size 90x25
    wire hit_back  = (mouse_x >= 10'd540) && (mouse_x < 10'd630) &&
                     (mouse_y >= 10'd390) && (mouse_y < 10'd415);

    // START/END screen: center area click
    wire hit_start = (mouse_x >= 10'd220) && (mouse_x < 10'd420) &&
                     (mouse_y >= 10'd240) && (mouse_y < 10'd320);

    wire click_box0  = mouse_click & hit_box0;
    wire click_box1  = mouse_click & hit_box1;
    wire click_box2  = mouse_click & hit_box2;
    wire click_box3  = mouse_click & hit_box3;
    wire click_back  = mouse_click & hit_back;
    wire click_start = mouse_click & hit_start;

    // ----------------------------------------------------------------
    //  Game FSM <-> Datapath wiring
    // ----------------------------------------------------------------
    wire [3:0] player_active_id, cpu_active_id;
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
    wire [4:0] be_move_type, be_def_type1, be_def_type2;
    wire [3:0] be_rng;
    wire       be_is_status;

    // ----------------------------------------------------------------
    //  Player stat ROM
    // ----------------------------------------------------------------
    wire [9:0] p_max_hp;
    wire [8:0] p_atk, p_def, p_spd;
    wire [4:0] p_type1, p_type2;
    wire [4:0] p_move0, p_move1, p_move2, p_move3;

    pokemon_stat_rom p_stats(
        .pokemon_id(player_active_id),
        .max_hp(p_max_hp),
        .atk(p_atk), .def_stat(p_def), .spd(p_spd),
        .type1(p_type1), .type2(p_type2),
        .move0(p_move0), .move1(p_move1), .move2(p_move2), .move3(p_move3)
    );

    // ----------------------------------------------------------------
    //  CPU stat ROM
    // ----------------------------------------------------------------
    wire [9:0] c_max_hp;
    wire [8:0] c_atk, c_def, c_spd;
    wire [4:0] c_type1, c_type2;
    wire [4:0] c_move0, c_move1, c_move2, c_move3;

    pokemon_stat_rom c_stats(
        .pokemon_id(cpu_active_id),
        .max_hp(c_max_hp),
        .atk(c_atk), .def_stat(c_def), .spd(c_spd),
        .type1(c_type1), .type2(c_type2),
        .move0(c_move0), .move1(c_move1), .move2(c_move2), .move3(c_move3)
    );

    // ----------------------------------------------------------------
    //  Move ROM
    // ----------------------------------------------------------------
    wire [13:0] move_data;
    move_rom move_lut(
        .move_id(move_id),
        .move_data(move_data)
    );

    // ----------------------------------------------------------------
    //  Battle Engine (damage calculator)
    // ----------------------------------------------------------------
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

    // ----------------------------------------------------------------
    //  Game FSM (the brain)
    // ----------------------------------------------------------------
    wire [9:0] p_hp0, p_hp1, p_hp2, c_hp0, c_hp1, c_hp2;
    wire [1:0] p_active_idx, c_active_idx;

    game_fsm fsm(
        .clk(ClkPort),
        .rst(sys_rst),
        .btn_c(btn_c), .btn_u(btn_u), .btn_d(btn_d), .btn_l(btn_l),
        .click_box0(click_box0), .click_box1(click_box1),
        .click_box2(click_box2), .click_box3(click_box3),
        .click_back(click_back), .click_start(click_start),
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

    // ----------------------------------------------------------------
    //  Sprite Mux
    // ----------------------------------------------------------------
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

    // ----------------------------------------------------------------
    //  Video Mixer (rendering pipeline)
    // ----------------------------------------------------------------
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
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .rgb(rgb)
    );

    // ----------------------------------------------------------------
    //  VGA output
    // ----------------------------------------------------------------
    assign vgaR = rgb[11:8];
    assign vgaG = rgb[7:4];
    assign vgaB = rgb[3:0];

    // ----------------------------------------------------------------
    //  7-Segment: tied off (unused)
    // ----------------------------------------------------------------
    assign Dp = 1;
    assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = 7'b1111111;
    assign {An7, An6, An5, An4, An3, An2, An1, An0} = 8'b11111111;

    assign QuadSpiFlashCS = 1'b1;

endmodule
