// =============================================================================
// pl_dmem.sv
// Memoria de dados -- RV32I pipelined
//
// Capacidade : 256 palavras x 32 bits = 1 KB
// Init file  : data.mif   (sintese Quartus)
//              data.hex   (simulacao ModelSim via $readmemh)
//
// Leitura  : assincrona (combinatorial) -- disponivel no estagio MEM
// Escrita  : sincrona (posedge clk, gated por MemWrite & ~mmio_sel)
// Endereco : alu_result[9:2]  (endereco de palavra de 8 bits)
// =============================================================================

`timescale 1ns / 1ps

module pl_dmem (
	 input  logic [2:0]  Funct3, //vai diferenciar se é lw, lb, lbu, lh
	 input  logic [1:0]  ByteOffset, //qual byte da mem será lido (0 à 1) lh e (0 à 3) lb ou lbu
    input  logic        clk,
    input  logic        MemWrite,
    input  logic [7:0]  addr,
    input  logic [31:0] WriteData,
    output logic [31:0] ReadData
);

    (* ram_init_file = "data.mif" *) logic [31:0] ram [0:255];

    // synthesis translate_off
    initial begin
        for (int i = 0; i < 256; i++) ram[i] = 32'h00000000;
        $readmemh("data.hex", ram);
    end
    // synthesis translate_on

    logic [31:0] word;
    assign word = ram[addr];

    // SW, SB, SH: monta a palavra nova trocando so os bytes escritos
    logic [31:0] new_word;

    always_comb begin
        new_word = word;
        case (Funct3)
            3'b010: new_word = WriteData;                       // SW
            3'b000: begin                                       // SB
                case (ByteOffset)
                    2'b00: new_word[7:0]   = WriteData[7:0];
                    2'b01: new_word[15:8]  = WriteData[7:0];
                    2'b10: new_word[23:16] = WriteData[7:0];
                    2'b11: new_word[31:24] = WriteData[7:0];
                endcase
            end
            3'b001: begin                                       // SH
                case (ByteOffset[1])
                    1'b0: new_word[15:0]  = WriteData[15:0];
                    1'b1: new_word[31:16] = WriteData[15:0];
                endcase
            end
            default: new_word = word;
        endcase
    end

    // Escrita sempre da palavra inteira (igual a versao que funciona)
    always @(posedge clk) begin
        if (MemWrite) ram[addr] <= new_word;
    end

    // LW, LB, LBU, LH, LHU
    always_comb begin
        case (Funct3)
            3'b010: ReadData = word;                            // LW

            3'b000: begin // LB: byte selecionado, repete o bit de sinal 24x
                case (ByteOffset)
                    2'b00: ReadData = {{24{word[7]}},  word[7:0]};
                    2'b01: ReadData = {{24{word[15]}}, word[15:8]};
                    2'b10: ReadData = {{24{word[23]}}, word[23:16]};
                    2'b11: ReadData = {{24{word[31]}}, word[31:24]};
                endcase
            end

            3'b100: begin // LBU: o mesmo que LB, mas completa com zeros
                case (ByteOffset)
                    2'b00: ReadData = {24'b0, word[7:0]};
                    2'b01: ReadData = {24'b0, word[15:8]};
                    2'b10: ReadData = {24'b0, word[23:16]};
                    2'b11: ReadData = {24'b0, word[31:24]};
                endcase
            end

            3'b001: begin // LH: meia palavra selecionada, repete o bit de sinal 16x
                case (ByteOffset[1])
                    1'b0: ReadData = {{16{word[15]}}, word[15:0]};
                    1'b1: ReadData = {{16{word[31]}}, word[31:16]};
                endcase
            end

            3'b101: begin // LHU: meia palavra selecionada, completa com zeros
                case (ByteOffset[1])
                    1'b0: ReadData = {16'b0, word[15:0]};
                    1'b1: ReadData = {16'b0, word[31:16]};
                endcase
            end

            default: ReadData = 32'b0;
        endcase
    end

endmodule
