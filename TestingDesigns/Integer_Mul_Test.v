module Integer_Mul_Test(
	input clk,
	input rst_n,
	input [10:0] A1,
	input [10:0] B1,
	input [10:0] A2,
	input [10:0] B2,
	output reg [21:0] C1,
	output reg [21:0] C2
);

	always@(posedge clk)
	begin
		if(~rst_n)
			begin
			C1 <= 21'd0;
			C2 <= 21'd0;
			end
		else
			begin
			C1 <= A1 * B1;
			C2 <= A2 * B2;
			end
	end	

endmodule