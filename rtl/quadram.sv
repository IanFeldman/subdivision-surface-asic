`timescale 1ns/1ps
`define ADDR_WIDTH 11
`define ADDR_WIDTH_RAM 9 

module quadram /* synthable */
(
    input clk, en,
    input [3:0] we,
    input [31:0] din,
    input [(`ADDR_WIDTH - 1):0] addr,
    output logic [31:0] dout
);

/* internal ram signals */
logic en0, en1, en2, en3;
logic [31:0] dout0, dout1, dout2, dout3;
logic [(`ADDR_WIDTH_RAM - 1):0] addr_ram;
assign addr_ram = addr[(`ADDR_WIDTH - 3):0];

/* ram selection */
logic [1:0] ram_sel;
assign ram_sel = addr[(`ADDR_WIDTH - 1):(`ADDR_WIDTH - 2)];

DFFRAM512x32 ram0 (
    .CLK(clk),
    .WE0(we),
    .EN0(en0),
    .Di0(din),
    .Do0(dout0),
    .A0(addr_ram)
);

DFFRAM512x32 ram1 (
    .CLK(clk),
    .WE0(we),
    .EN0(en1),
    .Di0(din),
    .Do0(dout1),
    .A0(addr_ram)
);

DFFRAM512x32 ram2 (
    .CLK(clk),
    .WE0(we),
    .EN0(en2),
    .Di0(din),
    .Do0(dout2),
    .A0(addr_ram)
);

DFFRAM512x32 ram3 (
    .CLK(clk),
    .WE0(we),
    .EN0(en3),
    .Di0(din),
    .Do0(dout3),
    .A0(addr_ram)
);

always_comb begin
    en0 = 1'b0;
    en1 = 1'b0;
    en2 = 1'b0;
    en3 = 1'b0;
    dout = 32'hDEADBEEF;
    case (ram_sel)
        2'b00: begin
            en0 = en;
            dout = dout0;
        end
        2'b01: begin
            en1 = en;
            dout = dout1;
        end
        2'b10: begin
            en2 = en;
            dout = dout2;
        end
        2'b11: begin
            en3 = en;
            dout = dout3;
        end
    endcase
end

endmodule

