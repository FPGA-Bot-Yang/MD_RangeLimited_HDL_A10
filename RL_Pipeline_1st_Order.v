/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Pipeline_1st_Order.v
//
//	Function: Evaluate the piarwise non-bonded force between particle pairs using 1st order interpolation (interpolation index is generated in Matlab (under Ethan_GoldenModel/Matlab_Interpolation))
// 			1 tile of force pipeline, without filter
//				for each force pipeline, there are 2 banks of brams to feed position data of particle pairs which are already filtered.
//
// Dependency:
// 			RL_Evaluate_Pairs_LJ_1st_Order.v
//				r2_compute.v
//
//	Latency: Between Start and first valid: 25 cycles
//
// Created by: Chen Yang 07/16/18
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_Pipeline_1st_Order
#(
	parameter DATA_WIDTH 				= 32,
	parameter INTERPOLATION_ORDER		= 1,
	parameter SEGMENT_NUM				= 14,
	parameter SEGMENT_WIDTH				= 4,
	parameter BIN_WIDTH					= 8,
	parameter BIN_NUM						= 256,
	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input  clk,
	input  rst,
	input  start,
	output [DATA_WIDTH-1:0] forceoutput_x,
	output [DATA_WIDTH-1:0] forceoutput_y,
	output [DATA_WIDTH-1:0] forceoutput_z,
	output forceoutput_valid,
	output reg done
);
	
	// rst & start signal is given by in-memory content editor
//	wire rst;
//	wire start;
	
