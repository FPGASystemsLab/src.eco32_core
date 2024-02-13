//=============================================================================================
//    Main contributors                                          
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//      - Jakub Siast         <mailto:jakubsiast@gmail.com>
//=============================================================================================
`default_nettype none
//---------------------------------------------------------------------------------------------
`timescale 1ns / 1ns      
//=============================================================================================
module eco32_core_ifu_evm_ff
(
input  wire             clk,
input  wire             rst,   

input  wire             i_stb,
input  wire     [4:0]   i_erx,
input  wire     [3:0]   i_eid,
output wire             i_af,

output wire             o_stb,
output wire     [4:0]   o_erx,
output wire     [3:0]   o_eid,
input  wire             o_ack
);      
//============================================================================================= 
ff_srl_af_ack_d16
#(
.WIDTH(9), 
.AF0LIMIT(6'd2),
.AF1LIMIT(6'd2)
)   
ff_dram
(             
.clk        (clk),
.rst        (rst),
                 
.i_stb  (i_stb),  
.i_data ({i_erx, i_eid}),
.i_af   (i_af),
.i_full (), 
.i_err  (), 

.o_stb  (o_stb),
.o_ack  (o_ack),
.o_data ({o_erx, o_eid}), 
.o_ae   (),    
.o_err  ()
);                                                                                           
//=============================================================================================
endmodule