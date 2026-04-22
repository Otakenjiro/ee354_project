`timescale 1ns / 1ps

module ps2_rx (
    input  wire clk,          // system clock (100 MHz)
    input  wire rst,
    input  wire ps2_clk_in,   // raw PS/2 clock from PIC24
    input  wire ps2_data_in,  // raw PS/2 data from PIC24
    output reg  [7:0] data,   // received byte
    output reg  data_valid     // one-cycle pulse when byte ready
);

    // -------------------------------------------------------
    //  2-FF synchronizers (CDC: PIC24 -> FPGA clock domain)
    // -------------------------------------------------------
    reg [1:0] clk_sync, data_sync;
    always @(posedge clk) begin
        clk_sync  <= {clk_sync[0],  ps2_clk_in};
        data_sync <= {data_sync[0], ps2_data_in};
    end
    wire ps2_clk  = clk_sync[1];
    wire ps2_data = data_sync[1];

    // -------------------------------------------------------
    //  Falling-edge detector on synchronized PS/2 clock
    // -------------------------------------------------------
    reg ps2_clk_prev;
    always @(posedge clk) ps2_clk_prev <= ps2_clk;
    wire clk_fall = ps2_clk_prev & ~ps2_clk;

    // -------------------------------------------------------
    //  11-bit shift register: start(0) + 8 data + parity + stop
    // -------------------------------------------------------
    reg [3:0] bit_cnt;
    reg [10:0] shift;

    always @(posedge clk) begin
        data_valid <= 1'b0;

        if (rst) begin
            bit_cnt <= 4'd0;
            shift   <= 11'd0;
        end else if (clk_fall) begin
            shift <= {ps2_data, shift[10:1]};  // shift in MSB-first
            if (bit_cnt == 4'd10) begin
                // All 11 bits received
                // shift[0] = start (should be 0)
                // shift[8:1] = data byte
                // shift[9] = parity
                // shift[10] = stop (should be 1)
                if (shift[0] == 1'b0 && ps2_data == 1'b1) begin
                    data       <= shift[8:1];
                    data_valid <= 1'b1;
                end
                bit_cnt <= 4'd0;
            end else begin
                bit_cnt <= bit_cnt + 4'd1;
            end
        end
    end

endmodule
