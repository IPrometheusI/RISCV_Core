////////////////////////////////////////////////////////////////////////////////////
//
//  mux2_1.v
//
//  Mux 2:1 en el core RISCV
//
//  2 entradas de 64 bits y 1 salida de 64 bits
//
////////////////////////////////////////////////////////////////////////////////////


module mux2_1 (input_a, input_b, select, output_y);

  input [63:0] input_a; // Entrada A de 64 bits
  input [63:0] input_b; // Entrada B de 64 bits
  input select;         // Señal de selección
  output reg [63:0] output_y; // Salida de 64 bits

  always @(*) begin
    case (select)
      1'b0: output_y = input_a; // Selecciona entrada A
      1'b1: output_y = input_b; // Selecciona entrada B
      default: output_y = 64'b0; // Caso por defecto
    endcase
  end
endmodule
