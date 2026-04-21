`timescale 1ns / 1ps

module btn_debounce (
    input  wire clk,
    input  wire btn_in,
    output reg  btn_out
);

    // Stage 1: two-flip-flop synchronizer (eliminates metastability).
    // ASYNC_REG attribute tells Vivado to place these flops close together
    // for maximum metastability resolution time.
    (* ASYNC_REG = "TRUE" *) reg sync0;
    (* ASYNC_REG = "TRUE" *) reg sync1;
    always @(posedge clk) begin
        sync0 <= btn_in;
        sync1 <= sync0;
    end

    // Stage 2: debounce — require stable for 2^19 cycles (~5 ms at 100 MHz)
    reg [19:0] cnt;

    initial begin
        sync0   = 0;
        sync1   = 0;
        btn_out = 0;
        cnt     = 0;
    end

    always @(posedge clk) begin
        if (sync1 == btn_out)
            cnt <= 20'd0;
        else if (cnt[19])
            btn_out <= sync1;
        else
            cnt <= cnt + 20'd1;
    end

endmodule
