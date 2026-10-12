`timescale 1ns / 1ps

module unified_mem (
    input  logic        clk,
    // Porta e instruksioneve
    input  logic [31:0] pc,
    output logic [31:0] instr,
    // Porta e te dhenave
    input  logic [3:0]  we,
    input  logic [31:0] addr,
    input  logic [31:0] wd,
    output logic [31:0] rd
);
    // Distributed RAM = lexim kombinatorial (0 latence) - kritikie per CPU 1-stage
    (* ram_style = "distributed" *)
    logic [31:0] RAM [0:16383];

    initial begin
        $readmemh("memfile.dat", RAM);
    end

    // Lexim instruksionesh - kombinatorial, 0 latence
    assign instr = RAM[pc[15:2]];

    // Lexim te dhenash - kombinatorial, 0 latence
    assign rd = (addr[31:16] == 16'h0000) ? RAM[addr[15:2]] : 32'h00000000;

    // Shkrim sinkron me byte-enable
    always_ff @(posedge clk) begin
        if (addr[31:16] == 16'h0000) begin
            if (we[0]) RAM[addr[15:2]][7:0]   <= wd[7:0];
            if (we[1]) RAM[addr[15:2]][15:8]  <= wd[15:8];
            if (we[2]) RAM[addr[15:2]][23:16] <= wd[23:16];
            if (we[3]) RAM[addr[15:2]][31:24] <= wd[31:24];
        end
    end
endmodule