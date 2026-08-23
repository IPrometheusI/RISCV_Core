# Capítulo 4 — The Processor (secciones 4.1 a 4.4)

> Transcripción/resumen técnico de *Computer Organization and Design: The Hardware/Software Interface — RISC-V Edition* (Patterson & Hennessy), Capítulo 4, secciones 4.1–4.4 (páginas 234–262 del libro).
> Cubre exactamente el diseño del **datapath monociclo** (single-cycle) y su unidad de control. No incluye pipelining (sección 4.5 en adelante) porque no aplica al core monociclo de este proyecto.
> Fuente: `Computer-Organization-and-Design-The-Hardware-Software-Interface-RISC-V-Edition.pdf` (páginas 234–262).

---

## 4.1 Introduction

El subconjunto de RISC-V que implementa el diseño monociclo del libro es:

- Instrucciones de memoria: `ld` (load doubleword), `sd` (store doubleword)
- Instrucciones aritmético-lógicas: `add`, `sub`, `and`, `or`
- Salto condicional: `beq` (branch if equal)

El proyecto extiende este subconjunto con `addi`, `andi`, `ori` y `bne`. Estas
extensiones reutilizan las rutas existentes del datapath: el formato I-type y
el mux del inmediato para las operaciones inmediatas, y el mismo cálculo de
destino de branch para `bne`, cambiando únicamente la condición de igualdad.

Toda instrucción comparte los dos primeros pasos:

1. Enviar el PC a la memoria de instrucciones y leer (fetch) la instrucción.
2. Leer uno o dos registros del banco de registros, según los campos de la instrucción.

Después de esto, las acciones dependen de la clase de instrucción, pero las tres clases (memoria, aritmético-lógica, salto) comparten el uso de la ALU:

- Load/store → la ALU calcula la dirección de memoria (base + offset).
- Aritmético-lógica → la ALU ejecuta la operación.
- `beq` → la ALU resta los dos registros y expone la señal `Zero` para el test de igualdad.

### Figura 4.1 — Vista abstracta del datapath

Unidades funcionales principales y sus conexiones (sin muxes ni control todavía):

- **PC** → dirección hacia **Instruction memory**
- **Instruction memory** → salida `Instruction`
- Campos de la instrucción → **Registers** (banco de registros): dos números de registro de lectura, uno de escritura
- **Registers** → dos salidas de datos hacia la **ALU**
- **ALU** → resultado hacia **Data memory** (como dirección) y de vuelta hacia **Registers** (dato a escribir)
- **Data memory** → dato leído, también puede volver a **Registers**
- Dos sumadores (**Add**): uno para `PC+4`, otro para `PC + branch offset` (branch target)

Nota importante del libro: en la práctica estas "conexiones dobles" (p. ej. el dato que se escribe en Registers puede venir de la ALU *o* de memoria) no se pueden cablear juntas — se necesita un **multiplexor** que seleccione la fuente.

### Figura 4.2 — Datapath básico con multiplexores y líneas de control

Se agregan 3 multiplexores y líneas de control:

- Mux superior: decide si el PC se actualiza con `PC+4` o con la dirección de branch target. Está controlado por una compuerta AND entre la señal `Zero` de la ALU y una señal de control que indica "es un branch".
- Mux medio (hacia el puerto de escritura de Registers): elige entre la salida de la ALU (instrucción aritmético-lógica) o la salida de Data memory (load).
- Mux inferior (segunda entrada de la ALU): elige entre el segundo registro leído (aritmético-lógica o branch) o el campo immediate/offset de la instrucción (load/store).

Señales de control mostradas: `ALU operation`, `MemWrite`, `MemRead`, `RegWrite`, `Zero` (desde la ALU), `Branch`.

---

## 4.2 Logic Design Conventions

Los elementos del datapath son de dos tipos:

- **Combinacionales**: la salida depende solo de las entradas actuales (sin memoria interna). Ejemplo: la ALU.
- **De estado (secuenciales)**: contienen almacenamiento interno. Ejemplo: memorias, banco de registros, PC, flip-flops.

Un elemento de estado tiene como mínimo dos entradas (dato a escribir, reloj) y una salida (valor almacenado previamente).

### Metodología de reloj

Se usa **edge-triggered clocking**: los elementos de estado se actualizan solo en el flanco del reloj (en este libro, flanco de subida — *positive edge-triggered*). Esto permite leer un registro, pasar el valor por lógica combinacional, y escribir ese mismo registro en el mismo ciclo de reloj sin condiciones de carrera (no hay feedback dentro de un ciclo).

