module sevenSegmentDecoder (
	input wire [3:0] bcd,
	output reg [7:0] ssd
);

	// The SSD is 'active low', which means the various segments are illuminated 
	// when supplied with logic low '0'.

	always @(*) begin
		case(bcd)
			4'd0 : ssd = 8'b11000000;
			4'd1 : ssd = 8'b11111001;
			4'd2 : ssd = 8'b10100100;
			4'd3 : ssd = 8'b10110000;
			4'd4 : ssd = 8'b10011001;
			4'd5 : ssd = 8'b10010010;
			4'd6 : ssd = 8'b10000010;
			4'd7 : ssd = 8'b11111000;
			4'd8 : ssd = 8'b10000000;
			4'd9 : ssd = 8'b10010000;
			4'd10 : ssd = 8'b10111111; // Dash 
			4'd11 : ssd = 8'b01111111; // Dot
			4'd12 : ssd = 8'b11111111; 

			default : ssd = 8'b11111111;
		endcase
	end

endmodule