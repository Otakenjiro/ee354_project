`timescale 1ns / 1ps

module display_controller(
	input clk,
	output hSync, vSync,
	output reg bright,
	output reg [9:0] hCount,
	output reg [9:0] vCount
);

	// 25MHz pixel-rate enable derived from 100MHz main clock
	// All registers use the single main clock — no derived clocks,
	// no clock-domain crossing.
	reg [1:0] clk_div;
	initial clk_div = 0;

	always @(posedge clk)
		clk_div <= clk_div + 2'd1;

	wire clk_en = (clk_div == 2'd0);

	initial begin
		hCount = 0;
		vCount = 0;
		bright = 0;
	end

	always @(posedge clk) begin
		if (clk_en) begin
			if (hCount < 10'd799) begin
				hCount <= hCount + 10'd1;
			end else begin
				hCount <= 10'd0;
				if (vCount < 10'd524)
					vCount <= vCount + 10'd1;
				else
					vCount <= 10'd0;
			end
		end
	end

	assign hSync = (hCount < 10'd96) ? 1'b1 : 1'b0;
	assign vSync = (vCount < 10'd2)  ? 1'b1 : 1'b0;

	always @(posedge clk) begin
		if (clk_en)
			bright <= (hCount > 10'd143) && (hCount < 10'd784) &&
			          (vCount > 10'd34)  && (vCount < 10'd516);
	end

endmodule
