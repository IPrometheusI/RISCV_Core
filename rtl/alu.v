////////////////////////////////////////////////////////////////////////////////////
//
//  alu.v
//
//  Ejecuta operaciones aritméticas y lógicas en el core RISCV
//
//  2 entradas de 64 bits y 2 salidas, 1 de 64 bits y otra de 1 bit (Zero flag)
//
////////////////////////////////////////////////////////////////////////////////////


module alu (ALUctl, A, B, ALUOut, Zero);

  input [3:0] ALUctl; // Control de la ALU
  input [63:0] A;     // Entrada A
  input [63:0] B;     // Entrada B
  output reg [63:0] ALUOut; // Salida de la ALU
  output Zero;        // Bandera Zero

  assign Zero = (ALUOut == 64'b0) ? 1'b1 : 1'b0;

  always @(*) begin
    case (ALUctl)
      4'b0000: ALUOut = A & B;          // AND
      4'b0001: ALUOut = A | B;          // OR
      4'b0010: ALUOut = A + B;          // ADD
      4'b0110: ALUOut = A - B;          // SUBTRACT
      default: ALUOut = 64'b0;          // Default case
    endcase
  end

endmodule
