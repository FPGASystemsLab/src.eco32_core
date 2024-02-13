//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
module eco32_core_ifu_icm_box
# // parameters
( 
 parameter                          PAGE_ADDR_WIDTH = 'd4,
 parameter                          FORCE_RST       =   0
)
// ports
(
 input  wire                        clk,
 input  wire                        rst,
 output wire                        rdy,

 input  wire                        req_stb,
 input  wire                        req_tid,       
 input  wire                [3:0]   req_asid,       
 input  wire                        req_wid,     
 input  wire                        req_tag,     
 input  wire                [31:0]  req_v_addr,    
 output wire                        req_rdy,
 
 output wire                        mm_wr_stb,
 output wire                        mm_wr_tid,
 output wire                        mm_wr_wid,
 output wire [PAGE_ADDR_WIDTH-1:0]  mm_wr_page,
 output wire                 [2:0]  mm_wr_offset,
 output wire                [71:0]  mm_wr_data, 
 
 output wire                        pt_wr_stb,
 output wire                        pt_wr_tid,
 output wire                        pt_wr_wid,
 output wire [PAGE_ADDR_WIDTH-1:0]  pt_wr_page,
 output wire                [35:0]  pt_wr_descriptor,

 input  wire                        epp_i_stb,
 input  wire                        epp_i_sof,
 input  wire                [71:0]  epp_i_data,                                       

 output wire                        epp_o_br,
 input  wire                        epp_o_bg,
 
 output wire                        epp_o_stb,
 output wire                        epp_o_sof,
 output wire                 [3:0]  epp_o_iid,
 output wire                [71:0]  epp_o_data,
 input  wire                 [1:0]  epp_o_rdy 
);                                     
//==============================================================================================
// local params
//==============================================================================================  
localparam      _AW         =                                                   PAGE_ADDR_WIDTH;
localparam      _CW         =                                           1 + 1 + PAGE_ADDR_WIDTH;
//==============================================================================================
// variables
//==============================================================================================
reg             rdy_all;
//----------------------------------------------------------------------------------------------
wire     [3:0]  req_token; 
wire            rdy_token;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b5_rdy;

(* shreg_extract = "NO"  *) reg             b5_stb;
(* shreg_extract = "NO"  *) reg             b5_tid;
(* shreg_extract = "NO"  *) reg             b5_wid;
(* shreg_extract = "NO"  *) reg             b5_tag;
(* shreg_extract = "NO"  *) reg      [3:0]  b5_asid;
(* shreg_extract = "NO"  *) reg     [31:0]  b5_v_addr;        
(* shreg_extract = "NO"  *) reg      [3:0]  b5_token;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             a6_stb;
(* shreg_extract = "NO"  *) reg             a6_tid;
(* shreg_extract = "NO"  *) reg             a6_wid;
(* shreg_extract = "NO"  *) reg             a6_tag;
(* shreg_extract = "NO"  *) reg       [3:0] a6_asid;
(* shreg_extract = "NO"  *) reg      [31:0] a6_v_addr;        
(* shreg_extract = "NO"  *) reg       [3:0] a6_token;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg      [31:0] tx_state;
(* shreg_extract = "NO"  *) reg      [71:0] tx_data;
(* shreg_extract = "NO"  *) reg             tx_req;     
(* shreg_extract = "NO"  *) reg       [3:0] tx_iid;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             mmu0_sel;
(* shreg_extract = "NO"  *) reg             mmu0_stb;
(* shreg_extract = "NO"  *) reg       [3:0] mmu0_offset;
(* shreg_extract = "NO"  *) reg       [3:0] mmu0_cnt;
(* shreg_extract = "NO"  *) reg             mmu0_tid;
(* shreg_extract = "NO"  *) reg             mmu0_wid;
(* shreg_extract = "NO"  *) reg   [_AW-1:0] mmu0_page;
(* shreg_extract = "NO"  *) reg       [3:0] mmu0_token;
(* shreg_extract = "NO"  *) reg      [63:0] mmu0_data;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             mmu1_stb;
(* shreg_extract = "NO"  *) reg       [2:0] mmu1_offset;
(* shreg_extract = "NO"  *) reg             mmu1_tid;
(* shreg_extract = "NO"  *) reg             mmu1_wid;
(* shreg_extract = "NO"  *) reg   [_AW-1:0] mmu1_page;
(* shreg_extract = "NO"  *) reg      [71:0] mmu1_data;
//----------------------------------------------------------------------------------------------
                            wire    [31:6] rd_a_v_addr;
                            wire     [3:0] rd_a_asid;
                            wire           rd_a_wid;
                            wire           rd_a_tag;
                            wire           rd_a_tid;
