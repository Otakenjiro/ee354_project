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

`endif