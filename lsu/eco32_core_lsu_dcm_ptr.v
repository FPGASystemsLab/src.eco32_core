//=============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================================
`default_nettype none
//---------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================================
module eco32_core_lsu_dcm_ptr
# // parameters
( 
 parameter        PAGE_ADDR_WIDTH = 'd5
)
// ports
(
input   wire                        clk,
input   wire                        rst,   
output  wire                        rdy,

input   wire                        i_stb,
input   wire                        i_tid,       
input   wire                        i_wid,     
input   wire                        i_tag,     
input   wire                        i_dirty,
input   wire                  [8:0] i_mode,
input   wire  [PAGE_ADDR_WIDTH-1:0] i_page,
input   wire                        i_k_ena,
input   wire                        i_k_force,
input   wire                  [1:0] i_k_op,
input   wire                        i_k_sh,
input   wire                 [31:0] i_r_addr,    
input   wire                 [31:0] i_p_addr,    
input   wire                 [31:0] i_k_addr,    
output  wire                        i_ack,

output  wire                        tx_stb,
output  wire                        tx_clr,
output  wire                        tx_tid,
output  wire                        tx_wid,
output  wire  [PAGE_ADDR_WIDTH-1:0] tx_page,
input   wire                        tx_ack,

input   wire                        mmr_stb,
input   wire                  [7:0] mmr_ben,
input   wire                 [63:0] mmr_data,   

output  wire                        req_stb,
output  wire                        req_end,
output  wire                  [3:0] req_rid,     
output  wire                        req_tid,       
output  wire                        req_wid,     
output  wire                        req_tag,
output  wire                 [31:0] req_v_addr,
output  wire  [PAGE_ADDR_WIDTH-1:0] req_page,
input   wire                        req_ack,
input   wire                        req_rdy,

input   wire                        ack_stb,
input   wire                        ack_tid,
input   wire                  [3:0] ack_rid,     

output  wire                        o_br,
input   wire                        o_bg,

output  wire                        o_stb,
output  wire                        o_sof,
output  wire                  [3:0] o_iid,
output  wire                 [71:0] o_data,
input   wire                  [1:0] o_rdy,
input   wire                  [1:0] o_rdyE
);                                                                                                
//=============================================================================================
// parameters
//=============================================================================================
localparam  _PAW              =                                                PAGE_ADDR_WIDTH;
//=============================================================================================
// variables
//=============================================================================================
integer         cc_state; /* synthesis syn_encoding = "ssafe,onehot" */
//---------------------------------------------------------------------------------------------
reg      [8:0]  cc_mode;
reg             cc_tid;
reg      [3:0]  cc_rid;
reg             cc_wid;
reg             cc_tag;
reg             cc_dirty;
reg [_PAW-1:0]  cc_page;
reg     [31:0]  cc_p_addr;
reg     [31:0]  cc_r_addr;
reg             cc_k_ena;
reg             cc_k_force;
reg             cc_k_ld;
reg             cc_k_st;
reg             cc_k_short;
reg     [31:0]  cc_k_addr;
//---------------------------------------------------------------------------------------------
reg             c0_stb;
reg      [7:0]  c0_ben;
reg     [63:0]  c0_data;          
//---------------------------------------------------------------------------------------------
reg             c1_stb;
reg      [7:0]  c1_ben;
reg     [63:0]  c1_data;
reg      [3:0]  c1_cnt;
reg      [3:0]  c1_cntx;          
//---------------------------------------------------------------------------------------------
reg             buff_task_stb; 
reg             buff_task_clr;  
reg             buff_task_tid;                                                                                                                                             
reg             buff_task_wid;  
reg [_PAW-1:0]  buff_task_page; 
//---------------------------------------------------------------------------------------------
reg     [71:0]  bus0_data;  
reg             bus0_stb;
reg             bus0_rts;
reg             bus0_bof;
reg             bus0_eof;
reg       [3:0] bus0_iid;
//---------------------------------------------------------------------------------------------
reg             bus1_stb;
reg     [71:0]  bus1_data;   
reg       [3:0] bus1_iid;
reg             bus1_sof;
//---------------------------------------------------------------------------------------------
reg             bus2_stb;
reg     [71:0]  bus2_data;   
reg      [3:0]  bus2_iid;
reg             bus2_sof;
//---------------------------------------------------------------------------------------------
reg             bus3_stb;
reg     [71:0]  bus3_data;   
reg      [3:0]  bus3_iid;
reg             bus3_sof;
//---------------------------------------------------------------------------------------------
wire            rid_rdy;
//=============================================================================================
localparam CC_WAIT      = 'h00;
localparam CC_HOLD      = 'h01;
localparam CC_RID       = 'h02;
localparam CC_SETUP     = 'h03;
localparam CC_PC_WAIT   = 'h04;

localparam CC_PT_RST    = 'h10;   

localparam CC_MC_INI    = 'h20;
localparam CC_MC_DNL    = 'h21;

localparam CC_FR_WRH    = 'h30;
localparam CC_FR_WR1    = 'h31;
localparam CC_FR_WR8    = 'h32;
localparam CC_MR_INI    = 'h33;
localparam CC_FR_WRD    = 'h34;

localparam CC_FR_RDH    = 'h40;
localparam CC_FR_NUL    = 'h41;

localparam CC_UP_WRH    = 'h50;
localparam CC_UP_WR1    = 'h51;
localparam CC_UP_WR8    = 'h52;
localparam CC_UP_INI    = 'h53;
localparam CC_UP_WRD    = 'h54;
localparam CC_UP_NUL    = 'h55;

localparam CC_PT_VAL    = 'h60;
localparam CC_PT_VRS    = 'h61;
localparam CC_PT_VED    = 'h62;

localparam CC_PT_INV    = 'h70;
localparam CC_WAIT0     = 'h100;
localparam CC_WAIT1     = 'h101;
localparam CC_WAIT2     = 'h102;
localparam CC_WAIT3     = 'h103;
localparam CC_WAIT4     = 'h104;
//=============================================================================================
wire       f_req        =                                                              (i_stb);
//---------------------------------------------------------------------------------------------
wire       f_rdy        =                                         o_bg && o_rdy[1] && o_rdy[0]; // powinno sprawdza tylko wybranego RDYka i RDYEka!!!
wire       f_rdyL       =                                                     o_bg && o_rdy[1]; 
wire       f_rdyS       =                                                     o_bg && o_rdy[0]; 
//---------------------------------------------------------------------------------------------
wire       f_pc_ack     =                                                              req_ack;
//---------------------------------------------------------------------------------------------
wire       f_mr_ack     =                                                               tx_ack;
wire       f_mr_eop     =                                                           c1_cntx[3];
//---------------------------------------------------------------------------------------------
wire       f_pg_barier  =                                                           cc_mode[8];
wire       f_pg_clr     =                                                           cc_mode[7];

wire       f_pg_rst     =                                                           cc_mode[6];
wire       f_pg_st      =                                  (cc_k_ena | cc_dirty) && cc_mode[5];
wire       f_pg_ld      =                                                           cc_mode[4];
wire       f_pg_up      =                                                           cc_mode[3];

wire       f_pg_val     =                                                           cc_mode[2];
wire       f_pg_inv     =                                                           cc_mode[1];

wire       f_pg_rep     =                                                           cc_mode[0];

wire       f_rid_st     =                                      cc_state==CC_PT_VRS && !ack_stb;
//---------------------------------------------------------------------------------------------
assign     rdy          =                                                              rid_rdy;   
assign     o_br         =                                                    cc_state!=CC_WAIT;
//=============================================================================================
always@(posedge clk or posedge rst) 
 if(rst)                        cc_state   <=                                          CC_WAIT;
 else case(cc_state)  
 CC_WAIT:       if(f_req)       cc_state   <=                                          CC_HOLD;
//.......................
 CC_HOLD:       if(f_rdy)       cc_state   <=                                           CC_RID;
//.......................																				  
 CC_RID:                        cc_state   <=                                         CC_SETUP;			
//.......................
 CC_SETUP:      if(f_pg_clr)    cc_state   <=                                        CC_MC_INI; 
           else if(f_pg_rst)    cc_state   <=                                        CC_PT_RST;
           else if(f_pg_st)     cc_state   <=                                        CC_FR_WRH;
           else if(f_pg_ld)     cc_state   <=                                        CC_FR_RDH; 
           else if(f_pg_up)     cc_state   <=                                        CC_UP_WRH; 
           else if(f_pg_val)    cc_state   <=                                        CC_PT_VAL; 
           else if(f_pg_inv)    cc_state   <=                                        CC_PT_INV; 
           else                 cc_state   <=                                        CC_WAIT0; 
//.......................
 CC_MC_INI:     if(f_mr_ack)    cc_state   <=                                        CC_MC_DNL;                                 
 CC_MC_DNL:     if(!f_mr_eop)   cc_state   <=                                        CC_MC_DNL;
           else if(f_pg_rst)    cc_state   <=                                        CC_PT_RST;
           else if(f_pg_st)     cc_state   <=                                        CC_FR_WRH;
           else if(f_pg_ld)     cc_state   <=                                        CC_FR_RDH; 
           else if(f_pg_up)     cc_state   <=                                        CC_UP_WRH; 
           else if(f_pg_val)    cc_state   <=                                        CC_PT_VAL; 
           else if(f_pg_inv)    cc_state   <=                                        CC_PT_INV; 
           else                 cc_state   <=                                        CC_WAIT0; 
//.......................
 CC_PT_RST:     if(!f_pc_ack)   cc_state   <=                                        CC_PT_RST;
           else if(f_pg_st)     cc_state   <=                                        CC_FR_WRH;
           else if(f_pg_ld)     cc_state   <=                                        CC_FR_RDH; 
           else if(f_pg_up)     cc_state   <=                                        CC_UP_WRH; 
           else if(f_pg_val)    cc_state   <=                                        CC_PT_VAL; 
           else if(f_pg_inv)    cc_state   <=                                        CC_PT_INV; 
           else if(f_pg_rep)    cc_state   <=                                        CC_SETUP; 
           else                 cc_state   <=                                        CC_WAIT0; 
//.......................
 CC_FR_WRH:     if(cc_k_short)  cc_state   <=                                        CC_FR_WR1;
           else                 cc_state   <=                                        CC_FR_WR8;
 CC_FR_WR1:                     cc_state   <=                                        CC_MR_INI;
 CC_FR_WR8:                     cc_state   <=                                        CC_MR_INI;
 CC_MR_INI:     if(f_mr_ack)    cc_state   <=                                        CC_FR_WRD;
 CC_FR_WRD:     if(!f_mr_eop)   cc_state   <=                                        CC_FR_WRD;
           else if(f_pg_ld)     cc_state   <=                                        CC_FR_RDH; 
           else if(f_pg_up)     cc_state   <=                                        CC_UP_WRH; 
           else if(f_pg_val)    cc_state   <=                                        CC_PT_VAL; 
           else if(f_pg_inv)    cc_state   <=                                        CC_PT_INV; 
           else if(f_pg_rep)    cc_state   <=                                        CC_SETUP; 
           else                 cc_state   <=                                        CC_WAIT0; 
//.......................
 CC_FR_RDH:                     cc_state   <=                                        CC_FR_NUL;
 CC_FR_NUL:     if(f_pg_up)     cc_state   <=                                        CC_UP_WRH; 
           else if(f_pg_val)    cc_state   <=                                        CC_PT_VAL; 
           else if(f_pg_inv)    cc_state   <=                                        CC_PT_INV; 
           else if(f_pg_rep)    cc_state   <=                                        CC_SETUP; 
           else                 cc_state   <=                                        CC_WAIT0; 
//.......................
 CC_UP_WRH:     if(cc_k_short)  cc_state   <=                                        CC_UP_WR1;
           else                 cc_state   <=                                        CC_UP_WR8;
 CC_UP_WR1:                     cc_state   <=                                        CC_UP_INI;
 CC_UP_WR8:                     cc_state   <=                                        CC_UP_INI;
 CC_UP_INI:     if(f_mr_ack)    cc_state   <=                                        CC_UP_WRD;
 CC_UP_WRD:     if(!f_mr_eop)   cc_state   <=                                        CC_UP_WRD;
           else                 cc_state   <=                                        CC_UP_NUL;
 CC_UP_NUL:     if(f_pg_val)    cc_state   <=                                        CC_PT_VAL; 
           else if(f_pg_inv)    cc_state   <=                                        CC_PT_INV; 
           else if(f_pg_rep)    cc_state   <=                                        CC_SETUP; 
           else                 cc_state   <=                                        CC_WAIT0; 
//.......................
 CC_PT_VAL:     if(f_pc_ack)    cc_state   <=                                        CC_PT_VRS;
 CC_PT_VRS:     if(f_rid_st)    cc_state   <=                                        CC_PT_VED; 
 CC_PT_VED:     if(f_pg_inv)    cc_state   <=                                        CC_PT_INV; 
           else if(f_pg_rep)    cc_state   <=                                        CC_SETUP; 
           else                 cc_state   <=                                        CC_WAIT0; 
//.......................
 CC_PT_INV:     if(!f_pc_ack)   cc_state   <=                                        CC_PT_INV;
           else if(f_pg_rep)    cc_state   <=                                        CC_SETUP; 
           else                 cc_state   <=                                        CC_WAIT0; 
//.......................
 CC_WAIT0:                      cc_state   <=                                        CC_WAIT1;
 CC_WAIT1:                      cc_state   <=                                        CC_WAIT2;
 CC_WAIT2:                      cc_state   <=                                        CC_WAIT3;
 CC_WAIT3:                      cc_state   <=                                        CC_WAIT4;
 CC_WAIT4:      if(!o_stb)      cc_state   <=                                        CC_WAIT;
//.......................
 endcase
//=============================================================================================
assign  i_ack            =                                        i_stb && cc_state == CC_WAIT;                          
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)
    begin
        cc_tid          <=                                                                 'd0;
        cc_wid          <=                                                                 'd0;
        cc_tag          <=                                                                 'd0;
        cc_page         <=                                                                 'd0;
        cc_dirty        <=                                                                 'd0;
        cc_k_ena        <=                                                                 'd0;
        cc_k_force      <=                                                                 'd0;
        cc_k_ld         <=                                                                 'd0;
        cc_k_st         <=                                                                 'd0;
        cc_k_short      <=                                                                 'd0; 
    end
 else if(cc_state==CC_WAIT && i_stb)
    begin
        cc_tid          <=                                                               i_tid;
        cc_wid          <=                                                               i_wid;
        cc_tag          <=                                                               i_tag;
        cc_page         <=                                                              i_page;
        cc_dirty        <=                                                             i_dirty;
        cc_k_ena        <=                                                             i_k_ena;
        cc_k_force      <=                                                           i_k_force;
        cc_k_ld         <=                                                           i_k_op[0];
        cc_k_st         <=                                                           i_k_op[1];
        cc_k_short      <=                                                              i_k_sh; 
    end
//---------------------------------------------------------------------------------------------
always@(posedge clk)
  if(cc_state==CC_WAIT && i_stb)
    begin
        cc_k_addr       <=                                                            i_k_addr;
        cc_r_addr       <=                                                            i_r_addr;
        cc_p_addr       <=                                                            i_p_addr;
    end 
  else 
    begin
        cc_k_addr       <=                                                           cc_k_addr;
        cc_r_addr       <=                                                           cc_r_addr;
        cc_p_addr       <=                                                           cc_p_addr;
    end                  
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                                cc_mode     <=                                     'd0;
 else if(cc_state==CC_WAIT && i_stb)    cc_mode     <=                                  i_mode;
 else if(cc_state==CC_MC_INI)           cc_mode     <=               cc_mode & 9'b10_1111_11_1;
 else if(cc_state==CC_PT_RST)           cc_mode     <=               cc_mode & 9'b11_0111_11_1;
 else if(cc_state==CC_FR_WRH)           cc_mode     <=               cc_mode & 9'b11_1011_11_1;
 else if(cc_state==CC_FR_RDH)           cc_mode     <=               cc_mode & 9'b11_1101_11_1;
 else if(cc_state==CC_UP_WRH)           cc_mode     <=               cc_mode & 9'b11_1110_11_1;
 else if(cc_state==CC_PT_VAL)           cc_mode     <=               cc_mode & 9'b11_1111_01_1;
 else if(cc_state==CC_PT_INV)           cc_mode     <=               cc_mode & 9'b11_1111_10_1;
//=============================================================================================
wire        f_get_RID               =                                       (cc_state==CC_RID);
//---------------------------------------------------------------------------------------------
wire        f_rid_stb;
wire  [3:0] f_rid_data;
reg   [6:0] rid_cnt;
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                rid_cnt     <=                                                    7'd0;
 else if(!rid_cnt[6])   rid_cnt     <=                                          rid_cnt + 1'd1;
//---------------------------------------------------------------------------------------------
assign      rid_rdy     =                                                           rid_cnt[6];  
//---------------------------------------------------------------------------------------------
wire        vrs_stb     =                                                cc_state == CC_PT_VRS;
wire        vrs_tid     =                                                               cc_tid;
wire  [3:0] vrs_rid     =                                                               cc_rid;
//---------------------------------------------------------------------------------------------
wire        f_wr_stb    = (rid_rdy)?        ( ack_stb ?  ack_stb : vrs_stb ) :      rid_cnt[5];
wire        f_wr_tid    = (rid_rdy)?        ( ack_stb ?  ack_tid : vrs_tid ) :      rid_cnt[4];
wire  [3:0] f_wr_rid    = (rid_rdy)?        ( ack_stb ?  ack_rid : vrs_rid ) :    rid_cnt[3:0];
//---------------------------------------------------------------------------------------------
eco32_core_lsu_dcm_rid rid
(
.clk        (clk),
.rst        (rst),   

.i_stb      (f_get_RID),
.i_tid      (cc_tid),       
.i_taf      (),

.wr_stb     (f_wr_stb),
.wr_tid     (f_wr_tid),       
.wr_rid     (f_wr_rid),                                                                                      

.o_stb      (f_rid_stb),
.o_rid      (f_rid_data)
);    
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)            cc_rid  <=                                                            4'd0;
 else if(f_rid_stb) cc_rid  <=                                                      f_rid_data;
//=============================================================================================
assign  req_stb          =                                             (cc_state == CC_PT_RST);
assign  req_end          =                  (cc_state == CC_PT_INV) || (cc_state == CC_PT_VAL);
assign  req_tid          =                                                              cc_tid;
assign  req_wid          =                                                              cc_wid;
assign  req_tag          =                                                              cc_tag;          
assign  req_rid          =                                                              cc_rid;         
assign  req_page         =                                                             cc_page;
assign  req_v_addr       =                                                           cc_r_addr;
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)
    begin
        buff_task_stb    <=                                                                'd0;
        buff_task_clr    <=                                                                'd0;
        buff_task_tid    <=                                                                'd0;
        buff_task_wid    <=                                                                'd0;
        buff_task_page   <=                                                                'd0;
    end
 else
    begin       
    buff_task_stb    <= (cc_state == CC_UP_INI)||(cc_state == CC_MR_INI)||(cc_state == CC_MC_INI);
    buff_task_clr    <=                                                               f_pg_clr;
    buff_task_tid    <=                                                                 cc_tid;
    buff_task_wid    <=                                                                 cc_wid;
    buff_task_page   <=                                                                cc_page;         
    end
//---------------------------------------------------------------------------------------------
assign  tx_stb           =                                                       buff_task_stb; 
assign  tx_clr           =                                                       buff_task_clr; 
assign  tx_tid           =                                                       buff_task_tid; 
assign  tx_wid           =                                                       buff_task_wid; 
assign  tx_page          =                                                      buff_task_page;
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)
    begin
        c0_stb          <=                                                                 'd0;
        c0_ben          <=                                                                 'd0; 
    end
 else
    begin
        c0_stb          <=                                                             mmr_stb;
        c0_ben          <=                                                             mmr_ben; 
    end                                                                                       
//---------------------------------------------------------------------------------------------
always@(posedge clk)                                                                      
        c0_data         <=                                                            mmr_data;
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)
    begin
        c1_stb          <=                                                                 'd0;
        c1_ben          <=                                                                 'd0; 
        c1_cnt          <=                                                                 'hF;
        c1_cntx         <=                                                                 'h7;
    end
 else if(cc_state==CC_FR_WRD || cc_state==CC_UP_WRD || cc_state==CC_MC_DNL)
    begin
        c1_stb          <=                                                              c0_stb;
        c1_ben          <=                                                              c0_ben; 
        c1_cnt          <= (c0_stb) ?                                    c1_cnt  + 4'h1 : 4'hF;
        c1_cntx         <= (c0_stb) ?                                    c1_cntx - 4'h1 : 4'h7;
    end                                                                                       
//---------------------------------------------------------------------------------------------
always@(posedge clk)         
      if(cc_state==CC_FR_WRD || cc_state==CC_UP_WRD || cc_state==CC_MC_DNL)                  
        c1_data         <=                                                             c0_data;
      else
        c1_data         <=                                                             c1_data;
//=============================================================================================
// packet formater
//=============================================================================================
wire  [2:0] _RD          = /* read mode      */ (cc_k_short)?                  3'b000 : 3'b001; 
wire  [2:0] _WR          = /* write mode     */                                         3'b010;
wire  [2:0] _UP          = /* update mode    */                                         3'b011;
wire [38:3] _RADDR       = /* 36 bits addres */ (cc_k_ld)?              {7'h0,cc_k_addr[31:3]}:
                                                                        {7'h0,cc_r_addr[31:3]};
wire [38:3] _WADDR       = /* 36 bits addres */ (cc_k_st)?              {7'h0,cc_k_addr[31:3]}:
                                                                        {7'h0,cc_p_addr[31:3]};
wire  [3:0] _SID         = /* source ID      */                                           4'h9;
wire  [3:0] _RID         = /* request ID     */                               {        cc_rid};
wire  [3:0] _IID         = /* devide ID      */                               {3'b000, cc_tid};
wire  [1:0] _PP          = /* packet priority*/                                           2'd0; // powinno by zmieniane dla eventow na wartosc 3
//---------------------------------------------------------------------------------------------                        
always@(posedge clk)                                                                            
// header 
      if(cc_state==CC_FR_RDH) bus0_data  <=         {2'h2,_PP,20'd0,_SID,_RID,1'b0,_RADDR,_RD};
 else if(cc_state==CC_FR_WR1) bus0_data  <=         {2'h2,_PP,20'd0,_SID,_RID,1'b0,_WADDR,_WR};
 else if(cc_state==CC_FR_WR8) bus0_data  <=         {2'h2,_PP,20'd0,_SID,_RID,1'b1,_WADDR,_WR};
 else if(cc_state==CC_UP_WR1) bus0_data  <=         {2'h2,_PP,20'd0,_SID,_RID,1'b0,_WADDR,_UP};
 else if(cc_state==CC_UP_WR8) bus0_data  <=         {2'h2,_PP,20'd0,_SID,_RID,1'b1,_WADDR,_UP};
// data 
 else if(cc_state==CC_FR_WRD) bus0_data  <=         {c1_ben,                          c1_data};
 else if(cc_state==CC_UP_WRD) bus0_data  <=         {c1_ben,                          c1_data};                                                  
 else                         bus0_data  <=                                              72'd0;
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)                                                            
 if(rst)
    begin
      bus0_stb           <=                                                                1'b0;
      bus0_rts           <=                                                                1'b0; 
      bus0_bof           <=                                                                1'b0;
      bus0_eof           <=                                                                1'b0;
      bus0_iid           <=                                                                4'd0;
    end
 else if(cc_state==CC_FR_RDH || cc_state==CC_FR_WR1 || cc_state==CC_FR_WR8 || cc_state==CC_UP_WR1  || cc_state==CC_UP_WR8)   
    begin
      bus0_stb           <=                                                                1'b1;
      bus0_rts           <=                                                                1'b0; 
      bus0_bof           <=                                                                1'b1;
      bus0_eof           <=                                                                1'b0;
      bus0_iid           <=                                                                _IID;
    end
 else if((cc_state==CC_FR_WRD || cc_state==CC_UP_WRD) && cc_k_short==1'b0)   
    begin
      bus0_stb           <=                                                              c1_stb;
      bus0_rts           <=                                                      c1_cnt == 4'd0; 
      bus0_bof           <=                                                                1'b0;
      bus0_eof           <=                                                      c1_cnt == 4'd7;
      bus0_iid           <=                                                                _IID;
    end
 else if((cc_state==CC_FR_WRD || cc_state==CC_UP_WRD) && cc_k_short==1'b1)   
    begin
      bus0_stb           <=                           (c1_cnt[2:0] == cc_r_addr[5:3]) && c1_stb;
      bus0_rts           <=                           (c1_cnt[2:0] == cc_r_addr[5:3]) && c1_stb; 
      bus0_bof           <=                                                                1'b0;
      bus0_eof           <=                           (c1_cnt[2:0] == cc_r_addr[5:3]) && c1_stb;
      bus0_iid           <=                                                                _IID;
    end
 else if(cc_state==CC_FR_NUL)   
    begin
      bus0_stb           <=                                                                1'b1;
      bus0_rts           <=                                                                1'b1; 
      bus0_bof           <=                                                                1'b0;
      bus0_eof           <=                                                                1'b1;
    end
 else
    begin
      bus0_stb           <=                                                                1'b0;
      bus0_rts           <=                                                                1'b0; 
      bus0_bof           <=                                                                1'b0;
      bus0_eof           <=                                                                1'b0;
    end
//=============================================================================================
// bus stage 1
//=============================================================================================
always@(posedge clk or posedge rst)                                                            
 if(rst)
    begin
      bus1_stb           <=                                                               1'b0;
      bus1_sof           <=                                                               1'b0; 
      bus1_iid           <=                                                               4'b0; 
    end
 else if(bus0_stb)
    begin
      bus1_stb           <=                                                               1'b1;
      bus1_sof           <=                                                           bus0_bof; 
      bus1_iid           <=                                                           bus0_iid; 
    end
 else if(bus1_sof==1'b0)
    begin
      bus1_stb           <=                                                               1'b0;                                              
      bus1_sof           <=                                                               1'b0; 
    end                                                                                     
always@(posedge clk)
  if(bus0_stb || (bus1_sof==1'b0))                                                                            
      bus1_data          <=                                                          bus0_data; 
  else              
      bus1_data          <=                                                          bus1_data;
//=============================================================================================
// bus stage 2
//=============================================================================================
always@(posedge clk or posedge rst)                                                            
 if(rst)
    begin
      bus2_stb           <=                                                                'b0;
      bus2_sof           <=                                                                'b0; 
      bus2_iid           <=                                                                'b0;
    end  
 else if( (bus0_stb && (bus1_stb && bus1_sof)) || (bus1_stb && !bus1_sof))
    begin
      bus2_stb           <=                                                                'b1;
      bus2_sof           <=                                                           bus1_sof; 
      bus2_iid           <=                                                           bus1_iid;           
    end                                                                                                    
 else
    begin
      bus2_stb           <=                                                                'b0;
      bus2_sof           <=                                                                'b0; 
      bus2_iid           <=                                                                'b0;
    end                                                                                       
always@(posedge clk)                                                                            
      bus2_data          <=                                                          bus1_data;        
//=============================================================================================        
always@(posedge clk or posedge rst)                                                            
 if(rst)
    begin
      bus3_stb           <=                                                                'b0;
      bus3_sof           <=                                                                'b0; 
      bus3_iid           <=                                                                'd0;
    end  
 else
    begin
      bus3_stb           <=                                                           bus2_stb;
      bus3_sof           <=                                                           bus2_sof; 
      bus3_iid           <=                                                           bus2_iid;  
    end      
always@(posedge clk)                                                             
      bus3_data          <=                                                          bus2_data;
//=============================================================================================
assign o_stb    = bus3_stb;
assign o_sof    = bus3_sof;
assign o_iid    = bus3_iid;
assign o_data   = bus3_data;
//=============================================================================================
endmodule