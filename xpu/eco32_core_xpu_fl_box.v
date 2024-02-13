//=============================================================================
//    Main contributors
//      - Jakub Siast         <mailto:jakubsiast@gmail.com>
//=============================================================================
// 1) ftoi dla liczb o module przekraczajcym zakres float zwraca wynik 0. PC 
// zwraca w takim przypadku 0x80000000 niezalenie od znaku liczby na wejciu.
// 2) Dokadno oblicze: 
//  Mul: 25x26, ale moze by 25x34 (bez liczenia bitu znaku, ze znakiem 
//   odpowiednio 26x27 i 26 x 35).  
//   Nie ma zaimplementowanego zaokrglania, a jedynie mantysa jest obcinana do 
//   24 bitw. Powstaj systematyczne bdy zaokrgle w stron zera.
//  Add / Sub: shifter na DSP umoliwia przesunicie o maksymaln warto do 
//   22 bitw. Dla wikszej rnicy wykadnikw mniejsza liczba jest zerowana.
//   Aby wyniki na etapie przesunicia i dodawania mantys byy poprawne
//   wymagany jest shift o 23. Prowadzi to do bdw systematycznych dla liczb 
//   o wykadnikach rnych o 23. Dodatkowo, brak jest zaokrglania wyniku 
//   podobnie jak w przypadku mnoenia. 
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_xpu_fl_box
#(                                                                                                                      
parameter           DSP             =                                                 "DSP48E1", // "DSP48E", "DSP48E1", "DSP48A1", "MUL18x18", "MUL25x18"                                                                
parameter           FORCE_RST       =     0
)
(
 input  wire            clk,
 input  wire            rst,   
                                                   
 input  wire            i_stb,
 input  wire            i_tid,
 input  wire     [1:0]  i_pid,
 input  wire    [15:0]  i_isw,
 input  wire     [1:0]  i_isz,
 input  wire    [31:0]  i_iva, 
 input  wire    [31:0]  i_opc,   
 input  wire    [31:0]  i_ext,   
 
 input  wire     [1:0]  i_clr,  
                              
 input  wire     [2:0]  i_dc_cw,
 input  wire     [3:0]  i_fr_cw,
 input  wire     [5:0]  i_ml_cw,
 input  wire     [7:0]  i_fl_cw,  
                                                              
 input  wire    [31:0]  i_r0_data,   
 input  wire    [31:0]  i_r1_data,  
 input  wire    [31:0]  i_r2_data,
 input  wire    [31:0]  i_r3_data,
                                                              
 input  wire            i_r0_locked,   
 input  wire            i_r1_locked,  
 input  wire            i_r2_locked,
 input  wire            i_r3_locked,                         
 
 input  wire     [1:0]  i_ry_ena,
 input  wire     [4:0]  i_ry_addr,
 input  wire     [1:0]  i_ry_tag,                                                                               
                                                                
 input  wire            fci_inst_jpf, //phase b1
 input  wire            fci_inst_lsf, //phase a0              
 input  wire            fci_inst_rep, //phase a0
 input  wire            fci_inst_skip,//phase a0      
                                                               
 // first XPU write back 
 output wire            wb0_stb0,   
 output wire            wb0_stb1,   
                                
 output wire     [1:0]  wb0_enaA,            
 output wire            wb0_tagA,            
                                             
 output wire     [1:0]  wb0_enaB,            
 output wire            wb0_tagB,            
 output wire            wb0_modB,            
                                            
 output wire     [4:0]  wb0_addr,           
 output wire    [31:0]  wb0_dataL,
 output wire    [31:0]  wb0_dataH, 
 
 // second XPU write back 
 output wire            wb1_stb0, //ry strobe for th0   
 output wire            wb1_stb1, //ry strobe for th1   
                                
 output wire     [1:0]  wb1_enaA, //ry in bank A             
 output wire            wb1_tagA,            
                                             
 output wire     [1:0]  wb1_enaB, //ry in bank B             
 output wire            wb1_tagB,            
 output wire            wb1_modB, //ry in bank B will contain dataH
                                  //if (AB or HL operations)  wb1_modB set 1;
                                  //else                      wb1_modB set 0;
                                            
 output wire     [4:0]  wb1_addr,           
 output wire    [31:0]  wb1_dataL,
 output wire    [31:0]  wb1_dataH
);                                                       
//=============================================================================================
// parameters check
//=============================================================================================   
// pragma translate_off
initial
    begin                                                                                                               
        if((DSP != "DSP48E") && (DSP != "DSP48E1") && (DSP != "DSP48A1") && (DSP != "MUL18x18") && (DSP != "MUL25x18"))  
            begin
            $display( "!!!ERROR!!! DSP = %d, is out of range (\"DSP48E\" \"DSP48E1\" \"DSP48A1\" \"MUL18x18\" \"MUL25x18\")", DSP );
            $finish;
            end
    end
// pragma translate_on  
//==============================================================================================
// 
//==============================================================================================                                                            
wire        ix_stb;
//==============================================================================================
// cw assigments
//==============================================================================================                                                   
wire        f_conv_stb   =  i_dc_cw[ 0];                                                   
wire        f_itof_stb   =  i_dc_cw[ 2] & f_conv_stb;                          
wire        f_ftoi_stb   =  i_dc_cw[ 1] & f_conv_stb;
                                                                      
wire        f_int16_stb  =  i_ml_cw[ 0];
wire        f_int32_stb  =  i_ml_cw[ 1];
wire        f_int16_sub  =  i_ml_cw[ 2]; 
wire        f_int16_add  =  i_ml_cw[ 3] || i_ml_cw[ 4]; 
wire        f_int16_lea  =  i_ml_cw[ 4];
wire        f_op_signed  = !i_ml_cw[ 5];   
//==============================================================================================
// float inf, nan, zero detection
//==============================================================================================                                                   
wire        f_fl_ra_ezero;
wire        f_fl_ra_emax ;
wire        f_fl_ra_mzero;
wire        f_fl_ra_mmax ;
wire        f_fl_ra_nan  ;
wire        f_fl_ra_inf  ;
wire        f_fl_ra_zero ;
                         
wire        f_fl_rb_ezero;
wire        f_fl_rb_emax ;
wire        f_fl_rb_mzero;
wire        f_fl_rb_mmax ;
wire        f_fl_rb_nan  ;
wire        f_fl_rb_inf  ;
wire        f_fl_rb_zero ;
                         
wire        f_fl_rc_ezero;
wire        f_fl_rc_emax ;
wire        f_fl_rc_mzero;
wire        f_fl_rc_mmax ;
wire        f_fl_rc_nan  ;
wire        f_fl_rc_inf  ;
wire        f_fl_rc_zero ;
                         
wire        f_fl_rd_ezero;
wire        f_fl_rd_emax ;
wire        f_fl_rd_mzero;
wire        f_fl_rd_mmax ;
wire        f_fl_rd_nan  ;
wire        f_fl_rd_inf  ;
wire        f_fl_rd_zero ;
                         
wire        f_i_fl_a_gr_c;

wire [ 8:0] i_fl_a_exp; 
wire [23:0] i_fl_a_man;
wire [ 8:0] i_fl_c_exp; 
wire [23:0] i_fl_c_man;

//----------------------------------------------------------------------------------------------
wire [31:0] i_data_con;
//----------------------------------------------------------------------------------------------
wire        f_zf3_pos;
wire        f_zf2_pos;
wire        f_zf1_pos;
wire        f_zf0_pos;
//----------------------------------------------------------------------------------------------
wire        f_of3_pos;
wire        f_of2_pos;
wire        f_of1_pos;
wire        f_of0_pos;
//----------------------------------------------------------------------------------------------
wire        f_zf3_neg;
wire        f_zf2_neg;
wire        f_zf1_neg;
wire        f_zf0_neg;                                     
//==============================================================================================
// XPU float part - just for full XPU
//==============================================================================================                              
wire        f_fl_stb; 
wire        f_fl_simd;
wire        f_fl_mul;
wire        f_fl_div;          
wire        f_fl_sub;                 
wire        f_fl_add; 
wire        f_fl_mul_sub;          
wire        f_fl_mul_add;  
wire        f_fl_neg;
wire        f_fl_abs;
                              
wire        f_fl_sub_or_add; 
//==============================================================================================
wire [31:0] i_fl_ra; 
wire [31:0] i_fl_rb;
wire [31:0] i_fl_rc;
wire [31:0] i_fl_rd;
//==============================================================================================
// input multiplayers mux
//==============================================================================================                                                                                                                         
// mul input data                                                                                                                          
wire [34:0] ix_mul_opa;                                                                                                                    
wire [24:0] ix_mul_opb;                                                                                                                
wire [34:0] ix_mul_opc;                                                                                                                
wire [24:0] ix_mul_opd;  
//==============================================================================================
// stage 0 variables
//==============================================================================================
reg             a0_stb;
reg             a0_tid;
reg     [ 1:0]  a0_pid;
reg     [31:0]  a0_v_addr;
reg     [31:0]  a0_opcode;
reg     [ 4:0]  a0_dst_addr;
reg     [ 1:0]  a0_dst_ena;
reg     [ 1:0]  a0_dst_tag;    
                              
reg             a0_int16_stb; 
reg             a0_int16_add; 
reg             a0_int16_lea;
reg             a0_int16_sub;
reg             a0_int32_stb; 
reg             a0_op_signed;  

reg     [31:0]  a0_ra_data; 
reg     [31:0]  a0_rb_data;  
reg     [31:0]  a0_rc_data; 
reg     [31:0]  a0_rd_data; 

wire            a0x_ins_valid;     
//==============================================================================================                         
reg             a0_itof_stb;  
reg             a0_ftoi_stb;  
reg             a0_fl_stb;
reg             a0_fl_mul;      
reg             a0_fl_add;
reg             a0_fl_sub;
reg             a0_fl_mul_add;
reg             a0_fl_mul_sub;    
reg             a0_fl_neg; 
reg             a0_fl_abs;         
                            
reg             a0_fl_conv_sig;                
reg     [31:0]  a0_data_itof;               
reg     [31:0]  a0_data_ftoi;

reg      [5:0]  a0_fl_ftoi_sh_cnt;
reg      [3:0]  a0_rb_zf;
                                    
reg     [ 7:0]  a0_fl_ra_exp; 
reg             a0_fl_ra_sig;                       
reg             a0_fl_ra_ezero_f;  
reg             a0_fl_ra_emax_f;                    
reg             a0_fl_ra_mzero_f; 
reg             a0_fl_ra_mmax_f;
reg             a0_fl_ra_nan_f;                     
reg             a0_fl_ra_zero_f; 
reg             a0_fl_ra_inf_f; 
                                
reg     [ 7:0]  a0_fl_rb_exp; 
reg             a0_fl_rb_sig;                       
reg             a0_fl_rb_ezero_f;  
reg             a0_fl_rb_emax_f;                    
reg             a0_fl_rb_mzero_f; 
reg             a0_fl_rb_mmax_f;
reg             a0_fl_rb_nan_f;                     
reg             a0_fl_rb_zero_f;   
reg             a0_fl_rb_inf_f;
                                    
reg     [ 7:0]  a0_fl_rc_exp; 
reg             a0_fl_rc_sig;                       
reg             a0_fl_rc_ezero_f;  
reg             a0_fl_rc_emax_f;                    
reg             a0_fl_rc_mzero_f; 
reg             a0_fl_rc_mmax_f;
reg             a0_fl_rc_nan_f;                     
reg             a0_fl_rc_zero_f; 
reg             a0_fl_rc_inf_f;
                               
reg     [ 7:0]  a0_fl_rd_exp;       
reg             a0_fl_rd_sig;                           
reg             a0_fl_rd_ezero_f;  
reg             a0_fl_rd_emax_f;                    
reg             a0_fl_rd_mzero_f; 
reg             a0_fl_rd_mmax_f;
reg             a0_fl_rd_nan_f;                     
reg             a0_fl_rd_zero_f; 
reg             a0_fl_rd_inf_f;
                                  
reg     [ 8:0]  a0_fl_mul_ab_exp; 
reg             a0_fl_mul_ab_sig; 
reg     [ 8:0]  a0_fl_mul_cd_exp; 
reg             a0_fl_mul_cd_sig;                      
//==============================================================================================
// stage b (1) variables
//==============================================================================================
reg             b1_stb;
reg             b1_tid;
reg     [ 1:0]  b1_dst_ena;
reg     [ 1:0]  b1_dst_tag;
reg     [ 1:0]  b1_pid;
reg     [31:0]  b1_v_addr;
reg     [31:0]  b1_opcode; 
reg     [ 4:0]  b1_dst_addr;
reg             b1_int16_stb; 
reg             b1_int16_add;
reg             b1_int16_lea;
reg             b1_int16_sub;
reg             b1_int32_stb;
reg             b1_op_signed;       
                                                  
reg     [31:0]  b1_ra_data;
reg     [31:0]  b1_rb_data;
reg     [31:0]  b1_rc_data;
reg     [31:0]  b1_rd_data; 
//==============================================================================================                               
reg             b1_itof_stb;  
reg             b1_ftoi_stb;  
reg             b1_fl_stb;
reg             b1_fl_mul;      
reg             b1_fl_add;
reg             b1_fl_sub;
reg             b1_fl_mul_add;
reg             b1_fl_mul_sub; 
reg             b1_fl_sub_or_add; 
reg             b1_fl_neg;
reg             b1_fl_abs;   
                          
reg     [63:0]  b1_data_conv;
reg             b1_fl_conv_sig; 
reg     [ 5:0]  b1_fl_sh_cnt;
reg     [ 7:0]  b1_bo_dt_itof;
                                    
reg             b1_fl_ra_nan_f;                     
reg             b1_fl_ra_zero_f; 
reg             b1_fl_ra_inf_f;
                                 
reg             b1_fl_rb_nan_f;                     
reg             b1_fl_rb_zero_f; 
reg             b1_fl_rb_inf_f;
                                  
reg             b1_fl_rc_nan_f;                     
reg             b1_fl_rc_zero_f; 
reg             b1_fl_rc_inf_f;
                                   
reg             b1_fl_rd_nan_f;                     
reg             b1_fl_rd_zero_f; 
reg             b1_fl_rd_inf_f;  
                               
reg     [1:0]   b1_fl_rab_mux; 
reg     [1:0]   b1_fl_rcd_mux;  
                                  
reg     [ 9:0]  b1_fl_mul_ab_exp; 
reg             b1_fl_mul_ab_sig; 
reg     [ 9:0]  b1_fl_mul_cd_exp; 
reg             b1_fl_mul_cd_sig;                   
//==============================================================================================  
// stage a (2) variables
//============================================================================================== 
reg             a2_stb;
reg             a2_tid;
reg     [ 1:0]  a2_dst_ena;
reg     [ 1:0]  a2_dst_tag;
reg      [1:0]  a2_pid;
reg     [31:0]  a2_v_addr;
reg     [31:0]  a2_opcode;
reg      [4:0]  a2_dst_addr;  
                              
reg             a2_int16_stb; 
reg             a2_int16_add;
reg             a2_int16_lea;
reg             a2_int16_sub;
reg             a2_int32_stb;   
reg             a2_op_signed;      

reg     [31:0]  a2_ra_data;
reg     [31:0]  a2_rb_data;
reg     [31:0]  a2_rc_data;
reg     [31:0]  a2_rd_data;                                                                   

wire    [59:0]  a2_ab_mul_data;
wire    [59:0]  a2_cd_mul_data;     

wire    [48:0]  a2x_res_add      ; 
wire    [63:0]  a2x_int32_res    ; 
//==============================================================================================                          
reg             a2_itof_stb;  
reg             a2_ftoi_stb;  
reg             a2_fl_stb;
reg             a2_fl_mul;      
reg             a2_fl_add;
reg             a2_fl_sub;
reg             a2_fl_mul_add;
reg             a2_fl_mul_sub;  
reg             a2_fl_neg;  
reg             a2_fl_abs;     
                       
reg             a2_fl_conv_sig; 

reg    [ 5:0]   a2_fl_sh_cnt;
reg    [63:0]   a2_data_conv;       

reg             a2_fl_rab_mux; 
reg             a2_fl_rcd_mux; 
                                   
reg     [ 7:0]  a2_fl_rab_exp_exe;
reg     [23:0]  a2_fl_rab_man_exe;
reg     [ 7:0]  a2_fl_rcd_exp_exe;
reg     [23:0]  a2_fl_rcd_man_exe;
                                  
reg     [ 8:0]  a2_fl_mul_ab_exp; 
reg             a2_fl_mul_ab_sig; 
reg     [ 8:0]  a2_fl_mul_cd_exp; 
reg             a2_fl_mul_cd_sig;

reg             a2_fl_mul_ab_exp_max;
reg             a2_fl_mul_cd_exp_max; 
reg             a2_fl_mul_ab_exp_amax;
reg             a2_fl_mul_cd_exp_amax;
reg             a2_fl_mul_ab_exp_undf;
reg             a2_fl_mul_cd_exp_undf;  
                                       
wire    [ 8:0]  a2x_fl_mul_ab_exp;  
wire    [23:0]  a2x_fl_mul_ab_man;  
wire    [ 8:0]  a2x_fl_mul_cd_exp;  
wire    [23:0]  a2x_fl_mul_cd_man;  
//==============================================================================================
// stage b (3) variables
//============================================================================================== 
reg             b3_stb;
reg             b3_tid;
reg     [ 1:0]  b3_dst_ena;
reg     [ 1:0]  b3_dst_tag;
reg      [1:0]  b3_pid;
reg     [31:0]  b3_v_addr;
reg     [31:0]  b3_opcode;
reg      [4:0]  b3_dst_addr;  
                              
