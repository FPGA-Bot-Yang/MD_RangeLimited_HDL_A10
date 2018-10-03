/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Evaluate_Pairs_LJ_1st_Order.v
//
//	Function: Evaluate the piarwise non-bonded force (LJ force only) between the intput particle pair using 1st order interpolation (interpolation index is generated in Matlab)
// 			Taking the square distance as input
//				Based on the sqaure distance, evaluate the table look-up entry
//				Evaluate the force component on x,y,z direction as output
//
// Dependency:
// 			Table memory module
//				FP_MUL_ADD
//				FP_MUL
//				FP_SUB
//
//
// FP IP timing:
//				FP_SUB: ay - ax = result				latency: 2
//				FP_MUL: ay * az = result				latency: 3
//				FP_MUL_ADD: ay * az + ax  = result	latency: 4
//
// Latency: total: 11 cycles
//				Input level: wait for table lookup to finish					      2 cycle
//				Level 1: calculate r8, r14 (MUL_ADD)						         4 cycles
//				Level 2: calculate LJ force (SUB)							         2 cycles
//				Level 3: calculate Force component in each direction (MUL)		3 cycles
//
// Created by: Chen Yang 07/15/18
//					Using single precision floating point
//					For IEEE Floating Point, the it follows the format: MSB: sign, 8-bit exponent, 23 mantissa.
//					The 8-bit exponent will be used to locate the bin, the high order bit on the mantissa used for locating bins
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_Evaluate_Pairs_LJ_1st_Order
#(
	parameter DATA_WIDTH 				= 32,
	parameter SEGMENT_NUM				= 14,
	parameter SEGMENT_WIDTH				= 4,
	parameter BIN_WIDTH					= 8,
	parameter BIN_NUM						= 256,
	parameter CUTOFF_2					= 32'h43100000,						// (12^2=144 in IEEE floating point)

	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input  clk,
	input  rst,
	input  r2_valid,
	input  [DATA_WIDTH-1:0] r2,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] dx,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] dy,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] dz,										// in IEEE floating point
	output [DATA_WIDTH-1:0] LJ_Force_X,								// in IEEE floating point
	output [DATA_WIDTH-1:0] LJ_Force_Y,								// in IEEE floating point
	output [DATA_WIDTH-1:0] LJ_Force_Z,								// in IEEE floating point
	output reg LJ_force_valid
);
	
	wire table_rden;														// Table lookup enable
	wire [LOOKUP_ADDR_WIDTH - 1:0] rdaddr;							// Table lookup address
	
	// Create a 2 cycles delay of the input R2 value, thus allow the table lookup entry to be readout from RAM
	reg [DATA_WIDTH-1:0] r2_reg1;
	reg [DATA_WIDTH-1:0] r2_delay;
	
	reg level1_en;															// Mul-Add enable: Calculate r8, r14 using interpolation
	reg level2_en;															// Sub enable: Calculate LJ Force
	reg level3_en;															// Mul enable: Calculate LJ Force component in each direction
	reg table_rden_reg1;
	reg level1_en_reg1;
	reg level1_en_reg2;
	reg level1_en_reg3;
	reg level2_en_reg1;
	reg level3_en_reg1;
	reg level3_en_reg2;
	
	// Delay register to propogate dx, dy, dz, delay for 2+4+2=8 cycles
	reg [DATA_WIDTH-1:0] dx_reg1;
	reg [DATA_WIDTH-1:0] dx_reg2;
	reg [DATA_WIDTH-1:0] dx_reg3;
	reg [DATA_WIDTH-1:0] dx_reg4;
	reg [DATA_WIDTH-1:0] dx_reg5;
	reg [DATA_WIDTH-1:0] dx_reg6;
	reg [DATA_WIDTH-1:0] dx_reg7;
	reg [DATA_WIDTH-1:0] dx_reg8;
	reg [DATA_WIDTH-1:0] dx_reg9;
	
	reg [DATA_WIDTH-1:0] dy_reg1;
	reg [DATA_WIDTH-1:0] dy_reg2;
	reg [DATA_WIDTH-1:0] dy_reg3;
	reg [DATA_WIDTH-1:0] dy_reg4;
	reg [DATA_WIDTH-1:0] dy_reg5;
	reg [DATA_WIDTH-1:0] dy_reg6;
	reg [DATA_WIDTH-1:0] dy_reg7;
	reg [DATA_WIDTH-1:0] dy_reg8;
	reg [DATA_WIDTH-1:0] dy_reg9;
	
	reg [DATA_WIDTH-1:0] dz_reg1;
	reg [DATA_WIDTH-1:0] dz_reg2;
	reg [DATA_WIDTH-1:0] dz_reg3;
	reg [DATA_WIDTH-1:0] dz_reg4;
	reg [DATA_WIDTH-1:0] dz_reg5;
	reg [DATA_WIDTH-1:0] dz_reg6;
	reg [DATA_WIDTH-1:0] dz_reg7;
	reg [DATA_WIDTH-1:0] dz_reg8;
	reg [DATA_WIDTH-1:0] dz_reg9;
	
	reg [DATA_WIDTH-1:0] r2_reg2;
	reg [DATA_WIDTH-1:0] r2_reg3;
	reg [DATA_WIDTH-1:0] r2_reg4;
	reg [DATA_WIDTH-1:0] r2_reg5;
	reg [DATA_WIDTH-1:0] r2_reg6;
	reg [DATA_WIDTH-1:0] r2_reg7;
	reg [DATA_WIDTH-1:0] r2_reg8;
	reg [DATA_WIDTH-1:0] r2_reg9;
	reg [DATA_WIDTH-1:0] r2_reg10;
	reg [DATA_WIDTH-1:0] r2_output_selection;
	
	reg [SEGMENT_WIDTH - 1:0] segment_id;							// Segment id, determined by r2 exponential part
	reg [BIN_WIDTH - 1:0] bin_id;										// Bin id, determined by r2 mantissa high order bits
	
	wire [DATA_WIDTH-1:0] terms0_r8,terms0_r14,terms1_r8,terms1_r14;
	wire [DATA_WIDTH-1:0] r14_result, r8_result;	// final result for r3, r8, r14
	wire [DATA_WIDTH-1:0] LJ_force;
	wire [DATA_WIDTH-1:0] LJ_Force_X_wire, LJ_Force_Y_wire, LJ_Force_Z_wire;
	
	assign table_rden = r2_valid;
	
	assign rdaddr = {segment_id, bin_id};							// asssign the table lookup address
	
	// assign output force (if exceed cutoff, then set as 0)
	assign LJ_Force_X = (r2_delay > CUTOFF_2) ? 0 : LJ_Force_X_wire;
	assign LJ_Force_Y = (r2_delay > CUTOFF_2) ? 0 : LJ_Force_Y_wire;
	assign LJ_Force_Z = (r2_delay > CUTOFF_2) ? 0 : LJ_Force_Z_wire;
	
	// Generate table lookup address
	always@(*)
		if(rst)
			begin		
			segment_id <= 0;
			bin_id <= 0;
			end
		else
			begin
				// Table lookup starting from 0.015625 = 2^-6
				// assign bin_id
				bin_id = r2[22:22-BIN_WIDTH+1];
				
				// assign segment_id
				if(r2[30:23] - 8'd121 < SEGMENT_NUM && r2[30:23] - 8'd121 >= 0)
					segment_id = r2[30:23] - 8'd121;
				else
					segment_id = 0;
			end
	
	
	always@(posedge clk)
		begin
		if(rst)
			begin
			// delay the input r2 value by 2 cycle to wait for table lookup to finish
			r2_reg1 <= 0;
			r2_delay <= 0;
			// delay registers to propagate the enable signal of FP IP units
			table_rden_reg1 <= 1'b0;
			level1_en <= 1'b0;
			level1_en_reg1 <= 1'b0;
			level1_en_reg2 <= 1'b0;
			level1_en_reg3 <= 1'b0;
			level2_en <= 1'b0;
			level2_en_reg1 <= 1'b0;
			level3_en <= 1'b0;
			level3_en_reg1 <= 1'b0;
			level3_en_reg2 <= 1'b0;
			LJ_force_valid <= 1'b0;
			// delay registers to propogate the dx, dy, dz input
			dx_reg1 <= 0;
			dx_reg2 <= 0;
			dx_reg3 <= 0;
			dx_reg4 <= 0;
			dx_reg5 <= 0;
			dx_reg6 <= 0;
			dx_reg7 <= 0;
			dx_reg8 <= 0;
			
			dy_reg1 <= 0;
			dy_reg2 <= 0;
			dy_reg3 <= 0;
			dy_reg4 <= 0;
			dy_reg5 <= 0;
			dy_reg6 <= 0;
			dy_reg7 <= 0;
			dy_reg8 <= 0;
			
			dz_reg1 <= 0;
			dz_reg2 <= 0;
			dz_reg3 <= 0;
			dz_reg4 <= 0;
			dz_reg5 <= 0;
			dz_reg6 <= 0;
			dz_reg7 <= 0;
			dz_reg8 <= 0;
			
			r2_reg2 <= 0;
			r2_reg3 <= 0;
			r2_reg4 <= 0;
			r2_reg5 <= 0;
			r2_reg6 <= 0;
			r2_reg7 <= 0;
			r2_reg8 <= 0;
			r2_reg9 <= 0;
			r2_reg10 <= 0;
			r2_output_selection <= 0;
			end
		else
			begin
			// delay the input r2 value by 1 cycle to wait for table lookup to finish
			r2_reg1 <= r2;
			r2_delay <= r2_reg1;
			// 2 cycle delay between table lookup enable and polynomial calculation
			table_rden_reg1 <= table_rden;
			level1_en <= table_rden_reg1;
			// 4 cycle delay between the starting of polynomical calculation and LJ force calculation
			level1_en_reg1 <= level1_en;
			level1_en_reg2 <= level1_en_reg1;
			level1_en_reg3 <= level1_en_reg2;		
			level2_en <= level1_en_reg3;
			// 2 cycle delay between the starting of LJ force calculation and force component evaluation
			level2_en_reg1 <= level2_en;
			level3_en <= level2_en_reg1;
			// 3 cycle delay between the starting of force component evaluation and the final output LJ force
			level3_en_reg1 <= level3_en;
			level3_en_reg2 <= level3_en_reg1;
			LJ_force_valid <= level3_en_reg2;
			// 8 cycle delay between the input of dx, dy, dz before it used for calculate LJ force components
			dx_reg1 <= dx;
			dx_reg2 <= dx_reg1;
			dx_reg3 <= dx_reg2;
			dx_reg4 <= dx_reg3;
			dx_reg5 <= dx_reg4;
			dx_reg6 <= dx_reg5;
			dx_reg7 <= dx_reg6;
			dx_reg8 <= dx_reg7;
			
			dy_reg1 <= dy;
			dy_reg2 <= dy_reg1;
			dy_reg3 <= dy_reg2;
			dy_reg4 <= dy_reg3;
			dy_reg5 <= dy_reg4;
			dy_reg6 <= dy_reg5;
			dy_reg7 <= dy_reg6;
			dy_reg8 <= dy_reg7;
			
			dz_reg1 <= dz;
			dz_reg2 <= dz_reg1;
			dz_reg3 <= dz_reg2;
			dz_reg4 <= dz_reg3;
			dz_reg5 <= dz_reg4;
			dz_reg6 <= dz_reg5;
			dz_reg7 <= dz_reg6;
			dz_reg8 <= dz_reg7;
			
			r2_reg2 <= r2_reg1;
			r2_reg3 <= r2_reg2;
			r2_reg4 <= r2_reg3;
			r2_reg5 <= r2_reg4;
			r2_reg6 <= r2_reg5;
			r2_reg7 <= r2_reg6;
			r2_reg8 <= r2_reg7;
			r2_reg9 <= r2_reg8;
			r2_reg10 <= r2_reg9;
			r2_output_selection <= r2_reg10;
			end
		end

	lut0_14
	#(
		.DEPTH(LOOKUP_NUM),
		.ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	lut0_14 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms0_r14)
		);

	lut1_14
	#(
		.DEPTH(LOOKUP_NUM),
		.ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	lut1_14 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms1_r14)
		);

	lut0_8
	#(
		.DEPTH(LOOKUP_NUM),
		.ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	lut0_8 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms0_r8)
		);

	lut1_8
	#(
		.DEPTH(LOOKUP_NUM),
		.ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	lut1_8 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms1_r8)
		);

	// Get r8 term = c1 * r2 + c0 (The coefficient of 24 is already included when generating the table)
	FP_MUL_ADD FP_MUL_r8_term (
		.ax     (terms0_r8),     //   input,  width = 32,     ax.ax
		.ay     (terms1_r8),     //   input,  width = 32,     ay.ay
		.az     (r2_delay),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.aclr   (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_en),     //   input,   width = 1,    ena.ena
		.result (r8_result)      //   output,  width = 32, result.result
	);
	
	// Get r14 term = c1 * r2 + c0 (The coefficient of 48 is already included when generating the table)
	FP_MUL_ADD FP_MUL_r14_term (
		.ax     (terms0_r14),    //   input,  width = 32,     ax.ax
		.ay     (terms1_r14),    //   input,  width = 32,     ay.ay
		.az     (r2_delay),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.aclr   (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_en),     //   input,   width = 1,    ena.ena
		.result (r14_result)     //   output,  width = 32, result.result
	);
	
	// Get Force/J = R14_term - R8_term
	FP_SUB FP_SUB_Total_Force (
		.ax     (r8_result),     //   input,  width = 32,     ax.ax
		.ay     (r14_result),    //   input,  width = 32,     ay.ay
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.aclr   (rst),           //   input,   width = 2,    clr.clr
		.ena    (level2_en),     //   input,   width = 1,    ena.ena
		.result (LJ_force)       //   output,  width = 32, result.result
	);
	
	// Get Force component on X direction: Fx = (Force/J) * dx
	FP_MUL FP_MUL_FX(
		.clk(clk),					 //   input,   width = 1,    clk.clk
		.ena(level3_en),         //   input,   width = 1,    ena.ena
		.aclr(rst),              //   input,   width = 2,    clr.clr
		.ay(LJ_force),           //   input,  width = 32,     ay.ay
		.az(dx_reg8),            //   input,  width = 32,     az.az
		.result(LJ_Force_X_wire)      //   output,  width = 32, result.result
	);
	
	// Get Force component on Y direction: Fy = (Force/J) * dy
	FP_MUL FP_MUL_FY(
		.clk(clk),					 //   input,   width = 1,    clk.clk
		.ena(level3_en),         //   input,   width = 1,    ena.ena
		.aclr(rst),              //   input,   width = 2,    clr.clr
		.ay(LJ_force),           //   input,  width = 32,     ay.ay
		.az(dy_reg8),            //   input,  width = 32,     az.az
		.result(LJ_Force_Y_wire)      //   output,  width = 32, result.result
	);
	
	// Get Force component on Z direction: Fz = (Force/J) * dz
	FP_MUL FP_MUL_FZ(
		.clk(clk),					 //   input,   width = 1,    clk.clk
		.ena(level3_en),         //   input,   width = 1,    ena.ena
		.aclr(rst),              //   input,   width = 2,    clr.clr
		.ay(LJ_force),           //   input,  width = 32,     ay.ay
		.az(dz_reg8),            //   input,  width = 32,     az.az
		.result(LJ_Force_Z_wire)      //   output,  width = 32, result.result
	);
	
endmodule

