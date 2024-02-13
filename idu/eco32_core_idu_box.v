//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_idu_box
(
 input  wire            clk,
 input  wire            rst,
 
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

 input  wire            i_ins_cnd_ena,
 input  wire     [5:0]  i_ins_cnd_val,
 input  wire     [5:0]  i_ins_rya,
 input  wire            i_ins_ryz,
 input  wire    [31:0]  i_ins_opc,
 input  wire    [31:0]  i_ins_const,
 
 input  wire            i_evt_req,
 input  wire     [2:0]  i_evt_eid,
 
 input  wire            wr0_clr,
 input  wire     [4:0]  wr0_addr,
 input  wire     [1:0]  wr0_a_ena,
 input  wire     [3:0]  wr0_a_ben,
 input  wire    [31:0]  wr0_a_data,
 input  wire            wr0_a_tag,
 input  wire     [1:0]  wr0_b_ena,
 input  wire     [3:0]  wr0_b_ben,
 input  wire    [31:0]  wr0_b_data,
 input  wire            wr0_b_tag,

 input  wire            wr1_clr,
 input  wire     [4:0]  wr1_addr,
 input  wire     [1:0]  wr1_a_ena,
 input  wire     [3:0]  wr1_a_ben,
 input  wire    [31:0]  wr1_a_data,
 input  wire            wr1_a_tag,
 input  wire     [1:0]  wr1_b_ena,
 input  wire     [3:0]  wr1_b_ben,
 input  wire    [31:0]  wr1_b_data,
 input  wire            wr1_b_tag,

 input  wire     [1:0]  lc_ry_enaG,
 input  wire     [1:0]  lc_ry_enaT0,
 input  wire     [1:0]  lc_ry_enaT1,
 input  wire     [4:0]  lc_ry_addr,
 input  wire     [1:0]  lc_ry_tag,
 
 input  wire            fci_inst_rep,
 input  wire            fci_inst_jpf,
 input  wire            fci_inst_lsf,
 
 output wire            o_stb,
 output wire            o_tid,
 output wire     [3:0]  o_asid,
 output wire     [1:0]  o_pid,
 output wire    [15:0]  o_isw,
 output wire     [1:0]  o_isz,
 output wire    [31:0]  o_iva,
 output wire    [31:0]  o_iop,
 output wire    [31:0]  o_iex,
 output wire     [3:0]  o_erx,
 output wire     [8:0]  o_wrx,

 output wire            o_evt_req,
 output wire     [2:0]  o_evt_eid,
 
 output wire    [31:0]  o_r0_data,                        
 output wire            o_r0_locked,
 output wire    [31:0]  o_r1_data,
 output wire            o_r1_locked,
 output wire    [31:0]  o_r2_data,
 output wire            o_r2_locked,
 output wire    [31:0]  o_r3_data,
 output wire            o_r3_locked,

 output wire     [1:0]  o_ry_ena,
 output wire     [4:0]  o_ry_addr,
 output wire     [1:0]  o_ry_tag,
 output wire     [1:0]  o_ry_locked,

 output wire     [7:0]  o_cc_cw,
 output wire     [5:0]  o_ar_cw,
 output wire     [3:0]  o_lo_cw,
 output wire     [4:0]  o_sh_cw,
 output wire     [4:0]  o_sh_val,
 output wire     [5:0]  o_mm_cw,
 output wire     [1:0]  o_ds_cw,
 output wire     [9:0]  o_bc_cw,
 output wire    [14:0]  o_ls_cw,
 output wire    [20:0]  o_jp_cw,
 output wire     [9:0]  o_jp_arg,
 output wire     [2:0]  o_dc_cw,
 output wire     [3:0]  o_fr_cw,
 output wire     [7:0]  o_fl_cw,
 output wire     [6:0]  o_ft_cw,
 output wire     [5:0]  o_ml_cw,
 output wire     [8:0]  o_cr_cw
);                             
//==============================================================================================
// parameters
//==============================================================================================
parameter               FORCE_RST   =     0;
//==============================================================================================
// variables
//==============================================================================================
                            wire     [4:0]  map_r0_addr;
                            wire            map_r0_ena;
                            wire            map_r0_bank;
                            wire            map_r0_mode;
                            wire     [1:0]  map_r0_ctype;
