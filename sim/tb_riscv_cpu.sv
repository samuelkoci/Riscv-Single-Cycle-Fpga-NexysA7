`timescale 1ns / 1ps

module tb_riscv_cpu();
    logic clk, rst, stall;
    logic [31:0] instr, read_data;
    logic [31:0] pc, alu_result, write_data, timer_val;
    logic mem_write;

    // Instancimi i CPU-së
    riscv_cpu dut (.*);

    // Clock 100MHz (perioda 10ns)
    always #5 clk = ~clk;

    initial begin
        // Reset
        clk = 0; rst = 1; stall = 0; instr = 32'h0; read_data = 0;
        #20 rst = 0;

        // Instruksioni 1: ADDI x1, x0, 10
        // Hex: 00a00093
        #10 instr = 32'h00a00093;
        
        // Instruksioni 2: ADDI x2, x1, 5
        // Hex: 00508113
        #10 instr = 32'h00508113;

        #50 $finish;
    end

    initial begin
        $monitor("Time=%0t | PC=%h | Instr=%h | ALU=%d | Timer=%d", 
                 $time, pc, instr, alu_result, timer_val);
    end
endmodule