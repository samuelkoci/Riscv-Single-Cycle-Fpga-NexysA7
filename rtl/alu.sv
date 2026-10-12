`timescale 1ns / 1ps

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [4:0]  alu_control, 
    output logic [31:0] alu_result,
    output logic        zero,
    output logic        cmp_result
);
    always_comb begin
        case (alu_control)
            5'b00000: alu_result = a + b;                  // ADD
            5'b01000: alu_result = a - b;                  // SUB
            5'b01001: alu_result = a * b;                  // MUL
            5'b00001: alu_result = a << b[4:0];            // SLL
            5'b00010: alu_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            5'b00011: alu_result = (a < b) ? 32'd1 : 32'd0; // SLTU
            5'b00100: alu_result = a ^ b;                  // XOR
            5'b00101: alu_result = a >> b[4:0];            // SRL
            5'b01101: alu_result = $signed(a) >>> b[4:0];  // SRA
            5'b00110: alu_result = a | b;                  // OR
            5'b00111: alu_result = a & b;                  // AND
            
            // SHTESA PER M-EXTENSION (DIV, REM)
            5'b10000: alu_result = ($signed(b) != 0) ? $signed(a) / $signed(b) : 32'hFFFFFFFF; // DIV
            5'b10001: alu_result = (b != 0) ? a / b : 32'hFFFFFFFF;                            // DIVU
            5'b10010: alu_result = ($signed(b) != 0) ? $signed(a) % $signed(b) : a;            // REM
            5'b10011: alu_result = (b != 0) ? a % b : a;                                       // REMU
            
            default: alu_result = 32'd0;
        endcase
    end
    
    assign zero = (alu_result == 32'd0);

    always_comb begin
        case (alu_control)
            5'b00010: cmp_result = ($signed(a) < $signed(b)); // SLT (Signed)
            5'b00011: cmp_result = (a < b);                  // SLTU (Unsigned)
            default:  cmp_result = 1'b0;
        endcase
    end
endmodule