//----------------------------------------------------------------------------------------------
                            wire     [4:0]  map_r1_addr;
                            wire            map_r1_ena;
                            wire            map_r1_bank;
                            wire            map_r1_mode; 
                            wire     [1:0]  map_r1_ctype;
//----------------------------------------------------------------------------------------------
                            wire     [4:0]  map_r2_addr;
                            wire            map_r2_ena;
                            wire            map_r2_bank;
                            wire            map_r2_mode; 
                            wire     [1:0]  map_r2_ctype;
//----------------------------------------------------------------------------------------------
                            wire     [4:0]  map_r3_addr;
                            wire            map_r3_ena;
                            wire            map_r3_bank;
                            wire            map_r3_mode; 
                            wire     [1:0]  map_r3_ctype;
//----------------------------------------------------------------------------------------------
                            wire     [4:0]  map_ry_addr;
                            wire     [1:0]  map_ry_ena;
//----------------------------------------------------------------------------------------------
                            wire     [3:0]  map_ud_mode;
                            wire            map_ud_udi;
//----------------------------------------------------------------------------------------------                                                                                                                
(* shreg_extract = "NO"  *) reg             a0_stb;
(* shreg_extract = "NO"  *) reg             a0_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  a0_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  a0_isw;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_isz;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_iva;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_iop;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_iex;
(* shreg_extract = "NO"  *) reg      [3:0]  a0_erx;
(* shreg_extract = "NO"  *) reg      [8:0]  a0_wrx;

(* shreg_extract = "NO"  *) reg             a0_ins_cnd_ena;  
(* shreg_extract = "NO"  *) reg      [5:0]  a0_ins_cnd_val;                                             
(* shreg_extract = "NO"  *) reg      [5:0]  a0_ins_rya;  
(* shreg_extract = "NO"  *) reg             a0_ins_ryz;  
(* shreg_extract = "NO"  *) reg     [31:0]  a0_ins_opc;                                             
(* shreg_extract = "NO"  *) reg     [31:0]  a0_ins_const;
(* shreg_extract = "NO"  *) reg             a0_evt_req;  
(* shreg_extract = "NO"  *) reg      [2:0]  a0_evt_eid;  

(* shreg_extract = "NO"  *) reg      [1:0]  a0_ry_ena;
(* shreg_extract = "NO"  *) reg      [4:0]  a0_ry_addr;

(* shreg_extract = "NO"  *) reg             a0_z0;
(* shreg_extract = "NO"  *) reg             a0_e0;
(* shreg_extract = "NO"  *) reg             a0_b0;
(* shreg_extract = "NO"  *) reg             a0_m0;
(* shreg_extract = "NO"  *) reg      [4:0]  a0_r0;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_const0;

(* shreg_extract = "NO"  *) reg             a0_z1;
(* shreg_extract = "NO"  *) reg             a0_e1;
(* shreg_extract = "NO"  *) reg             a0_b1;
(* shreg_extract = "NO"  *) reg             a0_m1;
(* shreg_extract = "NO"  *) reg      [4:0]  a0_r1;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_const1;

(* shreg_extract = "NO"  *) reg             a0_z2;
(* shreg_extract = "NO"  *) reg             a0_e2;
(* shreg_extract = "NO"  *) reg             a0_b2;
(* shreg_extract = "NO"  *) reg             a0_m2;
(* shreg_extract = "NO"  *) reg      [4:0]  a0_r2;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_const2;