reg             b3_int16_stb; 
reg             b3_int16_add;
reg             b3_int16_lea;
reg             b3_int16_sub;
reg             b3_int32_stb; 
reg             b3_op_signed;  

reg     [31:0]  b3_ra_data;
reg     [31:0]  b3_rb_data;
reg     [31:0]  b3_rc_data;
reg     [31:0]  b3_rd_data;
                                
reg     [31:0]  b3_int32_res_L;                                                                                                        
reg     [31:0]  b3_int32_res_H;                                                                                                        
reg     [31:0]  b3_int16_res_A;                                                              
reg     [31:0]  b3_int16_res_B;
reg     [48:0]  b3_int_add_a;
reg     [48:0]  b3_int_add_b;
wire    [48:0]  b3x_res_add;
reg     [48:0]  b3_int_add_res; 

reg     [ 3:0]  b3_res_mux;  
reg             b3_wb_A_ena; 
reg             b3_wb_B_ena; 
reg             b3_wb_BA_ena;
//==============================================================================================                          
reg             b3_itof_stb;  
reg             b3_ftoi_stb;
reg             b3_fl_stb;
reg             b3_fl_mul;      
reg             b3_fl_add;
reg             b3_fl_sub;
reg             b3_fl_mul_add;
reg             b3_fl_mul_sub;  
reg             b3_fl_neg;
reg             b3_fl_abs;
reg             b3_fl_part2_ena;   

reg             b3_fl_conv_sig; 

reg             b3_fl_conv;
reg     [31:0]  b3_data_conv; 
reg     [ 7:0]  b3_fl_itof_exp; 
                                  
reg     [ 8:0]  b3_fl_mul_ab_exp;  
reg     [23:0]  b3_fl_mul_ab_man;         
reg             b3_fl_mul_ab_sig;  
reg     [ 8:0]  b3_fl_mul_cd_exp;  
reg     [23:0]  b3_fl_mul_cd_man;         
reg             b3_fl_mul_cd_sig; 
 
wire            b3x_fl_a_gr_b; 
//==============================================================================================
// stage aw4 (4) prepering results for wb0
//==============================================================================================  
reg             aw4_stb;
reg             aw4_tid;
reg     [ 1:0]  aw4_dst_ena;
reg     [ 1:0]  aw4_dst_tag;
reg      [1:0]  aw4_pid;
reg     [31:0]  aw4_v_addr;
reg     [31:0]  aw4_opcode; 
reg      [4:0]  aw4_dst_addr;
                              
reg             aw4_int16_stb; 
reg             aw4_int16_add;
reg             aw4_int16_lea;
reg             aw4_int16_sub;
reg             aw4_int32_stb;
reg             aw4_op_signed; 
                             
reg     [ 2:0]  aw4_res_mux; 
reg             aw4_A_ena;  
reg             aw4_t0_ena;
reg             aw4_t1_ena;
reg     [ 4:0]  aw4_rg_addr;     
reg     [ 1:0]  aw4_tag;     
reg             aw4_B_ena;      
reg             aw4_B_mod; 
reg     [47:0]  aw4_res_add;   
reg     [31:0]  aw4_lo_data;
reg     [31:0]  aw4_hi_data; 
//============================================================================================== 
reg             aw4_itof_stb;  
reg             aw4_ftoi_stb;  
reg             aw4_fl_stb;
reg             aw4_fl_mul;      
reg             aw4_fl_add;
reg             aw4_fl_sub;
reg             aw4_fl_mul_add;
reg             aw4_fl_mul_sub; 
reg             aw4_fl_neg; 
reg             aw4_fl_abs;  
                                                                                                                                                   
reg             aw4_fl_conv;
reg     [31:0]  aw4_data_conv; 
reg     [ 7:0]  aw4_fl_itof_exp;
reg             aw4_fl_conv_sig;      
//==============================================================================================
// stage aw4 (4) prepering results for wb0
//============================================================================================== 
wire    [31:0]  aw4x_itof_data;  
//==============================================================================================
// stage bw5 (5) prepering results for wb0
//============================================================================================== 
reg             bw5_stb0;     
reg             bw5_stb1;     
reg     [ 4:0]  bw5_addr;     
                        
reg     [ 1:0]  bw5_enaA;
reg             bw5_tagA;        
    
reg     [ 1:0]  bw5_enaB; 
reg             bw5_tagB; 
reg             bw5_modB;  
    
reg     [31:0]  bw5_dataL;
reg     [31:0]  bw5_dataH;
//==============================================================================================
// stage a (4) variables
//============================================================================================== 
wire            b3x_free;                                
wire            b3x_src; 
//==============================================================================================
// float flags
//==============================================================================================                                                                        
        assign          f_fl_stb        =                             i_fl_cw[ 0]              ; 
        assign          f_fl_simd       =                             i_fl_cw[ 5]              ; 
        assign          f_fl_mul        =                             i_fl_cw[ 3]              ;
        assign          f_fl_div        =                             i_fl_cw[ 4]              ;                
        assign          f_fl_sub        =                             i_fl_cw[ 1] && !f_fl_simd;                  
        assign          f_fl_add        =                             i_fl_cw[ 2] && !f_fl_simd;  
        assign          f_fl_mul_sub    =                             i_fl_cw[ 1] &&  f_fl_simd;          
        assign          f_fl_mul_add    =                             i_fl_cw[ 2] &&  f_fl_simd; 
        assign          f_fl_neg        =                             i_fl_cw[ 6]              ;
        assign          f_fl_abs        =                             i_fl_cw[ 7]              ;             
        assign          f_fl_sub_or_add =             (i_fl_cw[ 1] || i_fl_cw[ 2])&& !f_fl_simd;
//==============================================================================================
        assign          i_fl_ra         =                                       i_r0_data[31:0]; 
        assign          i_fl_rb         =                                       i_r2_data[31:0]; 
        assign          i_fl_rc         =                                       i_r1_data[31:0]; 
        assign          i_fl_rd         =                                       i_r3_data[31:0]; 
//==============================================================================================
// float inf, nan, zero detection
//============================================================================================== 
        assign          f_fl_ra_ezero   =   i_fl_ra[30:23]                 ==  8'd0;
        assign          f_fl_ra_emax    =   i_fl_ra[30:23]                 ==  8'hFF;
        assign          f_fl_ra_mzero   =   i_fl_ra[22: 0]                 == 23'd0;      
        assign          f_fl_ra_mmax    =   i_fl_ra[22: 0]                 == 23'h7FFFFF; 
        assign          f_fl_ra_nan     =   f_fl_ra_emax  && !f_fl_ra_mzero;  
        assign          f_fl_ra_inf     =   f_fl_ra_emax  &&  f_fl_ra_mzero;
        assign          f_fl_ra_zero    =   f_fl_ra_ezero &&  f_fl_ra_mzero;
                        
        assign          f_fl_rb_ezero   =   i_fl_rb[30:23]                 ==  8'd0;
        assign          f_fl_rb_emax    =   i_fl_rb[30:23]                 ==  8'hFF;
        assign          f_fl_rb_mzero   =   i_fl_rb[22: 0]                 == 23'd0;
        assign          f_fl_rb_mmax    =   i_fl_rb[22: 0]                 == 23'h7FFFFF; 
        assign          f_fl_rb_nan     =   f_fl_rb_emax  && !f_fl_rb_mzero;  
        assign          f_fl_rb_inf     =   f_fl_rb_emax  &&  f_fl_rb_mzero;
        assign          f_fl_rb_zero    =   f_fl_rb_ezero &&  f_fl_rb_mzero; 
                        
        assign          f_fl_rc_ezero   =   i_fl_rc[30:23]                 ==  8'd0;
        assign          f_fl_rc_emax    =   i_fl_rc[30:23]                 ==  8'hFF;
        assign          f_fl_rc_mzero   =   i_fl_rc[22: 0]                 == 23'd0;
        assign          f_fl_rc_mmax    =   i_fl_rc[22: 0]                 == 23'h7FFFFF; 
        assign          f_fl_rc_nan     =   f_fl_rc_emax  && !f_fl_rc_mzero;  
        assign          f_fl_rc_inf     =   f_fl_rc_emax  &&  f_fl_rc_mzero;
        assign          f_fl_rc_zero    =   f_fl_rc_ezero &&  f_fl_rc_mzero;
                        
        assign          f_fl_rd_ezero   =   i_fl_rd[30:23]                 ==  8'd0;
        assign          f_fl_rd_emax    =   i_fl_rd[30:23]                 ==  8'hFF;
        assign          f_fl_rd_mzero   =   i_fl_rd[22: 0]                 == 23'd0;
        assign          f_fl_rd_mmax    =   i_fl_rd[22: 0]                 == 23'h7FFFFF; 
        assign          f_fl_rd_nan     =   f_fl_rd_emax  && !f_fl_rd_mzero;  
        assign          f_fl_rd_inf     =   f_fl_rd_emax  &&  f_fl_rd_mzero;
        assign          f_fl_rd_zero    =   f_fl_rd_ezero &&  f_fl_rd_mzero; 
                        
        assign          f_i_fl_a_gr_c   =         {1'b0, i_fl_ra[30:0]} > {1'b0, i_fl_rc[30:0]};  

        assign          i_fl_a_exp      =                                {1'b0, i_fl_ra[30:23]};  
        assign          i_fl_a_man      =                                {1'b1, i_fl_ra[22: 0]};  
        assign          i_fl_c_exp      =                                {1'b0, i_fl_rc[30:23]};  
        assign          i_fl_c_man      =                                {1'b1, i_fl_rc[22: 0]}; 

//----------------------------------------------------------------------------------------------
        assign          i_data_con      =                                       i_r1_data[31:0];
//----------------------------------------------------------------------------------------------
        assign          f_zf3_pos       =                             i_data_con[31:24] == 8'd0;
        assign          f_zf2_pos       =                             i_data_con[23:16] == 8'd0;
        assign          f_zf1_pos       =                             i_data_con[15: 8] == 8'd0;
        assign          f_zf0_pos       =                             i_data_con[ 7: 0] == 8'd0;
//----------------------------------------------------------------------------------------------
        assign          f_of3_pos       =                            i_data_con[31:24] == 8'hff;
        assign          f_of2_pos       =                            i_data_con[23:16] == 8'hff;
        assign          f_of1_pos       =                            i_data_con[15: 8] == 8'hff;
        assign          f_of0_pos       =                            i_data_con[ 7: 0] == 8'hff; 
//----------------------------------------------------------------------------------------------
// change negative U2 number to positive U2 number:
// 1) less significant zeros and first less significant 1 is not changing
// 2) rest bites are negated
                                 //mlodsze zero                      & teraz zera     //mlodsze nie zero                    & teraz jedynki
        assign          f_zf3_neg       = (f_zf0_pos & f_zf1_pos & f_zf2_pos & f_zf3_pos ) || (!(f_zf0_pos & f_zf1_pos & f_zf2_pos) & f_of3_pos );
                                         //mlodsze zero                      & teraz zera     //mlodsze nie zero                    & teraz jedynki
        assign          f_zf2_neg       = (f_zf0_pos&f_zf1_pos               & f_zf2_pos ) || (!(f_zf0_pos&f_zf1_pos)               & f_of2_pos );
                                         //mlodsze zero                      & teraz zera     //mlodsze nie zero                    & teraz jedynki
        assign          f_zf1_neg       = (f_zf0_pos                         & f_zf1_pos ) || (!f_zf0_pos                           & f_of1_pos );
                                         //                                    teraz zera
        assign          f_zf0_neg       =                                      f_zf0_pos;        
//==============================================================================================                                                                                                                      
generate                                                                                        
if((DSP == "DSP48A1") || (DSP == "MUL18x18"))
    begin : spartan6_mul_op_abcd
        // mul input data a                                                                                                                        
        assign       ix_mul_opa =(f_int16_stb && f_op_signed)?  {{ 3{i_r0_data[31]}}, i_r0_data[31: 0]}: //{19{i_r0_data[15]}, i_r0_data[15: 0]} 
                                 (f_int16_stb &&!f_op_signed)?  {  3'd0,              i_r0_data[31: 0]}: //{19'd0,             i_r0_data[15: 0]} 
                                 (f_int32_stb && f_op_signed)?  {{ 3{i_r0_data[31]}}, i_r0_data[31: 0]}: // first operand fits into multiplyer input (36x25)
                                 (f_int32_stb &&!f_op_signed)?  {  3'd0,              i_r0_data[31: 0]}: // first operand fits into multiplyer input (36x25)  
                                 (f_fl_stb                  )?  {  8'd0, 1'b1,        i_r0_data[22: 0]}: // float
                                                                                                 32'd0;   
        // mul input data b                                                                                                                    
        assign       ix_mul_opb =(f_int16_stb && f_op_signed)?  {{ 2{i_r2_data[15]}}, i_r2_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  2'd0,              i_r2_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {  1'd0,              i_r2_data[16: 0]}: // lower 17 bits form 32 bit int - NO sign extended!
                                 (f_int32_stb &&!f_op_signed)?  {  1'd0,              i_r2_data[16: 0]}: // lower 17 bits form 32 bit int     
                                 (f_fl_stb                  )?  {  1'd0, 1'b1,        i_r2_data[22: 7]}: // float reducted to higher 16 bits + leading 1                
                                                                                                 32'd0;
        // mul input data c                                                                                                                    
        assign       ix_mul_opc =(f_int16_stb && f_op_signed)?  {{ 3{i_r1_data[31]}}, i_r1_data[31: 0]}: //{19{i_r2_data[15]}, i_r2_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  3'd0,              i_r1_data[31: 0]}: //{19'd0,             i_r2_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {{ 3{i_r1_data[31]}}, i_r1_data[31: 0]}: // first operand fits into multiplyer input (36x25) 
                                 (f_int32_stb &&!f_op_signed)?  {  3'd0,              i_r1_data[31: 0]}: // first operand fits into multiplyer input (36x25) 
                                 (f_fl_stb                  )?  { 11'd0, 1'b1,        i_r1_data[22: 0]}: // float
                                                                                                 32'd0;  
        // mul input data d                                                                                                                    
        assign       ix_mul_opd =(f_int16_stb && f_op_signed)?  {{ 2{i_r3_data[15]}}, i_r3_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  2'd0,              i_r3_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {{ 3{i_r3_data[31]}}, i_r3_data[31:17]}: // high 15 bits form 32 bit int -  MAKE sign extended!
                                 (f_int32_stb &&!f_op_signed)?  {  3'd0,              i_r3_data[31:17]}: // high 15 bits form 32 bit int                  
                                 (f_fl_stb                  )?  {  1'd0, 1'b1,        i_r3_data[22: 7]}: // float reducted to higher 16 bits + leading 1
                                                                                                  32'd0;      
    end
else  
    begin : mul_op_abcd 
        // mul input data a 
        assign       ix_mul_opa =(f_int16_stb && f_op_signed)?  {{ 3{i_r0_data[31]}}, i_r0_data[31: 0]}: //{19{i_r0_data[15]}, i_r0_data[15: 0]} 
                                 (f_int16_stb &&!f_op_signed)?  {  3'd0,              i_r0_data[31: 0]}: //{19'd0,             i_r0_data[15: 0]} 
                                 (f_int32_stb && f_op_signed)?  {{ 3{i_r0_data[31]}}, i_r0_data[31: 0]}: // first operand fits into multiplyer input (36x25)
                                 (f_int32_stb &&!f_op_signed)?  {  3'd0,              i_r0_data[31: 0]}: // first operand fits into multiplyer input (36x25)  
                                 (f_fl_stb                  )?  { 11'd0, 1'b1,        i_r0_data[22: 0]}:
                                                                                                  32'd0;   
        // mul input data b                                                                                                                    
        assign       ix_mul_opb =(f_int16_stb && f_op_signed)?  {{ 9{i_r2_data[15]}}, i_r2_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  9'd0,              i_r2_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {  1'd0,              i_r2_data[23: 0]}: // lower 23 bits form 32 bit int - NO sign extended!
                                 (f_int32_stb &&!f_op_signed)?  {  1'd0,              i_r2_data[23: 0]}: // lower 23 bits form 32 bit int               
                                 (f_fl_stb                  )?  {  1'd0, 1'b1,        i_r2_data[22: 0]}:
                                                                                                 32'd0;
                // mul input data c                                                                                                                    
        assign       ix_mul_opc =(f_int16_stb && f_op_signed)?  {{ 3{i_r1_data[31]}}, i_r1_data[31: 0]}: //{19{i_r2_data[15]}, i_r2_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  3'd0,              i_r1_data[31: 0]}: //{19'd0,             i_r2_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {{ 3{i_r1_data[31]}}, i_r1_data[31: 0]}: // first operand fits into multiplyer input (36x25) 
                                 (f_int32_stb &&!f_op_signed)?  {  3'd0,              i_r1_data[31: 0]}: // first operand fits into multiplyer input (36x25)   
                                 (f_fl_stb                  )?  { 11'd0, 1'b1,        i_r1_data[22: 0]}:
                                                                                                  32'd0;  
                // mul input data d                                                                                                                    
        assign       ix_mul_opd =(f_int16_stb && f_op_signed)?  {{ 9{i_r3_data[15]}}, i_r3_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  9'd0,              i_r3_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {{17{i_r3_data[31]}}, i_r3_data[31:24]}: // high 8 bits form 32 bit int -  MAKE sign extended!
                                 (f_int32_stb &&!f_op_signed)?  { 17'd0,              i_r3_data[31:24]}: // high 8 bits form 32 bit int                
                                 (f_fl_stb                  )?  {  1'd0, 1'b1,        i_r3_data[22: 0]}:
                                                                                                  32'd0;
    end 
endgenerate
//==============================================================================================
// stage a (0)
//============================================================================================== 
generate                                                                                                                    
if(DSP == "DSP48A1")         
    begin  : DSP48A1_35x18_mul_ab_cd
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x18_DSP48A1 xmul_ab
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (ix_mul_opa),     
        .i_arg_18       (ix_mul_opb), 
        
        .o_data         (a2_ab_mul_data)
        );
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x18_DSP48A1 xmul_cd
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (ix_mul_opc),     
        .i_arg_18       (ix_mul_opd),  

        .o_data         (a2_cd_mul_data)
        );
//-------------------------------------------------------------------------------------- 
    end 
else if(DSP == "MUL18x18")           
    begin  : def_35x18_mul_ab_cd
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x18_def  
    #(
    .FORCE_RST          (FORCE_RST)
    )
    xmul_ab
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (ix_mul_opa),     
        .i_arg_18       (ix_mul_opb), 
        
        .o_data         (a2_ab_mul_data)
        );
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x18_def 
    #(
    .FORCE_RST          (FORCE_RST)
    )
    xmul_cd
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (ix_mul_opc),     
        .i_arg_18       (ix_mul_opd),  

        .o_data         (a2_cd_mul_data)
        );
//-------------------------------------------------------------------------------------- 
    end 
else if(DSP == "DSP48E")
    begin  : DSP48E_35x25_mul_ab_cd
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x25_DSP48E xmul_ab
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (ix_mul_opa),     
        .i_arg_25       (ix_mul_opb), 
        
        .o_data         (a2_ab_mul_data)
        );
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x25_DSP48E xmul_cd
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (ix_mul_opc),     
        .i_arg_25       (ix_mul_opd),  
        
        .o_data         (a2_cd_mul_data)
        );
//-------------------------------------------------------------------------------------- 
    end   
else if(DSP == "DSP48E1")
    begin  : DSP48E1_35x25_mul_ab_cd
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x25_DSP48E1 xmul_ab
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (ix_mul_opa),     
        .i_arg_25       (ix_mul_opb), 
        
        .o_data         (a2_ab_mul_data)
        );
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x25_DSP48E1 xmul_cd
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (ix_mul_opc),     
        .i_arg_25       (ix_mul_opd),  
        
        .o_data         (a2_cd_mul_data)
        );
//-------------------------------------------------------------------------------------- 
    end   
else  
    begin  : def_35x25_mul_ab_cd
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x25_def 
        #(
        .FORCE_RST          (FORCE_RST)
        )
        xmul_ab
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (ix_mul_opa),     
        .i_arg_25       (ix_mul_opb), 
        
        .o_data         (a2_ab_mul_data)
        );
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x25_def 
        #(
        .FORCE_RST          (FORCE_RST)
        )
        xmul_cd
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (ix_mul_opc),     
        .i_arg_25       (ix_mul_opd),  
        
        .o_data         (a2_cd_mul_data)
        );
