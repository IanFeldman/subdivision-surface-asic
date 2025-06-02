/*
 * DFFRAM.v
 *
 * A configurable DFFRAM Netlist to be hardened by OpenLane
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

module  CLKBUF_2  (input A, output X); 
    sky130_fd_sc_hd__clkbuf_2  __cell__ (.A(A), .X(X)); 
endmodule

module CLKBUF_8 (input A, output X); 
    sky130_fd_sc_hd__clkbuf_8 __cell__ (.A(A), .X(X));
endmodule

module CLKBUF_16 (input A, output X); 
    sky130_fd_sc_hd__clkbuf_16 __cell__ (.A(A), .X(X));
endmodule

module DIODE (input DIODE);
    sky130_fd_sc_hd__diode_2 __cell__ (.DIODE(DIODE));
endmodule

module CLKBUF_4 (input A, output X); 
    sky130_fd_sc_hd__clkbuf_4 __cell__ (.A(A), .X(X));
endmodule

module CONB (output HI, output LO); 
    sky130_fd_sc_hd__conb_1 __cell__ (.HI(), .LO(LO)); 
endmodule

module EBUFN_2 (input A, input TE_B, output Z); 
    sky130_fd_sc_hd__ebufn_2 __cell__ ( .A(A), .TE_B(TE_B), .Z(Z));
endmodule

module OUTREG #(parameter WIDTH=32)
(
    input   wire                CLK,        // FO: 8
    input   wire                EN,
    input   wire [WIDTH-1:0]    Di,         
    output  wire [WIDTH-1:0]    Do

);
    localparam BYTE_CNT = WIDTH / 8;

    wire [BYTE_CNT-1:0] CLKBUF;
    wire [BYTE_CNT-1:0] GCLK;
    
    wire CLK_buf;
    
    sky130_fd_sc_hd__clkbuf_4 Root_CLKBUF (.X(CLK_buf), .A(CLK));
    sky130_fd_sc_hd__clkbuf_4 Do_CLKBUF [BYTE_CNT-1:0] (.X(CLKBUF), .A(CLK_buf) );
    
    sky130_fd_sc_hd__dlclkp_4 CG [BYTE_CNT-1:0] ( .CLK(CLKBUF), .GCLK(GCLK), .GATE(EN) );

    generate
        genvar i;
        for(i=0; i<BYTE_CNT; i=i+1) begin : OUTREG_BYTE
            `ifndef NO_DIODES    
                (* keep = "true" *)
                sky130_fd_sc_hd__diode_2 DIODE [7:0] (.DIODE(Di[(i+1)*8-1:i*8]));
            `endif
            sky130_fd_sc_hd__dfxtp_1 Do_FF [7:0] ( .D(Di[(i+1)*8-1:i*8]), .Q(Do[(i+1)*8-1:i*8]), .CLK(GCLK[i]) );
        end
    endgenerate
endmodule

module DEC1x2 (
    input           EN,
    input           A,
    output [1:0]    SEL
);
    sky130_fd_sc_hd__and2b_2 AND0 ( .X(SEL[0]), .A_N(A), .B(EN) );
    sky130_fd_sc_hd__and2_2 AND1 ( .X(SEL[1]), .A(A) , .B(EN) );

endmodule

module DEC2x4 (
    input           EN,
    input   [1:0]   A,
    output  [3:0]   SEL
);
    sky130_fd_sc_hd__nor3b_2    AND0 ( .Y(SEL[0]), .A(A[0]),   .B(A[1]), .C_N(EN) );
    sky130_fd_sc_hd__and3b_2    AND1 ( .X(SEL[1]), .A_N(A[1]), .B(A[0]), .C(EN) );
    sky130_fd_sc_hd__and3b_2    AND2 ( .X(SEL[2]), .A_N(A[0]), .B(A[1]), .C(EN) ); // 4.600000
    sky130_fd_sc_hd__and3_2     AND3 ( .X(SEL[3]), .A(A[1]),   .B(A[0]), .C(EN) ); // 4.14
    
endmodule

module DEC3x8 (
    input           EN,
    input [2:0]     A,
    output [7:0]    SEL
);

    wire [2:0]  A_buf;
    wire        EN_buf;

    sky130_fd_sc_hd__clkbuf_2 ABUF[2:0] (.X(A_buf), .A(A));
    sky130_fd_sc_hd__clkbuf_2 ENBUF (.X(EN_buf), .A(EN));
    
    (* keep = "true" *)
    sky130_fd_sc_hd__nor4b_2   AND0 ( .Y(SEL[0])  , .A(A_buf[0]), .B(A_buf[1])  , .C(A_buf[2]), .D_N(EN_buf) ); // 000

    sky130_fd_sc_hd__and4bb_2   AND1 ( .X(SEL[1])  , .A_N(A_buf[2]), .B_N(A_buf[1]), .C(A_buf[0])  , .D(EN_buf) ); // 001
    sky130_fd_sc_hd__and4bb_2   AND2 ( .X(SEL[2])  , .A_N(A_buf[2]), .B_N(A_buf[0]), .C(A_buf[1])  , .D(EN_buf) ); // 010
    sky130_fd_sc_hd__and4b_2    AND3 ( .X(SEL[3])  , .A_N(A_buf[2]), .B(A_buf[1]), .C(A_buf[0])  , .D(EN_buf) );   // 011
    sky130_fd_sc_hd__and4bb_2   AND4 ( .X(SEL[4])  , .A_N(A_buf[0]), .B_N(A_buf[1]), .C(A_buf[2])  , .D(EN_buf) ); // 100
    sky130_fd_sc_hd__and4b_2    AND5 ( .X(SEL[5])  , .A_N(A_buf[1]), .B(A_buf[0]), .C(A_buf[2])  , .D(EN_buf) );   // 101
    sky130_fd_sc_hd__and4b_2    AND6 ( .X(SEL[6])  , .A_N(A_buf[0]), .B(A_buf[1]), .C(A_buf[2])  , .D(EN_buf) );   // 110
    sky130_fd_sc_hd__and4_2     AND7 ( .X(SEL[7])  , .A(A_buf[0]), .B(A_buf[1]), .C(A_buf[2])  , .D(EN_buf) ); // 111
endmodule

module BYTE #(  parameter   USE_LATCH=1)( 
    input   wire        CLK,    // FO: 1
    input   wire        WE0,     // FO: 1
    input   wire        SEL0,    // FO: 2
    input   wire [7:0]  Di0,     // FO: 1
    output  wire [7:0]  Do0
);

    wire [7:0]  Q_WIRE;
    wire        WE0_WIRE;
    wire        SEL0_B;
    wire        GCLK;
    wire        CLK_B;

    generate 
        genvar i;
`ifndef NO_DIODES
        (* keep = "true" *)
        sky130_fd_sc_hd__diode_2 DIODE_CLK (.DIODE(CLK));
`endif

        if(USE_LATCH == 1) begin
            sky130_fd_sc_hd__inv_1 CLKINV(.Y(CLK_B), .A(CLK));
            sky130_fd_sc_hd__dlclkp_1 CG( .CLK(CLK_B), .GCLK(GCLK), .GATE(WE0_WIRE) );
        end else begin
            sky130_fd_sc_hd__dlclkp_1 CG( .CLK(CLK), .GCLK(GCLK), .GATE(WE0_WIRE) );
        end
    
        sky130_fd_sc_hd__inv_1 SEL0INV(.Y(SEL0_B), .A(SEL0));
        sky130_fd_sc_hd__and2_1 CGAND( .A(SEL0), .B(WE0), .X(WE0_WIRE) );
    
        for(i=0; i<8; i=i+1) begin : BIT
            if(USE_LATCH == 0)
                sky130_fd_sc_hd__dfxtp_1 STORAGE ( .D(Di0[i]), .Q(Q_WIRE[i]), .CLK(GCLK) );
            else 
                sky130_fd_sc_hd__dlxtp_1 STORAGE (.Q(Q_WIRE[i]), .D(Di0[i]), .GATE(GCLK) );
            sky130_fd_sc_hd__ebufn_4 OBUF0 ( .A(Q_WIRE[i]), .Z(Do0[i]), .TE_B(SEL0_B) );
        end
    endgenerate 
  
endmodule

module WORD #( parameter    USE_LATCH=0,
                            WSIZE=1 ) (
    input   wire                 CLK,    // FO: 1
    input   wire [WSIZE-1:0]     WE0,     // FO: 1
    input   wire                 SEL0,    // FO: 1
    input   wire [(WSIZE*8-1):0] Di0,     // FO: 1
    output  wire [(WSIZE*8-1):0] Do0
);

    wire CLK_buf;
    wire SEL0_buf;

    sky130_fd_sc_hd__clkbuf_4 CLKBUF (.X(CLK_buf), .A(CLK));
    sky130_fd_sc_hd__clkbuf_2 SEL0BUF (.X(SEL0_buf), .A(SEL0));
    generate
        genvar i;
            for(i=0; i<WSIZE; i=i+1) begin : BYTE
                BYTE #(.USE_LATCH(USE_LATCH)) B ( .CLK(CLK_buf), .WE0(WE0[i]), .SEL0(SEL0_buf), .Di0(Di0[(i+1)*8-1:i*8]), .Do0(Do0[(i+1)*8-1:i*8]) );
            end
    endgenerate
    
endmodule 

module RAM8 #( parameter    USE_LATCH=1,
                            WSIZE=1 ) (
    input   wire                CLK,    // FO: 1
    input   wire [WSIZE-1:0]     WE0,     // FO: 1
    input                        EN0,     // EN0: 1
    input   wire [2:0]           A0,      // A: 1
    input   wire [(WSIZE*8-1):0] Di0,     // FO: 1
    output  wire [(WSIZE*8-1):0] Do0
);

    wire    [7:0]         SEL0;
    wire    [WSIZE-1:0]   WE0_buf; 
    wire                  CLK_buf;

    DEC3x8 DEC0 (.EN(EN0), .A(A0), .SEL(SEL0));
    CLKBUF_2 WEBUF[WSIZE-1:0] (.X(WE0_buf), .A(WE0));
    CLKBUF_2 CLKBUF (.X(CLK_buf), .A(CLK));

    generate
        genvar i;
        for (i=0; i< 8; i=i+1) begin : WORD
            WORD #(.USE_LATCH(USE_LATCH), .WSIZE(WSIZE)) W ( .CLK(CLK_buf), .WE0(WE0_buf), .SEL0(SEL0[i]), .Di0(Di0), .Do0(Do0) );
        end
    endgenerate

endmodule
// 2 x RAM8 slices (64 bytes) with registered outout 
module RAM16 #( parameter   USE_LATCH=1,
                            WSIZE=1 ) 
(
    input   wire                 CLK,    // FO: 2
    input   wire [WSIZE-1:0]     WE0,     // FO: 1
    input                        EN0,     // FO: 1
    input   wire [3:0]           A0,      // FO: 1
    input   wire [(WSIZE*8-1):0] Di0,     // FO: 1
    output  wire [(WSIZE*8-1):0] Do0
    
);
    wire [1:0]           SEL0;
    wire [3:0]           A0_buf;
    wire                 CLK_buf;
    wire [WSIZE-1:0]     WE0_buf;
    wire                 EN0_buf;

    wire [(WSIZE*8-1):0] Do0_pre;
    //wire [(WSIZE*8-1):0] Di0_buf;

    // Buffers
    // Di Buffers
    // CLKBUF_16  DIBUF[(WSIZE*8-1):0] (.X(Di0_buf), .A(Di0));
    // Control signals buffers
 

    
    CLKBUF_4   CLKBUF              (.X(CLK_buf), .A(CLK));
    
    CLKBUF_2   WEBUF[(WSIZE-1):0]  (.X(WE0_buf), .A(WE0));
 

    CLKBUF_2   A0BUF[3:0]           (.X(A0_buf),  .A(A0[3:0]));
    CLKBUF_2   EN0BUF               (.X(EN0_buf), .A(EN0));

    //DEC2x4 DEC0 (.EN(EN0_buf), .A(A0_buf[4:3]), .SEL(SEL0));
    DEC1x2 DEC0 (.EN(EN0_buf), .A(A0_buf[3:3]), .SEL(SEL0));
    
    generate
        genvar i;
        for (i=0; i< 2; i=i+1) begin : SLICE
            RAM8 #(.USE_LATCH(USE_LATCH), .WSIZE(WSIZE)) RAM8 (.CLK(CLK_buf), .WE0(WE0_buf),.EN0(SEL0[i]), .Di0(Di0), .Do0(Do0_pre), .A0(A0_buf[2:0]) ); 
        end
    endgenerate

    // Ensure that the Do0_pre lines are not floating when EN = 0
    wire [WSIZE-1:0] lo;
    wire [WSIZE-1:0] float_buf_en;
    CLKBUF_2   FBUFENBUF0[WSIZE-1:0] ( .X(float_buf_en), .A(EN0) );
    CONB     TIE0[WSIZE-1:0] (.LO(lo), .HI());

    // Following split by group because each is done by one TIE CELL and ONE CLKINV_4
    // Provides default values for floating lines (lo)
    generate
        for (i=0; i< WSIZE; i=i+1) begin : BYTE
            EBUFN_2 FLOATBUF0[(8*(i+1))-1:8*i] ( .A( lo[i] ), .Z(Do0_pre[(8*(i+1))-1:8*i]), .TE_B(float_buf_en[i]) );        
        end
    endgenerate

    OUTREG #(.WIDTH(WSIZE*8)) Do0_REG ( .CLK(CLK_buf), .EN(EN0_buf), .Di(Do0_pre), .Do(Do0) );

endmodule


/*
    The Main Module
    A (BANKS x 16) x (WSIZE x 8) DFFRAM
    for 128x32, use: WSIZE=4, BANKS=8    (512 Bytes)
    for 256x32, use: WSIZE=4, BANKS=16   (1K Bytes)
    for 512x32, use: WSIZE=4, BANKS=32   (2K Bytes)
*/
module DFFRAM  #( parameter     USE_LATCH   = 1,
							    WSIZE       = 4,
                                BANKS       = 8 ) 
