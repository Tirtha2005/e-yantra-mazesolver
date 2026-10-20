// main_decoder.v - corrected version

module main_decoder (
    input  [6:0] op,
    input  [2:0] funct3,
    input        Zero, ALUR31,
    output [1:0] ResultSrc,
    output       MemWrite, Branch, ALUSrc,
    output       RegWrite, Jump, Jalr,
    output [1:0] ImmSrc,
    output [2:0] ALUOp
);

reg [11:0] controls;  // now 12 bits to accommodate ALUOp[2:0]
reg TakeBranch;

always @(*) begin
    TakeBranch = 0;

    casez(op)
        // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_ALUOp_Jump_Jalr
        7'b0000011: controls = 12'b1_00_1_0_01_000_0_0; // lw
        7'b0100011: controls = 12'b0_01_1_1_00_000_0_0; // sw
        7'b0110011: controls = 12'b1_xx_0_0_00_010_0_0; // R-type
        7'b1100011: begin // branch
            controls = 12'b0_10_0_0_00_001_0_0; // ALUOp=001 for branch
            case(funct3)
                3'b000: TakeBranch = Zero;       // beq
                3'b001: TakeBranch = !Zero;      // bne
                3'b100: TakeBranch = ALUR31;     // blt
                3'b101: TakeBranch = !ALUR31;    // bge
                3'b110: TakeBranch = ALUR31;     // bltu
                3'b111: TakeBranch = !ALUR31;    // bgeu
            endcase
        end
        7'b0010011: controls = 12'b1_00_1_0_00_010_0_0; // I-type ALU
        7'b1101111: controls = 12'b1_11_0_0_10_000_1_0; // jal
        7'b1100111: controls = 12'b1_00_1_0_10_000_0_1; // jalr
        7'b0?10111: controls = 12'b1_xx_x_0_11_xxx_0_0; // lui/auipc
        default:    controls = 12'bx_xx_x_x_xx_xxx_x_x; // unknown
    endcase
end

assign Branch = TakeBranch;
assign {RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, ALUOp, Jump, Jalr} = controls;

endmodule
