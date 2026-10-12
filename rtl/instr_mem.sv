`timescale 1ns / 1ps

module instr_mem (
    input  logic        clk,
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    // 64 KB = 16384 fjale. BRAM e vertete (Block RAM), jo distributed.
    (* ram_style = "block" *)
    logic [31:0] ROM [0:16383];

    initial begin
        // RREGULLIM: inicializo GJITHE ROM me ZERO se pari (shih shenim te plote te data_mem.sv),
        // pastaj mbishkruaj me permbajtjen reale te firmware-it. Kjo mbron nga X-propagation
        // nese PC lexon ndonjehere jashte intervalit te perdorur nga firmware-i (memorie e papercaktuar
        // do te ishte 'addi x0,x0,0' / NOP ne vend te X, sjellje e parashikueshme).
        integer i;
        for (i = 0; i < 16384; i = i + 1) begin
            ROM[i] = 32'h00000000;
        end
        $readmemh("memfile.dat", ROM); // Duhet shtuar si Design Source ne Vivado!
    end

    // Lexim SINKRON - nje cikel vonese, perfekt per BRAM hardware
    always_ff @(posedge clk) begin
        instr <= ROM[addr[15:2]];
    end
endmodule