////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: SPI (Verilog)                                            ////
////                                                                        ////
//// Module Name: spi_slave                                                 ////
////                                                                        ////
////                                                                        ////
////  This file is part of the Ethernet IP core project                     ////
////  http://opencores.com/project,spi_verilog_master_slave                 ////
////                                                                        ////
////  Author(s):                                                            ////
////      Santhosh G (santhg@opencores.org)                                 ////
////                                                                        ////
////  Refer to Readme.txt for more information                              ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Copyright (C) 2014, 2015 Authors                                       ////
////                                                                        ////
//// This source file may be used and distributed without                   ////
//// restriction provided that this copyright statement is not              ////
//// removed from the file and that any derivative work contains            ////
//// the original copyright notice and the associated disclaimer.           ////
////                                                                        ////
//// This source file is free software; you can redistribute it             ////
//// and/or modify it under the terms of the GNU Lesser General             ////
//// Public License as published by the Free Software Foundation;           ////
//// either version 2.1 of the License, or (at your option) any             ////
//// later version.                                                         ////
////                                                                        ////
//// This source is distributed in the hope that it will be                 ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied             ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR                ////
//// PURPOSE.  See the GNU Lesser General Public License for more           ////
//// details.                                                               ////
////                                                                        ////
//// You should have received a copy of the GNU Lesser General              ////
//// Public License along with this source; if not, download it             ////
//// from http://www.opencores.org/lgpl.shtml                               ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
/* SPI MODE 3
        CHANGE DATA (sdout) @ NEGEDGE SCK
        read data (sdin) @posedge SCK
*/
`timescale 1ns/1ps

module spi_slave (rstb,ten,tdata,mlb,ss,sck,sdin, sdout,done,rdata);
  input rstb,ss,sck,sdin,ten,mlb;
  input [31:0] tdata;
  output sdout;           //slave out   master in 
  output reg done;
  output reg [31:0] rdata;
 
  reg [31:0] treg,rreg;
  reg [5:0] nb;
  wire sout;
 
  assign sout=mlb?treg[31]:treg[0];
  assign sdout=( (!ss)&&ten )?sout:1'bz; //if 1=> send data  else TRI-STATE sdout
 
 
//read from  sdout
always @(posedge sck or negedge rstb)
  begin
    if (rstb==0)
        begin rreg = 32'h0;  rdata = 32'h0; done = 0; nb = 0; end   //
    else if (!ss) begin 
            if(mlb==0)  //LSB first, in@msb -> right shift
                begin rreg ={sdin,rreg[31:1]}; end
            else     //MSB first, in@lsb -> left shift
                begin rreg ={rreg[30:0],sdin}; end  
        //increment bit count
            nb=nb+1;
            if(nb!=32) done=0;
            else  begin rdata=rreg; done=1; nb=0; end
        end     //if(!ss)_END  if(nb==32)
  end
 
//send to  sdout
always @(negedge sck or negedge rstb)
  begin
    if (rstb==0)
        begin treg = 32'hFFFFFFFF; end
    else begin
        if(!ss) begin            
            if(nb==0) treg=tdata;
            else begin
               if(mlb==0)  //LSB first, out=lsb -> right shift
                    begin treg = {1'b1,treg[31:1]}; end
               else     //MSB first, out=msb -> left shift
                    begin treg = {treg[30:0],1'b1}; end            
            end
        end //!ss
     end //rstb    
  end //always
 
endmodule
