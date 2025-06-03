`timescale 1ns/1ps
`define ADDR_WIDTH 11

module tb_top;

logic clk;
logic reset, busy;
logic spi_start, spi_done, mosi, miso, sck, ss;
logic [31:0] spi_data;

top top (
    .clk(clk),
    .reset(reset),
    .sck_in(sck),
    .ss_in(ss),
    .mosi(mosi),
    .miso(miso)
);

spi_master spi (
    .rstb(reset),
    .clk(clk),
    .mlb(1'b1),
    .start(spi_start),
    .tdat(spi_data),
    .cdiv(2'b11),
    .din(miso),
    .ss(ss),
    .sck(sck),
    .dout(mosi),
    .done(spi_done),
    .rdata(spi_data)
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
    reset = 1;
    #CLK_PERIOD
    reset = 0;
    while (busy) #CLK_PERIOD;
    #CLK_PERIOD;
    $finish();
end

endmodule

