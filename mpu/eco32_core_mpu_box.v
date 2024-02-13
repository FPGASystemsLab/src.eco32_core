//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_mpu_box
(
 input  wire            clk,
 input  wire            rst,   
 
 // iput from IDU
 
 input  wire            i_stb,
 input  wire            i_tid,
 input  wire     [3:0]  i_asid,
 input  wire     [1:0]  i_pid,
 input  wire    [15:0]  i_isw,
 input  wire     [1:0]  i_isz,
 input  wire    [31:0]  i_iva,
 input  wire    [31:0]  i_iop,
 input  wire    [31:0]  i_iex,
 input  wire     [3:0]  i_erx,
 input  wire     [8:0]  i_wrx,
 input  wire            i_evt_req,
 input  wire     [2:0]  i_evt_eid,

 input  wire     [1:0]  i_ds_cw,     
 input  wire     [7:0]  i_cc_cw,     
 input  wire     [5:0]  i_ar_cw,     
 input  wire     [3:0]  i_lo_cw,                       
 input  wire    [20:0]  i_jp_cw,                                                                            
 input  wire     [9:0]  i_jp_arg, 
 input  wire     [4:0]  i_sh_cw,     
 input  wire     [4:0]  i_sh_val,     
 input  wire     [5:0]  i_mm_cw,     
 input  wire     [8:0]  i_cr_cw,     
 input  wire     [9:0]  i_bc_cw,     
 
 input  wire    [31:0]  i_r0_data,    
 input  wire            i_r0_locked,     
 
 input  wire    [31:0]  i_r1_data,     
 input  wire            i_r1_locked,     

 input  wire    [31:0]  i_r2_data,     
 input  wire            i_r2_locked,                        

 input  wire    [31:0]  i_r3_data,     
 input  wire            i_r3_locked,                        
 
 input  wire     [1:0]  i_ry_ena,
 input  wire     [4:0]  i_ry_addr,
 input  wire     [1:0]  i_ry_tag,
 input  wire     [1:0]  i_ry_locked,                        
 
 // output to all units
 
 input  wire            fci_inst_lsf,
 input  wire            fci_inst_jpf,  
 
 output wire            fco_inst_rep,
 
 output wire            fco_inst_skip,

 // register lock
 
 output wire     [1:0]  lc_ry_enaG,
 output wire     [1:0]  lc_ry_enaT0,
 output wire     [1:0]  lc_ry_enaT1,
 output wire     [4:0]  lc_ry_addr,     
 output wire     [1:0]  lc_ry_tag,     
 
 // cra:crb registers 8-15
 
 output wire     [1:0]  jcr_wen,
 output wire            jcr_tid,
 output wire     [3:0]  jcr_addr,
 output wire    [31:0]  jcr_dataL,
 output wire    [31:0]  jcr_dataH,
 
 // system flags
 
 output wire     [1:0]  sys_trace_ena,
 output wire     [1:0]  sys_event_ena,
 
 // write back (short path)
 
 output wire            wba_stb0,    
 output wire            wba_stb1,    
                                
 output wire     [1:0]  wba_enaA,             
 output wire            wba_tagA,             
                                             
 output wire     [1:0]  wba_enaB,             
 output wire            wba_tagB,             
 output wire            wba_modB,             
                                            
 output wire     [4:0]  wba_addr,            
 output wire    [31:0]  wba_dataL,
 output wire    [31:0]  wba_dataH,
 
 // write back (long path)
 
 output wire            wbb_stb0,    
 output wire            wbb_stb1,    
                               
 output wire     [1:0]  wbb_enaA,             
 output wire            wbb_tagA,             
                                             
 output wire     [1:0]  wbb_enaB,             
 output wire            wbb_tagB,             
 output wire            wbb_modB,             
                                            
 output wire     [4:0]  wbb_addr,            
 output wire    [31:0]  wbb_dataL,
 output wire    [31:0]  wbb_dataH,
 
 output wire            dbg_ins_stb, 
 output wire            dbg_ins_skp, 
 output wire            dbg_ins_tid,
 output wire     [1:0]  dbg_ins_pid, 
 output wire    [15:0]  dbg_ins_isw, 
 output wire    [31:0]  dbg_ins_iva, 
 output wire    [31:0]  dbg_ins_opc, 
 output wire            dbg_ins_ste,
 output wire    [31:0]  dbg_ins_ext, 
 output wire     [7:0]  dbg_ins_crs,
 output wire    [31:0]  dbg_ins_cra, 
 output wire    [31:0]  dbg_ins_crb, 
 output wire            dbg_ins_stf,
 output wire     [7:0]  dbg_ins_cfa, 
 output wire            dbg_ins_stl,
 output wire     [7:0]  dbg_ins_lck 
);                             
//==============================================================================================
// parameters
//==============================================================================================
parameter       PROCESSOR_ID    =   'h00000000;
parameter       PROCESSOR_CAP   =   'h00000000;
parameter   FORCE_RST     =          0;
//==============================================================================================
// cw assigments
//==============================================================================================
wire            f_ds_ena    =   i_ds_cw[0];
wire            f_ds_ce     =   i_ds_cw[1];
//
wire            f_sh_ena    =   i_sh_cw[0];
wire            f_sh_dir    =   i_sh_cw[1];
wire     [1:0]  f_sh_mode   =   i_sh_cw[3:2];
wire            f_sh_imm    =   i_sh_cw[4];

wire     [4:0]  f_sh_val    =   i_sh_val;
//
wire            f_ar_ena    =   i_ar_cw[0];
wire            f_ar_ce     =   i_ar_cw[1];
wire            f_ar_opcL   =   i_ar_cw[2];
wire            f_ar_opcH   =   i_ar_cw[3];
wire            f_ar_us     =   i_ar_cw[4];
wire            f_ar_abs    =   i_ar_cw[5];
//
wire            f_lo_ena    =   i_lo_cw[0];
wire     [2:0]  f_lo_opc    =   i_lo_cw[3:1];
//
wire            f_mm_ena    =   i_mm_cw[0];      
wire            f_mm_mod    =   i_mm_cw[1];
wire            f_mm_p0     =   i_mm_cw[2];
wire            f_mm_p1     =   i_mm_cw[3];
wire     [1:0]  f_mm_opc    =   i_mm_cw[5:4];
//
wire            f_cr_ena    =   i_cr_cw[0];      
wire            f_cr_wen    =   i_cr_cw[1];      
wire     [1:0]  f_cr_bank   =   i_cr_cw[3:2];      
wire     [4:0]  f_cr_addr   =   i_cr_cw[8:4];      
//
wire            f_jp_ena    =   i_jp_cw[ 0];     
wire            f_jp_link   =   i_jp_cw[ 6];
wire            f_jp_ia     =   i_jp_cw[ 4];
wire     [9:0]  f_jp_arg    =   i_jp_arg;
//
wire            f_bc_ena    =   i_bc_cw[0];
wire            f_bc_clo    =   i_bc_cw[1];
wire     [2:0]  f_bc_cL     =   i_bc_cw[4:2];
wire     [2:0]  f_bc_cH     =   i_bc_cw[7:5];
wire     [1:0]  f_bc_opc    =   i_bc_cw[9:8];
//
wire            f_cc_chk    =   i_cc_cw[7];
wire            f_cc_set    =   i_cc_cw[6];
wire            f_cc_neg    =   i_cc_cw[5];
wire     [3:0]  f_cc_sel    =   i_cc_cw[4:1];       
wire            f_cc_ena    =   i_cc_cw[0];
//==============================================================================================
// variables
//==============================================================================================
(* shreg_extract = "NO"  *) reg             a0_stb;                                                                                                                       
(* shreg_extract = "NO"  *) reg             a0_rep;
(* shreg_extract = "NO"  *) reg             a0_tid;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_pid;
(* shreg_extract = "NO"  *) reg      [5:0]  a0_asid;
(* shreg_extract = "NO"  *) reg     [15:0]  a0_isw;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_isz;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_iva;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_iop;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_iex;
(* shreg_extract = "NO"  *) reg      [3:0]  a0_erx;
(* shreg_extract = "NO"  *) reg      [8:0]  a0_wrx;

(* shreg_extract = "NO"  *) reg      [1:0]  a0_ry_ena;
(* shreg_extract = "NO"  *) reg      [4:0]  a0_ry_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_ry_data;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_ry_tag;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_ry_mux;

(* shreg_extract = "NO"  *) reg             a0_lck_ry_stb;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_lck_ry_enaG;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_lck_ry_enaT0;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_lck_ry_enaT1;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_lck_ry_ena;
(* shreg_extract = "NO"  *) reg      [4:0]  a0_lck_ry_addr;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_lck_ry_tag;

(* shreg_extract = "NO"  *) reg     [31:0]  a0_r0_data;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_r1_data;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_r2_data;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_r3_data;

(* shreg_extract = "NO"  *) reg      [7:0]  a0_fg_lo_z; 
(* shreg_extract = "NO"  *) reg      [7:0]  a0_fg_ar_z; 
(* shreg_extract = "NO"  *) reg             a0_fg_fl_z; 
(* shreg_extract = "NO"  *) reg             a0_fg_fl_s; 
(* shreg_extract = "NO"  *) reg             a0_fg_fl_nan;  
(* shreg_extract = "NO"  *) reg             a0_fg_fl_inf;  
(* shreg_extract = "NO"  *) reg             a0_fg_fl_norm;

(* shreg_extract = "NO"  *) reg             a0_ar_ena;
(* shreg_extract = "NO"  *) reg             a0_ar_ce;
(* shreg_extract = "NO"  *) reg             a0_ar_us;
(* shreg_extract = "NO"  *) reg             a0_ar_opc;              
(* shreg_extract = "NO"  *) reg             a0_ar_ovs;
(* shreg_extract = "NO"  *) reg             a0_ar_sign;
(* shreg_extract = "NO"  *) reg     [32:0]  a0_ar_dataL;
(* shreg_extract = "NO"  *) reg     [32:0]  a0_ar_dataH;

(* shreg_extract = "NO"  *) reg             a0_lo_ena;
(* shreg_extract = "NO"  *) reg      [2:0]  a0_lo_opc;      
(* shreg_extract = "NO"  *) reg     [31:0]  a0_lo_dataL;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_lo_dataH;

(* shreg_extract = "NO"  *) reg             a0_jp_ena;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_jp_dataL;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_jp_dataH;

(* shreg_extract = "NO"  *) reg             a0_ds_ena;
(* shreg_extract = "NO"  *) reg             a0_ds_cout;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_ds_dataL;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_ds_dataH;

(* shreg_extract = "NO"  *) reg             a0_mm_ena;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_mm_opc;
(* shreg_extract = "NO"  *) reg             a0_mm_p0;
(* shreg_extract = "NO"  *) reg             a0_mm_p1;
(* shreg_extract = "NO"  *) reg             a0_mm_mod;
(* shreg_extract = "NO"  *) reg             a0_mm_cval;
(* shreg_extract = "NO"  *) reg     [33:0]  a0_mm_arg_a;
(* shreg_extract = "NO"  *) reg     [33:0]  a0_mm_arg_b;
(* shreg_extract = "NO"  *) reg     [33:0]  a0_mm_arg_c;
(* shreg_extract = "NO"  *) reg     [33:0]  a0_mm_arg_d;
(* shreg_extract = "NO"  *) reg             a0_mm_arL_b32;

(* shreg_extract = "NO"  *) reg             a0_cr_ena;
(* shreg_extract = "NO"  *) reg      [4:0]  a0_cr_addr;
(* shreg_extract = "NO"  *) reg             a0_cr_ren;
(* shreg_extract = "NO"  *) reg             a0_cr_cra0_wen;
(* shreg_extract = "NO"  *) reg             a0_cr_cra0_ren;
(* shreg_extract = "NO"  *) reg             a0_cr_cr6_ren;
(* shreg_extract = "NO"  *) reg             a0_cr_cr7_ren;
(* shreg_extract = "NO"  *) reg             a0_cr_cr15_ren;
(* shreg_extract = "NO"  *) reg             a0_cr_scr_wen_a;
(* shreg_extract = "NO"  *) reg             a0_cr_scr_wen_b;
(* shreg_extract = "NO"  *) reg             a0_cr_scr_wen_i;
                            wire    [31:0]  a0_cr_data_a;
                            wire    [31:0]  a0_cr_data_b;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_cr_jcr_wen;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_cr_jcr_data_L;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_cr_jcr_data_H;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_cr_data_L;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_cr_data_H;

(* shreg_extract = "NO"  *) reg             a0_bc_ena;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_bc_opc;
(* shreg_extract = "NO"  *) reg      [2:0]  a0_bc_cL;
(* shreg_extract = "NO"  *) reg      [2:0]  a0_bc_cH;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_bc_data;
(* shreg_extract = "NO"  *) reg      [7:0]  a0_bc_nibble;

(* shreg_extract = "NO"  *) reg             a0_sh_ena;
(* shreg_extract = "NO"  *) reg             a0_sh_m2;
(* shreg_extract = "NO"  *) reg             a0_sh_a1;
(* shreg_extract = "NO"  *) reg             a0_sh_clb;
(* shreg_extract = "NO"  *) reg             a0_sh_slb;
(* shreg_extract = "NO"  *) reg             a0_sh_imm;
(* shreg_extract = "NO"  *) reg             a0_sh_sign;
(* shreg_extract = "NO"  *) reg             a0_sh_dir;
(* shreg_extract = "NO"  *) reg      [5:0]  a0_sh_lb;       
(* shreg_extract = "NO"  *) reg      [7:0]  a0_sh_tmp;      
(* shreg_extract = "NO"  *) reg      [5:0]  a0_sh_cnt;      
(* shreg_extract = "NO"  *) reg     [63:0]  a0_sh_data;     

