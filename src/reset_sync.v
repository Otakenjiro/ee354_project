`timescale 1ns / 1ps

// Reset synchronizer:
//   - async assertion  (reset goes high immediately, even without a clock)
//   - sync de-assertion (reset only falls on a clock edge, 2 flops deep
//     to guarantee metastability settles before any logic sees it)
//
// This is the standard textbook CDC pattern for async reset in a single-
// clock design. It eliminates recovery/removal timing violations that
// otherwise cause flops to enter metastable states at reset release.

module reset_sync (
    input  wire clk,
    input  wire async_rst_in,
    output wire sync_rst_out
);

    (* ASYNC_REG = "TRUE" *) reg rst_meta;
    (* ASYNC_REG = "TRUE" *) reg rst_sync;

    initial begin
        rst_meta = 1'b1;
        rst_sync = 1'b1;
    end

    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            rst_meta <= 1'b1;
            rst_sync <= 1'b1;
        end else begin
            rst_meta <= 1'b0;
            rst_sync <= rst_meta;
        end
    end

    assign sync_rst_out = rst_sync;

endmodule
