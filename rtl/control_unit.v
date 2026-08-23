////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  control_unit.v
//
//  Unidad de control en el core RISCV
//
//  Recibe el opcode de la instrucción y genera señales de control para la ALU, memoria y registros.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////


module control_unit(opcode, funct3, Branch, BranchNotEqual, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite);

  input [6:0] opcode; // Entrada de 7 bits del opcode de la instrucción
  input [2:0] funct3; // Campo funct3 para distinguir operaciones relacionadas
  output reg Branch;   // Señal de control para la instrucción Branch
  output reg BranchNotEqual; // Indica que el branch comprueba desigualdad
  output reg MemRead;  // Señal de control para la lectura de memoria
  output reg MemtoReg; // Señal de control para escribir en el registro desde memoria
  output reg [1:0] ALUOp; // Señal de control para la operación de la ALU
  output reg MemWrite; // Señal de control para escribir en memoria
  output reg ALUSrc;   // Señal de control para seleccionar la fuente de la ALU
  output reg RegWrite; // Señal de control para escribir en el registro

  always @(*) begin
    case (opcode)
      7'b0110011: begin // R-type
        Branch = 0;
        BranchNotEqual = 0;
        MemRead = 0;
        MemtoReg = 0;
        ALUOp = 2'b10;
        MemWrite = 0;
        ALUSrc = 0;
        RegWrite = 1;
      end
      7'b0000011: begin // Load (I-type)
        Branch = 0;
        BranchNotEqual = 0;
        MemRead = 1;
        MemtoReg = 1;
        ALUOp = 2'b00;
        MemWrite = 0;
        ALUSrc = 1;
        RegWrite = 1;
      end
      7'b0100011: begin // Store (S-type)
        Branch = 0;
        BranchNotEqual = 0;
        MemRead = 0;
        MemtoReg = 'bx; // Don't care
        ALUOp = 2'b00;
        MemWrite = 1;
        ALUSrc = 1;
        RegWrite = 0;
      end
      7'b0010011: begin // Operaciones inmediatas: addi, andi y ori
        Branch = 0;
        BranchNotEqual = 0;
        MemRead = 0;
        MemtoReg = 0;
        ALUOp = 2'b11;
        MemWrite = 0;
        ALUSrc = 1;
        RegWrite = 1;
      end
      7'b1100011: begin // Branch if equal (B-type)
        // Solo se habilitan beq (funct3=000) y bne (funct3=001).
        Branch = (funct3 == 3'b000) || (funct3 == 3'b001);
        BranchNotEqual = (funct3 == 3'b001);
        MemRead = 0;
        MemtoReg = 'bx; // Don't care
        ALUOp = 2'b01;  // La ALU resta rs1 - rs2
        MemWrite = 0;
        ALUSrc = 0;     // Segundo operando: rs2
        RegWrite = 0;
      end
      default: begin // Default case for unsupported opcodes
        Branch = 'bx;   // Don't care
        BranchNotEqual = 'bx; // Don't care
        MemRead = 'bx;   // Don't care
        MemtoReg = 'bx;   // Don't care
        ALUOp = 'bx;     // Don't care
        MemWrite = 'bx;   // Don't care
        ALUSrc = 'bx;     // Don't care
        RegWrite = 'bx;   // Don't care
      end
    endcase
  end 
endmodule
    
