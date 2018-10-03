module ram_test_top(
	input [11:0] address,
	input clock,
	input [32:0] data,
	input wren,
	output [31:0] rd_data
);

	lut_test lut_test_inst(
		.data(data),
		.address(address),
		.wren(wren),
		.clock(clock),
		.q(rd_data)
	);

endmodule

