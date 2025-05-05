`timescale 1ns/1ps

module tb_subsurf;

// Declare test variables
logic clk;
reg [31:0] mem[((2**9)-1): 0];

logic [3:0] we0;
logic en0;
logic [31:0] di0;
logic [31:0] do0;
logic [8:0] a0;

logic [3:0] we1;
logic en1;
logic [31:0] di1;
logic [31:0] do1;
logic [8:0] a1;

DFFRAM512x32 ram1 (
    .CLK(clk),
    .WE0(we0),
    .EN0(en0),
    .Di0(di0),
    .Do0(do0),
    .A0(a0)
);

DFFRAM512x32 ram2 (
    .CLK(clk),
    .WE0(we1),
    .EN0(en1),
    .Di0(di1),
    .Do0(do1),
    .A0(a1)
);

neighbor neighbo(
    .clk(clk),
    .RAM1_Do(do0),
    .RAM2_Do(do1),
    .RAM1_EN(en0),
    .RAM2_EN(en1),
    .RAM1_A(a0),
    .RAM2_A(a1),
    .RAM1_WE(we0),
    .RAM2_WE(we1),
    .RAM1_Di(di0),
    .RAM2_Di(di1)
);

// Sample to drive clock
localparam CLK_PERIOD = 10;
always begin
    #(CLK_PERIOD/2) 
    clk<=~clk;
end

// Necessary to create Waveform
initial begin
    // Name as needed
    $dumpfile("tb_subsurf.vcd");
    $dumpvars(0);
end

initial begin
    // Test Goes Here
    clk = 0;

    #2500;

    // Make sure to call finish so test exits
    $finish();
end

endmodule