//-------------------------------------------------------------------------------------- 
    end   
endgenerate      
//----------------------------------------------------------------------------------------------                                              
assign ix_stb = i_stb & !fci_inst_jpf && (f_conv_stb  || // itof or ftoi
                                          f_int16_stb || 
                                          f_int32_stb || 
                                         (f_fl_stb && (f_fl_mul || (f_fl_sub_or_add && !b3x_free)))); 
//---------------------------------------------------------------------------------------------- 
always@(posedge clk or posedge rst)  
 if(rst) 
  begin                                                                         
    a0_stb                  <=                                                             1'b0;
    a0_tid                  <=                                                             1'b0;
    a0_dst_ena              <=                                                             2'd0;
    a0_dst_tag              <=                                                             2'd0;
    a0_pid                  <=                                                             2'd0;
    a0_v_addr               <=                                                            32'd0;
    a0_opcode               <=                                                            32'd0; 
    a0_dst_addr             <=                                                             5'd0;
           
    a0_int16_stb            <=                                                             1'b0;  
    a0_int16_add            <=                                                             1'b0;
    a0_int16_lea            <=                                                             1'b0;
    a0_int16_sub            <=                                                             1'b0;
    a0_int32_stb            <=                                                             1'b0;
    a0_op_signed            <=                                                             1'b0; 
    
    a0_ra_data              <=                                                            32'd0;
    a0_rb_data              <=                                                            32'd0;                                                             
    a0_rc_data              <=                                                            32'd0;
    a0_rd_data              <=                                                            32'd0;
  end
 else                                           
  begin
    a0_stb                  <=                                                           ix_stb;
    a0_tid                  <=                                                            i_tid;
    a0_dst_ena              <=                                                         i_ry_ena;
    a0_dst_tag              <=                                                         i_ry_tag;
    a0_pid                  <=                                                            i_pid;
    a0_v_addr               <=                                                            i_iva;
    a0_opcode               <=                                                            i_opc;
    a0_dst_addr             <=                                                        i_ry_addr;  
                                                                                                 
    a0_int16_stb            <=                                                     f_int16_stb ; 
    a0_int16_add            <=                                                     f_int16_add ;
    a0_int16_lea            <=                                                     f_int16_lea ;
    a0_int16_sub            <=                                                     f_int16_sub ;
    a0_int32_stb            <=                                                     f_int32_stb ; 
    a0_op_signed            <=                                                     f_op_signed ;
    
    a0_ra_data              <=                                                 i_r0_data[31: 0];                                                                                                   
    a0_rb_data              <=                                                 i_r2_data[31: 0];         
    a0_rc_data              <=                                                 i_r1_data[31: 0];    
    a0_rd_data              <=                                                 i_r3_data[31: 0];                                                                                              
  end 