(* shreg_extract = "NO"  *) reg             a0_cc_ena;
(* shreg_extract = "NO"  *) reg             a0_cc_fme;
(* shreg_extract = "NO"  *) reg             a0_cc_set;
(* shreg_extract = "NO"  *) reg             a0_cc_chk;
(* shreg_extract = "NO"  *) reg             a0_cc_val;
(* shreg_extract = "NO"  *) reg             a0_cc_skip;

(* shreg_extract = "NO"  *) reg             a0_dbg_ena;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b1_dbg_stb;
(* shreg_extract = "NO"  *) reg             b1_dbg_skp;
(* shreg_extract = "NO"  *) reg             b1_dbg_tid;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_dbg_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  b1_dbg_isw;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_dbg_iva;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_dbg_opc;
(* shreg_extract = "NO"  *) reg             b1_dbg_ste;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_dbg_ext;
(* shreg_extract = "NO"  *) reg             b1_dbg_stl;
(* shreg_extract = "NO"  *) reg      [7:0]  b1_dbg_lck;            
(* shreg_extract = "NO"  *) reg      [7:0]  b1_dbg_crs;            
(* shreg_extract = "NO"  *) reg     [31:0]  b1_dbg_cra;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_dbg_crb;

                            wire            b1_dbg_cf_stb;
                            wire     [6:0]  b1_dbg_cf_data;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b1_stb_SP;
(* shreg_extract = "NO"  *) reg             b1_stb_LP;
(* shreg_extract = "NO"  *) reg      [3:0]  b1_asid;
(* shreg_extract = "NO"  *) reg             b1_tid;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  b1_isw;
(* shreg_extract = "NO"  *) reg      [3:0]  b1_erx;
(* shreg_extract = "NO"  *) reg      [8:0]  b1_wrx;

(* shreg_extract = "NO"  *) reg     [31:0]  b1_r0_data;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_r1_data;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_r2_data;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_r3_data;

(* shreg_extract = "NO"  *) reg      [1:0]  b1_ry_ena;
(* shreg_extract = "NO"  *) reg      [4:0]  b1_ry_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_ry_dataL;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_ry_dataH;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_ry_tag;
(* shreg_extract = "NO"  *) reg      [2:0]  b1_ry_mux;

(* shreg_extract = "NO"  *) reg             b1_sh_ena;
(* shreg_extract = "NO"  *) reg             b1_sh_slb;
(* shreg_extract = "NO"  *) reg             b1_sh_clb;              
(* shreg_extract = "NO"  *) reg             b1_sh_dir;              
(* shreg_extract = "NO"  *) reg      [5:0]  b1_sh_cnt;              
(* shreg_extract = "NO"  *) reg     [31:0]  b1_sh_lb;               
(* shreg_extract = "NO"  *) reg     [63:0]  b1_sh_data;

(* shreg_extract = "NO"  *) reg             b1_bc_ena;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_bc_opc;
(* shreg_extract = "NO"  *) reg      [2:0]  b1_bc_cL;
(* shreg_extract = "NO"  *) reg      [2:0]  b1_bc_cH;
(* shreg_extract = "NO"  *) reg      [5:0]  b1_bc_cnt4;
(* shreg_extract = "NO"  *) reg      [5:0]  b1_bc_cnt8;
(* shreg_extract = "NO"  *) reg      [5:0]  b1_bc_cnt16;
(* shreg_extract = "NO"  *) reg      [5:0]  b1_bc_tmp8;

(* shreg_extract = "NO"  *) reg             b1_mm_ena;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_mm_opc;
(* shreg_extract = "NO"  *) reg             b1_mm_mod;
(* shreg_extract = "NO"  *) reg             b1_mm_cval;
(* shreg_extract = "NO"  *) reg             b1_mm_p0;
(* shreg_extract = "NO"  *) reg             b1_mm_min;
(* shreg_extract = "NO"  *) reg     [33:0]  b1_mm_arg_a;
(* shreg_extract = "NO"  *) reg     [33:0]  b1_mm_arg_b;
(* shreg_extract = "NO"  *) reg     [33:0]  b1_mm_arg_c;
(* shreg_extract = "NO"  *) reg     [33:0]  b1_mm_arg_d;
(* shreg_extract = "NO"  *) reg      [8:0]  b1_mm_dbL0;
(* shreg_extract = "NO"  *) reg      [8:0]  b1_mm_dbL1;
(* shreg_extract = "NO"  *) reg      [8:0]  b1_mm_dbL2;
(* shreg_extract = "NO"  *) reg      [8:0]  b1_mm_dbL3;
(* shreg_extract = "NO"  *) reg      [8:0]  b1_mm_dbH0;
(* shreg_extract = "NO"  *) reg      [8:0]  b1_mm_dbH1;
(* shreg_extract = "NO"  *) reg      [8:0]  b1_mm_dbH2;
(* shreg_extract = "NO"  *) reg      [8:0]  b1_mm_dbH3;

(* shreg_extract = "NO"  *) reg             b1_cr_ena;
(* shreg_extract = "NO"  *) reg             b1_cr_cr6_ena;
(* shreg_extract = "NO"  *) reg             b1_cr_cr7_ena;
(* shreg_extract = "NO"  *) reg             b1_cr_cr15_ena;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_cr_data_a;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_cr_data_b;
                            wire    [31:0]  b1_cr_erx_a;
                            wire    [31:0]  b1_cr_erx_b;

(* shreg_extract = "NO"  *) reg             b1_cc_ena;
                            wire    [15:0]  b1_cc_flags;        
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             a2_stb_SP;
(* shreg_extract = "NO"  *) reg             a2_stb_LP;
(* shreg_extract = "NO"  *) reg             a2_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  a2_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  a2_isw;

(* shreg_extract = "NO"  *) reg             a2_cnt_ena;

(* shreg_extract = "NO"  *) reg             a2_cr_ena;
(* shreg_extract = "NO"  *) reg             a2_cr_cr6_ena;
(* shreg_extract = "NO"  *) reg             a2_cr_cr7_ena;
(* shreg_extract = "NO"  *) reg             a2_cr_cr15_ena;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_cr_data_a;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_cr_data_b;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_cr_erx_a;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_cr_erx_b;

(* shreg_extract = "NO"  *) reg             a2_mm_ena;
(* shreg_extract = "NO"  *) reg             a2_mm_cval;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_mm_opc;
(* shreg_extract = "NO"  *) reg             a2_mm_p0;
(* shreg_extract = "NO"  *) reg             a2_mm_sel;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_mm_dataL;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_mm_dataH;
(* shreg_extract = "NO"  *) reg     [10:0]  a2_mm_sL;
(* shreg_extract = "NO"  *) reg     [10:0]  a2_mm_sH;

(* shreg_extract = "NO"  *) reg             a2_bc_ena;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_bc_opc;
(* shreg_extract = "NO"  *) reg      [2:0]  a2_bc_cL;
(* shreg_extract = "NO"  *) reg      [2:0]  a2_bc_cH;
(* shreg_extract = "NO"  *) reg      [6:0]  a2_bc_cnt;

(* shreg_extract = "NO"  *) reg             a2_cc_ena;
(* shreg_extract = "NO"  *) reg     [15:0]  a2_cc_flags;

(* shreg_extract = "NO"  *) reg             a2_ry_stb0;
(* shreg_extract = "NO"  *) reg             a2_ry_stb1;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_ry_enaA;
(* shreg_extract = "NO"  *) reg             a2_ry_tagA;

(* shreg_extract = "NO"  *) reg      [1:0]  a2_ry_enaB;
(* shreg_extract = "NO"  *) reg             a2_ry_modB;
(* shreg_extract = "NO"  *) reg             a2_ry_tagB;

(* shreg_extract = "NO"  *) reg      [4:0]  a2_ry_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_ry_dataL;    
(* shreg_extract = "NO"  *) reg     [31:0]  a2_ry_dataH;                                                         

(* shreg_extract = "NO"  *) reg      [1:0]  a2_ry_ena;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_ry_tag;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_ry_mux;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b3_stb;
(* shreg_extract = "NO"  *) reg             b3_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  b3_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  b3_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  b3_isw;

(* shreg_extract = "NO"  *) reg             b3_cr_cr6_ena;

(* shreg_extract = "NO"  *) reg             b3_mm_ena;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_mm_dataL;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_mm_dataH;

(* shreg_extract = "NO"  *) reg             b3_bc_ena;
(* shreg_extract = "NO"  *) reg      [6:0]  b3_bc_cntL;
(* shreg_extract = "NO"  *) reg      [6:0]  b3_bc_cntH;

(* shreg_extract = "NO"  *) reg      [1:0]  b3_ry_ena;
(* shreg_extract = "NO"  *) reg             b3_ry_mcr;
(* shreg_extract = "NO"  *) reg      [4:0]  b3_ry_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_ry_dataL;   
(* shreg_extract = "NO"  *) reg     [31:0]  b3_ry_dataH;  
(* shreg_extract = "NO"  *) reg      [1:0]  b3_ry_tag;
(* shreg_extract = "NO"  *) reg      [1:0]  b3_ry_mux;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             a4_stb;
(* shreg_extract = "NO"  *) reg             a4_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  a4_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  a4_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  a4_isw;

(* shreg_extract = "NO"  *) reg             a4_cr_cr6_ena;
(* shreg_extract = "NO"  *) reg     [32:0]  a4_cr_cnt_L;
(* shreg_extract = "NO"  *) reg     [31:0]  a4_cr_cnt_H;

(* shreg_extract = "NO"  *) reg      [1:0]  a4_ry_ena;
(* shreg_extract = "NO"  *) reg             a4_ry_mcr;
(* shreg_extract = "NO"  *) reg      [4:0]  a4_ry_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  a4_ry_dataL;  
(* shreg_extract = "NO"  *) reg     [31:0]  a4_ry_dataH; 
(* shreg_extract = "NO"  *) reg      [1:0]  a4_ry_tag;
(* shreg_extract = "NO"  *) reg      [1:0]  a4_ry_mux;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b5_stb;
(* shreg_extract = "NO"  *) reg             b5_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  b5_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  b5_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  b5_isw;

(* shreg_extract = "NO"  *) reg             b5_ry_stb0;
(* shreg_extract = "NO"  *) reg             b5_ry_stb1;
(* shreg_extract = "NO"  *) reg      [1:0]  b5_ry_enaA;
(* shreg_extract = "NO"  *) reg             b5_ry_tagA;

(* shreg_extract = "NO"  *) reg      [1:0]  b5_ry_enaB;
(* shreg_extract = "NO"  *) reg             b5_ry_modB;
(* shreg_extract = "NO"  *) reg             b5_ry_tagB;

(* shreg_extract = "NO"  *) reg      [4:0]  b5_ry_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  b5_ry_dataL; 
(* shreg_extract = "NO"  *) reg     [31:0]  b5_ry_dataH; 
//----------------------------------------------------------------------------------------------
                            wire     [3:0]  sys_asid;
//==============================================================================================
// regisrer locking
//==============================================================================================
wire            f_dst_valid     =                            !(i_ry_locked[1] | i_ry_locked[0]);
wire            f_src_valid     =   !(i_r0_locked || i_r1_locked || i_r2_locked || i_r3_locked);
wire            f_all_valid     =                                    f_dst_valid && f_src_valid;
//----------------------------------------------------------------------------------------------
wire            f_stb_valid     =                         f_all_valid && i_stb && !fci_inst_jpf;
wire            f_rep_valid     =                        !f_all_valid && i_stb && !fci_inst_jpf;
wire            f_loc_valid     =                         f_all_valid && i_stb && !fci_inst_jpf;
//==============================================================================================
// stage a(0): 
//==============================================================================================
wire            f_norm          =                                               b1_cc_flags[10];
wire            f_nan           =                                               b1_cc_flags[ 9];
wire            f_inf           =                                               b1_cc_flags[ 8];
//----------------------------------------------------------------------------------------------
wire            f_s             =                                               b1_cc_flags[ 3];
wire            f_o             =                                               b1_cc_flags[ 2];
wire            f_c             =                                               b1_cc_flags[ 1];
wire            f_z             =                                               b1_cc_flags[ 0];
//==============================================================================================
reg             f_cc_val;
//----------------------------------------------------------------------------------------------
always@(*) case(f_cc_sel)
4'h0:           f_cc_val        =                                  (          1'b1); // true
4'h1:           f_cc_val        =                                  (   f_c ||  f_z); // <=
4'h2:           f_cc_val        =                                  (  !f_c ||  f_z); // >=
4'h3:           f_cc_val        =                                  (          1'b1); // -
    
4'h4:           f_cc_val        =                                  (           f_z); // zero 
4'h5:           f_cc_val        =                                  (           f_c); // carry
4'h6:           f_cc_val        =                                  (           f_o); // overflow
4'h7:           f_cc_val        =                                  (           f_s); // sign
    
4'h8:           f_cc_val        =                                  (          1'b1); // -
4'h9:           f_cc_val        =                                  (          1'b1); // -
4'hA:           f_cc_val        =                                  (          1'b1); // -
4'hB:           f_cc_val        =                                  (          1'b1); // -
    
