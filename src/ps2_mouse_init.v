`timescale 1ns / 1ps

module ps2_mouse_init (
    input wire       clk,        // 100 MHz
    input wire       rst,

    // TX interface (directly wired to ps2_tx)
    output reg [7:0] tx_data,
    output reg       tx_start,
    input wire       tx_busy,
    input wire       tx_done,
    input wire       tx_err,

    // RX interface (from ps2_rx)
    input wire [7:0] rx_data,
    input wire       rx_valid,

    output reg       init_done   // stays high once mouse is streaming
);

    // ----------------------------------------------------------------
    //  States
    // ----------------------------------------------------------------
    localparam S_WAIT_PIC    = 3'd0;  // wait ~1 s for PIC24 USB enumeration
    localparam S_SEND_RESET  = 3'd1;  // send 0xFF (Reset)
    localparam S_WAIT_RESET  = 3'd2;  // wait for ACK (0xFA) + self-test (0xAA) + ID (0x00)
    localparam S_SEND_ENABLE = 3'd3;  // send 0xF4 (Enable Data Reporting)
    localparam S_WAIT_ENABLE = 3'd4;  // wait for ACK (0xFA)
    localparam S_DONE        = 3'd5;

    reg [2:0]  state;
    reg [26:0] wait_ctr;     // up to ~1.34 s at 100 MHz
    reg [1:0]  reset_phase;  // 0 = waiting ACK, 1 = waiting 0xAA, 2 = waiting 0x00
    reg [2:0]  retry_cnt;
    reg [24:0] timeout_ctr;  // ~335 ms per phase timeout

    always @(posedge clk) begin
        if (rst) begin
            state       <= S_WAIT_PIC;
            tx_data     <= 8'd0;
            tx_start    <= 1'b0;
            init_done   <= 1'b0;
            wait_ctr    <= 27'd0;
            reset_phase <= 2'd0;
            retry_cnt   <= 3'd0;
            timeout_ctr <= 25'd0;
        end else begin
            tx_start <= 1'b0;  // default: no start pulse

            case (state)
                S_WAIT_PIC: begin
                    // Wait ~1 second (100,000,000 cycles) for USB enumeration
                    wait_ctr <= wait_ctr + 27'd1;
                    if (wait_ctr >= 27'd100_000_000) begin
                        state <= S_SEND_RESET;
                    end
                end

                S_SEND_RESET: begin
                    if (~tx_busy) begin
                        tx_data     <= 8'hFF;  // Reset command
                        tx_start    <= 1'b1;
                        reset_phase <= 2'd0;
                        timeout_ctr <= 25'd0;
                        state       <= S_WAIT_RESET;
                    end
                end

                S_WAIT_RESET: begin
                    // Wait for up to 3 response bytes: ACK (0xFA), self-test (0xAA), ID (0x00)
                    // PIC24 may not relay all bytes, so timeout and proceed after any phase
                    timeout_ctr <= timeout_ctr + 25'd1;

                    if (rx_valid) begin
                        timeout_ctr <= 25'd0;
                        case (reset_phase)
                            2'd0: begin // expecting ACK (0xFA)
                                if (rx_data == 8'hFA)
                                    reset_phase <= 2'd1;
                                // ignore non-ACK bytes
                            end
                            2'd1: begin // expecting self-test pass (0xAA)
                                if (rx_data == 8'hAA)
                                    reset_phase <= 2'd2;
                            end
                            2'd2: begin // expecting mouse ID (0x00)
                                // Got all 3 response bytes — proceed to enable
                                state <= S_SEND_ENABLE;
                            end
                        endcase
                    end

                    // Timeout after ~335 ms — PIC24 may not relay all bytes
                    if (timeout_ctr[24]) begin
                        if (reset_phase > 2'd0) begin
                            // Got at least ACK — proceed
                            state <= S_SEND_ENABLE;
                        end else begin
                            // No ACK at all — retry (up to 3 times)
                            if (retry_cnt < 3'd3) begin
                                retry_cnt <= retry_cnt + 3'd1;
                                state     <= S_SEND_RESET;
                            end else begin
                                // Give up on reset, try enable anyway
                                state <= S_SEND_ENABLE;
                            end
                        end
                    end
                end

                S_SEND_ENABLE: begin
                    if (~tx_busy) begin
                        tx_data     <= 8'hF4;  // Enable Data Reporting
                        tx_start    <= 1'b1;
                        timeout_ctr <= 25'd0;
                        retry_cnt   <= 3'd0;
                        state       <= S_WAIT_ENABLE;
                    end
                end

                S_WAIT_ENABLE: begin
                    timeout_ctr <= timeout_ctr + 25'd1;

                    if (rx_valid && rx_data == 8'hFA) begin
                        // Got ACK — mouse will now stream data
                        init_done <= 1'b1;
                        state     <= S_DONE;
                    end

                    if (timeout_ctr[24]) begin
                        if (retry_cnt < 3'd3) begin
                            retry_cnt <= retry_cnt + 3'd1;
                            state     <= S_SEND_ENABLE;
                        end else begin
                            // Assume success after retries — some mice start without ACK
                            init_done <= 1'b1;
                            state     <= S_DONE;
                        end
                    end
                end

                S_DONE: begin
                    init_done <= 1'b1;
                end

                default: state <= S_WAIT_PIC;
            endcase
        end
    end

endmodule
