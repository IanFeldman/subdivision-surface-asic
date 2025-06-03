`timescale 1ns/1ps
`define ADDR_WIDTH 11

module top
(
    input clk, sck_in, reset, spi_en, ss_in, mosi,
    output logic miso
);

enum {SPI_IN, RUN, SPI_OUT} state;

/* ram logic */
logic [3:0] we0, we1, we2;
logic [3:0] ram0_we;
logic en0, en1, en2;
logic ram0_en, ram1_en;
logic [31:0] di0, di1, di2;
logic [31:0] ram0_di;
logic [31:0] do0, do1, do2;
logic [(`ADDR_WIDTH - 1):0] a0, a1, a2;
logic [(`ADDR_WIDTH - 1):0] ram0_addr, ram1_addr;

/* spi logic */
logic spi_done;
logic [31:0] spi_data, word_buffer_in, word_buffer_out;
logic [(`ADDR_WIDTH - 1):0] obj_address;

/* subsurf logic */
logic subsurf_start, busy;
logic [31:0] word_count;

quadram ram0 (
    .clk(clk),
    .we(ram0_we),
    .en(ram0_en),
    .din(ram0_di),
    .dout(do0),
    .addr(ram0_addr)
);

quadram ram1 (
    .clk(clk),
    .we(we1),
    .en(ram1_en),
    .din(di1),
    .dout(do1),
    .addr(ram1_addr)
);

quadram ram2 (
    .clk(clk),
    .we(we2),
    .en(en2),
    .din(di2),
    .dout(do2),
    .addr(a2)
);

spi_slave spi (
    .rstb(~reset),
    .ten(spi_en),
    .ss(ss_in),
    .sck(sck_in),
    .sdin(mosi),
    .mlb(1'b1),
    .tdata(spi_data),
    .sdout(miso),
    .done(spi_done),
    .rdata(spi_data)
);

subsurf subsurf (
    .clk(clk),
    .start(subsurf_start),
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

/* Change ram0 signal drivers */
always_comb begin
    /* ram0 */
    ram0_en = 1'b1;
    ram0_we = 4'b1111;
    ram0_di = word_buffer_in;
    ram0_addr = obj_address;
    /* ram1 */
    ram1_en = 1'b1;
    word_buffer_out = do0;
    ram1_addr = obj_address;

    /* set drivers to subsurf */
    if (state == RUN) begin
        /* ram0 */
        ram0_en = en0;
        ram0_we = we0;
        ram0_di = di0;
        ram0_addr = a0;
        /* ram1 */
        ram1_en = en1;
        ram1_addr = a1;

        word_buffer_out = 32'b0;
    end
end

always_ff@(posedge clk) begin
    /* init state */
    if (reset) begin
        state <= SPI_IN;
        obj_address <= 0;
    end
    case (state)
        /* read from spi */
        SPI_IN: begin
            if (spi_done == 1'b1) begin
                obj_address <= obj_address + 1;
                word_buffer_in <= spi_data;
            end

            /* when receive complete, start subdiv */
            if (spi_data == 32'hFFFFFFFF) begin
                state <= RUN;
            end
        end
        /* perform subdiv */
        RUN: begin
            subsurf_start <= 1'b1;
            /* when complete */
            if (!busy) begin
                state <= SPI_OUT;
                obj_address <= 0;
            end
        end
        /* write to spi */
        SPI_OUT: begin
            if (spi_done == 1'b1) begin
                obj_address <= obj_address + 1;
                spi_data = word_buffer_out;
            end

            /* when send complete, go back to spi in */
            if (obj_address == word_count[(`ADDR_WIDTH - 1):0]) begin
                spi_data = 32'hFFFFFFFF;
                state <= SPI_IN;
            end
        end
    endcase
end

endmodule

