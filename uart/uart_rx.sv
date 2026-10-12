`timescale 1ns / 1ps

module uart_rx (
    input  logic       clk, rst_n,
    input  logic       rx,           // Hyrja seriale
    input  logic       s_tick,       // 16x baud rate tick
    output logic       rx_done_tick, // Byte-i u mor me sukses
    output logic [7:0] dout          // Byte-i dal?s
);

    // Gjendjet e FSM
    typedef enum {idle, start, data, stop} state_type;
    state_type state_reg, state_next;

    logic [3:0] s_reg, s_next; // Numron 16 ticks per bit
    logic [2:0] n_reg, n_next; // Numron 8 bitet e te dhenave
    logic [7:0] b_reg, b_next; // Shift register

    // Regjistrat e gjendjes (Sekuencial)
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= idle;
            s_reg     <= 0;
            n_reg     <= 0;
            b_reg     <= 0;
        end else begin
            state_reg <= state_next;
            s_reg     <= s_next;
            n_reg     <= n_next;
            b_reg     <= b_next;
        end
    end

    // Logjika e FSM (Kombinatore)
    always_comb begin
        // Vlerat default per te shmangur Latches
        state_next = state_reg;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;
        rx_done_tick = 1'b0;

        case (state_reg)
            idle: begin
                if (!rx) begin        // Start bit (u ul teli ne 0)
                    state_next = start;
                    s_next = 0;
                end
            end
            
            start: begin
                if (s_tick) begin
                    if (s_reg == 7) begin // Mesatitja e Start Bit
                        state_next = data;
                        s_next = 0;
                        n_next = 0;
                    end else begin
                        s_next = s_reg + 4'b0001;
                    end
                end
            end
            
            data: begin
                if (s_tick) begin
                    if (s_reg == 15) begin // Mesatitja e bitit te te dhenave
                        s_next = 0;
                        b_next = {rx, b_reg[7:1]}; // LSb first
                        if (n_reg == 7)
                            state_next = stop;
                        else
                            n_next = n_reg + 3'b001;
                    end else begin
                        s_next = s_reg + 4'b0001;
                    end
                end
            end
            
            stop: begin
                if (s_tick) begin
                    if (s_reg == 15) begin // Fundi i Stop Bit
                        state_next = idle;
                        rx_done_tick = 1'b1;
                    end else begin
                        s_next = s_reg + 4'b0001;
                    end
                end
            end

            // Mungesa e k?tij blloku shkaktonte errorin n? Vivado
            default: begin
                state_next = idle;
            end
        endcase
    end

    assign dout = b_reg;

endmodule