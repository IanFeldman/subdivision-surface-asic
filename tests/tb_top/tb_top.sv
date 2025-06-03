`timescale 1ns/1ps
`define ADDR_WIDTH 11

module tb_top;

/* testing signals */
logic clk;
logic reset, busy;
logic spi_start, spi_done, mosi, miso, sck, ss;
logic [31:0] spi_data;

/* data array - size of one quadram */
localparam A_WIDTH = 11;
localparam NUM_WORDS = 2**A_WIDTH;
reg [31:0] RAM[(NUM_WORDS-1): 0];
initial $readmemh("input.hex", RAM);
integer i;

top top (
    .clk(clk),
    .reset(reset),
    .sck_in(sck),
    .ss_in(ss),
    .mosi(mosi),
    .miso(miso)
);

spi_master spi (
    .rstb(~reset), /* active low */
    .clk(clk),
    .mlb(1'b1),
    .start(spi_start),
    .tdat(spi_data),
    .cdiv(2'b00),
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

    /* start spi transaction */
    spi_start = 1'b1;
    #CLK_PERIOD
    /* send object data */
    spi_data = RAM[0];
    i = 1;
    while (i < 10) begin /* TODO: send very word in ram */
        #CLK_PERIOD
        if (spi_done == 1'b1) begin
            spi_data = RAM[i];
            i = i + 1;
        end
    end
    if (spi_done == 1'b1) begin
        spi_data = 32'hFFFFFFFF;
    end
    #CLK_PERIOD
    /* wait for subsurf to finish */
    while (busy) #CLK_PERIOD
    #CLK_PERIOD
    #100000
    $writememh("output.hex", RAM);
    $finish();
end

endmodule

