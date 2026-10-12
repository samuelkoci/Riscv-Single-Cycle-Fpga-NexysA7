`timescale 1ns / 1ps

module imm_extender (
    input  logic [31:0] instr,
    input  logic [2:0]  imm_src, // Sinjal nga Control Unit
    output logic [31:0] imm_ext
);
    always_comb begin
        case (imm_src)
            // I-Type (Load, ADDI, JALR) - Kujdes Sign Extension {20{...}}
            3'b000: imm_ext = {{20{instr[31]}}, instr[31:20]}; 
            
            // S-Type (Store: SW, SB)
            3'b001: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; 
            
            // B-Type (Branches: BEQ, BLT)
            3'b010: imm_ext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; 
            
            // J-Type (JAL - Kercimi tek Main)
            3'b011: imm_ext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; 
            
            // U-Type (LUI, AUIPC - Adresimi i stringjeve dhe Stack)
            3'b100: imm_ext = {instr[31:12], 12'b0}; 
            
            default: imm_ext = 32'b0;
        endcase
    end
endmodule