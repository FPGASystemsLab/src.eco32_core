//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_ifu_box
#
(
parameter               ICACHE_SIZE = "8KB",
parameter               FORCE_RST   =     0,
parameter        [38:0] MEM_SP_BOOTROM_START_LOG = 39'd0
)
(
input  wire             clk,          
input  wire             rst,          
input  wire             ena,          
output wire             rdy,
                                      
input  wire             ena_t0,       
input  wire             hold_t0,       

input  wire             ena_t1,       
input  wire             hold_t1,       

input  wire             epp_i_stb,
input  wire             epp_i_sof,
input  wire     [71:0]  epp_i_data,

output wire             epp_o_br,
input  wire             epp_o_bg,
 
output wire             epp_o_stb,
output wire             epp_o_sof,
output wire      [3:0]  epp_o_iid,
output wire     [71:0]  epp_o_data,
input  wire      [1:0]  epp_o_rdy, 

input  wire             jp_stb,       
input  wire             jp_evt_ack,       
input  wire     [3:0]   jp_asid,
input  wire     [1:0]   jp_pid,                                                      
input  wire    [15:0]   jp_isw,       
input  wire    [31:0]   jp_v_addr,    

input  wire             fci_inst_rep, 

input  wire             fci_inst_lsf, 
input  wire     [15:0]  fci_inst_lsw, 

input  wire      [1:0]  sys_event_ena, 

output wire             o_stb,
output wire             o_tid,
output wire     [3:0]   o_asid,
output wire     [1:0]   o_pid,
output wire     [1:0]   o_isz,
output wire    [15:0]   o_isw,
output wire    [31:0]   o_iva,     
output wire    [31:0]   o_iop,     
output wire    [31:0]   o_iex,     
output wire     [3:0]   o_erx,
output wire     [8:0]   o_wrx,

output  wire            o_ins_cnd_ena,
output  wire     [5:0]  o_ins_cnd_val,
output  wire     [5:0]  o_ins_rya,
output  wire            o_ins_ryz,
output  wire    [31:0]  o_ins_opc,
output  wire    [31:0]  o_ins_const,

output wire             o_evt_req,
output wire     [2:0]   o_evt_eid
);                       
//============================================================================================== 
// local params
//==============================================================================================  
localparam [5:0] _PAGE_ADDR_WIDTH     =   (ICACHE_SIZE ==  "4KB")?                                'd4: // 1K  * 2 ways * 2 threads
                                    (ICACHE_SIZE ==  "8KB")?                                'd5: // 2K  * 2 ways * 2 threads
                                    (ICACHE_SIZE == "16KB")?                                'd6: // 4K  * 2 ways * 2 threads
                                    (ICACHE_SIZE == "32KB")?                                'd7: // 8K  * 2 ways * 2 threads
                                    /*default*/                                "way_size_error";
//----------------------------------------------------------------------------------------------  
localparam _PAW                 =                                              _PAGE_ADDR_WIDTH;
//============================================================================================== 
// variables                                                                                      
//==============================================================================================  
reg            ena_th0;                                                                          
reg            ena_th1;                                                                          
//----------------------------------------------------------------------------------------------  
reg            rdy_all;
wire           rdy_icm;
//----------------------------------------------------------------------------------------------
// stage bn  
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             bn_ena_th0;
(* shreg_extract = "NO"  *) reg             bn_ena_th1;
(* shreg_extract = "NO"  *) reg             bn_tid;
(* shreg_extract = "NO"  *) reg      [1:0]  bn_pid;
(* shreg_extract = "NO"  *) reg             bn_evt_ack;
(* shreg_extract = "NO"  *) reg      [3:0]  bn_asid;
(* shreg_extract = "NO"  *) reg     [31:0]  bn_iva;
(* shreg_extract = "NO"  *) reg     [15:0]  bn_isw;
//----------------------------------------------------------------------------------------------  
// stage a0                                                                                       
//----------------------------------------------------------------------------------------------  
(* shreg_extract = "NO"  *) reg             a0_stb;
(* shreg_extract = "NO"  *) reg             a0_tid;
(* shreg_extract = "NO"  *) reg             a0_evt_ack;
(* shreg_extract = "NO"  *) reg      [3:0]  a0_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  a0_isw;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_iva;  
//----------------------------------------------------------------------------------------------
(* shreg_extract = "YES" *) reg     [31:0]  dl_iva  [9:0];
(* shreg_extract = "YES" *) reg      [1:0]  dl_pid  [5:0];
(* shreg_extract = "YES" *) reg      [3:0]  dl_asid [5:0];
(* shreg_extract = "YES" *) reg     [15:0]  dl_isw  [3:0];
//----------------------------------------------------------------------------------------------
// stage b1  
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b1_stb;
(* shreg_extract = "NO"  *) reg             b1_tid;
(* shreg_extract = "NO"  *) reg             b1_evt_ack;
(* shreg_extract = "NO"  *) reg      [3:0]  b1_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  b1_isw;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_iva;  
(* shreg_extract = "NO"  *) reg      [3:0]  b1_erx;
//----------------------------------------------------------------------------------------------
// stage a2
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             a2_stb;
(* shreg_extract = "NO"  *) reg             a2_tid;
(* shreg_extract = "NO"  *) reg             a2_evt_ack;
(* shreg_extract = "NO"  *) reg      [3:0]  a2_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  a2_isw;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_iva;  
(* shreg_extract = "NO"  *) reg      [3:0]  a2_erx;
//----------------------------------------------------------------------------------------------
// stage b3
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b3_stb;
(* shreg_extract = "NO"  *) reg             b3_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  b3_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  b3_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  b3_isw;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_iva;  
(* shreg_extract = "NO"  *) reg      [3:0]  b3_erx;
//                
                            wire            b3_cr_rdy;
                           
                            wire     [1:0]  b3_hit;         
                            wire     [1:0]  b3_miss;
                            wire     [1:0]  b3_locked;
                            wire     [1:0]  b3_empty;
                            wire     [1:0]  b3_exc;
                            wire     [1:0]  b3_way_tag;
                           
                            wire     [3:0]  b3_exc_ida      [1:0];         
                            wire     [3:0]  b3_exc_idp      [1:0];                                                                                         
                            wire     [3:0]  b3_exc_idt      [1:0];

