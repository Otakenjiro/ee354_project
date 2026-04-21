`timescale 1ns / 1ps

module lfsr (
    input wire clk,
    input wire rst,
    output wire [15:0] rnd
);
    reg [15:0] sr;

    always @(posedge clk or posedge rst) begin
        if (rst)
            sr <= 16'hACE1;
        else
            sr <= {sr[14:0], sr[15] ^ sr[14] ^ sr[12] ^ sr[3]};
    end

    assign rnd = sr;
endmodule
