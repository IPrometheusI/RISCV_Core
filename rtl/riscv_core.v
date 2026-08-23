////////////////////////////////////////////////////////////////////////////////////
//
//  riscv_core.v
//
//  Datapath principal del core RISC-V de un solo ciclo.
//
//  Este archivo conecta los bloques de búsqueda de instrucciones,
//  decodificación, archivo de registros, ALU, memoria de datos y writeback.
//
////////////////////////////////////////////////////////////////////////////////////



// Compuerta AND usada para decidir si un branch modifica el PC.
// El branch se toma cuando Branch=1 y la ALU produce Zero=1.
module and_gate(
    input wire a,
    input wire b,
    output wire z
);
    assign z = a & b;
endmodule




module core(
        input wire core_clk,             // Reloj principal del core.
        input wire core_reset            // Reset asíncrono del PC.
);

    // -------------------------------------------------------------------------
    // IF (Instruction Fetch): búsqueda de instrucciones y cálculo del próximo PC
    // -------------------------------------------------------------------------
    wire [31:0] pc_wire;                 // PC actual, expresado como dirección de bytes.
    wire [63:0] adder_4_result_wire;     // PC + 4, siguiente instrucción secuencial.
    wire [31:0] new_pc;                  // Próximo PC usado por el registro PC.
    wire [63:0] new_pc_wide;             // Salida de 64 bits del mux del PC.
    wire [31:0] decoded_inst;            // Instrucción de 32 bits leída de la ROM.
    wire [63:0] bta_adder_output_wire;   // Destino de branch: PC + inmediato.

    // -------------------------------------------------------------------------
    // ID (Instruction Decode): control, registros e inmediato
    // -------------------------------------------------------------------------
    wire branch_wire;                    // Indica que la instrucción es un branch.
    wire branch_not_equal_wire;           // Selecciona la condición de bne.
    wire memread_wire;                   // Habilita lectura de memoria de datos.
    wire memtoreg_wire;                  // Selecciona memoria o ALU para writeback.
    wire [1:0] aluop_wire;               // Operación general solicitada a la ALU.
    wire memwrite_wire;                  // Habilita escritura en memoria de datos.
    wire alusrc_wire;                    // Selecciona rs2 o inmediato para la ALU.
    wire regwrite_wire;                  // Habilita escritura en el archivo de registros.
    wire [63:0] read_data_1_wire;        // Valor leído de rs1.
    wire [63:0] read_data_2_wire;        // Valor leído de rs2.
    wire [63:0] imm_out_wire;            // Inmediato extendido a 64 bits.

    // -------------------------------------------------------------------------
    // EX (Execute): operación de la ALU y comparación de branches
    // -------------------------------------------------------------------------
    wire [63:0] alu_a_wire;              // Señal reservada; A se conecta directamente desde rs1.
    wire [63:0] alu_b_wire;              // Segunda entrada seleccionada para la ALU.
    wire [3:0]  alu_ctl_wire;            // Control específico de la operación de la ALU.
    wire [63:0] alu_out_wire;            // Resultado de la ALU o dirección efectiva.
    wire alu_zero_flag_wire;             // Vale 1 cuando el resultado de la ALU es cero.
    wire branch_condition_wire;           // Zero o !Zero según beq/bne.
    wire pc_src_sel;                     // Selecciona PC+4 o el destino del branch.

    // -------------------------------------------------------------------------
    // WB (Write Back): datos que regresan al archivo de registros
    // -------------------------------------------------------------------------
    wire [63:0] data_mem_read_wire;      // Dato leído desde la memoria.
    wire [63:0] write_data_file_reg_wire;// Dato que se escribe en rd.

    // El mux del PC trabaja con 64 bits, pero el PC del diseño es de 32 bits.
    // Solo los 32 bits inferiores se utilizan para actualizar el registro PC.
    assign new_pc = new_pc_wide[31:0];



    // Registro de estado del PC. Se reinicia a cero y se actualiza con el reloj.
    pc u_pc(
        .clk(core_clk),      
        .reset(core_reset),
        .next_pc(new_pc),
        .current_pc(pc_wire)  
    );

    // Dirección de la siguiente instrucción en ejecución secuencial.
    adder u_adder_4(
        .A({32'b0,pc_wire}),
        .B({32'b0,32'h4}),
        .Sum(adder_4_result_wire)
    );

    // Dirección destino de un branch: PC + inmediato B-type.
    // imm_gen ya incorpora el bit cero del desplazamiento.
    adder u_branch_target_adder(
        .A({32'b0, pc_wire}),
        .B(imm_out_wire),    // No es necesario shift left ya que esta implementado en el modulo
        .Sum(bta_adder_output_wire)
    );

    // Selección del próximo PC: PC+4 o destino del branch.
    mux2_1 u_pc_src_mux(
        .input_a(adder_4_result_wire),
        .input_b(bta_adder_output_wire),
        .select(pc_src_sel),
        .output_y(new_pc_wide)
    );

    // Memoria de instrucciones combinacional. El PC es una dirección de bytes;
    // inst_mem la convierte en un índice de palabras de 32 bits.
    inst_mem u_inst_mem(
        .read_address(pc_wire), //Entrada del pc
        .instruction(decoded_inst) //Salida de la instruccion de 32-bits
    );

    // Decodifica el opcode y genera las señales de control del datapath.
    control_unit u_control_unit(
        .opcode(decoded_inst[6:0]),
        .funct3(decoded_inst[14:12]),
        .Branch(branch_wire),
        .BranchNotEqual(branch_not_equal_wire),
        .MemRead(memread_wire),
        .MemtoReg(memtoreg_wire),
        .ALUOp(aluop_wire),
        .MemWrite(memwrite_wire),
        .ALUSrc(alusrc_wire),
        .RegWrite(regwrite_wire)
    );

    // Segundo operando de la ALU: rs2 cuando ALUSrc=0 o inmediato cuando ALUSrc=1.
    mux2_1 alu_src_mux(
        .input_a(read_data_2_wire),
        .input_b(imm_out_wire),
        .select(alusrc_wire),
        .output_y(alu_b_wire)
    );


    // Lecturas combinacionales y escritura sincronizada con core_clk.
    file_register u_file_register(
        .clk(core_clk),
        .RegWrite(regwrite_wire),
        .read_reg1(decoded_inst[19:15]),
        .read_reg2(decoded_inst[24:20]),
        .write_reg(decoded_inst[11:7]),
        .write_data(write_data_file_reg_wire),
        .read_data1(read_data_1_wire),
        .read_data2(read_data_2_wire)
    );

    // Extrae y extiende el inmediato según el formato I, S o B de la instrucción.
    imm_gen u_imm_gen(
        .instruction(decoded_inst),
        .imm_out(imm_out_wire)
    );

    // beq se toma con Zero=1; bne se toma con Zero=0.
    assign branch_condition_wire = branch_not_equal_wire
                                 ? ~alu_zero_flag_wire
                                 : alu_zero_flag_wire;

    and_gate u_and(
        .a(branch_wire),
        .b(branch_condition_wire),
        .z(pc_src_sel)
    );

    // Ejecuta operaciones aritméticas/lógicas, calcula direcciones y compara
    // registros para beq mediante la bandera Zero.
    alu u_alu(
        .ALUctl(alu_ctl_wire),
        .A(read_data_1_wire),
        .B(alu_b_wire),
        .Zero(alu_zero_flag_wire),
        .ALUOut(alu_out_wire)
    );

    // Convierte ALUOp, funct7 y funct3 en el control específico de la ALU.
    // Para beq, ALUOp=01 selecciona una resta.
    alu_control u_aluc_control(
        .ALUOp(aluop_wire),
        .Funct7(decoded_inst[31:25]),
        .Funct3(decoded_inst[14:12]),
        .ALUctl(alu_ctl_wire)
    );

    // Selecciona el valor que se escribe en rd: ALU para R-type o memoria para ld.
    mux2_1 u_writeback_mux(
        .input_a(alu_out_wire),
        .input_b(data_mem_read_wire),
        .select(memtoreg_wire),
        .output_y(write_data_file_reg_wire)
    );

    // Memoria de datos. La ALU calcula la dirección efectiva rs1+inmediato.
    // En sd se almacena rs2; en ld el dato vuelve por writeback.
    data_mem u_data_mem(
        .clk(core_clk),
        .MemRead(memread_wire),
        .MemWrite(memwrite_wire),
        .address(alu_out_wire),
        .write_data(read_data_2_wire),
        .read_data(data_mem_read_wire)
    );











endmodule
