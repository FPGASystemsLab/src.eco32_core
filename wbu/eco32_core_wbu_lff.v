//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_wbm_lff
(
 input  wire            clk,
 input  wire            rst,   
//................................
 output wire            x_af,
//................................
 input  wire            i_stb,
 
 input  wire            i_clr,
 input  wire     [4:0]  i_addr,
 
 input  wire     [1:0]  i_a_ena,
 input  wire    [31:0]  i_a_data,
 input  wire            i_a_tag,
 
 input  wire     [1:0]  i_b_ena,
 input  wire            i_b_mode,
 input  wire    [31:0]  i_b_data,
 input  wire            i_b_tag,
//................................
 output wire            o_stb,
 
 output wire            o_clr,
 output wire     [4:0]  o_addr,
 
 output wire     [1:0]  o_a_ena,
 output wire    [31:0]  o_a_data,
 output wire            o_a_tag,
 
 output wire     [1:0]  o_b_ena,
 output wire            o_b_mode,
 output wire    [31:0]  o_b_data,
 output wire            o_b_tag,
 
 input  wire            o_ack
//................................
);                           
//==============================================================================================
// variables
//==============================================================================================
wire    [76:0]  o_tmp;
//==============================================================================================
// fifo
//============================================================================================== 
ff_srl_af_ack_d16
#(
.WIDTH(77), 
.AF0LIMIT(6'd1),
.AF1LIMIT(6'd1) 
)   
ff_dram
(             
.clk        (clk),
.rst        (rst),
                 
.i_stb  (i_stb),  
.i_data ({i_clr,i_addr,i_a_ena,i_a_data,i_a_tag,i_b_ena,i_b_mode,i_b_data,i_b_tag}),
.i_af   (x_af),
.i_full (),  
.i_err  (),

.o_stb  (o_stb),
.o_ack  (o_ack),
.o_data (o_tmp),
.o_ae   (),     
.o_err  ()
);                                                                                             
//============================================================================================== 
// output
//==============================================================================================                                                                                                         
assign  {o_clr,o_addr,o_a_ena,o_a_data,o_a_tag,o_b_ena,o_b_mode,o_b_data,o_b_tag}       = o_tmp;
//==============================================================================================    
endmodule