//----------------------------------------------------------------------------------------------
                            wire    [31:6] rd_b_v_addr;
                            wire           rd_b_wid;
                            wire           rd_b_tid;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg            ptr_lock;
(* shreg_extract = "NO"  *) reg            ptr_unlock;
(* shreg_extract = "NO"  *) reg            ptr_tfree;
(* shreg_extract = "NO"  *) reg      [3:0] ptr_token;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg            ptu0_stb;
(* shreg_extract = "NO"  *) reg            ptu0_tid;
(* shreg_extract = "NO"  *) reg      [3:0] ptu0_asid;
(* shreg_extract = "NO"  *) reg            ptu0_lock;
(* shreg_extract = "NO"  *) reg            ptu0_val;
(* shreg_extract = "NO"  *) reg            ptu0_wid;
(* shreg_extract = "NO"  *) reg            ptu0_tag;
(* shreg_extract = "NO"  *) reg  [_AW-1:0] ptu0_page;
(* shreg_extract = "NO"  *) reg     [35:6] ptu0_v_addr;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg    [_CW:0] ptu1_cnt;
(* shreg_extract = "NO"  *) reg            ptu1_stb;
(* shreg_extract = "NO"  *) reg            ptu1_tid;
(* shreg_extract = "NO"  *) reg      [3:0] ptu1_asid;
(* shreg_extract = "NO"  *) reg            ptu1_lock;
(* shreg_extract = "NO"  *) reg            ptu1_val;
(* shreg_extract = "NO"  *) reg            ptu1_wid;
(* shreg_extract = "NO"  *) reg            ptu1_tag;
(* shreg_extract = "NO"  *) reg  [_AW-1:0] ptu1_page;
(* shreg_extract = "NO"  *) reg     [35:6] ptu1_v_addr;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg      [4:0] tr_cnt;
(* shreg_extract = "NO"  *) reg            tr_stb;
(* shreg_extract = "NO"  *) reg      [3:0] tr_token;
//----------------------------------------------------------------------------------------------
                            wire           req_end;
                            wire           req_hold;
//==============================================================================================
// ready for operation
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                b5_rdy        <=                                                    'b1;
 else if(req_stb)       b5_rdy          <=                                                    'b0;  
 else if(req_end)       b5_rdy        <=                                                    'b1;
//----------------------------------------------------------------------------------------------
assign                  req_rdy          =                                    b5_rdy && !req_hold;                  
//==============================================================================================
// buffer of the tokens
//==============================================================================================
eco32_core_ifu_icm_token token_buffer
(
.clk          (clk),
.rst          (rst),   
.rdy          (rdy_token),

.rd_stb       (req_stb),
.rd_token     (req_token),
.rd_hold      (req_hold),

.wr_stb       (tr_stb),
.wr_token     (tr_token)
); 
//==============================================================================================
// stage b1
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b5_stb              <=                                                                  'b0;
    b5_tid              <=                                                                  'b0;
    b5_wid              <=                                                                  'b0;
    b5_tag              <=                                                                  'b0;
  end
 else 
  begin
    b5_stb              <=                                                              req_stb;
    b5_tid              <=                                                              req_tid;
    b5_wid              <=                                                              req_wid;
    b5_tag              <=                                                              req_tag;
  end    