//============================================================================================== 
// stage a0 float
//============================================================================================== 
always@(posedge clk or posedge rst)  
 if(rst) 
  begin                                                                         
    a0_itof_stb             <=                                                             1'b0;  
    a0_ftoi_stb             <=                                                             1'b0;    
    a0_fl_stb               <=                                                             1'b0;     
    a0_fl_mul               <=                                                             1'b0;
    a0_fl_sub               <=                                                             1'b0;
    a0_fl_add               <=                                                             1'b0; 
    a0_fl_mul_add           <=                                                             1'b0;
    a0_fl_mul_sub           <=                                                             1'b0; 
    a0_fl_neg               <=                                                             1'b0; 
    a0_fl_abs               <=                                                             1'b0; 
            
    a0_fl_conv_sig          <=                                                             1'd0;
    a0_data_itof            <=                                                            32'd0;
    a0_data_ftoi            <=                                                            32'd0;
    
    a0_fl_ftoi_sh_cnt       <=                                                             6'd0;  
    a0_rb_zf                <=                                                             4'd0;
                                                                                                     
    a0_fl_ra_exp            <=                                                             8'd0; 
    a0_fl_ra_sig            <=                                                             1'd0;
    a0_fl_ra_ezero_f        <=                                                             1'd0;
    a0_fl_ra_emax_f         <=                                                             1'd0;
    a0_fl_ra_mzero_f        <=                                                             1'd0;
    a0_fl_ra_mmax_f         <=                                                             1'd0;
    a0_fl_ra_nan_f          <=                                                             1'd0;
    a0_fl_ra_zero_f         <=                                                             1'd0;
    a0_fl_ra_inf_f          <=                                                             1'd0;
                                                                                                     
    a0_fl_rb_exp            <=                                                             8'd0; 
    a0_fl_rb_sig            <=                                                             1'd0;
    a0_fl_rb_ezero_f        <=                                                             1'd0; 
    a0_fl_rb_emax_f         <=                                                             1'd0;
    a0_fl_rb_mzero_f        <=                                                             1'd0;
    a0_fl_rb_mmax_f         <=                                                             1'd0;
    a0_fl_rb_nan_f          <=                                                             1'd0;
    a0_fl_rb_zero_f         <=                                                             1'd0;
    a0_fl_rb_inf_f          <=                                                             1'd0;
                                                                                                                         
    a0_fl_rc_exp            <=                                                             8'd0; 
    a0_fl_rc_sig            <=                                                             1'd0;
    a0_fl_rc_ezero_f        <=                                                             1'd0;
    a0_fl_rc_emax_f         <=                                                             1'd0;
    a0_fl_rc_mzero_f        <=                                                             1'd0;
    a0_fl_rc_mmax_f         <=                                                             1'd0;
    a0_fl_rc_nan_f          <=                                                             1'd0;
    a0_fl_rc_zero_f         <=                                                             1'd0;
    a0_fl_rc_inf_f          <=                                                             1'd0;
                                                                                                    
    a0_fl_rd_exp            <=                                                             8'd0; 
    a0_fl_rd_sig            <=                                                             1'd0;
    a0_fl_rd_ezero_f        <=                                                             1'd0;
    a0_fl_rd_emax_f         <=                                                             1'd0;
    a0_fl_rd_mzero_f        <=                                                             1'd0;
    a0_fl_rd_mmax_f         <=                                                             1'd0;
    a0_fl_rd_nan_f          <=                                                             1'd0;
    a0_fl_rd_zero_f         <=                                                             1'd0;
    a0_fl_rd_inf_f          <=                                                             1'd0;
                                                                                                  
    a0_fl_mul_ab_exp        <=                                                             9'd0;   
    a0_fl_mul_cd_exp        <=                                                             8'd0; 
    a0_fl_mul_ab_sig        <=                                                             1'd0;  
    a0_fl_mul_cd_sig        <=                                                             1'd0; 
  end
 else                                           
  begin                                                                                          
    a0_itof_stb             <=                                                     f_itof_stb  ;  
    a0_ftoi_stb             <=                                                     f_ftoi_stb  ;    
    a0_fl_stb               <=                                                     f_fl_stb    ;     
    a0_fl_mul               <=                                                     f_fl_mul    ;
    a0_fl_sub               <=                                                     f_fl_sub    ;
    a0_fl_add               <=                                                     f_fl_add    ; 
    a0_fl_mul_add           <=                                                     f_fl_mul_add;
    a0_fl_mul_sub           <=                                                     f_fl_mul_sub; 
    a0_fl_neg               <=                                                     f_fl_neg    ; 
    a0_fl_abs               <=                                                     f_fl_abs    ;                                                                                              

    a0_fl_conv_sig          <=                                                 (i_data_con[31]);
    a0_data_itof            <=(i_data_con[31])? {1'b0, {- i_data_con[30:0]}} : i_data_con[31:0]; 
    a0_data_ftoi            <=                                                 i_data_con[31:0]; 
    
    begin
           if(i_data_con[30:23] < 127) a0_fl_ftoi_sh_cnt <=                                6'd0;
      else if(i_data_con[30:23] < 159) a0_fl_ftoi_sh_cnt <=          i_data_con[30:23] - 8'd126;
      else                             a0_fl_ftoi_sh_cnt <=                               6'd32;
    end  
    a0_rb_zf                <= (i_data_con[31])?  {f_zf3_neg, f_zf2_neg, f_zf1_neg, f_zf0_neg }:
                                                  {f_zf3_pos, f_zf2_pos, f_zf1_pos, f_zf0_pos };
    //a0_rb_zfh               <=                                    {f_zf3h,f_zf2h,f_zf1h,f_zf0h};                                                                                        
                                                                                                        
    a0_fl_ra_exp            <=                                                   i_fl_ra[30:23]; 
    a0_fl_ra_sig            <=                                                      i_fl_ra[31];
    a0_fl_ra_ezero_f        <=                                                    f_fl_ra_ezero;
    a0_fl_ra_emax_f         <=                                                    f_fl_ra_emax ;
    a0_fl_ra_mzero_f        <=                                                    f_fl_ra_mzero;
    a0_fl_ra_mmax_f         <=                                                    f_fl_ra_mmax ; 
    a0_fl_ra_nan_f          <=                                                    f_fl_ra_nan  ;
    a0_fl_ra_zero_f         <=                                                    f_fl_ra_zero ;
    a0_fl_ra_inf_f          <=                                                    f_fl_ra_inf  ;

    a0_fl_rb_exp            <=                                                   i_fl_rb[30:23]; 
    a0_fl_rb_sig            <=                                                      i_fl_rb[31];
    a0_fl_rb_ezero_f        <=                                                    f_fl_rb_ezero;
    a0_fl_rb_emax_f         <=                                                    f_fl_rb_emax ;
    a0_fl_rb_mzero_f        <=                                                    f_fl_rb_mzero;
    a0_fl_rb_mmax_f         <=                                                    f_fl_rb_mmax ;
    a0_fl_rb_nan_f          <=                                                    f_fl_rb_nan  ;
    a0_fl_rb_zero_f         <=                                                    f_fl_rb_zero ;
    a0_fl_rb_inf_f          <=                                                    f_fl_rb_inf  ;
                                                                                                                                                
    a0_fl_rc_exp            <=                                                   i_fl_rc[30:23]; 
    a0_fl_rc_sig            <=                                                      i_fl_rc[31];
    a0_fl_rc_ezero_f        <=                                                    f_fl_rc_ezero;
    a0_fl_rc_emax_f         <=                                                    f_fl_rc_emax ;
    a0_fl_rc_mzero_f        <=                                                    f_fl_rc_mzero;
    a0_fl_rc_mmax_f         <=                                                    f_fl_rc_mmax ; 
    a0_fl_rc_nan_f          <=                                                    f_fl_rc_nan  ;
    a0_fl_rc_zero_f         <=                                                    f_fl_rc_zero ;
    a0_fl_rc_inf_f          <=                                                    f_fl_rc_inf  ;
                                                                                                                                                 
    a0_fl_rd_exp            <=                                                   i_fl_rd[30:23]; 
    a0_fl_rd_sig            <=                                                      i_fl_rd[31];
    a0_fl_rd_ezero_f        <=                                                    f_fl_rd_ezero;
    a0_fl_rd_emax_f         <=                                                    f_fl_rd_emax ;
    a0_fl_rd_mzero_f        <=                                                    f_fl_rd_mzero;
    a0_fl_rd_mmax_f         <=                                                    f_fl_rd_mmax ;
    a0_fl_rd_nan_f          <=                                                    f_fl_rd_nan  ;
    a0_fl_rd_zero_f         <=                                                    f_fl_rd_zero ;
    a0_fl_rd_inf_f          <=                                                    f_fl_rd_inf  ;
                                                                                                 
    a0_fl_mul_ab_exp        <=                                  i_fl_ra[30:23] + i_fl_rb[30:23];  
    a0_fl_mul_cd_exp        <=                                  i_fl_rc[30:23] + i_fl_rd[30:23]; 
    a0_fl_mul_ab_sig        <=                                  i_fl_ra[31]    ^ i_fl_rb[31]   ;  
    a0_fl_mul_cd_sig        <=                                  i_fl_rc[31]    ^ i_fl_rd[31]   ; 
  end                                                                                           
//==============================================================================================
// instruction validation (signal in a0 phase)
//==============================================================================================
assign       a0x_ins_valid = (!fci_inst_rep && !fci_inst_skip && !fci_inst_lsf);                                                                    
//==============================================================================================
// stage b (1) int
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    b1_stb                  <=                                                             1'b0;
    b1_tid                  <=                                                             1'b0;
    b1_dst_ena              <=                                                             2'd0;
    b1_dst_tag              <=                                                             2'd0;
    b1_pid                  <=                                                             2'b0;
    b1_v_addr               <=                                                            32'd0;
    b1_opcode               <=                                                            32'd0; 
    b1_dst_addr             <=                                                             5'd0; 
                                                                                                   
    b1_int16_stb            <=                                                             1'b0;   
    b1_int16_add            <=                                                             1'b0;
    b1_int16_lea            <=                                                             1'b0;
    b1_int16_sub            <=                                                             1'b0;
    b1_int32_stb            <=                                                             1'b0;
    b1_op_signed            <=                                                             1'b0;    
    
    b1_ra_data              <=                                                            32'd0;
    b1_rb_data              <=                                                            32'd0;
    b1_rc_data              <=                                                            32'd0;
    b1_rd_data              <=                                                            32'd0;
  end
 else                                   
  begin
    b1_stb                  <=                                          a0x_ins_valid && a0_stb;
    b1_tid                  <=                                                           a0_tid;
    b1_dst_ena              <=                                                       a0_dst_ena;
    b1_dst_tag              <=                                                       a0_dst_tag;
    b1_pid                  <=                                                           a0_pid;
    b1_v_addr               <=                                                        a0_v_addr;
    b1_opcode               <=                                                        a0_opcode;
    b1_dst_addr             <=                                                      a0_dst_addr; 
                                                                                                   
    b1_int16_stb            <=                                                    a0_int16_stb ; 
    b1_int16_add            <=                                                    a0_int16_add ; 
    b1_int16_sub            <=                                                    a0_int16_sub ;
    b1_int16_lea            <=                                                    a0_int16_lea ;
    b1_int32_stb            <=                                                    a0_int32_stb ;
    b1_op_signed            <=                                                    a0_op_signed ;  
  end                                                       
//==============================================================================================
// stage b (1) float
//==============================================================================================   
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                                                                                                                     
    b1_itof_stb             <=                                                             1'b0;  
    b1_ftoi_stb             <=                                                             1'b0;   
    b1_fl_stb               <=                                                             1'b0;     
    b1_fl_mul               <=                                                             1'b0;
    b1_fl_sub               <=                                                             1'b0;
    b1_fl_add               <=                                                             1'b0; 
    b1_fl_mul_add           <=                                                             1'b0;
    b1_fl_mul_sub           <=                                                             1'b0;
    b1_fl_sub_or_add        <=                                                             1'b0; 
    b1_fl_neg               <=                                                             1'b0; 
    b1_fl_abs               <=                                                             1'b0;  
                                                                                        
    b1_data_conv            <=                                                            64'd0;
    b1_fl_conv_sig          <=                                                             1'd0; 
    b1_fl_sh_cnt            <=                                                             6'd0;
    b1_bo_dt_itof           <=                                                             8'd0;
                                                                                                 
    b1_fl_ra_nan_f          <=                                                             1'd0;
    b1_fl_ra_zero_f         <=                                                             1'd0;
    b1_fl_ra_inf_f          <=                                                             1'd0;
                                                                                                  
    b1_fl_rb_nan_f          <=                                                             1'd0;
    b1_fl_rb_zero_f         <=                                                             1'd0;
    b1_fl_rb_inf_f          <=                                                             1'd0;
                                                                                                
    b1_fl_rc_nan_f          <=                                                             1'd0;
    b1_fl_rc_zero_f         <=                                                             1'd0;
    b1_fl_rc_inf_f          <=                                                             1'd0;
                                                                                                   
    b1_fl_rd_nan_f          <=                                                             1'd0;
    b1_fl_rd_zero_f         <=                                                             1'd0;
    b1_fl_rd_inf_f          <=                                                             1'd0; 
    
    b1_fl_rab_mux           <=                                                             2'd0; 
    b1_fl_rcd_mux           <=                                                             2'd0; 
    
    b1_fl_mul_ab_exp        <=                                                            10'd0; 
    b1_fl_mul_cd_exp        <=                                                            10'd0;
    b1_fl_mul_ab_sig        <=                                                             1'd0; 
    b1_fl_mul_cd_sig        <=                                                             1'd0; 
  end
 else                                   
  begin                                                                                                                                                          
    b1_itof_stb             <=                                                    a0_itof_stb  ;  
    b1_ftoi_stb             <=                                                    a0_ftoi_stb  ;    
    b1_fl_stb               <=                                                    a0_fl_stb    ;     
    b1_fl_mul               <=                                                    a0_fl_mul    ;
    b1_fl_sub               <=                                                    a0_fl_sub    ;
    b1_fl_add               <=                                                    a0_fl_add    ; 
    b1_fl_mul_add           <=                                                    a0_fl_mul_add;
    b1_fl_mul_sub           <=                                                    a0_fl_mul_sub;
    b1_fl_sub_or_add        <=                                           a0_fl_sub || a0_fl_add;  
    b1_fl_neg               <=                                                    a0_fl_neg    ; 
    b1_fl_abs               <=                                                    a0_fl_abs    ; 
                                                                                                
    b1_fl_conv_sig          <=                                                   a0_fl_conv_sig;
    begin                                                                                       
        b1_data_conv        <= (a0_itof_stb)?                             {32'd0, a0_data_itof}:
                             /*(a0_ftoi_stb)?*/ {{1'd1,a0_data_ftoi[22:0]},32'h00000000 ,8'h00};
    end                                                                                         
    casex({a0_ftoi_stb, a0_rb_zf})
    5'b1_xxxx:   b1_fl_sh_cnt <=                                         a0_fl_ftoi_sh_cnt;  
    5'b0_0xxx:   b1_fl_sh_cnt <=                                                     6'h00;
    5'b0_10xx:   b1_fl_sh_cnt <=                                                     6'h08;
    5'b0_110x:   b1_fl_sh_cnt <=                                                     6'h10;
    5'b0_1110:   b1_fl_sh_cnt <=                                                     6'h18;
    5'b0_1111:   b1_fl_sh_cnt <=                                                     6'h20;
    default:     b1_fl_sh_cnt <=                                                     6'h00;
    endcase
      
    casex(a0_rb_zf[3:1])
    3'b111: b1_bo_dt_itof   <=                                              a0_data_itof[ 7: 0];
    3'b110: b1_bo_dt_itof   <=                                              a0_data_itof[15: 8];
    3'b10x: b1_bo_dt_itof   <=                                              a0_data_itof[23:16];
    3'b0xx: b1_bo_dt_itof   <=                                              a0_data_itof[31:24];
    endcase
                                                                                                
    b1_fl_ra_nan_f          <=                                                  a0_fl_ra_nan_f ;
    b1_fl_ra_zero_f         <=                                                  a0_fl_ra_zero_f;
    b1_fl_ra_inf_f          <=                                                  a0_fl_ra_inf_f ;
                                                                                                  
    b1_fl_rb_nan_f          <=                                                  a0_fl_rb_nan_f ;
    b1_fl_rb_zero_f         <=                                                  a0_fl_rb_zero_f;
    b1_fl_rb_inf_f          <=                                                  a0_fl_rb_inf_f ;
                                                                                                  
    b1_fl_rc_nan_f          <=                                                  a0_fl_rc_nan_f ;
    b1_fl_rc_zero_f         <=                                                  a0_fl_rc_zero_f;
    b1_fl_rc_inf_f          <=                                                  a0_fl_rc_inf_f ;
                                                                                                  
    b1_fl_rd_nan_f          <=                                                  a0_fl_rd_nan_f ;
    b1_fl_rd_zero_f         <=                                                  a0_fl_rd_zero_f;
    b1_fl_rd_inf_f          <=                                                  a0_fl_rd_inf_f ;
                     
    begin                                                                                        
             if(a0_fl_ra_nan_f)                     b1_fl_rab_mux   <=                     2'd1; // NaN
        else if(a0_fl_rb_nan_f)                     b1_fl_rab_mux   <=                     2'd1; // NaN 
        else if(a0_fl_ra_inf_f  && a0_fl_rb_zero_f) b1_fl_rab_mux   <=                     2'd1; // NaN 
        else if(a0_fl_rb_inf_f  && a0_fl_ra_zero_f) b1_fl_rab_mux   <=                     2'd1; // NaN  
        else if(a0_fl_ra_zero_f || a0_fl_rb_zero_f) b1_fl_rab_mux   <=                     2'd2; // zero 
        else if(a0_fl_ra_inf_f  || a0_fl_rb_inf_f ) b1_fl_rab_mux   <=                     2'd3; // +/- inf
        else                                        b1_fl_rab_mux   <=                     2'd0; // 
    end
    begin                                                                                        
             if(a0_fl_rc_nan_f)                     b1_fl_rcd_mux   <=                     2'd1; // NaN
        else if(a0_fl_rd_nan_f)                     b1_fl_rcd_mux   <=                     2'd1; // NaN 
        else if(a0_fl_rc_inf_f  && a0_fl_rd_zero_f) b1_fl_rcd_mux   <=                     2'd1; // NaN 
        else if(a0_fl_rd_inf_f  && a0_fl_rc_zero_f) b1_fl_rcd_mux   <=                     2'd1; // NaN  
        else if(a0_fl_rc_zero_f || a0_fl_rd_zero_f) b1_fl_rcd_mux   <=                     2'd2; // zero 
        else if(a0_fl_rc_inf_f  || a0_fl_rd_inf_f ) b1_fl_rcd_mux   <=                     2'd3; // +/- inf
        else                                        b1_fl_rcd_mux   <=                     2'd0; // 
    end
                                                                                                 
    b1_fl_mul_ab_exp        <= (a0_fl_sub || a0_fl_add)? a0_fl_ra_exp : a0_fl_mul_ab_exp - 10'd127; 
    b1_fl_mul_cd_exp        <= (a0_fl_sub || a0_fl_add)? a0_fl_rc_exp : a0_fl_mul_cd_exp - 10'd127; 
    b1_fl_mul_ab_sig        <= (a0_fl_sub || a0_fl_add)?        a0_fl_ra_sig : a0_fl_mul_ab_sig;  
    b1_fl_mul_cd_sig        <= (a0_fl_sub || a0_fl_add)?        a0_fl_rc_sig : a0_fl_mul_cd_sig; 
  end        
//==============================================================================================  
// stage a (2)
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    a2_stb                  <=                                                             1'b0;
    a2_tid                  <=                                                             1'b0;
    a2_dst_ena              <=                                                             2'd0;
    a2_dst_tag              <=                                                             2'd0;
    a2_pid                  <=                                                             2'b0;
    a2_v_addr               <=                                                            32'd0;
    a2_opcode               <=                                                            32'd0; 
    a2_dst_addr             <=                                                             5'd0;
     
    a2_int16_stb            <=                                                             1'b0;
    a2_int16_add            <=                                                             1'b0;
    a2_int16_lea            <=                                                             1'b0;
    a2_int16_sub            <=                                                             1'b0;
    a2_int32_stb            <=                                                             1'b0;
    a2_op_signed            <=                                                             1'b0;   
    
    a2_int16_add            <=                                                             1'b0;
                                                                         
    a2_ra_data              <=                                                            32'd0;
    a2_rb_data              <=                                                            32'd0;
    a2_rc_data              <=                                                            32'd0;
    a2_rd_data              <=                                                            32'd0;
  end
 else
  begin
    a2_stb                  <=                                                           b1_stb;
    a2_tid                  <=                                                           b1_tid;
    a2_dst_ena              <=                                                       b1_dst_ena;
    a2_dst_tag              <=                                                       b1_dst_tag;
    a2_pid                  <=                                                           b1_pid;
    a2_v_addr               <=                                                        b1_v_addr;
    a2_opcode               <=                                                        b1_opcode;
    a2_dst_addr             <=                                                      b1_dst_addr; 
                                                                                                  
    a2_int16_stb            <=                                                    b1_int16_stb ; 
    a2_int16_lea            <=                                                    b1_int16_lea ;
    a2_int16_sub            <=                                                    b1_int16_sub ;
    a2_int32_stb            <=                                                    b1_int32_stb ;
    a2_op_signed            <=                                                    b1_op_signed ;    
    a2_int16_add            <=                   b1_int16_stb && (b1_int16_add || b1_int16_lea);  
    
    a2_ra_data              <=                                                b1_ra_data[31: 0];
    a2_rb_data              <=                                                b1_rb_data[31: 0];
    a2_rc_data              <=                                                b1_rc_data[31: 0];
    a2_rd_data              <=                                                b1_rd_data[31: 0];
  end  
//==============================================================================================
// stage a (2) float
//============================================================================================== 
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    a2_itof_stb             <=                                                             1'b0;  
    a2_ftoi_stb             <=                                                             1'b0;  
    a2_fl_stb               <=                                                             1'b0;     
    a2_fl_mul               <=                                                             1'b0;
    a2_fl_sub               <=                                                             1'b0;
    a2_fl_add               <=                                                             1'b0; 
    a2_fl_mul_add           <=                                                             1'b0;
    a2_fl_mul_sub           <=                                                             1'b0;  
    a2_fl_neg               <=                                                             1'b0;  
    a2_fl_abs               <=                                                             1'b0; 
    
    a2_fl_conv_sig          <=                                                             1'b0; 
    a2_fl_sh_cnt            <=                                                             6'd0;
    a2_data_conv            <=                                                            64'd0;  
        
    a2_fl_rab_mux           <=                                                             2'd0; 
    a2_fl_rcd_mux           <=                                                             2'd0; 
                                                                                                 
    a2_fl_rab_exp_exe       <=                                                             8'd0;
    a2_fl_rab_man_exe       <=                                                            24'd0;
    a2_fl_rcd_exp_exe       <=                                                             8'd0;
    a2_fl_rcd_man_exe       <=                                                            24'd0;
    
    a2_fl_mul_ab_exp        <=                                                             9'd0; 
    a2_fl_mul_cd_exp        <=                                                             9'd0;
    a2_fl_mul_ab_sig        <=                                                             1'd0; 
    a2_fl_mul_cd_sig        <=                                                             1'd0;
    
    a2_fl_mul_ab_exp_max    <=                                                             1'b0; 
    a2_fl_mul_cd_exp_max    <=                                                             1'b0; 
    a2_fl_mul_ab_exp_amax   <=                                                             1'b0; 
    a2_fl_mul_cd_exp_amax   <=                                                             1'b0;
    a2_fl_mul_ab_exp_undf   <=                                                             1'b0; 
    a2_fl_mul_cd_exp_undf   <=                                                             1'b0;
  end
 else
  begin                                                                                       
    a2_itof_stb             <=                                                    b1_itof_stb  ;  
    a2_ftoi_stb             <=                                                    b1_ftoi_stb  ;   
    a2_fl_stb               <=                                                    b1_fl_stb    ;     
    a2_fl_mul               <=                                                    b1_fl_mul    ;
    a2_fl_sub               <=                                                    b1_fl_sub    ;
    a2_fl_add               <=                                                    b1_fl_add    ; 
    a2_fl_mul_add           <=                                                    b1_fl_mul_add;
    a2_fl_mul_sub           <=                                                    b1_fl_mul_sub;  
    
    a2_fl_neg               <=                                                    b1_fl_neg    ;
    a2_fl_abs               <=                                                    b1_fl_abs    ;
                                                                                                
    a2_fl_conv_sig          <=                                                   b1_fl_conv_sig; 
        
    casex({b1_itof_stb, b1_bo_dt_itof})
    9'b0_xxxx_xxxx: a2_fl_sh_cnt <=                                                b1_fl_sh_cnt;
    9'b1_1xxx_xxxx: a2_fl_sh_cnt <=                                    {b1_fl_sh_cnt[5:3],3'd0};
    9'b1_01xx_xxxx: a2_fl_sh_cnt <=                                    {b1_fl_sh_cnt[5:3],3'd1};
    9'b1_001x_xxxx: a2_fl_sh_cnt <=                                    {b1_fl_sh_cnt[5:3],3'd2};
    9'b1_0001_xxxx: a2_fl_sh_cnt <=                                    {b1_fl_sh_cnt[5:3],3'd3};
    9'b1_0000_1xxx: a2_fl_sh_cnt <=                                    {b1_fl_sh_cnt[5:3],3'd4};
    9'b1_0000_01xx: a2_fl_sh_cnt <=                                    {b1_fl_sh_cnt[5:3],3'd5};
    9'b1_0000_001x: a2_fl_sh_cnt <=                                    {b1_fl_sh_cnt[5:3],3'd6};
    9'b1_0000_0001: a2_fl_sh_cnt <=                                    {b1_fl_sh_cnt[5:3],3'd7};
    9'b1_0000_0000: a2_fl_sh_cnt <=                                    {b1_fl_sh_cnt[5:3],3'd0};
    default:        a2_fl_sh_cnt <=                                                b1_fl_sh_cnt;
    endcase
    case(b1_fl_sh_cnt[5:3])
    3'h0:   a2_data_conv  <=   {b1_data_conv[63:32],  b1_data_conv[31: 0]                     };
    3'h1:   a2_data_conv  <=   {b1_data_conv[55:32],  b1_data_conv[31: 0], b1_data_conv[63:56]};
    3'h2:   a2_data_conv  <=   {b1_data_conv[47:32],  b1_data_conv[31: 0], b1_data_conv[63:48]};
    3'h3:   a2_data_conv  <=   {b1_data_conv[39:32],  b1_data_conv[31: 0], b1_data_conv[63:40]};
    default:a2_data_conv  <=   {                      b1_data_conv[31: 0], b1_data_conv[63:32]};
    endcase
        
    a2_fl_rab_mux           <=  (b1_fl_sub_or_add                )?                        1'd1: // skip multiplication for float addition or float subtraction 
                                (b1_fl_mul_ab_exp[9:8] == 2'b01  )?                        1'd1: // inf as a result of multiplication
                                (b1_fl_mul_ab_exp[9:0] == 10'h0FF)?                        1'd1: // inf as a result of multiplication
                                (b1_fl_rab_mux == 2'd0           )?                1'd0 :  1'd1; // normal result : exeption float(NaN, inf, zero)
    a2_fl_rcd_mux           <=  (b1_fl_sub_or_add                )?                        1'd1: // skip multiplication for float addition or float subtraction
                                (b1_fl_mul_cd_exp[9:8] == 2'b01  )?                        1'd1: // inf as a result of multiplication
                                (b1_fl_mul_cd_exp[9:0] == 10'h0FF)?                        1'd1: // inf as a result of multiplication
                                (b1_fl_rcd_mux == 2'd0           )?                1'd0 :  1'd1; // normal result : exeption float(NaN, inf, zero)  
                                                                                                 
    a2_fl_rab_exp_exe       <=  (b1_fl_sub_or_add     )?                      b1_ra_data[30:23]: // skip multiplication for float addition or float subtraction
                                (b1_fl_rab_mux == 3'd0)?                                  8'hFF: // inf as a result of multiplication
                                (b1_fl_rab_mux == 3'd1)?                                  8'hFF: // NaN
                                (b1_fl_rab_mux == 3'd2)?                                  8'h00: // zero
                              /*(b1_fl_rab_mux == 3'd3)?*/                                8'hFF; // inf
    a2_fl_rab_man_exe       <=  (b1_fl_sub_or_add     )?              {1'b1, b1_ra_data[22: 0]}: // skip multiplication for float addition or float subtraction
                                (b1_fl_rab_mux == 3'd0)?                             24'h000000: // inf as a result of multiplication
                                (b1_fl_rab_mux == 3'd1)?                             24'hFFFFFF: // NaN
                                (b1_fl_rab_mux == 3'd2)?                             24'h000000: // zero
                              /*(b1_fl_rcd_mux == 3'd3)?*/                           24'h000000; // inf 
    a2_fl_rcd_exp_exe       <=  (b1_fl_sub_or_add     )?                      b1_rb_data[30:23]: // skip multiplication for float addition or float subtraction
                                (b1_fl_rcd_mux == 3'd0)?                                  8'hFF: // inf as a result of multiplication
                                (b1_fl_rcd_mux == 3'd1)?                                  8'hFF: // NaN
                                (b1_fl_rcd_mux == 3'd2)?                                  8'h00: // zero
                              /*(b1_fl_rcd_mux == 3'd3)?*/                                8'hFF; // inf
    a2_fl_rcd_man_exe       <=  (b1_fl_sub_or_add     )?              {1'b1, b1_rb_data[22: 0]}: // skip multiplication for float addition or float subtraction
                                (b1_fl_rcd_mux == 3'd0)?                             24'h000000: // inf as a result of multiplication
                                (b1_fl_rcd_mux == 3'd1)?                             24'hFFFFFF: // NaN
                                (b1_fl_rcd_mux == 3'd2)?                             24'h000000: // zero
                              /*(b1_fl_rcd_mux == 3'd3)?*/                           24'h000000; // inf  
                                                                                                 
    a2_fl_mul_ab_exp        <=                                                 b1_fl_mul_ab_exp; 
    a2_fl_mul_cd_exp        <=                                                 b1_fl_mul_cd_exp; 
    a2_fl_mul_ab_exp_max    <=                                                 b1_fl_mul_ab_exp == 9'h0FF; 
    a2_fl_mul_cd_exp_max    <=                                                 b1_fl_mul_cd_exp == 9'h0FF; 
    a2_fl_mul_ab_exp_amax   <=                                                 b1_fl_mul_ab_exp == 9'h0FE; 
    a2_fl_mul_cd_exp_amax   <=                                                 b1_fl_mul_cd_exp == 9'h0FE; 
    a2_fl_mul_ab_exp_undf   <=                                                 b1_fl_mul_ab_exp[9] == 1'b1; 
    a2_fl_mul_cd_exp_undf   <=                                                 b1_fl_mul_cd_exp[9] == 1'b1; 
    a2_fl_mul_ab_sig        <=  (b1_fl_sub_or_add     )?     b1_ra_data[31] :  b1_fl_mul_ab_sig; // skip multiplication for float addition or float subtraction 
    a2_fl_mul_cd_sig        <=  (b1_fl_sub_or_add     )?     b1_rb_data[31] :  b1_fl_mul_cd_sig; // skip multiplication for float addition or float subtraction
  end                                                                                             
//==============================================================================================
// stage b (3)
//============================================================================================== 
// a2x_res_add is adder subtractor used by integer path, if it is to long 
//  (if it affects maximal clock frequency) it can be divided into two 32 bit addesrs/subtractors 
//assign  a2x_res_add = (a2_int16_add)? a2_ab_mul_data[48: 0] + a2_cd_mul_data[48: 0] : a2_ab_mul_data[48: 0] - a2_cd_mul_data[48: 0];                    
// results collection   
generate                                                                                                            
if(DSP == "DSP48A1") 
    begin : spartan6_mul_int32_res
        assign  a2x_int32_res      = {a2_cd_mul_data[49:0] +  {{19{a2_ab_mul_data[48] & a2_op_signed}}, a2_ab_mul_data[48:17]}, a2_ab_mul_data[16:0]}; 
    end
else
    begin : mul_int32_res
        assign  a2x_int32_res      = {a2_cd_mul_data[39:0] +  {{ 8{a2_ab_mul_data[55] & a2_op_signed}}, a2_ab_mul_data[55:24]}, a2_ab_mul_data[23:0]}; 
    end 
endgenerate
//----------------------------------------------------------------------------------------------  
//assign scut_mul_a2_b9 =  a2_stb && (!a8_stb && a2_fl_mul);
//---------------------------------------------------------------------------------------------- 
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    b3_stb                  <=                                                             1'b0;
    b3_tid                  <=                                                             1'b0;
    b3_dst_ena              <=                                                             2'd0;
    b3_dst_tag              <=                                                             2'd0;
    b3_pid                  <=                                                             2'b0;
    b3_v_addr               <=                                                            32'd0;
    b3_opcode               <=                                                            32'd0;
    b3_dst_addr             <=                                                             5'b0;
                                                                                                  
    b3_int16_stb            <=                                                             1'b0; 
    b3_int16_add            <=                                                             1'b0;
    b3_int16_lea            <=                                                             1'b0;
    b3_int16_sub            <=                                                             1'b0;
    b3_int32_stb            <=                                                             1'b0;
    b3_op_signed            <=                                                             1'b0; 
    
    b3_ra_data              <=                                                            32'd0;
    b3_rb_data              <=                                                            32'd0;
    b3_rc_data              <=                                                            32'd0;
    b3_rd_data              <=                                                            32'd0;
    
    b3_int32_res_L          <=                                                            32'd0;                                                                                                       
    b3_int32_res_H          <=                                                            32'd0;                                                                                                       
    b3_int16_res_A          <=                                                            32'd0;                                                              
    b3_int16_res_B          <=                                                            32'd0;
                          
    b3_int_add_res          <=                                                            48'd0;
    b3_res_mux              <=                                                             4'd0;
  end
 else  
  begin                                                               
    b3_stb                  <=                                                           a2_stb;
    b3_tid                  <=                                                           a2_tid;
    b3_dst_ena              <=                                                       a2_dst_ena;
    b3_dst_tag              <=                                                       a2_dst_tag;
    b3_pid                  <=                                                           a2_pid;
    b3_v_addr               <=                                                        a2_v_addr;
    b3_opcode               <=                                                        a2_opcode;
    b3_dst_addr             <=                                                      a2_dst_addr;
                                                                                                 
    b3_int16_stb            <=                                                    a2_int16_stb ; 
    b3_int16_add            <=                                                    a2_int16_add ;
    b3_int16_lea            <=                                                    a2_int16_lea ;
    b3_int16_sub            <=                                                    a2_int16_sub ;
    b3_int32_stb            <=                                                    a2_int32_stb ;
    b3_op_signed            <=                                                    a2_op_signed ; 
    
    b3_int16_add            <=                                                     a2_int16_add;
                                                                           
    b3_ra_data              <=                                                a2_ra_data[31: 0];
    b3_rb_data              <=                                                a2_rb_data[31: 0];
    b3_rc_data              <=                                                a2_rc_data[31: 0];
    b3_rd_data              <=                                                a2_rd_data[31: 0];
    
    case(a2_int16_add)                                                      
    1'b0:  b3_int_add_res   <=                     a2_ab_mul_data[48: 0] - a2_cd_mul_data[48: 0]; // mul16sub
    1'b1:  b3_int_add_res   <=                     a2_ab_mul_data[48: 0] + a2_cd_mul_data[48: 0]; // mul16add, lea
    endcase     
    
    b3_int32_res_L          <=                                             a2x_int32_res[31: 0];                                                                                                       
    b3_int32_res_H          <=                                             a2x_int32_res[63:32];                                                                                                       
    b3_int16_res_A          <=                                             a2_ab_mul_data[31:0];                                                             
    b3_int16_res_B          <=                                             a2_cd_mul_data[31:0];
    
    casex({a2_int32_stb, a2_int16_stb, a2_int16_add, a2_int16_sub})  
    4'b1_xxx:  b3_res_mux   <=                                                        4'd3;// int32
    4'b0_100:  b3_res_mux   <=                                                        4'd4;// int16
    4'b0_11x:  b3_res_mux   <=                                                        4'd5;// int16 + , lea, leai
    4'b0_101:  b3_res_mux   <=                                                        4'd5;// int16 - 
    default:   b3_res_mux   <=                                                        4'd8;// fl
    endcase                                                                                
  end  
//==============================================================================================  
generate                                                                                    
if((DSP == "DSP48A1") || (DSP == "MUL18x18")) 
    begin : m18x18_mul_fl_res
//============================================================================================== 
assign   a2x_fl_mul_ab_exp        = (a2_fl_rab_mux)?                          a2_fl_rab_exp_exe:
                                    (a2_fl_mul_ab_exp_amax && 
                                        a2_ab_mul_data[40])?                  a2_fl_rab_exp_exe:  // overflow where exp is calculated to be FE but mantysa result in adding one to it and in sumary in overflow
                                    (a2_fl_mul_ab_exp_undf)?                               9'd0:
                                    (a2_ab_mul_data[40])?               a2_fl_mul_ab_exp + 9'd1:
                                                                        a2_fl_mul_ab_exp       ;     
                                                                        
assign   a2x_fl_mul_ab_man        = (a2_fl_rab_mux)?                  {1'b0, a2_fl_rab_man_exe}: 
                                    (a2_fl_mul_ab_exp_amax && 
                                        a2_ab_mul_data[40])?          {1'b0, a2_fl_rab_man_exe}: // detection of round to inf
                                    (a2_fl_mul_ab_exp_undf)?                              24'd0:
                                    (a2_ab_mul_data[40])?                 a2_ab_mul_data[40:17]:
                                                                          a2_ab_mul_data[39:16];    

assign   a2x_fl_mul_cd_exp        = (a2_fl_rcd_mux)?                          a2_fl_rcd_exp_exe:
                                    (a2_fl_mul_cd_exp_amax && 
                                        a2_cd_mul_data[40])?                  a2_fl_rcd_exp_exe:
                                    (a2_fl_mul_cd_exp_undf)?                               9'd0:
                                    (a2_cd_mul_data[40])?               a2_fl_mul_cd_exp + 9'd1:
                                                                        a2_fl_mul_cd_exp       ;     
 
assign   a2x_fl_mul_cd_man        = (a2_fl_rcd_mux)?                  {1'b0, a2_fl_rcd_man_exe}:
                                    (a2_fl_mul_cd_exp_amax && 
                                        a2_cd_mul_data[40])?          {1'b0, a2_fl_rcd_exp_exe}:
                                    (a2_fl_mul_cd_exp_undf)?                              24'd0:
                                    (a2_cd_mul_data[40])?                 a2_cd_mul_data[40:17]:
                                                                          a2_cd_mul_data[39:16]; 
//============================================================================================== 
    end
else  
    begin : mul_fl_res 
//============================================================================================== 
assign   a2x_fl_mul_ab_exp        = (a2_fl_rab_mux)?                          a2_fl_rab_exp_exe:
                                    (a2_fl_mul_ab_exp_amax && 
                                        a2_ab_mul_data[47])?                  a2_fl_rab_exp_exe:  // overflow where exp is calculated to be FE but mantysa result in adding one to it and in sumary in overflow
                                    (a2_fl_mul_ab_exp_undf)?                               9'd0:
                                    (a2_ab_mul_data[47])?               a2_fl_mul_ab_exp + 9'd1:
                                                                        a2_fl_mul_ab_exp       ;     
                                                                        
assign   a2x_fl_mul_ab_man        = (a2_fl_rab_mux)?                  {1'b0, a2_fl_rab_man_exe}: 
                                    (a2_fl_mul_ab_exp_amax && 
                                        a2_ab_mul_data[47])?          {1'b0, a2_fl_rab_man_exe}: // detection of round to inf
                                    (a2_fl_mul_ab_exp_undf)?                              24'd0:
                                    (a2_ab_mul_data[47])?                 a2_ab_mul_data[47:24]:
                                                                          a2_ab_mul_data[46:23];    
                                                                          
assign   a2x_fl_mul_cd_exp        = (a2_fl_rcd_mux)?                          a2_fl_rcd_exp_exe:
                                    (a2_fl_mul_cd_exp_amax && 
                                        a2_cd_mul_data[47])?                  a2_fl_rcd_exp_exe:
                                    (a2_fl_mul_cd_exp_undf)?                               9'd0:
                                    (a2_cd_mul_data[47])?               a2_fl_mul_cd_exp + 9'd1:
                                                                        a2_fl_mul_cd_exp       ;     
                                                                        
assign   a2x_fl_mul_cd_man        = (a2_fl_rcd_mux)?                  {1'b0, a2_fl_rcd_man_exe}:
                                    (a2_fl_mul_cd_exp_amax && 
                                        a2_cd_mul_data[47])?          {1'b0, a2_fl_rcd_exp_exe}:
                                    (a2_fl_mul_cd_exp_undf)?                              24'd0:
                                    (a2_cd_mul_data[47])?                 a2_cd_mul_data[47:24]:
                                                                          a2_cd_mul_data[46:23];
//==============================================================================================   
    end     
endgenerate
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                                                                                                                   
    b3_itof_stb             <=                                                             1'b0;  
    b3_ftoi_stb             <=                                                             1'b0;   
    b3_fl_stb               <=                                                             1'b0;     
    b3_fl_mul               <=                                                             1'b0;
    b3_fl_sub               <=                                                             1'b0;
    b3_fl_add               <=                                                             1'b0; 
    b3_fl_mul_add           <=                                                             1'b0;
    b3_fl_mul_sub           <=                                                             1'b0; 
    b3_fl_neg               <=                                                             1'b0; 
    b3_fl_abs               <=                                                             1'b0; 
    b3_fl_part2_ena         <=                                                             1'b0;
    
    b3_fl_conv_sig          <=                                                             1'b0; 
    b3_fl_conv              <=                                                             1'b0;
    b3_data_conv            <=                                                            32'd0; 
    b3_fl_itof_exp          <=                                                             8'd0;
    
    b3_fl_mul_ab_exp        <=                                                             9'd0; 
    b3_fl_mul_cd_exp        <=                                                             9'd0;
    b3_fl_mul_ab_man        <=                                                            24'd0;
    b3_fl_mul_cd_man        <=                                                            24'd0;
    b3_fl_mul_ab_sig        <=                                                             1'd0; 
    b3_fl_mul_cd_sig        <=                                                             1'd0; 
    
    b3_wb_A_ena             <=                                                             1'd0; 
    b3_wb_B_ena             <=                                                             1'd0;
    b3_wb_BA_ena            <=                                                             1'd0;
  end
 else  
  begin                                                                                                                                                                                                                          
    b3_itof_stb             <=                                                    a2_itof_stb  ;  
    b3_ftoi_stb             <=                                                    a2_ftoi_stb  ;   
    b3_fl_stb               <=                                                    a2_fl_stb    ;     
    b3_fl_mul               <=                                                    a2_fl_mul    ;
    b3_fl_sub               <=                                                    a2_fl_sub    ;
    b3_fl_add               <=                                                    a2_fl_add    ; 
    b3_fl_mul_add           <=                                                    a2_fl_mul_add;
    b3_fl_mul_sub           <=                                                    a2_fl_mul_sub;  
    b3_fl_neg               <=                                                    a2_fl_neg    ; 
    b3_fl_abs               <=                                                    a2_fl_abs    ; 
    b3_fl_part2_ena         <=  a2_stb && a2_fl_stb && (a2_fl_sub || a2_fl_add || a2_fl_mul_sub || a2_fl_mul_add);  
    
    b3_fl_conv_sig          <=                                                   a2_fl_conv_sig;
    b3_fl_conv              <=                                       a2_itof_stb || a2_ftoi_stb;
   
    case(a2_fl_sh_cnt[2:0])
    3'b000:  b3_data_conv   <=                         {a2_data_conv[31:0]                    };
    3'b001:  b3_data_conv   <=                         {a2_data_conv[30:0],a2_data_conv[63:63]};
    3'b010:  b3_data_conv   <=                         {a2_data_conv[29:0],a2_data_conv[63:62]};
    3'b011:  b3_data_conv   <=                         {a2_data_conv[28:0],a2_data_conv[63:61]};
    3'b100:  b3_data_conv   <=                         {a2_data_conv[27:0],a2_data_conv[63:60]};
    3'b101:  b3_data_conv   <=                         {a2_data_conv[26:0],a2_data_conv[63:59]};
    3'b110:  b3_data_conv   <=                         {a2_data_conv[25:0],a2_data_conv[63:58]};
    3'b111:  b3_data_conv   <=                         {a2_data_conv[24:0],a2_data_conv[63:57]};
    endcase                      

    case({a2_itof_stb, a2_fl_sh_cnt[5]})
    2'b10:   b3_fl_itof_exp <=                                     8'd158 - {3'd0,a2_fl_sh_cnt};
    2'b11:   b3_fl_itof_exp <=                                                             8'd0;// jeeli przesunicie o 32 to znaczy e liczba do zamiany to zero
    default: b3_fl_itof_exp <=                                                             8'd0;
    endcase    
                                                                                                     
    b3_fl_mul_ab_exp        <=                                                a2x_fl_mul_ab_exp;     
    b3_fl_mul_ab_man        <=                                                a2x_fl_mul_ab_man;    
    b3_fl_mul_cd_exp        <=                                                a2x_fl_mul_cd_exp;     
    b3_fl_mul_cd_man        <=                                                a2x_fl_mul_cd_man;
    b3_fl_mul_ab_sig        <=                                                 a2_fl_mul_ab_sig;  
    b3_fl_mul_cd_sig        <=                                                 a2_fl_mul_cd_sig;
                            
    b3_wb_A_ena            <=           ((a2_itof_stb            && a2_dst_ena[0]) ||
                                         (a2_ftoi_stb            && a2_dst_ena[0]) || 
                                         (a2_int16_stb           && a2_dst_ena[0]) || 
                                         (a2_int32_stb           && a2_dst_ena[0]) || 
                                         (a2_fl_stb && a2_fl_mul && a2_dst_ena[0]));   
    b3_wb_B_ena            <=           ((a2_itof_stb            && a2_dst_ena[1]) ||
                                         (a2_ftoi_stb            && a2_dst_ena[1]) || 
                                         (a2_int16_stb           && a2_dst_ena[1]) || 
                                         (a2_int32_stb           && a2_dst_ena[1]) || 
                                         (a2_fl_stb && a2_fl_mul && a2_dst_ena[1]));
    b3_wb_BA_ena           <=           ((a2_int16_stb           && a2_dst_ena[0] && a2_dst_ena[1]) || 
                                         (a2_int32_stb           && a2_dst_ena[0] && a2_dst_ena[1]) || 
                                         (a2_fl_stb && a2_fl_mul && a2_dst_ena[0] && a2_dst_ena[1]));
  end  
//----------------------------------------------------------------------------------------------  
assign   b3x_fl_a_gr_b  = {1'b0, b3_fl_mul_ab_exp, b3_fl_mul_ab_man} > {1'b0, b3_fl_mul_cd_exp, b3_fl_mul_cd_man};                                                                                 
//==============================================================================================
// stage aw4 (4) prepering results for wb0
//==============================================================================================                                                                                                                                                      
always@(posedge clk or posedge rst)   
 if(rst) 
  begin                                                                        
    aw4_stb                  <=                                                            1'b0; 
    aw4_dst_ena              <=                                                            2'd0;
    aw4_dst_tag              <=                                                            2'd0;
    aw4_tid                  <=                                                            1'b0;
    aw4_pid                  <=                                                            2'b0;
    aw4_v_addr               <=                                                           32'd0;
    aw4_opcode               <=                                                           32'd0;
    aw4_dst_addr             <=                                                            5'd0;                                             
                                                                                                 
    aw4_int16_stb            <=                                                            1'b0; 
    aw4_int16_add            <=                                                            1'b0;
    aw4_int16_lea            <=                                                            1'b0;
    aw4_int16_sub            <=                                                            1'b0;
    aw4_int32_stb            <=                                                            1'b0;
    aw4_op_signed            <=                                                            1'b0;
    
    aw4_tag                  <=                                                            2'd0; 
    aw4_t1_ena               <=                                                            1'b0;        
    aw4_t0_ena               <=                                                            1'b0;  
    aw4_rg_addr              <=                                                            5'd0; 
    aw4_A_ena                <=                                                            1'b0; 
    aw4_B_ena                <=                                                            1'b0; 
    aw4_B_mod                <=                                                            1'b0;
  end 
 else  
  begin                                                                                         
    aw4_stb                  <=                           b3_stb && (b3_wb_A_ena || b3_wb_B_ena);  
    aw4_tid                  <=                                                           b3_tid;
    aw4_dst_ena              <=                                                       b3_dst_ena;
    aw4_dst_tag              <=                                                       b3_dst_tag;
    aw4_pid                  <=                                                           b3_pid;
    aw4_v_addr               <=                                                        b3_v_addr;
    aw4_opcode               <=                                                        b3_opcode;
    aw4_dst_addr             <=                                                      b3_dst_addr;
                                                                                                  
    aw4_int16_stb            <=                                                     b3_int16_stb; 
    aw4_int16_add            <=                                                     b3_int16_add;
    aw4_int16_lea            <=                                                     b3_int16_lea;
    aw4_int16_sub            <=                                                     b3_int16_sub;
    aw4_int32_stb            <=                                                     b3_int32_stb;
    aw4_op_signed            <=                                                     b3_op_signed;            
                                                                                                 
    aw4_t0_ena      <=                      (b3_stb && !b3_tid && (b3_wb_A_ena || b3_wb_B_ena));     
    aw4_t1_ena      <=                      (b3_stb &&  b3_tid && (b3_wb_A_ena || b3_wb_B_ena));
                                                                    
    aw4_rg_addr     <=                                                              b3_dst_addr;     
    aw4_tag         <=                                                               b3_dst_tag;    
                                                                    
    aw4_A_ena       <=                                                              b3_wb_A_ena; 
                                                                    
    aw4_B_ena       <=                                                              b3_wb_B_ena;        
    aw4_B_mod       <=                                                             b3_wb_BA_ena; // H:L / B:A mode  
  end                                                                                             
//==============================================================================================
// stage aw (4) float
//============================================================================================== 
always@(posedge clk or posedge rst)   
 if(rst) 
  begin                                                                                                                                                                  
    aw4_itof_stb             <=                                                            1'b0;  
    aw4_ftoi_stb             <=                                                            1'b0;  
    aw4_fl_stb               <=                                                            1'b0;     
    aw4_fl_mul               <=                                                            1'b0;
    aw4_fl_sub               <=                                                            1'b0;
    aw4_fl_add               <=                                                            1'b0; 
    aw4_fl_mul_add           <=                                                            1'b0;
    aw4_fl_mul_sub           <=                                                            1'b0; 
    aw4_fl_neg               <=                                                            1'b0;
    aw4_fl_abs               <=                                                            1'b0;
    
    aw4_fl_itof_exp          <=                                                            8'd0;
    aw4_fl_conv_sig          <=                                                            1'b0;      
    aw4_data_conv            <=                                                           32'd0; 
    
    aw4_res_mux              <=                                                            3'd0; 
    aw4_lo_data              <=                                                           32'd0; 
    aw4_hi_data              <=                                                           32'd0;
  end 
 else  
  begin                                                                                                                                                                             
    aw4_itof_stb             <=                                                      b3_itof_stb;  
    aw4_ftoi_stb             <=                                                      b3_ftoi_stb;  
    aw4_fl_stb               <=                                                        b3_fl_stb;  
    aw4_fl_mul               <=                                                        b3_fl_mul;
    aw4_fl_sub               <=                                                        b3_fl_sub;
    aw4_fl_add               <=                                                        b3_fl_add; 
    aw4_fl_mul_add           <=                                                    b3_fl_mul_add;
    aw4_fl_mul_sub           <=                                                    b3_fl_mul_sub; 
    aw4_fl_neg               <=                                                    b3_fl_neg    ;
    aw4_fl_abs               <=                                                    b3_fl_abs    ;
    
    case(b3_ftoi_stb & b3_fl_conv_sig)
    1'b0   : aw4_data_conv   <=                                               b3_data_conv[31:0];
    1'b1   : aw4_data_conv   <=                                              -b3_data_conv[31:0];
    endcase        
    aw4_fl_itof_exp          <=                                                   b3_fl_itof_exp;
    aw4_fl_conv_sig          <=                                                   b3_fl_conv_sig; 
    
    casex(b3_res_mux)  
    4'd3:   aw4_lo_data  <=                                                      b3_int32_res_L; // int32 L
    4'd4:   aw4_lo_data  <=                                                      b3_int16_res_A; // int16 A
    4'd5:   aw4_lo_data  <=                                               b3_int_add_res[31: 0]; // mul16sub                                                 
    default:aw4_lo_data  <=   {(b3_fl_mul_ab_sig & (!b3_fl_abs)) ^ b3_fl_neg, 
                                                 b3_fl_mul_ab_exp[7:0], b3_fl_mul_ab_man[22:0]}; // b3_res_mux == 8 -> fl
    endcase  
                                                                                                   
    casex(b3_res_mux)  
    4'd3:   aw4_hi_data  <=                                                      b3_int32_res_H; // int32 H
    4'd4:   aw4_hi_data  <=                                                      b3_int16_res_B; // int16 B                                            
    default:aw4_hi_data  <=   {(b3_fl_mul_cd_sig & (!b3_fl_abs)) ^ b3_fl_neg, 
                                                  b3_fl_mul_cd_exp[7:0], b3_fl_mul_cd_man[22:0]}; // b3_res_mux == 8 -> fl
    endcase                                                                          
    
    casex({b3_itof_stb, b3_ftoi_stb, b3_res_mux})
    6'b1x_xxxx:  aw4_res_mux   <=                                                          3'd1; // itof
    6'b01_xxxx:  aw4_res_mux   <=                                                          3'd2; // ftoi            
    default:     aw4_res_mux   <=                                                          3'd0; // from aw4_xx_data
    endcase 
  end   
//==============================================================================================
// wa4x
//==============================================================================================   
assign  aw4x_itof_data =                  {aw4_fl_conv_sig,aw4_fl_itof_exp,aw4_data_conv[30:8]};  
//==============================================================================================
// bw5
//==============================================================================================                                                                                                                                                      
always@(posedge clk or posedge rst)   
 if(rst) 
  begin                                         
    bw5_stb0        <=                                                                     1'b0;     
    bw5_stb1        <=                                                                     1'b0;     
    bw5_addr        <=                                                                     5'd0;     
                                                
    bw5_enaA        <=                                                                     2'd0;
    bw5_tagA        <=                                                                     1'b0;         
                                                
    bw5_enaB        <=                                                                     2'd0; 
    bw5_tagB        <=                                                                     1'b0; 
    bw5_modB        <=                                                                     1'b0;  
                                                
    bw5_dataL       <=                                                                    32'd0;
    bw5_dataH       <=                                                                    32'd0;    
  end                                           
 else                                           
  begin                                                                                      
    bw5_stb0        <=                                                               aw4_t0_ena;     
    bw5_stb1        <=                                                               aw4_t1_ena;     
    bw5_addr        <=                                                         aw4_rg_addr[4:0];     
                                                
    bw5_enaA        <=                                                           {2{aw4_A_ena}};
    bw5_tagA        <=                                                               aw4_tag[0];         
                                                
    bw5_enaB        <=                                                           {2{aw4_B_ena}}; 
    bw5_tagB        <=                                                               aw4_tag[1]; 
    bw5_modB        <=                                                                aw4_B_mod;  
    case(aw4_res_mux)                           
    3'd1:    bw5_dataL  <=                                                       aw4x_itof_data; //itof
    3'd2:    bw5_dataL  <=                                                        aw4_data_conv; //ftoi  
    default: bw5_dataL  <=                                                          aw4_lo_data; //other 
    endcase                                     
    bw5_dataH       <=                                                              aw4_hi_data;  
  end                                                                                                               
//==============================================================================================
// first XPU write back
//============================================================================================== 
assign  wb0_stb0        =                                                              bw5_stb0;     
assign  wb0_stb1        =                                                              bw5_stb1;     
assign  wb0_addr        =                                                              bw5_addr;     
                                                                                        
assign  wb0_enaA        =                                                              bw5_enaA;
assign  wb0_tagA        =                                                              bw5_tagA;        
                                                                                         
assign  wb0_enaB        =                                                              bw5_enaB; 
assign  wb0_tagB        =                                                              bw5_tagB; 
assign  wb0_modB        =                                                              bw5_modB;  
                                                                                             
assign  wb0_dataL       =                                                             bw5_dataL;
assign  wb0_dataH       =                                                             bw5_dataH; 
//==============================================================================================
// second XPU part - just for full XPU
//==============================================================================================  
assign        b3x_free      = !b3_fl_part2_ena;                               
assign        b3x_src       = b3x_free; // 0 - b3, 1 - xpu module input         
//==============================================================================================
// stage a (4)
//==============================================================================================  
reg             a4_stb;
reg             a4_tid;
reg     [ 1:0]  a4_dst_ena;
reg     [ 1:0]  a4_dst_tag;
reg      [1:0]  a4_pid;
reg     [31:0]  a4_v_addr;
reg     [31:0]  a4_opcode; 
reg      [4:0]  a4_dst_addr;
                             
reg             a4_fl_stb;
reg             a4_fl_mul;      
reg             a4_fl_add;
reg             a4_fl_sub;
reg             a4_fl_mul_add;
reg             a4_fl_mul_sub; 
reg             a4_fl_neg; 
reg             a4_fl_abs;  
                              
reg             a4_fl_a_sig;
reg     [ 9:0]  a4_fl_a_exp; 
reg     [24:0]  a4_fl_a_man; 
reg     [24:0]  a4_fl_a_man_;  
reg             a4_fl_b_sig; 
reg     [ 8:0]  a4_fl_b_exp; 
reg     [24:0]  a4_fl_b_man; 
reg     [24:0]  a4_fl_b_man_;  
                                    
reg             a4_fl_a_gr_b;  
reg     [ 9:0]  a4_fl_a_min_b_exp;
reg     [ 9:0]  a4_fl_b_min_a_exp; 
                                                        
reg             a4_from_input; 

wire    [ 7:0]  a4x_fl_exp_delta; 
wire    [24:0]  a4x_fl_add_a_man;   
wire    [24:0]  a4x_fl_add_b_man;  
wire            a4x_fl_add_sign; 
                                                              
wire            a4x_fl_ra_ezero;
wire            a4x_fl_ra_emax ;
wire            a4x_fl_ra_mzero;
wire            a4x_fl_ra_mmax ;
wire            a4x_fl_ra_nan  ;
wire            a4x_fl_ra_inf  ;
wire            a4x_fl_ra_zero ;
                           
wire            a4x_fl_rb_ezero;
wire            a4x_fl_rb_emax ;
wire            a4x_fl_rb_mzero;
wire            a4x_fl_rb_mmax ;
wire            a4x_fl_rb_nan  ;
wire            a4x_fl_rb_inf  ;
wire            a4x_fl_rb_zero ;
            
wire            a4x_fl_ra_eq_rb;                                                                                   
//==============================================================================================
// stage b (5) variables
//==============================================================================================    


reg             b5_stb;
reg             b5_tid;
reg     [ 1:0]  b5_dst_ena;
reg     [ 1:0]  b5_dst_tag;
reg      [1:0]  b5_pid;
reg     [31:0]  b5_v_addr;
reg     [31:0]  b5_opcode; 
reg      [4:0]  b5_dst_addr;
                             
reg             b5_fl_stb;
reg             b5_fl_mul;      
reg             b5_fl_add;
reg             b5_fl_sub;
reg             b5_fl_mul_add;
reg             b5_fl_mul_sub;  
reg             b5_fl_neg;
reg             b5_fl_abs;          

reg             b5_fl_ra_sig_f;
reg             b5_fl_ra_nan_f;
reg             b5_fl_ra_zero_f;
reg             b5_fl_ra_inf_f; 
reg             b5_fl_rb_sig_f; 
reg             b5_fl_rb_nan_f;
reg             b5_fl_rb_zero_f; 
reg             b5_fl_rb_inf_f;
reg             b5_fl_ra_eq_rb;          
                                     
reg     [ 8:0]  b5_fl_add_shift_cnt;   
                                  
reg             b5_fl_add_ab_sig;
reg     [ 9:0]  b5_fl_add_ab_exp;  
reg     [26:0]  b5_fl_add_a_man;  
reg     [26:0]  b5_fl_add_b_man;   
//==============================================================================================
// stage a (6) variables
//============================================================================================== 
reg             a6_stb;
reg             a6_tid;
reg     [ 1:0]  a6_dst_ena;
reg     [ 1:0]  a6_dst_tag;
reg      [1:0]  a6_pid;
reg     [31:0]  a6_v_addr;
reg     [31:0]  a6_opcode; 
reg      [4:0]  a6_dst_addr;

reg             a6_fl_stb;
reg             a6_fl_mul;      
reg             a6_fl_add;
reg             a6_fl_sub;
reg             a6_fl_mul_add;
reg             a6_fl_mul_sub;  
reg             a6_fl_neg;  
reg             a6_fl_abs;     

reg             a6_fl_add_nan_f;
reg             a6_fl_add_zero_f;
reg             a6_fl_add_inf_f;
                                 
reg      [9:0]  a6_fl_add_ab_exp;
reg             a6_fl_add_ab_sig;  

wire     [7:0]  a6_fl_add_exp_decrease;
//==============================================================================================
// stage b (7) variables
//============================================================================================== 
reg             b7_stb;
reg             b7_tid;
reg     [ 1:0]  b7_dst_ena;
reg     [ 1:0]  b7_dst_tag;
reg      [1:0]  b7_pid;
reg     [31:0]  b7_v_addr;
reg     [31:0]  b7_opcode;
reg      [4:0]  b7_dst_addr;
                             
reg             b7_fl_stb;
reg             b7_fl_mul;      
reg             b7_fl_add;
reg             b7_fl_sub;
reg             b7_fl_mul_add;
reg             b7_fl_mul_sub; 
reg             b7_fl_neg; 
reg             b7_fl_abs;
                                  
reg      [9:0]  b7_fl_add_ab_exp;
wire     [3:0]  b7x_fl_add_nonz_nibble;
wire     [9:0]  b7x_fl_add_ab_exp_offh;
reg             b7_fl_add_ab_sig;

wire    [26:0]  b7_fl_add_man; 

reg      [7:0]  b7_fl_add_ab_exp_exe; 
reg     [26:0]  b7_fl_add_man_exe; 
reg             b7_fl_add_exe_f; 
                                                
wire    [ 6:0]  b7_fl_add_man_nz_nibble_pos;   
wire    [ 3:0]  b7_fl_add_man_nz_nibble;                                                            
//==============================================================================================
// stage a (8) variables
//============================================================================================== 
reg             a8_stb;
reg             a8_tid;
reg     [ 1:0]  a8_dst_ena;
reg     [ 1:0]  a8_dst_tag;
reg      [1:0]  a8_pid;
reg     [31:0]  a8_v_addr;
reg     [31:0]  a8_opcode;
reg      [4:0]  a8_dst_addr;
                             
reg             a8_fl_stb;
reg             a8_fl_mul;      
reg             a8_fl_add;
reg             a8_fl_sub;
reg             a8_fl_mul_add;
reg             a8_fl_mul_sub;  
reg             a8_fl_neg;  
reg             a8_fl_abs;  
                               
reg      [9:0]  a8_fl_add_ab_exp;          
reg             a8_fl_add_ab_sig;
                
reg     [27:0]  a8_fl_add_man;  
reg     [ 3:0]  a8_fl_add_nonz_nibble;   
reg     [ 1:0]  a8_zero_bit_cnt; 

reg      [7:0]  a8_fl_add_ab_exp_exe; 
reg     [26:0]  a8_fl_add_man_exe; 
reg             a8_fl_add_exe_f;                                                           
//==============================================================================================
// stage b (9) variables
//============================================================================================== 
reg             b9_stb;
reg             b9_tid;
reg     [ 1:0]  b9_dst_ena;
reg     [ 1:0]  b9_dst_tag;
reg      [1:0]  b9_pid;
reg     [31:0]  b9_v_addr;
reg     [31:0]  b9_opcode;
reg      [4:0]  b9_dst_addr;
                            
reg             b9_fl_stb;
reg             b9_fl_mul;      
reg             b9_fl_add;
reg             b9_fl_sub;
reg             b9_fl_mul_add;
reg             b9_fl_mul_sub; 
reg             b9_fl_neg;
reg             b9_fl_abs;
                               
reg      [9:0]  b9_fl_add_ab_exp;
reg             b9_fl_add_ab_sig;
                
reg     [27:0]  b9_fl_add_man; 

reg      [7:0]  b9_fl_add_ab_exp_exe; 
reg     [26:0]  b9_fl_add_man_exe; 
reg             b9_fl_add_exe_f;                                                                                                  
//==============================================================================================
// b9x - mux on b9 and exeptions and b3  variables
//============================================================================================== 
wire            b9x_A_ena;    
wire            b9x_t0_ena;    
wire            b9x_t1_ena;   
wire    [ 4:0]  b9x_dst_addr;   
wire    [ 1:0]  b9x_tag;    
wire            b9x_B_ena;
wire            b9x_B_mod;
wire    [31:0]  b9x_lo_data; 
wire    [31:0]  b9x_hi_data;    
//==============================================================================================                                                                                                                                                      
always@(posedge clk or posedge rst)   
 if(rst) 
  begin                                                                         
    a4_stb                  <=                                                             1'b0;
    a4_from_input           <=                                                             1'b0;
    a4_dst_ena              <=                                                             2'd0;
    a4_dst_tag              <=                                                             2'd0;
    a4_tid                  <=                                                             1'b0;
    a4_pid                  <=                                                             2'b0;
    a4_v_addr               <=                                                            32'd0;
    a4_opcode               <=                                                            32'd0;
    a4_dst_addr             <=                                                             5'd0;                                             
                                                                                                 
    a4_fl_stb               <=                                                             1'b0;     
    a4_fl_mul               <=                                                             1'b0;
    a4_fl_sub               <=                                                             1'b0;
    a4_fl_add               <=                                                             1'b0; 
    a4_fl_mul_add           <=                                                             1'b0;
    a4_fl_mul_sub           <=                                                             1'b0;
    a4_fl_neg               <=                                                             1'b0;
    a4_fl_abs               <=                                                             1'b0;
                                                                                                
    //a4_fl_conv              <=                                                             1'b0;
    //a4_fl_conv_data         <=                                                            32'd0;
    
    a4_fl_a_exp             <=                                                            10'd0; 
    a4_fl_b_exp             <=                                                             9'd0; 
    a4_fl_a_man             <=                                                            25'd0;
    a4_fl_a_man_            <=                                                            25'd0;
    a4_fl_b_man             <=                                                            25'd0;
    a4_fl_b_man_            <=                                                            25'd0;
    a4_fl_a_sig             <=                                                             1'd0; 
    a4_fl_b_sig             <=                                                             1'd0; 
    
    a4_fl_b_min_a_exp       <=                                                             8'd0;    
    a4_fl_a_min_b_exp       <=                                                             8'd0;
    a4_fl_a_gr_b            <=                                                             1'b0; 
  end      
 else  
  begin                                                                                         
    a4_stb                  <=  b3_fl_part2_ena || (i_stb && !fci_inst_jpf && (f_fl_add || f_fl_sub));
    a4_from_input           <=                                                          b3x_src; 
    a4_tid                  <=  (b3_fl_part2_ena)?                                 b3_tid  :       i_tid;
    a4_dst_ena              <=  (b3_fl_part2_ena)?                     b3_dst_ena :    i_ry_ena;
    a4_dst_tag              <=  (b3_fl_part2_ena)?                     b3_dst_tag :    i_ry_tag;
    a4_pid                  <=  (b3_fl_part2_ena)?                        b3_pid  :       i_pid;
    a4_v_addr               <=  (b3_fl_part2_ena)?                      b3_v_addr :       i_iva;
    a4_opcode               <=  (b3_fl_part2_ena)?                      b3_opcode :       i_opc;
    a4_dst_addr             <=  (b3_fl_part2_ena)?                    b3_dst_addr :   i_ry_addr;
                                                                                                
    a4_fl_stb               <=  (b3_fl_part2_ena)?                b3_fl_stb    :  f_fl_stb    ;  
    a4_fl_mul               <=  (b3_fl_part2_ena)?                b3_fl_mul    :  f_fl_mul    ;
    a4_fl_sub               <=  (b3_fl_part2_ena)?                b3_fl_sub    :  f_fl_sub    ;
    a4_fl_add               <=  (b3_fl_part2_ena)?                b3_fl_add    :  f_fl_add    ; 
    a4_fl_mul_add           <=  (b3_fl_part2_ena)?                b3_fl_mul_add:  f_fl_mul_add;
    a4_fl_mul_sub           <=  (b3_fl_part2_ena)?                b3_fl_mul_sub:  f_fl_mul_sub; 
    a4_fl_neg               <=  (b3_fl_part2_ena)?                b3_fl_neg    :  f_fl_neg    ; 
    a4_fl_abs               <=  (b3_fl_part2_ena)?                b3_fl_abs    :  f_fl_abs    ;    
                                                                                                
    a4_fl_a_sig             <=  (b3_fl_part2_ena)?             b3_fl_mul_ab_sig: i_r0_data[31];// ^ f_fl_neg; 
    a4_fl_a_exp             <=  (b3_fl_part2_ena)?                b3_fl_mul_ab_exp:  i_fl_a_exp; 
    a4_fl_a_man             <=  (b3_fl_part2_ena)? {1'b0, b3_fl_mul_ab_man}: {1'b0, i_fl_a_man};
    a4_fl_a_man_            <=  (b3_fl_part2_ena)?-{1'b0, b3_fl_mul_ab_man}:-{1'b0, i_fl_a_man};
    
    a4_fl_b_sig             <=  (b3_fl_part2_ena)? b3_fl_mul_cd_sig ^ b3_fl_sub ^ b3_fl_mul_sub:
                                                        i_r1_data[31] ^ f_fl_sub ^ f_fl_mul_sub;// ^ f_fl_neg;
    a4_fl_b_exp             <=  (b3_fl_part2_ena)?                b3_fl_mul_cd_exp:  i_fl_c_exp; 
    a4_fl_b_man             <=  (b3_fl_part2_ena)? {1'b0, b3_fl_mul_cd_man}: {1'b0, i_fl_c_man};
    a4_fl_b_man_            <=  (b3_fl_part2_ena)?-{1'b0, b3_fl_mul_cd_man}:-{1'b0, i_fl_c_man};
                                                                                                                                     
    a4_fl_a_gr_b            <=  (b3_fl_part2_ena)?                b3x_fl_a_gr_b : f_i_fl_a_gr_c;
                                                                                                
    a4_fl_a_min_b_exp       <=  (b3_fl_part2_ena)?{1'b0, b3_fl_mul_ab_exp} - {1'b0, b3_fl_mul_cd_exp}:
                                                  {2'b0, i_r0_data[30:23]} - {2'b0, i_r1_data[30:23]};
    a4_fl_b_min_a_exp       <=  (b3_fl_part2_ena)?{1'b0, b3_fl_mul_cd_exp} - {1'b0, b3_fl_mul_ab_exp}:
                                                  {2'b0, i_r1_data[30:23]} - {2'b0, i_r0_data[30:23]}; 
  end                                                                      
//==============================================================================================
// stage b (5)
//============================================================================================== 
assign a4x_fl_exp_delta = (a4_fl_a_gr_b)?    a4_fl_a_min_b_exp[7:0] : a4_fl_b_min_a_exp[7:0];   
assign a4x_fl_add_a_man = (a4_fl_a_gr_b)?               a4_fl_a_man :            a4_fl_b_man; 
                                                                                               
assign a4x_fl_add_b_man =                                                                    
    ({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig} == 3'b1_01)?                      a4_fl_b_man_:
    ({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig} == 3'b1_10)?                      a4_fl_b_man_:
    ({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig} == 3'b1_11)?                      a4_fl_b_man :
    ({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig} == 3'b1_00)?                      a4_fl_b_man :
    ({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig} == 3'b0_11)?                      a4_fl_a_man :
    ({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig} == 3'b0_00)?                      a4_fl_a_man :
                                                                                a4_fl_a_man_;
assign a4x_fl_add_sign =                                                                     
    ({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig} == 3'b1_11)?                      1'b0 :
    ({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig} == 3'b1_00)?                      1'b0 :
    ({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig} == 3'b0_11)?                      1'b0 :
    ({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig} == 3'b0_00)?                      1'b0 :
                                                                                1'b1;  
                                                                                                                                                   
assign  a4x_fl_ra_ezero   =   a4_fl_a_exp[7: 0]   ==  8'd0;
assign  a4x_fl_ra_emax    =   a4_fl_a_exp[7: 0]   ==  8'hFF;
assign  a4x_fl_ra_mzero   =   a4_fl_a_man[22: 0]  == 23'd0;      
assign  a4x_fl_ra_mmax    =   a4_fl_a_man[23: 0]  == 24'hFFFFFF; 
assign  a4x_fl_ra_nan     =   a4x_fl_ra_emax  && !a4x_fl_ra_mzero;  
assign  a4x_fl_ra_inf     =   a4x_fl_ra_emax  &&  a4x_fl_ra_mzero;
assign  a4x_fl_ra_zero    =   a4x_fl_ra_ezero/* &&  a4x_fl_ra_mzero*/;
      
assign  a4x_fl_rb_ezero   =   a4_fl_b_exp[7: 0]   ==  8'd0;
assign  a4x_fl_rb_emax    =   a4_fl_b_exp[7: 0]   ==  8'hFF;
assign  a4x_fl_rb_mzero   =   a4_fl_b_man[22: 0]  == 23'd0;
assign  a4x_fl_rb_mmax    =   a4_fl_b_man[23: 0]  == 24'hFFFFFF; 
assign  a4x_fl_rb_nan     =   a4x_fl_rb_emax  && !a4x_fl_rb_mzero;  
assign  a4x_fl_rb_inf     =   a4x_fl_rb_emax  &&  a4x_fl_rb_mzero;
assign  a4x_fl_rb_zero    =   a4x_fl_rb_ezero/* &&  a4x_fl_rb_mzero*/; 
      
assign  a4x_fl_ra_eq_rb   =   {a4_fl_a_exp, a4_fl_a_man} == {a4_fl_b_exp, a4_fl_b_man}; 
//----------------------------------------------------------------------------------------------
eco32_core_xpu_sh_add_bezDSP 
#(
.FORCE_RST          (FORCE_RST)
)
xsh_add
(
.clk                    (clk),
.rst                    (rst),

.i_stb                  (a4_stb && (!a4_from_input || a0x_ins_valid)),

.i_sh_bit               (a4x_fl_exp_delta),     // shift od 0 do ...                                   
                                                // i_sh_bit[23:0] == 0             -> zerowanie argumentu b     
.i_arg_a                (a4x_fl_add_a_man),  
.i_arg_b                (a4x_fl_add_b_man),     
.i_sign                 (a4x_fl_add_sign),   

.o_exp_decrease         (a6_fl_add_exp_decrease),
.o_data                 (b7_fl_add_man),
.o_data_nz_nibble       (b7_fl_add_man_nz_nibble_pos)
);
//---------------------------------------------------------------------------------------------- 
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                                         
    b5_stb                  <=                                                             1'b0;
    b5_tid                  <=                                                             1'b0;
    b5_dst_ena              <=                                                             2'd0;
    b5_dst_tag              <=                                                             2'd0;
    b5_pid                  <=                                                             2'b0;
    b5_v_addr               <=                                                            32'd0;
    b5_opcode               <=                                                            32'd0;
    b5_dst_addr             <=                                                             5'b0;                                                 
                                                                                                
    b5_fl_stb               <=                                                             1'b0;     
    b5_fl_mul               <=                                                             1'b0;
    b5_fl_sub               <=                                                             1'b0;
    b5_fl_add               <=                                                             1'b0; 
    b5_fl_mul_add           <=                                                             1'b0;
    b5_fl_mul_sub           <=                                                             1'b0; 
    b5_fl_neg               <=                                                             1'b0;
    b5_fl_abs               <=                                                             1'b0;
                                                                                                
    b5_fl_ra_sig_f          <=                                                             1'b0;
    b5_fl_ra_nan_f          <=                                                             1'd0;
    b5_fl_ra_zero_f         <=                                                             1'd0;
    b5_fl_ra_inf_f          <=                                                             1'd0;
    b5_fl_rb_sig_f          <=                                                             1'b0;  
    b5_fl_rb_nan_f          <=                                                             1'd0;
    b5_fl_rb_zero_f         <=                                                             1'd0;
    b5_fl_rb_inf_f          <=                                                             1'd0;
    b5_fl_ra_eq_rb          <=                                                             1'd0;
                                                                                                   
    b5_fl_add_ab_sig        <=                                                             1'd0;
    b5_fl_add_ab_exp        <=                                                            10'd0; 
    b5_fl_add_a_man         <=                                                            26'd0;
    b5_fl_add_b_man         <=                                                            26'd0;  
  end
 else  
  begin
    b5_stb                  <=                    a4_stb && (!a4_from_input || a0x_ins_valid)  ; 
    b5_tid                  <=                                                           a4_tid;
    b5_dst_ena              <=              a4_dst_ena & {2{(!a4_from_input || a0x_ins_valid)}};
    b5_dst_tag              <=                                                       a4_dst_tag;
    b5_pid                  <=                                                           a4_pid;
    b5_v_addr               <=                                                        a4_v_addr;
    b5_opcode               <=                                                        a4_opcode;
    b5_dst_addr             <=                                                      a4_dst_addr; 
                                                                                                
    b5_fl_stb               <=                                                    a4_fl_stb    ;     
    b5_fl_mul               <=                                                    a4_fl_mul    ;
    b5_fl_sub               <=                                                    a4_fl_sub    ;
    b5_fl_add               <=                                                    a4_fl_add    ; 
    b5_fl_mul_add           <=                                                    a4_fl_mul_add;
    b5_fl_mul_sub           <=                                                    a4_fl_mul_sub; 
    b5_fl_neg               <=                                                    a4_fl_neg    ;
    b5_fl_abs               <=                                                    a4_fl_abs    ; 
                                                                                                
    b5_fl_add_shift_cnt     <=                                                 a4x_fl_exp_delta;   
                                               
    b5_fl_add_a_man         <=                                                 a4x_fl_add_a_man;  
    b5_fl_add_b_man         <=                                                 a4x_fl_add_b_man; 
                                                                                                 
    case(a4_fl_a_gr_b)                                               
    1'b1:        b5_fl_add_ab_exp   <=                                              a4_fl_a_exp;     
    default:     b5_fl_add_ab_exp   <=                                              a4_fl_b_exp;
    endcase     
    
    casex({a4_fl_a_gr_b, a4_fl_a_sig, a4_fl_b_sig})                                              
    3'b1_1x:     b5_fl_add_ab_sig   <=                                                     1'b1;
    3'b0_x1:     b5_fl_add_ab_sig   <=                                                     1'b1;     
    default:     b5_fl_add_ab_sig   <=                                                     1'b0;
    endcase  
                                                                                                 
    b5_fl_ra_sig_f          <=                                                   a4_fl_a_sig   ;
    b5_fl_ra_nan_f          <=                                                   a4x_fl_ra_nan ;
    b5_fl_ra_zero_f         <=                                                   a4x_fl_ra_zero;
    b5_fl_ra_inf_f          <=                                                   a4x_fl_ra_inf ;
    b5_fl_rb_sig_f          <=                                                   a4_fl_b_sig   ;
    b5_fl_rb_nan_f          <=                                                   a4x_fl_rb_nan ;
    b5_fl_rb_zero_f         <=                                                   a4x_fl_rb_zero;
    b5_fl_rb_inf_f          <=                                                   a4x_fl_rb_inf ;
    b5_fl_ra_eq_rb          <=                                                  a4x_fl_ra_eq_rb; 
    
  end           
//==============================================================================================
// stage a (6)
//==============================================================================================                                                                                                                
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    a6_stb                  <=                                                             1'b0;
    a6_tid                  <=                                                             1'b0; 
    a6_dst_ena              <=                                                             2'd0;
    a6_dst_tag              <=                                                             2'd0;
    a6_pid                  <=                                                             2'b0;
    a6_v_addr               <=                                                            32'd0;
    a6_opcode               <=                                                            32'd0;
    a6_dst_addr             <=                                                             5'b0;  
                                                                                                
    a6_fl_stb               <=                                                             1'b0;     
    a6_fl_mul               <=                                                             1'b0;
    a6_fl_sub               <=                                                             1'b0;
    a6_fl_add               <=                                                             1'b0; 
    a6_fl_mul_add           <=                                                             1'b0;
    a6_fl_mul_sub           <=                                                             1'b0; 
    a6_fl_neg               <=                                                             1'b0; 
    a6_fl_abs               <=                                                             1'b0; 
    
    a6_fl_add_nan_f         <=                                                             1'b0;
    a6_fl_add_zero_f        <=                                                             1'b0;
    a6_fl_add_inf_f         <=                                                             1'b0;
                                                                                                
    a6_fl_add_ab_exp        <=                                                            10'd0;
    a6_fl_add_ab_sig        <=                                                             1'b0;
  end
 else  
  begin
    a6_stb                  <=                                                           b5_stb;
    a6_tid                  <=                                                           b5_tid;
    a6_dst_ena              <=                                                       b5_dst_ena;
    a6_dst_tag              <=                                                       b5_dst_tag;
    a6_pid                  <=                                                           b5_pid;
    a6_v_addr               <=                                                        b5_v_addr;
    a6_opcode               <=                                                        b5_opcode;
    a6_dst_addr             <=                                                      b5_dst_addr; 
    
    a6_fl_stb               <=                                                    b5_fl_stb    ;     
    a6_fl_mul               <=                                                    b5_fl_mul    ;
    a6_fl_sub               <=                                                    b5_fl_sub    ;
    a6_fl_add               <=                                                    b5_fl_add    ; 
    a6_fl_mul_add           <=                                                    b5_fl_mul_add;
    a6_fl_mul_sub           <=                                                    b5_fl_mul_sub;   
    a6_fl_neg               <=                                                    b5_fl_neg    ; 
    a6_fl_abs               <=                                                    b5_fl_abs    ; 
    
    a6_fl_add_nan_f         <=                               b5_fl_ra_nan_f || b5_fl_rb_nan_f || 
                                                            (b5_fl_ra_inf_f && b5_fl_rb_inf_f && 
                                                            (b5_fl_ra_sig_f ^  b5_fl_rb_sig_f));
    a6_fl_add_zero_f        <=         ((b5_fl_ra_sig_f ^ b5_fl_rb_sig_f ) && b5_fl_ra_eq_rb) ||
                                                           (b5_fl_ra_zero_f && b5_fl_rb_zero_f);
    a6_fl_add_inf_f         <=                                 b5_fl_ra_inf_f || b5_fl_rb_inf_f;        
    
    a6_fl_add_ab_exp        <=                                         b5_fl_add_ab_exp + 10'd1;
    a6_fl_add_ab_sig        <=                                                 b5_fl_add_ab_sig;
  end                                                                                          
//==============================================================================================
// stage b (7)
//============================================================================================== 
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    b7_stb                  <=                                                             1'b0;
    b7_tid                  <=                                                             1'b0;
    b7_dst_ena              <=                                                             2'd0;
    b7_dst_tag              <=                                                             2'd0;
    b7_pid                  <=                                                             2'b0;
    b7_v_addr               <=                                                            32'd0;
    b7_opcode               <=                                                            32'd0;
    b7_dst_addr             <=                                                             5'd0;
                                                                                                
    b7_fl_stb               <=                                                             1'b0;     
    b7_fl_mul               <=                                                             1'b0;
    b7_fl_sub               <=                                                             1'b0;
    b7_fl_add               <=                                                             1'b0; 
    b7_fl_mul_add           <=                                                             1'b0;
    b7_fl_mul_sub           <=                                                             1'b0; 
    b7_fl_neg               <=                                                             1'b0; 
    b7_fl_abs               <=                                                             1'b0; 
                                                                                                
    b7_fl_add_ab_exp        <=                                                            10'd0;
    b7_fl_add_ab_sig        <=                                                             1'd0;
    
    b7_fl_add_ab_exp_exe    <=                                                             8'd0; 
    b7_fl_add_man_exe       <=                                                            26'd0;
    b7_fl_add_exe_f         <=                                                             1'b0;
  end
 else  
  begin
    b7_stb                  <=                                                           a6_stb;
    b7_tid                  <=                                                           a6_tid;
    b7_dst_ena              <=                                                       a6_dst_ena;
    b7_dst_tag              <=                                                       a6_dst_tag;
    b7_pid                  <=                                                           a6_pid;
    b7_v_addr               <=                                                        a6_v_addr;
    b7_opcode               <=                                                        a6_opcode; 
    b7_dst_addr             <=                                                      a6_dst_addr;
                                                                                                
    b7_fl_stb               <=                                                    a6_fl_stb    ;     
    b7_fl_mul               <=                                                    a6_fl_mul    ;
    b7_fl_sub               <=                                                    a6_fl_sub    ;
    b7_fl_add               <=                                                    a6_fl_add    ; 
    b7_fl_mul_add           <=                                                    a6_fl_mul_add;
    b7_fl_mul_sub           <=                                                    a6_fl_mul_sub; 
    b7_fl_neg               <=                                                    a6_fl_neg    ; 
    b7_fl_abs               <=                                                    a6_fl_abs    ;   
                                                                                                 
    b7_fl_add_ab_exp        <=                        a6_fl_add_ab_exp - a6_fl_add_exp_decrease;
    b7_fl_add_ab_sig        <=                                                 a6_fl_add_ab_sig;
                                                                                                        
    b7_fl_add_ab_exp_exe    <=  (a6_fl_add_nan_f)? 8'hFF:
                                (a6_fl_add_inf_f)? 8'hFF:
                                                   8'h00; 
    b7_fl_add_man_exe       <=  (a6_fl_add_nan_f)? 26'h3FFFFFF:
                                (a6_fl_add_inf_f)? 26'h0000000:
                                                   26'h0000000;
    b7_fl_add_exe_f         <= a6_fl_add_nan_f || a6_fl_add_zero_f || a6_fl_add_inf_f;
  end                                                                
//==============================================================================================
// stage a (8)
//==============================================================================================        
assign   b7x_fl_add_nonz_nibble   =   (b7_fl_add_man_nz_nibble_pos[6])? {1'd0, b7_fl_add_man[26:24]}:
                                      (b7_fl_add_man_nz_nibble_pos[5])?        b7_fl_add_man[23:20]:                                      
                                      (b7_fl_add_man_nz_nibble_pos[4])?        b7_fl_add_man[19:16]:                                      
                                      (b7_fl_add_man_nz_nibble_pos[3])?        b7_fl_add_man[15:12]:                                      
                                      (b7_fl_add_man_nz_nibble_pos[2])?        b7_fl_add_man[11: 8]:                                      
                                      (b7_fl_add_man_nz_nibble_pos[1])?        b7_fl_add_man[ 7: 4]:                                      
                                      (b7_fl_add_man_nz_nibble_pos[0])?        b7_fl_add_man[ 3: 0]:    
                                                                               b7_fl_add_man[ 3: 0];
assign   b7x_fl_add_ab_exp_offh =                                                                              
        (b7_fl_add_man_nz_nibble_pos[6])?       -10'd05: 
        (b7_fl_add_man_nz_nibble_pos[5])?       -10'd09:
        (b7_fl_add_man_nz_nibble_pos[4])?       -10'd13:
        (b7_fl_add_man_nz_nibble_pos[3])?       -10'd17: 
        (b7_fl_add_man_nz_nibble_pos[2])?       -10'd21:
        (b7_fl_add_man_nz_nibble_pos[2])?       -10'd25:
        (b7_fl_add_man_nz_nibble_pos[0])?       -10'd29:
                                                 10'd00; 
//----------------------------------------------------------------------------------------------   
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    a8_stb                  <=                                                             1'b0;
    a8_tid                  <=                                                             1'b0;
    a8_dst_ena              <=                                                             2'd0;
    a8_dst_tag              <=                                                             2'd0;
    a8_pid                  <=                                                             2'b0;
    a8_v_addr               <=                                                            32'd0;
    a8_opcode               <=                                                            32'd0;
    a8_dst_addr             <=                                                             5'd0;  
                                                                                            
    a8_fl_stb               <=                                                             1'b0;     
    a8_fl_mul               <=                                                             1'b0;
    a8_fl_sub               <=                                                             1'b0;
    a8_fl_add               <=                                                             1'b0; 
    a8_fl_mul_add           <=                                                             1'b0;
    a8_fl_mul_sub           <=                                                             1'b0; 
    a8_fl_neg               <=                                                             1'b0; 
    a8_fl_abs               <=                                                             1'b0; 
                                                                                                
    a8_fl_add_ab_exp        <=                                                            10'd0;
    a8_fl_add_ab_sig        <=                                                             1'd0;
    
    a8_fl_add_ab_exp_exe    <=                                                             8'd0;   
    a8_fl_add_man           <=                                                            28'd0; 
    a8_fl_add_nonz_nibble   <=                                                             4'd0;                  
    
    a8_fl_add_man_exe       <=                                                            26'd0;
    a8_fl_add_exe_f         <=                                                             1'b0; 
  end
 else  
  begin
    a8_stb                  <=                                                           b7_stb;
    a8_tid                  <=                                                           b7_tid;
    a8_dst_ena              <=                                                       b7_dst_ena;
    a8_dst_tag              <=                                                       b7_dst_tag;
    a8_pid                  <=                                                           b7_pid;
    a8_v_addr               <=                                                        b7_v_addr;
    a8_opcode               <=                                                        b7_opcode; 
    a8_dst_addr             <=                                                      b7_dst_addr;
                                                                                               
    a8_fl_stb               <=                                                    b7_fl_stb    ;     
    a8_fl_mul               <=                                                    b7_fl_mul    ;
    a8_fl_sub               <=                                                    b7_fl_sub    ;
    a8_fl_add               <=                                                    b7_fl_add    ; 
    a8_fl_mul_add           <=                                                    b7_fl_mul_add;
    a8_fl_mul_sub           <=                                                    b7_fl_mul_sub; 
    a8_fl_neg               <=                                                    b7_fl_neg    ; 
    a8_fl_abs               <=                                                    b7_fl_abs    ;  
                                                                                               
    a8_fl_add_ab_exp        <=                        b7_fl_add_ab_exp + b7x_fl_add_ab_exp_offh; 

    a8_fl_add_ab_sig        <=                                                 b7_fl_add_ab_sig; 
    
    begin                                                                               
             if(b7_fl_add_man_nz_nibble_pos[6]) a8_fl_add_man <=    {1'd0, b7_fl_add_man[26:0]}; 
        else if(b7_fl_add_man_nz_nibble_pos[5]) a8_fl_add_man <=    {b7_fl_add_man[23:0], 4'd0};
        else if(b7_fl_add_man_nz_nibble_pos[4]) a8_fl_add_man <=    {b7_fl_add_man[19:0], 8'd0};
        else if(b7_fl_add_man_nz_nibble_pos[3]) a8_fl_add_man <=    {b7_fl_add_man[15:0],12'd0};
        else if(b7_fl_add_man_nz_nibble_pos[2]) a8_fl_add_man <=    {b7_fl_add_man[11:0],16'd0}; 
        else if(b7_fl_add_man_nz_nibble_pos[1]) a8_fl_add_man <=    {b7_fl_add_man[ 7:0],20'd0};
        else if(b7_fl_add_man_nz_nibble_pos[0]) a8_fl_add_man <=    {b7_fl_add_man[ 3:0],24'd0};
        else                                    a8_fl_add_man <=    {                    28'd0};
    end 
    a8_fl_add_nonz_nibble   <=                                           b7x_fl_add_nonz_nibble;
    
    a8_fl_add_ab_exp_exe    <=                                             b7_fl_add_ab_exp_exe;   
    a8_fl_add_man_exe       <=                                                b7_fl_add_man_exe;
    a8_fl_add_exe_f         <=                                                  b7_fl_add_exe_f;   
  end                                                
//==============================================================================================
// stage b (9)
//==============================================================================================  
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    b9_stb                  <=                                                             1'b0;
    b9_tid                  <=                                                             1'b0;
    b9_dst_ena              <=                                                             2'd0;
    b9_dst_tag              <=                                                             2'd0;
    b9_pid                  <=                                                             2'b0;
    b9_v_addr               <=                                                            32'd0;
    b9_opcode               <=                                                            32'd0;
    b9_dst_addr             <=                                                             5'd0; 
                                                                                               
    b9_fl_stb               <=                                                             1'b0;     
    b9_fl_mul               <=                                                             1'b0;
    b9_fl_sub               <=                                                             1'b0;
    b9_fl_add               <=                                                             1'b0; 
    b9_fl_mul_add           <=                                                             1'b0;
    b9_fl_mul_sub           <=                                                             1'b0;
    b9_fl_neg               <=                                                             1'b0;
    b9_fl_abs               <=                                                             1'b0; 
                                                                                                 
    b9_fl_add_ab_sig        <=                                                             1'd0;
    b9_fl_add_ab_exp        <=                                                            10'd0;
    b9_fl_add_man           <=                                                            28'd0; 
                                                                                                 
    b9_fl_add_ab_exp_exe    <=                                                             8'd0;   
    b9_fl_add_man_exe       <=                                                            26'd0;
    b9_fl_add_exe_f         <=                                                             1'b0; 
  end
 else  
  begin
    b9_stb                  <=                                                           a8_stb;
    b9_tid                  <=                                                           a8_tid;
    b9_dst_ena              <=                                                       a8_dst_ena;
    b9_dst_tag              <=                                                       a8_dst_tag;
    b9_pid                  <=                                                           a8_pid;
    b9_v_addr               <=                                                        a8_v_addr;
    b9_opcode               <=                                                        a8_opcode; 
    b9_dst_addr             <=                                                      a8_dst_addr;
                                                                                                
    b9_fl_stb               <=                                                    a8_fl_stb    ;     
    b9_fl_mul               <=                                                    a8_fl_mul    ;
    b9_fl_sub               <=                                                    a8_fl_sub    ;
    b9_fl_add               <=                                                    a8_fl_add    ; 
    b9_fl_mul_add           <=                                                    a8_fl_mul_add;
    b9_fl_mul_sub           <=                                                    a8_fl_mul_sub; 
    b9_fl_neg               <=                                                    a8_fl_neg    ; 
    b9_fl_abs               <=                                                    a8_fl_abs    ;  
                                                                               
    b9_fl_add_ab_sig        <=                    (a8_fl_add_ab_sig & (!a8_fl_abs)) ^ a8_fl_neg;
    begin                                                                                         
             if(a8_fl_add_nonz_nibble[3] == 1'd1) b9_fl_add_ab_exp <=  a8_fl_add_ab_exp + 10'd9; 
        else if(a8_fl_add_nonz_nibble[2] == 1'd1) b9_fl_add_ab_exp <=  a8_fl_add_ab_exp + 10'd8;
        else if(a8_fl_add_nonz_nibble[1] == 1'd1) b9_fl_add_ab_exp <=  a8_fl_add_ab_exp + 10'd7;
        else if(a8_fl_add_nonz_nibble[0] == 1'd1) b9_fl_add_ab_exp <=  a8_fl_add_ab_exp + 10'd6;             
        else                                      b9_fl_add_ab_exp <=  a8_fl_add_ab_exp + 10'd6;
    end                                                                                          
    begin                                                                               
             if(a8_fl_add_nonz_nibble[3] == 1'd1) b9_fl_add_man  <=  a8_fl_add_man[27:0]       ; 
        else if(a8_fl_add_nonz_nibble[2] == 1'd1) b9_fl_add_man  <= {a8_fl_add_man[26:0], 1'd0};
        else if(a8_fl_add_nonz_nibble[1] == 1'd1) b9_fl_add_man  <= {a8_fl_add_man[25:0], 2'd0};
        else if(a8_fl_add_nonz_nibble[0] == 1'd1) b9_fl_add_man  <= {a8_fl_add_man[24:0], 3'd0};             
        else                                      b9_fl_add_man  <= {a8_fl_add_man[24:0], 3'd0};
    end   
    b9_fl_add_ab_exp_exe    <=                                             a8_fl_add_ab_exp_exe;   
    b9_fl_add_man_exe       <=                                                a8_fl_add_man_exe;
    b9_fl_add_exe_f         <=                                                  a8_fl_add_exe_f;                                                                                       
  end                                                                                                                                                                                                 
//==============================================================================================
// b9x - mux on b9 and exeptions
//==============================================================================================                              
assign  b9x_t0_ena      =                                                   (!b9_tid && b9_stb);     
assign  b9x_t1_ena      =                                                   ( b9_tid && b9_stb); 

assign  b9x_dst_addr    =                                                           b9_dst_addr;     
assign  b9x_tag         =                                                            b9_dst_tag;

assign  b9x_A_ena       =                                               b9_stb && b9_dst_ena[0];  

assign  b9x_B_ena       =                                               b9_stb && b9_dst_ena[1];     
assign  b9x_B_mod       =                                                                  1'b0;

assign  b9x_lo_data     = (b9_fl_add_exe_f)?        {b9_fl_add_ab_sig, b9_fl_add_ab_exp_exe[7:0], b9_fl_add_man_exe[24:2]}:          
                          (b9_fl_add_ab_exp[9])?    {b9_fl_add_ab_sig, 8'd0                     , 23'd0                  }:  // zero 
                          (b9_fl_add_ab_exp[8])?    {b9_fl_add_ab_sig, 8'hFF                    , 23'd0                  }:  // inf
                          (&b9_fl_add_ab_exp[7:0])? {b9_fl_add_ab_sig, 8'hFF                    , 23'd0                  }:  // inf
                                                    {b9_fl_add_ab_sig, b9_fl_add_ab_exp[7:0]    , b9_fl_add_man[26:4]    };   
                                                                                                                                                 
assign  b9x_hi_data     =                                                                 32'b0;  
                                                                                              
//==============================================================================================
// second XPU write back
//==============================================================================================   
assign  wb1_stb0        =                                                            b9x_t0_ena;     
assign  wb1_stb1        =                                                            b9x_t1_ena;     
assign  wb1_addr        =                                                          b9x_dst_addr;     
                                             
assign  wb1_enaA        =                                                        {2{b9x_A_ena}};
assign  wb1_tagA        =                                                            b9x_tag[0];          

assign  wb1_enaB        =                                                        {2{b9x_B_ena}}; 
assign  wb1_tagB        =                                                            b9x_tag[1]; 
assign  wb1_modB        =                                                             b9x_B_mod;  

assign  wb1_dataL       =                                                           b9x_lo_data;
assign  wb1_dataH       =                                                           b9x_hi_data; 
//============================================================================================== 
endmodule                
                         
                         
                         
                         
                         
                         