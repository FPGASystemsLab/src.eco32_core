//=============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================================
`default_nettype none
//---------------------------------------------------------------------------------------------
`timescale 1ns / 1ns      
//=============================================================================================
module eco32_core_ifu_icm_token
(
input  wire             clk,
input  wire             rst,   
output wire             rdy,

input  wire             rd_stb,
output wire     [3:0]   rd_token,
output wire             rd_hold,

input  wire             wr_stb,
input  wire     [3:0]   wr_token
);      
//=============================================================================================
// parameters
//=============================================================================================
//=============================================================================================
// variables
//=============================================================================================
reg      [3:0]  fifo_token  [0:15];
reg      [4:0]  fifo_sel;
reg             fifo_rdy;
reg             fifo_hold;
//=============================================================================================
// fifo TH0
//=============================================================================================
wire            fifo_stb    =                                                           wr_stb;
wire            fifo_ack    =                                                           rd_stb;
//---------------------------------------------------------------------------------------------
generate
genvar i;
    for(i=0;i<16;i=i+1) 
     begin : shift_register
        if(i==0)
            begin : stage0
                always@(posedge clk) if(fifo_stb)   fifo_token [i]  <=                wr_token;
            end     
        else    
            begin : stageN
                always@(posedge clk) if(fifo_stb)   fifo_token [i]  <=        fifo_token [i-1];
            end     
     end
endgenerate
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst) 
 if(rst)                                    fifo_sel    <=                                 - 1;
 else if(~fifo_stb &&  fifo_ack)            fifo_sel    <=                        fifo_sel - 1;
 else if( fifo_stb && ~fifo_ack)            fifo_sel    <=                        fifo_sel + 1;
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)                                           
 if(rst)                                    fifo_rdy    <=                                1'b0;
 else                                       fifo_rdy    <=      fifo_rdy | fifo_sel==5'b0_1111;
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)                                           
 if(rst)                                    fifo_hold   <=                                1'b0;
 else                                       fifo_hold   <=  fifo_sel==5'h10 || fifo_sel<=5'h02;
//=============================================================================================
assign  rd_hold     =                                                                fifo_hold;
assign  rdy         =                                                                fifo_rdy ;
//---------------------------------------------------------------------------------------------
assign  rd_token    =                                                fifo_token[fifo_sel[3:0]];
//=============================================================================================
endmodule