`timescale 1ns/1ps
`define ADDR_WIDTH 11

module tb_subsurf;

logic clk;
logic [3:0] we0, we1, we2;
logic en0, en1, en2;
logic [31:0] di0, di1, di2;
logic [31:0] do0, do1, do2;
logic [(`ADDR_WIDTH - 1):0] a0, a1, a2;
logic write0, write1, write2;

logic start, busy;
logic [31:0] word_count;

quadram_sim ram0 (
    .clk(clk),
    .we(we0),
    .en(en0),
    .din(di0),
    .dout(do0),
    .addr(a0),
    .wr(write0)
);

quadram_sim ram1 (
    .clk(clk),
    .we(we1),
    .en(en1),
    .din(di1),
    .dout(do1),
    .addr(a1),
    .wr(write1)
);

quadram_sim ram2 (
    .clk(clk),
    .we(we2),
    .en(en2),
    .din(di2),
    .dout(do2),
    .addr(a2),
    .wr(write2)
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
    .busy(busy),
    .word_count(word_count)
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
    write0 = 1'b0;
    write1 = 1'b0;
    write2 = 1'b0;
    #10;
    start = 1'b1;
    #10;
    start = 1'b0;
    #1000000;
    /* averager writes result to ram2 */
    write2 = 1'b1;
    #10;
    write2 = 1'b0;
    $finish();
end

endmodule

