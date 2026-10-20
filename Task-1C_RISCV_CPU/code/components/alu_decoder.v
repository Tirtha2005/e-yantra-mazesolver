// alu_decoder.v - FINAL VERIFIED for e-Yantra Task 1C (Updated for OR/ORI fix)
module alu_decoder (
    input            opb5,
    input [2:0]      funct3,
    input            funct7b5,
    input [2:0]      ALUOp,
    output reg [2:0] ALUControl
);

always @(*) begin
    case (ALUOp)
        2'b00: ALUControl = 3'b000; // ADD (Load/Store/ADDI)
        2'b01: ALUControl = 3'b001; // SUB (Branch)
        default: begin
            case (funct3)
                3'b000: begin
                    if (funct7b5 & opb5)
                        ALUControl = 3'b001;  // SUB
                    else
                        ALUControl = 3'b000;  // ADD / ADDI
                end
                3'b001: ALUControl = 3'b100;  // SLL / SLLI
                3'b010: ALUControl = 3'b010;  // SLT / SLTI
                3'b011: ALUControl = 3'b011;  // SLTU / SLTIU
                3'b100: ALUControl = 3'b101;  // XOR / XORI
                3'b101: ALUControl = 3'b101;  // SRL / SRA / SRLI / SRAI
                3'b110: ALUControl = 3'b110;  // OR / ORI
                3'b111: ALUControl = 3'b111;  // AND / ANDI
                default: ALUControl = 3'b000;
            endcase
        end
    endcase
end

endmodule
