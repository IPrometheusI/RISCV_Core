////////////////////////////////////////////////////////////////////////////////////
//
//  data_mem.v
//
//  Memoria de datos en el core RISCV
//
//  Ejecuta operaciones de lectura y escritura en memoria
//
////////////////////////////////////////////////////////////////////////////////////



module data_mem (clk, MemRead, MemWrite, address, write_data, read_data);

  input clk;                // Reloj
  input MemRead;            // Señal de control para lectura de memoria
  input MemWrite;           // Señal de control para escritura en memoria
  input [63:0] address;     // Dirección de memoria
  input [63:0] write_data;  // Datos a escribir en memoria
  output reg [63:0] read_data; // Datos leídos de memoria

  reg [63:0] memory [0:255]; // Memoria de datos de 256 palabras de 64 bits

  always @(posedge clk) begin
    if (MemWrite) begin
      memory[address[10:3]] <= write_data; // Escribir en memoria
    end
  end

  always @(*) begin
    if (MemRead) begin
      read_data = memory[address[10:3]]; // Leer de memoria
    end else begin
      read_data = 64'b0;
    end
  end
endmodule