- **asserted** = señal en 1 lógico / activa.
- **deasserted** = señal en 0 lógico / inactiva.
- Si un elemento de estado se escribe en *todos* los flancos de reloj (p. ej. el PC), no necesita señal explícita de "write enable". Si se escribe solo condicionalmente (registros, memoria de datos), sí necesita una señal de control de escritura explícita (`RegWrite`, `MemWrite`).
- El ancho de dato por defecto en RV64 es 64 bits salvo que se indique lo contrario.
- Las líneas de color en las figuras del libro representan señales de **control** (vs. señales de **datos**).

---

## 4.3 Building a Datapath

Construcción incremental del datapath, elemento por elemento.

### Fetch (Figura 4.5 / 4.6)

- **Instruction memory**: memoria de solo lectura desde el punto de vista del datapath (no requiere señal de read). Entrada: dirección. Salida: instrucción de 32 bits.
- **PC**: registro de 64 bits, se escribe en cada flanco de reloj (no necesita write-enable).
- **Adder ("Add")**: ALU cableada permanentemente en modo suma, usada para `PC + 4`.

### R-format / aritmético-lógicas (Figura 4.7)

- **Register file (Registers)**: 32 registros de propósito general.
  - Entradas: `Read register 1` (5 bits), `Read register 2` (5 bits), `Write register` (5 bits), `Write data` (64 bits), `RegWrite` (control).
  - Salidas: `Read data 1` (64 bits), `Read data 2` (64 bits).
  - Lectura combinacional (siempre expone el contenido de los registros solicitados); escritura sincrónica por flanco, solo si `RegWrite` está asertada.
- **ALU**: dos entradas de 64 bits, salida de 64 bits + salida `Zero` (1 bit). Control de 4 bits (`ALU operation`), detallado en el Apéndice A.

### Load/Store (Figura 4.8)

- **Data memory**: entradas `Address`, `Write data`; salida `Read data`. Señales `MemRead` y `MemWrite` (solo una activa por ciclo). A diferencia del banco de registros, sí necesita señal de lectura explícita porque leer una dirección inválida puede causar problemas (ver Cap. 5).
- **Immediate generation unit (ImmGen)**: toma la instrucción de 32 bits, selecciona el campo de 12 bits correspondiente (load, store o branch) y lo sign-extiende a 64 bits.
  - *Elaboration*: la lógica de ImmGen decide el campo según el opcode: bits 31:20 para load; bits 31:25 + 11:7 para store; bits 31,7,30:25,11:8 para branch. Los bits de opcode 6 y 5 alcanzan para seleccionar (mux 3:1 interno).

### Branch (Figura 4.9)

- `beq x1, x2, offset` necesita:
  - **ImmGen** + **Shift left 1** (concatenar un 0 al final del campo sign-extendido — no requiere hardware real, es solo ruteo de señales) + **Adder** → calcula branch target = `PC + (offset << 1)`.
  - **Register file** para leer los dos operandos a comparar.
  - **ALU** en modo resta, usando la salida `Zero` para el test de igualdad.
- La ISA especifica que la base del cálculo de dirección de branch es la dirección de la propia instrucción de branch (o sea, se usa el PC actual, no PC+4).

### Datapath combinado (Figuras 4.10 y 4.11)

Para compartir un único register file y una única ALU entre instrucciones R-type y de memoria, se necesitan 2 multiplexores:

1. Mux en la segunda entrada de la ALU (`ALUSrc`): registro (`Read data 2`) vs. immediate sign-extendido.
2. Mux en la entrada de datos a escribir en Registers (`MemtoReg`): resultado de la ALU vs. dato leído de memoria.

Al integrar el branch se agrega un tercer mux (`PCSrc`) para elegir entre `PC+4` y la branch target address.

**Datapath final monociclo (Figura 4.11)** combina:
- Fetch (Fig. 4.6)
- R-type + memoria (Fig. 4.10)
- Branch (Fig. 4.9)

Regla de diseño: como todo debe ejecutarse en **un solo ciclo de reloj**, ningún recurso del datapath puede usarse más de una vez por instrucción ⇒ memoria de instrucciones y de datos deben ser **físicamente separadas**.

---

## 4.4 A Simple Implementation Scheme

### ALU Control (Figura 4.12/4.13)

Códigos de la ALU (4 bits):

| ALU control lines | Función  |
|---|---|
| 0000 | AND |
| 0001 | OR |
| 0010 | add |
| 0110 | subtract |

La unidad **ALU control** genera estos 4 bits a partir de:
- `ALUOp` (2 bits, viene de la unidad de control principal)
- `funct7` (bits 31:25) y `funct3` (bits 14:12) de la instrucción

Significado de `ALUOp`:
- `00` → add (para `ld`/`sd`, cálculo de dirección)
- `01` → subtract (para `beq`, test de igualdad)
- `10` → la operación la determinan `funct7`/`funct3` (instrucciones R-type)

