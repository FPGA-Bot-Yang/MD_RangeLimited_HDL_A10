/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Evaluation_1st_Order.v
//
//	Function: Evaluate the piarwise LJ force between 2 particles using 1st order interpolation (interpolation index is generated in Matlab (under Ethan_GoldenModel/Matlab_Interpolation))
// 			1 tile of force pipeline, without filter
//				Taking 2 particles' position data as input
//				
//
// Dependency:
// 			RL_Evaluate_Pairs_LJ_1st_Order.v      (11 cycles)
//				r2_compute.v      (13 cycles)
//
//	Latency: Between Start and first valid: 13+11=24 cycles
//
// Created by: Chen Yang 07/25/18
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_LJ_Evaluation_1st_Order
#(
	parameter DATA_WIDTH 				= 32,
	parameter INTERPOLATION_ORDER		= 1,
	parameter SEGMENT_NUM				= 14,
	parameter SEGMENT_WIDTH				= 4,
	parameter BIN_WIDTH					= 8,
	parameter BIN_NUM						= 256,
	parameter CUTOFF_2					= 32'h43100000,						// (12^2=144 in IEEE floating point)
	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input  clock,
	input  resetn,
	input  ivalid,
	input  iready,
	output ovalid,
	output oready,
//	input  [DATA_WIDTH-1:0] ref_x,
//	input  [DATA_WIDTH-1:0] ref_y,
//	input  [DATA_WIDTH-1:0] ref_z,
//	input  [DATA_WIDTH-1:0] neighbor_x,
//	input  [DATA_WIDTH-1:0] neighbor_y,
//	input  [DATA_WIDTH-1:0] neighbor_z,
	input  [4*DATA_WIDTH-1:0] reference,
	input  [4*DATA_WIDTH-1:0] neighbor,
	output [4*DATA_WIDTH-1:0] forceoutput
);

	assign oready = iready;
	
	wire [DATA_WIDTH-1:0] ref_x;
	wire [DATA_WIDTH-1:0] ref_y;
	wire [DATA_WIDTH-1:0] ref_z;
	wire [DATA_WIDTH-1:0] neighbor_x;
	wire [DATA_WIDTH-1:0] neighbor_y;
	wire [DATA_WIDTH-1:0] neighbor_z;
	assign ref_x = reference[DATA_WIDTH-1:0];
	assign ref_y = reference[2*DATA_WIDTH-1:DATA_WIDTH];
	assign ref_z = reference[3*DATA_WIDTH-1:2*DATA_WIDTH];
	assign neighbor_x = neighbor[DATA_WIDTH-1:0];
	assign neighbor_y = neighbor[2*DATA_WIDTH-1:DATA_WIDTH];
	assign neighbor_z = neighbor[3*DATA_WIDTH-1:2*DATA_WIDTH];

	//////////////////////////////////////////////////////////////////////////////////////
	// Wires connection r2_evaluation and force_evaluation
	//////////////////////////////////////////////////////////////////////////////////////
	
	wire [DATA_WIDTH-1:0] r2;
	wire r2_valid;
	wire [DATA_WIDTH-1:0] dx;
	wire [DATA_WIDTH-1:0] dy;
	wire [DATA_WIDTH-1:0] dz;
	
	wire [DATA_WIDTH-1:0] forceoutput_x;
	wire [DATA_WIDTH-1:0] forceoutput_y;
	wire [DATA_WIDTH-1:0] forceoutput_z;
	assign forceoutput = {32'd0,forceoutput_z,forceoutput_y,forceoutput_x};
	
	
	r2_compute #(DATA_WIDTH) r2_evaluate(
		.clk(clock),
		.rst(!resetn),
		.enable(ivalid),						// Connect to FSM controller
		.refx(ref_x),
		.refy(ref_y),
		.refz(ref_z),
		.posx(neighbor_x),
		.posy(neighbor_y),
		.posz(neighbor_z),
		.r2(r2),										// Connect to RL_Evaluate_Pairs_LJ.r2
		.dx_out(dx),								// Connect to RL_Evaluate_Pairs_LJ.dx
		.dy_out(dy),								// Connect to RL_Evaluate_Pairs_LJ.dy
		.dz_out(dz),								// Connect to RL_Evaluate_Pairs_LJ.dz
		.r2_valid(r2_valid)						// Connect to RL_Evaluate_Pairs_LJ.r2_valid
		);

	RL_Evaluate_Pairs_LJ_1st_Order #(
		.DATA_WIDTH(DATA_WIDTH),
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_WIDTH(BIN_WIDTH),
		.BIN_NUM(BIN_NUM),
		.CUTOFF_2(CUTOFF_2),
		.LOOKUP_NUM(LOOKUP_NUM),
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	RL_Evaluate_Pairs_LJ(
		.clk(clock),
		.rst(!resetn),
		.r2_valid(r2_valid),						// Connect to r2_compute.r2_valid
		.r2(r2),										// Connect to r2_compute.r2
		.dx(dx),										// Connect to r2_compute.dx
		.dy(dy),										// Connect to r2_compute.dy
		.dz(dz),										// Connect to r2_compute.dz
		.LJ_Force_X(forceoutput_x),			// Connect to output
		.LJ_Force_Y(forceoutput_y),			// Connect to output
		.LJ_Force_Z(forceoutput_z),			// Connect to output
		.LJ_force_valid(ovalid)	// Connect to output
		);

endmodule


