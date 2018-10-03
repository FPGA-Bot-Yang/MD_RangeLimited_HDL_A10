`timescale 1ps/1ps

module FP_test_tb;
	
	reg clk;
	reg ena;
	reg aclr;
	reg [31:0] ax;
	reg [31:0] ay;
	reg [31:0] az;
	wire [31:0] result_mul_add;
	wire [31:0] result_mul;
	wire [31:0] result_mul_then_add;
	wire [31:0] result_sub;
	wire [31:0] result_add;
	
	
	FP_Mult_Add FP_Mult_Add(
		.clk(clk),
		.ena(ena),
		.aclr(aclr),
		.ax(ax),
		.ay(ay),
		.az(az),
		.result(result_mul_add)
	);
	
	FP_Mult FP_Mult(
		.clk(clk),
		.ena(ena),
		.aclr(aclr),
		.ay(ay),
		.az(az),
		.result(result_mul)
	);
	
	FP_Add FP_Add(
		.clk(clk),
		.ena(ena),
		.aclr(aclr),
		.ax(ax),
		.ay(ay),
		.result(result_add)
	);
	
	FP_Sub FP_Sub(
		.clk(clk),
		.ena(ena),
		.aclr(aclr),
		.ax(ay),
		.ay(ax),
		.result(result_sub)
	);
	
	always #1 clk <= ~clk;
	
	initial begin
		clk <= 1'b1;
		ena <= 1'b0;
		aclr <= 1'b1;
		ax <= 32'h40000000;				// 2.0
		ay <= 32'h40800000;				// 4.0
		az <= 32'h41000000;				// 8.0
	
		#10
		ena <= 1'b1;
		#10
		aclr <= 1'b0;
		#50
		$stop;
	
	end

endmodule