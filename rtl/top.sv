`timescale 1ns/1ps
`define ADDR_WIDTH 11

module top
(
    input clk, sck_in, reset, ss_in, mosi,
    output logic miso
);

enum {SPI_IN, RUN, WAIT, SPI_OUT, DONE} state;

/* ram logic */
logic [3:0] we0, we1, we2;
logic [3:0] ram0_we;
logic en0, en1, en2;
logic ram0_en, ram2_en;
logic [31:0] di0, di1, di2;
logic [31:0] ram0_di;
logic [31:0] do0, do1, do2;
logic [(`ADDR_WIDTH - 1):0] a0, a1, a2;
logic [(`ADDR_WIDTH - 1):0] ram0_addr, ram2_addr;

/* spi logic */
logic spi_done, spi_done_buffer;
logic [31:0] spi_data_t, spi_data_r, word_buffer_in;
logic [(`ADDR_WIDTH - 1):0] obj_address;

/* subsurf logic */
logic subsurf_start, busy;
logic [31:0] input_word_count, word_count;

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
    .en(en1),
    .din(di1),
    .dout(do1),
    .addr(a1)
);

quadram ram2 (
    .clk(clk),
    .we(we2),
    .en(ram2_en),
    .din(di2),
    .dout(do2),
    .addr(ram2_addr)
);

spi_slave spi (
    .rstb(~reset),
    .ten(1'b1),
    .ss(ss_in),
    .sck(sck_in),
    .sdin(mosi),
    .mlb(1'b1),
    .tdata(spi_data_t),
    .sdout(miso),
    .done(spi_done),
    .rdata(spi_data_r)
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
    /* ram2 */
    ram2_en = 1'b1;
    ram2_addr = obj_address - 1;

    /* set drivers to subsurf */
    if (state == RUN || state == WAIT) begin
        /* ram0 */
        ram0_en = en0;
        ram0_we = we0;
        ram0_di = di0;
        ram0_addr = a0;
        /* ram2 */
        ram2_en = en2;
        ram2_addr = a2;
    end
end

always_ff @(posedge clk) begin
    /* init state */
    if (reset) begin
        state <= SPI_IN;
        obj_address <= -2;
    end
    case (state)
        /* read from spi */
        SPI_IN: begin
            spi_done_buffer <= spi_done;
            if (spi_done == 1'b1 && spi_done_buffer == 1'b0) begin
                obj_address <= obj_address + 1;
                if (obj_address == -`ADDR_WIDTH'd2) begin
                    input_word_count <= spi_data_r;
                end else begin
                    word_buffer_in <= spi_data_r;
                end
            end

            /* when receive complete, start subdiv */
            if (obj_address - 1 == input_word_count[(`ADDR_WIDTH - 1):0]) begin
                state <= RUN;
                spi_done_buffer <= 0;
            end
        end
        /* perform subdiv */
        RUN: begin
            spi_data_t <= 32'hFFFFFFFF;
            subsurf_start <= 1'b1;
            if (busy) begin
                subsurf_start <= 1'b0;
                state <= WAIT;
            end
        end
        WAIT: begin
            spi_data_t <= 32'hFFFFFFFF;
            /* when complete */
            if (!busy) begin
                obj_address <= 0;
                state <= SPI_OUT;
            end
        end
        /* write to spi */
        SPI_OUT: begin
            spi_done_buffer <= spi_done;
            if (spi_done == 1'b1 && spi_done_buffer == 1'b0) begin
                if (obj_address == 0) begin
                    spi_data_t <= word_count;
                end else begin
                    spi_data_t <= do2;
                end
                obj_address <= obj_address + 1;
            end
            if (obj_address > word_count[(`ADDR_WIDTH - 1):0] + 1) begin
                state <= DONE;
            end
        end
        DONE: begin
            spi_data_t <= 32'b0;
        end
    endcase
end

endmodule

