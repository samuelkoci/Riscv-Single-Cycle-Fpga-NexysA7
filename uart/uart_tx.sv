`timescale 1ns / 1ps

module uart_tx (
    input  logic        clk, rst_n,
    input  logic        tx_start,
    input  logic        s_tick,
    input  logic [7:0]  din,
    output logic        tx_done_tick,
    output logic        tx_busy, // I shtuar: Tregon kur UART-i po transmeton
    output logic        tx
);

    typedef enum logic [1:0] {idle, start, data, stop} state_type;
    state_type state_reg, state_next;

    logic [3:0] s_reg, s_next;
    logic [2:0] n_reg, n_next;
    logic [7:0] b_reg, b_next;
    logic tx_reg, tx_next;

    // Logjika e gjendjes "busy"
    assign tx_busy = (state_reg != idle);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= idle;
            s_reg     <= 4'b0;
            n_reg     <= 3'b0;
            b_reg     <= 8'b0;
            tx_reg    <= 1'b1;
        end else begin
            state_reg <= state_next;
            s_reg     <= s_next;
            n_reg     <= n_next;
            b_reg     <= b_next;
            tx_reg    <= tx_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        s_next     = s_reg;
        n_next     = n_reg;
        b_next     = b_reg;
        tx_next    = tx_reg;
        tx_done_tick = 1'b0;

        case (state_reg)
            idle: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    state_next = start;
                    s_next     = 4'b0;
                    b_next     = din;
                end
            end
            start: begin
                tx_next = 1'b0;
                if (s_tick) begin
                    if (s_reg == 15) begin
                        state_next = data;
                        s_next     = 4'b0;
                        n_next     = 3'b0;
                    end else s_next = s_reg + 1;
                end
            end
            data: begin
                tx_next = b_reg[0];
                if (s_tick) begin
                    if (s_reg == 15) begin
                        s_next = 4'b0;
                        b_next = b_reg >> 1;
                        if (n_reg == 7) state_next = stop;
                        else n_next = n_reg + 1;
                    end else s_next = s_reg + 1;
                end
            end
            stop: begin
                tx_next = 1'b1;
                if (s_tick) begin
                    if (s_reg == 15) begin
                        state_next = idle;
                        tx_done_tick = 1'b1;
                    end else s_next = s_reg + 1;
                end
            end
            default: state_next = idle;
        endcase
    end
    assign tx = tx_reg;
endmodule