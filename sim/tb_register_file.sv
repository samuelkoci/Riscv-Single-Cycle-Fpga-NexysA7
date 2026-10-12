`timescale 1ns / 1ps

module tb_register_file();

    // Sinjalet hyrëse si regjistra (reg)
    logic clk, rst, reg_write;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] write_data;
    
    // Sinjalet dalëse si tela (wire)
    logic [31:0] rd1, rd2;

    // Instancimi i modulit (DUT - Device Under Test)
    register_file dut (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .write_data(write_data),
        .rd1(rd1), .rd2(rd2)
    );

    // Gjenerimi i Clock-ut (10ns periodë)
    always #5 clk = ~clk;

    initial begin
        // Inicializimi
        clk = 0; rst = 1; reg_write = 0;
        rs1 = 0; rs2 = 0; rd = 0; write_data = 0;
        
        #20 rst = 0; // Lirojmë reset-in

        // TEST 1: Shkrim në regjistrin x5
        #10 reg_write = 1; rd = 5; write_data = 32'hABCD1234;
        #10 reg_write = 0; // Ndalo shkrimin
        
        // TEST 2: Leximi nga x5
        #10 rs1 = 5;
        
        // TEST 3: Provë për x0 (Duhet të kthejë gjithmonë 0)
        #10 reg_write = 1; rd = 0; write_data = 32'hFFFFFFFF;
        #10 rs1 = 0; 
        
        #20 $finish;
    end

    // Monitorimi i vlerave (për t'i parë në konsolë)
    initial begin
        $monitor("Time=%0t | rs1=%d, rd1=%h | rd=%d, write_data=%h", $time, rs1, rd1, rd, write_data);
    end

endmodule