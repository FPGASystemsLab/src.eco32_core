//=============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================================
`default_nettype none
//---------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================================
module eco32_core_lsu_dcm_pff
(
input  wire             clk,
input  wire             rst,   

input  wire             i_stb,
input  wire             i_hdr,  
input  wire     [71:0]  i_data,
input  wire     [ 3:0]  i_iid,
output wire      [1:0]  i_af,

output wire             o_hdr_stb,
input  wire             o_hdr_ack,
output wire             o_data_stb,
input  wire             o_data_flush,
output wire     [71:0]  o_data,
output wire     [ 3:0]  o_iid
);      
//=============================================================================================
// parameters
//=============================================================================================
parameter               FORCE_RST   =     0;
//=============================================================================================
// variables
//=============================================================================================
(* shreg_extract = "YES" *) reg             ff_hdr  [0:31];
(* shreg_extract = "YES" *) reg             ff_pld  [0:31]; 
(* shreg_extract = "YES" *) reg     [71:0]  ff_data [0:31];
(* shreg_extract = "YES" *) reg     [ 3:0]  ff_iid  [0:31];
(* shreg_extract = "NO"  *) reg      [5:0]  ff_icnt;
(* shreg_extract = "NO"  *) reg             ff_af9;
(* shreg_extract = "NO"  *) reg             ff_af2;
//---------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             buff_hdr_stb;
(* shreg_extract = "NO"  *) reg             buff_data_stb; 
(* shreg_extract = "NO"  *) reg     [71:0]  buff_data;
(* shreg_extract = "NO"  *) reg     [ 3:0]  buff_iid;
//---------------------------------------------------------------------------------------------
wire            f_lde;
wire            f_flush_hdr;
wire            f_flush_data;
wire            f_rde;
wire     [4:0]  f_sel;
//=============================================================================================
// fifo
//=============================================================================================
generate
genvar i;
    for(i=0;i<32;i=i+1) 
     begin : shift_register
        if(i==0)
            begin : stage0
                always@(posedge clk) if(i_stb) ff_hdr [i]   <=                           i_hdr;
                always@(posedge clk) if(i_stb) ff_pld [i]   <=                          !i_hdr; 
                always@(posedge clk) if(i_stb) ff_data[i]   <=                          i_data;
                always@(posedge clk) if(i_stb) ff_iid [i]   <=                           i_iid;
            end     
        else    
            begin : stageN
                always@(posedge clk) if(i_stb) ff_hdr [i]   <=                    ff_hdr [i-1];
                always@(posedge clk) if(i_stb) ff_pld [i]   <=                    ff_pld [i-1];
                always@(posedge clk) if(i_stb) ff_data[i]   <=                    ff_data[i-1];
                always@(posedge clk) if(i_stb) ff_iid [i]   <=                     ff_iid[i-1];
            end     
     end
endgenerate
//=============================================================================================                  
// io
//=============================================================================================
always@(posedge clk or posedge rst) 
 if(rst)                    ff_icnt    <=                                                -6'd1;
 else if( i_stb && !f_rde)  ff_icnt    <=                                       ff_icnt + 6'd1;
 else if(!i_stb &&  f_rde)  ff_icnt    <=                                       ff_icnt - 6'd1;
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst) 
 if(rst)                    ff_af9     <=                                                    0;
 else                       ff_af9     <=                !ff_icnt[5] && ff_icnt[4:0]>5'b1_0110; 
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst) 
 if(rst)                    ff_af2     <=                                                    0;
 else                       ff_af2     <=                !ff_icnt[5] && ff_icnt[4:0]>5'b1_1100; 
//=============================================================================================
// registered output
//=============================================================================================
wire    f_rdy                            =                                         !ff_icnt[5];
assign  f_lde                            =                     !buff_hdr_stb && !buff_data_stb;
assign  f_flush_hdr                      =                           o_hdr_ack && buff_hdr_stb;
assign  f_flush_data                     =                       o_data_flush && buff_data_stb;
assign  f_rde                            =               (f_lde | f_flush_data) && !ff_icnt[5];
assign  f_sel                            =                                        ff_icnt[4:0];
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst) 
 if(rst)
    begin
        buff_hdr_stb                    <=                                                 'd0;
        buff_data_stb                   <=                                                 'd0; 
        buff_data                       <=                                                 'd0;
        buff_iid                        <=                                                 'd0;
    end
 else if(f_lde && f_rdy)
    begin
        buff_hdr_stb                    <=                                      ff_hdr [f_sel];
        buff_data_stb                   <=                                      ff_pld [f_sel];
        buff_data                       <=                                      ff_data[f_sel];
        buff_iid                        <=                                      ff_iid [f_sel];
    end
 else if(f_flush_data & f_rdy)
    begin
        buff_hdr_stb                    <=                                      ff_hdr [f_sel];
        buff_data_stb                   <=                                      ff_pld [f_sel];
        buff_data                       <=                                      ff_data[f_sel]; 
        buff_iid                        <=                                      ff_iid [f_sel];
    end
 else if(f_flush_data & !f_rdy)
    begin
        buff_hdr_stb                    <=                                                 'd0;
        buff_data_stb                   <=                                                 'd0;
        buff_data                       <=                                      ff_data[f_sel];
        buff_iid                        <=                                      ff_iid [f_sel];
    end
 else if(f_flush_hdr & f_rdy)
    begin
        buff_hdr_stb                    <=                                                 'd0;    
        buff_data_stb                   <=                                                 'd0;
        buff_data                       <=                                      ff_data[f_sel];
        buff_iid                        <=                                      ff_iid [f_sel];
    end
 else if(f_flush_hdr & !f_rdy)                                                                             
    begin                                                                                                  
        buff_hdr_stb                    <=                                                 'd0;
        buff_data_stb                   <=                                                 'd0;
        buff_data                       <=                                      ff_data[f_sel];
        buff_iid                        <=                                      ff_iid [f_sel];
    end
//=============================================================================================
assign                      o_hdr_stb   =                                         buff_hdr_stb;
assign                      o_data_stb  =                                        buff_data_stb;
assign                      o_data      =                                            buff_data;
assign                      o_iid       =                                             buff_iid;      
//=============================================================================================
assign                      i_af        =                                      {ff_af9,ff_af2};
//=============================================================================================
endmodule