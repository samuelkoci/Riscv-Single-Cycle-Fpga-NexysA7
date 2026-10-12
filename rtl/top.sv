`timescale 1ns / 1ps

module top (
    input  logic        clk,
    input  logic        cpu_resetn,
    input  logic        uart_rx_pin,
    output logic        uart_tx_pin,
    output logic [3:0]  LED
);
    logic rst;
    assign rst = !cpu_resetn;

    logic clk_50 = 1'b0;
    always_ff @(posedge clk) clk_50 <= ~clk_50;

    logic [31:0] pc;
    logic [31:0] write_data, data_addr;
    logic        mem_write;
    logic [31:0] timer_val;
    logic        s_tick, tx_busy;
    logic [7:0]  uart_dout, tx_data_reg;
    logic        tx_start_pulse;

    // =========================================================
    // --- FSM: FETCH (BRAM) -> DECODE/LOAD (BRAM) -> EXECUTE ---
    // Single-cycle CPU i pandryshuar (riscv_cpu/datapath) tani
    // punon me memorie sinkrone (BRAM e vertete) permes nje FSM
    // te vogel qe gjeneron 'stall' per ciklet e nevojshme te pritjes.
    // =========================================================
    typedef enum logic [2:0] {
        S_FETCH1,
        S_FETCH2,
        S_DECODE_LOAD,
        S_LOAD_WAIT,
        S_EXEC
    } state_t;
    state_t state, state_next;

    logic [31:0] instr_raw;       // output direkt nga instr_mem (BRAM, sinkron)
    logic [31:0] instr_latched;   // 'instr' qe i dergohet riscv_cpu - stabil gjate gjithe instruksionit
    logic [31:0] read_data_raw;   // output direkt nga data_mem (BRAM, sinkron)
    logic [31:0] read_data_latched; // 'read_data' qe i dergohet riscv_cpu per LOAD

    logic        stall;
    logic        is_load;
    logic        is_load_next;
    logic        is_ram_load;
    logic [31:0] read_data_cpu;
    assign is_load      = (instr_latched[6:0] == 7'b0000011);
    // is_load_next: bazuar ne instr_raw (vlera E RE nga BRAM, jo instr_latched ende i vjeter!)
    // Perdoret VETEM brenda next-state logic te S_FETCH2, kur instr_latched akoma mban
    // instruksionin e MEPARSHEM (do te perditesohet ne fund te ketij cikli).
    assign is_load_next  = (instr_raw[6:0] == 7'b0000011);
    assign is_ram_load   = is_load && (data_addr < 32'h00010000);
    assign read_data_cpu = read_data_latched;

    // FSM sekuenciale
    always_ff @(posedge clk_50 or posedge rst) begin
        if (rst) begin
            state <= S_FETCH1;
        end else begin
            state <= state_next;
        end
    end

    // FSM kombinatoriale (next-state)
    always_comb begin
        state_next = state;
        case (state)
            S_FETCH1: state_next = S_FETCH2;
            S_FETCH2: begin
                if (is_load_next) state_next = S_DECODE_LOAD;
                else               state_next = S_EXEC;
            end
            // Ne S_DECODE_LOAD, instr_latched eshte tashme vendosur (nga S_FETCH2),
            // keshtu qe 'data_addr' (alu_result, kombinatorial brenda riscv_cpu) eshte i vlefshem KETU.
            // Nese eshte load nga RAM e vertete -> duhet 1 cikel pritje shtese per BRAM.
            // Nese eshte load nga MMIO (UART/timer) -> read_data_cpu eshte gati menjehere, skip pritjen.
            S_DECODE_LOAD: begin
                if (is_ram_load) state_next = S_LOAD_WAIT;
                else              state_next = S_EXEC;
            end
            S_LOAD_WAIT:   state_next = S_EXEC;
            S_EXEC:        state_next = S_FETCH1;
            default:       state_next = S_FETCH1;
        endcase
    end

    // stall=1 ne te gjitha gjendjet pervec EXEC (kur CPU lejohet te perparoje 1 cikel)
    assign stall = (state != S_EXEC);

    // Kapja e instruksionit: behet VETEM ne S_FETCH2, mbetet stabil deri ne EXEC
    always_ff @(posedge clk_50) begin
        if (state == S_FETCH2) begin
            instr_latched <= instr_raw;
        end
    end

    // Kapja e te dhenave te ngarkuara (LOAD):
    // - Per RAM load: kapet drejtperdrejt nga 'read_data_raw' (output i data_mem BRAM) ne S_LOAD_WAIT
    // - Per MMIO load (UART/timer): kapet nga 'mmio_read_data' (kombinatorial) ne S_DECODE_LOAD
    always_ff @(posedge clk_50) begin
        if (state == S_LOAD_WAIT) begin
            read_data_latched <= read_data_raw;
        end else if (state == S_DECODE_LOAD && !is_ram_load) begin
            read_data_latched <= mmio_read_data;
        end
    end

    // =========================================================
    // --- DIAGNOSTIKIMI "E VERTETA ABSOLUTE" ME LED ---
    // =========================================================

    assign LED[0] = cpu_resetn;

    logic [25:0] heartbeat = 0;
    always_ff @(posedge clk_50) heartbeat <= heartbeat + 1;
    assign LED[1] = heartbeat[25];

    logic uart_sent = 0;
    always_ff @(posedge clk_50 or posedge rst) begin
        if (rst) uart_sent <= 0;
        else if (tx_start_pulse) uart_sent <= 1;
    end
    assign LED[2] = uart_sent;

    logic ram_written = 0;
    always_ff @(posedge clk_50 or posedge rst) begin
        if (rst) ram_written <= 0;
        else if (mem_write && !stall && (data_addr < 32'h00010000)) ram_written <= 1;
    end
    assign LED[3] = ram_written;

    // =========================================================
    // --- ZGJIDHJA E ARTE E UART-IT (RACE CONDITION FIX) ---
    // =========================================================
    logic tx_busy_or_pending;
    logic tx_sent_pending;

    always_ff @(posedge clk_50 or posedge rst) begin
        if (rst) begin
            tx_data_reg     <= 8'b0;
            tx_start_pulse  <= 1'b0;
            tx_sent_pending <= 1'b0;
        end else begin
            tx_start_pulse  <= 1'b0;

            // CPU gjuan germen vetem 1 here, vetem ne S_EXEC (stall=0), kur instruksioni eshte real
            if (mem_write && !stall && (data_addr == 32'h80000000) && !tx_busy_or_pending) begin
                tx_data_reg     <= write_data[7:0];
                tx_start_pulse  <= 1'b1;
                tx_sent_pending <= 1'b1;
            end

            if (tx_busy) begin
                tx_sent_pending <= 1'b0;
            end
        end
    end

    assign tx_busy_or_pending = tx_busy | tx_sent_pending;

    // =========================================================

    logic [3:0]  ram_we;
    logic [31:0] ram_wd;
    always_comb begin
        ram_we = 4'b0000;
        ram_wd = write_data;
        if (mem_write && !stall && (data_addr < 32'h00010000)) begin
            case (instr_latched[14:12])
                3'b000: begin
                    ram_wd = {4{write_data[7:0]}};
                    case (data_addr[1:0])
                        2'b00: ram_we = 4'b0001; 2'b01: ram_we = 4'b0010;
                        2'b10: ram_we = 4'b0100; 2'b11: ram_we = 4'b1000;
                    endcase
                end
                3'b001: begin
                    ram_wd = {2{write_data[15:0]}};
                    case (data_addr[1])
                        1'b0: ram_we = 4'b0011; 1'b1: ram_we = 4'b1100;
                    endcase
                end
                default: ram_we = 4'b1111;
            endcase
        end
    end

    riscv_cpu cpu (
        .clk(clk_50), .rst(rst), .stall(stall),
        .pc(pc),
        .instr(instr_latched),
        .mem_write(mem_write),
        .alu_result(data_addr),
        .write_data(write_data),
        .read_data(read_data_cpu),
        .timer_val(timer_val)
    );

    // instr_mem: BRAM sinkron e vertete. Adresohet vazhdimisht me 'pc' aktual;
    // outputi 'instr_raw' eshte vlefshem 1 cikel pas cdo ndryshim te pc (perfshire S_FETCH1->S_FETCH2)
    instr_mem imem (.clk(clk_50), .addr(pc), .instr(instr_raw));

    // data_mem: BRAM sinkron e vertete. Adresohet me 'data_addr' (=alu_result, kombinatorial nga instr_latched)
    data_mem dmem (.clk(clk_50), .we(ram_we), .addr(data_addr), .wd(ram_wd), .rd(read_data_raw));

    baud_gen #(.N(326)) baud_unit (.clk(clk_50), .rst_n(cpu_resetn), .tick(s_tick));
    uart_tx transmitter (.clk(clk_50), .rst_n(cpu_resetn), .tx_start(tx_start_pulse), .s_tick(s_tick), .din(tx_data_reg), .tx(uart_tx_pin), .tx_busy(tx_busy));
    uart_rx receiver (.clk(clk_50), .rst_n(cpu_resetn), .rx(uart_rx_pin), .s_tick(s_tick), .rx_done_tick(), .dout(uart_dout));

    // =========================================================
    // mmio_read_data: lexim KOMBINATORIAL i pastrte vetem per MMIO (UART/timer),
    // pa varesi nga read_data_latched - perdoret per ta kapur ne S_DECODE_LOAD
    logic [31:0] mmio_read_data;
    always_comb begin
        mmio_read_data = 32'h0;
        if (data_addr[31:4] == 28'h8000000) begin
            case (data_addr[3:0])
                4'h0: mmio_read_data = {24'b0, uart_dout};
                4'h4: mmio_read_data = timer_val;
                4'h8: mmio_read_data = {31'b0, tx_busy_or_pending};
                default: mmio_read_data = 32'h0;
            endcase
        end
    end

    // read_data_cpu eshte definuar me lart si 'assign read_data_cpu = read_data_latched;'
endmodule