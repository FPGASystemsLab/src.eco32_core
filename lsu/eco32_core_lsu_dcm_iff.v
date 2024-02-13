//=============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================================
`default_nettype none
//---------------------------------------------------------------------------------------------
`timescale 1ns / 1ns      
//=============================================================================================
module eco32_core_lsu_dcm_iff
(
input  wire             clk,
input  wire             rst,   

input  wire             i_stb,
input  wire             i_tid,       
input  wire             i_wid,     
input  wire             i_tag,     
input  wire             i_dirty,
input  wire     [6:0]   i_page,
input  wire     [8:0]   i_mode,
input  wire             i_k_ena,
input  wire             i_k_force,
input  wire     [1:0]   i_k_op,
input  wire             i_k_sh,
input  wire    [31:0]   i_r_addr,    
input  wire    [31:0]   i_p_addr,    
input  wire    [31:0]   i_k_addr,    
output wire             i_rdy,
                                                                          
output wire             o_stb,
output wire             o_tid,       
output wire             o_wid,     
output wire             o_tag,
output wire             o_dirty,
output wire     [6:0]   o_page,
output wire     [8:0]   o_mode,
output wire             o_k_ena,
output wire             o_k_force,
output wire     [1:0]   o_k_op,       
output wire             o_k_sh,
output wire    [31:0]   o_r_addr,    
output wire    [31:0]   o_p_addr,    
output wire    [31:0]   o_k_addr,    
input  wire             o_ack
);      
//=============================================================================================
// parameters
//=============================================================================================
//=============================================================================================
// variables
//=============================================================================================
reg             ff_tid      [0:15];
reg             ff_wid      [0:15];
reg             ff_tag      [0:15];
reg             ff_dirty    [0:15];
reg      [6:0]  ff_page     [0:15];
reg      [8:0]  ff_mode     [0:15];
reg             ff_k_ena    [0:15];
reg             ff_k_force  [0:15];
reg      [1:0]  ff_k_op     [0:15];
reg             ff_k_sh     [0:15];
reg     [31:0]  ff_r_addr   [0:15];
reg     [31:0]  ff_p_addr   [0:15];
reg     [31:0]  ff_k_addr   [0:15];
reg      [4:0]  ff_sel;
reg             ff_rdy;
//=============================================================================================
// fifo
//=============================================================================================
generate
genvar i;
    for(i=0;i<16;i=i+1) 
     begin : shift_register
        if(i==0)
            begin : stage0
                always@(posedge clk) if(i_stb) ff_tid   [i]     <=        i_tid;
                always@(posedge clk) if(i_stb) ff_wid   [i]     <=        i_wid;
                always@(posedge clk) if(i_stb) ff_tag   [i]     <=        i_tag;
                always@(posedge clk) if(i_stb) ff_dirty [i]     <=        i_dirty;
                always@(posedge clk) if(i_stb) ff_page  [i]     <=        i_page;
                always@(posedge clk) if(i_stb) ff_mode  [i]     <=        i_mode;
                always@(posedge clk) if(i_stb) ff_k_ena [i]     <=        i_k_ena;
                always@(posedge clk) if(i_stb) ff_k_force[i]    <=        i_k_force;
                always@(posedge clk) if(i_stb) ff_k_op  [i]     <=        i_k_op;
                always@(posedge clk) if(i_stb) ff_k_sh  [i]     <=        i_k_sh;
                always@(posedge clk) if(i_stb) ff_r_addr[i]     <=        i_r_addr;
                always@(posedge clk) if(i_stb) ff_p_addr[i]     <=        i_p_addr;
                always@(posedge clk) if(i_stb) ff_k_addr[i]     <=        i_k_addr;
            end     
        else    
            begin : stageN
                always@(posedge clk) if(i_stb) ff_tid   [i]     <=        ff_tid [i-1];
                always@(posedge clk) if(i_stb) ff_wid   [i]     <=        ff_wid [i-1];
                always@(posedge clk) if(i_stb) ff_tag   [i]     <=        ff_tag [i-1];
                always@(posedge clk) if(i_stb) ff_dirty [i]     <=        ff_dirty [i-1];
                always@(posedge clk) if(i_stb) ff_page  [i]     <=        ff_page[i-1];
                always@(posedge clk) if(i_stb) ff_mode  [i]     <=        ff_mode[i-1];
                always@(posedge clk) if(i_stb) ff_k_ena [i]     <=        ff_k_ena [i-1];
                always@(posedge clk) if(i_stb) ff_k_force[i]    <=        ff_k_force [i-1];
                always@(posedge clk) if(i_stb) ff_k_op  [i]     <=        ff_k_op [i-1];
                always@(posedge clk) if(i_stb) ff_k_sh  [i]     <=        ff_k_sh [i-1];
                always@(posedge clk) if(i_stb) ff_r_addr[i]     <=        ff_r_addr[i-1];
                always@(posedge clk) if(i_stb) ff_p_addr[i]     <=        ff_p_addr[i-1];
                always@(posedge clk) if(i_stb) ff_k_addr[i]     <=        ff_k_addr[i-1];
            end     
     end
endgenerate
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst) 
 if(rst)                            ff_sel     <=                                          - 1;
 else if(~i_stb &&  o_ack)          ff_sel     <=                                   ff_sel - 1;
 else if( i_stb && ~o_ack)          ff_sel     <=                                   ff_sel + 1;
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)                                           
 if(rst)                            ff_rdy     <=                                         1'b0;
 else                               ff_rdy     <=                           ff_sel[4:3]!=2'b01;
//=============================================================================================
assign  o_stb       =                                                           !ff_sel[4];
assign  o_tid       =                                                 ff_tid    [ff_sel[3:0]];
assign  o_wid       =                                                 ff_wid    [ff_sel[3:0]];
assign  o_tag       =                                                 ff_tag    [ff_sel[3:0]];
assign  o_page      =                                                 ff_page   [ff_sel[3:0]];
assign  o_mode      =                                                 ff_mode   [ff_sel[3:0]];
assign  o_dirty     =                                                 ff_dirty  [ff_sel[3:0]];
assign  o_k_ena     =                                                 ff_k_ena  [ff_sel[3:0]];
assign  o_k_force   =                                                 ff_k_force[ff_sel[3:0]];
assign  o_k_op      =                                                 ff_k_op   [ff_sel[3:0]];
assign  o_k_sh      =                                                 ff_k_sh   [ff_sel[3:0]];
assign  o_r_addr    =                                                 ff_r_addr [ff_sel[3:0]];
assign  o_p_addr    =                                                 ff_p_addr [ff_sel[3:0]];
assign  o_k_addr    =                                                 ff_k_addr [ff_sel[3:0]];
//---------------------------------------------------------------------------------------------
assign  i_rdy       =                                                                   ff_rdy;
//=============================================================================================
endmodule