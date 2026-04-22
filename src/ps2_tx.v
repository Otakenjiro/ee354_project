`timescale 1ns / 1ps

module ps2_tx (
    input wire       clk,          // 100 MHz system clock
    input wire       rst,
    input wire [7:0] tx_data,      // byte to send
    input wire       tx_start,     // pulse to begin transmission

    input wire       ps2_clk_in,   // sampled PS/2 clock (active-low idle-high)
    input wire       ps2_data_in,  // sampled PS/2 data

    output reg       tx_busy,
    output reg       tx_done,      // 1-clk pulse on success
    output reg       tx_err,       // 1-clk pulse on error

    output reg       ps2_clk_oe,   // 1 = drive CLK low (active-low open-drain)
    output reg       ps2_data_out, // value to drive on DATA when ps2_data_oe=1
    output reg       ps2_data_oe   // 1 = drive DATA
);

    // ----------------------------------------------------------------
    //  2-FF CDC synchronizer for ps2_clk_in
    // ----------------------------------------------------------------
    reg [1:0] clk_sync;
    always @(posedge clk) clk_sync <= {clk_sync[0], ps2_clk_in};
    wire ps2_clk_s = clk_sync[1];

    reg ps2_clk_prev;
    always @(posedge clk) ps2_clk_prev <= ps2_clk_s;
    wire falling_edge = ps2_clk_prev & ~ps2_clk_s;

    // ----------------------------------------------------------------
    //  State machine
    // ----------------------------------------------------------------
    localparam S_IDLE     = 3'd0;
    localparam S_INHIBIT  = 3'd1;  // pull CLK low >=100 us
    localparam S_REQ_SEND = 3'd2;  // pull DATA low (start bit), release CLK
    localparam S_DATA     = 3'd3;  // shift out 8 data bits + parity + stop
    localparam S_ACK      = 3'd4;  // wait for device ACK (DATA low on falling edge)

    reg [2:0]  state;
    reg [13:0] timer;       // up to 16383 counts (~164 us at 100 MHz)
    reg [3:0]  bit_cnt;     // 0-7 = data, 8 = parity, 9 = stop
    reg [7:0]  shift_reg;
    reg        parity;      // odd parity
    reg [17:0] watchdog;    // ~2.6 ms timeout

    always @(posedge clk) begin
        if (rst) begin
            state        <= S_IDLE;
            tx_busy      <= 1'b0;
            tx_done      <= 1'b0;
            tx_err       <= 1'b0;
            ps2_clk_oe   <= 1'b0;
            ps2_data_out <= 1'b1;
            ps2_data_oe  <= 1'b0;
            timer        <= 14'd0;
            bit_cnt      <= 4'd0;
            shift_reg    <= 8'd0;
            parity       <= 1'b0;
            watchdog     <= 18'd0;
        end else begin
            tx_done <= 1'b0;
            tx_err  <= 1'b0;

            case (state)
                S_IDLE: begin
                    ps2_clk_oe   <= 1'b0;
                    ps2_data_oe  <= 1'b0;
                    ps2_data_out <= 1'b1;
                    tx_busy      <= 1'b0;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        parity    <= ~(tx_data[0] ^ tx_data[1] ^ tx_data[2] ^ tx_data[3] ^
                                       tx_data[4] ^ tx_data[5] ^ tx_data[6] ^ tx_data[7]);
                        tx_busy   <= 1'b1;
                        timer     <= 14'd0;
                        state     <= S_INHIBIT;
                    end
                end

                S_INHIBIT: begin
                    // Pull CLK low for ~110 us (11,000 cycles at 100 MHz)
                    ps2_clk_oe <= 1'b1;
                    ps2_data_oe <= 1'b0;
                    timer <= timer + 14'd1;
                    if (timer >= 14'd11000) begin
                        state <= S_REQ_SEND;
                    end
                end

                S_REQ_SEND: begin
                    // Pull DATA low (start bit), then release CLK
                    ps2_data_out <= 1'b0;
                    ps2_data_oe  <= 1'b1;
                    ps2_clk_oe   <= 1'b0;  // release CLK — device will start clocking
                    bit_cnt      <= 4'd0;
                    watchdog     <= 18'd0;
                    state        <= S_DATA;
                end

                S_DATA: begin
                    // Shift out bits on each falling edge of device-driven CLK
                    watchdog <= watchdog + 18'd1;
                    if (watchdog[17]) begin
                        // Timeout — device not responding
                        tx_err      <= 1'b1;
                        ps2_data_oe <= 1'b0;
                        ps2_clk_oe  <= 1'b0;
                        state       <= S_IDLE;
                    end else if (falling_edge) begin
                        watchdog <= 18'd0;
                        if (bit_cnt < 4'd8) begin
                            // Data bits (LSB first)
                            ps2_data_out <= shift_reg[0];
                            shift_reg    <= {1'b0, shift_reg[7:1]};
                            bit_cnt      <= bit_cnt + 4'd1;
                        end else if (bit_cnt == 4'd8) begin
                            // Parity bit
                            ps2_data_out <= parity;
                            bit_cnt      <= bit_cnt + 4'd1;
                        end else begin
                            // Stop bit — release DATA (high)
                            ps2_data_out <= 1'b1;
                            ps2_data_oe  <= 1'b0;
                            bit_cnt      <= 4'd0;
                            state        <= S_ACK;
                        end
                    end
                end

                S_ACK: begin
                    // Wait for device to pull DATA low on next falling edge (ACK)
                    watchdog <= watchdog + 18'd1;
                    if (watchdog[17]) begin
                        tx_err <= 1'b1;
                        state  <= S_IDLE;
                    end else if (falling_edge) begin
                        if (~ps2_data_in) begin
                            tx_done <= 1'b1;
                        end else begin
                            tx_err <= 1'b1;
                        end
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
