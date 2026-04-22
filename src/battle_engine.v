`timescale 1ns / 1ps

module battle_engine (
    input wire [8:0]  atk,         // attacker's ATK stat
    input wire [7:0]  power,       // move's base power (0 for status)
    input wire [4:0]  move_type,   // move's type
    input wire [8:0]  def_stat,    // defender's DEF stat
    input wire [4:0]  def_type1,   // defender's type 1
    input wire [4:0]  def_type2,   // defender's type 2
    input wire [3:0]  rng,         // 4-bit random variance (0-15)
    input wire        is_status,   // 1 if status move (no damage)
    output wire [9:0] damage,
    output wire       super_effective,
    output wire       not_effective,
    output wire       immune
);

    // Type effectiveness lookups (dual-type)
    wire [1:0] eff1, eff2;
    type_eff te1 (.atk_type(move_type), .def_type(def_type1), .eff(eff1));
    type_eff te2 (.atk_type(move_type), .def_type(def_type2), .eff(eff2));

    // Convert to multiplier values: 0→0, 1→1, 2→2, 3→4
    wire [2:0] m1 = (eff1 == 2'd0) ? 3'd0 :
                     (eff1 == 2'd1) ? 3'd1 :
                     (eff1 == 2'd3) ? 3'd4 : 3'd2;
    wire [2:0] m2 = (eff2 == 2'd0) ? 3'd0 :
                     (eff2 == 2'd1) ? 3'd1 :
                     (eff2 == 2'd3) ? 3'd4 : 3'd2;

    // Combined multiplier: m1*m2 with denominator 4
    // Possible values: 0, 1, 2, 4, 8, 16
    wire [4:0] type_mult = m1 * m2;

    assign immune         = (type_mult == 5'd0);
    assign super_effective = (type_mult > 5'd4);
    assign not_effective   = (type_mult > 5'd0) && (type_mult < 5'd4);

    // Damage formula (integer, level 50):
    //   base = (22 * power * atk) / (50 * def) + 2
    //   typed = base * type_mult / 4
    //   final = typed * (85 + rng) / 100   (85-100% random variance)
    wire [24:0] numerator = 25'd22 * {17'd0, power} * {16'd0, atk};
    wire [17:0] denominator = {9'd0, def_stat} * 18'd50;
    wire [9:0]  base_dmg = (denominator != 0) ? (numerator / denominator) + 10'd2 : 10'd2;

    wire [14:0] typed_dmg = base_dmg * type_mult;
    wire [12:0] after_type_wide = typed_dmg[14:2]; // divide by 4
    wire [9:0]  after_type = (after_type_wide > 13'd1023) ? 10'd1023 : after_type_wide[9:0];

    wire [7:0]  rng_factor = 8'd85 + {4'd0, rng};
    wire [17:0] final_prod = after_type * rng_factor;
    wire [9:0]  final_dmg  = final_prod / 18'd100;

    assign damage = is_status ? 10'd0 :
                    immune    ? 10'd0 :
                    (final_dmg == 10'd0) ? 10'd1 : final_dmg;

endmodule
