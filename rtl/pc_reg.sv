module pc_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] pc_next,
    output logic [31:0] pc
);

    // 1. Inicializimi per simulim (dhe per te ndihmuar FPGA-ne)
    logic [31:0] pc_reg_internal = 32'h00000000; 

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg_internal <= 32'h00000000;
        end else begin
            pc_reg_internal <= pc_next;
        end
    end

    assign pc = pc_reg_internal;

endmodule