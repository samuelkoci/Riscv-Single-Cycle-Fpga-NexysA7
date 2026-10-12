module baud_gen #(parameter N = 326) (
    input  logic clk,
    input  logic rst_n,
    output logic tick
);
    // Logu yt tregoi N=651 me pare, ndaj r_reg duhet te jete 10-11 bit
    logic [10:0] r_reg; 
    logic [10:0] r_next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            r_reg <= 0;
        else
            r_reg <= r_next;
    end

    // Tick ndodh kur arrijme N-1
    assign r_next = (r_reg == (N-1)) ? 0 : r_reg + 1;
    assign tick = (r_reg == (N-1));
endmodule