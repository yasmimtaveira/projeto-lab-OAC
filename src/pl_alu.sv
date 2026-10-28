// =============================================================================
// pl_alu.sv
// Unidade Logica e Aritmetica de 32 bits -- RV32I pipelined
//
// Codificacao de operacao (Operation[3:0]):
//   4'd01 : ADD  -- adicao com sinal
//   4'd02 : SUB  -- subtracao com sinal  (BEQ usa Zero)
//   4'd04 : OR   -- OU bit a bit
//   4'd05 : AND  -- E bit a bit
//   4'd11 : SLT  -- set-less-than com sinal
// =============================================================================

`timescale 1ns / 1ps

module pl_alu (
    input  logic [31:0] SrcA,
    input  logic [31:0] SrcB,
    input  logic [3:0]  Operation,
    output logic [31:0] ALUResult,
    output logic        Zero
);

    always_comb begin
        case (Operation)
            4'd01:   ALUResult = $signed(SrcA) + $signed(SrcB);
            4'd02:   ALUResult = $signed(SrcA) - $signed(SrcB);
            4'd03:   ALUResult = SrcA ^ SrcB; // XOR
            4'd04:   ALUResult = SrcA | SrcB;
            4'd05:   ALUResult = SrcA & SrcB;
            4'd06:   ALUResult = SrcA << SrcB[4:0]; // sll - shift left com ultimos 5 bits
            4'd07:   ALUResult = SrcA >> SrcB[4:0]; // srl - shift right
            4'd08:   ALUResult = $signed(SrcA) >>> SrcB[4:0]; // sra - shift right preserva o bit de sinal
				4'd09:   ALUResult = 32'($unsigned(SrcA) < $unsigned(SrcB)); // SLTU (unsignte)
            4'd11:   ALUResult = 32'($signed(SrcA) < $signed(SrcB));
            default: ALUResult = 32'b0;
        endcase
    end

    assign Zero = (ALUResult == 32'b0);

endmodule