Tabla de verdad (Fig. 4.13) — solo se necesitan 4 bits de funct (bits 30, 14, 13, 12) porque son los únicos que difieren entre `add`/`sub`/`and`/`or`:

| ALUOp1 | ALUOp0 | I[30] | I[14:12] | Operación | ALU control |
|---|---|---|---|---|---|
| 0 | 0 | X | XXX | add | 0010 |
| X | 1 | X | XXX | subtract | 0110 |
| 1 | X | 0 | 000 | add | 0010 |
| 1 | X | 1 | 000 | subtract | 0110 |
| 1 | X | 0 | 111 | AND | 0000 |
| 1 | X | 0 | 110 | OR | 0001 |

Es un diseño de **control en dos niveles**: la unidad de control principal genera `ALUOp`, que alimenta a la unidad de ALU control, que genera las líneas reales de la ALU. Reduce el tamaño (y potencialmente la latencia) del control principal.

### Formatos de instrucción relevantes (Figura 4.14)

| Tipo | 31:25 | 24:20 | 19:15 | 14:12 | 11:7 | 6:0 |
|---|---|---|---|---|---|---|
| R-type | funct7 | rs2 | rs1 | funct3 | rd | opcode |
| I-type (load) | immediate[11:0] (todo el rango 31:20) | | rs1 | funct3 | rd | opcode |
| S-type (store) | immed[11:5] | rs2 | rs1 | funct3 | immed[4:0] | opcode |
| SB-type (branch) | immed[12,10:5] | rs2 | rs1 | funct3 | immed[4:1,11] | opcode |

Observaciones clave que simplifican el control:
- `opcode` siempre en bits 6:0.
- `rs1` siempre en bits 19:15 (R-type y branch; también base de load/store).
- `rs2` siempre en bits 24:20 (R-type y branch; también dato a guardar en store).
- `rd` siempre en bits 11:7 (R-type y load).

Opcodes RV64I usados en este subconjunto:
- R-format (`add`,`sub`,`and`,`or`): `0110011`
- `ld` (load doubleword): `0000011`
- `sd` (store doubleword): `0100011`
- `beq`: `1100011`

### Las 6 señales de control de un bit (Figura 4.15/4.16)

| Señal | Desasertada (0) | Asertada (1) |
|---|---|---|
| `RegWrite` | — | Se escribe en el registro indicado por `Write register` el valor de `Write data`. |
| `ALUSrc` | 2ª entrada de la ALU = `Read data 2` (registro) | 2ª entrada de la ALU = immediate sign-extendido (12 bits) |
| `PCSrc`* | PC ← salida del adder `PC+4` | PC ← salida del adder de branch target |
| `MemRead` | — | La salida `Read data` de Data memory refleja el contenido en `Address`. |
| `MemWrite` | — | El contenido de Data memory en `Address` se reemplaza por `Write data`. |
| `MemtoReg` | El dato a escribir en Registers viene de la ALU | El dato a escribir en Registers viene de Data memory |

\* `PCSrc` **no** es una salida directa de la unidad de control: se genera como `Branch AND Zero` (AND entre la señal `Branch` del control y la señal `Zero` de la ALU). A partir de la Fig. 4.17 el libro deja de tratarla como señal independiente.

Además: **`ALUOp`** (2 bits) es generado directamente por la unidad de control principal, en base solo al opcode.

### Datapath completo con unidad de control (Figura 4.17)

La **Control unit** (control principal) toma como única entrada el opcode (7 bits, instrucción[6:0]) y genera:

- `ALUSrc`, `MemtoReg` (selección de muxes)
- `RegWrite`, `MemRead`, `MemWrite` (lectura/escritura de banco de registros y memoria de datos)
- `Branch` (habilita el posible cambio de PC; se combina vía AND con `Zero` para producir `PCSrc`)
- `ALUOp` (2 bits, hacia la unidad de ALU control)

### Tabla de control por opcode (Figura 4.18)

| Instrucción | ALUSrc | MemtoReg | RegWrite | MemRead | MemWrite | Branch | ALUOp1 | ALUOp0 |
|---|---|---|---|---|---|---|---|---|
| R-format | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 0 |
| `ld` | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 |
| `sd` | 1 | X | 0 | 0 | 1 | 0 | 0 | 0 |
| `beq` | 0 | X | 0 | 0 | 0 | 1 | 0 | 1 |

Notas:
- `MemtoReg` es *don't care* en `sd`/`beq` porque `RegWrite=0` (no se escribe en el banco de registros, así que ese mux no importa).
- `ALUOp=10` en R-format delega la decisión real a la ALU control (usa `funct3`/`funct7`).
- `ALUOp=01` en `beq` fuerza resta (para el test de igualdad vía `Zero`).
- `ALUOp=00` en `ld`/`sd` fuerza suma (cálculo de dirección).

