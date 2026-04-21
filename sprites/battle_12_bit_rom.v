module battle_rom
	(
		input wire clk,
		input wire [8:0] row,
		input wire [9:0] col,
		output reg [11:0] color_data
	);

	// 320x240 image stored in BRAM, displayed at 2x (each pixel = 2x2 block)
	localparam HALF_W = 320;
	localparam DEPTH  = 76800;  // 320 * 240

	(* rom_style = "block" *)
	reg [11:0] mem [0:DEPTH-1];

	initial $readmemh("battle_bg.mem", mem);

	// Downscale coordinates: divide by 2
	wire [7:0] half_row = row[8:1];  // 0-239
	wire [8:0] half_col = col[9:1];  // 0-319

	// Address = half_row * 320 + half_col
	// 320 = 256 + 64, so multiply using shifts + add
	wire [16:0] addr = ({9'b0, half_row} << 8)
	                  + ({9'b0, half_row} << 6)
	                  + {8'b0, half_col};

	always @(posedge clk)
		color_data <= mem[addr];

endmodule
