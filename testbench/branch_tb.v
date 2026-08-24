`timescale 1ns/1ps

module branch_tb;

  reg [1:0] alu_op;
  reg [6:0] funct7;
  reg [2:0] funct3;
  reg [63:0] A;
  reg [63:0] B;
  reg [6:0] opcode;

  wire [3:0] alu_ctl;
  wire [63:0] alu_out;
  wire branch_taken;
  wire branch;
  wire mem_read;
  wire mem_to_reg;
  wire mem_write;
  wire alu_src;
  wire reg_write;
  wire [1:0] control_alu_op;
  wire pc_src;

  integer failures;

  alu_control u_alu_control(
      .ALUOp(alu_op),
      .Funct7(funct7),
      .Funct3(funct3),
      .ALUctl(alu_ctl)
  );

  alu u_alu(
      .ALUctl(alu_ctl),
      .A(A),
      .B(B),
      .ALUOut(alu_out),
      .BranchTaken(branch_taken)
  );

  control_unit u_control_unit(
      .opcode(opcode),
      .funct3(funct3),
      .Branch(branch),
      .MemRead(mem_read),
      .MemtoReg(mem_to_reg),
      .ALUOp(control_alu_op),
      .MemWrite(mem_write),
      .ALUSrc(alu_src),
      .RegWrite(reg_write)
  );

  and_gate u_and(
      .a(branch),
      .b(branch_taken),
      .z(pc_src)
  );

  task check_branch;
    input [2:0] test_funct3;
    input [63:0] test_a;
    input [63:0] test_b;
    input expected_taken;
    begin
      opcode = 7'b1100011;
      alu_op = 2'b01;
      funct7 = 7'b0000000;
      funct3 = test_funct3;
      A = test_a;
      B = test_b;
      #1;

      if (branch !== 1'b1) begin
        $display("FAIL decode funct3=%b: Branch=%b", test_funct3, branch);
        failures = failures + 1;
      end
      if (branch_taken !== expected_taken) begin
        $display("FAIL condition funct3=%b A=%h B=%h expected=%b got=%b",
                 test_funct3, test_a, test_b, expected_taken, branch_taken);
        failures = failures + 1;
      end
      if (pc_src !== expected_taken) begin
        $display("FAIL PCSrc funct3=%b expected=%b got=%b",
                 test_funct3, expected_taken, pc_src);
        failures = failures + 1;
      end
    end
  endtask

  initial begin
    failures = 0;

    // BEQ / BNE
    check_branch(3'b000, 64'd7, 64'd7, 1'b1);
    check_branch(3'b000, 64'd7, 64'd8, 1'b0);
    check_branch(3'b001, 64'd7, 64'd7, 1'b0);
    check_branch(3'b001, 64'd7, 64'd8, 1'b1);

    // Comparaciones con signo.
    check_branch(3'b100, 64'hffff_ffff_ffff_ffff, 64'd1, 1'b1); // -1 < 1
    check_branch(3'b100, 64'd1, 64'hffff_ffff_ffff_ffff, 1'b0); // 1 < -1
    check_branch(3'b101, 64'hffff_ffff_ffff_ffff, 64'd1, 1'b0); // -1 >= 1
    check_branch(3'b101, 64'd1, 64'hffff_ffff_ffff_ffff, 1'b1); // 1 >= -1

    // Comparaciones sin signo.
    check_branch(3'b110, 64'hffff_ffff_ffff_ffff, 64'd1, 1'b0);
    check_branch(3'b110, 64'd1, 64'hffff_ffff_ffff_ffff, 1'b1);
    check_branch(3'b111, 64'hffff_ffff_ffff_ffff, 64'd1, 1'b1);
    check_branch(3'b111, 64'd1, 64'hffff_ffff_ffff_ffff, 1'b0);

    // Un funct3 reservado no debe activar el camino de branch.
    funct3 = 3'b010;
    opcode = 7'b1100011;
    alu_op = 2'b01;
    A = 64'd0;
    B = 64'd0;
    #1;
    if (branch !== 1'b0 || pc_src !== 1'b0) begin
      $display("FAIL reserved branch funct3 activated: Branch=%b PCSrc=%b",
               branch, pc_src);
      failures = failures + 1;
    end

    if (failures == 0) begin
      $display("PASS: branch conditions and PCSrc");
    end else begin
      $display("FAIL: %0d branch test(s)", failures);
      $fatal(1);
    end
  end

endmodule
