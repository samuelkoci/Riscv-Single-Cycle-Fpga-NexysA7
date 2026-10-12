`timescale 1ns / 1ps

module tb_datapath();
    // Inputs
    logic clk, rst, stall, reg_write, alu_src, mem_to_reg, branch, jal, jalr, mem_write, is_lbu;
    logic [4:0] rs1, rs2, rd, alu_control;
    logic [2:0] imm_src;
    logic [31:0] instr, read_data;

    // Outputs
    logic [31:0] pc, alu_result, write_data;
    logic zero;

    // Instancimi i Datapath
    datapath dut (
        .clk(clk), .rst(rst), .stall(stall), .reg_write(reg_write),
        .rs1(rs1), .rs2(rs2), .rd(rd), .instr(instr),
        .imm_src(imm_src), .alu_control(alu_control), .alu_src(alu_src),
        .mem_to_reg(mem_to_reg), .branch(branch), .jal(jal), .jalr(jalr),
        .mem_write(mem_write), .is_lbu(is_lbu), .read_data(read_data),
        .pc(pc), .alu_result(alu_result), .write_data(write_data), .zero(zero)
    );

    // Gjenerimi i Clock-ut
    always #5 clk = ~clk;

    initial begin
        // Inicializimi
        clk = 0; rst = 1; stall = 0;
        rs1 = 0; rs2 = 0; rd = 0; instr = 0;
        read_data = 0; reg_write = 0; alu_src = 0; 
        alu_control = 0; imm_src = 0;
        mem_to_reg = 0; branch = 0; jal = 0; jalr = 0; mem_write = 0; is_lbu = 0;

        #10 rst = 0; // Lirojmë reset-in

        // TEST: ADDI x1, x0, 5 (x1 = x0 + 5)
        // Opcode (0010011), rd (00001), funct3 (000), rs1 (00000), imm (000000000101)
        #10;
        instr = 32'h00500093; 
        rd = 5'd1; rs1 = 5'd0; rs2 = 5'd0; // rs1=x0, rd=x1
        reg_write = 1; alu_src = 1; alu_control = 5'b00000;
        imm_src = 3'b000;

        #20;
        $display("Pas ADDI: PC=%h, ALU_Result=%d (duhet te jete 5)", pc, alu_result);
        
        #20 $finish;
    end

    // Monitorim për të parë ndryshimet në real-time
    initial begin
        $monitor("Time=%0t | PC=%h | ALU_Result=%d", $time, pc, alu_result);
    end

endmodule