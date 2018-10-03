`timescale 1ps/1ps

module ram_test_tb;
	
	reg [11:0] address;
	reg clk;
	reg [31:0] input_data;
	reg wren;
	wire [31:0] rd_data;
	
	
	ram_test_top test_inst(
		.address(address),
		.clock(clk),
		.data(input_data),
		.wren(wren),
		.rd_data(rd_data)
	);
	
	always #1 clk <= ~clk;
	
	initial begin
		clk <= 1'b1;
		wren <= 1'b0;
		input_data <= 32'hDEADBEEF;
		address <= 1'd0;
	
		#10
		address <= 12'd1;
		#10
		address <= 12'd2;
		#10
		address <= 12'd3;
		#10
		wren <= 1'b1;
		address <= 12'd4;
		#10
		wren <= 1'b0;
		address <= 12'd4;
		#10
		address <= 12'd5;
		#50
		$stop;
	
	end

endmodule