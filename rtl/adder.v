////////////////////////////////////////////////////////////////////////////////////
//
//  adder.v
//
//  Implementa un sumador de 64 bits para el core RISCV
//
//  2 entradas de 64 bits y 1 salida de 64 bits
//
////////////////////////////////////////////////////////////////////////////////////



module adder (A, B, Sum);

  input [63:0] A;     // Entrada A
  input [63:0] B;     // Entrada B
  output [63:0] Sum;  // Salida de la suma

  assign Sum = A + B; // Suma de A y B

endmodule

