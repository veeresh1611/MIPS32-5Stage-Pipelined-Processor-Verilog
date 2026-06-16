# MIPS32 5-Stage Pipelined Processor in Verilog

## Overview
A 32-bit MIPS processor implemented in Verilog HDL using a 5-stage pipeline architecture. This project demonstrates instruction execution through the classic MIPS pipeline and serves as a learning platform for Computer Architecture and RTL Design.

## Features
- 32-bit MIPS Architecture
- 5-Stage Pipeline (IF, ID, EX, MEM, WB)
- Register File (32 Registers)
- ALU Operations
- Instruction and Data Memory
- Branch Instruction Support
- Halt Signal Implementation
- Verilog RTL Design and Verification

## Pipeline Stages
1. **IF** – Instruction Fetch
2. **ID** – Instruction Decode & Register Read
3. **EX** – Execute / Address Calculation
4. **MEM** – Memory Access
5. **WB** – Write Back

## Project Structure

```text
MIPS32-5Stage-Pipelined-Processor-Verilog/
│
├── rtl/
│   └── mips32.v
│
├── tb/
│   └── mips32_tb.v
│
├── docs/
│   ├── MIPS32_Block_Diagram.png
│   └── MIPS32_Datapath_and_Control.pdf
│
└── README.md
```

## Supported Instructions

| Category | Instructions |
|-----------|-------------|
| Arithmetic | ADD, SUB |
| Logical | AND, OR |
| Immediate | ADDI |
| Memory | LW, SW |
| Branch | BEQ, BNE |
| Control | HLT |

## Simulation

Compile RTL:
```bash
vlog rtl/mips32.v
```

Compile Testbench:
```bash
vlog tb/mips32_tb.v
```

Run Simulation:
```bash
vsim work.mips32_tb
run -all
```

## Key Signals
- PC
- HALTED
- IF_ID_IR
- ID_EX_IR
- EX_MEM_IR
- MEM_WB_IR
- Reg[1] to Reg[5]

## Documentation
Detailed architecture and datapath diagrams are available in the `docs/` folder.

## Future Enhancements
- Hazard Detection Unit
- Data Forwarding
- Branch Prediction
- Cache Memory Integration

## Author
veeresh  
Electronics and Communication Engineering  
Interested in RTL Design, VLSI, and Computer Architecture.
