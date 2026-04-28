`timescale 1ns / 1ps

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
