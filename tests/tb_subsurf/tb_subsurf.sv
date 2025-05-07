`timescale 1ns/1ps

module tb_subsurf;

// Declare test variables
logic clk;
reg [31:0] mem[((2**9)-1): 0];

logic [3:0] we0, we1, we2;
logic en0, en1, en2;
logic [31:0] di0, di1, di2;
logic [31:0] do0, do1, do2;
logic [8:0] a0, a1, a2;
logic write;

logic start, busy;

DFFRAM512x32 ram0 (
    .CLK(clk),
    .WE0(we0),
    .EN0(en0),
    .Di0(di0),
    .Do0(do0),
    .A0(a0)
);

DFFRAM512x32_ZERO ram1 (
    .CLK(clk),
    .WE0(we1),
    .EN0(en1),
    .Di0(di1),
    .Do0(do1),
    .A0(a1),
    .write(write)
);

DFFRAM512x32 ram2 (
    .CLK(clk),
    .WE0(we2),
    .EN0(en2),
    .Di0(di2),
    .Do0(do2),
    .A0(a2)
);

subsurf top (
    .clk(clk),
    .start(start),
    .do0(do0),
    .do1(do1),
    .do2(do2),
    .en0(en0),
    .en1(en1),
    .en2(en2),
    .a0(a0),
    .a1(a1),
    .a2(a2),
    .we0(we0),
    .we1(we1),
    .we2(we2),
    .di0(di0),
    .di1(di1),
    .di2(di2),
    .busy(busy)
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
    clk = 0;
    #10;
    start = 1'b1;
    #10;
    start = 1'b0;
    #50000;
    $finish();
end

endmodule