(* shreg_extract = "NO"  *) reg             b3_evt_req;
(* shreg_extract = "NO"  *) reg      [2:0]  b3_evt_eid;
(* shreg_extract = "NO"  *) reg             b3_evt_ack0;
(* shreg_extract = "NO"  *) reg             b3_evt_ack1;

                            wire    [71:0]  b3_data         [1:0];

                            wire     [1:0]  b3_ins_skip;
                            wire     [1:0]  b3_ins_ext;

                            wire     [2:0]  b3_cmod_lo      [1:0];
                            wire     [1:0]  b3_cmod_mi      [1:0];
                            wire     [2:0]  b3_cmod_hi      [1:0];
//----------------------------------------------------------------------------------------------
// stage a4
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg              a4_stb;
(* shreg_extract = "NO"  *) reg              a4_rep;
(* shreg_extract = "NO"  *) reg              a4_tid;
(* shreg_extract = "NO"  *) reg        [3:0] a4_asid;
(* shreg_extract = "NO"  *) reg        [1:0] a4_pid;
(* shreg_extract = "NO"  *) reg        [1:0] a4_wid;
(* shreg_extract = "NO"  *) reg   [_PAW-1:0] a4_page;  
(* shreg_extract = "NO"  *) reg       [15:0] a4_isw;
(* shreg_extract = "NO"  *) reg       [31:0] a4_iva;  
(* shreg_extract = "NO"  *) reg        [3:0] a4_erx;
(* shreg_extract = "NO"  *) reg              a4_hit;
(* shreg_extract = "NO"  *) reg              a4_cancel;

(* shreg_extract = "NO"  *) reg              a4_cr_stb;
(* shreg_extract = "NO"  *) reg              a4_cr_cancel;
(* shreg_extract = "NO"  *) reg              a4_cr_tid;
(* shreg_extract = "NO"  *) reg       [15:0] a4_cr_isw;
(* shreg_extract = "NO"  *) reg              a4_cr_wid;
(* shreg_extract = "NO"  *) reg              a4_cr_tag;
(* shreg_extract = "NO"  *) reg   [_PAW-1:0] a4_cr_page;
(* shreg_extract = "NO"  *) reg       [31:0] a4_cr_iva; 

(* shreg_extract = "NO"  *) reg       [63:0] a4_data;   
                           
(* shreg_extract = "NO"  *) reg        [1:0] a4_ins_skip;   
(* shreg_extract = "NO"  *) reg              a4_ins_ext;    
(* shreg_extract = "NO"  *) reg        [1:0] a4_ins_rym;    
(* shreg_extract = "NO"  *) reg        [1:0] a4_ins_cndm;   
                             
(* shreg_extract = "NO"  *) reg        [2:0] a4_cmod_lo;    
(* shreg_extract = "NO"  *) reg        [1:0] a4_cmod_mi;    
(* shreg_extract = "NO"  *) reg        [2:0] a4_cmod_hi;    

(* shreg_extract = "NO"  *) reg              a4_evt_req;
(* shreg_extract = "NO"  *) reg        [2:0] a4_evt_eid;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg              b5_stb;
(* shreg_extract = "NO"  *) reg              b5_tid;
(* shreg_extract = "NO"  *) reg        [3:0] b5_asid;
(* shreg_extract = "NO"  *) reg        [1:0] b5_pid;
(* shreg_extract = "NO"  *) reg       [15:0] b5_isw;
(* shreg_extract = "NO"  *) reg        [1:0] b5_isz;
(* shreg_extract = "NO"  *) reg       [31:0] b5_iva;
(* shreg_extract = "NO"  *) reg       [31:0] b5_iex;
(* shreg_extract = "NO"  *) reg        [3:0] b5_erx;

(* shreg_extract = "NO"  *) reg              b5_ins_cnd_ena;  
(* shreg_extract = "NO"  *) reg        [5:0] b5_ins_cnd_val;  

(* shreg_extract = "NO"  *) reg        [5:0] b5_ins_rya;  
(* shreg_extract = "NO"  *) reg              b5_ins_ryz;  

(* shreg_extract = "NO"  *) reg       [31:0] b5_ins_opc;  
(* shreg_extract = "NO"  *) reg       [31:0] b5_ins_const;

(* shreg_extract = "NO"  *) reg              b5_evt_req;  
(* shreg_extract = "NO"  *) reg       [2:0]  b5_evt_eid;  

