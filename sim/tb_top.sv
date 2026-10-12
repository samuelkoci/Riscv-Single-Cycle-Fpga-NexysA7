`timescale 1ns / 1ps

module tb_top();
    logic clk, cpu_resetn, uart_rx_pin;
    logic uart_tx_pin;
    logic [3:0] LED;

    // Buffer për të ruajtur fjalën (E zmadhuar per mesazhet e CoreMark)
    logic [7:0] captured_string [0:2047]; 
    integer char_idx = 0;

    // Instancimi i TOP (dut)
    top dut (
        .clk(clk),
        .cpu_resetn(cpu_resetn),
        .uart_rx_pin(uart_rx_pin),
        .uart_tx_pin(uart_tx_pin),
        .LED(LED)
    );

    // Gjenerimi i orës (100MHz hyrëse)
    always #5 clk = ~clk;

    // 1. MONITORI I DETAJUAR
    // (E kam komentuar qe te mos beje spam ne Console, por mund ta heqesh komentin)
    initial begin
        // $display("--- Monitorimi i sinjaleve te ALU ---");
        // $monitor("Time=%0t | PC=%h | Ctrl=%b | Res=%h | SrcB=%h | SrcA=%h", 
        //           $time, dut.pc, dut.cpu.controller.alu_control, 
        //           dut.cpu.alu_result, dut.cpu.dp.src_b_final, dut.cpu.dp.src_a);
    end

    // 2. LOGJIKA E SNOOPER-it (Lexon direkt nga truri i CPU-se)
    // Kjo ben qe karakteret te kapen INSTANT në simulim!
    always_ff @(posedge dut.clk_50) begin
        if (dut.mem_write && (dut.data_addr == 32'h80000000) && !dut.tx_busy_or_pending) begin
            // Ruaje germen ne array-n tend
            captured_string[char_idx] = dut.write_data[7:0];
            char_idx = char_idx + 1;
            
            // Printoje drejtperdrejt ne Tcl Console
            $write("%c", dut.write_data[7:0]); 
            $fflush();
        end
    end

    event event_finish;

    // 3. KONTROLLI I KOHËS
    initial begin
        clk = 0; 
        cpu_resetn = 0; 
        uart_rx_pin = 1;
        #100 cpu_resetn = 1; // Reset i paster
        
        $display("========================================");
        $display("SIMULIMI I COREMARK FILLOI...");
        $display("========================================");
        
        // Time-out i rritur ne 50ms per t'i dhene kohe procesorit 
        // te inicializohet dhe te arrije Checkpoint-et
        #50000000; 
        $display("\n[TB] Simulimi arriti kohën maksimale (Time-out).");
        -> event_finish;
    end

    // 4. EKRANI I REZULTATIT (TRIGGERED NGA EVENTI YT)
    initial begin
        @(event_finish);
        $display("\n\n========================================");
        $display("SIMULIMI PERFUNDOI. MESAZHET E KAPURA:");
        $display("----------------------------------------");
        for (int i = 0; i < char_idx; i++) begin
            $write("%c", captured_string[i]);
        end
        $display("\n========================================");
        $finish;
    end
endmodule