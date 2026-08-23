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
          default: ALUctl = 4'b0000; // Default case
        endcase
      end
      default: ALUctl = 4'b0000; // Default case
    endcase
    end
endmodule


