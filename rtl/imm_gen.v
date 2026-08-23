////////////////////////////////////////////////////////////////////////////////////
//
//  imm_gen.v
//
//  Generador de inmediatos en el core RISCV
//
//  1 entrada de 32 bits y 1 salida de 64 bits
//
////////////////////////////////////////////////////////////////////////////////////

module imm_gen (instruction, imm_out);

  input [31:0] instruction; // Instrucción de 32 bits
  output reg [63:0] imm_out; // Inmediato de 64 bits

  always @(*) begin
    case (instruction[6:0])
      7'b0000011: imm_out = {{52{instruction[31]}}, instruction[31:20]}; // I-type
      7'b0010011: imm_out = {{52{instruction[31]}}, instruction[31:20]}; // I-type ALU
      7'b0100011: imm_out = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type
      7'b1100011: imm_out = {{51{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type
      7'b0010111: imm_out = {{44{instruction[31]}}, instruction[31:12], 12'b0}; // U-type (AUIPC)
      7'b0110111: imm_out = {{44{instruction[31]}}, instruction[31:12], 12'b0}; // U-type (LUI)
      7'b1101111: imm_out = {{43{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type
      default: imm_out = 64'b0; // Default case
    endcase
  end
endmodule
