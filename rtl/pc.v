////////////////////////////////////////////////////////////////////////////////////
//
//  pc.v
//
//  Contador de programa en el core RISCV
//
//  1 entrada de 32 bits y 1 salida de 32 bits
//
////////////////////////////////////////////////////////////////////////////////////




module pc (clk, reset, next_pc, current_pc);

  input clk; // Señal de reloj
  input reset; // Señal de reinicio
  input [31:0] next_pc; // Próxima dirección de programa
  output reg [31:0] current_pc; // Dirección de programa actual

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      current_pc <= 32'b0; // Reinicia el contador de programa a 0
    end else begin
      current_pc <= next_pc; // Actualiza el contador de programa con la próxima dirección
    end
  end
endmodule