(* shreg_extract = "NO"  *) reg             a0_z3;
(* shreg_extract = "NO"  *) reg             a0_e3;
(* shreg_extract = "NO"  *) reg             a0_b3;
(* shreg_extract = "NO"  *) reg             a0_m3;
(* shreg_extract = "NO"  *) reg      [4:0]  a0_r3;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_const3;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b1_stb;
(* shreg_extract = "NO"  *) reg             b1_rep;
(* shreg_extract = "NO"  *) reg             b1_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  b1_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  b1_isw;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_isz;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_iva;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_iop;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_iex;
(* shreg_extract = "NO"  *) reg      [3:0]  b1_erx;
(* shreg_extract = "NO"  *) reg      [8:0]  b1_wrx;

(* shreg_extract = "NO"  *) reg             b1_ins_cnd_ena;  
(* shreg_extract = "NO"  *) reg      [5:0]  b1_ins_cnd_val;  
(* shreg_extract = "NO"  *) reg      [5:0]  b1_ins_rya;  
(* shreg_extract = "NO"  *) reg             b1_ins_ryz;  
(* shreg_extract = "NO"  *) reg     [31:0]  b1_ins_opc;  
(* shreg_extract = "NO"  *) reg     [31:0]  b1_ins_const;
(* shreg_extract = "NO"  *) reg             b1_evt_req;  
(* shreg_extract = "NO"  *) reg      [2:0]  b1_evt_eid;  

                            wire    [31:0]  b1_r0_data;
                            wire            b1_r0_locked;

                            wire    [31:0]  b1_r1_data;
                            wire            b1_r1_locked;

                            wire    [31:0]  b1_r2_data;
                            wire            b1_r2_locked;

                            wire    [31:0]  b1_r3_data;
                            wire            b1_r3_locked;

                            wire     [1:0]  b1_ry_ena; 
                            wire     [4:0]  b1_ry_addr;
                            wire     [1:0]  b1_ry_tag; 
                            wire     [1:0]  b1_ry_locked;

                            wire     [7:0]  b1_cc_cw;
                            wire     [5:0]  b1_ar_cw;
                            wire     [3:0]  b1_lo_cw;
                            wire     [4:0]  b1_sh_cw;
                            wire     [4:0]  b1_sh_val;
                            wire    [14:0]  b1_ls_cw;
                            wire    [20:0]  b1_jp_cw;
                            wire     [9:0]  b1_jp_arg;
                            wire     [2:0]  b1_dc_cw;
                            wire     [3:0]  b1_fr_cw;
                            wire     [5:0]  b1_ml_cw;
                            wire     [7:0]  b1_fl_cw;
                            wire     [6:0]  b1_ft_cw;
                            wire     [6:0]  b1_mm_cw;
                            wire     [1:0]  b1_ds_cw;
                            wire     [8:0]  b1_cr_cw;
                            wire     [9:0]  b1_bc_cw;
//==============================================================================================
// stage (a)0:  
//==============================================================================================
// aliases
//==============================================================================================
wire    [4:0]   f_ra        =                                                  i_ins_opc[23:19];
wire            f_ba        =                                                  i_ins_opc[   24];

wire    [4:0]   f_rb        =                                                  i_ins_opc[ 5: 1];
wire            f_bb        =                                                  i_ins_opc[    6];

wire    [4:0]   f_rc        =                                                  i_ins_opc[11: 7];
wire            f_bc        =                                                  i_ins_opc[   12];

wire    [4:0]   f_ry        =                                                  i_ins_rya[ 4: 0];
wire            f_by        =                                                  i_ins_rya[    5];
wire            f_zy        =                                                  i_ins_ryz;

wire    [4:0]   f_cc        =                                                  i_ins_opc[23:19];