//	wire [DATA_WIDTH-1:0] p_a;
//	wire [DATA_WIDTH-1:0] p_b;
//	wire [DATA_WIDTH-1:0] p_qq;
//	
//	assign p_a  = 32'h40000000;				// p_a = 2, in IEEE floating point format
//	assign p_b  = 32'h40800000;				// p_b = 4, in IEEE floating point format
//	assign p_qq = 32'h41000000;				// p_qq = 8, in IEEE floating point format

	//////////////////////////////////////////////////////////////////////////////////////
	// Wires connecting input position data ram and r2_evaluation
	//////////////////////////////////////////////////////////////////////////////////////
	wire [DATA_WIDTH-1:0] refx;	
	wire [DATA_WIDTH-1:0] posx;
	wire [DATA_WIDTH-1:0] refy;
	wire [DATA_WIDTH-1:0] posy;
	wire [DATA_WIDTH-1:0] refz;
	wire [DATA_WIDTH-1:0] posz;

	reg rden;
	reg wren;

	reg [8:0] neighbor_rdaddr;
	reg [8:0] home_rdaddr;

	//////////////////////////////////////////////////////////////////////////////////////
	// Wires connection r2_evaluation and force_evaluation
	//////////////////////////////////////////////////////////////////////////////////////
	reg r2_enable;									// control signal that enables R2 calculation, this signal should have 1 cycle delay of the rden signal, thus wait for the data read out from BRAM
	wire [DATA_WIDTH-1:0] r2;
	wire r2_valid;
	wire [DATA_WIDTH-1:0] dx;
	wire [DATA_WIDTH-1:0] dy;
	wire [DATA_WIDTH-1:0] dz;
	
	
	//////////////////////////////////////////////////////////////////////////////////////
	// Control FSM
	//////////////////////////////////////////////////////////////////////////////////////
	parameter WAIT_FOR_START = 2'b00;
	parameter START 			 = 2'b01;
	parameter EVALUATION 	 = 2'b10;
	parameter DONE 			 = 2'b11;
	reg [1:0] state;
	
	always@(posedge clk)
		if(rst)
			begin
			neighbor_rdaddr <= 9'd0;
			home_rdaddr <= 9'd0;
			wren <= 1'b0;
			rden <= 1'b0;
			r2_enable <= 1'b0;
			
			state <= WAIT_FOR_START;
			end
		else if(start)
			begin
			r2_enable <= rden;				// Assign the r2_enable signal, one cycle delay from the rden signal
			
			wren <= 1'b0;						// temporarily disable write back to position ram
			case(state)
				WAIT_FOR_START:				// Wait for the input start signal from outside
					begin
					neighbor_rdaddr <= 9'd0;
					home_rdaddr <= 9'd0;
					rden <= 1'b0;
					done <= 1'b0;
					if(start)
						state <= START;
					else
						state <= WAIT_FOR_START;
					end
					
				START:							// Evaluate the first pair (start from addr = 0)
					begin
					neighbor_rdaddr <= 9'd0;
					home_rdaddr <= 9'd0;
					
					done <= 1'b0;
					rden <= 1'b1;
					state <= EVALUATION;
					end
					
				EVALUATION:						// Evaluating all the particle pairs
					begin
					done <= 1'b0;
					
					neighbor_rdaddr <= neighbor_rdaddr + 1'b1;
					rden <= 1'b1;
					if(neighbor_rdaddr == 9'b111111111)
						home_rdaddr <= home_rdaddr + 1'b1;

					if(home_rdaddr < 9'b111111111)
						state <= EVALUATION;
					else
						state <= DONE;
					end
					
				DONE:								// Output a done signal
					begin
					done <= 1'b1;
					neighbor_rdaddr <= 9'd0;
					home_rdaddr <= 9'd0;
					rden <= 1'b0;
					
					state <= WAIT_FOR_START;
					end
			endcase
			end
			
//	CTRL_RAM Rst_RAM(
//		.data(),    //  ram_input.datain
//		.address(1'b0), //           .address
//		.wren(1'b0),    //           .wren
//		.clock(clk),   //           .clk
//		.q(rst)        // ram_output.dataout
//		);

		
//	Start_Ctrl_RAM Start_Ctrl_RAM(
//		.data(),    //  ram_input.datain
//		.address(1'b0), //           .address
//		.wren(1'b0),    //           .wren
//		.clock(clk),   //           .clk
//		.q(start)        // ram_output.dataout
//	);

	r2_compute #(DATA_WIDTH) r2_evaluate(
		.clk(clk),
		.rst(rst),
		.enable(r2_enable),						// Connect to FSM controller
		.refx(refx),
		.refy(refy),
		.refz(refz),
		.posx(posx),
		.posy(posy),
		.posz(posz),
		.r2(r2),										// Connect to RL_Evaluate_Pairs_LJ.r2
		.dx_out(dx),								// Connect to RL_Evaluate_Pairs_LJ.dx
		.dy_out(dy),								// Connect to RL_Evaluate_Pairs_LJ.dy
		.dz_out(dz),								// Connect to RL_Evaluate_Pairs_LJ.dz
		.r2_valid(r2_valid)						// Connect to RL_Evaluate_Pairs_LJ.r2_valid
		);

	RL_Evaluate_Pairs_LJ_1st_Order #(
		DATA_WIDTH,
		SEGMENT_NUM,
		SEGMENT_WIDTH,
		BIN_WIDTH,
		BIN_NUM,
		LOOKUP_NUM,
		LOOKUP_ADDR_WIDTH
	)
	RL_Evaluate_Pairs_LJ(
		.clk(clk),
		.rst(rst),
		.r2_valid(r2_valid),						// Connect to r2_compute.r2_valid
		.r2(r2),										// Connect to r2_compute.r2
		.dx(dx),										// Connect to r2_compute.dx
		.dy(dy),										// Connect to r2_compute.dy
		.dz(dz),										// Connect to r2_compute.dz
		.LJ_Force_X(forceoutput_x),			// Connect to output
		.LJ_Force_Y(forceoutput_y),			// Connect to output
		.LJ_Force_Z(forceoutput_z),			// Connect to output
		.LJ_force_valid(forceoutput_valid)	// Connect to output
		);

	refx
	#(
		.DEPTH(512),
		.ADDR_WIDTH(9)
	)
	refx_bram (
		.data(),
		.address(home_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(refx)
		);

	refy
	#(
		.DEPTH(512),
		.ADDR_WIDTH(9)
	)
	refy_bram (
		.data(),
		.address(home_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(refy)
		);

	refz
	#(
		.DEPTH(512),
		.ADDR_WIDTH(9)
	)
	refz_bram (
		.data(),
		.address(home_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(refz)
		);


	posx
	#(
		.DEPTH(512),
		.ADDR_WIDTH(9)
	)
	posx_bram (
		.data(),
		.address(neighbor_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(posx)
		);

	posy
	#(
		.DEPTH(512),
		.ADDR_WIDTH(9)
	)
	posy_bram (
		.data(),
		.address(neighbor_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(posy)
		);

	posz
	#(
		.DEPTH(512),
		.ADDR_WIDTH(9)
	)
	posz_bram (
		.data(),
		.address(neighbor_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(posz)
		);

endmodule


