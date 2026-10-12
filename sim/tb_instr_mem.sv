`timescale 1ns / 1ps

module tb_instr_mem();

    logic [31:0] addr;
    logic [31:0] instr;

    // Instancimi
    instr_mem dut (
        .addr(addr),
        .instr(instr)
    );

    initial begin
        // Test 1: Lexo adresën 0 (duhet të jetë NOP: 00000013)
        addr = 32'h0;
        #10;
        $display("Time=%0t | Addr=%h | Instr=%h", $time, addr, instr);

        // Test 2: Lexo adresën 4 (gjithashtu NOP)
        addr = 32'd4;
        #10;
        $display("Time=%0t | Addr=%h | Instr=%h", $time, addr, instr);

        // Test 3: Provë për adresë të lartë (brenda kufirit 16384)
        addr = 32'd100;
        #10;
        $display("Time=%0t | Addr=%h | Instr=%h", $time, addr, instr);

        $finish;
    end

endmodule