wire    [2:0]   f_vec       =                                                  i_ins_opc[ 2: 0];
//----------------------------------------------------------------------------------------------
wire    [5:0]   f_mopc      =                                                  i_ins_opc[31:26];
wire    [3:0]   f_sopc      =                                                  i_ins_opc[ 5: 2];
//----------------------------------------------------------------------------------------------
wire            f_m         =                                                  i_ins_opc[   25];
wire            f_p0        =                                                  i_ins_opc[    0];
wire            f_p1        =                                                  i_ins_opc[   12];
wire            f_cr        =                                                  i_ins_opc[    1];
wire    [1:0]   f_vt        =                                                  i_ins_opc[17:16];
//----------------------------------------------------------------------------------------------
wire            f_xa        =                                                  i_ins_opc[ 2: 1];
wire            f_xb        =                                                  i_ins_opc[ 4: 3];
wire            f_xc        =                                                  i_ins_opc[ 6: 5];
//----------------------------------------------------------------------------------------------
eco32_core_idu_r0t r0_tab
(
.i_mopc         (f_mopc),
.i_sopc         (f_sopc),
.i_m            (f_m),
.i_p0           (f_p0),

.i_ra           (f_ra),
.i_ba           (f_ba),

.i_rb           (f_rb),
.i_bb           (f_bb),

.i_rc           (f_rc),
.i_bc           (f_bc),

.i_ry           (f_ry),
.i_by           (f_by),

.o_ena          (map_r0_ena),
.o_bank         (map_r0_bank),
.o_addr         (map_r0_addr),
.o_mode         (map_r0_mode),
.o_c_type       (map_r0_ctype) 
);
//----------------------------------------------------------------------------------------------
eco32_core_idu_r1t r1_tab
(
.i_mopc         (f_mopc),
.i_sopc         (f_sopc),
.i_m            (f_m),
.i_p0           (f_p0),

.i_ra           (f_ra),
.i_ba           (f_ba),

.i_rb           (f_rb),
.i_bb           (f_bb),

.i_rc           (f_rc),
.i_bc           (f_bc),

.i_ry           (f_ry),
.i_by           (f_by),

.o_ena          (map_r1_ena),
.o_bank         (map_r1_bank),
.o_addr         (map_r1_addr),
.o_mode         (map_r1_mode),
.o_c_type       (map_r1_ctype) 
);
//----------------------------------------------------------------------------------------------
eco32_core_idu_r2t r2_tab
(
.i_mopc         (f_mopc),
.i_sopc         (f_sopc),
.i_m            (f_m),
.i_p0           (f_p0),

.i_ra           (f_ra),
.i_ba           (f_ba),

.i_rb           (f_rb),
.i_bb           (f_bb),

.i_rc           (f_rc),
.i_bc           (f_bc),

.i_ry           (f_ry),
.i_by           (f_by),

.o_ena          (map_r2_ena),
.o_bank         (map_r2_bank),
.o_addr         (map_r2_addr),
.o_mode         (map_r2_mode),
.o_c_type       (map_r2_ctype) 
);
//----------------------------------------------------------------------------------------------
eco32_core_idu_r3t r3_tab
(
.i_mopc     (f_mopc),
.i_sopc     (f_sopc),
.i_m        (f_m),
.i_p0       (f_p0),

.i_ra       (f_ra),
.i_ba       (f_ba),

.i_rb       (f_rb),
.i_bb       (f_bb),

.i_rc       (f_rc),
.i_bc       (f_bc),

.i_ry       (f_ry),
.i_by       (f_by),

.o_ena      (map_r3_ena),
.o_bank     (map_r3_bank),
.o_addr     (map_r3_addr),
.o_mode     (map_r3_mode),
.o_c_type   (map_r3_ctype)
);
//----------------------------------------------------------------------------------------------
eco32_core_idu_ryt ry_tab
(
.i_mopc     (f_mopc),
.i_sopc     (f_sopc),
.i_m        (f_m),
.i_p0       (f_p0),

.i_ry       (f_ry),
.i_by       (f_by),
.i_zy       (f_zy),

.o_ena      (map_ry_ena),
.o_addr     (map_ry_addr)
);
//----------------------------------------------------------------------------------------------
eco32_core_idu_udt undef_tab
(
.i_mopc     (f_mopc),
.i_sopc     (f_sopc),
.i_m        (f_m),
.i_p0       (f_p0),
.i_p1       (f_p1),

.i_ra       (f_ra),
.i_ba       (f_ba),

.i_rb       (f_rb),
.i_bb       (f_bb),

.i_rc       (f_rc),
.i_bc       (f_bc),

.i_ry       (f_ry),
.i_by       (f_by),

.o_udi      (map_ud_udi),
.o_mode     (map_ud_mode)
);
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a0_stb              <=                                                                  'd0;
    a0_tid              <=                                                                  'd0;
    a0_asid             <=                                                                  'd0;
    a0_pid              <=                                                                  'd0;
    a0_isw              <=                                                                  'd0;        
    a0_isz              <=                                                                  'd0;
    a0_iva              <=                                                                  'd0;
    a0_iop              <=                                                                  'd0;
    a0_iex              <=                                                                  'd0;
    a0_erx              <=                                                                  'd0;
    a0_wrx              <=                                                                  'd0;

    a0_ins_cnd_ena      <=                                                                  'd0;
    a0_ins_cnd_val      <=                                                                  'd0;
    a0_ins_rya          <=                                                                  'd0;
    a0_ins_ryz          <=                                                                  'd0;
    a0_ins_opc          <=                                                                  'd0;
    a0_ins_const        <=                                                                  'd0;
    
    a0_evt_req          <=                                                                  'd0;
    a0_evt_eid          <=                                                                  'd0;
    
    a0_z0               <=                                                                  'd0;                                                      
    a0_e0               <=                                                                  'd0;                                                      
    a0_b0               <=                                                                  'd0;                                                      
    a0_m0               <=                                                                  'd0;                                                      
    a0_r0               <=                                                                  'd0;                                                      
    a0_const0           <=                                                                  'd0;                                                      
    
    a0_z1               <=                                                                  'd0;                                                      
    a0_e1               <=                                                                  'd0;                                                      
    a0_b1               <=                                                                  'd0;                                                      
    a0_m1               <=                                                                  'd0;                                                      
    a0_r1               <=                                                                  'd0;                                                      
    a0_const1           <=                                                                  'd0;                                                      

    a0_z2               <=                                                                  'd0;                                                      
    a0_e2               <=                                                                  'd0;                                                      
    a0_b2               <=                                                                  'd0;                                                      
    a0_m2               <=                                                                  'd0;                                                      
    a0_r2               <=                                                                  'd0;                                                      
    a0_const2           <=                                                                  'd0;                                                      
    
    a0_z3               <=                                                                  'd0;                                                      
    a0_e3               <=                                                                  'd0;                                                      
    a0_b3               <=                                                                  'd0;                                                      
    a0_m3               <=                                                                  'd0;                                                      
    a0_r3               <=                                                                  'd0;                                                      
    a0_const3           <=                                                                  'd0;                                                      
  end
 else
  begin  
    a0_stb              <=                                               !fci_inst_jpf && i_stb;
    a0_tid              <=                                                                i_tid;
    a0_asid             <=                                                               i_asid;
    a0_pid              <=                                                                i_pid;
    a0_isw              <=                                                                i_isw;
    a0_isz              <=                                                                i_isz;
    a0_iva              <=                                                                i_iva;
    a0_iop              <=                                                                i_iop;
    a0_iex              <=                                                                i_iex;
    a0_erx              <=                                                                i_erx;
    a0_wrx              <=                                                                i_wrx;
    
    a0_ins_cnd_ena      <=                                                        i_ins_cnd_ena;
    a0_ins_cnd_val      <=                                                        i_ins_cnd_val;
    a0_ins_rya          <=                                                            i_ins_rya;
    a0_ins_ryz          <=                                                            i_ins_ryz;
    a0_ins_opc          <=                                                            i_ins_opc;
    a0_ins_const        <=                                                          i_ins_const;
    
    a0_evt_req          <=                                                            i_evt_req;
    a0_evt_eid          <=                                                            i_evt_eid;
    
    a0_z0               <=                                                      !(|map_r0_addr);
    a0_e0               <=                                                           map_r0_ena;
    a0_b0               <=                                                          map_r0_bank;
    a0_m0               <=                                                          map_r0_mode;
    a0_r0               <=                                                          map_r0_addr;
    a0_const0           <=                                                                i_iva; // PC counter
    
    a0_z1               <=                                                      !(|map_r1_addr);
    a0_e1               <=                                                           map_r1_ena;
    a0_b1               <=                                                          map_r1_bank;
    a0_m1               <=                                                          map_r1_mode;
    a0_r1               <=                                                          map_r1_addr;
    a0_const1           <=                                                          i_ins_const; // const | offset | addr

    a0_z2               <=                                                      !(|map_r2_addr);
    a0_e2               <=                                                           map_r2_ena;
    a0_b2               <=                                                          map_r2_bank;
    a0_m2               <=                                                          map_r2_mode;
    a0_r2               <=                                                          map_r2_addr;                
    a0_const2           <= (map_r2_ctype == 2'd0)?                                  i_ins_const: // const
                           (map_r2_ctype == 2'd1)?                         {1'd0, 8'h7F, 23'd0}: // float 1 
                                                           {25'd0,i_isw[11],6'd0} + i_ins_const; // PageBreak (LSU)
    
    
    a0_z3               <=                                                      !(|map_r3_addr);
    a0_e3               <=                                                           map_r3_ena;
    a0_b3               <=                                                          map_r3_bank;
    a0_m3               <=                                                          map_r3_mode;
    a0_r3               <=                                                          map_r3_addr;
    a0_const3           <= (map_r3_ctype == 2'd3)?                                  i_ins_const: //  const
                           (map_r3_ctype == 2'd1)?                         {1'd0, 8'h7F, 23'd0}: // float 1
                         /*(map_r3_ctype == 2'd2)?*/                                      32'd1; // int 1;  
    
    a0_ry_ena           <= (i_evt_req)?                                      2'b0 :  map_ry_ena;
    a0_ry_addr          <=                                                          map_ry_addr;
  end
//==============================================================================================
// stage (b)5:  
//============================================================================================== 
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b1_stb              <=                                                                  'd0;
    b1_tid              <=                                                                  'd0;
    b1_asid             <=                                                                  'd0;
    b1_pid              <=                                                                  'd0;
    b1_isw              <=                                                                  'd0;
    b1_isz              <=                                                                  'd0;
    b1_iva              <=                                                                  'd0;
    b1_iop              <=                                                                  'd0;
    b1_iex              <=                                                                  'd0;
    b1_erx              <=                                                                  'd0;
    b1_wrx              <=                                                                  'd0;

    b1_ins_cnd_ena      <=                                                                  'd0;
    b1_ins_cnd_val      <=                                                                  'd0;
    b1_ins_rya          <=                                                                  'd0;
    b1_ins_ryz          <=                                                                  'd0;
    b1_ins_opc          <=                                                                  'd0;
    b1_ins_const        <=                                                                  'd0;
    
    b1_evt_req          <=                                                                  'd0;
    b1_evt_eid          <=                                                                  'd0;
  end
 else
  begin  
    b1_stb              <=                             !fci_inst_lsf && !fci_inst_rep && a0_stb;
    b1_rep              <=                             !fci_inst_lsf &&  fci_inst_rep && a0_stb;
    b1_tid              <=                                                               a0_tid;
    b1_asid             <=                                                              a0_asid;
    b1_pid              <=                                                               a0_pid;
    b1_isw              <=                                                               a0_isw;
    b1_isz              <=                                                               a0_isz;
    b1_iva              <=                                                               a0_iva;
    b1_iop              <=                                                               a0_iop;
    b1_iex              <=                                                               a0_iex;
    b1_erx              <=                                                               a0_erx;
    b1_wrx              <=                                                               a0_wrx;
    
    b1_ins_cnd_ena      <=                                                       a0_ins_cnd_ena;
    b1_ins_cnd_val      <=                                                       a0_ins_cnd_val;
    b1_ins_rya          <=                                                           a0_ins_rya;
    b1_ins_ryz          <=                                                           a0_ins_ryz;
    b1_ins_opc          <=                                                           a0_ins_opc;
    b1_ins_const        <=                                                         a0_ins_const;
      
    b1_evt_req          <=                                                           a0_evt_req;
    b1_evt_eid          <=                                                           a0_evt_eid;
  end
//----------------------------------------------------------------------------------------------
eco32_core_idu_cwd
#(
.FORCE_RST          (FORCE_RST)
)   
cwd
(
.clk                (clk),
.rst                (rst),

.i_stb              (a0_stb),
.i_tid              (a0_tid),
.i_pid              (a0_pid),
.i_isw              (a0_isw),
.i_iva              (a0_iva),            

.i_opc_cnd_ena      (a0_ins_cnd_ena),
.i_opc_cnd_val      (a0_ins_cnd_val),
.i_opc_vect         (a0_ins_opc),
.i_evt_req          (a0_evt_req),

.o_cc_cw            (b1_cc_cw),
.o_ar_cw            (b1_ar_cw),
.o_lo_cw            (b1_lo_cw),
.o_sh_cw            (b1_sh_cw),
.o_sh_val           (b1_sh_val),
.o_mm_cw            (b1_mm_cw),
.o_ds_cw            (b1_ds_cw),
.o_bc_cw            (b1_bc_cw),
.o_ls_cw            (b1_ls_cw),
.o_jp_cw            (b1_jp_cw),
.o_jp_arg           (b1_jp_arg),
.o_dc_cw            (b1_dc_cw),
.o_fr_cw            (b1_fr_cw),
.o_fl_cw            (b1_fl_cw),
.o_ft_cw            (b1_ft_cw),
.o_ml_cw            (b1_ml_cw),
.o_cr_cw            (b1_cr_cw)
);   
//----------------------------------------------------------------------------------------------
eco32_core_idu_rfu_box
#(
.FORCE_RST          (FORCE_RST)
) 
rfu
(
.clk                (clk),
.rst                (rst),

.i_tid              (a0_tid),

.i_r0_addr          (a0_r0),
.i_r0_ena           (a0_e0),
.i_r0_bank          (a0_b0),
.i_r0_mode          (a0_m0),
.i_r0_const         (a0_const0),

.i_r1_addr          (a0_r1),          
.i_r1_ena           (a0_e1),
.i_r1_bank          (a0_b1),
.i_r1_mode          (a0_m1),
.i_r1_const         (a0_const1),

.i_r2_addr          (a0_r2),          
.i_r2_ena           (a0_e2),
.i_r2_bank          (a0_b2),
.i_r2_mode          (a0_m2),
.i_r2_const         (a0_const2),

.i_r3_addr          (a0_r3),          
.i_r3_ena           (a0_e3),
.i_r3_bank          (a0_b3),
.i_r3_mode          (a0_m3),
.i_r3_const         (a0_const3),

.i_ry_addr          (a0_ry_addr),                 
.i_ry_ena           (a0_ry_ena),

.wr0_clr            (wr0_clr),
.wr0_addr           (wr0_addr),

.wr0_a_ena          (wr0_a_ena),
.wr0_a_ben          (wr0_a_ben),
.wr0_a_data         (wr0_a_data),
.wr0_a_tag          (wr0_a_tag),

.wr0_b_ena          (wr0_b_ena),
.wr0_b_ben          (wr0_b_ben),
.wr0_b_data         (wr0_b_data),
.wr0_b_tag          (wr0_b_tag),

.wr1_clr            (wr1_clr),
.wr1_addr           (wr1_addr),

.wr1_a_ena          (wr1_a_ena),
.wr1_a_ben          (wr1_a_ben),
.wr1_a_data         (wr1_a_data),
.wr1_a_tag          (wr1_a_tag),

.wr1_b_ena          (wr1_b_ena),
.wr1_b_ben          (wr1_b_ben),
.wr1_b_data         (wr1_b_data),
.wr1_b_tag          (wr1_b_tag),

.lc_ry_enaG         (lc_ry_enaG),
.lc_ry_enaT0        (lc_ry_enaT0),
.lc_ry_enaT1        (lc_ry_enaT1),
.lc_ry_addr         (lc_ry_addr),
.lc_ry_tag          (lc_ry_tag),

.o_r0_data          (b1_r0_data),
.o_r0_locked        (b1_r0_locked),

.o_r1_data          (b1_r1_data),
.o_r1_locked        (b1_r1_locked),

.o_r2_data          (b1_r2_data),
.o_r2_locked        (b1_r2_locked),

.o_r3_data          (b1_r3_data),
.o_r3_locked        (b1_r3_locked),

.o_ry_ena           (b1_ry_ena),     
.o_ry_addr          (b1_ry_addr),     
.o_ry_tag           (b1_ry_tag),     
.o_ry_locked        (b1_ry_locked)
);                             
//==============================================================================================
// output
//==============================================================================================
assign  o_stb           =                                                                b1_stb;
assign  o_tid           =                                                                b1_tid;
assign  o_asid          =                                                               b1_asid;
assign  o_pid           =                                                                b1_pid;                     
assign  o_isw           =                                                                b1_isw;
assign  o_isz           =                                                                b1_isz;
assign  o_iva           =                                                                b1_iva;
assign  o_iop           =                                                                b1_iop;
assign  o_iex           =                                                                b1_iex;
assign  o_erx           =                                                                b1_erx;
assign  o_wrx           =                                                                b1_wrx;
assign  o_evt_req       =                                                            b1_evt_req;
assign  o_evt_eid       =                                                            b1_evt_eid;
//----------------------------------------------------------------------------------------------
assign  o_r0_data       =                                                            b1_r0_data;
assign  o_r0_locked     =                                                          b1_r0_locked;
assign  o_r1_data       =                                                            b1_r1_data;
assign  o_r1_locked     =                                                          b1_r1_locked;
assign  o_r2_data       =                                                            b1_r2_data;
assign  o_r2_locked     =                                                          b1_r2_locked;
assign  o_r3_data       =                                                            b1_r3_data;
assign  o_r3_locked     =                                                          b1_r3_locked;
//----------------------------------------------------------------------------------------------
assign  o_ry_ena        =                                                             b1_ry_ena;
assign  o_ry_addr       =                                                            b1_ry_addr;
assign  o_ry_tag        =                                                             b1_ry_tag;
assign  o_ry_locked     =                                                          b1_ry_locked;
//----------------------------------------------------------------------------------------------
assign  o_cc_cw         =                                                              b1_cc_cw;
assign  o_ar_cw         =                                                              b1_ar_cw;
assign  o_lo_cw         =                                                              b1_lo_cw;
assign  o_sh_cw         =                                                              b1_sh_cw;
assign  o_sh_val        =                                                             b1_sh_val;
assign  o_mm_cw         =                                                              b1_mm_cw;
assign  o_ds_cw         =                                                              b1_ds_cw;
assign  o_bc_cw         =                                                              b1_bc_cw;
assign  o_cr_cw         =                                                              b1_cr_cw;
assign  o_ls_cw         =                                                              b1_ls_cw;
assign  o_jp_cw         =                                                              b1_jp_cw;
assign  o_jp_arg        =                                                              b1_jp_arg;
assign  o_dc_cw         =                                                              b1_dc_cw;
assign  o_fr_cw         =                                                              b1_fr_cw;
assign  o_fl_cw         =                                                              b1_fl_cw;
assign  o_ft_cw         =                                                              b1_ft_cw;
assign  o_ml_cw         =                                                              b1_ml_cw;
assign  o_sh_cw         =                                                              b1_sh_cw;
//==============================================================================================   
endmodule