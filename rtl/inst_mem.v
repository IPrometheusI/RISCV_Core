////////////////////////////////////////////////////////////////////////////////////
//
//  inst_mem.v
//
//  Memoria de instrucciones en el core RISCV
//
//  1 entrada de 32 bits y 1 salida de 32 bits
//
////////////////////////////////////////////////////////////////////////////////////



module inst_mem (read_address, instruction);

  input [31:0] read_address; // Dirección de lectura de 32 bits
  output reg [31:0] instruction; // Instrucción de 32 bits

  // Memoria de instrucciones (ROM)
  reg [31:0] memory [0:255]; // Memoria de 256 palabras de 32 bits

  initial begin
    // Instrucciones soportadas por el subconjunto actual.
    // La secuencia prueba memoria, operaciones R-type, operaciones inmediatas
    // y un bne tomado que salta directamente al beq final.
    memory[0] = 32'h00003023; // sd  x0, 0(x0)
    memory[1] = 32'h00003083; // ld  x1, 0(x0)
    memory[2] = 32'h00108133; // add x2, x1, x1
    memory[3] = 32'h401101B3; // sub x3, x2, x1
    memory[4] = 32'h00310233; // and x4, x2, x3
    memory[5] = 32'h004182B3; // or  x5, x3, x4
    memory[6] = 32'h00528313; // addi x6, x5, 5
    memory[7] = 32'h00737393; // andi x7, x6, 7
    memory[8] = 32'h0083E413; // ori  x8, x7, 8
    memory[9] = 32'h00041463; // bne  x8, x0, 8 (salta a memory[11])
    memory[10] = 32'h06300493; // addi x9, x0, 99 (se salta)
    memory[11] = 32'h00840063; // beq  x8, x8, 0 (bucle en esta instrucción)
  end

  always @(*) begin
    instruction = memory[read_address[9:2]]; // Lectura de la instrucción (asumiendo alineación a palabra)
  end

endmodule
