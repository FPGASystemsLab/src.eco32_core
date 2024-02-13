//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_trace_box
(
 input  wire            clk,
 input  wire            rst,   

 output wire            fco_dbg_af,
 input  wire            fci_inst_lsf,
 
 input  wire            ins_stb,                                 
 input  wire            ins_skp,                                 
 input  wire            ins_tid,                                 
 input  wire     [1:0]  ins_pid,
 input  wire    [15:0]  ins_isw,
 input  wire    [31:0]  ins_iva,
 input  wire    [31:0]  ins_opc,
 input  wire            ins_ste,   
 input  wire    [31:0]  ins_ext,
 input  wire            ins_stf,   
 input  wire     [7:0]  ins_cfa,
 input  wire            ins_stl,   
 input  wire     [7:0]  ins_lck,
 input  wire     [7:0]  ins_crs,
 input  wire    [31:0]  ins_cra,
 input  wire    [31:0]  ins_crb,
 
 input  wire            wb0_ena, 
 input  wire     [3:0]  wb0_stb,
 input  wire     [4:0]  wb0_addr,
 input  wire     [7:0]  wb0_ben,
 input  wire    [63:0]  wb0_data,
 
 input  wire            wb1_ena, 
 input  wire     [3:0]  wb1_stb,
 input  wire     [4:0]  wb1_addr,
 input  wire     [7:0]  wb1_ben,
 input  wire    [63:0]  wb1_data,
                                  
 input  wire            nif_i_stb,
 input  wire            nif_i_tid, 
 input  wire    [ 3:0]  nif_i_rid,
 input  wire    [ 3:0]  nif_i_sid, 
 input  wire    [38:3]  nif_i_addr,
 input  wire            nif_i_vir,
 input  wire            nif_i_l,
 input  wire    [ 1:0]  nif_i_mop, 
                                  
 input  wire            nif_o_stb,
 input  wire            nif_o_tid, 
 input  wire    [ 3:0]  nif_o_rid,
 input  wire    [ 3:0]  nif_o_sid,	
 input  wire    [38:3]  nif_o_addr,
 input  wire            nif_o_vir,	  
 input  wire            nif_o_l,
 input  wire    [ 1:0]  nif_o_mop,
 
 // trace port

 input  wire            dbg_i_stb,
 input  wire     [7:0]  dbg_i_data,
 output wire            dbg_i_ack,
 
 output wire            dbg_o_stb,
 output wire     [7:0]  dbg_o_data,
 input  wire            dbg_o_ack
);                             
//==============================================================================================
parameter   [6:0] CORE_ID   =  8'd0;
//==============================================================================================
// variables
//==============================================================================================
reg     [(15+52)*8-1:0]  buff_in_a2;
reg                 buff_we_a2;
reg                 buff_ins_a2;

