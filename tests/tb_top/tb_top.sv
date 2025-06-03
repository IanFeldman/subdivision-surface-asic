`timescale 1ns/1ps
`define ADDR_WIDTH 11

module tb_top;

logic clk;
logic reset, busy;
logic mosi, miso, sck_in, ss_in;

top top (
    .clk(clk),
    .reset(reset),
    .sck_in(sck_in),
    .ss_in(ss_in),
    .mosi(mosi),
    .miso(miso)
);

assign mosi = 1'b0;
assign miso = 1'b0;
assign sck_in = 1'b0;
assign ss_in = 1'b1;

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
    reset = 1;

    #10;

    reset = 0;
    while (busy) #CLK_PERIOD;
    #CLK_PERIOD;
    $finish();
end

endmodule

