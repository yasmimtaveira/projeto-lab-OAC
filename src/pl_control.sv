// =============================================================================
// pl_control.sv
// Unidade de Controle Principal -- RV32I pipelined (P&H secao 4.4)
//
// Decodifica o opcode de 7 bits (estagio ID) e gera os sinais de controle
// que serao propagados pelos registradores de pipeline.
//
// Instrucoes suportadas:
//   R-type  (0110011): add, and, sub, or, xor, sll, srl, sra, sltu
//   I-type  (0010011): addi, ori, xori, andi, slti, slli, srai
//   S-type  (0100011): sw, sb, sh
//   Load    (0000011): lw, lh, lb, lhu, lbu
//   B-type  (1100011): beq, bne, blt, bge, bltu, bgeu
//   U-type           : lui, auipc
//   J-type           : jal, jalr
//
// Tabela de sinais de controle:
//   Sinal     | R-type | lw | sw | beq
//   ----------|--------|----|----|-----
//   ALUSrc    |   0    |  1 |  1 |  0    0=reg, 1=imm
//   MemtoReg  |   0    |  1 |  - |  -    0=ALU, 1=mem
//   RegWrite  |   1    |  1 |  0 |  0
//   MemRead   |   0    |  1 |  0 |  0
//   MemWrite  |   0    |  0 |  1 |  0
//   Branch    |   0    |  0 |  0 |  1
//   ALUOp     |   10   |  0 |  0 | 01
// =============================================================================

`timescale 1ns / 1ps

module pl_control (
    input  logic [6:0] Opcode,
    output logic       ALUSrc,
    output logic       MemtoReg,
    output logic       RegWrite,
    output logic       MemRead,
    output logic       MemWrite,
    output logic       Branch,
    output logic [2:0] ALUOp // mudança para 3 bits
);

    localparam R_TYPE = 7'b0110011;
    localparam I_TYPE = 7'b0010011; 
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam BRANCH = 7'b1100011;
	 localparam U_TYPE = 7'b0110111; //lui
	 localparam AUIPC  = 7'b0010111; //auipc
	 localparam JAL    = 7'b1101111;
    localparam JALR   = 7'b1100111;
   

    always_comb begin
        ALUSrc   = 1'b0;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        Branch   = 1'b0;
        ALUOp    = 3'b000;

        case (Opcode)
            R_TYPE: begin
                ALUSrc   = 1'b0;
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                ALUOp    = 3'b010;
            end
            I_TYPE: begin 
                ALUSrc = 1'b1; // 1 seleciona o imed
                MemtoReg = 1'b0; //resultado da ALU
                RegWrite = 1'b1;
                ALUOp    = 3'b011;
            end
            LOAD: begin
                ALUSrc   = 1'b1;
                MemtoReg = 1'b1;
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                ALUOp    = 3'b000;
            end
            STORE: begin
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                ALUOp    = 3'b000;
            end
            BRANCH: begin
                Branch   = 1'b1;
                ALUOp    = 3'b001;
            end
				U_TYPE: begin
                ALUSrc   = 1'b1;
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemRead  = 1'b0;
                ALUOp    = 3'b100;
				end
				
				JAL: begin
                RegWrite = 1'b1;   // PC + 4 no rd
                ALUOp    = 3'b110;
            end

            JALR: begin
                RegWrite = 1'b1;   // PC + 4 no rd
                ALUOp    = 3'b111;
            end
					
				AUIPC: begin
                ALUSrc   = 1'b1;
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemRead  = 1'b0;
                ALUOp 	 = 3'b101; // AUIPC
				end
            default: ; // sinais permanecem em zero (seguro)
        endcase
    end

endmodule
