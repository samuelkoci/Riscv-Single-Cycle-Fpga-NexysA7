`timescale 1ns / 1ps

module tb_alu();
    logic [31:0] a, b;
    logic [4:0]  alu_control;
    logic [31:0] alu_result;
    logic        zero;

    // Instancimi i ALU
    alu uut (.*);

    initial begin
        // Test 1: ADD
        a = 32'd10; b = 32'd5; alu_control = 5'b00000; #10;
        
        // Test 2: SUB
        alu_control = 5'b01000; #10;
        
        // Test 3: SLL (Shift Left Logical) - Këtu duhet të kesh kujdes me b[4:0]
        a = 32'd1; b = 32'd4; alu_control = 5'b00001; #10; // 1 << 4 = 16
        
        // Test 4: SLT (Set Less Than)
        a = 32'd5; b = 32'd10; alu_control = 5'b00010; #10; // 5 < 10 = 1
        
        // Test 5: SRL (Shift Right Logical)
        a = 32'd16; b = 32'd2; alu_control = 5'b00101; #10; // 16 >> 2 = 4
        
        // Test 6: SRA (Shift Right Arithmetic) - Testohet me numër negativ
        a = 32'hFFFFFFFF; b = 32'd4; alu_control = 5'b01101; #10; // -1 >> 4 = -1
        
        // Test 7: AND
        a = 32'hF0F0F0F0; b = 32'h0000FFFF; alu_control = 5'b00111; #10;

        $display("Testimi i ALU perfundoi.");
        $finish;
    end

    // Monitorim për të parë rezultatet në konsolë
    initial begin
        $monitor("Time=%0t | Ctrl=%b | A=%h | B=%h | Res=%h | Zero=%b", 
                  $time, alu_control, a, b, alu_result, zero);
    end
endmodule