reg     [(15+52)*8-1:0]  buff_in_b3;
reg                 buff_we_b3;
reg                 buff_is_b3;
reg                 buff_ins_b3;
//----------------------------------------------------------------------------------------------  
reg                 dbg_cnt_ovf;
reg         [24:0]  dbg_cnt;
reg                 dbg_af;
//----------------------------------------------------------------------------------------------
wire                buff_wen;
wire  [1+(15+56)*8-1:0]  buff_data;
reg   [1+(15+56)*8-1:0]     buff [128:0];
reg          [7:0]  buff_cnt;
reg          [6:0]  wr_ptr;
reg          [6:0]  rd_ptr;
reg                 buff_af;
reg                 buff_ae;
wire                buff_stb;
//----------------------------------------------------------------------------------------------
wire                io_wen;
wire                io_ren;
wire         [7:0]  io_input;
reg          [7:0]  io_buff [1023:0];
reg         [10:0]  io_cnt;
reg          [9:0]  io_wptr;
reg          [9:0]  io_rptr;
reg                 io_rdy;
reg                 io_af;
reg                 io_ae;
//==============================================================================================
wire            wb0_L       =                                                     |wb0_stb[1:0];
wire            wb0_H       =                                                     |wb0_stb[3:2];
wire            wb1_L       =                                                     |wb1_stb[1:0];
wire            wb1_H       =                                                     |wb1_stb[3:2];
wire            wb0_enax    =                                        wb0_ena && (wb0_L | wb0_H);
wire            wb1_enax    =                                        wb1_ena && (wb1_L | wb1_H);
//----------------------------------------------------------------------------------------------
wire    [2:0]   wb0_ebenL   =   (wb0_stb[1:0]==2'b10  ) ?                                  3'd7:
                                (wb0_ben[3:0]==4'b0001) ?                                  3'd4:
                                (wb0_ben[3:0]==4'b0011) ?                                  3'd5:
                                (wb0_ben[3:0]==4'b0111) ?                                  3'd6:
                                (wb0_ben[3:0]==4'b1111) ?                                  3'd0:
                                (wb0_ben[3:0]==4'b1110) ?                                  3'd1:
                                (wb0_ben[3:0]==4'b1100) ?                                  3'd2:
                                (wb0_ben[3:0]==4'b1000) ?                                  3'd3:
                                                                                           3'd7;
//----------------------------------------------------------------------------------------------
wire    [2:0]   wb0_ebenH   =   (wb0_stb[3:2]==2'b10  ) ?                                  3'd7:
                                (wb0_ben[7:4]==4'b0001) ?                                  3'd4:
                                (wb0_ben[7:4]==4'b0011) ?                                  3'd5:
                                (wb0_ben[7:4]==4'b0111) ?                                  3'd6:
                                (wb0_ben[7:4]==4'b1111) ?                                  3'd0:
                                (wb0_ben[7:4]==4'b1110) ?                                  3'd1:
                                (wb0_ben[7:4]==4'b1100) ?                                  3'd2:
                                (wb0_ben[7:4]==4'b1000) ?                                  3'd3:
                                                                                           3'd7;
//----------------------------------------------------------------------------------------------
wire    [2:0]   wb1_ebenL   =   (wb1_stb[1:0]==2'b10  ) ?                                  3'd7:
                                (wb1_ben[3:0]==4'b0001) ?                                  3'd4:
                                (wb1_ben[3:0]==4'b0011) ?                                  3'd5:
                                (wb1_ben[3:0]==4'b0111) ?                                  3'd6:
                                (wb1_ben[3:0]==4'b1111) ?                                  3'd0:
                                (wb1_ben[3:0]==4'b1110) ?                                  3'd1:
                                (wb1_ben[3:0]==4'b1100) ?                                  3'd2:
                                (wb1_ben[3:0]==4'b1000) ?                                  3'd3:
                                                                                           3'd7;
//----------------------------------------------------------------------------------------------
wire    [2:0]   wb1_ebenH   =   (wb1_stb[3:2]==2'b10  ) ?                                  3'd7:
                                (wb1_ben[7:4]==4'b0001) ?                                  3'd4:
                                (wb1_ben[7:4]==4'b0011) ?                                  3'd5:
                                (wb1_ben[7:4]==4'b0111) ?                                  3'd6:
                                (wb1_ben[7:4]==4'b1111) ?                                  3'd0:
                                (wb1_ben[7:4]==4'b1110) ?                                  3'd1:
                                (wb1_ben[7:4]==4'b1100) ?                                  3'd2:
                                (wb1_ben[7:4]==4'b1000) ?                                  3'd3:
                                                                                           3'd7;
//---------------------------------------------------------------------------------------------- 
wire            crx_ena     =                                                     |ins_crs[7:5];
wire            nif_ena     =                                                     nif_i_stb | nif_o_stb;
//----------------------------------------------------------------------------------------------
wire     [7:0]  header      =       {1'b0, 1'b0, 1'b0,ins_stb,nif_ena,crx_ena,wb0_enax,wb1_enax};
//==============================================================================================
// instruction trace
//==============================================================================================
wire     [7:0]  ihdr_b0     =          {1'b0,ins_tid,ins_ste,ins_stf,1'b0,ins_stl,ins_skp,1'b0};
//----------------------------------------------------------------------------------------------
wire     [7:0]  chdr_b0     =                                                           ins_crs;
//----------------------------------------------------------------------------------------------
wire     [7:0]  addr_b1     =                                {1'b0,3'b000,      ins_iva[31:28]};
wire     [7:0]  addr_b2     =                                {1'b0,             ins_iva[27:21]};
wire     [7:0]  addr_b3     =                                {1'b0,             ins_iva[20:14]};
wire     [7:0]  addr_b4     =                                {1'b0,             ins_iva[13: 7]};
wire     [7:0]  addr_b5     =                                {1'b0,             ins_iva[ 6: 0]};
//----------------------------------------------------------------------------------------------
wire     [7:0]  iopc_b1     =                                {1'b0,1'b0,ins_pid,ins_opc[31:28]};
wire     [7:0]  iopc_b2     =                                {1'b0,             ins_opc[27:21]};
wire     [7:0]  iopc_b3     =                                {1'b0,             ins_opc[20:14]};
wire     [7:0]  iopc_b4     =                                {1'b0,             ins_opc[13: 7]};
wire     [7:0]  iopc_b5     =                                {1'b0,             ins_opc[ 6: 0]};
//----------------------------------------------------------------------------------------------
wire     [7:0]  iext_b1     =                                {1'b0,3'b000      ,ins_ext[31:28]};
wire     [7:0]  iext_b2     =                                {1'b0,             ins_ext[27:21]};
wire     [7:0]  iext_b3     =                                {1'b0,             ins_ext[20:14]};
wire     [7:0]  iext_b4     =                                {1'b0,             ins_ext[13: 7]};
wire     [7:0]  iext_b5     =                                {1'b0,             ins_ext[ 6: 0]};
//----------------------------------------------------------------------------------------------
wire     [7:0]  cra_b1      =                               {1'b0,2'b10,ins_tid,ins_cra[31:28]};
wire     [7:0]  cra_b2      =                               {1'b0,              ins_cra[27:21]};
wire     [7:0]  cra_b3      =                               {1'b0,              ins_cra[20:14]};
wire     [7:0]  cra_b4      =                               {1'b0,              ins_cra[13: 7]};
wire     [7:0]  cra_b5      =                               {1'b0,              ins_cra[ 6: 0]};
//----------------------------------------------------------------------------------------------
wire     [7:0]  crb_b1      =                               {1'b0,2'b10,ins_tid,ins_crb[31:28]};
wire     [7:0]  crb_b2      =                               {1'b0,              ins_crb[27:21]};
wire     [7:0]  crb_b3      =                               {1'b0,              ins_crb[20:14]};
wire     [7:0]  crb_b4      =                               {1'b0,              ins_crb[13: 7]};
wire     [7:0]  crb_b5      =                               {1'b0,              ins_crb[ 6: 0]};
//----------------------------------------------------------------------------------------------
wire     [7:0]  icfa_b0     =                                {1'b0,             ins_cfa[ 6: 0]};
//----------------------------------------------------------------------------------------------
wire     [7:0]  ilck_b0     =                                {1'b0,             ins_lck[ 6: 0]};    
//============================================================================================== 
wire     [7:0]  nif_hdr =                          {4'd0, nif_i_stb, nif_i_tid, nif_o_stb, nif_o_tid};             
//---------------------------------------------------------------------------------------------- 
wire     [7:0]  nif_i_b0    =                               {1'b0, nif_i_vir, nif_i_mop[1:0], nif_i_rid[3:0]};
wire     [7:0]  nif_i_b1    =                               {1'b0, nif_i_sid[3:0], nif_i_l, nif_i_addr[38:37]};
wire     [7:0]  nif_i_b2    =                               {1'b0, 1'b1,            nif_i_addr[36:31]};
wire     [7:0]  nif_i_b3    =                               {1'b0,                  nif_i_addr[30:24]};
wire     [7:0]  nif_i_b4    =                               {1'b0,                  nif_i_addr[23:17]};
wire     [7:0]  nif_i_b5    =                               {1'b0,                  nif_i_addr[16:10]};
wire     [7:0]  nif_i_b6    =                               {1'b0,                  nif_i_addr[ 9: 3]};      
//---------------------------------------------------------------------------------------------- 
wire     [7:0]  nif_o_b0    =                               {1'b0, nif_o_vir, nif_o_mop[1:0], nif_o_rid[3:0]};
wire     [7:0]  nif_o_b1    =                               {1'b0, nif_o_sid[3:0], nif_o_l, nif_o_addr[38:37]};
wire     [7:0]  nif_o_b2    =                               {1'b0, 1'b1,            nif_o_addr[36:31]};
wire     [7:0]  nif_o_b3    =                               {1'b0,                  nif_o_addr[30:24]};
wire     [7:0]  nif_o_b4    =                               {1'b0,                  nif_o_addr[23:17]};
wire     [7:0]  nif_o_b5    =                               {1'b0,                  nif_o_addr[16:10]};
wire     [7:0]  nif_o_b6    =                               {1'b0,                  nif_o_addr[ 9: 3]};       
//==============================================================================================
wire     [7:0]  wb0_hdr =                                   {1'b0,wb0_L,wb0_H,        wb0_addr};
//----------------------------------------------------------------------------------------------
wire     [7:0]  wb0_L_b1    =                               {1'b0, wb0_ebenL  ,wb0_data[31:28]};
wire     [7:0]  wb0_L_b2    =                               {1'b0,             wb0_data[27:21]};
wire     [7:0]  wb0_L_b3    =                               {1'b0,             wb0_data[20:14]};
wire     [7:0]  wb0_L_b4    =                               {1'b0,             wb0_data[13: 7]};
wire     [7:0]  wb0_L_b5    =                               {1'b0,             wb0_data[ 6: 0]};
//----------------------------------------------------------------------------------------------
wire     [7:0]  wb0_H_b1    =                               {1'b0, wb0_ebenH  ,wb0_data[63:60]};
wire     [7:0]  wb0_H_b2    =                               {1'b0,             wb0_data[59:53]};
wire     [7:0]  wb0_H_b3    =                               {1'b0,             wb0_data[52:46]};
wire     [7:0]  wb0_H_b4    =                               {1'b0,             wb0_data[45:39]};
wire     [7:0]  wb0_H_b5    =                               {1'b0,             wb0_data[38:32]};
//----------------------------------------------------------------------------------------------
wire     [7:0]  wb1_hdr     =                               {1'b0,wb1_L,wb1_H,        wb1_addr};
//----------------------------------------------------------------------------------------------
wire     [7:0]  wb1_L_b1    =                               {1'b0,  wb1_ebenL ,wb1_data[31:28]};
wire     [7:0]  wb1_L_b2    =                               {1'b0,             wb1_data[27:21]};
wire     [7:0]  wb1_L_b3    =                               {1'b0,             wb1_data[20:14]};
wire     [7:0]  wb1_L_b4    =                               {1'b0,             wb1_data[13: 7]};
wire     [7:0]  wb1_L_b5    =                               {1'b0,             wb1_data[ 6: 0]};
//----------------------------------------------------------------------------------------------
wire     [7:0]  wb1_H_b1    =                               {1'b0,  wb1_ebenH ,wb1_data[63:60]};
wire     [7:0]  wb1_H_b2    =                               {1'b0,             wb1_data[59:53]};
wire     [7:0]  wb1_H_b3    =                               {1'b0,             wb1_data[52:46]};
wire     [7:0]  wb1_H_b4    =                               {1'b0,             wb1_data[45:39]};
wire     [7:0]  wb1_H_b5    =                               {1'b0,             wb1_data[38:32]};
//----------------------------------------------------------------------------------------------
wire [(15+52)*8-1:0] buff_in = 
{              
nif_hdr,                                                             
nif_i_b0, nif_i_b1, nif_i_b2, nif_i_b3, nif_i_b4, nif_i_b5, nif_i_b6,
nif_o_b0, nif_o_b1, nif_o_b2, nif_o_b3, nif_o_b4, nif_o_b5, nif_o_b6,
addr_b1, addr_b2, addr_b3, addr_b4, addr_b5,
iopc_b1, iopc_b2, iopc_b3, iopc_b4, iopc_b5, 
iext_b1, iext_b2, iext_b3, iext_b4, iext_b5,  
chdr_b0,
cra_b1,  cra_b2,  cra_b3,  cra_b4,  cra_b5, 
crb_b1,  crb_b2,  crb_b3,  crb_b4,  crb_b5, 
icfa_b0,
ilck_b0,
wb0_hdr, 
wb0_L_b1, wb0_L_b2, wb0_L_b3, wb0_L_b4, wb0_L_b5,
wb0_H_b1, wb0_H_b2, wb0_H_b3, wb0_H_b4, wb0_H_b5,
wb1_hdr, 
wb1_L_b1, wb1_L_b2, wb1_L_b3, wb1_L_b4, wb1_L_b5,
wb1_H_b1, wb1_H_b2, wb1_H_b3, wb1_H_b4, wb1_H_b5,
ihdr_b0, 
header
};
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst) 
  begin 
    buff_we_a2 <= 'd0;            
    buff_ins_a2 <= 'd0;                 
  end
 else    
  begin 
    buff_we_a2 <= |header[3:0];               
    buff_ins_a2 <= ins_stb;   
  end
//----------------------------------------------------------------------------------------------
always@(posedge clk) buff_in_a2 <= buff_in; 
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst) 
  begin 
    buff_we_b3 <= 'd0;               
    buff_is_b3 <= 'd0;              
    buff_ins_b3 <= 'd0;
  end
 else    
  begin 
    buff_we_b3 <= buff_we_a2; 
    buff_is_b3 <= fci_inst_lsf;            
    buff_ins_b3 <= buff_ins_a2; 
  end
//----------------------------------------------------------------------------------------------
always@(posedge clk)  buff_in_b3 <= buff_in_a2; 
//----------------------------------------------------------------------------------------------
wire      ins_en      =                                              !buff_is_b3 && buff_ins_b3;
assign    buff_wen    =                                                    ins_en || buff_we_b3;
assign    buff_data   = {dbg_cnt_ovf,dbg_cnt[23:0],buff_in_b3[(15+52)*8-1:5],ins_en,buff_in_b3[3:0]}; 
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                        dbg_cnt <= 25'd0;
 else if(buff_wen)              dbg_cnt <= 25'd0;
 else                           dbg_cnt <= dbg_cnt + 25'd1;
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                        dbg_cnt_ovf <= 1'd0;
 else if(buff_wen)              dbg_cnt_ovf <= 1'd0;
 else if(dbg_cnt[24])           dbg_cnt_ovf <= 1'd1;
//==============================================================================================
// buffer
//==============================================================================================
wire                            wr_ena      =                                          buff_wen;
wire                            rd_ena;
//----------------------------------------------------------------------------------------------
always@(posedge clk)
    if(buff_wen)                buff[wr_ptr] <= buff_data;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        wr_ptr <= 8'd0;
 else if(wr_ena)                wr_ptr <= wr_ptr + 8'd1;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)                                       
 if(rst)                        rd_ptr <= 9'd0;                         
 else if(rd_ena)                rd_ptr <= rd_ptr + 8'd1;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        buff_cnt <=          - 'd1;
 else if(!rd_ena &&  wr_ena)    buff_cnt <= buff_cnt + 'd1;
 else if( rd_ena && !wr_ena)    buff_cnt <= buff_cnt - 'd1;
//----------------------------------------------------------------------------------------------
wire  [1+(15+56)*8-1:0]                 buff_out = buff[rd_ptr];
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        buff_af <= 1'd0;
 else if(buff_af==1'b1)         buff_af <= buff_cnt[7:4] == 4'b0_000 ?             1'b0 : 1'b1 ;
 else if(buff_af==1'b0)         buff_af <= buff_cnt[7:5] == 3'b0_11  ?             1'b1 : 1'b0 ;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        buff_ae <=                                                 1'd0;
 else                           buff_ae <=            (buff_cnt[7:4] == 4'b0_000) | buff_cnt[7];
//----------------------------------------------------------------------------------------------
assign                          buff_stb        =                                  !buff_cnt[7];
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                        dbg_af  <=                                                 1'd0;
 else if(dbg_af==1'b0)          dbg_af  <=                                              buff_af;
 else if(dbg_af==1'b1)          dbg_af  <= (buff_ae && io_ae) ?                     1'b0 : 1'b1;
//----------------------------------------------------------------------------------------------
assign                          fco_dbg_af      =                                        dbg_af;  
//==============================================================================================
wire    [23:0]  o_dbg_cnt;  
wire            o_dbg_cnt_ovf;
//----------------------
wire     [7:0]  o_header;   
//----------------------
wire     [7:0]  o_ihdr_b0;  
//----------------------
wire     [7:0]  o_chdr_b0;  
//----------------------
wire     [7:0]  o_addr_b1;  
wire     [7:0]  o_addr_b2;  
wire     [7:0]  o_addr_b3;  
wire     [7:0]  o_addr_b4;  
wire     [7:0]  o_addr_b5;  
//----------------------
wire     [7:0]  o_iopc_b1;  
wire     [7:0]  o_iopc_b2;  
wire     [7:0]  o_iopc_b3;  
wire     [7:0]  o_iopc_b4;  
wire     [7:0]  o_iopc_b5;  
//----------------------
wire     [7:0]  o_iext_b1;  
wire     [7:0]  o_iext_b2;  
wire     [7:0]  o_iext_b3;  
wire     [7:0]  o_iext_b4;  
wire     [7:0]  o_iext_b5;  
//----------------------
wire     [7:0]  o_cra_b1;   
wire     [7:0]  o_cra_b2;   
wire     [7:0]  o_cra_b3;   
wire     [7:0]  o_cra_b4;   
wire     [7:0]  o_cra_b5;   
//----------------------
wire     [7:0]  o_crb_b1;   
wire     [7:0]  o_crb_b2;   
wire     [7:0]  o_crb_b3;   
wire     [7:0]  o_crb_b4;   
wire     [7:0]  o_crb_b5;   
//-----------------------
wire     [7:0]  o_icfa_b0;
//-----------------------
wire     [7:0]  o_ilck_b0;  
//----------------------
wire     [7:0]  o_wb0_hdr;
wire     [7:0]  o_wb0_L_b1;
wire     [7:0]  o_wb0_L_b2;
wire     [7:0]  o_wb0_L_b3;
wire     [7:0]  o_wb0_L_b4;
wire     [7:0]  o_wb0_L_b5;
//----------------------
wire     [7:0]  o_wb0_H_b1;
wire     [7:0]  o_wb0_H_b2;
wire     [7:0]  o_wb0_H_b3;
wire     [7:0]  o_wb0_H_b4;
wire     [7:0]  o_wb0_H_b5;
//----------------------
wire     [7:0]  o_wb1_hdr;
wire     [7:0]  o_wb1_L_b1;
wire     [7:0]  o_wb1_L_b2;
wire     [7:0]  o_wb1_L_b3;
wire     [7:0]  o_wb1_L_b4;
wire     [7:0]  o_wb1_L_b5;
//----------------------
wire     [7:0]  o_wb1_H_b1;
wire     [7:0]  o_wb1_H_b2;
wire     [7:0]  o_wb1_H_b3;
wire     [7:0]  o_wb1_H_b4;
wire     [7:0]  o_wb1_H_b5; 
//---------------------- 
wire     [7:0]  o_nif_hdr;  
//---------------------- 
wire     [7:0]  o_nif_i_b0;
wire     [7:0]  o_nif_i_b1;
wire     [7:0]  o_nif_i_b2;
wire     [7:0]  o_nif_i_b3;
wire     [7:0]  o_nif_i_b4;
wire     [7:0]  o_nif_i_b5;
wire     [7:0]  o_nif_i_b6; 
//---------------------- 
wire     [7:0]  o_nif_o_b0;
wire     [7:0]  o_nif_o_b1;
wire     [7:0]  o_nif_o_b2;
wire     [7:0]  o_nif_o_b3;
wire     [7:0]  o_nif_o_b4;
wire     [7:0]  o_nif_o_b5;
wire     [7:0]  o_nif_o_b6;                                            
//==============================================================================================
assign 
{      
o_dbg_cnt_ovf,  o_dbg_cnt,                          
o_nif_hdr,                                                             
o_nif_i_b0, o_nif_i_b1, o_nif_i_b2, o_nif_i_b3, o_nif_i_b4, o_nif_i_b5, o_nif_i_b6,
o_nif_o_b0, o_nif_o_b1, o_nif_o_b2, o_nif_o_b3, o_nif_o_b4, o_nif_o_b5, o_nif_o_b6,
o_addr_b1,  o_addr_b2, o_addr_b3, o_addr_b4, o_addr_b5,
o_iopc_b1,  o_iopc_b2, o_iopc_b3, o_iopc_b4, o_iopc_b5,
o_iext_b1,  o_iext_b2, o_iext_b3, o_iext_b4, o_iext_b5,
o_chdr_b0, 
o_cra_b1,   o_cra_b2,  o_cra_b3,  o_cra_b4,  o_cra_b5, 
o_crb_b1,   o_crb_b2,  o_crb_b3,  o_crb_b4,  o_crb_b5, 
o_icfa_b0,
o_ilck_b0, 
o_wb0_hdr, 
o_wb0_L_b1, o_wb0_L_b2, o_wb0_L_b3, o_wb0_L_b4, o_wb0_L_b5,
o_wb0_H_b1, o_wb0_H_b2, o_wb0_H_b3, o_wb0_H_b4, o_wb0_H_b5,
o_wb1_hdr, 
o_wb1_L_b1, o_wb1_L_b2, o_wb1_L_b3, o_wb1_L_b4, o_wb1_L_b5,
o_wb1_H_b1, o_wb1_H_b2, o_wb1_H_b3, o_wb1_H_b4, o_wb1_H_b5,
o_ihdr_b0, 
o_header
}                                                                                =     buff_out;        
//==============================================================================================
// output
//==============================================================================================
reg      [8:0]  r_header_b0;    
reg      [8:0]  r_header_b1;    
reg      [8:0]  r_header_t0;    
reg      [8:0]  r_header_t1;    
reg      [8:0]  r_header_t2;    
reg      [8:0]  r_header_t3;    
//----------------------
reg      [8:0]  r_ihdr_b0;  
//----------------------
reg      [8:0]  r_addr_b1;  
reg      [8:0]  r_addr_b2;  
reg      [8:0]  r_addr_b3;  
reg      [8:0]  r_addr_b4;  
reg      [8:0]  r_addr_b5;  
//----------------------
reg      [8:0]  r_iopc_b1;  
reg      [8:0]  r_iopc_b2;  
reg      [8:0]  r_iopc_b3;  
reg      [8:0]  r_iopc_b4;  
reg      [8:0]  r_iopc_b5;  
//----------------------
reg      [8:0]  r_iext_b1;  
reg      [8:0]  r_iext_b2;  
reg      [8:0]  r_iext_b3;  
reg      [8:0]  r_iext_b4;  
reg      [8:0]  r_iext_b5;  
//-----------------------
reg      [8:0]  r_icfa_b0;  
//-----------------------
reg      [8:0]  r_ilck_b0;  
//----------------------
reg      [8:0]  r_chdr_b0;  
//----------------------
reg      [8:0]  r_cra_b1;   
reg      [8:0]  r_cra_b2;   
reg      [8:0]  r_cra_b3;   
reg      [8:0]  r_cra_b4;   
reg      [8:0]  r_cra_b5;   
//----------------------
reg      [8:0]  r_crb_b1;   
reg      [8:0]  r_crb_b2;   
reg      [8:0]  r_crb_b3;   
reg      [8:0]  r_crb_b4;   
reg      [8:0]  r_crb_b5;
//----------------------
reg      [8:0]  r_wb0_hdr;
reg      [8:0]  r_wb0_L_b1;
reg      [8:0]  r_wb0_L_b2;
reg      [8:0]  r_wb0_L_b3;
reg      [8:0]  r_wb0_L_b4;
reg      [8:0]  r_wb0_L_b5;
reg      [8:0]  r_wb0_H_b1;
reg      [8:0]  r_wb0_H_b2;
reg      [8:0]  r_wb0_H_b3;
reg      [8:0]  r_wb0_H_b4;
reg      [8:0]  r_wb0_H_b5;
//----------------------
reg      [8:0]  r_wb1_hdr;
reg      [8:0]  r_wb1_L_b1;
reg      [8:0]  r_wb1_L_b2;
reg      [8:0]  r_wb1_L_b3;
reg      [8:0]  r_wb1_L_b4;
reg      [8:0]  r_wb1_L_b5;
reg      [8:0]  r_wb1_H_b1;
reg      [8:0]  r_wb1_H_b2;
reg      [8:0]  r_wb1_H_b3;
reg      [8:0]  r_wb1_H_b4;
reg      [8:0]  r_wb1_H_b5; 
//----------------------
reg      [8:0]  r_nif_hdr;
//----------------------
reg      [8:0]  r_nif_i_b0;
reg      [8:0]  r_nif_i_b1;
reg      [8:0]  r_nif_i_b2;
reg      [8:0]  r_nif_i_b3;
reg      [8:0]  r_nif_i_b4;
reg      [8:0]  r_nif_i_b5;
reg      [8:0]  r_nif_i_b6;
//----------------------
reg      [8:0]  r_nif_o_b0;
reg      [8:0]  r_nif_o_b1;
reg      [8:0]  r_nif_o_b2;
reg      [8:0]  r_nif_o_b3;
reg      [8:0]  r_nif_o_b4;
reg      [8:0]  r_nif_o_b5;
reg      [8:0]  r_nif_o_b6; 
//==============================================================================================
reg      [7:0]  r_state;
reg      [8:0]  r_buff;
//----------------------------------------------------------------------------------------------
wire                        f_stb           =                                          buff_stb;
wire                        f_hdr_end       =                                   !r_header_b0[8]; 
                                                                    
wire                        f_ins_ena       =                                      r_ihdr_b0[8];
wire                        f_ins_end       =                                     !r_ihdr_b0[8];

wire                        f_nif_ena       =                                      r_nif_hdr[8];
wire                        f_nif_end       =                                     !r_nif_hdr[8];

wire                        f_crx_ena       =                                      r_chdr_b0[8];
wire                        f_crx_end       =                                     !r_chdr_b0[8];
                                                                                                                                                                    
wire                        f_wb0_ena       =                                      r_wb0_hdr[8];
wire                        f_wb0_end       =                                     !r_wb0_hdr[8];

wire                        f_wb1_ena       =                                      r_wb1_hdr[8];
wire                        f_wb1_end       =                                     !r_wb1_hdr[8];
wire                        f_rdy           =                                            io_rdy;
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                    r_state <=   0;
 else case(r_state) 
 0:         if(f_stb)       r_state <=  10;
//.....................................
 10:                        r_state <=  20;   // load trace vector
//.....................................
 20:        if(!f_hdr_end)  r_state <=  20;  
     else   if( f_ins_ena)  r_state <=  30;
     else   if( f_nif_ena)  r_state <=  35;
     else   if( f_crx_ena)  r_state <=  40;
     else   if( f_wb0_ena)  r_state <=  50;
     else   if( f_wb1_ena)  r_state <=  60;
     else                   r_state <=  90;       
//.....................................
 30:        if(!f_ins_end)  r_state <=  30; 
     else   if( f_nif_ena)  r_state <=  35;
     else   if( f_crx_ena)  r_state <=  40;
     else   if( f_wb0_ena)  r_state <=  50;
     else   if( f_wb1_ena)  r_state <=  60;
     else                   r_state <=  90;
//.....................................
 35:        if(!f_nif_end)  r_state <=  35;
     else   if( f_crx_ena)  r_state <=  40;
     else   if( f_wb0_ena)  r_state <=  50;
     else   if( f_wb1_ena)  r_state <=  60;
     else                   r_state <=  90;
//.....................................
 40:        if(!f_crx_end)  r_state <=  40;
     else   if( f_wb0_ena)  r_state <=  50;
     else   if( f_wb1_ena)  r_state <=  60;
     else                   r_state <=  90;
//.....................................   
 50:        if(!f_wb0_end)  r_state <=  50;
     else   if( f_wb1_ena)  r_state <=  60;
     else                   r_state <=  90;
//.....................................   
 60:        if(!f_wb1_end)  r_state <=  60; 
     else                   r_state <=  90;
//.....................................    
 90:        if(f_rdy)       r_state <=   0;
//.....................................    
 endcase
//==============================================================================================
wire                        r_lde           =                                     r_state == 10;
wire                        r_she_hdr       =                                     r_state == 20;  
wire                        r_she_ins       =                                     r_state == 30;
wire                        r_she_nif       =                                     r_state == 35;
wire                        r_she_crx       =                                     r_state == 40;
wire                        r_she_wb0       =                                     r_state == 50;
wire                        r_she_wb1       =                                     r_state == 60;
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                    r_buff          <=                                              'd0;    
 else if(r_she_hdr)         r_buff          <=                                      r_header_b0; 
 else if(r_she_ins)         r_buff          <=                                        r_ihdr_b0;
 else if(r_she_nif)         r_buff          <=                                        r_nif_hdr;
 else if(r_she_crx)         r_buff          <=                                        r_chdr_b0;  
 else if(r_she_wb0)         r_buff          <=                                        r_wb0_hdr;  
 else if(r_she_wb1)         r_buff          <=                                        r_wb1_hdr;  
 else                       r_buff          <=                                              'd0;    
//----------------------------------------------------------------------------------------------
assign                      rd_ena          =                                             r_lde;
assign                      io_input        =                                       r_buff[7:0];
assign                      io_wen          =                                         r_buff[8];
//==============================================================================================
// header
//============================================================================================== 
wire    f_ovx           =                                     o_dbg_cnt_ovf                    ;
wire    f_t0            =                                    !o_dbg_cnt_ovf                    ;
wire    f_t1            =                                    !o_dbg_cnt_ovf & |o_dbg_cnt[22: 6];
wire    f_t2            =                                    !o_dbg_cnt_ovf & |o_dbg_cnt[22:12];
wire    f_t3            =                                    !o_dbg_cnt_ovf & |o_dbg_cnt[22:18];
//----------------------------------------------------------------------------------------------
always@(posedge clk)
 if(r_lde)
    begin
        r_header_b0     <=                                {1'b1,            2'b10,CORE_ID[5:0]};    
        r_header_b1     <=                                {1'b1, 2'b0, f_ovx,    o_header[4:0]};    
        r_header_t0     <=                                {f_t0, 1'b0,  f_t1, o_dbg_cnt[ 5: 0]};
        r_header_t1     <=                                {f_t1, 1'b0,  f_t2, o_dbg_cnt[11: 6]};
        r_header_t2     <=                                {f_t2, 1'b0,  f_t3, o_dbg_cnt[17:12]};
        r_header_t3     <=                                {f_t3, 1'b0,  1'b0, o_dbg_cnt[23:18]};
    end
 else if(r_she_hdr)
    begin
        r_header_b0     <=                                                          r_header_b1;    
        r_header_b1     <=                                                          r_header_t0;    
        r_header_t0     <=                                                          r_header_t1;    
        r_header_t1     <=                                                          r_header_t2;    
        r_header_t2     <=                                                          r_header_t3;    
        r_header_t3     <=                                                                 9'd0;    
    end
//==============================================================================================
// instruction
//==============================================================================================
always@(posedge clk)
 if(r_lde)
    begin   
        r_ihdr_b0       <=  {o_header[4]               ,o_ihdr_b0};
        
        r_addr_b1       <=  {o_header[4]               ,o_addr_b1};
        r_addr_b2       <=  {o_header[4]               ,o_addr_b2};
        r_addr_b3       <=  {o_header[4]               ,o_addr_b3};
        r_addr_b4       <=  {o_header[4]               ,o_addr_b4};
        r_addr_b5       <=  {o_header[4]               ,o_addr_b5};
        
        r_iopc_b1       <=  {o_header[4]               ,o_iopc_b1};
        r_iopc_b2       <=  {o_header[4]               ,o_iopc_b2};
        r_iopc_b3       <=  {o_header[4]               ,o_iopc_b3};
        r_iopc_b4       <=  {o_header[4]               ,o_iopc_b4};
        r_iopc_b5       <=  {o_header[4]               ,o_iopc_b5};

        r_iext_b1       <=  {o_header[4] & o_ihdr_b0[5],o_iext_b1};
        r_iext_b2       <=  {o_header[4] & o_ihdr_b0[5],o_iext_b2};
        r_iext_b3       <=  {o_header[4] & o_ihdr_b0[5],o_iext_b3};
        r_iext_b4       <=  {o_header[4] & o_ihdr_b0[5],o_iext_b4};
        r_iext_b5       <=  {o_header[4] & o_ihdr_b0[5],o_iext_b5};
        
        r_icfa_b0       <=  {o_header[4] & o_ihdr_b0[4],o_icfa_b0};
        r_ilck_b0       <=  {o_header[4] & o_ihdr_b0[2],o_ilck_b0};
    end
 else if(r_she_ins)
    begin   
        r_ihdr_b0       <=                               r_addr_b1; 

        r_addr_b1       <=                               r_addr_b2;
        r_addr_b2       <=                               r_addr_b3;
        r_addr_b3       <=                               r_addr_b4;
        r_addr_b4       <=                               r_addr_b5;
        r_addr_b5       <=                               r_iopc_b1;

        r_iopc_b1       <=                               r_iopc_b2;
        r_iopc_b2       <=                               r_iopc_b3;
        r_iopc_b3       <=                               r_iopc_b4;
        r_iopc_b4       <=                               r_iopc_b5;
        r_iopc_b5       <=( r_iext_b1[8]) ?              r_iext_b1:
                          ( r_icfa_b0[8]) ?              r_icfa_b0:
                                                         r_ilck_b0;
                                            
        r_iext_b1       <=                                  r_iext_b2;
        r_iext_b2       <=                                  r_iext_b3;
        r_iext_b3       <=                                  r_iext_b4;
        r_iext_b4       <=                                  r_iext_b5;
        r_iext_b5       <=( r_iext_b1[8] && r_icfa_b0[8]) ? r_icfa_b0:
                          ( r_iext_b1[8] && r_ilck_b0[8]) ? r_ilck_b0:
                                                                 9'd0; 
        
        r_icfa_b0       <=( r_icfa_b0[8]) ?                 r_ilck_b0:
                                                                 9'd0;
        
        r_ilck_b0       <=                                    9'd0;
    end            
//==============================================================================================
// network interface
//==============================================================================================
always@(posedge clk)
if(r_lde)
    begin   
        r_nif_hdr     <=                                               {o_header[3],o_nif_hdr };                   
        r_nif_i_b0      <=                             {o_nif_hdr[3] && o_header[3],o_nif_i_b0};
        r_nif_i_b1      <=                             {o_nif_hdr[3] && o_header[3],o_nif_i_b1};
        r_nif_i_b2      <=                             {o_nif_hdr[3] && o_header[3],o_nif_i_b2};
        r_nif_i_b3      <=                             {o_nif_hdr[3] && o_header[3],o_nif_i_b3};
        r_nif_i_b4      <=                             {o_nif_hdr[3] && o_header[3],o_nif_i_b4};
        r_nif_i_b5      <=                             {o_nif_hdr[3] && o_header[3],o_nif_i_b5}; 
        r_nif_i_b6      <=                             {o_nif_hdr[3] && o_header[3],o_nif_i_b6};
        r_nif_o_b0      <=                             {o_nif_hdr[1] && o_header[3],o_nif_o_b0};
        r_nif_o_b1      <=                             {o_nif_hdr[1] && o_header[3],o_nif_o_b1};
        r_nif_o_b2      <=                             {o_nif_hdr[1] && o_header[3],o_nif_o_b2};
        r_nif_o_b3      <=                             {o_nif_hdr[1] && o_header[3],o_nif_o_b3};
        r_nif_o_b4      <=                             {o_nif_hdr[1] && o_header[3],o_nif_o_b4};
        r_nif_o_b5      <=                             {o_nif_hdr[1] && o_header[3],o_nif_o_b5};
        r_nif_o_b6      <=                             {o_nif_hdr[1] && o_header[3],o_nif_o_b6};
    end                                                                       
 else if(r_she_nif)
    begin   
        r_nif_hdr     <= (!r_nif_i_b0[8]) ?                                  r_nif_o_b0 : r_nif_i_b0;
        r_nif_i_b0      <=                                                           r_nif_i_b1;
        r_nif_i_b1      <=                                                           r_nif_i_b2;
        r_nif_i_b2      <=                                                           r_nif_i_b3;
        r_nif_i_b3      <=                                                           r_nif_i_b4;
        r_nif_i_b4      <=                                                           r_nif_i_b5;
        r_nif_i_b5      <=                                                           r_nif_i_b6;
        r_nif_i_b6      <= ( r_nif_i_b0[8] && r_nif_o_b0[8]) ?                 r_nif_o_b0 :     'd0;
        r_nif_o_b0      <=                                                           r_nif_o_b1;
        r_nif_o_b1      <=                                                           r_nif_o_b2;
        r_nif_o_b2      <=                                                           r_nif_o_b3;
        r_nif_o_b3      <=                                                           r_nif_o_b4;
        r_nif_o_b4      <=                                                           r_nif_o_b5;
        r_nif_o_b5      <=                                                           r_nif_o_b6;
        r_nif_o_b6      <=                                                                  'd0;
    end 
//==============================================================================================
// cr regs
//==============================================================================================
always@(posedge clk)
 if(r_lde)
    begin   
        r_chdr_b0       <=  {o_header[2]                  ,1'b0,o_chdr_b0[7],|o_chdr_b0[6:5],o_chdr_b0[4:0]};
        
        r_cra_b1        <=  {o_header[2]&o_chdr_b0[7]     ,o_cra_b1};
        r_cra_b2        <=  {o_header[2]&o_chdr_b0[7]     ,o_cra_b2};
        r_cra_b3        <=  {o_header[2]&o_chdr_b0[7]     ,o_cra_b3};
        r_cra_b4        <=  {o_header[2]&o_chdr_b0[7]     ,o_cra_b4};
        r_cra_b5        <=  {o_header[2]&o_chdr_b0[7]     ,o_cra_b5};
        
        r_crb_b1        <=  {o_header[2]&(|o_chdr_b0[6:5]),o_crb_b1};
        r_crb_b2        <=  {o_header[2]&(|o_chdr_b0[6:5]),o_crb_b2};
        r_crb_b3        <=  {o_header[2]&(|o_chdr_b0[6:5]),o_crb_b3};
        r_crb_b4        <=  {o_header[2]&(|o_chdr_b0[6:5]),o_crb_b4};
        r_crb_b5        <=  {o_header[2]&(|o_chdr_b0[6:5]),o_crb_b5};
    end
 else if(r_she_crx)
    begin   
        r_chdr_b0       <= (r_cra_b1[8])?                r_cra_b1:
                                                         r_crb_b1;

        r_cra_b1        <=                               r_cra_b2;
        r_cra_b2        <=                               r_cra_b3;
        r_cra_b3        <=                               r_cra_b4;
        r_cra_b4        <=                               r_cra_b5;
        r_cra_b5        <= (r_cra_b1[8])?                r_crb_b1 : 9'd0;

        r_crb_b1        <=                               r_crb_b2;
        r_crb_b2        <=                               r_crb_b3;
        r_crb_b3        <=                               r_crb_b4;
        r_crb_b4        <=                               r_crb_b5;
        r_crb_b5        <=                                   9'd0; 
    end
//==============================================================================================
// write back 0
//==============================================================================================
always@(posedge clk)
if(r_lde)
    begin   
        r_wb0_hdr       <=                                             {o_header[1],o_wb0_hdr };                   
        r_wb0_L_b1      <=                             {o_wb0_hdr[6] && o_header[1],o_wb0_L_b1};
        r_wb0_L_b2      <=                             {o_wb0_hdr[6] && o_header[1],o_wb0_L_b2};
        r_wb0_L_b3      <=                             {o_wb0_hdr[6] && o_header[1],o_wb0_L_b3};
        r_wb0_L_b4      <=                             {o_wb0_hdr[6] && o_header[1],o_wb0_L_b4};
        r_wb0_L_b5      <=                             {o_wb0_hdr[6] && o_header[1],o_wb0_L_b5};
        r_wb0_H_b1      <=                             {o_wb0_hdr[5] && o_header[1],o_wb0_H_b1};
        r_wb0_H_b2      <=                             {o_wb0_hdr[5] && o_header[1],o_wb0_H_b2};
        r_wb0_H_b3      <=                             {o_wb0_hdr[5] && o_header[1],o_wb0_H_b3};
        r_wb0_H_b4      <=                             {o_wb0_hdr[5] && o_header[1],o_wb0_H_b4};
        r_wb0_H_b5      <=                             {o_wb0_hdr[5] && o_header[1],o_wb0_H_b5};
    end                                                                       
 else if(r_she_wb0)
    begin   
        r_wb0_hdr       <= (!r_wb0_L_b1[8]) ?                           r_wb0_H_b1 : r_wb0_L_b1;
        r_wb0_L_b1      <=                                                           r_wb0_L_b2;
        r_wb0_L_b2      <=                                                           r_wb0_L_b3;
        r_wb0_L_b3      <=                                                           r_wb0_L_b4;
        r_wb0_L_b4      <=                                                           r_wb0_L_b5;
        r_wb0_L_b5      <= ( r_wb0_H_b1[8] && r_wb0_L_b1[8]) ?          r_wb0_H_b1 :        'd0;
        r_wb0_H_b1      <=                                                           r_wb0_H_b2;
        r_wb0_H_b2      <=                                                           r_wb0_H_b3;
        r_wb0_H_b3      <=                                                           r_wb0_H_b4;
        r_wb0_H_b4      <=                                                           r_wb0_H_b5;
        r_wb0_H_b5      <=                                                                  'd0;
    end 
//==============================================================================================
// write back 1
//==============================================================================================
always@(posedge clk)
 if(r_lde)
    begin   
        r_wb1_hdr       <=                                             {o_header[0],o_wb1_hdr };                   
        r_wb1_L_b1      <=                             {o_wb1_hdr[6] && o_header[0],o_wb1_L_b1};
        r_wb1_L_b2      <=                             {o_wb1_hdr[6] && o_header[0],o_wb1_L_b2};
        r_wb1_L_b3      <=                             {o_wb1_hdr[6] && o_header[0],o_wb1_L_b3};
        r_wb1_L_b4      <=                             {o_wb1_hdr[6] && o_header[0],o_wb1_L_b4};
        r_wb1_L_b5      <=                             {o_wb1_hdr[6] && o_header[0],o_wb1_L_b5};
        r_wb1_H_b1      <=                             {o_wb1_hdr[5] && o_header[0],o_wb1_H_b1};
        r_wb1_H_b2      <=                             {o_wb1_hdr[5] && o_header[0],o_wb1_H_b2};
        r_wb1_H_b3      <=                             {o_wb1_hdr[5] && o_header[0],o_wb1_H_b3};
        r_wb1_H_b4      <=                             {o_wb1_hdr[5] && o_header[0],o_wb1_H_b4};
        r_wb1_H_b5      <=                             {o_wb1_hdr[5] && o_header[0],o_wb1_H_b5};
    end                                                                       
 else if(r_she_wb1)
    begin   
        r_wb1_hdr       <= (!r_wb1_L_b1[8]) ?                           r_wb1_H_b1 : r_wb1_L_b1;
        r_wb1_L_b1      <=                                                           r_wb1_L_b2;
        r_wb1_L_b2      <=                                                           r_wb1_L_b3;
        r_wb1_L_b3      <=                                                           r_wb1_L_b4;
        r_wb1_L_b4      <=                                                           r_wb1_L_b5;
        r_wb1_L_b5      <= ( r_wb1_H_b1[8] && r_wb1_L_b1[8]) ?          r_wb1_H_b1 :        'd0;
        r_wb1_H_b1      <=                                                           r_wb1_H_b2;
        r_wb1_H_b2      <=                                                           r_wb1_H_b3;
        r_wb1_H_b3      <=                                                           r_wb1_H_b4;
        r_wb1_H_b4      <=                                                           r_wb1_H_b5;
        r_wb1_H_b5      <=                                                                  'd0;
    end 
//----------------------------------------------------------------------------------------------
//always@(posedge clk or posedge rst)
// if(rst)
//  begin   
//      r_wb0_H_hdr     <=                                                                  'd0;
//  end
// else if(r_lde)
//  begin   
//      r_wb0_H_hdr     <=                                                                       
//        
// else if(r_she_wb0_h)
//    begin 
//      r_wb0_H_hdr     <=                                                          r_wb0_L_hdr;
//        
//      r_wb0_H_b1      <=                                                           r_wb0_L_b2;
//      r_wb0_H_b2      <=                                                           r_wb0_L_b3;
//      r_wb0_H_b3      <=                                                           r_wb0_L_b4;
//      r_wb0_H_b4      <=                                                           r_wb0_L_b5;
//      r_wb0_H_b5      <=                                                                  'd0;
//  end 
//==============================================================================================
// output buffer
//==============================================================================================
always@(posedge clk)
 if(io_wen)           io_buff [io_wptr] <=                                             io_input;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        io_wptr <=                                                10'd0;
 else if(io_wen)                io_wptr <=                                      io_wptr + 10'd1;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        io_rptr <=                                                10'd0;
 else if(io_ren)                io_rptr <=                                      io_rptr + 10'd1;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        io_cnt  <=                                                - 'd1;
 else if(!io_ren &&  io_wen)    io_cnt  <=                                         io_cnt + 'd1;
 else if( io_ren && !io_wen)    io_cnt  <=                                         io_cnt - 'd1;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        io_rdy  <=                                                 1'd1;      
 else if(io_rdy == 1'b0)        io_rdy  <= io_cnt[10:6] == 'b0_0000 ?               1'b1 : 1'b0;     
 else if(io_rdy == 1'b1)        io_rdy  <= io_cnt[10:6] == 'b0_1111 ?               1'b0 : 1'b1;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        io_af   <=                                                 1'd0;      
 else if(io_af == 1'b1)         io_af   <= io_cnt[10:6] == 'b0_0000 ?               1'b0 : 1'b1;     
 else if(io_af == 1'b0)         io_af   <= io_cnt[10:6] == 'b0_1111 ?               1'b1 : 1'b0;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        io_ae   <=                                                 1'd1;      
 else                           io_ae   <=                io_cnt[10:6] == 'b0_0000 | io_cnt[10];
//----------------------------------------------------------------------------------------------
//==============================================================================================
generate
    if(CORE_ID=='d0)
        begin
    // Debug information from this module is sent.
      assign                            io_ren   =                               dbg_o_ack && dbg_o_stb; 
            assign  dbg_o_stb            =                                          !io_cnt[10];
            assign  dbg_o_data           =                                     io_buff[io_rptr];  
            assign  dbg_i_ack            =                                                 1'b0;
        end
    else
        begin
    // TODO: Debug information from this module is NOT sent. Just propagate debug from CORE0
      assign                            io_ren   =                               !io_cnt[10]; // skip debug 
            assign  dbg_o_stb            =                                            dbg_i_stb;
            assign  dbg_o_data           =                                           dbg_i_data;
            assign  dbg_i_ack            =                                            dbg_o_ack;
        end
endgenerate
//==============================================================================================
endmodule