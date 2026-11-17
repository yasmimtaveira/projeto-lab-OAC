// =============================================================================
// pl_alu_ctrl.sv
// Unidade de Controle da ALU -- RV32I pipelined (P&H secao 4.4)
//
// Entradas (do estagio EX -- registrador ID/EX):
//   ALUOp[2:0] : codigo do controlador principal
//     00 : Load/Store  -> forcar ADD
//     01 : Branch BEQ  -> forcar SUB
//     10 : R-type      -> decodificar via Funct3/Funct7
//     011: I-type      -> decodificar via Funct3/Funct7
//     100 e 101: lui e auipc (
//   Funct7[6:0], Funct3[2:0] : campos da instrucao
//
// Saida Operation[3:0] -> pl_alu.sv:
//   4'd01 ADD  4'd02 SUB  4'd04 OR  4'd05 AND  4'd11 SLT
// =============================================================================

`timescale 1ns / 1ps

module pl_alu_ctrl (
    input  logic [2:0] ALUOp,
    input  logic [6:0] Funct7,
    input  logic [2:0] Funct3,
    output logic [3:0] Operation
);

    always_comb begin
        case (ALUOp)
            3'b000: Operation = 4'd01;   // Load / Store -> ADD ou auipc

            3'b001: Operation = 4'd02;   // Branch BEQ  -> SUB

            3'b010: begin                // R-type: decodificar Funct
                case (Funct3)
                    3'h0: Operation = Funct7[5] ? 4'd02 : 4'd01; // SUB ou ADD
                    3'h1: Operation = 4'd06;  // SLL (imp)
                    3'h3: Operation = 4'd09;  // sltu (imp)
                    3'h4: Operation = 4'd03; // XOR (imp)
                    3'h5: Operation = Funct7[5] ? 4'd08 : 4'd07;  // SRA : SRL (imp)
                    3'h6: Operation = 4'd04;  // OR
                    3'h7: Operation = 4'd05;  // AND
                    3'h2: Operation = 4'd11;  // SLT
                    default: Operation = 4'd01;
                endcase
            end
            
            3'b011: begin  //I-type (implementado)
                case(Funct3)
                    3'h0: Operation = 4'd01; //ADDI
                    3'h7: Operation = 4'd05; //ANDI
                    3'h6: Operation = 4'd04; //ORI
                    3'h2: Operation = 4'd11; // SLTI
                    3'h1: Operation = 4'd06; // SLLI
                    3'h5: Operation =  Funct7[5] ? 4'd08: 4'd07; // SRAI ou SRLI
						  3'h4: Operation = 4'd03; //xorI
						  
                    default: Operation = 4'd00; // ainda conferir ------------
                endcase
            end
				
				3'b100: Operation = 4'd01; // LUI: 0 + imediato (imp)
				3'b101: Operation = 4'd01; // AUIPC: PC + imediato (imp)

            default: Operation = 4'd01;
        endcase
    end

endmodule
