module branch_cond(
	input logic [31:0] rs1_data,rs2_data,
	input logic [2:0]  funct3,
	input logic        is_branch,
	output logic       br_taken);
	
	always_comb begin
		unique case (funct3)  
			3'b000 : br_taken = is_branch && (rs1_data == rs2_data);
			3'b001 : br_taken = is_branch && (rs1_data != rs2_data);
			3'b100 : br_taken = is_branch && ($signed(rs1_data) < $signed(rs2_data));
			3'b101 : br_taken = is_branch && ($signed(rs1_data) >= $signed(rs2_data));
		        3'b110 : br_taken = is_branch && rs1_data < rs2_data;
		        3'b111 : br_taken = is_branch && rs1_data >= rs2_data;
		default : br_taken = 1'b0;
endcase
end
endmodule