//----------------------------------------------------------------------------------------------
                            wire             mm_wr_stb;       
                            wire             mm_wr_tid;       
                            wire             mm_wr_wid;
                            wire [_PAW-1:0]  mm_wr_page;      
                            wire      [2:0]  mm_wr_offset;    
                            wire     [71:0]  mm_wr_data;      
                                 
                            wire             pt_wr_stb;       
                            wire             pt_wr_tid;       
                            wire             pt_wr_wid;
                            wire [_PAW-1:0]  pt_wr_page;      
                            wire     [35:0]  pt_wr_descriptor;
//----------------------------------------------------------------------------------------------
                            wire            evt_th0_req;                            
                            wire     [2:0]  evt_th0_eid;                            
                            wire     [3:0]  evt_th0_erx;                            
                            wire            evt_th0_ack;                            
                                                        
                            wire            evt_th1_req;                            
                            wire     [2:0]  evt_th1_eid;                            
                            wire     [3:0]  evt_th1_erx;                            
                            wire            evt_th1_ack;                            
//==============================================================================================           
// module ready
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) rdy_all        <=                                                                 1'b0;
 else    rdy_all        <=                                                              rdy_icm;
//----------------------------------------------------------------------------------------------
assign   rdy             =                                                              rdy_all;
//==============================================================================================           
// enable switches
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) ena_th0        <=                                                                 1'b0;
 else    ena_th0        <=                                            !hold_t0 && ena_t0 && ena;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst) ena_th1        <=                                                                 1'b0;
 else    ena_th1        <=                                            !hold_t1 && ena_t1 && ena;
//==============================================================================================
// stage (b)n: next pc 
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    bn_tid              <=                                                                 1'b1;
    bn_ena_th0          <=                                                                 1'b0;
    bn_ena_th1          <=                                                                 1'b0;
    bn_asid             <=                                                                 4'd0;
    bn_pid              <=                                                                2'b11;
    bn_isw              <=                                                                16'b0;        
    bn_iva              <=                                             MEM_SP_BOOTROM_START_LOG; // 3G (kernel) + 3*250M (bootrom)
    bn_iva              <=                                             MEM_SP_BOOTROM_START_LOG; 
    bn_evt_ack          <=                                                                  'd0; 
  end   
 else                                                                                                               
  begin                                                                                                             
    bn_tid              <=                                                               a0_tid;
    //..........................................................................................
    
    bn_pid              <=  (fci_inst_lsf   ) ?                                      dl_pid[5] :
                            (fci_inst_rep   ) ?                                      dl_pid[3] :  
                            (a4_rep         ) ?                                         a4_pid : 
                            (a0_stb         ) ?                                         a0_pid : 
                                                                                        a0_pid ;
       
    //..........................................................................................

    bn_asid            <=   (fci_inst_lsf   ) ?                                     dl_asid[5] :
                            (fci_inst_rep   ) ?                                     dl_asid[3] :  
                            (a4_rep         ) ?                                        a4_asid : 
                            (a0_stb         ) ?                                        a0_asid :
                                                                                       a0_asid ;
    //..........................................................................................

    bn_iva             <=   (fci_inst_lsf   ) ?                                   dl_iva[9]    :
                            (fci_inst_rep   ) ?                                   dl_iva[7]    :  
                            (a4_rep         ) ?                                   dl_iva[3]    : 
                            (a0_stb         ) ?                                   a0_iva+32'd4 : 
                                                                                  a0_iva+32'd0 ;

    //..........................................................................................
                            
    bn_isw             <=   (fci_inst_lsf   ) ?                                   fci_inst_lsw :
                            (fci_inst_rep   ) ?                                   dl_isw[3]    :  
                            (a4_rep         ) ?                                      a4_cr_isw : 
                            (a0_stb         ) ?                                          16'd0 : 
                                                                                        a0_isw ;         

    //..........................................................................................
                            
    bn_evt_ack          <=  (fci_inst_lsf   ) ?                                           1'b0 :
                            (fci_inst_rep   ) ?                                           1'b0 :
                            (a4_rep         ) ?                                           1'b0 :
                                                                                    a0_evt_ack ;

    //..........................................................................................
    
    bn_ena_th0          <=  (fci_inst_lsf   ) ?   fci_inst_lsw[8] | fci_inst_lsw[10] | ena_th0 :
                            (fci_inst_rep   ) ?                                        ena_th0 :
                            (a4_rep         ) ?                                        ena_th0 :
                                                                                       ena_th0 ;

    //..........................................................................................
    
    bn_ena_th1          <=  (fci_inst_lsf   ) ?   fci_inst_lsw[8] | fci_inst_lsw[10] | ena_th1 :
                            (fci_inst_rep   ) ?                                        ena_th1 :
                            (a4_rep         ) ?                                        ena_th1 :
                                                                                       ena_th1 ;

    //..........................................................................................
  end      
