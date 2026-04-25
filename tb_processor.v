`timescale 1ns / 1ps
module tb_processor();
    reg clk, reset;
    
    reg [63:0] v1, v2, v3, v4, v5, v6, v7;
    
    Pipelined_processor uut(
        .clk(clk),
        .reset(reset)
    );

    // Original clock speed
    always #5 clk = ~clk;
    
    // Sample memory every clock cycle
    always @(posedge clk) begin
        v1 = uut.Data_Mem.data_mem[256];
        v2 = uut.Data_Mem.data_mem[260];
        v3 = uut.Data_Mem.data_mem[264];
        v4 = uut.Data_Mem.data_mem[268];
        v5 = uut.Data_Mem.data_mem[272];
        v6 = uut.Data_Mem.data_mem[276];
        v7 = uut.Data_Mem.data_mem[280];
    end
    
    initial begin
        $display("=== TESTBENCH STARTED ===");
        
        clk = 0;
        reset = 1;
        #20;
        reset = 0;
        
        $display("=== INITIAL ARRAY ===");
        $display("val1 = %0d", uut.Data_Mem.data_mem[256]);
        $display("val2 = %0d", uut.Data_Mem.data_mem[260]);
        $display("val3 = %0d", uut.Data_Mem.data_mem[264]);
        $display("val4 = %0d", uut.Data_Mem.data_mem[268]);
        $display("val5 = %0d", uut.Data_Mem.data_mem[272]);
        $display("val6 = %0d", uut.Data_Mem.data_mem[276]);
        $display("val7 = %0d", uut.Data_Mem.data_mem[280]);
        
        #50000000;
        
        $display("=== FINAL ARRAY ===");
        $display("val1 = %0d", uut.Data_Mem.data_mem[256]);
        $display("val2 = %0d", uut.Data_Mem.data_mem[260]);
        $display("val3 = %0d", uut.Data_Mem.data_mem[264]);
        $display("val4 = %0d", uut.Data_Mem.data_mem[268]);
        $display("val5 = %0d", uut.Data_Mem.data_mem[272]);
        $display("val6 = %0d", uut.Data_Mem.data_mem[276]);
        $display("val7 = %0d", uut.Data_Mem.data_mem[280]);
        
        $finish;
    end
endmodule