`timescale 1ns / 1ps
module Pipelined_processor(
    input clk,
    input reset
);

    wire [63:0] PC_In, PC_Out;
    wire [63:0] PC_Plus_4;
    wire [31:0] Instruction_IF;
    wire [63:0] PC_Branch_Target;
    wire PCSrc;
    
    wire PC_Write_Enable;
    wire IF_ID_Write_Enable;
    wire Stall_Control_Mux;

    wire [63:0] PC_ID;
    wire [31:0] Instruction_ID;

    wire [6:0] opcode = Instruction_ID[6:0];
    wire [4:0] rd_ID  = Instruction_ID[11:7];
    wire [2:0] funct3 = Instruction_ID[14:12];
    wire [4:0] rs1_ID = Instruction_ID[19:15];
    wire [4:0] rs2_ID = Instruction_ID[24:20];
    wire [6:0] funct7 = Instruction_ID[31:25];
    wire [3:0] ALU_Control_Funct_ID = {Instruction_ID[30], Instruction_ID[14:12]};

    wire Branch_ID, MemRead_ID, MemtoReg_ID, MemWrite_ID, ALUSrc_ID, RegWrite_ID;
    wire [1:0] ALUOp_ID;

    wire Branch_ID_Final   = (Stall_Control_Mux) ? 1'b0 : Branch_ID;
    wire MemRead_ID_Final  = (Stall_Control_Mux) ? 1'b0 : MemRead_ID;
    wire MemtoReg_ID_Final = (Stall_Control_Mux) ? 1'b0 : MemtoReg_ID;
    wire MemWrite_ID_Final = (Stall_Control_Mux) ? 1'b0 : MemWrite_ID;
    wire ALUSrc_ID_Final   = (Stall_Control_Mux) ? 1'b0 : ALUSrc_ID;
    wire RegWrite_ID_Final = (Stall_Control_Mux) ? 1'b0 : RegWrite_ID;
    wire [1:0] ALUOp_ID_Final = (Stall_Control_Mux) ? 2'b00 : ALUOp_ID;

    wire [63:0] ReadData1_ID, ReadData2_ID;
    wire [63:0] Imm_ID;
    wire [63:0] WriteData_WB;

    wire [63:0] PC_EX, ReadData1_EX, ReadData2_EX, Imm_EX;
    wire [4:0] rs1_EX, rs2_EX, rd_EX;
    wire [3:0] Funct_EX;
    wire Branch_EX, MemRead_EX, MemtoReg_EX, MemWrite_EX, ALUSrc_EX, RegWrite_EX;
    wire [1:0] ALUOp_EX;

    wire [63:0] ALU_Input_A, ALU_Input_B_Intermediate, ALU_Input_B_Final;
    wire [63:0] ALU_Result_EX;
    wire Zero_Flag, BLT_Flag;
    wire [3:0] ALU_Control_Signal;
    wire [1:0] ForwardA, ForwardB;

    wire [63:0] ALU_Result_MEM, WriteData_MEM, Adder_2_MEM;
    wire [4:0] rd_MEM;
    wire MemRead_MEM, MemtoReg_MEM, MemWrite_MEM, RegWrite_MEM;
    wire Branch_MEM, Zero_MEM, BLT_MEM;

    wire [63:0] ReadData_Memory_MEM;

    wire [63:0] ReadData_Memory_WB, ALU_Result_WB;
    wire [4:0] rd_WB;
    wire MemtoReg_WB, RegWrite_WB;

    assign PC_In = (PCSrc) ? PC_Branch_Target : PC_Plus_4;

    Program_Counter PC (
        .clk(clk),
        .reset(reset),
        .PC_Write(PC_Write_Enable),
        .PC_In(PC_In),
        .PC_Out(PC_Out)
    );

    Adder Add_Inst (
        .a(PC_Out),
        .b(64'd4),
        .out(PC_Plus_4)
    );

    Instruction_Memory Instruction_Mem (
        .Instr_Addr(PC_Out),
        .Instruction(Instruction_IF)
    );

    IF_ID_reg if_id (
        .clk(clk),
        .reset(reset),
        .IF_ID_WRITE(IF_ID_Write_Enable),
        .IF_FLUSH(PCSrc),
        .PC_Out_in(PC_Out),
        .Instruction_in(Instruction_IF),
        .PC_Out_out(PC_ID),
        .Instruction_out(Instruction_ID)
    );

    Hazard_Detection_Unit Hazard_Unit (
        .RS1(rs1_ID),
        .RS2(rs2_ID),
        .ID_EX_RD(rd_EX),
        .ID_EX_MEMREAD(MemRead_EX),
        .IF_ID_WRITE(IF_ID_Write_Enable),
        .PC_WRITE(PC_Write_Enable),
        .MUX_SELECTOR_BIT(Stall_Control_Mux)
    );

    Control_Unit CU (
        .Opcode(opcode),
        .Branch(Branch_ID),
        .MemRead(MemRead_ID),
        .MemtoReg(MemtoReg_ID),
        .ALUOp(ALUOp_ID),
        .MemWrite(MemWrite_ID),
        .ALUSrc(ALUSrc_ID),
        .RegWrite(RegWrite_ID)
    );

    registerFile RF (
        .clk(clk),
        .reset(reset),
        .RS1(rs1_ID),
        .RS2(rs2_ID),
        .RD(rd_WB),
        .WriteData(WriteData_WB),
        .RegWrite(RegWrite_WB),
        .ReadData1(ReadData1_ID),
        .ReadData2(ReadData2_ID)
    );

    Imm_Extractor Imm_Gen (
        .instruction(Instruction_ID),
        .imm_data(Imm_ID)
    );

    ID_EX_reg id_ex (
        .clk(clk),
        .reset(reset),
        .ID_EX_FLUSH(PCSrc),
        .Branch_in(Branch_ID_Final),
        .MemRead_in(MemRead_ID_Final),
        .MemtoReg_in(MemtoReg_ID_Final),
        .ALUOp_in(ALUOp_ID_Final),
        .MemWrite_in(MemWrite_ID_Final),
        .ALUSrc_in(ALUSrc_ID_Final),
        .RegWrite_in(RegWrite_ID_Final),
        .PC_Out_in(PC_ID),
        .ReadData1_in(ReadData1_ID),
        .ReadData2_in(ReadData2_ID),
        .imm_data_in(Imm_ID),
        .Funct_in(ALU_Control_Funct_ID),
        .rd_in(rd_ID),
        .rs1_in(rs1_ID),
        .rs2_in(rs2_ID),
        .Branch_out(Branch_EX),
        .MemRead_out(MemRead_EX),
        .MemtoReg_out(MemtoReg_EX),
        .ALUOp_out(ALUOp_EX),
        .MemWrite_out(MemWrite_EX),
        .ALUSrc_out(ALUSrc_EX),
        .RegWrite_out(RegWrite_EX),
        .PC_Out_out(PC_EX),
        .ReadData1_out(ReadData1_EX),
        .ReadData2_out(ReadData2_EX),
        .imm_data_out(Imm_EX),
        .Funct_out(Funct_EX),
        .rd_out(rd_EX),
        .rs1_out(rs1_EX),
        .rs2_out(rs2_EX)
    );

    Fowarding_Unit Forwarding_Unit (
        .ID_EX_RS1(rs1_EX),
        .ID_EX_RS2(rs2_EX),
        .ID_EX_RD(rd_EX),
        .EX_MEM_RD(rd_MEM),
        .MEM_WB_RD(rd_WB),
        .EX_MEM_REGWRITE(RegWrite_MEM),
        .MEM_WB_REGWRITE(RegWrite_WB),
        .FA(ForwardA),
        .FB(ForwardB)
    );

    assign ALU_Input_A = (ForwardA == 2'b10) ? ALU_Result_MEM :
                         (ForwardA == 2'b01) ? WriteData_WB :
                         ReadData1_EX;

    assign ALU_Input_B_Intermediate = (ForwardB == 2'b10) ? ALU_Result_MEM :
                                      (ForwardB == 2'b01) ? WriteData_WB :
                                      ReadData2_EX;

    assign ALU_Input_B_Final = (ALUSrc_EX) ? Imm_EX : ALU_Input_B_Intermediate;

    Adder adder2 (
        .a(PC_EX),
        .b(Imm_EX),
        .out(PC_Branch_Target)
    );

    ALU_Control Control (
        .ALUOp(ALUOp_EX),
        .Funct(Funct_EX),
        .ALU_Control(ALU_Control_Signal)
    );

    ALU_64 ALU (
        .a(ALU_Input_A),
        .b(ALU_Input_B_Final),
        .ALUOp(ALU_Control_Signal),
        .Result(ALU_Result_EX),
        .Zero(Zero_Flag),
        .BLT(BLT_Flag)
    );

    wire Is_BLT = (Funct_EX[2:0] == 3'b100) || (Funct_EX[2:0] == 3'b101);
    assign PCSrc = Branch_EX & (Is_BLT ? BLT_Flag : Zero_Flag);

    EX_MEM_reg ex_mem (
        .clk(clk),
        .reset(reset),
        .Branch_in(Branch_EX),
        .MemRead_in(MemRead_EX),
        .MemtoReg_in(MemtoReg_EX),
        .MemWrite_in(MemWrite_EX),
        .RegWrite_in(RegWrite_EX),
        .Adder_2_in(PC_Branch_Target),
        .zero_in(Zero_Flag),
        .BLT_in(BLT_Flag),
        .ALU_Result_in(ALU_Result_EX),
        .ReadData2_in(ALU_Input_B_Intermediate),
        .rd_in(rd_EX),
        .Funct_in(Funct_EX),
        .Branch_out(Branch_MEM),
        .MemRead_out(MemRead_MEM),
        .MemtoReg_out(MemtoReg_MEM),
        .MemWrite_out(MemWrite_MEM),
        .RegWrite_out(RegWrite_MEM),
        .Adder_2_out(Adder_2_MEM),
        .zero_out(Zero_MEM),
        .BLT_out(BLT_MEM),
        .ALU_Result_out(ALU_Result_MEM),
        .ReadData2_out(WriteData_MEM),
        .rd_out(rd_MEM)
    );

    Data_Memory Data_Mem (
        .Mem_Addr(ALU_Result_MEM),
        .Write_Data(WriteData_MEM),
        .clk(clk),
        .MemWrite(MemWrite_MEM),
        .MemRead(MemRead_MEM),
        .Read_Data(ReadData_Memory_MEM)
    );

    MEM_WB_reg mem_wb (
        .clk(clk),
        .reset(reset),
        .MemtoReg_in(MemtoReg_MEM),
        .RegWrite_in(RegWrite_MEM),
        .ReadData_in(ReadData_Memory_MEM),
        .ALU_Result_in(ALU_Result_MEM),
        .rd_in(rd_MEM),
        .MemtoReg_out(MemtoReg_WB),
        .RegWrite_out(RegWrite_WB),
        .ReadData_out(ReadData_Memory_WB),
        .ALU_Result_out(ALU_Result_WB),
        .rd_out(rd_WB)
    );

    assign WriteData_WB = (MemtoReg_WB) ? ReadData_Memory_WB : ALU_Result_WB;

endmodule