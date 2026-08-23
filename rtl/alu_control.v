////////////////////////////////////////////////////////////////////////////////////
//
//  alu_control.v
//
//  Controla las operaciones de la ALU en el core RISCV
//
//  2 entradas de 4 bits y 1 salida de 4 bits
//
////////////////////////////////////////////////////////////////////////////////////


module alu_control (ALUOp, Funct7, Funct3, ALUctl);

  input [1:0] ALUOp;   // Control de la ALU
  input [6:0] Funct7;  // Función 7 bits
  input [2:0] Funct3;  // Función 3 bits
  output reg [3:0] ALUctl; // Salida de control de la ALU

  always @(*) begin
    case (ALUOp)
      2'b00: ALUctl = 4'b0010; // ADD
      2'b01: ALUctl = 4'b0110; // SUBTRACT
      2'b10: begin
        case ({Funct7, Funct3})
          {7'b0000000, 3'b000}: ALUctl = 4'b0010; // ADD
          {7'b0100000, 3'b000}: ALUctl = 4'b0110; // SUBTRACT
          {7'b0000000, 3'b111}: ALUctl = 4'b0000; // AND
          {7'b0000000, 3'b110}: ALUctl = 4'b0001; // OR
          {7'b0000000, 3'b100}: ALUctl = 4'b0011; // XOR
          {7'b0000000, 3'b001}: ALUctl = 4'b0100; // SLL
          {7'b0000000, 3'b101}: ALUctl = 4'b0101; // SRL
          {7'b0100000, 3'b101}: ALUctl = 4'b0111; // SRA
          {7'b0000000, 3'b010}: ALUctl = 4'b1000; // SLT
          {7'b0000000, 3'b011}: ALUctl = 4'b1001; // SLTU
          default: ALUctl = 4'b0000; // Default case
        endcase
      end
      2'b11: begin
        // Operaciones inmediatas soportadas. En este formato funct7
        // pertenece al inmediato, por lo que solo se usa funct3.
        case (Funct3)
          3'b000: ALUctl = 4'b0010; // ADDI
          3'b001: begin
            ALUctl = (Funct7 == 7'b0000000) ? 4'b0100 : 4'b0000; // SLLI
          end
          3'b010: ALUctl = 4'b1000; // SLTI
          3'b011: ALUctl = 4'b1001; // SLTIU
          3'b100: ALUctl = 4'b0011; // XORI
          3'b101: begin
            ALUctl = (Funct7 == 7'b0100000) ? 4'b0111 : 4'b0101; // SRAI/SRLI
          end
          3'b111: ALUctl = 4'b0000; // ANDI
          3'b110: ALUctl = 4'b0001; // ORI
          default: ALUctl = 4'b0000; // Operación inmediata no soportada
        endcase
      end
      default: ALUctl = 4'b0000; // Default case
    endcase
    end
endmodule
