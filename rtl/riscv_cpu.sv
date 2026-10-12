`timescale 1ns / 1ps

module riscv_cpu (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic [31:0] instr,
    input  logic [31:0] read_data,
    output logic [31:0] pc,
    output logic [31:0] alu_result,
    output logic [31:0] write_data,
    output logic        mem_write,
    output logic [31:0] timer_val
);
    logic [2:0]  imm_src;
    logic [4:0]  alu_control;
    logic        alu_src, mem_to_reg;
    logic        branch, jal, jalr, zero;
    logic        is_lbu;
    logic        reg_write_int;
    logic        is_blt, is_bge, is_bltu, is_bgeu;

    // Timer/cikël counter
    logic [31:0] cycle_counter;
    always_ff @(posedge clk) begin
        if (rst) cycle_counter <= 32'd0;
        else     cycle_counter <= cycle_counter + 1;
    end
    assign timer_val = cycle_counter;

    // FIX KRITIK: shto .instr(instr) ne instancimin e riscv_isa
    riscv_isa controller (
        .op(instr[6:0]),
        .funct3(instr[14:12]),
        .funct7(instr[31:25]),
        .instr(instr),          // ? MUNGONTE - shkaktonte SRA/SRL/DIVU gabime
        .zero(zero),
        .imm_src(imm_src),
        .alu_control(alu_control),
        .alu_src(alu_src),
        .reg_write(reg_write_int),
        .mem_to_reg(mem_to_reg),
        .mem_write(mem_write),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .is_lbu(is_lbu),
        .is_blt(is_blt),
        .is_bge(is_bge),
        .is_bltu(is_bltu),
        .is_bgeu(is_bgeu)
    );

    logic reg_write;
    assign reg_write = reg_write_int & ~stall;

    datapath dp (
        .clk(clk), .rst(rst), .stall(stall),
        .reg_write(reg_write),
        .rs1(instr[19:15]), .rs2(instr[24:20]), .rd(instr[11:7]),
        .instr(instr),
        .imm_src(imm_src),
        .alu_control(alu_control),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jal(jal), .jalr(jalr),
        .mem_write(mem_write),
        .is_lbu(is_lbu),
        .is_blt(is_blt), .is_bge(is_bge),
        .is_bltu(is_bltu), .is_bgeu(is_bgeu),
        .read_data(read_data),
        .pc(pc),
        .alu_result(alu_result),
        .write_data(write_data),
        .zero(zero)
    );
endmodule