`timescale 1ns/1ps
`define ADDR_WIDTH 11

module tb_top;

/* testing signals */
logic clk, reset;
logic spi_start, spi_done, mosi, miso, sck, ss;
logic [31:0] spi_data;

/* data array - size of one quadram */
localparam A_WIDTH = 11;
localparam NUM_WORDS = 2**A_WIDTH;
reg [31:0] RAM[(NUM_WORDS-1): 0];
initial $readmemh("input.hex", RAM);
integer i;
logic [31:0] vertex_count, face_count, word_count;

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
    /* determine word count */
    vertex_count = RAM[0];
    face_count = RAM[vertex_count * 3 + 1];
    word_count = (vertex_count + face_count) * 3 + 2;

    /* reset */
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
    while (i <= word_count) begin
        #CLK_PERIOD
        if (spi_done == 1'b1) begin
            spi_data = RAM[i];
            i = i + 1;
            #CLK_PERIOD; /* wait an extra clock for spi_done to go low */
        end
    end
    if (spi_done == 1'b1) begin
        spi_data = 32'hFFFFFFFF;
        #CLK_PERIOD; /* wait an extra clock for spi_done to go low */
    end
    /* wait for spi done to go high */
    while (~spi_done) #CLK_PERIOD
    spi_start = 1'b0;

    /* wait for subsurf to finish */
    #1000000

    $writememh("output.hex", RAM);
    $finish();
end

endmodule

