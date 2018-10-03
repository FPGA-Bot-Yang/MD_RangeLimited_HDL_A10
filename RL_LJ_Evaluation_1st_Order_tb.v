/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Evaluate_Pairs_LJ_1st_Order_tb.v
//
//	Function: Testbench for timing and result evaluation of RL_LJ_Evaluation_1st_Order.v
//
// Dependency:
// 			RL_LJ_Evaluation_1st_Order.v
//
// Reference:
//		A reference script is provided along with this testbench, using same input data.
//
// FP IP timing:
//				FP_SUB: ay - ax = result				latency: 2
//				FP_MUL: ay * az = result				latency: 3
//				FP_MUL_ADD: ay * az + ax  = result	latency: 4
//
// Latency: total: 24 cycles
//				r2_compute: 13 cycles
//				RL_Evaluate_Pairs_LJ_1st_Order: 11 cycles
//
// Created by: Chen Yang 07/15/18
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps

module RL_LJ_Evaluation_1st_Order_tb;

	reg clk;
	reg rst;
	
	reg iready_wire;
	reg ivalid_wire;
	reg [31:0] ref_x_wire;
	reg [31:0] ref_y_wire;
	reg [31:0] ref_z_wire;
	reg [31:0] neighbor_x_wire;
	reg [31:0] neighbor_y_wire;
	reg [31:0] neighbor_z_wire;
	
	reg iready;
	reg ivalid;
	reg [31:0] ref_x;
	reg [31:0] ref_y;
	reg [31:0] ref_z;
	reg [31:0] neighbor_x;
	reg [31:0] neighbor_y;
	reg [31:0] neighbor_z;
	
	wire [127:0] forceoutput;
	wire ovalid;
	wire oready;
	
	wire [31:0] LJ_Force_X;
	wire [31:0] LJ_Force_Y;
	wire [31:0] LJ_Force_Z;
	
	assign LJ_Force_X = forceoutput[31:0];
	assign LJ_Force_Y = forceoutput[63:32];
	assign LJ_Force_Z = forceoutput[95:64];

	RL_LJ_Evaluation_1st_Order test_inst
	(
		.clock(clk),
		.resetn(!rst),
		.ivalid(ivalid),
		.iready(iready),
		.ovalid(ovalid),
		.oready(oready),
		//.ref_x(ref_x),
		//.ref_y(ref_y),
		//.ref_z(ref_z),
		//.neighbor_x(neighbor_x),
		//.neighbor_y(neighbor_y),
		//.neighbor_z(neighbor_z),
		.reference({32'd0,ref_z,ref_y,ref_x}),
		.neighbor({32'd0,neighbor_z,neighbor_y,neighbor_x}),
		.forceoutput(forceoutput)
	);
	
	always #1 clk <= ~clk;
	
	always@(posedge clk)
		begin
		iready <= iready_wire;
		ivalid <= ivalid_wire;
		ref_x <= ref_x_wire;
		ref_y <= ref_y_wire;
		ref_z <= ref_z_wire;
		neighbor_x <= neighbor_x_wire;
		neighbor_y <= neighbor_y_wire;
		neighbor_z <= neighbor_z_wire;
		end
	
	initial begin
		clk <= 1'b1;
		rst <= 1'b1;
		
		iready_wire <= 1'b1;
		ivalid_wire <= 1'b0;
		
		ref_x_wire <= 32'd0;
		ref_y_wire <= 32'd0;
		ref_z_wire <= 32'd0;
		neighbor_x_wire <= 32'd0;
		neighbor_y_wire <= 32'd0;
		neighbor_z_wire <= 32'd0;
		
		#10
		rst <= 1'b0;
		
		// dx = 1, dy = 2, dz = 4, r2 = 21
		#10
		ivalid_wire <= 1'b1;
		ref_x_wire <= 32'h3F800000;				// 1.0
		ref_y_wire <= 32'h3F800000;				// 1.0
		ref_z_wire <= 32'h3F800000;				// 1.0
		neighbor_x_wire <= 32'h40000000;				// 2.0
		neighbor_y_wire <= 32'h40400000;				// 3.0
		neighbor_z_wire <= 32'h40A00000;				// 5.0
		
		// dx = 2, dy = 2, dz = 2, r2 = 12
		#2
		ivalid_wire <= 1'b1;
		ref_x_wire <= 32'h40000000;				// 2.0
		ref_y_wire <= 32'h40000000;				// 2.0
		ref_z_wire <= 32'h40000000;				// 2.0
		neighbor_x_wire <= 32'h40800000;				// 4.0
		neighbor_y_wire <= 32'h40800000;				// 4.0
		neighbor_z_wire <= 32'h40800000;				// 4.0
		
		// dx = 1, dy = 4, dz = 8, r2 = 81
		#2
		ivalid_wire <= 1'b1;
		ref_x_wire <= 32'h3F800000;				// 1.0
		ref_y_wire <= 32'h3F800000;				// 1.0
		ref_z_wire <= 32'h3F800000;				// 1.0
		neighbor_x_wire <= 32'h40000000;				// 2.0
		neighbor_y_wire <= 32'h40A00000;				// 5.0
		neighbor_z_wire <= 32'h41100000;				// 9.0

		#20
		ivalid_wire <= 1'b0;

		#100
		$stop;
		
	end
	
endmodule