// 9 POKEMON INSTANTIATION
// Choices: 
// 1 = Charizard, 2 = Venusar, 3 = Blastoise 
// 4 = Nidoking, 5 = Gengar, 6 = Pikachu
// 7 = Moltres, 8 = Zapdos, 9 = Articuno

// choices were made to somewhat? balance the type advanatages/disadvantages 
// mainly gen 1 legendaries, gen 3 starters, and random 3 in the mix

`include "pokemon/types.vh"

module top (
    input wire clk;
    input wire rst;

    // figure out how to use keyboard as input
    // use arrow keys for navigation, A as "A", Z as "B" in Nintendo GameBoy fashion

);

// Base stats were all pulled from the original pokemon game 
// Level is used to further calculate from the base stats:
localparam [6:0] BATTLE_LEVEL = 7'd50; // All pokemon are level 50


/* TEMPLATE  
pokemon # (
    .SPECIES_ID (),
    .TYPE_1 (`TYPE_),
    .TYPE_2 (`Type_),
    .BASE_HP (), .BASE_ATK (), .BASE_DEF (), .BASE_SPD (),
    .MOVE_0 (5'd), // 
    .MOVE_1 (5'd), // 
    .MOVE_2 (5'd), // 
    .MOVE_3 (5'd), // 
    .SPRITE_FILE ("sprites/.hex")
) _inst ( // instantiation of given pokemon 
    .clk (clk), 
    .rst (rst),
    .level (BATTLE_LEVEL)
);
*/


// Charizard 
pokemon # (
    .SPECIES_ID (1),
    .TYPE_1 (`TYPE_FIRE),
    .TYPE_2 (`Type_FLYING),
    .BASE_HP (78), .BASE_ATK (84), .BASE_DEF (78), .BASE_SPD (100),
    .MOVE_0 (5'd1), // Flamethrower
    .MOVE_1 (5'd2), // Fire Blast
    .MOVE_2 (5'd3), // Slash
    .MOVE_3 (5'd21), // Smokescreen 
    .SPRITE_FILE ("sprites/charizard.hex")
) charizard_inst ( // instantiation of given pokemon 
    .clk (clk), 
    .rst (rst),
    .level (BATTLE_LEVEL)
);

// Venusaur
pokemon # (
    .SPECIES_ID (2),
    .TYPE_1 (`TYPE_GRASS),
    .TYPE_2 (`TYPE_POISON),
    .BASE_HP (80), .BASE_ATK (82), .BASE_DEF (83), .BASE_SPD (80),
    .MOVE_0 (5'd4), // Razor Leaf
    .MOVE_1 (5'd5), // Solar Beam
    .MOVE_2 (5'd6), // Sludge Bomb
    .MOVE_3 (5'd22), // Sleep Power: FX_SLEEP
    .SPRITE_FILE ("sprites/venusaur.hex")
) _inst ( // instantiation of given pokemon 
    .clk (clk), 
    .rst (rst),
    .level (BATTLE_LEVEL)
);

// Blastoise
pokemon # (
    .SPECIES_ID (3),
    .TYPE_1 (`TYPE_WATER),
    .TYPE_2 (`Type_NONE),
    .BASE_HP (79), .BASE_ATK (83), .BASE_DEF (100), .BASE_SPD (78),
    .MOVE_0 (5'd7), // Surf 
    .MOVE_1 (5'd8), // Hydro Pump
    .MOVE_2 (5'd9), // Ice Beam
    .MOVE_3 (5'd23), // Withdraw: FX_RAISE_DEF
    .SPRITE_FILE ("sprites/blastoise.hex")
) _inst ( // instantiation of given pokemon 
    .clk (clk), 
    .rst (rst),
    .level (BATTLE_LEVEL)
);

// Nidoking
pokemon # (
    .SPECIES_ID (4),
    .TYPE_1 (`TYPE_POISON),
    .TYPE_2 (`TYPE_GROUND),
    .BASE_HP (81), .BASE_ATK (92), .BASE_DEF (77), .BASE_SPD (85),
    .MOVE_0 (5'd10), // Earthquake
    .MOVE_1 (5'd11), // Poison Jab
    .MOVE_2 (5'd12), // Megahorn
    .MOVE_3 (5'd24), // Scary Face: FX_LOWER_SPD
    .SPRITE_FILE ("sprites/nidoking.hex")
) nidoking_inst ( // instantiation of given pokemon
    .clk (clk),
    .rst (rst),
    .level (BATTLE_LEVEL)
);

// Gengar
pokemon # (
    .SPECIES_ID (5),
    .TYPE_1 (`TYPE_GHOST),
    .TYPE_2 (`TYPE_POISON),
    .BASE_HP (60), .BASE_ATK (65), .BASE_DEF (60), .BASE_SPD (110),
    .MOVE_0 (5'd13), // Shadow Ball
    .MOVE_1 (5'd6), // Sludge Bomb
    .MOVE_2 (5'd14), // Dream Eater
    .MOVE_3 (5'd25), // Hypnosis: FX_SLEEP
    .SPRITE_FILE ("sprites/gengar.hex")
) gengar_inst ( // instantiation of given pokemon
    .clk (clk),
    .rst (rst),
    .level (BATTLE_LEVEL)
);

// Pikachu
pokemon # (
    .SPECIES_ID (6),
    .TYPE_1 (`TYPE_ELECTRIC),
    .TYPE_2 (`TYPE_NONE),
    .BASE_HP (35), .BASE_ATK (55), .BASE_DEF (40), .BASE_SPD (90),
    .MOVE_0 (5'd15), // Thunderbolt
    .MOVE_1 (5'd16), // Thunder
    .MOVE_2 (5'd17), // Quick Attack
    .MOVE_3 (5'd26), // Thunder Wave: FX_PARALYZE
    .SPRITE_FILE ("sprites/pikachu.hex")
) pikachu_inst ( // instantiation of given pokemon
    .clk (clk),
    .rst (rst),
    .level (BATTLE_LEVEL)
);

// Moltres
pokemon # (
    .SPECIES_ID (7),
    .TYPE_1 (`TYPE_FIRE),
    .TYPE_2 (`TYPE_FLYING),
    .BASE_HP (90), .BASE_ATK (100), .BASE_DEF (90), .BASE_SPD (90),
    .MOVE_0 (5'd2), // Fire Blast
    .MOVE_1 (5'd1), // Flamethrower
    .MOVE_2 (5'd18), // Wing Attack
    .MOVE_3 (5'd27), // Agility: FX_RAISE_SPD
    .SPRITE_FILE ("sprites/moltres.hex")
) moltres_inst ( // instantiation of given pokemon
    .clk (clk),
    .rst (rst),
    .level (BATTLE_LEVEL)
);

// Zapdos
pokemon # (
    .SPECIES_ID (8),
    .TYPE_1 (`TYPE_ELECTRIC),
    .TYPE_2 (`TYPE_FLYING),
    .BASE_HP (90), .BASE_ATK (90), .BASE_DEF (85), .BASE_SPD (100),
    .MOVE_0 (5'd15), // Thunderbolt
    .MOVE_1 (5'd16), // Thunder
    .MOVE_2 (5'd19), // Drill Peck
    .MOVE_3 (5'd26), // Thunder Wave: FX_PARALYZE
    .SPRITE_FILE ("sprites/zapdos.hex")
) zapdos_inst ( // instantiation of given pokemon
    .clk (clk),
    .rst (rst),
    .level (BATTLE_LEVEL)
);

// Articuno
pokemon # (
    .SPECIES_ID (9),
    .TYPE_1 (`TYPE_ICE),
    .TYPE_2 (`TYPE_FLYING),
    .BASE_HP (90), .BASE_ATK (85), .BASE_DEF (100), .BASE_SPD (85),
    .MOVE_0 (5'd9), // Ice Beam
    .MOVE_1 (5'd20), // Blizzard
    .MOVE_2 (5'd18), // Wing Attack
    .MOVE_3 (5'd28), // Mist: FX_BLOCK_DROPS
    .SPRITE_FILE ("sprites/articuno.hex")
) articuno_inst ( // instantiation of given pokemon
    .clk (clk),
    .rst (rst),
    .level (BATTLE_LEVEL)
);