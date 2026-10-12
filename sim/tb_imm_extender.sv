`timescale 1ns / 1ps

module tb_imm_extender();

    logic [31:0] instr;
    logic [2:0]  imm_src;
    logic [31:0] imm_ext;

    // Instancimi i DUT
    imm_extender dut (
        .instr(instr),
        .imm_src(imm_src),
        .imm_ext(imm_ext)
    );

    initial begin
        // Test 1: I-type (instr: 0xFFF00000 -> duhet te jete -1)
        instr = 32'hFFF00000; imm_src = 3'b000;
        #10;
        
        // Test 2: S-type (instr: 0xFE000000 | 0x00000F00 -> verifikim shkeputje)
        instr = 32'hFE000F00; imm_src = 3'b001;
        #10;
        
        // Test 3: U-type (lui: 0x12345000)
        instr = 32'h12345000; imm_src = 3'b100;
        #10;

        // Test 4: J-type (jal)
        instr = 32'h80000000; imm_src = 3'b011;
        #10;

        $finish;
    end

    initial begin
        $monitor("Time=%0t | Src=%b | Instr=%h | Result=%h", 
                 $time, imm_src, instr, imm_ext);
    end

endmodule