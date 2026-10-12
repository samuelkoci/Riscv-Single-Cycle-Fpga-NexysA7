`timescale 1ns / 1ps

module register_file (
    input  logic        clk,           
    input  logic        rst,           // Reset sinkron
    input  logic        reg_write,     
    input  logic [4:0]  rs1, rs2, rd,  
    input  logic [31:0] write_data,    
    output logic [31:0] rd1, rd2       
);

    // Atributet per te ndaluar Vivado-n nga optimizimi agresiv
    (* dont_touch = "yes", keep = "true", mark_debug = "true" *) 
    logic [31:0] registers [31:0];

    // INITIALIZIMI PER SIMULIM
    // Kjo siguron qe simulimi nuk fillon me vlera 'x'
    initial begin
        for (int i = 0; i < 32; i++) begin
            registers[i] = 32'h0;
        end
    end

    // LEXIMI ASINKRON
    // Regjistri x0 eshte gjithmone 0 sipas specifikimit RISC-V
    assign rd1 = (rs1 == 5'b0) ? 32'h0 : registers[rs1];
    assign rd2 = (rs2 == 5'b0) ? 32'h0 : registers[rs2];

    // SHKRIMI SINKRON
    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset sinkron i te gjithe regjistrave
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'h0;
            end
        end else if (reg_write && (rd != 5'b0)) begin
            // Shkrimi ne regjistrin e duhur (nqs rd != x0)
            registers[rd] <= write_data;
        end
    end

endmodule