////////////////////////////////////////////////////////////////////////////////////
//
//  alu.v
//
//  Ejecuta operaciones aritméticas y lógicas en el core RISCV
//
//  2 entradas de 64 bits y 2 salidas: resultado de 64 bits y BranchTaken.
//
////////////////////////////////////////////////////////////////////////////////////


module alu (ALUctl, A, B, ALUOut, BranchTaken);

  input [3:0] ALUctl; // Control de la ALU
  input [63:0] A;     // Entrada A
  input [63:0] B;     // Entrada B
  output reg [63:0] ALUOut; // Salida de la ALU
  output reg BranchTaken;    // Condición de branch evaluada por la ALU

  always @(*) begin
    ALUOut = 64'b0;
    BranchTaken = 1'b0;

    case (ALUctl)
      4'b0000: ALUOut = A & B;          // AND
      4'b0001: ALUOut = A | B;          // OR
      4'b0010: ALUOut = A + B;          // ADD
      4'b0011: ALUOut = A ^ B;          // XOR
      4'b0100: ALUOut = A << B[5:0];     // SLL
      4'b0101: ALUOut = A >> B[5:0];     // SRL lógico
      4'b0110: ALUOut = A - B;          // SUBTRACT
      4'b0111: ALUOut = $signed(A) >>> B[5:0]; // SRA aritmético
      4'b1000: ALUOut = ($signed(A) < $signed(B)) ? 64'd1 : 64'd0; // SLT
      4'b1001: ALUOut = (A < B) ? 64'd1 : 64'd0; // SLTU
      4'b1010: begin
        BranchTaken = (A == B); // BEQ
      end
      4'b1011: begin
        BranchTaken = (A != B); // BNE
      end
      4'b1100: begin
        BranchTaken = ($signed(A) < $signed(B)); // BLT
      end
      4'b1101: begin
        BranchTaken = ($signed(A) >= $signed(B)); // BGE
      end
      4'b1110: begin
        BranchTaken = (A < B); // BLTU
      end
      4'b1111: begin
        BranchTaken = (A >= B); // BGEU
      end
    endcase
  end

endmodule
