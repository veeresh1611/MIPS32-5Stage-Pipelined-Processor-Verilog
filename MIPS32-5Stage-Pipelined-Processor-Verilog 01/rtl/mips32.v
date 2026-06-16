`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project      : MIPS32 5-Stage Pipelined Processor
// Author       : veeresh
// Description  :
//   RTL implementation of a 32-bit MIPS processor using a classic 5-stage
//   pipeline architecture:
//
//      IF  - Instruction Fetch
//      ID  - Instruction Decode
//      EX  - Execute
//      MEM - Memory Access
//      WB  - Write Back
//
//   Supported Instructions:
//      ADD, SUB, AND, OR, SLT, MUL
//      ADDI, SUBI, SLTI
//      LW, SW
//      BEQZ, BNEQZ
//      HLT
//
//   Features:
//      • 32-bit Architecture
//      • Two-Phase Clocking Scheme
//      • Pipeline Registers Between All Stages
//      • Register File (32 × 32)
//      • Memory (1024 × 32)
//      • Branch Handling Support
//
//   Notes:
//      • Educational RTL implementation
//      • Does not include forwarding unit
//      • Does not include hazard detection unit
//      • Does not include branch prediction
//
//////////////////////////////////////////////////////////////////////////////////

module pipe_MIPS32 (
input  clk1,
input  clk2,

output [31:0] pc_out,
output [31:0] r1_out,
output [31:0] r2_out

);

//==================================================================
// Pipeline Registers
//==================================================================

reg [31:0] PC;

// IF/ID Pipeline Registers
reg [31:0] IF_ID_IR;
reg [31:0] IF_ID_NPC;

// ID/EX Pipeline Registers
reg [31:0] ID_EX_IR;
reg [31:0] ID_EX_NPC;
reg [31:0] ID_EX_A;
reg [31:0] ID_EX_B;
reg [31:0] ID_EX_Imm;

// Pipeline Control Information
reg [2:0] ID_EX_type;
reg [2:0] EX_MEM_type;
reg [2:0] MEM_WB_type;

// EX/MEM Pipeline Registers
reg [31:0] EX_MEM_IR;
reg [31:0] EX_MEM_ALUOut;
reg [31:0] EX_MEM_B;
reg        EX_MEM_cond;

// MEM/WB Pipeline Registers
reg [31:0] MEM_WB_IR;
reg [31:0] MEM_WB_ALUOut;
reg [31:0] MEM_WB_LMD;

//==================================================================
// Architectural Storage Elements
//==================================================================

// 32 × 32 Register File
reg [31:0] Reg [31:0];

// 1024 × 32 Main Memory
reg [31:0] Mem [0:1023];

//==================================================================
// Opcode Definitions
//==================================================================

parameter ADD   = 6'b000000,
          SUB   = 6'b000001,
          AND   = 6'b000010,
          OR    = 6'b000011,
          SLT   = 6'b000100,
          MUL   = 6'b000101,
          HLT   = 6'b111111,
          LW    = 6'b001000,
          SW    = 6'b001001,
          ADDI  = 6'b001010,
          SUBI  = 6'b001011,
          SLTI  = 6'b001100,
          BNEQZ = 6'b001101,
          BEQZ  = 6'b001110;

//==================================================================
// Instruction Type Encoding
//==================================================================

parameter RR_ALU = 3'b000,
          RM_ALU = 3'b001,
          LOAD   = 3'b010,
          STORE  = 3'b011,
          BRANCH = 3'b100,
          HALT   = 3'b101;

//==================================================================
// Processor Status Signals
//==================================================================

reg HALTED;
reg TAKEN_BRANCH;

//==================================================================
// IF Stage : Instruction Fetch
//==================================================================

always @(posedge clk1)
    if (HALTED == 0)
    begin
        if (((EX_MEM_IR[31:26] == BEQZ)  && (EX_MEM_cond == 1)) ||
            ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0)))
        begin
            IF_ID_IR      <= Mem[EX_MEM_ALUOut];
            TAKEN_BRANCH  <= 1'b1;
            IF_ID_NPC     <= EX_MEM_ALUOut + 1;
            PC            <= EX_MEM_ALUOut + 1;
        end
        else
        begin
            IF_ID_IR      <= Mem[PC];
            IF_ID_NPC     <= PC + 1;
            PC            <= PC + 1;
        end
    end

//==================================================================
// ID Stage : Instruction Decode
//==================================================================

always @(posedge clk2)
    if (HALTED == 0)
    begin
        if (IF_ID_IR[25:21] == 5'b00000)
            ID_EX_A <= 0;
        else
            ID_EX_A <= Reg[IF_ID_IR[25:21]];

        if (IF_ID_IR[20:16] == 5'b00000)
            ID_EX_B <= 0;
        else
            ID_EX_B <= Reg[IF_ID_IR[20:16]];

        ID_EX_NPC  <= IF_ID_NPC;
        ID_EX_IR   <= IF_ID_IR;

        // Sign Extension
        ID_EX_Imm <= {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};

        case (IF_ID_IR[31:26])
            ADD, SUB, AND, OR, SLT, MUL : ID_EX_type <= RR_ALU;
            ADDI, SUBI, SLTI            : ID_EX_type <= RM_ALU;
            LW                          : ID_EX_type <= LOAD;
            SW                          : ID_EX_type <= STORE;
            BNEQZ, BEQZ                 : ID_EX_type <= BRANCH;
            HLT                         : ID_EX_type <= HALT;
            default                     : ID_EX_type <= HALT;
        endcase
    end

//==================================================================
// EX Stage : Execute
//==================================================================

always @(posedge clk1)
    if (HALTED == 0)
    begin
        EX_MEM_type <= ID_EX_type;
        EX_MEM_IR   <= ID_EX_IR;

        TAKEN_BRANCH <= 0;

        case (ID_EX_type)

            RR_ALU:
            begin
                case (ID_EX_IR[31:26])
                    ADD : EX_MEM_ALUOut <= ID_EX_A + ID_EX_B;
                    SUB : EX_MEM_ALUOut <= ID_EX_A - ID_EX_B;
                    AND : EX_MEM_ALUOut <= ID_EX_A & ID_EX_B;
                    OR  : EX_MEM_ALUOut <= ID_EX_A | ID_EX_B;
                    SLT : EX_MEM_ALUOut <= ID_EX_A < ID_EX_B;
                    MUL : EX_MEM_ALUOut <= ID_EX_A * ID_EX_B;
                    default : EX_MEM_ALUOut <= 32'hxxxxxxxx;
                endcase
            end

            RM_ALU:
            begin
                case (ID_EX_IR[31:26])
                    ADDI : EX_MEM_ALUOut <= ID_EX_A + ID_EX_Imm;
                    SUBI : EX_MEM_ALUOut <= ID_EX_A - ID_EX_Imm;
                    SLTI : EX_MEM_ALUOut <= ID_EX_A < ID_EX_Imm;
                    default : EX_MEM_ALUOut <= 32'hxxxxxxxx;
                endcase
            end

            LOAD, STORE:
            begin
                EX_MEM_ALUOut <= ID_EX_A + ID_EX_Imm;
                EX_MEM_B      <= ID_EX_B;
            end

            BRANCH:
            begin
                EX_MEM_ALUOut <= ID_EX_NPC + ID_EX_Imm;
                EX_MEM_cond   <= (ID_EX_A == 0);
            end
        endcase
    end

//==================================================================
// MEM Stage : Memory Access
//==================================================================

always @(posedge clk2)
    if (HALTED == 0)
    begin
        MEM_WB_type <= EX_MEM_type;
        MEM_WB_IR   <= EX_MEM_IR;

        case (EX_MEM_type)

            RR_ALU,
            RM_ALU :
                MEM_WB_ALUOut <= EX_MEM_ALUOut;

            LOAD :
                MEM_WB_LMD <= Mem[EX_MEM_ALUOut];

            STORE :
                if (TAKEN_BRANCH == 0)
                    Mem[EX_MEM_ALUOut] <= EX_MEM_B;
        endcase
    end

//==================================================================
// WB Stage : Write Back
//==================================================================

always @(posedge clk1)
begin
    if (TAKEN_BRANCH == 0)
    begin
        case (MEM_WB_type)

            RR_ALU :
                Reg[MEM_WB_IR[15:11]] <= MEM_WB_ALUOut;

            RM_ALU :
                Reg[MEM_WB_IR[20:16]] <= MEM_WB_ALUOut;

            LOAD :
                Reg[MEM_WB_IR[20:16]] <= MEM_WB_LMD;

            HALT :
                HALTED <= 1'b1;
        endcase
    end
end

//==================================================================
// Debug Outputs
//==================================================================

assign pc_out = PC;
assign r1_out = Reg[1];
assign r2_out = Reg[2];


endmodule