//==============================================================================================
// stage (a)0: pc 
//==============================================================================================
always@(posedge clk or posedge rst) 
 if(rst) 
  begin 
    a0_stb              <=                                                                 1'b0;      
    a0_tid              <=                                                                 1'b0;      
    a0_evt_ack          <=                                                                 1'b0;
    a0_asid             <=                                                                 4'd0;      
    a0_pid              <=                                                                2'b11;      
    a0_iva              <= /* reset */                                            MEM_SP_BOOTROM_START_LOG;
    a0_isw              <=                                                                16'b0;        
  end                                                                                                   
 else if(jp_stb)
  begin
    a0_stb              <=  (bn_tid) ?                                  bn_ena_th1 : bn_ena_th0; 
    a0_tid              <=                                                               bn_tid;
    a0_evt_ack          <=                                                           jp_evt_ack;      
    a0_asid             <=                                                              jp_asid;
    a0_pid              <=                                                               jp_pid;
    a0_iva              <=                                                            jp_v_addr;    
    a0_isw              <=                                                               jp_isw;        
  end     
 else
  begin
    a0_stb              <=  (bn_tid) ?                                  bn_ena_th1 : bn_ena_th0; 
    a0_tid              <=                                                               bn_tid;
    a0_evt_ack          <=                                                                 1'b0;      
    a0_asid             <=                                                              bn_asid;
    a0_pid              <=                                                               bn_pid;  
    a0_iva              <=                                                               bn_iva;    
    a0_isw              <=                                                               bn_isw;
  end               
//==============================================================================================
// delay buffer
//==============================================================================================
always@(posedge clk) 
 begin  
    dl_iva[0]           <=                                                            a0_iva   ;
    dl_iva[1]           <=                                                            dl_iva[0];
    dl_iva[2]           <=                                                            dl_iva[1];
    dl_iva[3]           <=                                                            dl_iva[2];
    dl_iva[4]           <=                                                            dl_iva[3];
    dl_iva[5]           <=                                                            dl_iva[4];
    dl_iva[6]           <=                                                            dl_iva[5];
    dl_iva[7]           <=                                                            dl_iva[6];
    dl_iva[8]           <=                                                            dl_iva[7];
    dl_iva[9]           <=                                                            dl_iva[8];
 end 
//==============================================================================================
// instruction cache way
//==============================================================================================   
generate
genvar i;

 for(i=0;i<2;i=i+1)
     begin : way
        eco32_core_ifu_icu_way 
        #(
        .PAGE_ADDR_WIDTH    (_PAGE_ADDR_WIDTH),
        .FORCE_RST          (FORCE_RST)
        )
        ic_way0
        (
        .clk                (clk),
        .rst                (rst),
        
        .i_stb              (a0_stb),
        .i_tid              (a0_tid),
        .i_pid              (a0_pid),
        .i_asid             (a0_asid),
        .i_v_addr           (a0_iva),
        
        .pt_wr_stb          (pt_wr_stb && pt_wr_wid == i[0]),
        .pt_wr_tid          (pt_wr_tid),
        .pt_wr_page         (pt_wr_page),
        .pt_wr_descriptor   (pt_wr_descriptor),
        
        .mm_wr_stb          (mm_wr_stb && mm_wr_wid == i[0]),
        .mm_wr_tid          (mm_wr_tid),
        .mm_wr_page         (mm_wr_page),
        .mm_wr_offset       (mm_wr_offset),
        .mm_wr_data         (mm_wr_data),
                                               
        .o_hit              (b3_hit[i]),
        .o_miss             (b3_miss[i]),
        .o_locked           (b3_locked[i]),
        .o_empty            (b3_empty[i]),
        .o_tag              (b3_way_tag[i]),
                                                                                                    
        .o_exc              (b3_exc[i]),
        .o_exc_ida          (b3_exc_ida[i]),
        .o_exc_idp          (b3_exc_idp[i]),
        .o_exc_idt          (b3_exc_idt[i]),
        
        .o_data             (b3_data[i]),            

        .o_inst_skip        (b3_ins_skip[i]),       
        .o_inst_ext         (b3_ins_ext[i]),        
                                                     
        .o_cmod_lo          (b3_cmod_lo[i]),        
        .o_cmod_mi          (b3_cmod_mi[i]),        
        .o_cmod_hi          (b3_cmod_hi[i])         
        );                                    
    end     
//..........................................................................................
endgenerate   
//==============================================================================================
// stage (b)1: pc 
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b1_stb              <=                                                                 1'b0;
    b1_tid              <=                                                                 1'b1;
    b1_evt_ack          <=                                                                 1'b0;      
    b1_asid             <=                                                                 4'd0;
    b1_pid              <=                                                                2'b11;
    b1_isw              <=                                                                16'b0;        
    b1_iva              <=                                             MEM_SP_BOOTROM_START_LOG; // 3G (kernel) + 3*250M (bootrom)
  end   
 else                                                                                                               
  begin
    b1_stb              <=                  !fci_inst_rep && !fci_inst_lsf && !a4_rep && a0_stb;
    b1_tid              <=                                                               a0_tid;
    b1_evt_ack          <=                                                           a0_evt_ack;      
    b1_asid             <=                                                              a0_asid;
    b1_pid              <=                                                               a0_pid;
    b1_isw              <=                                                               a0_isw;         
    b1_iva              <=                                                               a0_iva;          
  end      
//==============================================================================================
// stage (a)2:  
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a2_stb              <=                                                                  'b0;
    a2_tid              <=                                                                  'b0;
    a2_evt_ack          <=                                                                  'b0;      
    a2_asid             <=                                                                  'd0;
    a2_pid              <=                                                                  'd0;
    a2_isw              <=                                                                  'd0;        
    a2_iva              <=                                                                  'd0; 
    a2_erx              <=                                                                  'd0; 
  end   
 else  
  begin
    a2_stb              <=                                                    !jp_stb && b1_stb;
    a2_tid              <=                                                               b1_tid;
    a2_evt_ack          <=                                                           b1_evt_ack;      
    a2_asid             <=                                                              b1_asid;
    a2_pid              <=                                                               b1_pid;
    a2_isw              <=                                                               b1_isw;
    a2_iva              <=                                                               b1_iva;
    a2_erx              <=                                                                  'd0; 
  end
