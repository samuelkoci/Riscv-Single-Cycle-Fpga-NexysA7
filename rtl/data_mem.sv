`timescale 1ns / 1ps

module data_mem (
    input  logic        clk,
    input  logic [3:0]  we,
    input  logic [31:0] addr,
    input  logic [31:0] wd,
    output logic [31:0] rd
);
    // 64 KB = 16384 fjale. BRAM e vertete (Block RAM), jo distributed.
    (* ram_style = "block" *)
    logic [31:0] RAM [0:16383];

    initial begin
        // RREGULLIM KRITIK: inicializo GJITHE RAM me ZERO se pari.
        // memfile.dat permban vetem .text+.rodata+.data (fjalet e perdorura nga programi),
        // JO .bss (variablat globale jo-inicializuara, si start_time_val/stop_time_val).
        // Pa kete hap, fjalet PAS fundit te memfile.dat mbeten 'X' (e papercaktuar) ne simulim,
        // dhe ne FPGA real ne BRAM e pa-inicializuar mund te kete vlera te paqendrueshme/random.
        // Kjo X/random e perhapet (X-propagation) ne register, ALU, FSM next-state logic, dhe
        // CPU ngec/sillet gabim sapo lexon nje variabel globale jo-inicializuar (p.sh. .bss).
        integer i;
        for (i = 0; i < 16384; i = i + 1) begin
            RAM[i] = 32'h00000000;
        end
        $readmemh("memfile.dat", RAM); // Duhet shtuar si Design Source ne Vivado!
    end

    // Lexim SINKRON - nje cikel vonese (BRAM hardware)
    always_ff @(posedge clk) begin
        if (addr[31:16] == 16'h0000) begin
            rd <= RAM[addr[15:2]];
            if (we[0]) RAM[addr[15:2]][7:0]   <= wd[7:0];
            if (we[1]) RAM[addr[15:2]][15:8]  <= wd[15:8];
            if (we[2]) RAM[addr[15:2]][23:16] <= wd[23:16];
            if (we[3]) RAM[addr[15:2]][31:24] <= wd[31:24];
        end else begin
            rd <= 32'h00000000;
        end
    end
endmodule