4'hC:           f_cc_val        =                                  (         f_inf); // inf
4'hD:           f_cc_val        =                                  (         f_nan); // nan
4'hE:           f_cc_val        =                                  (        f_norm); // norm
4'hF:           f_cc_val        =                                  (          1'b1); // -
endcase 
//==============================================================================================
// AR unit
//==============================================================================================
wire    [33:0]  f_arg_a         =          {!f_ar_us & i_r0_data[31],i_r0_data,~f_ar_opcL     };
wire    [33:0]  f_arg_b         =          {!f_ar_us & i_r2_data[31],i_r2_data, f_ar_ce & f_c };
//----------------------------------------------------------------------------------------------
wire    [33:0]  f_arg_c         =          {!f_ar_us & i_r1_data[31],i_r1_data, 1'b0          };
wire    [33:0]  f_arg_d         =          {!f_ar_us & i_r3_data[31],i_r3_data, 1'b0          };
//----------------------------------------------------------------------------------------------  
wire            f_ar_modeL      =  f_ar_abs ?                        !i_r2_data[31] : f_ar_opcL; 
wire            f_ar_modeH      =  f_ar_abs ?                        !i_r3_data[31] : f_ar_opcH; 
//----------------------------------------------------------------------------------------------  
wire    [33:0]  f_ar_dataL      = (f_ar_modeL) ?          f_arg_a + f_arg_b : f_arg_a - f_arg_b;
wire    [33:0]  f_ar_dataH      = (f_ar_modeH) ?          f_arg_c + f_arg_d : f_arg_c - f_arg_d;
//----------------------------------------------------------------------------------------------
wire      [7:0] f_ar_zero;
//----------------------------------------------------------------------------------------------
assign          f_ar_zero[7]    =                                          (|f_ar_dataL[32:28]);
assign          f_ar_zero[6]    =                                          (|f_ar_dataL[27:24]);
assign          f_ar_zero[5]    =                                          (|f_ar_dataL[23:20]);
assign          f_ar_zero[4]    =                                          (|f_ar_dataL[19:16]);
assign          f_ar_zero[3]    =                                          (|f_ar_dataL[15:12]);
assign          f_ar_zero[2]    =                                          (|f_ar_dataL[11: 8]);
assign          f_ar_zero[1]    =                                          (|f_ar_dataL[ 7: 4]);
assign          f_ar_zero[0]    =                                          (|f_ar_dataL[ 3: 1]);
//==============================================================================================    
// LO unit
//==============================================================================================    
reg     [31:0]  f_lo_dataL;
//----------------------------------------------------------------------------------------------
always@(*) case(f_lo_opc)
3'd0:           f_lo_dataL      =                                      i_r0_data &  i_r2_data ;// and
3'd1:           f_lo_dataL      =                                      i_r0_data ^  i_r2_data ;// xor
3'd2:           f_lo_dataL      =                                      i_r0_data |  i_r2_data ;// or
3'd3:           f_lo_dataL      =                                                   i_r2_data ;// move
3'd4:           f_lo_dataL      =                                      i_r0_data & ~i_r2_data ;// and
3'd5:           f_lo_dataL      =                                      i_r0_data ^ ~i_r2_data ;// xor
3'd6:           f_lo_dataL      =                                      i_r0_data | ~i_r2_data ;// or
3'd7:           f_lo_dataL      =                                                  ~i_r2_data ;// move
endcase                           
//----------------------------------------------------------------------------------------------
reg     [31:0]  f_lo_dataH;
//----------------------------------------------------------------------------------------------
always@(*) case(f_lo_opc)
3'd0:           f_lo_dataH      =                                      i_r1_data &  i_r3_data ;// and
3'd1:           f_lo_dataH      =                                      i_r1_data ^  i_r3_data ;// xor
3'd2:           f_lo_dataH      =                                      i_r1_data |  i_r3_data ;// or
3'd3:           f_lo_dataH      =                                                   i_r3_data ;// move
3'd4:           f_lo_dataH      =                                      i_r1_data & ~i_r3_data ;// and
3'd5:           f_lo_dataH      =                                      i_r1_data ^ ~i_r3_data ;// xor
3'd6:           f_lo_dataH      =                                      i_r1_data | ~i_r3_data ;// or
3'd7:           f_lo_dataH      =                                                  ~i_r3_data ;// move
endcase                           
//----------------------------------------------------------------------------------------------
wire     [7:0]  f_lo_zero;
//----------------------------------------------------------------------------------------------
assign          f_lo_zero[7]    =                                         !(|f_lo_dataL[31:28]);
assign          f_lo_zero[6]    =                                         !(|f_lo_dataL[27:24]);
assign          f_lo_zero[5]    =                                         !(|f_lo_dataL[23:20]);
assign          f_lo_zero[4]    =                                         !(|f_lo_dataL[19:16]);
assign          f_lo_zero[3]    =                                         !(|f_lo_dataL[15:12]);
assign          f_lo_zero[2]    =                                         !(|f_lo_dataL[11: 8]);
assign          f_lo_zero[1]    =                                         !(|f_lo_dataL[ 7: 4]);
assign          f_lo_zero[0]    =                                         !(|f_lo_dataL[ 3: 0]);
//==============================================================================================    
wire            f_fl_sign       =                                             i_r1_data[   31] ;    
wire            f_fl_zero       =                                         !(| i_r1_data[30:23]); // denormalized floats treated as zero   
wire            f_fl_nan        =                 (|i_r1_data[22:0])   &&  (& i_r1_data[30:23]); 
wire            f_fl_inf        =                !(|i_r1_data[22:0])   &&  (& i_r1_data[30:23]);
wire            f_fl_denorm     =                 (|i_r1_data[22:0])   && !(| i_r1_data[30:23]);
//==============================================================================================    
wire    [9:0]   f_jp_funID      =   (f_jp_ia       )?                   {f_jp_arg,2'd0} + 10'd4: 
                                                                  {i_r3_data[9:0],2'd0} + 10'd4;
//----------------------------------------------------------------------------------------------   
wire            f_ins_enable    =                         f_loc_valid && !fci_inst_jpf && i_stb;
//----------------------------------------------------------------------------------------------                                         
function [3:0] dcdt2;
input [3:0] x;

dcdt2   =   (x == 4'h0) ?   {1'b0,3'h0}:
            (x == 4'h1) ?   {1'b0,3'h1}:
            (x == 4'h2) ?   {1'b0,3'h2}:
            (x == 4'h3) ?   {1'b0,3'h3}:
            (x == 4'h4) ?   {1'b0,3'h4}:
            (x == 4'h5) ?   {1'b1,3'h0}:
            (x == 4'h6) ?   {1'b1,3'h1}:
            (x == 4'h7) ?   {1'b1,3'h2}:
            (x == 4'h8) ?   {1'b1,3'h3}:
                            {1'b1,3'h4};
endfunction
//==============================================================================================    
wire    [7:0]   f_bc_nibble;
//----------------------------------------------------------------------------------------------                                         
assign          f_bc_nibble[7]  = f_bc_clo ?           &i_r2_data[31:28] : &(~i_r2_data[31:28]);
assign          f_bc_nibble[6]  = f_bc_clo ?           &i_r2_data[27:24] : &(~i_r2_data[27:24]);
assign          f_bc_nibble[5]  = f_bc_clo ?           &i_r2_data[23:20] : &(~i_r2_data[23:20]);
assign          f_bc_nibble[4]  = f_bc_clo ?           &i_r2_data[19:16] : &(~i_r2_data[19:16]);
assign          f_bc_nibble[3]  = f_bc_clo ?           &i_r2_data[15:12] : &(~i_r2_data[15:12]);
assign          f_bc_nibble[2]  = f_bc_clo ?           &i_r2_data[11: 8] : &(~i_r2_data[11: 8]);
assign          f_bc_nibble[1]  = f_bc_clo ?           &i_r2_data[ 7: 4] : &(~i_r2_data[ 7: 4]);
assign          f_bc_nibble[0]  = f_bc_clo ?           &i_r2_data[ 3: 0] : &(~i_r2_data[ 3: 0]);
//==============================================================================================    
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    a0_stb                  <=                                                             1'b0;
    a0_rep                  <=                                                             1'b0;
    a0_tid                  <=                                                             1'b0;
    a0_asid                 <=                                                             4'b0;
    a0_pid                  <=                                                             2'b0;
    a0_isw                  <=                                                            16'b0;        
    a0_isz                  <=                                                             2'b0;        
    a0_iva                  <=                                                              'b0;
    a0_iop                  <=                                                              'b0;
    a0_iex                  <=                                                              'b0;
    a0_erx                  <=                                                              'b0;
    a0_wrx                  <=                                                              'b0;

    a0_ry_ena               <=                                                             2'd0;
    a0_ry_addr              <=                                                             5'd0;
    a0_ry_data              <=                                                            32'd0;
    a0_ry_tag               <=                                                             2'd0;
    a0_ry_mux               <=                                                             2'd0;
    
    a0_lck_ry_stb           <=                                                             1'd0;
    a0_lck_ry_enaG          <=                                                             2'd0;
    a0_lck_ry_enaT0         <=                                                             2'd0;
    a0_lck_ry_enaT1         <=                                                             2'd0;
    a0_lck_ry_ena           <=                                                             2'd0;
    a0_lck_ry_addr          <=                                                             5'd0;
    a0_lck_ry_tag           <=                                                             2'd0;
    
    a0_r0_data              <=                                                            32'd0;
    a0_r1_data              <=                                                            32'd0;
    a0_r2_data              <=                                                            32'd0;
    a0_r3_data              <=                                                            32'd0;

    a0_ar_ena               <=                                                             1'd0;
    a0_ar_ce                <=                                                             1'd0;
    a0_ar_us                <=                                                             1'd0;
    a0_ar_opc               <=                                                             1'd0;
    a0_ar_ovs               <=                                                             1'b0;
    a0_ar_sign              <=                                                             1'b0;
    a0_ar_dataL             <=                                                            33'd0;
    a0_ar_dataL             <=                                                            33'd0;

    a0_lo_ena               <=                                                             1'd0;
    a0_lo_opc               <=                                                             3'd0;
    a0_lo_dataL             <=                                                            32'd0;
    a0_lo_dataH             <=                                                            32'd0;

    a0_jp_ena               <=                                                             1'd0;
    a0_jp_dataL             <=                                                            32'd0;
    a0_jp_dataH             <=                                                            32'd0;
    
    a0_ds_ena               <=                                                             1'd0;
    a0_ds_dataL             <=                                                            32'd0;
    a0_ds_dataH             <=                                                            32'd0;
    
    a0_mm_ena               <=                                                             1'd0;
    a0_mm_opc               <=                                                             2'd0;
    a0_mm_p0                <=                                                             1'd0;
    a0_mm_p1                <=                                                             1'd0;
    a0_mm_mod               <=                                                             1'd0;
    a0_mm_cval              <=                                                             1'd0;
    a0_mm_arg_a             <=                                                            34'd0;
    a0_mm_arg_b             <=                                                            34'd0;
    a0_mm_arg_c             <=                                                            34'd0;
    a0_mm_arg_d             <=                                                            34'd0;
    a0_mm_arL_b32           <=                                                             1'd0;

    a0_cr_ena               <=                                                             1'd0;
    a0_cr_addr              <=                                                             5'd0;
    a0_cr_ren               <=                                                             1'd0;
    a0_cr_cr6_ren           <=                                                              'b0;
    a0_cr_cr7_ren           <=                                                              'b0;
    a0_cr_cr15_ren          <=                                                              'b0;
    a0_cr_cra0_ren          <=                                                             1'd0;
    a0_cr_cra0_wen          <=                                                             1'd0;
    a0_cr_scr_wen_a         <=                                                             1'd0;
    a0_cr_scr_wen_b         <=                                                             1'd0;
    a0_cr_jcr_wen           <=                                                             1'd0;
    a0_cr_jcr_data_L        <=                                                              'd0;
    a0_cr_jcr_data_H        <=                                                              'd0;
    a0_cr_data_L            <=                                                              'd0;
    a0_cr_data_H            <=                                                              'd0;
    
    a0_bc_ena               <=                                                             1'd0;
    a0_bc_cL                <=                                                             3'd0;
    a0_bc_cH                <=                                                             3'd0;
    a0_bc_opc               <=                                                             2'd0;
    a0_bc_data              <=                                                            32'd0;
    a0_bc_nibble            <=                                                             8'd0;
    
    a0_sh_ena               <=                                                             1'd0;
    a0_sh_sign              <=                                                             1'd0;
    a0_sh_m2                <=                                                             1'd0;
    a0_sh_a1                <=                                                             1'd0;
    a0_sh_clb               <=                                                             1'd0;
    a0_sh_slb               <=                                                             1'd0;
    a0_sh_imm               <=                                                             1'd0;
    a0_sh_sign              <=                                                             2'd0;
    a0_sh_dir               <=                                                             2'd0;
    a0_sh_lb                <=                                                             6'd0;
    a0_sh_tmp               <=                                                             8'd0;
    a0_sh_cnt               <=                                                             6'd0;
    a0_sh_data              <=                                                            64'd0;
    
    a0_fg_fl_nan            <=                                                             1'b0;
    a0_fg_fl_inf            <=                                                             1'b0;
    a0_fg_fl_norm           <=                                                             1'b0;
    a0_fg_fl_s              <=                                                             1'b0;
    a0_fg_fl_z              <=                                                             1'b0;
    a0_fg_lo_z              <=                                                             8'b0;
    a0_fg_ar_z              <=                                                             8'b0;
    
    a0_cc_ena               <=                                                             1'd0;
    a0_cc_fme               <=                                                             1'd0;
    a0_cc_set               <=                                                             1'd0;
    a0_cc_chk               <=                                                             1'd0;
    a0_cc_val               <=                                                             1'd0;
    a0_cc_skip              <=                                                             1'd0;

    a0_dbg_ena              <=                                                             1'd0;
  end
 else
  begin
    a0_stb                  <=                            f_loc_valid && !fci_inst_jpf && i_stb;
    a0_rep                  <=                           !f_loc_valid && !fci_inst_jpf && i_stb;        
    a0_tid                  <=                                                            i_tid;
    a0_asid                 <=                                                           i_asid;
    a0_pid                  <=                                                            i_pid;
    a0_isw                  <=                                                            i_isw;        
    a0_isz                  <=                                                            i_isz;        
    a0_iva                  <=                                                            i_iva;        
    a0_iop                  <=                                                            i_iop;        
    a0_iex                  <=                                                            i_iex;        
    a0_erx                  <=                                                            i_erx;        
    a0_wrx                  <=                                                            i_wrx;        
        
    a0_lck_ry_stb           <=                     f_ins_enable && (|i_ry_ena) && f_loc_valid  ;
    a0_lck_ry_enaG          <=              i_ry_ena & {2{i_stb                && f_loc_valid}};
    a0_lck_ry_enaT0         <=              i_ry_ena & {2{i_stb && i_tid==1'b0 && f_loc_valid}};
    a0_lck_ry_enaT1         <=              i_ry_ena & {2{i_stb && i_tid==1'b1 && f_loc_valid}};
    a0_lck_ry_ena           <=              i_ry_ena & {2{                        f_loc_valid}};
    a0_lck_ry_addr          <=                                                        i_ry_addr;
    a0_lck_ry_tag           <=                                                         i_ry_tag;

    a0_r0_data              <=                                                        i_r0_data;
    a0_r1_data              <=                                                        i_r1_data;
    a0_r2_data              <=                                                        i_r2_data;
    a0_r3_data              <=                                                        i_r3_data;

    a0_ar_ena               <=                                         f_ins_enable && f_ar_ena;
    a0_ar_ce                <=                                                          f_ar_ce;               
    a0_ar_us                <=                                                          f_ar_us;               
    a0_ar_opc               <=                                                        f_ar_opcL;
    a0_ar_ovs               <=                     i_r0_data[31] ^ (~f_ar_opcL ^ i_r1_data[31]);
    a0_ar_sign              <=                                                    i_r0_data[31];
    a0_ar_dataL             <=                                                 f_ar_dataL[33:1]; 
    a0_ar_dataH             <=                                                 f_ar_dataH[33:1]; 
    
    a0_lo_ena               <=                                         f_ins_enable && f_lo_ena; 
    a0_lo_opc               <=                                                         f_lo_opc;//and/or/xor/nor
    a0_lo_dataL             <=                                                       f_lo_dataL;
    a0_lo_dataH             <=                                                       f_lo_dataH;

    a0_jp_ena               <=                            f_ins_enable && f_jp_link && f_jp_ena; 
    case(i_isz)
    2'd0:    a0_jp_dataL    <=                                                   i_iva + 32'h04;
    2'd1:    a0_jp_dataL    <=                                                   i_iva + 32'h08;
    default: a0_jp_dataL    <=                                                   i_iva + 32'h04;     
    endcase           
    
    a0_jp_dataH             <=  (f_jp_funID==10'd0)?                 32'd4 : {22'd0,f_jp_funID};

    a0_ds_ena               <=                                         f_ins_enable && f_ds_ena;
    
    {a0_ds_cout,a0_ds_dataL[31:29]} <=                                  dcdt2(i_r2_data[31:28]);
    a0_ds_dataL[28:25]              <=                                  dcdt2(i_r2_data[27:24]);
    a0_ds_dataL[24:21]              <=                                  dcdt2(i_r2_data[23:20]);
    a0_ds_dataL[20:17]              <=                                  dcdt2(i_r2_data[19:16]);
    a0_ds_dataL[16:13]              <=                                  dcdt2(i_r2_data[15:12]);
    a0_ds_dataL[12: 9]              <=                                  dcdt2(i_r2_data[11: 8]);
    a0_ds_dataL[ 8: 5]              <=                                  dcdt2(i_r2_data[ 7: 4]);
    a0_ds_dataL[ 4: 1]              <=                                  dcdt2(i_r2_data[ 3: 0]);
    a0_ds_dataL[    0]              <= (f_ds_ce)?                           f_c : i_r1_data[31];
    
    a0_ds_dataH                     <=                                   {i_r1_data[30:0],1'b0};
    
    a0_mm_ena               <=                                         f_ins_enable && f_mm_ena;
    a0_mm_opc               <=                                                         f_mm_opc;
    a0_mm_p0                <=                                                          f_mm_p0;
    a0_mm_p1                <=                                                          f_mm_p1;
    a0_mm_mod               <=                                                         f_mm_mod;              
    a0_mm_cval              <=                                                         f_cc_val;              
    a0_mm_arg_a             <=                                                          f_arg_a;
    a0_mm_arg_b             <=                                                          f_arg_b;
    a0_mm_arg_c             <=                                                          f_arg_c;
    a0_mm_arg_d             <=                                                          f_arg_d; 
    a0_mm_arL_b32           <=                                                   f_ar_dataL[32];

    if(i_evt_req && !fci_inst_jpf && i_stb)
        begin               
            a0_cr_ena       <=                                                             1'b0;
            case(i_evt_eid)
            3'h0: a0_cr_addr    <=                                                        5'd24; //IntExc
            3'h1: a0_cr_addr    <=                                                        5'd25; //IntDBG 
            3'h2: a0_cr_addr    <=                                                        5'd24; //IntReserved 
            3'h3: a0_cr_addr    <=                                                        5'd24; //IntUndefined
            3'h4: a0_cr_addr    <=                                                        5'd26; //ExtReflector
            3'h5: a0_cr_addr    <=                                                        5'd27; //ExtTLB
            3'h6: a0_cr_addr    <=                                                        5'd26; //ExtReserved 
            3'h7: a0_cr_addr    <=                                                        5'd26; //ExtUndefined
            endcase
            a0_cr_ren       <=                                                              'b0;
            a0_cr_cra0_ren  <=                                                              'b0;
            a0_cr_cra0_wen  <=                                                              'b0;
            a0_cr_cr6_ren   <=                                                              'b0;
            a0_cr_cr7_ren   <=                                                              'b0;
            a0_cr_cr15_ren  <=                                                              'b0;
            a0_cr_scr_wen_a <=                                                              'b1;
            a0_cr_scr_wen_b <=                                                              'b1;
            a0_cr_scr_wen_i <=                                                              'b1;
            a0_cr_data_L    <=                                                            i_iva;
            a0_cr_data_H    <=                                                            i_isw;
            
            a0_cr_jcr_wen[0]<=                                                              'b1;
            a0_cr_jcr_wen[1]<=                                                              'b1;
            a0_cr_jcr_data_L<=                                                            i_iva;
            a0_cr_jcr_data_H<=                                                            i_isw;
        end
    else if(f_ins_enable && f_cr_ena && f_jp_ena)//jump przez cr (czyli iret) wymusza odblokowanie przerwa
        begin               
            a0_cr_ena       <=                                                             1'b1;
            a0_cr_addr      <=                                                            5'd14; // crb14 - external event enable
            a0_cr_ren       <=                                                             1'b0;
            a0_cr_cra0_ren  <=                                                             1'b0;
            a0_cr_cra0_wen  <=                                                             1'b0;
            a0_cr_cr6_ren   <=                                                             1'b0;
            a0_cr_cr7_ren   <=                                                             1'b0;
            a0_cr_cr15_ren  <=                                                              'b0;
            a0_cr_scr_wen_a <=                                                             1'b0;                                      
            a0_cr_scr_wen_b <=                                                             1'b0;
            a0_cr_scr_wen_i <=                                                             1'b1;
            a0_cr_data_L    <=                                                        i_r2_data;
            a0_cr_data_H    <=                                           {i_r1_data[31:1],1'b1};
            
            a0_cr_jcr_wen[0]<=                                                             1'b0;
            a0_cr_jcr_wen[1]<=                                                             1'b0;
            a0_cr_jcr_data_L<=                                                        i_r2_data;
            a0_cr_jcr_data_H<=                                                        i_r1_data;
        end
    else if(f_ins_enable && f_cr_ena)
        begin
            a0_cr_ena       <=                                                             1'b1;
            a0_cr_addr      <=                                                        f_cr_addr;
            a0_cr_ren       <=            f_cr_addr!= 0                 && !f_cr_wen & f_cr_ena;
            a0_cr_cra0_ren  <=            f_cr_addr== 0 && f_cr_bank[0] && !f_cr_wen & f_cr_ena;
            a0_cr_cra0_wen  <=            f_cr_addr== 0 && f_cr_bank[0] &&  f_cr_wen & f_cr_ena;
            a0_cr_cr6_ren   <=            f_cr_addr== 6                 && !f_cr_wen & f_cr_ena;
            a0_cr_cr7_ren   <=            f_cr_addr== 7                 && !f_cr_wen & f_cr_ena;
            a0_cr_cr15_ren  <=            f_cr_addr== 15                && !f_cr_wen & f_cr_ena;
            a0_cr_scr_wen_a <=                             f_cr_bank[0] &&  f_cr_wen & f_cr_ena;
            a0_cr_scr_wen_b <=                             f_cr_bank[1] &&  f_cr_wen & f_cr_ena;
            a0_cr_scr_wen_i <=                             f_cr_bank[1] &&  f_cr_wen & f_cr_ena;                                      
            a0_cr_data_L    <=                                                        i_r2_data;
            a0_cr_data_H    <=                                                        i_r1_data;
            
            a0_cr_jcr_wen[0]<=            f_cr_addr[4]  && f_cr_bank[0] &&  f_cr_wen & f_cr_ena;
            a0_cr_jcr_wen[1]<=            f_cr_addr[4]  && f_cr_bank[1] &&  f_cr_wen & f_cr_ena;
            a0_cr_jcr_data_L<=                                                        i_r2_data;
            a0_cr_jcr_data_H<=                                                        i_r1_data;
        end
    else 
        begin               
            a0_cr_ena       <=                                                             1'b0;
            a0_cr_addr      <=                                                             5'd0;
            a0_cr_ren       <=                                                              'b0;
            a0_cr_cra0_ren  <=                                                              'b0;
            a0_cr_cra0_wen  <=                                                              'b0;
            a0_cr_cr6_ren   <=                                                              'b0;
            a0_cr_cr7_ren   <=                                                              'b0;
            a0_cr_scr_wen_a <=                                                              'b0;
            a0_cr_scr_wen_b <=                                                              'b0;
            a0_cr_scr_wen_i <=                                                              'b0;
            a0_cr_data_L    <=                                                        i_r2_data;
            a0_cr_data_H    <=                                                        i_r1_data;
            
            a0_cr_jcr_wen[0]<=                                                              'b0;
            a0_cr_jcr_wen[1]<=                                                              'b0;
            a0_cr_jcr_data_L<=                                                        i_r2_data;
            a0_cr_jcr_data_H<=                                                        i_r1_data;
        end
        
    a0_sh_ena               <=                                         f_ins_enable && f_sh_ena;
    a0_sh_imm               <=                                                         f_sh_imm;
    a0_sh_dir               <=                                                         f_sh_dir;
    
    case({f_sh_imm,f_sh_dir})
    2'b0_0: a0_sh_cnt       <=                                                   i_r0_data[4:0];           
    2'b0_1: a0_sh_cnt       <=                                                  ~i_r0_data[4:0];
    2'b1_0: a0_sh_cnt       <=                                                         f_sh_val;           
    2'b1_1: a0_sh_cnt       <=                                                        ~f_sh_val;
    endcase
    
    casex({f_sh_mode,f_sh_dir})
    3'b00_x:a0_sh_data      <=                                  {i_r2_data,      32'h0000_0000}; // shl
    3'b01_x:a0_sh_data      <=                                  {i_r2_data,      32'hFFFF_FFFF}; // shm
    3'b10_0:a0_sh_data      <=                                  {i_r2_data,{32{i_r2_data[ 0]}}}; // she
    3'b10_1:a0_sh_data      <=                                  {i_r2_data,{32{i_r2_data[31]}}}; // sha
    3'b11_x:a0_sh_data      <=                                  {i_r2_data,    i_r2_data      }; // rot
    endcase
    
    a0_bc_ena               <=                                         f_ins_enable && f_bc_ena;
    a0_bc_cL                <=                                                          f_bc_cL;
    a0_bc_cH                <=                                                          f_bc_cH;
    a0_bc_opc               <=                                                         f_bc_opc;
    a0_bc_data              <=                                                        i_r2_data; 
    a0_bc_nibble            <=                                                      f_bc_nibble; 
                                                                                                                     
    a0_fg_fl_norm           <=                                                     !f_fl_denorm;                    
    a0_fg_fl_nan            <=                                                         f_fl_nan;
    a0_fg_fl_inf            <=                                                         f_fl_inf;
    a0_fg_fl_s              <=                                                        f_fl_sign;
    a0_fg_fl_z              <=                                                        f_fl_zero;
    a0_fg_lo_z              <=                                                        f_lo_zero;
    a0_fg_ar_z              <=                                                        f_ar_zero;

    a0_cc_ena               <=                                         f_ins_enable && f_cc_ena;
    a0_cc_set               <=                                    f_cc_ena && i_stb && f_cc_set;
    a0_cc_chk               <=                                    f_cc_ena && i_stb && f_cc_chk;
    a0_cc_val               <=                                                         f_cc_val;
    a0_cc_skip              <=        (f_cc_chk && f_cc_ena && i_stb) && (f_cc_neg ^ !f_cc_val);

    a0_dbg_ena              <= (i_tid)?                     sys_trace_ena[1] : sys_trace_ena[0];

// .... product Ry path ........................................................................

    a0_ry_ena               <=                                     {2{f_ins_enable}} & i_ry_ena;
    a0_ry_addr              <=                                                        i_ry_addr;
    a0_ry_data              <=                                                            32'd0;
    a0_ry_tag               <=                                                         i_ry_tag;
    
    casex({f_ds_ena,f_ar_ena,f_lo_ena,f_jp_ena,f_jp_link})
    5'b00011:  a0_ry_mux    <=                                                             2'd1;
    5'b001xx:  a0_ry_mux    <=                                                             2'd2;
    5'b01xxx:  a0_ry_mux    <=                                                             2'd3;
    5'b1xxxx:  a0_ry_mux    <=                                                             2'd0;
    default:   a0_ry_mux    <=                                                             2'd0;
    endcase
    
// .............................................................................................
  end
//==============================================================================================
wire    f_inst_skip         =                                              a0_cc_skip && a0_stb;
wire    f_inst_rep          =                                             !a0_cc_skip && a0_rep;
// .............................................................................................
assign  fco_inst_skip       =                                                       f_inst_skip;
assign  fco_inst_rep        =                                                        f_inst_rep;
//==============================================================================================
assign  lc_ry_enaG          =          {2{!fci_inst_lsf}} & {2{!f_inst_skip}} & a0_lck_ry_enaG ;
assign  lc_ry_enaT0         =          {2{!fci_inst_lsf}} & {2{!f_inst_skip}} & a0_lck_ry_enaT0;
assign  lc_ry_enaT1         =          {2{!fci_inst_lsf}} & {2{!f_inst_skip}} & a0_lck_ry_enaT1;
assign  lc_ry_addr          =                                                    a0_lck_ry_addr;
assign  lc_ry_tag           =                                                    a0_lck_ry_tag ;
//==============================================================================================
// cc flags
//==============================================================================================
reg         fg_norm; 
reg         fg_nan;           
reg         fg_inf;     
            
reg         fg_s;   
reg         fg_o;   
reg         fg_c;   
reg         fg_z;   
//----------------------------------------------------------------------------------------------
always@(*) 
    if(a0_cc_fme)
        begin   // float tests
            fg_norm              =                                                a0_fg_fl_norm; // norm
            fg_nan               =                                                 a0_fg_fl_nan; // nan           
            fg_inf               =                                                 a0_fg_fl_inf; // inf
            
            fg_s                 =                                                   a0_fg_fl_s; // s
            fg_o                 =                                                         1'b0; // o
            fg_c                 =                                                         1'b0; // c
            fg_z                 =                                                   a0_fg_fl_z; // z
        end                             
    else         
        begin   // integer tests
            fg_norm              =                                                         1'b0; // norm
            fg_nan               =                                                         1'b0; // nan           
            fg_inf               =                                                         1'b0; // inf
             
            if(a0_ar_ena)
                begin
                    fg_s         =                                              a0_ar_dataL[31]; // s
                    fg_o         =                  !a0_ar_ovs & (a0_ar_sign ^ a0_ar_dataL[31]); // o
                    fg_c         =                   a0_ar_ovs & (a0_ar_sign ^ a0_ar_dataL[32]); // c
                    fg_z         =                                          &(~a0_fg_ar_z[7:0]); // z
                end
            else if(a0_ds_ena)    
                begin
                    fg_s         =                                                         1'b0; // s
                    fg_o         =                                                         1'b0; // o
                    fg_c         =                                                   a0_ds_cout; // c
                    fg_z         =                                                         1'b0; // z
                end
            else    
                begin
                    fg_s         =                                              a0_lo_dataL[31]; // s
                    fg_o         =                                                         1'b0; // o
                    fg_c         =                                                         1'b0; // c
                    fg_z         =                                                  &a0_fg_lo_z; // z
                end
        end                             
//==============================================================================================
// conditional flags
//==============================================================================================
eco32_core_mpu_cfr cfr 
(
.clk            (clk),
.rst            (rst),
                      
.ia_wen         (a0_cc_set && !f_inst_skip && !f_inst_rep && !fci_inst_lsf),     
.ia_flags       ({5'b00000,fg_norm,fg_nan,fg_inf,4'b0000,fg_s,fg_o,fg_c,fg_z}),     

.ib_wen         (a0_cr_cra0_wen && !f_inst_skip && !f_inst_rep && !fci_inst_lsf),     
.ib_flags       (a0_r1_data[15:0]),     

.o_flags        (b1_cc_flags),

.dbg_stb        (b1_dbg_cf_stb),
.dbg_flags      (b1_dbg_cf_data) 
);
//==============================================================================================
// cr registers
//==============================================================================================
wire        cra_wen     =       a0_cr_scr_wen_a && !f_inst_skip && !f_inst_rep && !fci_inst_lsf;
wire        crb_wen     =       a0_cr_scr_wen_b && !f_inst_skip && !f_inst_rep && !fci_inst_lsf;
wire        cri_wen     =       a0_cr_scr_wen_i && !f_inst_skip && !f_inst_rep && !fci_inst_lsf;
//----------------------------------------------------------------------------------------------
eco32_core_mpu_crx ctx 
(
.clk            (clk),   
.rst            (rst),

.i_tid          (a0_tid),
.i_addr         (a0_cr_addr[4:0]),
.i_wra          (cra_wen),
.i_cra          (a0_cr_data_L),
.i_wrb          (crb_wen),
.i_wri          (cri_wen),
.i_crb          (a0_cr_data_H),                                                                                                      

.o_cra          (a0_cr_data_a),
.o_crb          (a0_cr_data_b),

.sys_asid       (sys_asid),
.sys_event_ena  (sys_event_ena),
.sys_trace_ena  (sys_trace_ena)
);
//----------------------------------------------------------------------------------------------
// shared registers in jpu block
//----------------------------------------------------------------------------------------------
assign      jcr_wen[0]  =  a0_cr_jcr_wen[0] && !f_inst_skip && !f_inst_rep && !fci_inst_lsf;
assign      jcr_wen[1]  =  a0_cr_jcr_wen[1] && !f_inst_skip && !f_inst_rep && !fci_inst_lsf;
assign      jcr_tid     =  a0_tid;
assign      jcr_addr    =  a0_cr_addr[3:0];
assign      jcr_dataL   =  a0_cr_jcr_data_L;
assign      jcr_dataH   =  a0_cr_jcr_data_H;
//==============================================================================================
// debug port
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    b1_dbg_stb                  <=                                                         1'b0;
    b1_dbg_skp                  <=                                                         1'b0;
    b1_dbg_tid                  <=                                                         1'b0;
    b1_dbg_pid                  <=                                                         2'b0;
    b1_dbg_isw                  <=                                                        16'b0;        
    b1_dbg_iva                  <=                                                        32'b0;        
    b1_dbg_opc                  <=                                                        32'b0;        

    b1_dbg_ste                  <=                                                         1'b0;        
    b1_dbg_ext                  <=                                                        32'b0;        
    b1_dbg_stl                  <=                                                         1'b0;        
    b1_dbg_lck                  <=                                                         8'b0;        
    b1_dbg_crs                  <=                                                          'd0;
    b1_dbg_cra                  <=                                                          'd0;
    b1_dbg_crb                  <=                                                          'd0;
  end
 else if(a0_dbg_ena && !f_inst_rep && !fci_inst_lsf && (a0_stb || (a0_cc_skip && a0_rep)))
  begin
    b1_dbg_stb                  <=                           (a0_stb || (a0_cc_skip && a0_rep));
    b1_dbg_skp                  <=                                                   a0_cc_skip;
    b1_dbg_tid                  <=                                                       a0_tid;
    b1_dbg_pid                  <=                                                       a0_pid;
    b1_dbg_isw                  <=                                                       a0_isw;        
    b1_dbg_iva                  <=                                                       a0_iva;        
    b1_dbg_opc                  <=                                                       a0_iop;        
    
    b1_dbg_ste                  <=                                                    a0_isz[0];
    b1_dbg_ext                  <=                                                       a0_iex;
    b1_dbg_stl                  <=                                                a0_lck_ry_stb;        
    b1_dbg_lck                  <=                          {1'b0,a0_lck_ry_ena,a0_lck_ry_addr};  
    b1_dbg_crs                  <=                    {cra_wen,crb_wen,cri_wen,a0_cr_addr[4:0]};
    b1_dbg_cra                  <=                                                 a0_cr_data_L;
    b1_dbg_crb                  <=                                                 a0_cr_data_H;
  end
 else
  begin                                                                         
    b1_dbg_stb                  <=                                                         1'b0;
    b1_dbg_skp                  <=                                                         1'b0;
    b1_dbg_tid                  <=                                                         1'b0;
    b1_dbg_pid                  <=                                                         2'b0;
    b1_dbg_isw                  <=                                                        16'b0;        
    b1_dbg_iva                  <=                                                        32'b0;        
    b1_dbg_opc                  <=                                                        32'b0;        

    b1_dbg_ste                  <=                                                         1'b0;        
    b1_dbg_ext                  <=                                                        32'b0;        
    b1_dbg_stl                  <=                                                         1'b0;        
    b1_dbg_lck                  <=                                                         8'b0;        
    b1_dbg_crs                  <=                                                          'd0;
    b1_dbg_cra                  <=                                                          'd0;
    b1_dbg_crb                  <=                                                          'd0;
  end
//----------------------------------------------------------------------------------------------
assign  dbg_ins_stb              =                                                   b1_dbg_stb;
assign  dbg_ins_skp              =                                                   b1_dbg_skp;
assign  dbg_ins_tid              =                                                   b1_dbg_tid;
assign  dbg_ins_pid              =                                                   b1_dbg_pid;
assign  dbg_ins_isw              =                                                   b1_dbg_isw;
assign  dbg_ins_iva              =                                                   b1_dbg_iva;
assign  dbg_ins_opc              =                                                   b1_dbg_opc;
                                 
assign  dbg_ins_ste              =                                                   b1_dbg_ste;
assign  dbg_ins_ext              =                                                   b1_dbg_ext;
assign  dbg_ins_stf              =                                                b1_dbg_cf_stb;
assign  dbg_ins_cfa              =                                               b1_dbg_cf_data;
assign  dbg_ins_stl              =                                                   b1_dbg_stl;
assign  dbg_ins_lck              =                                                   b1_dbg_lck;
assign  dbg_ins_crs              =                                                   b1_dbg_crs;
assign  dbg_ins_cra              =                                                   b1_dbg_cra;
assign  dbg_ins_crb              =                                                   b1_dbg_crb;
//==============================================================================================
// stage b(1): 
//==============================================================================================
wire    [63:0]  f_sh_temp       =   

        (a0_sh_cnt[4:1]==4'h0)?      {a0_sh_data[63:32],  a0_sh_data[31: 0]                   }:
        (a0_sh_cnt[4:1]==4'h1)?      {a0_sh_data[61:32],  a0_sh_data[31: 0], a0_sh_data[63:62]}:
        (a0_sh_cnt[4:1]==4'h2)?      {a0_sh_data[59:32],  a0_sh_data[31: 0], a0_sh_data[63:60]}:
        (a0_sh_cnt[4:1]==4'h3)?      {a0_sh_data[57:32],  a0_sh_data[31: 0], a0_sh_data[63:58]}:
        (a0_sh_cnt[4:1]==4'h4)?      {a0_sh_data[55:32],  a0_sh_data[31: 0], a0_sh_data[63:56]}:
        (a0_sh_cnt[4:1]==4'h5)?      {a0_sh_data[53:32],  a0_sh_data[31: 0], a0_sh_data[63:54]}:
        (a0_sh_cnt[4:1]==4'h6)?      {a0_sh_data[51:32],  a0_sh_data[31: 0], a0_sh_data[63:52]}:
        (a0_sh_cnt[4:1]==4'h7)?      {a0_sh_data[49:32],  a0_sh_data[31: 0], a0_sh_data[63:50]}:
        (a0_sh_cnt[4:1]==4'h8)?      {a0_sh_data[47:32],  a0_sh_data[31: 0], a0_sh_data[63:48]}:
        (a0_sh_cnt[4:1]==4'h9)?      {a0_sh_data[45:32],  a0_sh_data[31: 0], a0_sh_data[63:46]}:
        (a0_sh_cnt[4:1]==4'hA)?      {a0_sh_data[43:32],  a0_sh_data[31: 0], a0_sh_data[63:44]}:
        (a0_sh_cnt[4:1]==4'hB)?      {a0_sh_data[41:32],  a0_sh_data[31: 0], a0_sh_data[63:42]}:
        (a0_sh_cnt[4:1]==4'hC)?      {a0_sh_data[39:32],  a0_sh_data[31: 0], a0_sh_data[63:40]}:
        (a0_sh_cnt[4:1]==4'hD)?      {a0_sh_data[37:32],  a0_sh_data[31: 0], a0_sh_data[63:38]}:
        (a0_sh_cnt[4:1]==4'hE)?      {a0_sh_data[35:32],  a0_sh_data[31: 0], a0_sh_data[63:36]}:
      /*(a0_sh_cnt[4:1]==4'hF)?*/    {a0_sh_data[33:32],  a0_sh_data[31: 0], a0_sh_data[63:34]};
//----------------------------------------------------------------------------------------------
wire            f_mpu_ena_cr    =                                   a0_cr_ren || a0_cr_cra0_ren;
//----------------------------------------------------------------------------------------------
wire            f_mpu_ena_SP    = a0_ds_ena || a0_jp_ena || a0_sh_ena || a0_lo_ena || a0_ar_ena;
wire            f_mpu_ena_LP    =                        f_mpu_ena_cr || a0_bc_ena || a0_mm_ena;
//----------------------------------------------------------------------------------------------
wire            f_mpu_sel       =                                  f_mpu_ena_SP || f_mpu_ena_LP;
wire            f_mpu_ena       =     !f_inst_rep && !fci_inst_lsf && f_mpu_sel && !f_inst_skip;
//==============================================================================================    
// min/max/sel
//==============================================================================================    
wire        f_mm_min        = (a0_mm_arg_a[32] == a0_mm_arg_b[32]) ?                a0_mm_arL_b32 : 
                                                                                                     a0_r0_data[31]; 
//==============================================================================================    
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    b1_stb_SP               <=                                                             1'b0;
    b1_stb_LP               <=                                                             1'b0;
    b1_tid                  <=                                                             1'b0;
    b1_asid                 <=                                                             4'b0;
    b1_pid                  <=                                                             2'b0;
    b1_isw                  <=                                                            16'b0;        
    b1_erx                  <=                                                              'b0;        
    b1_wrx                  <=                                                              'b0;        

    b1_r0_data              <=                                                            32'd0;
    b1_r1_data              <=                                                            32'd0;
    b1_r2_data              <=                                                            32'd0;
    b1_r3_data              <=                                                            32'd0;

    b1_sh_ena               <=                                                             1'd0;
    b1_sh_slb               <=                                                             1'd0;
    b1_sh_clb               <=                                                             1'd0;
    b1_sh_dir               <=                                                             2'd0;
    b1_sh_cnt               <=                                                             5'd0;
    b1_sh_lb                <=                                                            32'd0;
    b1_sh_data              <=                                                            64'd0;
    
    b1_cr_ena               <=                                                             1'd0;
    b1_cr_cr6_ena           <=                                                             1'd0;
    b1_cr_cr7_ena           <=                                                             1'd0;
    b1_cr_cr15_ena          <=                                                             1'd0;
    b1_cr_data_a            <=                                                            32'd0;
    b1_cr_data_b            <=                                                            32'd0;

    b1_mm_ena               <=                                                             1'd0;
    b1_mm_p0                <=                                                             1'd0;
    b1_mm_min               <=                                                             1'b0;
    b1_mm_cval              <=                                                             1'b0;
    b1_mm_arg_a             <=                                                            34'b0;
    b1_mm_arg_b             <=                                                            34'b0;
    b1_mm_arg_c             <=                                                            34'b0;
    b1_mm_arg_d             <=                                                            34'b0;
    b1_mm_dbL0              <=                                                              'b0;
    b1_mm_dbL1              <=                                                              'b0;
    b1_mm_dbL2              <=                                                              'b0;
    b1_mm_dbL3              <=                                                              'b0;
    b1_mm_dbH0              <=                                                              'b0;
    b1_mm_dbH1              <=                                                              'b0;
    b1_mm_dbH2              <=                                                              'b0;
    b1_mm_dbH3              <=                                                              'b0;
    
    b1_bc_ena               <=                                                             1'b0;     
    b1_bc_cL                <=                                                             2'd0;
    b1_bc_cH                <=                                                             2'd0;
    b1_bc_opc               <=                                                             2'd0;
    b1_bc_cnt4              <=                                                             6'd0;
    b1_bc_cnt8              <=                                                             6'd0;
    b1_bc_cnt16             <=                                                             6'd0;
    b1_bc_tmp8              <=                                                             8'd0;
    
    b1_ry_ena               <=                                                             2'd0;
    b1_ry_addr              <=                                                             5'd0;
    b1_ry_dataL             <=                                                            32'd0;
    b1_ry_dataH             <=                                                            32'd0;
    b1_ry_tag               <=                                                             2'd0;
    b1_ry_mux               <=                                                             2'd0;
  end
 else
  begin
    b1_stb_SP               <=                              f_mpu_ena_SP && f_mpu_ena && a0_stb;
    b1_stb_LP               <=                              f_mpu_ena_LP && f_mpu_ena && a0_stb;
    b1_tid                  <=                                                           a0_tid;
    b1_asid                 <=                                                          a0_asid;
    b1_pid                  <=                                                           a0_pid;
    b1_isw                  <=                                                           a0_isw;        
    b1_erx                  <=                                                           a0_erx;
    b1_wrx                  <=                                                           a0_wrx;

    b1_r0_data              <=                                                       a0_r0_data;
    b1_r1_data              <=                                                       a0_r1_data;
    b1_r2_data              <=                                                       a0_r2_data;
    b1_r3_data              <=                                                       a0_r3_data;
    
    b1_sh_ena               <=                                 a0_sh_ena && f_mpu_ena && a0_stb;
    b1_sh_dir               <=                                                        a0_sh_dir;
    b1_sh_data              <=                                                        f_sh_temp;
                                                                                                         
    b1_cr_ena               <= !a0_cr_cr7_ren & !a0_cr_cr6_ren & a0_cr_ren & f_mpu_ena & a0_stb;
    b1_cr_cr6_ena           <=                   a0_cr_cr6_ren & a0_cr_ren & f_mpu_ena & a0_stb;
    b1_cr_cr7_ena           <=                   a0_cr_cr7_ren & a0_cr_ren & f_mpu_ena & a0_stb;
    b1_cr_cr15_ena          <=                  a0_cr_cr15_ren & a0_cr_ren & f_mpu_ena & a0_stb;
    b1_cr_data_a            <=                                                     a0_cr_data_a;
    b1_cr_data_b            <=                                                     a0_cr_data_b;

    b1_cc_ena               <=                            a0_cr_cra0_ren && f_mpu_ena && a0_stb;
    
    b1_mm_ena               <=                                 a0_mm_ena && f_mpu_ena && a0_stb;     
    b1_mm_opc               <=                                                        a0_mm_opc;     
    b1_mm_mod               <=                                                        a0_mm_mod;
    b1_mm_p0                <=                                                         a0_mm_p0;
    b1_mm_cval              <=                                                       a0_mm_cval;                         //
    b1_mm_min               <=                                                         f_mm_min;
    b1_mm_arg_a             <=                                                      a0_mm_arg_a;
    b1_mm_arg_b             <=                                                      a0_mm_arg_b;
    b1_mm_arg_c             <=                                                      a0_mm_arg_c;
    b1_mm_arg_d             <=                                                      a0_mm_arg_d;
    b1_mm_dbL0              <=              {1'b0,a0_mm_arg_a[ 8: 1]}-{1'b0,a0_mm_arg_b[ 8: 1]};
    b1_mm_dbL1              <=              {1'b0,a0_mm_arg_a[16: 9]}-{1'b0,a0_mm_arg_b[16: 9]};
    b1_mm_dbL2              <=              {1'b0,a0_mm_arg_a[24:17]}-{1'b0,a0_mm_arg_b[24:17]};
    b1_mm_dbL3              <=              {1'b0,a0_mm_arg_a[32:25]}-{1'b0,a0_mm_arg_b[32:25]};
    b1_mm_dbH0              <=              {1'b0,a0_mm_arg_c[ 8: 1]}-{1'b0,a0_mm_arg_d[ 8: 1]};
    b1_mm_dbH1              <=              {1'b0,a0_mm_arg_c[16: 9]}-{1'b0,a0_mm_arg_d[16: 9]};
    b1_mm_dbH2              <=              {1'b0,a0_mm_arg_c[24:17]}-{1'b0,a0_mm_arg_d[24:17]};
    b1_mm_dbH3              <=              {1'b0,a0_mm_arg_c[32:25]}-{1'b0,a0_mm_arg_d[32:25]};
   
    b1_bc_ena               <=                                 a0_bc_ena && f_mpu_ena && a0_stb;     
    b1_bc_cL                <=                                                         a0_bc_cL;
    b1_bc_cH                <=                                                         a0_bc_cH;
    b1_bc_opc               <=                                                        a0_bc_opc;
    
    casex(a0_bc_nibble)
    8'b0xxx_xxxx: b1_bc_cnt4    <=                                                          'd0;
    8'b10xx_xxxx: b1_bc_cnt4    <=                                                          'd4;
    8'b110x_xxxx: b1_bc_cnt4    <=                                                          'd8;
    8'b1110_xxxx: b1_bc_cnt4    <=                                                         'd12;
    8'b1111_0xxx: b1_bc_cnt4    <=                                                         'd16;
    8'b1111_10xx: b1_bc_cnt4    <=                                                         'd20;
    8'b1111_110x: b1_bc_cnt4    <=                                                         'd24;
    8'b1111_1110: b1_bc_cnt4    <=                                                         'd28;
    8'b1111_1111: b1_bc_cnt4    <=                                                         'd32;
    endcase

    casex(a0_bc_nibble)
    8'b0xxx_xxxx: b1_bc_cnt8    <=                                                          'd0;
    8'b10xx_xxxx: b1_bc_cnt8    <=                                                          'd0;
    8'b110x_xxxx: b1_bc_cnt8    <=                                                          'd8;
    8'b1110_xxxx: b1_bc_cnt8    <=                                                          'd8;
    8'b1111_0xxx: b1_bc_cnt8    <=                                                         'd16;
    8'b1111_10xx: b1_bc_cnt8    <=                                                         'd16;
    8'b1111_110x: b1_bc_cnt8    <=                                                         'd24;
    8'b1111_1110: b1_bc_cnt8    <=                                                         'd24;
    8'b1111_1111: b1_bc_cnt8    <=                                                         'd32;
    endcase

    casex(a0_bc_nibble)
    8'b0xxx_xxxx: b1_bc_cnt16   <=                                                          'd0;
    8'b10xx_xxxx: b1_bc_cnt16   <=                                                          'd0;
    8'b110x_xxxx: b1_bc_cnt16   <=                                                          'd0;
    8'b1110_xxxx: b1_bc_cnt16   <=                                                          'd0;
    8'b1111_0xxx: b1_bc_cnt16   <=                                                         'd16;
    8'b1111_10xx: b1_bc_cnt16   <=                                                         'd16;
    8'b1111_110x: b1_bc_cnt16   <=                                                         'd16;
    8'b1111_1110: b1_bc_cnt16   <=                                                         'd16;
    8'b1111_1111: b1_bc_cnt16   <=                                                         'd32;
    endcase

    casex(a0_bc_nibble)
    8'b0xxx_xxxx: b1_bc_tmp8    <=                                            a0_bc_data[31:24];
    8'b10xx_xxxx: b1_bc_tmp8    <=                                            a0_bc_data[31:24];
    8'b110x_xxxx: b1_bc_tmp8    <=                                            a0_bc_data[23:16];
    8'b1110_xxxx: b1_bc_tmp8    <=                                            a0_bc_data[23:16];
    8'b1111_0xxx: b1_bc_tmp8    <=                                            a0_bc_data[15: 8];
    8'b1111_10xx: b1_bc_tmp8    <=                                            a0_bc_data[15: 8];
    8'b1111_110x: b1_bc_tmp8    <=                                            a0_bc_data[ 7: 0];
    8'b1111_1110: b1_bc_tmp8    <=                                            a0_bc_data[ 7: 0];
    8'b1111_1111: b1_bc_tmp8    <=                                            a0_bc_data[ 7: 0];
    endcase
    
// .... product Ry path ........................................................................
       
    b1_ry_ena               <= (a0_stb && f_mpu_ena) ?                        a0_ry_ena : 2'b00;
    b1_ry_addr              <=                                                       a0_ry_addr;
    
    casex(a0_ry_mux)    
    2'd0:  b1_ry_dataL      <=                                                      a0_ds_dataL;
    2'd1:  b1_ry_dataL      <=                                                      a0_jp_dataL;
    2'd2:  b1_ry_dataL      <=                                                      a0_lo_dataL;
    2'd3:  b1_ry_dataL      <=                                                      a0_ar_dataL;
    endcase
    
    casex(a0_ry_mux)    
    2'd0:  b1_ry_dataH      <=                                                      a0_ds_dataH;
    2'd1:  b1_ry_dataH      <=                                                      a0_jp_dataH;
    2'd2:  b1_ry_dataH      <=                                                      a0_lo_dataH;
    2'd3:  b1_ry_dataH      <=                                                      a0_ar_dataH;
    endcase
    
    b1_ry_tag               <= (a0_stb && !f_inst_skip) ?                    a0_ry_tag  : 2'b00;

    casex({a0_sh_ena, a0_sh_dir})
    4'b01_0:  b1_ry_mux     <=                                             {2'd2, a0_sh_cnt[0]};
    4'b01_1:  b1_ry_mux     <=                                             {2'd3, a0_sh_cnt[0]};                       
    default:  b1_ry_mux     <=                                             {2'd0,         1'd0};
    endcase 
    
// .............................................................................................
  end
//==============================================================================================
// exception registers
//==============================================================================================
eco32_core_mpu_erx 
#(
.FORCE_RST          (FORCE_RST)
)
erx
(
.clk            (clk),
.rst            (rst),

.wr_bus         (b1_wrx),     

.rd_tid         (b1_tid),
.rd_addr        (b1_erx),
.rd_data        ({b1_cr_erx_b,b1_cr_erx_a})
);
//==============================================================================================
// stage a(2): 
//==============================================================================================           
wire  [7:0] b1_mm_b0            =                                              b1_mm_arg_b[8:1];
wire  [7:0] b1_mm_b1            =                                             b1_mm_arg_b[16:9];
wire  [7:0] b1_mm_b2            =                                            b1_mm_arg_b[24:17];
wire  [7:0] b1_mm_b3            =                                            b1_mm_arg_b[32:25];
//----------------------------------------------------------------------------------------------
wire  [7:0] b1_mm_d0            =                                              b1_mm_arg_d[8:1];
wire  [7:0] b1_mm_d1            =                                             b1_mm_arg_d[16:9];
wire  [7:0] b1_mm_d2            =                                            b1_mm_arg_d[24:17];
wire  [7:0] b1_mm_d3            =                                            b1_mm_arg_d[32:25];
//----------------------------------------------------------------------------------------------
wire  [9:0] b1_seL0             =                               {b1_mm_dbL0[8],b1_mm_dbL0[8:0]};
wire  [9:0] b1_seL1             =                               {b1_mm_dbL1[8],b1_mm_dbL1[8:0]};
wire  [9:0] b1_seL2             =                               {b1_mm_dbL2[8],b1_mm_dbL2[8:0]};
wire  [9:0] b1_seL3             =                               {b1_mm_dbL3[8],b1_mm_dbL3[8:0]};
//----------------------------------------------------------------------------------------------
wire  [9:0] b1_seH0             =                               {b1_mm_dbH0[8],b1_mm_dbH0[8:0]};
wire  [9:0] b1_seH1             =                               {b1_mm_dbH1[8],b1_mm_dbH1[8:0]};
wire  [9:0] b1_seH2             =                               {b1_mm_dbH2[8],b1_mm_dbH2[8:0]};
wire  [9:0] b1_seH3             =                               {b1_mm_dbH3[8],b1_mm_dbH3[8:0]};
//----------------------------------------------------------------------------------------------
wire  [9:0] b1_sumL0            =  b1_seL0[8]^b1_seL1[8] ?    b1_seL0-b1_seL1 : b1_seL0+b1_seL1;     
wire  [9:0] b1_sumL1            =  b1_seL2[8]^b1_seL3[8] ?    b1_seL2-b1_seL3 : b1_seL2+b1_seL3;     
wire  [9:0] b1_sumH0            =  b1_seH0[8]^b1_seH1[8] ?    b1_seH0-b1_seH1 : b1_seH0+b1_seH1;     
wire  [9:0] b1_sumH1            =  b1_seH2[8]^b1_seH3[8] ?    b1_seH2-b1_seH3 : b1_seH2+b1_seH3;     
//----------------------------------------------------------------------------------------------
wire [10:0] b1_sxL0             =                                   {b1_sumL0[9],b1_sumL0[9:0]};
wire [10:0] b1_sxL1             =                                   {b1_sumL1[9],b1_sumL1[9:0]};
wire [10:0] b1_sxH0             =                                   {b1_sumH0[9],b1_sumH0[9:0]};
wire [10:0] b1_sxH1             =                                   {b1_sumH1[9],b1_sumH1[9:0]};
//----------------------------------------------------------------------------------------------
wire [10:0] b1_mm_sL            =  b1_sxL0[9]^b1_sxL1[9] ?    b1_sxL0-b1_sxL1 : b1_sxL0+b1_sxL1;     
wire [10:0] b1_mm_sH            =  b1_sxH0[9]^b1_sxH1[9] ?    b1_sxH0-b1_sxH1 : b1_sxH0+b1_sxH1;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    a2_stb_SP                   <=                                                         1'b0;
    a2_stb_LP                   <=                                                         1'b0;
    a2_tid                      <=                                                         1'b0;
    a2_asid                     <=                                                         4'b0;
    a2_pid                      <=                                                         2'b0;
    a2_isw                      <=                                                         1'b0;        

    a2_cr_ena                   <=                                                         1'd0;
    a2_cr_cr6_ena               <=                                                         1'd0;
    a2_cr_cr7_ena               <=                                                         1'd0;
    a2_cr_cr15_ena              <=                                                         1'd0;
    a2_cr_data_a                <=                                                        32'd0;
    a2_cr_data_b                <=                                                        32'd0;
    a2_cr_erx_a                 <=                                                        32'd0;
    a2_cr_erx_b                 <=                                                        32'd0;
    
    a2_bc_ena                   <=                                                          'd0;
    a2_bc_opc                   <=                                                          'd0;
    a2_bc_cL                    <=                                                          'd0;
    a2_bc_cH                    <=                                                          'd0;
    
    a2_cc_ena                   <=                                                         1'b0;
    a2_cc_flags                 <=                                                        12'b0;

    a2_mm_ena                   <=                                                          'b0;     
    a2_mm_cval                  <=                                                          'd0;     
    a2_mm_opc                   <=                                                          'd0;
    a2_mm_sel                   <=                                                          'b0;     
    a2_mm_p0                    <=                                                          'b0;     
    a2_mm_dataL                 <=                                                        32'b0;     
    a2_mm_dataH                 <=                                                        32'b0;     
    a2_mm_sL                    <=                                                          'b0;     
    a2_mm_sH                    <=                                                          'b0;     
    
    a2_ry_stb0                  <=                                                         1'b0;
    a2_ry_stb1                  <=                                                         1'b0;
    a2_ry_enaA                  <=                                                         2'd0;
    a2_ry_tagA                  <=                                                         1'd0;
    a2_ry_enaB                  <=                                                         2'd0;
    a2_ry_modB                  <=                                                         1'd0;
    a2_ry_tagB                  <=                                                         1'd0;
    a2_ry_addr                  <=                                                         5'd0;
    a2_ry_dataL                 <=                                                        32'd0;
    a2_ry_dataH                 <=                                                        32'd0;
  end
 else
  begin
    a2_stb_SP                   <=                                                    b1_stb_SP;
    a2_stb_LP                   <=                                                    b1_stb_LP;                       
    a2_tid                      <=                                                       b1_tid;
    a2_asid                     <=                                                      b1_asid;
    a2_pid                      <=                                                       b1_pid;
    a2_isw                      <=                                                       b1_isw;        

    a2_cr_ena                   <=                                                    b1_cr_ena;
    a2_cr_cr6_ena               <=                                                b1_cr_cr6_ena;
    a2_cr_cr7_ena               <=                                                b1_cr_cr7_ena;
    a2_cr_cr15_ena              <=                                               b1_cr_cr15_ena;
    a2_cr_data_a                <=                                                 b1_cr_data_a;
    a2_cr_data_b                <=                                                 b1_cr_data_b;
    a2_cr_erx_a                 <=                                                  b1_cr_erx_a;
    a2_cr_erx_b                 <=                                                  b1_cr_erx_b;
    
    a2_mm_ena                   <=                                                    b1_mm_ena;     
    a2_mm_cval                  <=                                                   b1_mm_cval;     
    a2_mm_opc                   <=                                                    b1_mm_opc;     
    a2_mm_p0                    <=                                                     b1_mm_p0;     
    a2_mm_sL                    <=                                                     b1_mm_sL;     
    a2_mm_sH                    <=                                                     b1_mm_sH;     
    
     casex({b1_mm_opc,b1_mm_mod})                                                                                                                                                               
     3'b00_0: a2_mm_dataL       <=  (!b1_mm_min)?         b1_mm_arg_b[32:1] : b1_mm_arg_a[32:1]; // min
     3'b00_1: a2_mm_dataL       <=  ( b1_mm_min)?         b1_mm_arg_b[32:1] : b1_mm_arg_a[32:1]; // max
     3'b01_x: a2_mm_dataL       <=                        b1_mm_arg_b[32:1]                    ; // sel
     3'b10_x: a2_mm_dataL       <=                        {b1_mm_b0,b1_mm_b1,b1_mm_b2,b1_mm_b3}; // bsawp
     default:a2_mm_dataL        <=                        b1_mm_arg_b[32:1]                    ; // 
     endcase

     casex({b1_mm_opc,b1_mm_mod})                                                                                                                                                               
     3'b00_0: a2_mm_dataH       <=  (!b1_mm_min)?         b1_mm_arg_c[32:1] : b1_mm_arg_d[32:1]; // min
     3'b00_1: a2_mm_dataH       <=  ( b1_mm_min)?         b1_mm_arg_c[32:1] : b1_mm_arg_d[32:1]; // max
     3'b01_x: a2_mm_dataH       <=                        b1_mm_arg_c[32:1]                    ; // sel
     3'b10_x: a2_mm_dataH       <=                        {b1_mm_d0,b1_mm_d1,b1_mm_d2,b1_mm_d3}; // bsawp
     default:a2_mm_dataH        <=                        b1_mm_arg_c[32:1]                    ; // 
     endcase

    a2_cc_ena                   <=                                                    b1_cc_ena;
    a2_cc_flags                 <=                                                  b1_cc_flags;

    a2_bc_ena                   <=                                                    b1_bc_ena;
    a2_bc_opc                   <=                                                    b1_bc_opc;
    a2_bc_cL                    <=                                                     b1_bc_cL;
    a2_bc_cH                    <=                                                     b1_bc_cH;
    
    casex({b1_bc_opc,b1_bc_tmp8})
    10'b00_1xxx_xxxx: a2_bc_cnt <=                                             b1_bc_cnt8 + 'd0;
    10'b00_01xx_xxxx: a2_bc_cnt <=                                             b1_bc_cnt8 + 'd1;
    10'b00_001x_xxxx: a2_bc_cnt <=                                             b1_bc_cnt8 + 'd2;
    10'b00_0001_xxxx: a2_bc_cnt <=                                             b1_bc_cnt8 + 'd3;
    10'b00_0000_1xxx: a2_bc_cnt <=                                             b1_bc_cnt8 + 'd4;
    10'b00_0000_01xx: a2_bc_cnt <=                                             b1_bc_cnt8 + 'd5;
    10'b00_0000_001x: a2_bc_cnt <=                                             b1_bc_cnt8 + 'd6;
    10'b00_0000_0001: a2_bc_cnt <=                                             b1_bc_cnt8 + 'd7;
    10'b00_0000_0000: a2_bc_cnt <=                                             b1_bc_cnt8 + 'd0;

    10'b01_xxxx_xxxx: a2_bc_cnt <=                                                   b1_bc_cnt4;
    10'b10_xxxx_xxxx: a2_bc_cnt <=                                                   b1_bc_cnt8;
    10'b11_xxxx_xxxx: a2_bc_cnt <=                                                  b1_bc_cnt16;
    endcase 

    
// .... product Ya path ........................................................................

    a2_ry_stb0                  <=                           !b1_tid & (|b1_ry_ena) & b1_stb_SP;
    a2_ry_stb1                  <=                            b1_tid & (|b1_ry_ena) & b1_stb_SP;

    a2_ry_addr                  <=                                                   b1_ry_addr;
    
    a2_ry_enaA                  <=                           {2{b1_stb_SP}} & {2{b1_ry_ena[0]}};
    a2_ry_tagA                  <=                                                 b1_ry_tag[0];
    
    a2_ry_enaB                  <=                           {2{b1_stb_SP}} & {2{b1_ry_ena[1]}};       
    a2_ry_modB                  <=                                                   &b1_ry_ena;
    a2_ry_tagB                  <=                                                 b1_ry_tag[1];
    
    casex(b1_ry_mux)
    3'b00_x: a2_ry_dataL        <=                                                  b1_ry_dataL;
    
    3'b10_0: a2_ry_dataL        <=                                            b1_sh_data[63:32];
    3'b10_1: a2_ry_dataL        <=                                            b1_sh_data[62:31];
    
    3'b11_0: a2_ry_dataL        <=                        {b1_sh_data[30: 0],b1_sh_data[   63]}; 
    3'b11_1: a2_ry_dataL        <=                        {b1_sh_data[29: 0],b1_sh_data[63:62]};
    endcase

    casex(b1_ry_mux)
    3'b00_x: a2_ry_dataH        <=                                                  b1_ry_dataH;

    3'b10_0: a2_ry_dataH        <=                                                        32'd0;
    3'b10_1: a2_ry_dataH        <=                                                        32'd0;
    
    3'b11_0: a2_ry_dataH        <=                                                        32'd0;
    3'b11_1: a2_ry_dataH        <=                                                        32'd0;
    default: a2_ry_dataH        <=                                                        32'd0;
    endcase  

// to long path ................................................................................
    
    a2_ry_ena                   <=                                   b1_ry_ena & {2{b1_stb_LP}};
    a2_ry_tag                   <=                                   b1_ry_tag & {2{b1_stb_LP}};
    
    casex({b1_cr_cr15_ena,b1_cr_cr7_ena,b1_cc_ena,b1_cr_ena})
    4'b1xxx:     a2_ry_mux      <=                                                         2'd0;
    4'b01xx:     a2_ry_mux      <=                                                         2'd1;
    4'b001x:     a2_ry_mux      <=                                                         2'd2;
    4'b0001:     a2_ry_mux      <=                                                         2'd3;
    default:     a2_ry_mux      <=                                                         2'd0;
    endcase 
    
// .............................................................................................
  end   
//==============================================================================================
// write back (short path)
//==============================================================================================
assign  wba_stb0             =                                                       a2_ry_stb0; 
assign  wba_stb1             =                                                       a2_ry_stb1; 

assign  wba_enaA             =                                                       a2_ry_enaA; 
assign  wba_tagA             =                                                       a2_ry_tagA;

assign  wba_enaB             =                                                       a2_ry_enaB; 
assign  wba_modB             =                                                       a2_ry_modB;
assign  wba_tagB             =                                                       a2_ry_tagB;

assign  wba_addr             =                                                       a2_ry_addr; 
assign  wba_dataL            =                                                      a2_ry_dataL;
assign  wba_dataH            =                                                      a2_ry_dataH;
//==============================================================================================
// stage b3
//==============================================================================================
wire [11:0] a2_mm_sX             =                                      {a2_mm_sL[10],a2_mm_sL};     
wire [11:0] a2_mm_sY             =  a2_mm_p0=='d0 ?              'd0 :  {a2_mm_sH[10],a2_mm_sH};     
wire        a2_mm_sign           =                                    a2_mm_sX[11]^a2_mm_sY[11];
//----------------------------------------------------------------------------------------------
wire [11:0] a2_mm_sum            =  a2_mm_sign    ?   a2_mm_sX - a2_mm_sY : a2_mm_sX + a2_mm_sY;     
//----------------------------------------------------------------------------------------------
wire [11:0] a2_mm_sad            =  a2_mm_sum[11] ?            -a2_mm_sum :           a2_mm_sum;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    b3_stb                      <=                                                         1'b0;
    b3_tid                      <=                                                         1'b0;
    b3_asid                     <=                                                         4'b0;
    b3_pid                      <=                                                         2'b0;
    b3_isw                      <=                                                         1'b0;        

    b3_cr_cr6_ena               <=                                                         1'b0;
    
    b3_mm_ena                   <=                                                         1'b0;
    b3_mm_dataL                 <=                                                        32'b0;
    b3_mm_dataH                 <=                                                        32'b0;
    
    b3_ry_ena                   <=                                                         2'd0;
    b3_ry_addr                  <=                                                         5'd0;
    b3_ry_dataL                 <=                                                        32'd0;
    b3_ry_dataH                 <=                                                        32'd0;
    b3_ry_tag                   <=                                                         2'd0;
    b3_ry_mux                   <=                                                         2'd0;
  end
 else
  begin
    b3_stb                      <=                                                    a2_stb_LP;
    b3_tid                      <=                                                       a2_tid;
    b3_asid                     <=                                                      a2_asid;
    b3_pid                      <=                                                       a2_pid;
    b3_isw                      <=                                                       a2_isw;        

    b3_cr_cr6_ena               <=                                                a2_cr_cr6_ena;
    
    b3_mm_ena                   <=                                                    a2_mm_ena;     
    
    casex(a2_mm_opc)
    2'b00: b3_mm_dataL          <=                                                 a2_mm_dataL; // min/max
    2'b01: b3_mm_dataL          <= (a2_mm_cval ) ?                   a2_mm_dataH : a2_mm_dataL; // sel
    2'b10: b3_mm_dataL          <=                                                 a2_mm_dataL; // bswap
    2'b11: b3_mm_dataL          <=                                                   a2_mm_sad; // sad
    endcase
    
    casex(a2_mm_opc)
    2'b00:  b3_mm_dataH         <=                                                 a2_mm_dataH; // min/max
    2'b01:  b3_mm_dataH         <= (a2_mm_cval ) ?                   a2_mm_dataL : a2_mm_dataH; // sel
    2'b10:  b3_mm_dataH         <=                                                 a2_mm_dataH; // bswap
    2'b11:  b3_mm_dataH         <=                                                       32'd0; // sad
    endcase

    b3_bc_ena                   <=                                                    a2_bc_ena;     

    casex(a2_bc_cL)
    3'b000:  b3_bc_cntL         <=                                       {1'b0,a2_bc_cnt} + 8'b0;
    3'b001:  b3_bc_cntL         <=                                       {1'b0,a2_bc_cnt} + 8'b1;
    3'b010:  b3_bc_cntL         <=                                       {a2_bc_cnt,1'b0} + 8'd0;
    3'b011:  b3_bc_cntL         <=                                       {a2_bc_cnt,1'b0} + 8'd1;
    
    3'b100:  b3_bc_cntL         <=                             8'd32 - ({1'b0,a2_bc_cnt} + 8'b0);
    3'b101:  b3_bc_cntL         <=                             8'd32 - ({1'b0,a2_bc_cnt} + 8'b1);
    3'b110:  b3_bc_cntL         <=                             8'd32 - ({a2_bc_cnt,1'b0} + 8'd0);
    3'b111:  b3_bc_cntL         <=                             8'd32 - ({a2_bc_cnt,1'b0} + 8'd1);
    endcase   

    casex(a2_bc_cH)
    3'b000:  b3_bc_cntH        <=                                       {1'b0,a2_bc_cnt} + 8'b0;
    3'b001:  b3_bc_cntH        <=                                       {1'b0,a2_bc_cnt} + 8'b1;
    3'b010:  b3_bc_cntH        <=                                       {a2_bc_cnt,1'b0} + 8'd0;
    3'b011:  b3_bc_cntH        <=                                       {a2_bc_cnt,1'b0} + 8'd1;
   
    3'b100:  b3_bc_cntH        <=                             8'd32 - ({1'b0,a2_bc_cnt} + 8'b0);
    3'b101:  b3_bc_cntH        <=                             8'd32 - ({1'b0,a2_bc_cnt} + 8'b1);
    3'b110:  b3_bc_cntH        <=                             8'd32 - ({a2_bc_cnt,1'b0} + 8'd0);
    3'b111:  b3_bc_cntH        <=                             8'd32 - ({a2_bc_cnt,1'b0} + 8'd1);
    endcase   
    
// .... product Ya path ........................................................................

    b3_ry_ena                   <=                                                    a2_ry_ena;
    b3_ry_mcr                   <=                                    a2_ry_ena[1] && a2_cr_ena;
    b3_ry_addr                  <=                                                   a2_ry_addr;
    b3_ry_tag                   <=                                                    a2_ry_tag;
    
    casex(a2_ry_mux)
    2'b00:      b3_ry_dataL     <=                                                  a2_cr_erx_a;
    2'b01:      b3_ry_dataL     <=                                                 PROCESSOR_ID;
    2'b10:      b3_ry_dataL     <=                                   {15'b0,a2_tid,a2_cc_flags};
    2'b11:      b3_ry_dataL     <=                                                 a2_cr_data_a;
    endcase

    casex(a2_ry_mux)
    2'b00:      b3_ry_dataH     <=                                                  a2_cr_erx_b;
    2'b01:      b3_ry_dataH     <=                                                PROCESSOR_CAP;
    2'b10:      b3_ry_dataH     <=                                                        32'd0;
    2'b11:      b3_ry_dataH     <=                                                 a2_cr_data_b;  
    default:    b3_ry_dataH     <=                                                        32'd0;
    endcase

    casex({a2_mm_ena,a2_bc_ena,1'b0})
    3'b1xx:     b3_ry_mux       <=                                                         2'd1;
    3'b01x:     b3_ry_mux       <=                                                         2'd2;
    3'b001:     b3_ry_mux       <=                                                         2'd3;
    default:    b3_ry_mux       <=                                                         2'd0;
    endcase 
    
// .............................................................................................
  end   
//==============================================================================================
// stage a4
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    a4_stb                      <=                                                         1'b0;
    a4_tid                      <=                                                         1'b0;
    a4_asid                     <=                                                         4'b0;
    a4_pid                      <=                                                         2'b0;
    a4_isw                      <=                                                         1'b0;        

     a4_cr_cr6_ena                   <=                                                                     1'b0;
     a4_cr_cnt_L                     <=                                                                 33'b0;
     a4_cr_cnt_H                     <=                                                                 32'b0;
    
    a4_ry_ena                   <=                                                         2'd0;
    a4_ry_mcr                   <=                                                         1'd0;
    a4_ry_addr                  <=                                                         5'd0;
    a4_ry_dataL                 <=                                                        32'd0;
    a4_ry_dataH                 <=                                                        32'd0;
    a4_ry_tag                   <=                                                         2'd0;
    a4_ry_mux                   <=                                                         2'd0;
  end
 else
  begin
    a4_stb                      <=                                                       b3_stb;
    a4_tid                      <=                                                       b3_tid;
    a4_asid                     <=                                                      b3_asid;
    a4_pid                      <=                                                       b3_pid;
    a4_isw                      <=                                                       b3_isw;        

    a4_cr_cr6_ena               <=                                                b3_cr_cr6_ena;
    
    if( b3_tid) a4_cr_cnt_L     <=                                    32'b1 + a4_cr_cnt_L[31:0];
    if(!b3_tid) a4_cr_cnt_H     <=                        a4_cr_cnt_H[31:0] + a4_cr_cnt_L[  32];

// .... product Ya path ........................................................................
    
    a4_ry_ena                   <=                                                    b3_ry_ena;
    a4_ry_mcr                   <=                                                    b3_ry_mcr;
    a4_ry_addr                  <=                                                   b3_ry_addr;
    a4_ry_tag                   <=                                                    b3_ry_tag;   
    
    casex({b3_cr_cr6_ena})
    1'b1:       a4_ry_mux       <=                                                         2'd1;
    1'b0:       a4_ry_mux       <=                                                         2'd0;
    default:    a4_ry_mux       <=                                                         2'd0;
    endcase 

    casex(b3_ry_mux)
    2'b00:      a4_ry_dataL     <=                                                  b3_ry_dataL;
    2'b01:      a4_ry_dataL     <=                                                  b3_mm_dataL;                         
    2'b10:      a4_ry_dataL     <=                                                   b3_bc_cntL;
    2'b11:      a4_ry_dataL     <=                                                        32'd0;
    endcase

    casex(b3_ry_mux)
    2'b00:      a4_ry_dataH     <=                                                  b3_ry_dataH;
    2'b01:      a4_ry_dataH     <=                                                  b3_mm_dataH;
    2'b10:      a4_ry_dataH     <=                                                   b3_bc_cntH;
    2'b11:      a4_ry_dataH     <=                                                        32'd0;
    default:    a4_ry_dataH     <=                                                        32'd0;
     endcase
   
// .............................................................................................
  end   
//==============================================================================================
// stage b5
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    b5_stb                      <=                                                         1'b0;
    b5_tid                      <=                                                         1'b0;
    b5_asid                     <=                                                         4'b0;
    b5_pid                      <=                                                         2'b0;
    b5_isw                      <=                                                         1'b0;        
  end
 else
  begin
    b5_stb                      <=                                                       a4_stb;
    b5_tid                      <=                                                       a4_tid;
    b5_asid                     <=                                                      a4_asid;
    b5_pid                      <=                                                       a4_pid;
    b5_isw                      <=                                                       a4_isw;        
    
// .... product Ya path ........................................................................
                                                                                                                                                                                                                                     
    b5_ry_stb0                  <=                              !a4_tid & (|a4_ry_ena) & a4_stb;
    b5_ry_stb1                  <=                               a4_tid & (|a4_ry_ena) & a4_stb;

    b5_ry_addr                  <=                                                   a4_ry_addr;
    
    b5_ry_enaA                  <=                              {2{a4_stb}} & {2{a4_ry_ena[0]}};
    b5_ry_tagA                  <=                                                 a4_ry_tag[0];
    
    
    b5_ry_enaB                  <=                              {2{a4_stb}} & {2{a4_ry_ena[1]}};       
    b5_ry_modB                  <=                                     a4_ry_mcr | (&a4_ry_ena);
    b5_ry_tagB                  <=                                                 a4_ry_tag[1];
    
    case(a4_ry_mux)
    1'b0: b5_ry_dataL           <=                                                  a4_ry_dataL;
    1'b1: b5_ry_dataL           <=                                                  a4_cr_cnt_L;
    endcase

    case(a4_ry_mux)
    1'b0: b5_ry_dataH           <=                                                  a4_ry_dataH;
    1'b1: b5_ry_dataH           <=                                                  a4_cr_cnt_H;
    endcase    
    
// .............................................................................................
  end   
//==============================================================================================
// write back (long path)
//==============================================================================================
assign  wbb_stb0             =                                                       b5_ry_stb0; 
assign  wbb_stb1             =                                                       b5_ry_stb1; 

assign  wbb_enaA             =                                                       b5_ry_enaA; 
assign  wbb_tagA             =                                                       b5_ry_tagA;

assign  wbb_enaB             =                                                       b5_ry_enaB; 
assign  wbb_modB             =                                                       b5_ry_modB;
assign  wbb_tagB             =                                                       b5_ry_tagB;

assign  wbb_addr             =                                                       b5_ry_addr; 
assign  wbb_dataL            =                                                      b5_ry_dataL;
assign  wbb_dataH            =                                                      b5_ry_dataH;
//==============================================================================================
endmodule