//==============================================================================================
// stage (b)3:  
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b3_stb              <=                                                                 1'b0;
    b3_tid              <=                                                                 1'b0;
    b3_asid             <=                                                                 4'd0;
    b3_pid              <=                                                                 2'd0;
    b3_isw              <=                                                                16'd0;        
    b3_iva              <=                                                        32'h0000_0000; 
    b3_erx              <=                                                                  'd0;

    b3_evt_req          <=                                                                  'd0;
    b3_evt_eid          <=                                                                  'd0;
    b3_evt_ack0         <=                                                                  'b0;
    b3_evt_ack1         <=                                                                  'b0;
  end
 else
  begin
    b3_stb              <=                  !fci_inst_rep && !fci_inst_lsf && !a4_rep && a2_stb;
    b3_tid              <=                                                               a2_tid;
    b3_asid             <=                                                              a2_asid;
    b3_pid              <=                                                               a2_pid;
    b3_isw              <=                                                               a2_isw;
    b3_iva              <=                                                               a2_iva;

    if(a2_tid==1'b0)
        begin
            b3_evt_req  <= (!fci_inst_lsw[8] & !fci_inst_lsw[10]) && !a2_evt_ack && evt_th0_req;
            b3_evt_eid  <=                                                          evt_th0_eid;
            b3_erx      <=                                                          evt_th0_erx;
            b3_evt_ack0 <=                                            a2_evt_ack && evt_th0_req;
        end
    else
        begin
            b3_evt_req  <= (!fci_inst_lsw[8] & !fci_inst_lsw[10]) && !a2_evt_ack && evt_th1_req;
            b3_evt_eid  <=                                                          evt_th1_eid;
            b3_erx      <=                                                          evt_th1_erx;
            b3_evt_ack1 <=                                            a2_evt_ack && evt_th1_req;
        end
  end
//----------------------------------------------------------------------------------------------
wire        b3_c_hit_wid = (b3_hit[0]) ?                                                   1'd0:
                           (b3_hit[1]) ?                                                   1'd1:
                                                                                           1'd0;
//----------------------------------------------------------------------------------------------
wire        b3_c_hit     =                                                           (|b3_hit );
wire        b3_c_miss    =                                              !b3_c_hit && (|b3_miss);
wire        b3_c_locked  =                            (!b3_cr_rdy | (|b3_locked)) & !(|b3_hit );     
wire        b3_c_way     =                                        b3_way_tag[0] ^ b3_way_tag[1];     
wire        b3_c_way_tag =                                                !b3_way_tag[b3_c_way];     
//----------------------------------------------------------------------------------------------
wire [63:0] b3_data0     =                                                           b3_data[0];
wire [63:0] b3_data1     =                                                           b3_data[1];
//==============================================================================================
// event ack
//==============================================================================================
assign      evt_th0_ack  =                                                          b3_evt_ack0;
assign      evt_th1_ack  =                                                          b3_evt_ack1;
//==============================================================================================
// stage (a)4:  
//============================================================================================== 
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a4_stb              <=                                                                 1'b0;
    a4_rep              <=                                                                 1'b0;
    a4_tid              <=                                                                 1'b0;
    a4_asid             <=                                                                 4'd0;
    a4_pid              <=                                                                 2'd0;
    a4_isw              <=                                                                16'd0;        
    a4_iva              <=                                                        32'h0000_0000; 
    a4_erx              <=                                                                  'd0; 
    a4_wid              <=                                                                  'd0;  
    a4_page             <=                                                                  'd0;  
    a4_hit              <=                                                                  'd0;  
                          
    a4_cr_stb           <=                                                                  'd0;    
    a4_cr_cancel        <=                                                                  'd0;  
    a4_cr_tid           <=                                                                  'd0;    
    a4_cr_isw           <=                                                                  'd0;    
    a4_cr_wid           <=                                                                  'd0;    
    a4_cr_tag           <=                                                                  'd0;  
    a4_cr_iva           <=                                                                  'd0;    
    a4_cr_page          <=                                                                  'd0;

    a4_data             <=                                                                  'd0;
    a4_ins_skip         <=                                                                  'd0;
    a4_ins_ext          <=                                                                  'd0;
    a4_ins_rym          <=                                                                  'd0;
    a4_ins_cndm         <=                                                                  'd0;

    a4_cmod_lo          <=                                                                  'd0;
    a4_cmod_mi          <=                                                                  'd0;
    a4_cmod_hi          <=                                                                  'd0;

    a4_evt_req          <=                                                                  'd0;
    a4_evt_eid          <=                                                                  'd0;
  end   
 else  
  begin
    a4_stb              <=                                        b3_c_hit && !jp_stb && b3_stb;
    a4_rep              <=                                       b3_c_miss && !jp_stb && b3_stb;
    a4_tid              <=                                                               b3_tid;
    a4_asid             <=                                                              b3_asid;
    a4_pid              <=                                                               b3_pid;
    a4_isw              <=                                                               b3_isw;        
    a4_iva              <=                                                               b3_iva;
    a4_erx              <=                                                               b3_erx;
    a4_wid              <=                                                         b3_c_hit_wid;
    a4_page             <=                                       b3_iva[_PAGE_ADDR_WIDTH-1+6:6];
    a4_hit              <=                                       (|b3_hit) && !jp_stb && b3_stb;  
    a4_cr_cancel        <=                                                    jp_stb || !b3_stb;                               

    casex({a4_cr_stb,b3_c_miss,b3_c_locked,b3_isw[14:13]})                                                                             

    // check for page lodk  
        
    5'b0_x_1_00: // page locked
        begin
            a4_cr_stb          <=                                                          1'b0;
            a4_cr_isw[14:13]   <=                                                         2'b01;
        end
    5'b0_0_0_00: // hit & and page not locked
        begin
            a4_cr_stb          <=                                                          1'b0;
            a4_cr_isw[14:13]   <=                                                         2'b00;
        end
    5'b0_1_0_00: // miss & page not locked
        begin
            a4_cr_stb          <=                                                          1'b1;
            a4_cr_isw[14:13]   <=                                                         2'b10;
        end                                                                                                                                                              

    // wait for unlock  
        
    5'b0_x_1_01: // wait for page unlock
        begin
            a4_cr_stb          <=                                                          1'b0;
            a4_cr_isw[14:13]   <=                                                         2'b01;
        end
    5'b0_0_0_01: // hit and page unlocked
        begin
            a4_cr_stb          <=                                                          1'b0;
            a4_cr_isw[14:13]   <=                                                         2'b00;
        end 
    5'b0_1_0_01: // miss and page unlocked
        begin
            a4_cr_stb          <=                                                          1'b1;
            a4_cr_isw[14:13]   <=                                                         2'b10;
        end 

    // wait for page load
        
    5'b0_1_x_1x: // page not loaded
        begin
            a4_cr_stb          <=                                                          1'b0;
            a4_cr_isw[14:13]   <=                                                         2'b10;
        end
    5'b0_0_x_1x: // hit but not unloaded
        begin
            a4_cr_stb          <=                                                          1'b0;
            a4_cr_isw[14:13]   <=                                                         2'b00;
        end   
        
    5'b1_x_x_xx: // wait for cache engine ready
        begin
            a4_cr_stb          <=                                                          1'b0;
            a4_cr_isw[14:13]   <=                                                 b3_isw[14:13];
        end
    endcase                                                                                               
                                                                                                         
    a4_cr_wid           <=                                                             b3_c_way;
    a4_cr_tag           <=                                                         b3_c_way_tag;
    
    a4_cr_isw[12:0]     <=                                                         b3_isw[12:0];                                                       
    a4_cr_isw[  15]     <=                                                         b3_isw[  15];
    a4_cr_tid           <=                                                               b3_tid;
    a4_cr_iva           <=                                                               b3_iva;
    a4_cr_page          <=                                       b3_iva[_PAGE_ADDR_WIDTH-1+6:6];
    
    a4_evt_req          <=                                                           b3_evt_req;
    a4_evt_eid          <=                                                           b3_evt_eid;

    
    if(b3_evt_req)
        begin
            a4_data     <=                      {6'h37,1'b0,6'd0,6'd0,6'd0,1'b0,b3_evt_eid,3'd7};   
            a4_ins_skip <=                                                                  1'b0;
            a4_ins_ext  <=                                                                  1'b0;
            a4_ins_rym  <=                                                                  2'd2;
            a4_ins_cndm <=                                                                  2'd2;
                                                                                                    
            a4_cmod_lo  <=                                                                3'b100;
            a4_cmod_mi  <=                                                                 2'b11;
            a4_cmod_hi  <=                                                                3'b111;
        end 
    else if(b3_hit[1]) // way 1
        begin
            a4_data     <=                                                            b3_data[1];   
            a4_ins_skip <=                                                        b3_ins_skip[1];
            a4_ins_ext  <=                                                         b3_ins_ext[1];
            a4_ins_rym  <=  (b3_data1[31:26] == 6'h38) ?                                    2'd0:
                            (b3_data1[31:26] == 6'h39) ?                                    2'd1:
                                                                                            2'd3;
                            
            a4_ins_cndm <=  (b3_ins_ext[1]   == 1'b0 ) ?                                    2'd0:
                                                                                            2'd1;
            
            a4_cmod_lo  <=                                                         b3_cmod_lo[1];
            a4_cmod_mi  <=                                                         b3_cmod_mi[1];
            a4_cmod_hi  <=                                                         b3_cmod_hi[1];
        end
    else          // way 0
        begin
            a4_data     <=                                                            b3_data[0];   
            a4_ins_skip <=                                                        b3_ins_skip[0];
            a4_ins_ext  <=                                                         b3_ins_ext[0];
            a4_ins_rym  <=  (b3_data0[31:26] == 6'h38) ?                                    2'd0:
                            (b3_data0[31:26] == 6'h39) ?                                    2'd1:
                                                                                            2'd3;
                                                                                                    
            a4_ins_cndm <=  (b3_ins_ext[0]   == 1'b0 ) ?                                    2'd0:
                                                                                            2'd1;
            
            a4_cmod_lo  <=                                                         b3_cmod_lo[0];
            a4_cmod_mi  <=                                                         b3_cmod_mi[0];
            a4_cmod_hi  <=                                                         b3_cmod_hi[0];
        end
  end      
//==============================================================================================
// delay buffer
//==============================================================================================
always@(posedge clk) 
 begin  
    dl_pid[0]           <=                                                            a4_pid   ;
    dl_pid[1]           <=                                                            dl_pid[0];
    dl_pid[2]           <=                                                            dl_pid[1];
    dl_pid[3]           <=                                                            dl_pid[2];
    dl_pid[4]           <=                                                            dl_pid[3];
    dl_pid[5]           <=                                                            dl_pid[4];
 end 
//----------------------------------------------------------------------------------------------
always@(posedge clk) 
 begin  
    dl_asid[0]          <=                                                           a4_asid   ;
    dl_asid[1]          <=                                                           dl_asid[0];
    dl_asid[2]          <=                                                           dl_asid[1];
    dl_asid[3]          <=                                                           dl_asid[2];
    dl_asid[4]          <=                                                           dl_asid[3];
    dl_asid[5]          <=                                                           dl_asid[4];
 end 
//----------------------------------------------------------------------------------------------
always@(posedge clk) 
 begin  
    dl_isw[0]           <=                                                           a4_isw    ;
    dl_isw[1]           <=                                                           dl_isw [0];
    dl_isw[2]           <=                                                           dl_isw [1];
    dl_isw[3]           <=                                                           dl_isw [2];
 end 
//==============================================================================================
// stage (b)5:  
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                                                                
    b5_stb              <=                                                                  'b0;                       
    b5_tid              <=                                                                  'b0;
    b5_asid             <=                                                                  'b0;
    b5_pid              <=                                                                  'b0;
    b5_isw              <=                                                                  'b0;
    b5_isz              <=                                                                  'b0;
    b5_iva              <=                                                                  'd0;
    b5_iex              <=                                                                  'd0;
    b5_erx              <=                                                                  'd0;
    
    b5_ins_cnd_ena      <=                                                                  'd0;
    b5_ins_cnd_val      <=                                                                  'd0;
    b5_ins_rya          <=                                                                  'd0;
    b5_ins_ryz          <=                                                                  'd0;
    b5_ins_opc          <=                                                                  'd0;
    b5_ins_const        <=                                                                  'd0;
    
    b5_evt_req          <=                                                                  'd0;
    b5_evt_eid          <=                                                                  'd0;
  end 
 else 
  begin  
    b5_stb              <=             !fci_inst_rep && !fci_inst_lsf && !a4_ins_skip && a4_stb;
    b5_tid              <=                                                               a4_tid;
    b5_asid             <=                                                              a4_asid;
    b5_pid              <=                                                               a4_pid;
    b5_isw              <=                                                               a4_isw;
    b5_isz              <=                                                    {1'b0,a4_ins_ext};
    b5_iva              <=                                                               a4_iva;
    b5_erx              <=                                                               a4_erx;
    
    b5_evt_req          <=                                                           a4_evt_req;
    b5_evt_eid          <=                                                           a4_evt_eid;

    // opcode   
    
    b5_ins_opc          <=                                                        a4_data[31:0]; // Regular
    
    // cond

    case(a4_ins_cndm)
    2'd0:   b5_ins_cnd_ena  <=                                                             1'b0; // instr
    2'd1:   b5_ins_cnd_ena  <=                                                             1'b1; // force 
    2'd2:   b5_ins_cnd_ena  <=                                                             1'b0; // foo
    2'd3:   b5_ins_cnd_ena  <=                                                             1'b0; // foo
    endcase
       
    case(a4_ins_cndm)
    2'd0:   b5_ins_cnd_val  <=                                                   a4_data[24:19]; // LO
    2'd1:   b5_ins_cnd_val  <=                                                   a4_data[56:51]; // EXT
    2'd2:   b5_ins_cnd_val  <=                                                             6'd0; // off 
    2'd3:   b5_ins_cnd_val  <=                                                             6'd0; // 
    endcase
    
    // ry address znad zero flag
                                                                                                                     
    case(a4_ins_rym)
    2'd0:   b5_ins_rya  <=                                                       a4_data[24:19]; // Ra
    2'd1:   b5_ins_rya  <=                                                       a4_data[24:19]; // Ra
    2'd2:   b5_ins_rya  <=                                                                6'h1F; // R31
    2'd3:   b5_ins_rya  <=                                                       a4_data[18:13]; // Ry
    endcase

    casex(a4_ins_rym)
    2'd0:   b5_ins_ryz  <=                                                   !(|a4_data[24:19]); // Ra                    
    2'd1:   b5_ins_ryz  <=                                                   !(|a4_data[24:19]); // Ra                      
    2'd2:   b5_ins_ryz  <=                                                                 1'b0; // R31
    2'd3:   b5_ins_ryz  <=                                                   !(|a4_data[18:13]); // Ry
    endcase
    
    // const    

    casex(a4_cmod_lo)
    3'b0_00: b5_ins_const[12:0] <=                                               a4_data[12: 0]; // LO_13
    3'b0_01: b5_ins_const[12:0] <=                                        {a4_data[12: 2],2'd0}; // ADR_11
    3'b0_10: b5_ins_const[12:0] <=                                        {a4_data[12: 3],3'd0}; // ADR_10
    3'b0_11: b5_ins_const[12:0] <=                                                        13'd0; //
    3'b1_xx: b5_ins_const[12:0] <=                                       {6'd0,a4_evt_eid,3'd0}; //
    endcase 

    case(a4_cmod_mi)
    2'b00:  b5_ins_const[18:13] <=                                               a4_data[18:13]; // MX_MI_6
    2'b01:  b5_ins_const[18:13] <=                                             {6{a4_data[12]}}; // LO_SGN
    2'b10:  b5_ins_const[18:13] <=                                               a4_data[50:45]; // MX_HI_MI_6
    2'b11:  b5_ins_const[18:13] <=                                                         6'd0;
    endcase 

    case(a4_cmod_hi)
    3'b000: b5_ins_const[31:19] <=                                            {13{a4_data[12]}}; // LO_SGN
    3'b001: b5_ins_const[31:19] <=                                            {13{a4_data[18]}}; // MI_SGN
    3'b010: b5_ins_const[31:19] <=                            {{7{a4_data[24]}},a4_data[24:19]}; // SIG_6
    3'b011: b5_ins_const[31:19] <=                            {{7{1'b0       }},a4_data[24:19]}; // UNS_6
    3'b100: b5_ins_const[31:19] <=                                               a4_data[12: 0]; // LO_13
    3'b101: b5_ins_const[31:19] <=                                               a4_data[44:32]; // HI_13
    3'b110: b5_ins_const[31:19] <=                                                          'd0; // zero
    3'b111: b5_ins_const[31:19] <=                                                          'd0; // zero
    endcase 
  end  
//==============================================================================================   
// output
//==============================================================================================   
assign  o_stb           =                                                                b5_stb;
assign  o_tid           =                                                                b5_tid;
assign  o_asid          =                                                               b5_asid;
assign  o_pid           =                                                                b5_pid;
assign  o_isw           =                                                                b5_isw;
assign  o_isz           =                                                                b5_isz;
assign  o_iva           =                                                                b5_iva;     
assign  o_iop           =                                                            b5_ins_opc;     
assign  o_iex           =                                                                b5_iex;     
assign  o_erx           =                                                                b5_erx;     
assign  o_ins_cnd_ena   =                                                        b5_ins_cnd_ena;
assign  o_ins_cnd_val   =                                                        b5_ins_cnd_val;
assign  o_ins_rya       =                                                            b5_ins_rya;
assign  o_ins_ryz       =                                                            b5_ins_ryz;
assign  o_ins_opc       =                                                            b5_ins_opc;
assign  o_ins_const     =                                                          b5_ins_const;
assign  o_evt_req       =                                                            b5_evt_req;
assign  o_evt_eid       =                                                            b5_evt_eid;
//==============================================================================================   
// instruction cache manager
//==============================================================================================
eco32_core_ifu_icm_box
#
( 
.PAGE_ADDR_WIDTH(_PAGE_ADDR_WIDTH),
.FORCE_RST      (FORCE_RST)
)
icm_box
(
.clk                (clk),
.rst                (rst),
.rdy                (rdy_icm),

.req_stb            (a4_cr_stb && !a4_cr_cancel),
.req_tid            (a4_cr_tid),       
.req_wid            (a4_cr_wid),     
.req_tag            (a4_cr_tag),     
.req_asid           (4'd0),       
.req_v_addr         (a4_cr_iva),    
.req_rdy            (b3_cr_rdy),

.mm_wr_stb          (mm_wr_stb),
.mm_wr_tid          (mm_wr_tid),
.mm_wr_wid          (mm_wr_wid),
.mm_wr_page         (mm_wr_page),
.mm_wr_offset       (mm_wr_offset),
.mm_wr_data         (mm_wr_data), 

.pt_wr_stb          (pt_wr_stb),
.pt_wr_tid          (pt_wr_tid),
.pt_wr_wid          (pt_wr_wid),
.pt_wr_page         (pt_wr_page),
.pt_wr_descriptor   (pt_wr_descriptor),

.epp_i_stb          (epp_i_stb),
.epp_i_sof          (epp_i_sof),
.epp_i_data         (epp_i_data),

.epp_o_br           (epp_o_br),
.epp_o_bg           (epp_o_bg),

.epp_o_stb          (epp_o_stb),
.epp_o_sof          (epp_o_sof),   
.epp_o_iid          (epp_o_iid),
.epp_o_data         (epp_o_data),
.epp_o_rdy          (epp_o_rdy)
);                                  
//==============================================================================================   
// event manager
//==============================================================================================   
eco32_core_ifu_evm_box
#(
.FORCE_RST          (FORCE_RST)
)
 evm_box
(
.clk                (clk),
.rst                (rst),

.epp_i_stb          (epp_i_stb),
.epp_i_sof          (epp_i_sof),
.epp_i_data         (epp_i_data),

.sys_event_ena      (sys_event_ena),

.evt_th0_req        (evt_th0_req),
.evt_th0_eid        (evt_th0_eid),
.evt_th0_erx        (evt_th0_erx),
.evt_th0_ack        (evt_th0_ack),

.evt_th1_req        (evt_th1_req),
.evt_th1_eid        (evt_th1_eid),
.evt_th1_erx        (evt_th1_erx),
.evt_th1_ack        (evt_th1_ack),

.wrx                (o_wrx)
); 
//==============================================================================================   
endmodule