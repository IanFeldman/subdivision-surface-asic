`timescale 1ns/1ps
`define ADDR_WIDTH 11

module tb_top;

logic clk;
logic start, busy;

top top (
    .clk(clk),
    .start(start),
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
    $dumpfile("tb_top.vcd");
    $dumpvars(2, tb_top);
end

initial begin
    clk = 1;
    start = 1;
    while (busy) #CLK_PERIOD;
    #CLK_PERIOD;
    $finish();
end

endmodule

