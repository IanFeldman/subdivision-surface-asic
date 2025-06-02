`timescale 1ns/1ps
`define ADDR_WIDTH 11

module top
(
    input clk, start,
    output logic busy
);

logic [3:0] we0, we1, we2;
logic en0, en1, en2;
logic [31:0] di0, di1, di2;
logic [31:0] do0, do1, do2;
logic [(`ADDR_WIDTH - 1):0] a0, a1, a2;

quadram ram0 (
    .clk(clk),
    .we(we0),
    .en(en0),
    .din(di0),
    .dout(do0),
    .addr(a0)
);

quadram ram1 (
    .clk(clk),
    .we(we1),
    .en(en1),
    .din(di1),
    .dout(do1),
    .addr(a1)
);

quadram ram2 (
    .clk(clk),
    .we(we2),
    .en(en2),
    .din(di2),
    .dout(do2),
    .addr(a2)
);

subsurf subsurf (
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

endmodule
