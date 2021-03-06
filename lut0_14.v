module lut0_14 #(
	parameter DEPTH = 3072,
	parameter ADDR_WIDTH = 12
)
(
	input clock,
	input [ADDR_WIDTH-1:0] address,
	input [31:0] data,
	input rden,
	input wren,
	output [31:0] q
);
		
	altera_syncram  altera_syncram_component (
                .address_a (address),
                .clock0 (clock),
                .data_a (data),
                .rden_a (rden),
                .wren_a (wren),
                .q_a (q),
                .aclr0 (1'b0),
                .aclr1 (1'b0),
                .address2_a (1'b1),
                .address2_b (1'b1),
                .address_b (1'b1),
                .addressstall_a (1'b0),
                .addressstall_b (1'b0),
                .byteena_a (1'b1),
                .byteena_b (1'b1),
                .clock1 (1'b1),
                .clocken0 (1'b1),
                .clocken1 (1'b1),
                .clocken2 (1'b1),
                .clocken3 (1'b1),
                .data_b (1'b1),
                .eccencbypass (1'b0),
                .eccencparity (8'b0),
                .eccstatus ( ),
                .q_b ( ),
                .rden_b (1'b1),
                .sclr (1'b0),
                .wren_b (1'b0));
    defparam
        altera_syncram_component.width_byteena_a  = 1,
        altera_syncram_component.clock_enable_input_a  = "BYPASS",
        altera_syncram_component.clock_enable_output_a  = "BYPASS",
//`ifdef NO_PLI
//        altera_syncram_component.init_file = "/home/jiayi/Dropbox/CAAD_Server/MD_RL_Pipeline/Ethan_RL_LJ_Force_A10_17.1/memory_posx_1.rif"
//`else
        altera_syncram_component.init_file = "/home/jiayi/Dropbox/CAAD_Server/MD_RL_Pipeline/Ethan_RL_LJ_Force_A10_17.1/SourceFile/c0_14.hex",
//`endif
//,
        altera_syncram_component.intended_device_family  = "Arria 10",
        altera_syncram_component.lpm_hint  = "ENABLE_RUNTIME_MOD=NO",
        altera_syncram_component.lpm_type  = "altera_syncram",
        altera_syncram_component.numwords_a  = DEPTH,
        altera_syncram_component.operation_mode  = "SINGLE_PORT",
        altera_syncram_component.outdata_aclr_a  = "NONE",
        altera_syncram_component.outdata_sclr_a  = "NONE",
        altera_syncram_component.outdata_reg_a  = "CLOCK0",
        altera_syncram_component.enable_force_to_zero  = "FALSE",
        altera_syncram_component.power_up_uninitialized  = "FALSE",
        altera_syncram_component.read_during_write_mode_port_a  = "DONT_CARE",
        altera_syncram_component.widthad_a  = ADDR_WIDTH,
        altera_syncram_component.width_a  = 32;
		
endmodule