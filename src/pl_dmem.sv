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

	 //SW, SB, SH
    always @(posedge clk) begin
    if (MemWrite) begin
        case (Funct3)

            3'b010: begin // SW
                ram[addr] <= WriteData;
            end

            3'b000: begin // SB
                case (ByteOffset)
                    2'b00: ram[addr][7:0]   <= WriteData[7:0];
                    2'b01: ram[addr][15:8]  <= WriteData[7:0];
                    2'b10: ram[addr][23:16] <= WriteData[7:0];
                    2'b11: ram[addr][31:24] <= WriteData[7:0];
                endcase
            end
				3'b001: begin //SH
					 case (ByteOffset[1])
                    1'b0: ram[addr][15:0]   <= WriteData[15:0];
                    1'b1: ram[addr][31:16]  <= WriteData[15:0];
                endcase
				end

        endcase
    end
end

    always_comb begin
    case (Funct3)

        3'b010: begin // LW
            ReadData = ram[addr];
        end

        3'b000: begin // LB
            case (ByteOffset) //ver qual o byte selecionado e repete o bit de sinal 24x e junta com o byte escolhido
                2'b00: ReadData = {{24{ram[addr][7]}},  ram[addr][7:0]};
                2'b01: ReadData = {{24{ram[addr][15]}}, ram[addr][15:8]};
                2'b10: ReadData = {{24{ram[addr][23]}}, ram[addr][23:16]};
                2'b11: ReadData = {{24{ram[addr][31]}}, ram[addr][31:24]};
            endcase
        end

		  3'b100: begin //LBU (o mesmo que lb, mas pega os bytes sem sinal)
				case (ByteOffset) //ver qual o byte selecionado e repete o bit de sinal (sempre 0) 24x e junta com o byte escolhido
				  2'b00: ReadData = {24'b0, ram[addr][7:0]};
				  2'b01: ReadData = {24'b0, ram[addr][15:8]};
				  2'b10: ReadData = {24'b0, ram[addr][23:16]};
				  2'b11: ReadData = {24'b0, ram[addr][31:24]};
			   endcase
		  end
		  
		  3'b001: begin // LH
            case (ByteOffset[1]) //ver qual o byte selecionado e repete o bit de sinal 16x e junta com o byte escolhido
                1'b0: ReadData = {{16{ram[addr][15]}},  ram[addr][15:0]};
                1'b1: ReadData = {{16{ram[addr][31]}}, ram[addr][31:16]};
            endcase
        end
		  
		  3'b101: begin // LHU
            case (ByteOffset[1]) //ver qual o byte selecionado e repete o bit de sinal 16x e junta com o byte escolhido
                1'b0: ReadData = {16'b0,  ram[addr][15:0]};
                1'b1: ReadData = {16'b0, ram[addr][31:16]};
            endcase
        end
		  
		  
        default: ReadData = 32'b0;

    endcase
   end

endmodule
