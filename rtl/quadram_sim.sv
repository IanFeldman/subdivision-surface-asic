`timescale 1ns/1ps

module quadram_sim (
        clk,
        we,
        en,
        din,
        dout,
        addr,
        wr
);
       localparam A_WIDTH = 11;
       localparam NUM_WORDS = 2**A_WIDTH;
       

       input   wire                         clk;
       input   wire    [3:0]                we;
       input   wire                         en;
       input   wire    [31:0]               din;
       output  reg     [31:0]               dout;
       input   wire    [(A_WIDTH - 1): 0]   addr;
       input   wire                         wr;
       
       reg [31:0] RAM[(NUM_WORDS-1): 0];

       initial $readmemh("input.hex", RAM);
   
       always @(posedge clk) begin
           if (wr == 1'b1) begin $writememh("output.hex", RAM); end
           if(en) begin
               dout <= RAM[addr];
               if(we[0]) RAM[addr][ 7: 0] <= din[7:0];
               if(we[1]) RAM[addr][15: 8] <= din[15:8];
               if(we[2]) RAM[addr][23:16] <= din[23:16];
               if(we[3]) RAM[addr][31:24] <= din[31:24];
           end
           else
               dout <= 32'b0;
       end
endmodule
