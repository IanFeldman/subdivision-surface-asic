/*
 * DFFRAM.v
 *
 * * A 512x32 DFFRAM (2 Kbytes)
 *
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the Apache License, Version 2.0 (the "License").
 *
 * DFFRAM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * Apache License, Version 2.0 for more details.
 *
 * You should have received a copy of the Apache License, Version 2.0
 * along with DFFRAM. If not, see <https://www.apache.org/licenses/LICENSE-2.0>.
 *
 * For further information, please visit .
 *
 */
 
`timescale 1ns/1ps

`default_nettype        none

module DFFRAM512x32  (
        CLK,
        WE0,
        EN0,
        Di0,
        Do0,
        A0
);
       localparam A_WIDTH = 9;
       localparam NUM_WORDS = 2**A_WIDTH;
       

       input   wire                         CLK;
       input   wire    [3:0]                WE0;
       input   wire                         EN0;
       input   wire    [31:0]               Di0;
       output  reg     [31:0]               Do0;
       input   wire    [(A_WIDTH - 1): 0]   A0;
       
       reg [31:0] RAM[(NUM_WORDS-1): 0];
   
       always @(posedge CLK)
           if(EN0) begin
               Do0 <= RAM[A0];
               if(WE0[0]) RAM[A0][ 7: 0] <= Di0[7:0];
               if(WE0[1]) RAM[A0][15: 8] <= Di0[15:8];
               if(WE0[2]) RAM[A0][23:16] <= Di0[23:16];
               if(WE0[3]) RAM[A0][31:24] <= Di0[31:24];
           end
           else
               Do0 <= 32'b0;
    endmodule