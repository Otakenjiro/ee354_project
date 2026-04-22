`timescale 1ns / 1ps

module mouse_ctrl (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  rx_data,
    input  wire        rx_valid,
    output reg  [9:0]  mouse_x,
    output reg  [9:0]  mouse_y,
    output reg         mouse_left,
    output reg         mouse_right
);

    // -------------------------------------------------------
    //  3-byte PS/2 mouse packet collector
    //    Byte 0: [Yovf Xovf Ysign Xsign 1 Mbtn Rbtn Lbtn]
    //    Byte 1: X movement (unsigned, sign in byte 0 bit 4)
    //    Byte 2: Y movement (unsigned, sign in byte 0 bit 5)
    // -------------------------------------------------------
    reg [1:0] byte_cnt;
    reg [7:0] pkt_byte0, pkt_byte1;

    // Signed accumulators for delta (wider than 10-bit for clamping)
    reg signed [10:0] next_x, next_y;

    always @(posedge clk) begin
        if (rst) begin
            byte_cnt   <= 2'd0;
            mouse_x    <= 10'd320;   // center of 640
            mouse_y    <= 10'd240;   // center of 480
            mouse_left <= 1'b0;
            mouse_right<= 1'b0;
            pkt_byte0  <= 8'd0;
            pkt_byte1  <= 8'd0;
        end else if (rx_valid) begin
            case (byte_cnt)
                2'd0: begin
                    // Byte 0 - verify bit 3 is set (always 1 in standard PS/2 mouse)
                    if (rx_data[3]) begin
                        pkt_byte0  <= rx_data;
                        mouse_left <= rx_data[0];
                        mouse_right<= rx_data[1];
                        byte_cnt   <= 2'd1;
                    end
                    // If bit 3 not set, stay at byte 0 (resync)
                end
                2'd1: begin
                    // Byte 1 - X delta
                    pkt_byte1 <= rx_data;
                    byte_cnt  <= 2'd2;
                end
                2'd2: begin
                    // Byte 2 - Y delta: apply both deltas now
                    byte_cnt <= 2'd0;

                    // --- X accumulation ---
                    // Sign-extend X delta using byte0[4] (Xsign)
                    if (pkt_byte0[6]) begin
                        // X overflow - ignore packet
                    end else begin
                        if (pkt_byte0[4])
                            next_x = $signed({1'b0, mouse_x}) + $signed({3'b111, pkt_byte1});
                        else
                            next_x = $signed({1'b0, mouse_x}) + $signed({3'b000, pkt_byte1});

                        if (next_x < 0)
                            mouse_x <= 10'd0;
                        else if (next_x > 639)
                            mouse_x <= 10'd639;
                        else
                            mouse_x <= next_x[9:0];
                    end

                    // --- Y accumulation ---
                    // PS/2 Y is inverted: positive = up on screen
                    // We want positive = down, so SUBTRACT the delta
                    if (pkt_byte0[7]) begin
                        // Y overflow - ignore packet
                    end else begin
                        if (pkt_byte0[5])
                            next_y = $signed({1'b0, mouse_y}) - $signed({3'b111, rx_data});
                        else
                            next_y = $signed({1'b0, mouse_y}) - $signed({3'b000, rx_data});

                        if (next_y < 0)
                            mouse_y <= 10'd0;
                        else if (next_y > 479)
                            mouse_y <= 10'd479;
                        else
                            mouse_y <= next_y[9:0];
                    end
                end
                default: byte_cnt <= 2'd0;
            endcase
        end
    end

endmodule
