// alu.v - FINAL CODE (Updated for OR/ORI fix)
module alu #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] a, b,
    input  [2:0]       alu_ctrl,
    output reg [WIDTH-1:0] alu_out,
    output              zero
);

always @(*) begin
    case (alu_ctrl)
        3'b000: alu_out = a + b;                        // ADD / ADDI
        3'b001: alu_out = a - b;                        // SUB
        3'b010: alu_out = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT / SLTI
        3'b011: alu_out = (a < b) ? 32'd1 : 32'd0;      // SLTU / SLTIU
        3'b100: alu_out = a << b[4:0];                  // SLL / SLLI  
        3'b101: begin                                   // SRL / SRA / SRLI / SRAI
            if (b[10]) alu_out = ($signed(a)) >>> b[4:0]; // arithmetic
            else        alu_out = a >> b[4:0];            // logical
        end
        3'b110: alu_out = a | b;                        // OR / ORI
        3'b111: alu_out = a & b;                        // AND / ANDI
        default: alu_out = 32'd0;
    endcase
end

assign zero = (alu_out == 0);

endmodule
