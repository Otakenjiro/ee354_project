// types.vh header file for pokemon type selection/assignment
`ifndef TYPES_VH
`define TYPES_VH

// 5-bit type encoding (covers all 15 Gen-I types)
// some of them won't be used, but just thought I'd add all of them while I was at it so we have it if we need it
`define TYPE_NORMAL   5'd0
`define TYPE_FIRE     5'd1
`define TYPE_WATER    5'd2
`define TYPE_GRASS    5'd3
`define TYPE_ELECTRIC 5'd4
`define TYPE_ICE      5'd5
`define TYPE_FIGHTING 5'd6
`define TYPE_POISON   5'd7
`define TYPE_GROUND   5'd8
`define TYPE_FLYING   5'd9
`define TYPE_PSYCHIC  5'd10
`define TYPE_BUG      5'd11
`define TYPE_ROCK     5'd12
`define TYPE_GHOST    5'd13
`define TYPE_DRAGON   5'd14
`define TYPE_NONE     5'd31   // used for mono-type pokemon's second slot. ex: charmander: fire, NONE. charizard: fire, flying

// 1-bit encoding for the status effect IDs 
`define FX_NONE        8'd0
`define FX_LOWER_ACC   8'd1 // Smokescreen: opponent -1 accuracy stage
`define FX_SLEEP       8'd2 // Sleep Powder, Hypnosis
`define FX_RAISE_DEF   8'd3 // Withdraw: self +1 defense stage
`define FX_LOWER_SPD   8'd4 // Scary Face: opponent -2 speed stage
`define FX_PARALYZE    8'd5 // Thunder Wave
`define FX_RAISE_SPD   8'd6 // Agility: self +2 speed stage
`define FX_BLOCK_DROPS 8'd7 // Mist: block stat drops

`endif