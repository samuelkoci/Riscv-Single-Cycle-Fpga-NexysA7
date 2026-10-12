`timescale 1ns / 1ps

module tb_riscv_isa();

    logic [6:0] op;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic       zero;
    
    logic [2:0] imm_src;
    logic [4:0] alu_control;
    logic       alu_src, reg_write, mem_to_reg, mem_write, branch, jal, jalr, is_lbu;

    // Instancimi i Kontrollerit
    riscv_isa dut (.*);

    initial begin
        // TEST 1: R-type ADD (0110011)
        op = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0000000; zero = 0;
        #10;
        
        // TEST 2: LW (0000011)
        op = 7'b0000011; funct3 = 3'b010; funct7 = 7'b0000000; zero = 0;
        #10;
        
        // TEST 3: Branch BEQ (1100011)
        op = 7'b1100011; funct3 = 3'b000; funct7 = 7'b0000000; zero = 0;
        #10;
        
        // TEST 4: JAL (1101111)
        op = 7'b1101111; funct3 = 3'b000; funct7 = 7'b0000000; zero = 0;
        #10;

        $finish;
    end

    initial begin
        $monitor("Time=%0t | Op=%b | RegWrite=%b | MemWrite=%b | ALUControl=%b | ImmSrc=%b", 
                 $time, op, reg_write, mem_write, alu_control, imm_src);
    end

endmodule