La Figura 4.22 del libro expande esta misma tabla a nivel de bits individuales del opcode (`I[6]…I[0]`) para poder implementarla como lógica de compuertas/PLA; es la misma información que la tabla de arriba, solo que indexada por cada bit del opcode en vez de por nombre de instrucción.

### Operación del datapath, instrucción por instrucción

**R-type** (`add x1, x2, x3`) — Figura 4.19, 4 pasos:
1. Fetch de la instrucción, PC se incrementa.
2. Se leen `x2` y `x3` del banco de registros; el control principal calcula las señales.
3. La ALU opera sobre los datos leídos (la operación exacta la decide `funct3`/`funct7` vía ALU control).
4. El resultado de la ALU se escribe en `x1`.

**Load** (`ld x1, offset(x2)`) — Figura 4.20, 5 pasos:
1. Fetch, PC se incrementa.
2. Se lee `x2` del banco de registros.
3. La ALU suma `x2` + offset sign-extendido.
4. La suma se usa como dirección hacia Data memory.
5. El dato leído de memoria se escribe en `x1`.

**Store**: análogo al load, pero `MemWrite` en vez de `MemRead`, el segundo dato leído del banco de registros (`x1` en `sd x1, offset(x2)`) es el que se escribe en memoria, y no hay escritura de vuelta al banco de registros.

**Branch** (`beq x1, x2, offset`) — Figura 4.21, 4 pasos:
1. Fetch, PC se incrementa.
2. Se leen `x1` y `x2`.
3. La ALU resta ambos valores (test de igualdad); en paralelo, `PC + (offset sign-extendido << 1)` calcula la branch target address.
4. La salida `Zero` de la ALU decide cuál de los dos adders (`PC+4` o branch target) se guarda en el PC.

### Por qué el diseño monociclo no se usa en la práctica

El ciclo de reloj debe ser lo suficientemente largo para la instrucción más lenta — típicamente `load`, que atraviesa en serie: instruction memory → register file → ALU → data memory → register file (5 unidades funcionales). Aunque el CPI es 1, el rendimiento real es pobre porque el ciclo de reloj es demasiado largo para *todas* las instrucciones, incluso las más simples. Esto viola el principio de "hacer rápido el caso común" (Cap. 1). La solución que desarrolla el resto del capítulo (fuera del alcance de estas notas) es el **pipelining**.

---

## Glosario rápido (términos del capítulo usados arriba)

- **combinational element**: elemento cuya salida depende solo de las entradas actuales (p. ej. ALU).
- **state element**: elemento con almacenamiento interno (memoria, registro).
- **clocking methodology**: define cuándo se pueden leer/escribir señales de forma predecible.
- **edge-triggered clocking**: los elementos de estado se actualizan solo en el flanco de reloj.
- **datapath element**: unidad que opera o almacena datos en el procesador (memorias, register file, ALU, adders).
- **program counter (PC)**: registro con la dirección de la instrucción en ejecución.
- **register file**: colección de registros direccionables por número.
- **sign-extend**: extender un dato replicando el bit de signo en los bits altos.
- **branch target address**: dirección destino de un branch tomado = PC + offset (sign-extendido y shifteado).
- **opcode**: campo que determina la operación/formato de la instrucción (bits 6:0 en RISC-V).
- **asserted / deasserted**: señal en 1 lógico / en 0 lógico.

---

## Mapeo a los módulos RTL de este proyecto (`rtl/`)

| Módulo del libro | Archivo actual | Estado |
|---|---|---|
| Program counter | `rtl/pc.v` | vacío (stub) |
| Instruction memory | `rtl/inst_mem.v` | vacío (stub) |
| Register file | `rtl/file_register.v` | vacío (stub) |
| ALU | `rtl/alu.v` | vacío (stub) |
| ALU control | `rtl/alu_control.v` | vacío (stub) |
| Immediate generation unit | `rtl/imm_gen.v` | vacío (stub) |
| Data memory | `rtl/data_mem.v` | vacío (stub) |
| Multiplexor 2:1 (ALUSrc / MemtoReg / PCSrc) | `rtl/mux2_1.v` | vacío (stub), se instancia 3 veces |
| **Adder** (`PC+4` y branch target) | — | **falta** (`adder.v` / `add.v`) |
| **Control unit** (control principal, decodifica opcode) | — | **falta** (`control.v`) |
| **AND gate** (`Branch` AND `Zero` → `PCSrc`) | — | falta (trivial, puede ir inline en el top) |
| **Top-level datapath** (conecta todo, Fig. 4.17) | — | **falta** (`datapath.v` / `riscv_core.v` / `cpu.v`) |
| `testbench/` | (vacío) | sin testbenches todavía |
