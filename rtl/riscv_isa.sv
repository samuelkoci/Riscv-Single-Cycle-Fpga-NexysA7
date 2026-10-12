`timescale 1ns / 1ps

module riscv_isa (
    input  logic [6:0]  op,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    input  logic [31:0] instr,
    input  logic        zero,
    output logic [2:0]  imm_src,
    output logic [4:0]  alu_control,
    output logic        alu_src, reg_write, mem_to_reg, mem_write,
    output logic        branch, jal, jalr,
    output logic        is_lbu, is_blt, is_bge, is_bltu, is_bgeu
);
    always_comb begin
        // Vlerat default (parandalon latch-e)
        reg_write   = 1'b0; alu_src    = 1'b0;
        mem_write   = 1'b0; mem_to_reg = 1'b0;
        branch      = 1'b0; jal        = 1'b0; jalr   = 1'b0;
        is_lbu      = 1'b0; is_blt     = 1'b0; is_bge = 1'b0;
        is_bltu     = 1'b0; is_bgeu    = 1'b0;
        alu_control = 5'b00000;
        imm_src     = 3'b000;

        case(op)

            // ?? R-type ??????????????????????????????????????????????
            7'b0110011: begin
                reg_write = 1'b1;
                case(funct3)
                    3'b000: alu_control = (funct7 == 7'b0000001) ? 5'b01001 :
                                          (funct7[5]             ? 5'b01000 : 5'b00000); // MUL/SUB/ADD
                    3'b001: alu_control = 5'b00001; // SLL
                    3'b010: alu_control = 5'b00010; // SLT
                    3'b011: alu_control = 5'b00011; // SLTU
                    3'b100: alu_control = (funct7 == 7'b0000001) ? 5'b10000 : 5'b00100; // DIV/XOR
                    3'b101: alu_control = (funct7 == 7'b0000001) ? 5'b10001 :
                                          (instr[30]             ? 5'b01101 : 5'b00101); // DIVU/SRA/SRL
                    3'b110: alu_control = (funct7 == 7'b0000001) ? 5'b10010 : 5'b00110; // REM/OR
                    3'b111: alu_control = (funct7 == 7'b0000001) ? 5'b10011 : 5'b00111; // REMU/AND
                    default: alu_control = 5'b00000;
                endcase
            end

            // ?? I-type ALU ??????????????????????????????????????????
            7'b0010011: begin
                reg_write = 1'b1; alu_src = 1'b1;
                imm_src = 3'b000; // FIX: Gjithmone 000 per te gjitha I-Types!
                case(funct3)
                    3'b000: alu_control = 5'b00000; // ADDI
                    3'b010: alu_control = 5'b00010; // SLTI
                    3'b011: alu_control = 5'b00011; // SLTIU
                    3'b100: alu_control = 5'b00100; // XORI
                    3'b110: alu_control = 5'b00110; // ORI
                    3'b111: alu_control = 5'b00111; // ANDI
                    3'b001: alu_control = 5'b00001; // SLLI
                    3'b101: alu_control = instr[30] ? 5'b01101 : 5'b00101; // SRLI/SRAI
                    default: alu_control = 5'b00000; 
                endcase
            end

            // ?? LOAD (LB, LH, LW, LBU, LHU) ???????????????????????
            7'b0000011: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                mem_to_reg  = 1'b1;
                imm_src     = 3'b000;
                alu_control = 5'b00000; // ADD (addr = rs1 + imm)
                // FIX KRITIK: vendos is_lbu saktesisht per LBU
                case(funct3)
                    3'b100: is_lbu = 1'b1; // LBU
                    default: is_lbu = 1'b0;
                endcase
            end

            // ?? STORE (SB, SH, SW) ?????????????????????????????????
            7'b0100011: begin
                alu_src     = 1'b1;
                imm_src     = 3'b001;
                mem_write   = 1'b1;
                alu_control = 5'b00000; // ADD (addr = rs1 + imm)
            end

            // ?? BRANCH ?????????????????????????????????????????????
            7'b1100011: begin
                branch  = 1'b1;
                imm_src = 3'b010;
                case(funct3)
                    3'b000, 3'b001: alu_control = 5'b01000;           // BEQ, BNE
                    3'b100: begin alu_control = 5'b00010; is_blt  = 1'b1; end // BLT
                    3'b101: begin alu_control = 5'b00010; is_bge  = 1'b1; end // BGE
                    3'b110: begin alu_control = 5'b00011; is_bltu = 1'b1; end // BLTU
                    3'b111: begin alu_control = 5'b00011; is_bgeu = 1'b1; end // BGEU
                    default: alu_control = 5'b01000;
                endcase
            end

            // ?? JAL ????????????????????????????????????????????????
            7'b1101111: begin
                reg_write = 1'b1;
                imm_src   = 3'b011;
                jal       = 1'b1;
            end

            // ?? JALR ???????????????????????????????????????????????
            7'b1100111: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                imm_src     = 3'b000;
                jalr        = 1'b1;
                alu_control = 5'b00000;
            end

            // ?? LUI ????????????????????????????????????????????????
            7'b0110111: begin
                reg_write = 1'b1;
                imm_src   = 3'b100;
                alu_src   = 1'b1;
            end

            // ?? AUIPC ??????????????????????????????????????????????
            7'b0010111: begin
                reg_write = 1'b1;
                imm_src   = 3'b100;
                alu_src   = 1'b1;
            end

        endcase
    end
endmodule