//----------------------------------------------------------------------------------------------
always@(posedge clk)
  begin
    b5_v_addr           <=                                                           req_v_addr;
    b5_asid             <=                                                             req_asid;
    b5_token            <=                                                            req_token;
  end    
//==============================================================================================   
// task buffer
//==============================================================================================   
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a6_stb              <=                                                                  'b0;
    a6_tid              <=                                                                  'b0;
    a6_wid              <=                                                                  'b0;
    a6_tag              <=                                                                  'b0;
  end
 else 
  begin
    a6_stb              <=                                                               b5_stb;
    a6_tid              <=                                                               b5_tid;
    a6_wid              <=                                                               b5_wid;
    a6_tag              <=                                                               b5_tag;
  end    
//----------------------------------------------------------------------------------------------
always@(posedge clk)
  begin
    a6_v_addr           <=                                                            b5_v_addr;
    a6_asid             <=                                                              b5_asid;
    a6_token            <=                                                             b5_token;
  end    
//==============================================================================================   
// memory request
//==============================================================================================   
wire  [1:0] _RD          = /* read 8 DW       */                                          2'b01;
wire [38:3] _RADDR       = /* 39 bits addres  */                    {7'h0,a6_v_addr[31:6],3'd0};
wire  [3:0] _SID         = /* source ID       */                                        4'b1000;
wire  [3:0] _RID         = /* request ID      */                                       a6_token;
wire  [3:0] _IID         = /* internal ID     */                               {3'b000, a6_tid};
wire        _L           = /* req LEN (short) */                                           1'b0;
wire        _V           = /* virtual address */                                           1'b0;
wire  [1:0] _PP          = /* priority        */                                           2'b0;
//==============================================================================================   
wire                    tx_rdy       =                                 epp_o_bg && epp_o_rdy[0];
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                tx_state    <=                                                      'd0;
 else case(tx_state)
 0:     if(a6_stb)      tx_state    <=  /*wait        */                                    'd1;
 1:     if(tx_rdy)      tx_state    <=  /*bus request */                                    'd2;
 2:                     tx_state    <=  /*send header */                                    'd3; 
 3:                     tx_state    <=  /*send data   */                                    'd4; 
 4:                     tx_state    <=  /*free bus    */                                    'd0; 
 endcase
//----------------------------------------------------------------------------------------------
always@(posedge clk)
      if(a6_stb)        tx_data     <=          {2'b10,_PP,20'd0,_SID,_RID,  _L,_RADDR,_V, _RD};
 else if(tx_state==2)   tx_data     <=          {2'b10,_PP,20'd0,4'd0,4'd0,1'd0,_RADDR,_V,2'd0};
//----------------------------------------------------------------------------------------------    
always@(posedge clk)
      if(a6_stb)        tx_iid      <=                                                     _IID;
//----------------------------------------------------------------------------------------------              
always@(posedge clk or posedge rst)
 if(rst)                tx_req      <=                                                      'd0;
 else if(tx_state==1)   tx_req      <=                                                      'd1;
 else if(tx_state==4)   tx_req      <=                                                      'd0;
//----------------------------------------------------------------------------------------------
assign                  epp_o_br     =                                                   tx_req;
assign                  epp_o_stb    =                           (tx_state==3) || (tx_state==2);
assign                  epp_o_sof    =                                            (tx_state==2);
assign                  epp_o_iid    =                                                   tx_iid;
assign                  epp_o_data   =                                                  tx_data;
//----------------------------------------------------------------------------------------------
assign                  req_end        =                                            (tx_state==4);
//==============================================================================================   
// cache update
//==============================================================================================   
wire                    mmf_set       =                                  epp_i_sof && epp_i_stb;
wire                    mmf_clr       =                                             mmu0_cnt[3];
wire                    mmf_wre       =                                   mmu0_sel && epp_i_stb;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                mmu0_sel     <=                                                     'd0;
 else if(mmf_set)       mmu0_sel     <=                                 epp_i_data[47:44]==4'd8;
 else if(mmf_clr)       mmu0_sel     <=                                                     'd0;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                mmu0_stb     <=                                                     'd0;
 else if(mmf_set)       mmu0_stb     <=                                                     'd0;
 else if(mmf_clr)       mmu0_stb     <=                                                     'd0;
 else if(mmf_wre)       mmu0_stb     <=                                                     'd1;
 else                   mmu0_stb     <=                                                     'd0;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                mmu0_offset  <=                                                    -'d1;
 else if(mmf_set)       mmu0_offset  <=                                                    -'d1;                    
 else if(mmf_clr)       mmu0_offset  <=                                                    -'d1;
 else if(mmf_wre)       mmu0_offset  <=                                           mmu0_offset+1;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                mmu0_cnt     <=                                                     'd0; 
 else if(mmf_set)       mmu0_cnt     <=                                                     'd0;
 else if(mmf_clr)       mmu0_cnt     <=                                                     'd0;
 else if(mmf_wre)       mmu0_cnt     <=                                              mmu0_cnt+1;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                mmu0_token   <=                                                     'd0;
 else if(mmf_set)       mmu0_token   <=                                       epp_i_data[43:40];
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                mmu0_page    <=                                                     'd0;
 else if(mmf_set)       mmu0_page    <=                       epp_i_data[PAGE_ADDR_WIDTH-1+6:6];
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                mmu0_tid     <=                                                     'd0;
 else if(mmf_set)       mmu0_tid     <=                                                     'd0;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                mmu0_wid     <=                                                     'd0;
 else if(mmf_set)       mmu0_wid     <=                                                     'd0;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                mmu0_data    <=                                                     'd0;
 else                   mmu0_data    <=                                        epp_i_data[63:0];
//==============================================================================================   
wire  [5:0]             f_mopc        =                                        mmu0_data[63:58];
wire                    f_ext3A       =                                            f_mopc=='h3A; 
wire                    f_ext3B       =                                            f_mopc=='h3B; 
wire                    f_ext         =                                      f_ext3A || f_ext3B; 
//==============================================================================================   
always@(posedge clk or posedge rst)
 if(rst)                mmu1_stb     <=                                                     'd0;
 else                   mmu1_stb     <=                                                mmu0_stb;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    mmu1_offset <=                                                  'd0;
 else                       mmu1_offset <=                                          mmu0_offset;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    mmu1_page   <=                                                  'd0;
 else                       mmu1_page   <=                   rd_b_v_addr[PAGE_ADDR_WIDTH-1+6:6];
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    mmu1_tid    <=                                                  'd0;
 else                       mmu1_tid    <=                                             rd_b_tid;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    mmu1_wid    <=                                                  'd0;
 else                       mmu1_wid    <=                                             rd_b_wid;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    mmu1_data   <=                                                  'd0;
 else                       mmu1_data   <=               {5'd0,f_ext,f_ext3B,f_ext3A,mmu0_data};
//==============================================================================================   
assign                      mm_wr_stb    =                                             mmu1_stb;    
assign                      mm_wr_tid    =                                             mmu1_tid;    
assign                      mm_wr_wid    =                                             mmu1_wid;
assign                      mm_wr_page   =                                            mmu1_page;
assign                      mm_wr_offset =                                          mmu1_offset; 
assign                      mm_wr_data   =                                            mmu1_data;  
//==============================================================================================   
// page table update  
//==============================================================================================   
always@(posedge clk or posedge rst)
 if(rst)                    ptr_lock    <=                                                  'd0;
 else if(a6_stb)            ptr_lock    <=                                                  'd1;
 else                       ptr_lock    <=                                                  'd0;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptr_unlock  <=                                                  'd0;
 else if(a6_stb)            ptr_unlock  <=                                                  'd0;
 else if(mmu0_sel)          ptr_unlock  <=                 (mmu0_offset==6) || (mmu0_offset==7);
 else                       ptr_unlock  <=                                                  'd0;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptr_tfree   <=                                                  'd0;
 else if(a6_stb)            ptr_tfree   <=                                                  'd0;
 else if(mmu0_sel)          ptr_tfree   <=                                     (mmu0_offset==7);
 else                       ptr_tfree   <=                                                  'd0;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptr_token   <=                                                  'd0;
 else if(a6_stb)            ptr_token   <=                                             a6_token;
 else if(mmu0_sel)          ptr_token   <=                                           mmu0_token;
 else                       ptr_token   <=                                                  'd0;     
//==============================================================================================   
// request address buffer
//==============================================================================================   
eco32_core_ifu_icm_tab tab
(
.clk              (clk),

.wr_stb           (b5_stb),
.wr_ptr           (b5_token),
.wr_v_addr        (b5_v_addr[31:6]),
.wr_asid          (b5_asid),
.wr_wid           (b5_wid),
.wr_tid           (b5_tid),
.wr_tag           (b5_tag),

.rd_a_ptr         (ptr_token),
.rd_a_v_addr      (rd_a_v_addr),
.rd_a_asid        (rd_a_asid),
.rd_a_wid         (rd_a_wid),
.rd_a_tid         (rd_a_tid),
.rd_a_tag         (rd_a_tag),

.rd_b_ptr         (mmu0_token),
.rd_b_v_addr      (rd_b_v_addr),
.rd_b_wid         (rd_b_wid),
.rd_b_tid         (rd_b_tid)
);     
//==============================================================================================   
// page table update
//==============================================================================================   
wire                        ptf_lock     =                                             ptr_lock;
wire                        ptf_unlock   =                                           ptr_unlock;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu0_stb    <=                                                  'd0;
 else if(ptf_lock)          ptu0_stb    <=                                                  'd1;
 else if(ptf_unlock)        ptu0_stb    <=                                                  'd1;
 else                       ptu0_stb    <=                                                  'd0;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu0_tid    <=                                                  'd0;
 else if(ptf_lock)          ptu0_tid    <=                                             rd_a_tid;
 else if(ptf_unlock)        ptu0_tid    <=                                             rd_a_tid;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu0_asid   <=                                                  'd0;
 else if(ptf_lock)          ptu0_asid   <=                                            rd_a_asid;
 else if(ptf_unlock)        ptu0_asid   <=                                            rd_a_asid;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu0_val    <=                                                  'd0;
 else if(ptf_lock)          ptu0_val    <=                                                  'd0;
 else if(ptf_unlock)        ptu0_val    <=                                                  'd1;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu0_lock   <=                                                  'd0;
 else if(ptf_lock)          ptu0_lock   <=                                                  'd1;
 else if(ptf_unlock)        ptu0_lock   <=                                                  'd0;                
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu0_wid    <=                                                  'd0;
 else if(ptf_lock)          ptu0_wid    <=                                             rd_a_wid;
 else if(ptf_unlock)        ptu0_wid    <=                                             rd_a_wid;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu0_tag    <=                                                  'd0;
 else if(ptf_lock)          ptu0_tag    <=                                             rd_a_tag;
 else if(ptf_unlock)        ptu0_tag    <=                                             rd_a_tag;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu0_page   <=                                                  'd0;
 else if(ptf_lock)          ptu0_page   <=                   rd_a_v_addr[PAGE_ADDR_WIDTH-1+6:6];
 else if(ptf_unlock)        ptu0_page   <=                   rd_a_v_addr[PAGE_ADDR_WIDTH-1+6:6];
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu0_v_addr <=                                                  'd0;
 else if(ptf_lock)          ptu0_v_addr <=                                   {4'd0,rd_a_v_addr};
 else if(ptf_unlock)        ptu0_v_addr <=                                   {4'd0,rd_a_v_addr};
//==============================================================================================   
wire                        ptf_set      =                                       !ptu1_cnt[_CW];
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu1_cnt    <=                                                  'd0;
 else if(ptf_set)           ptu1_cnt    <=                                           ptu1_cnt+1;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu1_stb    <=                                                  'd0;
 else if(ptf_set)           ptu1_stb    <=                                                  'd1;
 else                       ptu1_stb    <=                                             ptu0_stb;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu1_tid    <=                                                  'd0;
 else if(ptf_set)           ptu1_tid    <=                                      ptu1_cnt[_CW-1];
 else                       ptu1_tid    <=                                             ptu0_tid;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu1_asid   <=                                                  'd0;
 else if(ptf_set)           ptu1_asid   <=                                                  'd0;
 else                       ptu1_asid   <=                                            ptu0_asid;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu1_val    <=                                                  'd0;
 else if(ptf_set)           ptu1_val    <=                                                  'd0;
 else                       ptu1_val    <=                                             ptu0_val;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu1_lock   <=                                                  'd0;
 else if(ptf_set)           ptu1_lock   <=                                                  'd0;
 else                       ptu1_lock   <=                                            ptu0_lock;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu1_wid    <=                                                  'd0;
 else if(ptf_set)           ptu1_wid    <=                                      ptu1_cnt[_CW-2];
 else                       ptu1_wid    <=                                             ptu0_wid;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu1_tag    <=                                                  'd0;
 else if(ptf_set)           ptu1_tag    <=                                                  'd0;
 else                       ptu1_tag    <=                                             ptu0_tag;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu1_page   <=                                                  'd0;
 else if(ptf_set)           ptu1_page   <=                                    ptu1_cnt[_CW-3:0];
 else                       ptu1_page   <=                                            ptu0_page;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    ptu1_v_addr <=                                                  'd0;
 else if(ptf_set)           ptu1_v_addr <=                                                36'd0;
 else                       ptu1_v_addr <=                                          ptu0_v_addr;
//==============================================================================================   
wire      [1:0]             _PID         =                                 {2{ptu1_v_addr[31]}};
wire      [3:0]             _ASID        =                                            ptu1_asid;
wire    [35:11]             _V_ADDR      =                                   ptu1_v_addr[35:11];
wire      [2:0]             _AV          =                            {{2{ptu1_val}},ptu1_lock};
wire      [7:0]             _AR          =                         {ptu1_tag,1'b0,_PID,4'b1110};
//----------------------------------------------------------------------------------------------
assign                      pt_wr_stb           =                                      ptu1_stb;       
assign                      pt_wr_tid           =                                      ptu1_tid;       
assign                      pt_wr_wid           =                                      ptu1_wid;      
assign                      pt_wr_page          =                                     ptu1_page;
assign                      pt_wr_descriptor    =                       {_ASID,_V_ADDR,_AV,_AR};
//==============================================================================================   
// token return
//==============================================================================================   
wire                        tr_set      =                                            !tr_cnt[4];   
wire                        tr_ret      =                                             ptr_tfree;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    tr_cnt     <=                                                   'd0;
 else if(tr_set)            tr_cnt     <=                                              tr_cnt+1;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    tr_stb     <=                                                   'd0;
 else if(tr_set)            tr_stb     <=                                                   'd1;                                 
 else if(tr_ret)            tr_stb     <=                                                   'd1;
 else                       tr_stb     <=                                                   'd0;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    tr_token   <=                                                   'd0;
 else if(tr_set)            tr_token   <=                                           tr_cnt[3:0];
 else if(tr_ret)            tr_token   <=                                             ptr_token;
//==============================================================================================  
// module ready signal
//==============================================================================================  
always@(posedge clk or posedge rst)
 if(rst)                    rdy_all    <=                                                   'd0;
 else                       rdy_all    <=                                   !ptf_set && !tr_set;
//----------------------------------------------------------------------------------------------
assign                      rdy         =                                               rdy_all;
//==============================================================================================  
endmodule