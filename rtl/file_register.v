////////////////////////////////////////////////////////////////////////////////////
//
//  file_register.v
//
//  Archivo de registros en el core RISCV
//
//  32 registros de 64 bits cada uno
//
////////////////////////////////////////////////////////////////////////////////////


module file_register (clk, RegWrite, read_reg1, read_reg2, write_reg, write_data, read_data1, read_data2);

  input clk;                // Reloj
  input RegWrite;           // Señal de control para escribir en el registro
  input [4:0] read_reg1;    // Registro a leer 1
  input [4:0] read_reg2;    // Registro a leer 2
  input [4:0] write_reg;    // Registro a escribir
  input [63:0] write_data;  // Datos a escribir en el registro
  output reg [63:0] read_data1; // Datos leídos del registro 1
  output reg [63:0] read_data2; // Datos leídos del registro 2

  reg [63:0] registers [0:31]; // Archivo de registros de 32 registros de 64 bits

  always @(posedge clk) begin
    // El registro x0 está cableado a cero y no puede modificarse.
    registers[0] <= 64'b0;
    if (RegWrite && (write_reg != 5'd0)) begin
      registers[write_reg] <= write_data; // Escribir en el registro
    end
  end

  always @(*) begin
    read_data1 = (read_reg1 == 5'd0) ? 64'b0 : registers[read_reg1]; // Leer del registro 1
    read_data2 = (read_reg2 == 5'd0) ? 64'b0 : registers[read_reg2]; // Leer del registro 2
  end

endmodule
