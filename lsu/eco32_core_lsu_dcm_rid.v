//=============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================================
`default_nettype none
//---------------------------------------------------------------------------------------------
`timescale 1ns / 1ns      
//=============================================================================================
module eco32_core_lsu_dcm_rid
(
input  wire             clk,
input  wire             rst,   

input  wire             i_stb,
input  wire             i_tid,       
output wire     [1:0]   i_taf,

input  wire             wr_stb,
input  wire             wr_tid,       
input  wire     [3:0]   wr_rid,

output wire             o_stb,
output wire     [3:0]   o_rid
);      
//=============================================================================================
// parameters
//=============================================================================================
//=============================================================================================
// variables
//=============================================================================================
reg      [3:0]  th0_rid [0:15];
reg      [4:0]  th0_sel;
reg             th0_af;
//---------------------------------------------------------------------------------------------
reg      [3:0]  th1_rid [0:15];
reg      [4:0]  th1_sel;
reg             th1_af;
//=============================================================================================
// fifo TH0
//=============================================================================================
wire                                            th0_stb      =           wr_stb & wr_tid==1'b0;
wire                                            th0_ack      =            i_stb &  i_tid==1'b0;
//---------------------------------------------------------------------------------------------
generate
genvar i;
    for(i=0;i<16;i=i+1) 
     begin : shift_register_th0                                                                                                                                       
        if(i==0)
            begin : stage0
                always@(posedge clk) if(th0_stb)    th0_rid [i] <=                     wr_rid;
            end     
        else    
            begin : stageN
                always@(posedge clk) if(th0_stb)    th0_rid [i] <=               th0_rid [i-1];
            end     
     end
endgenerate
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst) 
 if(rst)                                        th0_sel     <=                             - 1;
 else if(~th0_stb &&  th0_ack)                  th0_sel     <=                     th0_sel - 1;
 else if( th0_stb && ~th0_ack)                  th0_sel     <=                     th0_sel + 1;
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)                                           
 if(rst)                                        th0_af      <=                            1'b0;
 else                                           th0_af      <=           th0_sel[4:1]!=4'b0111;
//=============================================================================================
// fifo TH1
//=============================================================================================
wire                                            th1_stb      =           wr_stb & wr_tid==1'b1;
wire                                            th1_ack      =            i_stb &  i_tid==1'b1;
//---------------------------------------------------------------------------------------------
generate
genvar j;
    for(j=0;j<16;j=j+1) 
     begin : shift_register_th1
        if(j==0)
            begin : stage0
                always@(posedge clk) if(th1_stb)    th1_rid [j]     <=                  wr_rid;
            end     
        else    
            begin : stageN
                always@(posedge clk) if(th1_stb)    th1_rid [j]     <=           th1_rid [j-1];
            end     
     end
endgenerate
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst) 
 if(rst)                                        th1_sel     <=                             - 1;
 else if(~th1_stb &&  th1_ack)                  th1_sel     <=                     th1_sel - 1;
 else if( th1_stb && ~th1_ack)                  th1_sel     <=                     th1_sel + 1;
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)                                           
 if(rst)                                        th1_af      <=                            1'b0;
 else                                           th1_af      <=           th1_sel[4:1]!=4'b0111;
//=============================================================================================
assign  i_taf[0]    =                                                                   th0_af;
assign  i_taf[1]    =                                                                   th1_af;
//---------------------------------------------------------------------------------------------
assign  o_stb       =                                                                    i_stb;
assign  o_rid       =   (i_tid)?               th1_rid [th1_sel[3:0]] : th0_rid [th0_sel[3:0]];
//=============================================================================================
endmodule