(
	input   wire                        CLK,  
    input   wire [WSIZE-1:0]            WE0,  
    input                               EN0,  
    input   wire [$clog2(BANKS)+3:0]    A0,   
    input   wire [(WSIZE*8-1):0]        Di0,  
    output  wire [(WSIZE*8-1):0]        Do0
);
	wire [(WSIZE*8-1): 0]	Do0_pre[BANKS-1: 0];
	wire [BANKS-1: 0]       SEL0;
	reg  [BANKS-1: 0]       last_SEL0;
	
    /* A manual clock tree
        The root is buf_16 driving BANKS/4 buf_8 (ratio: 1(128), 1/2(256), 1/4(512))
        buf_8 drivies 4 x buf_4 (ratio: 1/2)
    */

    wire CLK_buf;
    wire CLK_buf_leaf[(BANKS/4)-1:0];
    (* keep *) CLKBUF_16 long_wire_repair (.X(CLK_buf), .A(CLK));

	always @(posedge CLK_buf)
        if(EN0)
		    last_SEL0 <= SEL0;
	
	generate
        genvar i;
        for (i=0; i<(BANKS); i=i+1) begin : SLICE_16
            if(i%4 == 0) begin
                (* keep *) CLKBUF_8 clk_buf_leaf (.X(CLK_buf_leaf[i/4]), .A(CLK_buf));        
            end
			assign	SEL0[i] = (A0[$clog2(BANKS)+3:4] == i) && EN0;
            RAM16   #(.USE_LATCH(USE_LATCH), .WSIZE(WSIZE)) 
                    RAM16 (.CLK(CLK_buf_leaf[i/4]), .EN0(SEL0[i]), .WE0(WE0), .Di0(Di0), .Do0(Do0_pre[i]), .A0(A0[3:0]) );        
        end
    endgenerate
	 
	integer e;
    reg[(WSIZE*8-1):0]  Do;
	always @* begin
        Do = 'b0;
        for(e=0; e<(BANKS); e=e+1)
			if((1<<e) == last_SEL0) begin
				Do = Do0_pre[e];
            end
    end
    assign Do0 = Do;
		
endmodule