`timescale 1ns / 1ps

module datapath (
    input  logic        clk, rst, stall,
    input  logic        reg_write, alu_src, mem_to_reg, branch, jal, jalr, mem_write, is_lbu,
    input  logic        is_blt, is_bge, is_bltu, is_bgeu,
    input  logic [4:0]  rs1, rs2, rd, alu_control,
    input  logic [31:0] instr, read_data,
    input  logic [2:0]  imm_src,
    output logic [31:0] pc, alu_result, write_data,
    output logic        zero
);
    logic [31:0] pc_next, pc_plus4, pc_target, src_a, src_b_wire, src_b_final, result, imm_ext;
    logic cmp_result, branch_taken, pc_src;

    // PC REGISTER
    always_ff @(posedge clk or posedge rst) begin
        if (rst) pc <= 32'h0;
        else if (!stall) pc <= pc_next;
    end

    assign pc_plus4  = pc + 32'd4;
    assign pc_target = jalr ? (src_a + imm_ext) & ~32'd1 : (pc + imm_ext);

    // LOGJIKA E DEGËZIMEVE (BRANCH)
    always_comb begin
        branch_taken = 1'b0;
        if (branch) begin
            case (instr[14:12])
                3'b000: branch_taken = zero;
                3'b001: branch_taken = ~zero;
                3'b100: branch_taken = is_blt  ? cmp_result  : 1'b0;
                3'b101: branch_taken = is_bge  ? ~cmp_result : 1'b0;
                3'b110: branch_taken = is_bltu ? cmp_result  : 1'b0;
                3'b111: branch_taken = is_bgeu ? ~cmp_result : 1'b0;
                default: branch_taken = 1'b0;
            endcase
        end
    end

    assign pc_src = (~stall & (branch & branch_taken)) | ((jal | jalr) & ~stall);
    assign pc_next = pc_src ? pc_target : pc_plus4;

    // ZGJERUESI I IMMEDIATE DHE REGISTER FILE
    imm_extender imm_gen (.instr(instr), .imm_src(imm_src), .imm_ext(imm_ext));

    register_file rf (
        .clk(clk), .rst(rst), .reg_write(reg_write & ~stall),
        .rs1(rs1), .rs2(rs2), .rd(rd), .write_data(result), .rd1(src_a), .rd2(src_b_wire)
    );

    assign src_b_final = alu_src ? imm_ext : src_b_wire;
    
    // ALU
    alu alu_unit (
        .a(src_a), .b(src_b_final), 
        .alu_control(alu_control), 
        .alu_result(alu_result), 
        .zero(zero), .cmp_result(cmp_result)
    );

    // --- ALIGNER PER SHKRIMIN NE MEMORIE (SB, SH, SW) ---
    logic [31:0] aligned_wd;
    always_comb begin
        aligned_wd = src_b_wire; // Default (SW)
        if (instr[6:0] == 7'b0100011) begin // Rasti i Store
            case (instr[14:12])
                3'b000: aligned_wd = {4{src_b_wire[7:0]}};  // SB: Përsërit bajtin 4 herë
                3'b001: aligned_wd = {2{src_b_wire[15:0]}}; // SH: Përsërit halfword 2 herë
            endcase
        end
    end
    assign write_data = aligned_wd;

    // --- ALIGNER PER LEXIMIN NGA MEMORIA (LB, LH, LBU, LHU, LW) ---
    logic [31:0] loaded_data;
    always_comb begin
        loaded_data = read_data; // Default (LW)
        if (instr[6:0] == 7'b0000011) begin // Rasti i Load
            case (instr[14:12])
                3'b000: // LB (Sign-Extended Byte)
                    case (alu_result[1:0])
                        2'b00: loaded_data = {{24{read_data[7]}}, read_data[7:0]};
                        2'b01: loaded_data = {{24{read_data[15]}}, read_data[15:8]};
                        2'b10: loaded_data = {{24{read_data[23]}}, read_data[23:16]};
                        2'b11: loaded_data = {{24{read_data[31]}}, read_data[31:24]};
                    endcase
                3'b001: // LH (Sign-Extended Halfword)
                    case (alu_result[1])
                        1'b0: loaded_data = {{16{read_data[15]}}, read_data[15:0]};
                        1'b1: loaded_data = {{16{read_data[31]}}, read_data[31:16]};
                    endcase
                3'b100: // LBU (Zero-Extended Byte)
                    case (alu_result[1:0])
                        2'b00: loaded_data = {24'b0, read_data[7:0]};
                        2'b01: loaded_data = {24'b0, read_data[15:8]};
                        2'b10: loaded_data = {24'b0, read_data[23:16]};
                        2'b11: loaded_data = {24'b0, read_data[31:24]};
                    endcase
                3'b101: // LHU (Zero-Extended Halfword)
                    case (alu_result[1])
                        1'b0: loaded_data = {16'b0, read_data[15:0]};
                        1'b1: loaded_data = {16'b0, read_data[31:16]};
                    endcase
            endcase
        end
    end

    // WRITE-BACK MULTIPLEXER
    always_comb begin
        if (mem_to_reg) result = loaded_data; // Përdor të dhënat e filtruara (Byte/Half/Word)
        else if (jal | jalr) result = pc_plus4;
        else if (instr[6:0] == 7'b0110111) result = imm_ext; // LUI
        else if (instr[6:0] == 7'b0010111) result = pc + imm_ext; // AUIPC
        else result = alu_result;
    end
endmodule