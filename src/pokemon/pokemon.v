`include "types.vh"

module pokemon #(
    // Species definition (set at instantiation) 
    parameter SPECIES_ID = 0, // 1-9, ID for which pokemon it is
    parameter [4:0] TYPE_1 = `TYPE_NORMAL, // 5-bit ID from types.vh 
    parameter [4:0] TYPE_2 = `TYPE_NONE, // TYPE_NONE for mono-type

    // Base stats
    parameter [7:0] BASE_HP  = 45,
    parameter [7:0] BASE_ATK = 45,
    parameter [7:0] BASE_DEF = 45,
    parameter [7:0] BASE_SPD = 45,

    // Moveset (4 move IDs referencing move_rom)
    // instantiate as 0s
    parameter [4:0] MOVE_0 = 5'd0,
    parameter [4:0] MOVE_1 = 5'd0,
    parameter [4:0] MOVE_2 = 5'd0,
    parameter [4:0] MOVE_3 = 5'd0,

    parameter SPRITE_FILE  = "sprites/default.hex"
)
(
    input wire clk,
    input wire rst,

    // Level
    input wire [6:0] level, // 1–100

    // Move selection 
    input wire  [1:0]  move_select,        // which of 4 moves to use
    output wire [31:0] selected_move,      // full packed move word
    output wire        selected_is_status, // 1 if move is a status move
    output wire [7:0]  selected_effect,    // effect ID when is_status=1
    output wire [4:0]  selected_move_type, // type of selected move
    output wire [7:0]  selected_power,     // base power (0 if status)
    output wire [6:0]  selected_accuracy,

    // Computed stats (combinational from level + base stats) 
    output wire [9:0] stat_hp,
    output wire [8:0] stat_atk,
    output wire [8:0] stat_def,
    output wire [8:0] stat_spd,

    // Battle state 
    input wire [9:0] damage_in, // calculated in battle_engine.v
    input wire apply_damage, // single-cycle clock pulse that triggers HP subtraction
    input wire heal_full, // heal full on reset of battle
    output reg [9:0] current_hp, // resets on heal_full
    output wire fainted, // when current_hp = 0

    // PP tracking (one counter per move) 
    input wire use_move, // pulse: deduct PP for move_select
    output reg [5:0]  pp [0:3],

    // Type outputs (for type_effectiveness in battle_engine) 
    output wire [4:0] type1,
    output wire [4:0] type2,

    // Sprite interface 
    input  wire [11:0] sprite_pixel_addr,
    output wire [1:0]  sprite_pixel_out
);

    // Type pass-through 
    assign type1 = TYPE_1;
    assign type2 = TYPE_2;

    // Stat calculation 
    // HP = floor((2 * base * level) / 100) + level + 10
    // Stat = floor((2 * base * level) / 100) + 5
    assign stat_hp  = (((2 * BASE_HP * level) / 100) + level + 10);
    assign stat_atk = (((2 * BASE_ATK * level) / 100) + 5);
    assign stat_def = (((2 * BASE_DEF * level) / 100) + 5);
    assign stat_spd = (((2 * BASE_SPD * level) / 100) + 5);

    // Move ID mux 
    reg [4:0] active_move_id;
    always @(*) begin
        case (move_select)
            2'd0: active_move_id = MOVE_0;
            2'd1: active_move_id = MOVE_1;
            2'd2: active_move_id = MOVE_2;
            2'd3: active_move_id = MOVE_3;
        endcase
    end

    // Move ROM lookup 
    move_rom move_lookup (
        .move_id (active_move_id),
        .move_data (selected_move)
    );

    // Unpack move word fields 
    assign selected_is_status  = selected_move[0];
    assign selected_move_type  = selected_move[26:22];
    assign selected_power      = selected_move[0] ? 8'd0 : selected_move[21:14];
    assign selected_effect     = selected_move[0] ? selected_move[21:14] : 8'd0;
    assign selected_accuracy   = selected_move[13:7];

    // PP tracking 
    // PP max sourced from move_rom pp_max field × 1 (field is already real PP)
    wire [3:0] pp_max_field = selected_move[6:3];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pp[0] <= 6'd35; // Tackle by default
            pp[1] <= 6'd35;
            pp[2] <= 6'd35;
            pp[3] <= 6'd35;
        end else if (use_move && pp[move_select] > 0) begin
            pp[move_select] <= pp[move_select] - 1;
        end
    end

    // Current HP or damage 
    always @(posedge clk or posedge rst) begin
        if (rst || heal_full) begin
            current_hp <= stat_hp;
        end else if (apply_damage) begin
            if (damage_in >= current_hp)
                current_hp <= 10'd0;
            else
                current_hp <= current_hp - damage_in;
        end
    end

    assign fainted = (current_hp == 10'd0);

    // Sprite ROM 
    sprite_rom #(
        .SPRITE_FILE (SPRITE_FILE)
    ) sprite (
        .clk        (clk),
        .pixel_addr (sprite_pixel_addr),
        .pixel_out  (sprite_pixel_out)
    );

endmodule