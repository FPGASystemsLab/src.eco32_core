//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
module eco32_core_lsu_box
(
 input  wire            clk,
 input  wire            rst,   
 output wire            rdy,
 
 // input port from IDU
 
 input  wire            i_stb,
 input  wire            i_tid,
 input  wire     [1:0]  i_pid,
 input  wire     [3:0]  i_asid,
 input  wire     [1:0]  i_isz,
 input  wire    [15:0]  i_isw,
 input  wire    [31:0]  i_iva,
 
 // LSU control word
 
 input  wire    [14:0]  i_ls_cw,
 
 // src data

 input  wire    [31:0]  i_r0_data, // Ra | PC
 input  wire    [31:0]  i_r1_data, // Rb | Offset
 input  wire    [31:0]  i_r2_data, // Rc | Ac
 input  wire    [31:0]  i_r3_data, // -- | Bc
 
 // destination address
 
 input  wire     [1:0]  i_ry_ena,
 input  wire     [4:0]  i_ry_addr,
 input  wire     [1:0]  i_ry_tag,
 
 // conditiona code
 
 input  wire            fci_inst_jpf,
 input  wire            fci_inst_rep,                                   
 input  wire            fci_inst_skip,                                  

 output wire            fco_inst_lsf,
 output wire    [31:0]  fco_inst_lva,
 output wire    [15:0]  fco_inst_lsw,
 
 // ringbus
 
 input  wire            ep_i_stb,
 input  wire            ep_i_sof,
 input  wire    [ 3:0]  ep_i_iid,
 input  wire    [71:0]  ep_i_data,
 
 output wire            ep_o_br,
 input  wire            ep_o_bg,

 output wire            ep_o_stb,
 output wire            ep_o_sof,
 output wire     [3:0]  ep_o_iid,
 output wire    [71:0]  ep_o_data, 
 input  wire     [1:0]  ep_o_rdy,
 input  wire     [1:0]  ep_o_rdyE,

 // write back from cache
 
 output wire            wb_stb0,    
 output wire            wb_stb1,    
                                
 output wire     [1:0]  wb_enaA,             
 output wire     [3:0]  wb_benA,
 output wire            wb_tagA,             
                                             
 output wire     [1:0]  wb_enaB,             
 output wire     [3:0]  wb_benB,
 output wire            wb_tagB,             
 output wire            wb_modB,             
                                            
 output wire     [4:0]  wb_addr,            
 output wire    [31:0]  wb_dataL,
 output wire    [31:0]  wb_dataH
);                          
//==============================================================================================
// parameters
//==============================================================================================
parameter           CORE_DCACHE_SIZE    =                                                 "8KB";
//----------------------------------------------------------------------------------------------
localparam          PAGE_ADDR_WIDTH     =   (CORE_DCACHE_SIZE ==  "8KB") ?                  'd5: // 2K  * 2 ways * 2 threads
                                            (CORE_DCACHE_SIZE == "16KB") ?                  'd6: // 4K  * 2 ways * 2 threads
                                            (CORE_DCACHE_SIZE == "32KB") ?                  'd7: // 8K  * 2 ways * 2 threads
                                            (CORE_DCACHE_SIZE == "64KB") ?                  'd8: // 16K * 2 ways * 2 threads
                                                                                            'd4;
parameter           FORCE_RST           =     0;
//----------------------------------------------------------------------------------------------
localparam          _PAW                =                                       PAGE_ADDR_WIDTH;
//=============================================================================================
// parameters check
//=============================================================================================   
// pragma translate_off
initial
    begin                                                                                     
        if((CORE_DCACHE_SIZE != "8KB") && (CORE_DCACHE_SIZE != "16KB") && (CORE_DCACHE_SIZE != "32KB") && (CORE_DCACHE_SIZE != "64KB")) 
            begin
            $display( "!!!ERROR!!! CORE_DCACHE_SIZE = %s, is out of range (\"8KB\" \"16KB\" \"32KB\" \"64KB\")", CORE_DCACHE_SIZE ); 
            $finish;
            end    
    end
// pragma translate_on 
//==============================================================================================
// variables
//==============================================================================================
(* shreg_extract = "NO"  *) reg             a0_stb;
(* shreg_extract = "NO"  *) reg             a0_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  a0_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  a0_isw;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_isz;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_iva;

(* shreg_extract = "NO"  *) reg             a0_st;
(* shreg_extract = "NO"  *) reg             a0_ld;
(* shreg_extract = "NO"  *) reg             a0_fc;
(* shreg_extract = "NO"  *) reg             a0_hi;
(* shreg_extract = "NO"  *) reg             a0_sign;
(* shreg_extract = "NO"  *) reg             a0_twin;
(* shreg_extract = "NO"  *) reg             a0_pbr;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_size;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_ben_sel;

(* shreg_extract = "NO"  *) reg             a0_k_ena;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_k_sel;
(* shreg_extract = "NO"  *) reg      [3:0]  a0_k_dir;
(* shreg_extract = "NO"  *) reg             a0_k_force;

(* shreg_extract = "NO"  *) reg     [63:0]  a0_data;    
(* shreg_extract = "NO"  *) reg      [2:0]  a0_data_rot;

(* shreg_extract = "NO"  *) reg     [31:0]  a0_v_addr;  
(* shreg_extract = "NO"  *) reg     [31:0]  a0_k_addr;  

(* shreg_extract = "NO"  *) reg      [1:0]  a0_ry_ena;
(* shreg_extract = "NO"  *) reg      [4:0]  a0_ry_addr;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_ry_tag;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b1_stb;
(* shreg_extract = "NO"  *) reg             b1_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  b1_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  b1_isw;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_isz;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_iva;

(* shreg_extract = "NO"  *) reg             b1_st;  
(* shreg_extract = "NO"  *) reg             b1_ld;  
(* shreg_extract = "NO"  *) reg             b1_fc;
(* shreg_extract = "NO"  *) reg             b1_sign;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_size;
(* shreg_extract = "NO"  *) reg             b1_twin;
(* shreg_extract = "NO"  *) reg             b1_pbr;
(* shreg_extract = "NO"  *) reg             b1_hi;
(* shreg_extract = "NO"  *) reg             b1_lsh;

(* shreg_extract = "NO"  *) reg             b1_k_ena;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_k_sel;
(* shreg_extract = "NO"  *) reg      [3:0]  b1_k_dir;
(* shreg_extract = "NO"  *) reg             b1_k_dte;
(* shreg_extract = "NO"  *) reg             b1_k_force;

(* shreg_extract = "NO"  *) reg      [7:0]  b1_ben;     
(* shreg_extract = "NO"  *) reg      [7:0]  b1_adc;
(* shreg_extract = "NO"  *) reg      [7:0]  b1_mask;
(* shreg_extract = "NO"  *) reg     [63:0]  b1_data;  

(* shreg_extract = "NO"  *) reg     [31:0]  b1_v_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_k_addr;

(* shreg_extract = "NO"  *) reg      [1:0]  b1_ry_ena;
(* shreg_extract = "NO"  *) reg      [4:0]  b1_ry_addr;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_ry_tag;

(* shreg_extract = "NO"  *) wire    [31:0]  b1_p_addr [1:0];
(* shreg_extract = "NO"  *) wire     [1:0]  b1_hit;
(* shreg_extract = "NO"  *) wire     [1:0]  b1_miss;
(* shreg_extract = "NO"  *) wire     [1:0]  b1_locked;
(* shreg_extract = "NO"  *) wire     [1:0]  b1_empty;
(* shreg_extract = "NO"  *) wire     [1:0]  b1_wrt;
(* shreg_extract = "NO"  *) wire     [1:0]  b1_tag;
(* shreg_extract = "NO"  *) wire     [1:0]  b1_exc;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             a2_stb;
(* shreg_extract = "NO"  *) reg             a2_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  a2_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  a2_isw;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_isz;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_iva;

(* shreg_extract = "NO"  *) reg      [1:0]  a2_ry_ena;
(* shreg_extract = "NO"  *) reg      [3:0]  a2_ry_benA;
(* shreg_extract = "NO"  *) reg      [3:0]  a2_ry_benB;
(* shreg_extract = "NO"  *) reg      [4:0]  a2_ry_addr;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_ry_tag;

(* shreg_extract = "NO"  *) reg             a2_ld;
(* shreg_extract = "NO"  *) reg             a2_st;
(* shreg_extract = "NO"  *) reg             a2_sign;
(* shreg_extract = "NO"  *) reg             a2_twin;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_size;         

(* shreg_extract = "NO"  *) reg     [31:0]  a2_v_addr;

(* shreg_extract = "NO"  *) reg             a2_cr_stb;
(* shreg_extract = "NO"  *) reg             a2_cr_rep;
(* shreg_extract = "NO"  *) reg      [4:0]  a2_cr_state;
(* shreg_extract = "NO"  *) reg             a2_cr_wr;
(* shreg_extract = "NO"  *) reg             a2_cr_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  a2_cr_asid;
(* shreg_extract = "NO"  *) reg             a2_cr_tag;
(* shreg_extract = "NO"  *) reg             a2_cr_wid;
(* shreg_extract = "NO"  *) reg             a2_cr_k_ena;
(* shreg_extract = "NO"  *) reg             a2_cr_k_force;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_cr_kop;
(* shreg_extract = "NO"  *) reg             a2_cr_ksh;
(* shreg_extract = "NO"  *) reg      [3:0]  a2_cr_k_dir;
(* shreg_extract = "NO"  *) reg             a2_cr_empty;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_cr_r_addr;     
(* shreg_extract = "NO"  *) reg     [31:0]  a2_cr_p_addr;     
(* shreg_extract = "NO"  *) reg     [31:0]  a2_cr_k_addr;     

(* shreg_extract = "NO"  *) reg             a2_cancel;
(* shreg_extract = "NO"  *) reg             a2_pass;
(* shreg_extract = "NO"  *) reg             a2_lsh;

(* shreg_extract = "NO"  *) reg             a2_c_ena;
(* shreg_extract = "NO"  *) reg             a2_c_wen;
(* shreg_extract = "NO"  *) reg             a2_c_tid;
(* shreg_extract = "NO"  *) reg             a2_c_wid;
(* shreg_extract = "NO"  *) reg [_PAW-1:0]  a2_c_page;  
   
(* shreg_extract = "NO"  *) reg             a2_c_b0_wen;
(* shreg_extract = "NO"  *) reg      [2:0]  a2_c_b0_addr;   
(* shreg_extract = "NO"  *) reg      [7:0]  a2_c_b0_data;   

(* shreg_extract = "NO"  *) reg             a2_c_b1_wen;        
(* shreg_extract = "NO"  *) reg      [2:0]  a2_c_b1_addr;   
(* shreg_extract = "NO"  *) reg      [7:0]  a2_c_b1_data;   

(* shreg_extract = "NO"  *) reg             a2_c_b2_wen;        
(* shreg_extract = "NO"  *) reg      [2:0]  a2_c_b2_addr;   
(* shreg_extract = "NO"  *) reg      [7:0]  a2_c_b2_data;   

(* shreg_extract = "NO"  *) reg             a2_c_b3_wen;        
(* shreg_extract = "NO"  *) reg      [2:0]  a2_c_b3_addr;   
(* shreg_extract = "NO"  *) reg      [7:0]  a2_c_b3_data;   

(* shreg_extract = "NO"  *) reg             a2_c_b4_wen;        
(* shreg_extract = "NO"  *) reg      [2:0]  a2_c_b4_addr;   
(* shreg_extract = "NO"  *) reg      [7:0]  a2_c_b4_data;   

(* shreg_extract = "NO"  *) reg             a2_c_b5_wen;        
(* shreg_extract = "NO"  *) reg      [2:0]  a2_c_b5_addr;   
(* shreg_extract = "NO"  *) reg      [7:0]  a2_c_b5_data;   

(* shreg_extract = "NO"  *) reg             a2_c_b6_wen;        
(* shreg_extract = "NO"  *) reg      [2:0]  a2_c_b6_addr;   
(* shreg_extract = "NO"  *) reg      [7:0]  a2_c_b6_data;   

(* shreg_extract = "NO"  *) reg             a2_c_b7_wen;        
(* shreg_extract = "NO"  *) reg      [2:0]  a2_c_b7_addr;   
(* shreg_extract = "NO"  *) reg      [7:0]  a2_c_b7_data;   
//---------------------------------------------------------------------------------------------- 
(* shreg_extract = "NO"  *) reg             b3_cr_req;
(* shreg_extract = "NO"  *) reg             b3_cr_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  b3_cr_asid;
(* shreg_extract = "NO"  *) reg             b3_cr_wid;
(* shreg_extract = "NO"  *) reg             b3_cr_tag;
(* shreg_extract = "NO"  *) reg      [1:0]  b3_cr_kop;
(* shreg_extract = "NO"  *) reg             b3_cr_k_ena;
(* shreg_extract = "NO"  *) reg             b3_cr_k_force;
(* shreg_extract = "NO"  *) reg             b3_cr_ksh;
(* shreg_extract = "NO"  *) reg      [8:0]  b3_cr_mode;     
(* shreg_extract = "NO"  *) reg      [6:0]  b3_cr_page;     
(* shreg_extract = "NO"  *) reg     [31:0]  b3_cr_r_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_cr_p_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_cr_k_addr;
(* shreg_extract = "NO"  *) wire            b3_cr_pwf;
//---------------------------------------------------------------------------------------------- 
(* shreg_extract = "NO"  *) reg             b3_stb;
(* shreg_extract = "NO"  *) reg             b3_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  b3_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  b3_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  b3_isw;
(* shreg_extract = "NO"  *) reg      [1:0]  b3_isz;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_iva;

(* shreg_extract = "NO"  *) reg      [1:0]  b3_ry_ena;
(* shreg_extract = "NO"  *) reg      [3:0]  b3_ry_benA;
(* shreg_extract = "NO"  *) reg      [3:0]  b3_ry_benB;
(* shreg_extract = "NO"  *) reg      [4:0]  b3_ry_addr;
(* shreg_extract = "NO"  *) reg      [1:0]  b3_ry_tag;
(* shreg_extract = "NO"  *) reg             b3_ry_abort;

(* shreg_extract = "NO"  *) reg             b3_st;
(* shreg_extract = "NO"  *) reg             b3_ld;
(* shreg_extract = "NO"  *) reg             b3_sign;
(* shreg_extract = "NO"  *) reg      [1:0]  b3_size;         
(* shreg_extract = "NO"  *) reg             b3_twin;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_v_addr;
                            wire    [63:0]  b3_data;
//---------------------------------------------------------------------------------------------- 
(* shreg_extract = "NO"  *) reg             a4_stb;
(* shreg_extract = "NO"  *) reg             a4_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  a4_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  a4_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  a4_isw;
(* shreg_extract = "NO"  *) reg      [1:0]  a4_isz;
(* shreg_extract = "NO"  *) reg     [31:0]  a4_iva;

(* shreg_extract = "NO"  *) reg      [1:0]  a4_ry_ena;
(* shreg_extract = "NO"  *) reg      [3:0]  a4_ry_benA;
(* shreg_extract = "NO"  *) reg      [3:0]  a4_ry_benB;
(* shreg_extract = "NO"  *) reg      [4:0]  a4_ry_addr;
(* shreg_extract = "NO"  *) reg      [1:0]  a4_ry_tag;
(* shreg_extract = "NO"  *) reg             a4_ry_abort;

(* shreg_extract = "NO"  *) reg      [2:0]  a4_ry_Lo_mxd;
(* shreg_extract = "NO"  *) reg      [2:0]  a4_ry_Lo_mxs;
(* shreg_extract = "NO"  *) reg      [2:0]  a4_ry_Lo_mxm;

(* shreg_extract = "NO"  *) reg      [2:0]  a4_ry_Hi_mxd;
(* shreg_extract = "NO"  *) reg      [2:0]  a4_ry_Hi_mxs;
(* shreg_extract = "NO"  *) reg      [2:0]  a4_ry_Hi_mxm;

(* shreg_extract = "NO"  *) reg             a4_st;
(* shreg_extract = "NO"  *) reg             a4_ld;
(* shreg_extract = "NO"  *) reg             a4_sign;
(* shreg_extract = "NO"  *) reg      [1:0]  a4_size;         
(* shreg_extract = "NO"  *) reg     [31:0]  a4_v_addr;

(* shreg_extract = "NO"  *) reg     [63:0]  a4_data64;
//---------------------------------------------------------------------------------------------- 
(* shreg_extract = "NO"  *) reg             b5_stb;
(* shreg_extract = "NO"  *) reg             b5_tid;
(* shreg_extract = "NO"  *) reg      [3:0]  b5_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  b5_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  b5_isw;

(* shreg_extract = "NO"  *) reg             b5_ry_stb0;
(* shreg_extract = "NO"  *) reg             b5_ry_stb1;

(* shreg_extract = "NO"  *) reg      [1:0]  b5_ry_enaA;
(* shreg_extract = "NO"  *) reg      [3:0]  b5_ry_benA;
(* shreg_extract = "NO"  *) reg             b5_ry_tagA;

(* shreg_extract = "NO"  *) reg      [1:0]  b5_ry_enaB;
(* shreg_extract = "NO"  *) reg      [3:0]  b5_ry_benB;
(* shreg_extract = "NO"  *) reg             b5_ry_modB;
(* shreg_extract = "NO"  *) reg             b5_ry_tagB;

(* shreg_extract = "NO"  *) reg      [4:0]  b5_ry_addr;

(* shreg_extract = "NO"  *) reg     [31:0]  b5_ry_Lo_d;
(* shreg_extract = "NO"  *) reg             b5_ry_Lo_s;
(* shreg_extract = "NO"  *) reg     [31:0]  b5_ry_Lo;

(* shreg_extract = "NO"  *) reg     [31:0]  b5_ry_Hi_d;
(* shreg_extract = "NO"  *) reg             b5_ry_Hi_s;
(* shreg_extract = "NO"  *) reg     [31:0]  b5_ry_Hi;           
//---------------------------------------------------------------------------------------------- 
wire            cache_pt_w_stb;  
wire            cache_pt_w_tid;  
wire            cache_pt_w_wid;  
wire [_PAW-1:0] cache_pt_w_page; 
wire     [38:0] cache_pt_w_data; 
                              
wire            cache_pf_w_clr;  
wire            cache_pf_w_wen;  
wire            cache_pf_w_tid;  
wire            cache_pf_w_wid;  
wire [_PAW-1:0] cache_pf_w_page; 

wire            cache_mm_w_stb;  
wire            cache_mm_w_wen;  
wire            cache_mm_w_tid;  
wire            cache_mm_w_wid;  
wire [_PAW-1:0] cache_mm_w_page; 
wire      [2:0] cache_mm_w_offset;
wire     [63:0] cache_mm_w_data;
                              
wire            cache_mm_r_stb;  
wire      [7:0] cache_mm_r_ben;  
wire     [63:0] cache_mm_r_data; 
//==============================================================================================
// address generator
//==============================================================================================              
wire    [31:0]  f_v_addr        =                                         i_r0_data + i_r2_data;
wire    [31:0]  f_x_addr        =                                   f_v_addr + {i_isw[12],6'd0};              
//==============================================================================================
// stage (a)0
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a0_stb                  <=                                                             1'b0;
    a0_tid                  <=                                                             1'b0;
    a0_asid                 <=                                                             4'b0;
    a0_pid                  <=                                                             2'b0;
    a0_isw                  <=                                                            16'b0;        
    a0_isz                  <=                                                             2'b0;
    a0_iva                  <=                                                            32'b0;        

    a0_st                   <=                                                             1'b0;
    a0_ld                   <=                                                             1'b0;
    a0_fc                   <=                                                             1'b0;
    a0_hi                   <=                                                             1'b0;
    a0_sign                 <=                                                             1'b0;
    a0_size                 <=                                                             2'd0;
    a0_twin                 <=                                                             1'b0;
    a0_pbr                  <=                                                             1'b0;
    a0_ben_sel              <=                                                             2'b0;
    a0_k_ena                <=                                                             1'b0;
    a0_k_sel                <=                                                             2'b0;
    a0_k_dir                <=                                                             4'b0;
    a0_k_force              <=                                                              'd0;
    
    a0_ry_ena               <=                                                             2'd0;
    a0_ry_addr              <=                                                             5'd0;
    a0_ry_tag               <=                                                             2'd0;                         
    
    a0_v_addr               <=                                                            32'd0;
    a0_k_addr               <=                                                            32'd0;
    a0_data                 <=                                                            32'd0;
  end
 else
  begin                                                 
    a0_stb                  <=                             !fci_inst_jpf && i_ls_cw[0] && i_stb;                       
    a0_tid                  <=                                                            i_tid;                                       
    a0_asid                 <=                                                           i_asid;
    a0_pid                  <=                                                            i_pid;
    a0_isw                  <=                                                            i_isw;        
    a0_isz                  <=                                                            i_isz;        
    a0_iva                  <=                                                            i_iva;        
      
    casex({i_ls_cw[5],i_ls_cw[2:1]})   
    3'b0_xx: a0_data        <=                              {i_r3_data[31: 0],i_r1_data[31: 0]}; // Rc (Ac or Bc)
                                                                  // B               AorB
    3'b1_00: a0_data        <=                              {i_r3_data[ 7: 0],i_r1_data[ 7: 0]}; // byte  - Bc:Ac
    3'b1_01: a0_data        <=                              {i_r3_data[15: 0],i_r1_data[15: 0]}; // half  - Bc:Ac
    3'b1_10: a0_data        <=                              {i_r3_data[31: 0],i_r1_data[31: 0]}; // word  - Bc:Ac
    3'b1_11: a0_data        <=                              {i_r3_data[31: 0],i_r1_data[31: 0]}; // dword - Bc:Ac
    endcase

    a0_st                   <=                      (!i_ls_cw[11] &&  i_ls_cw[3]) && i_ls_cw[0];
    a0_ld                   <=                      (!i_ls_cw[11] && !i_ls_cw[3]) && i_ls_cw[0];
    
    a0_fc                   <=                                                      i_ls_cw[11];
    a0_hi                   <=                                                        i_isw[12];
    a0_sign                 <=                                                       i_ls_cw[4];
    a0_size                 <=                                                     i_ls_cw[2:1];
    a0_twin                 <=                                                       i_ls_cw[5];
    a0_pbr                  <=                                                   &f_x_addr[5:3];
    a0_ben_sel              <=                                        i_ls_cw[2:1] + i_ls_cw[5];

    a0_k_ena                <=                                       i_ls_cw[11] && i_ls_cw[10];
    a0_k_sel                <=                                                   i_ls_cw[13:12];
    a0_k_dir                <=                                                     i_ls_cw[9:6];
    a0_k_force              <=                                                              'd0;
    
    a0_v_addr               <=                                                         f_x_addr;  
    a0_k_addr               <=                                                        i_r3_data;  
       
    case({i_ls_cw[5],i_ls_cw[2:1],f_x_addr[2:0]})   
    // single byte
    6'b0_00_000: a0_data_rot <=                                                            3'd7;
    6'b0_00_001: a0_data_rot <=                                                            3'd6;
    6'b0_00_010: a0_data_rot <=                                                            3'd5;
    6'b0_00_011: a0_data_rot <=                                                            3'd4;
    6'b0_00_100: a0_data_rot <=                                                            3'd3;
    6'b0_00_101: a0_data_rot <=                                                            3'd2;
    6'b0_00_110: a0_data_rot <=                                                            3'd1;
    6'b0_00_111: a0_data_rot <=                                                            3'd0;
    // single short
    6'b0_01_000: a0_data_rot <=                                                            3'd6;
    6'b0_01_001: a0_data_rot <=                                                            3'd5;
    6'b0_01_010: a0_data_rot <=                                                            3'd4;
    6'b0_01_011: a0_data_rot <=                                                            3'd3;
    6'b0_01_100: a0_data_rot <=                                                            3'd2;
    6'b0_01_101: a0_data_rot <=                                                            3'd1;
    6'b0_01_110: a0_data_rot <=                                                            3'd0;
    6'b0_01_111: a0_data_rot <=                                                            3'd7;
    // single word/float
    6'b0_10_000: a0_data_rot <=                                                            3'd4;
    6'b0_10_001: a0_data_rot <=                                                            3'd3;
    6'b0_10_010: a0_data_rot <=                                                            3'd2;
    6'b0_10_011: a0_data_rot <=                                                            3'd1;
    6'b0_10_100: a0_data_rot <=                                                            3'd0;
    6'b0_10_101: a0_data_rot <=                                                            3'd7;
    6'b0_10_110: a0_data_rot <=                                                            3'd6;
    6'b0_10_111: a0_data_rot <=                                                            3'd5;

    // twin bytes
    6'b1_00_000: a0_data_rot <=                                                            3'd6;
    6'b1_00_001: a0_data_rot <=                                                            3'd5;
    6'b1_00_010: a0_data_rot <=                                                            3'd4;
    6'b1_00_011: a0_data_rot <=                                                            3'd3;
    6'b1_00_100: a0_data_rot <=                                                            3'd2;
    6'b1_00_101: a0_data_rot <=                                                            3'd1;
    6'b1_00_110: a0_data_rot <=                                                            3'd0;
    6'b1_00_111: a0_data_rot <=                                                            3'd7;
    // twin shorts
    6'b1_01_000: a0_data_rot <=                                                            3'd4;
    6'b1_01_001: a0_data_rot <=                                                            3'd3;
    6'b1_01_010: a0_data_rot <=                                                            3'd2;
    6'b1_01_011: a0_data_rot <=                                                            3'd1;
    6'b1_01_100: a0_data_rot <=                                                            3'd0;
    6'b1_01_101: a0_data_rot <=                                                            3'd7;
    6'b1_01_110: a0_data_rot <=                                                            3'd6;
    6'b1_01_111: a0_data_rot <=                                                            3'd5;
    // twin words/floats
    6'b1_10_000: a0_data_rot <=                                                            3'd0;
    6'b1_10_001: a0_data_rot <=                                                            3'd7;
    6'b1_10_010: a0_data_rot <=                                                            3'd6;
    6'b1_10_011: a0_data_rot <=                                                            3'd5;
    6'b1_10_100: a0_data_rot <=                                                            3'd4;
    6'b1_10_101: a0_data_rot <=                                                            2'd3;
    6'b1_10_110: a0_data_rot <=                                                            3'd2;
    6'b1_10_111: a0_data_rot <=                                                            3'd1;
    endcase
       
// .... product Ry path ........................................................................
       
    a0_ry_ena               <=                                                         i_ry_ena;
    a0_ry_addr              <=                                                        i_ry_addr;
    a0_ry_tag               <=                                                         i_ry_tag;
    
// .............................................................................................
  end
//==============================================================================================
// data cache page tables
//==============================================================================================
generate     
    genvar w;                                       

    for (w=0; w<2; w = w + 1)
        begin : dc_way 
`ifdef ALTERA
            (*  syn_ramstyle="no_rw_check,MLAB"  *) eco32_core_lsu_dcu_way
`else
            (*  syn_ramstyle="select_ram,no_rw_check"  *) eco32_core_lsu_dcu_way
`endif
            #
            (
            .PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)
            )
            dcw_box 
            (
            .clk                (clk),
            .rst                (rst),
            
            .i_stb              (i_stb && i_ls_cw[0]),
            .i_tid              (i_tid),
            .i_pid              (i_pid),
            .i_asid             (i_asid),
            .i_v_addr           (f_x_addr),
            
            .wr_pt_stb          (cache_pt_w_stb && cache_pt_w_wid == w),
            .wr_pt_tid          (cache_pt_w_tid),
            .wr_pt_page         (cache_pt_w_page),
            .wr_pt_descriptor   (cache_pt_w_data),
            
            .o_v_addr           (b1_p_addr[w]),
            .o_hit              (b1_hit[w]),
            .o_miss             (b1_miss[w]),
            .o_locked           (b1_locked[w]),
            .o_empty            (b1_empty[w]), 
            .o_wrt              (b1_wrt[w]),
            .o_tag              (b1_tag[w]),  
            
            .o_exc              (b1_exc[w]),
            .o_exc_ida          (),
            .o_exc_idp          (),
            .o_exc_idt          ()
            );      
        end 
endgenerate           
//==============================================================================================
// stage (b)1
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b1_stb                  <=                                                             1'b0;
    b1_tid                  <=                                                             1'b0;
    b1_asid                 <=                                                             4'b0;
    b1_pid                  <=                                                             2'b0;
    b1_isw                  <=                                                            16'b0;        
    b1_isz                  <=                                                             2'b0;        
    b1_iva                  <=                                                            32'b0;        

    b1_st                   <=                                                             1'b0;
    b1_ld                   <=                                                             1'b0;
    b1_fc                   <=                                                             1'b0;
    b1_sign                 <=                                                             1'b0;
    b1_size                 <=                                                             2'd0;
    b1_twin                 <=                                                             1'b0;
    b1_pbr                  <=                                                             1'b0;
    b1_hi                   <=                                                             1'b0;
    b1_lsh                  <=                                                             1'b0;
    
    b1_k_ena                <=                                                             1'b0;
    b1_k_sel                <=                                                             2'b0;
    b1_k_dir                <=                                                             4'b0;
    b1_k_dte                <=                                                             1'b0;
    b1_k_force              <=                                                              'd0;
    
    b1_v_addr               <=                                                            32'd0;
    b1_k_addr               <=                                                            32'd0;
    
    b1_ben                  <=                                                             8'h0;    
    b1_adc                  <=                                                             8'h0;    
    b1_mask                 <=                                                             8'h0;    
    b1_data                 <=                                                            64'h0;    
    
    b1_ry_ena               <=                                                             2'd0;
    b1_ry_addr              <=                                                             5'd0;
    b1_ry_tag               <=                                                             2'd0;
  end
 else
  begin  
    b1_stb                  <=          !a2_cr_rep && !fci_inst_rep && !fci_inst_skip && a0_stb;
    b1_tid                  <=                                                           a0_tid;
    b1_asid                 <=                                                          a0_asid;
    b1_pid                  <=                                                           a0_pid;
    b1_isw                  <=                                                           a0_isw;        
    b1_isz                  <=                                                           a0_isz;        
    b1_iva                  <=                                                           a0_iva;        

    b1_v_addr               <=                                                        a0_v_addr;
    b1_k_addr               <=                                                        a0_k_addr;

    casex(a0_data_rot)                          
    3'd0:   b1_data         <=                                 {                a0_data[63: 0]};
    3'd1:   b1_data         <=                                 {a0_data[55: 0], a0_data[63:56]};
    3'd2:   b1_data         <=                                 {a0_data[47: 0], a0_data[63:48]};
    3'd3:   b1_data         <=                                 {a0_data[39: 0], a0_data[63:40]};
    3'd4:   b1_data         <=                                 {a0_data[31: 0], a0_data[63:32]};
    3'd5:   b1_data         <=                                 {a0_data[23: 0], a0_data[63:24]};
    3'd6:   b1_data         <=                                 {a0_data[15: 0], a0_data[63:16]};
    3'd7:   b1_data         <=                                 {a0_data[ 7: 0], a0_data[63: 8]};
    endcase     
    
    case({a0_ben_sel,a0_v_addr[2:0]})   
    5'b00_000:  b1_adc      <=                                                     8'b0000_0000; // {byte}
    5'b00_001:  b1_adc      <=                                                     8'b0000_0000;
    5'b00_010:  b1_adc      <=                                                     8'b0000_0000;
    5'b00_011:  b1_adc      <=                                                     8'b0000_0000;    
    5'b00_100:  b1_adc      <=                                                     8'b0000_0000; 
    5'b00_101:  b1_adc      <=                                                     8'b0000_0000;
    5'b00_110:  b1_adc      <=                                                     8'b0000_0000;
    5'b00_111:  b1_adc      <=                                                     8'b0000_0000;    
    
    5'b01_000:  b1_adc      <=                                                     8'b0000_0000; // {short | byte:byte}
    5'b01_001:  b1_adc      <=                                                     8'b0000_0000;
    5'b01_010:  b1_adc      <=                                                     8'b0000_0000;
    5'b01_011:  b1_adc      <=                                                     8'b0000_0000;    
    5'b01_100:  b1_adc      <=                                                     8'b0000_0000; 
    5'b01_101:  b1_adc      <=                                                     8'b0000_0000;
    5'b01_110:  b1_adc      <=                                                     8'b0000_0000;
    5'b01_111:  b1_adc      <=                                                     8'b1000_0000;    
    
    5'b10_000:  b1_adc      <=                                                     8'b0000_0000; // {word | short:short}
    5'b10_001:  b1_adc      <=                                                     8'b0000_0000;
    5'b10_010:  b1_adc      <=                                                     8'b0000_0000;
    5'b10_011:  b1_adc      <=                                                     8'b0000_0000;    
    5'b10_100:  b1_adc      <=                                                     8'b0000_0000; 
    5'b10_101:  b1_adc      <=                                                     8'b1000_0000;
    5'b10_110:  b1_adc      <=                                                     8'b1100_0000;
    5'b10_111:  b1_adc      <=                                                     8'b1110_0000;    
            
    5'b11_000:  b1_adc      <=                                                     8'b0000_0000; // {word:word}
    5'b11_001:  b1_adc      <=                                                     8'b1000_0000;
    5'b11_010:  b1_adc      <=                                                     8'b1100_0000;
    5'b11_011:  b1_adc      <=                                                     8'b1110_0000;    
    5'b11_100:  b1_adc      <=                                                     8'b1111_0000; 
    5'b11_101:  b1_adc      <=                                                     8'b1111_1000;
    5'b11_110:  b1_adc      <=                                                     8'b1111_1100;
    5'b11_111:  b1_adc      <=                                                     8'b1111_1110;    
    endcase                                                                                  
    
    case({a0_hi,a0_pbr,a0_twin,a0_size,a0_v_addr[2:0]})   
    // page break   
    8'b0_1_0_00_xxx: b1_pbr  <=                                                            1'b0; // byte
    
    8'b0_1_0_01_000: b1_pbr  <=                                                            1'b0; // short
    8'b0_1_0_01_001: b1_pbr  <=                                                            1'b0;
    8'b0_1_0_01_010: b1_pbr  <=                                                            1'b0;
    8'b0_1_0_01_011: b1_pbr  <=                                                            1'b0;    
    8'b0_1_0_01_100: b1_pbr  <=                                                            1'b0;  
    8'b0_1_0_01_101: b1_pbr  <=                                                            1'b0;
    8'b0_1_0_01_110: b1_pbr  <=                                                            1'b0;
    8'b0_1_0_01_111: b1_pbr  <=                                                            1'b1;    
    
    8'b0_1_0_10_000: b1_pbr  <=                                                            1'b0; // word
    8'b0_1_0_10_001: b1_pbr  <=                                                            1'b0;
    8'b0_1_0_10_010: b1_pbr  <=                                                            1'b0;
    8'b0_1_0_10_011: b1_pbr  <=                                                            1'b0;    
    8'b0_1_0_10_100: b1_pbr  <=                                                            1'b0;         
    8'b0_1_0_10_101: b1_pbr  <=                                                            1'b1;
    8'b0_1_0_10_110: b1_pbr  <=                                                            1'b1;
    8'b0_1_0_10_111: b1_pbr  <=                                                            1'b1;    
    
    // twin
    // page break   
    8'b0_1_1_00_000: b1_pbr  <=                                                            1'b0; // byte
    8'b0_1_1_00_001: b1_pbr  <=                                                            1'b0;
    8'b0_1_1_00_010: b1_pbr  <=                                                            1'b0;
    8'b0_1_1_00_011: b1_pbr  <=                                                            1'b0;
    8'b0_1_1_00_100: b1_pbr  <=                                                            1'b0; 
    8'b0_1_1_00_101: b1_pbr  <=                                                            1'b0;
    8'b0_1_1_00_110: b1_pbr  <=                                                            1'b0;
    8'b0_1_1_00_111: b1_pbr  <=                                                            1'b1;
    
    8'b0_1_1_01_000: b1_pbr  <=                                                            1'b0; // short
    8'b0_1_1_01_001: b1_pbr  <=                                                            1'b0;
    8'b0_1_1_01_010: b1_pbr  <=                                                            1'b0;
    8'b0_1_1_01_011: b1_pbr  <=                                                            1'b0;    
    8'b0_1_1_01_100: b1_pbr  <=                                                            1'b0;  
    8'b0_1_1_01_101: b1_pbr  <=                                                            1'b1;
    8'b0_1_1_01_110: b1_pbr  <=                                                            1'b1;
    8'b0_1_1_01_111: b1_pbr  <=                                                            1'b1;    
    
    8'b0_1_1_10_000: b1_pbr  <=                                                            1'b0; // word
    8'b0_1_1_10_001: b1_pbr  <=                                                            1'b1;
    8'b0_1_1_10_010: b1_pbr  <=                                                            1'b1;
    8'b0_1_1_10_011: b1_pbr  <=                                                            1'b1;    
    8'b0_1_1_10_100: b1_pbr  <=                                                            1'b1;  
    8'b0_1_1_10_101: b1_pbr  <=                                                            1'b1;
    8'b0_1_1_10_110: b1_pbr  <=                                                            1'b1;
    8'b0_1_1_10_111: b1_pbr  <=                                                            1'b1;    
    
    default:         b1_pbr  <=                                                            1'b0;    
    endcase                                                                                   
    
    
    if(!a2_cr_rep && !fci_inst_rep && !fci_inst_skip && a0_stb)
        begin
            b1_st           <=                                                            a0_st;
            b1_ld           <=                                                            a0_ld;
            b1_fc           <=                                                            a0_fc;
            b1_sign         <=                                                          a0_sign;
            b1_size         <=                                                          a0_size;
            b1_hi           <=                                                            a0_hi;
            b1_twin         <=                                                          a0_twin;
            b1_lsh          <=                                                            a0_hi;

            b1_k_ena        <=                                                         a0_k_ena;
            b1_k_sel        <=                                                         a0_k_sel;
            b1_k_dir        <=                                                         a0_k_dir;  
            b1_k_dte        <=                                          a0_k_sel[1] && a0_k_ena;
            b1_k_force      <=                                                       a0_k_force;
    
            case({a0_st,a0_ben_sel,a0_v_addr[2:0]})   
            7'b1_00_000: b1_ben     <=                                             8'b1000_0000; // byte
            7'b1_00_001: b1_ben     <=                                             8'b0100_0000;
            7'b1_00_010: b1_ben     <=                                             8'b0010_0000;
            7'b1_00_011: b1_ben     <=                                             8'b0001_0000;
            7'b1_00_100: b1_ben     <=                                             8'b0000_1000;
            7'b1_00_101: b1_ben     <=                                             8'b0000_0100;
            7'b1_00_110: b1_ben     <=                                             8'b0000_0010;
            7'b1_00_111: b1_ben     <=                                             8'b0000_0001;
    
            7'b1_01_000: b1_ben     <=                                             8'b1100_0000; // short
            7'b1_01_001: b1_ben     <=                                             8'b0110_0000;                            
            7'b1_01_010: b1_ben     <=                                             8'b0011_0000;                            
            7'b1_01_011: b1_ben     <=                                             8'b0001_1000;    
            7'b1_01_100: b1_ben     <=                                             8'b0000_1100; 
            7'b1_01_101: b1_ben     <=                                             8'b0000_0110;
            7'b1_01_110: b1_ben     <=                                             8'b0000_0011;
            7'b1_01_111: b1_ben     <=                                             8'b1000_0001;    
    
            7'b1_10_000: b1_ben     <=                                             8'b1111_0000; // word
            7'b1_10_001: b1_ben     <=                                             8'b0111_1000;
            7'b1_10_010: b1_ben     <=                                             8'b0011_1100;
            7'b1_10_011: b1_ben     <=                                             8'b0001_1110;    
            7'b1_10_100: b1_ben     <=                                             8'b0000_1111;  
            7'b1_10_101: b1_ben     <=                                             8'b1000_0111;
            7'b1_10_110: b1_ben     <=                                             8'b1100_0011;
            7'b1_10_111: b1_ben     <=                                             8'b1110_0001;    
    
            7'b1_11_000: b1_ben     <=                                             8'b1111_1111; // dword
            7'b1_11_001: b1_ben     <=                                             8'b1111_1111;
            7'b1_11_010: b1_ben     <=                                             8'b1111_1111;
            7'b1_11_011: b1_ben     <=                                             8'b1111_1111;    
            7'b1_11_100: b1_ben     <=                                             8'b1111_1111; 
            7'b1_11_101: b1_ben     <=                                             8'b1111_1111;
            7'b1_11_110: b1_ben     <=                                             8'b1111_1111;
            7'b1_11_111: b1_ben     <=                                             8'b1111_1111;    
    
            default:     b1_ben     <=                                             8'b0000_0000;    
            endcase
    
            
            casex({a0_hi,a0_pbr,a0_v_addr[2:0]})   
            // page break 
            5'b0_1_000: b1_mask     <=                                             8'b1111_1111; 
            5'b0_1_001: b1_mask     <=                                             8'b0111_1111;
            5'b0_1_010: b1_mask     <=                                             8'b0011_1111;
            5'b0_1_011: b1_mask     <=                                             8'b0001_1111;
            5'b0_1_100: b1_mask     <=                                             8'b0000_1111; 
            5'b0_1_101: b1_mask     <=                                             8'b0000_0111;
            5'b0_1_110: b1_mask     <=                                             8'b0000_0011;
            5'b0_1_111: b1_mask     <=                                             8'b0000_0001;
            
            // ls high
            5'b1_x_000: b1_mask     <=                                             8'b0000_0000; 
            5'b1_x_001: b1_mask     <=                                             8'b1000_0000;
            5'b1_x_010: b1_mask     <=                                             8'b1100_0000;
            5'b1_x_011: b1_mask     <=                                             8'b1110_0000;
            5'b1_x_100: b1_mask     <=                                             8'b1111_0000; 
            5'b1_x_101: b1_mask     <=                                             8'b1111_1000;
            5'b1_x_110: b1_mask     <=                                             8'b1111_1100;
            5'b1_x_111: b1_mask     <=                                             8'b1111_1110;
            
            default:    b1_mask <=                                                 8'b1111_1111;    
            endcase                                                                                         
            
// .... product Ry path ........................................................................
               
            b1_ry_ena       <=                                                        a0_ry_ena;
            b1_ry_addr      <=                                                       a0_ry_addr;
            b1_ry_tag       <=                                                        a0_ry_tag;
    
// .............................................................................................

        end
    else
        begin
            b1_st           <=                                                              'd0;
            b1_ld           <=                                                              'd0;
            b1_fc           <=                                                              'd0;
            b1_sign         <=                                                              'd0;
            b1_size         <=                                                              'd0;
            b1_hi           <=                                                              'd0;
            b1_twin         <=                                                              'd0;
            b1_lsh          <=                                                              'd0;
                                                                                            
            b1_k_ena        <=                                                              'd0;
            b1_k_sel        <=                                                              'd0;
            b1_k_dir        <=                                                              'd0; 
            b1_k_dte        <=                                                              'd0; 
            b1_k_force      <=                                                              'd0;
            
            b1_ben          <=                                                              'd0;
            b1_mask         <=                                                              'd0;
            
// .... product Ry path ........................................................................

            b1_ry_ena       <=                                                            2'b00;
            b1_ry_addr      <=                                                       a0_ry_addr;
            b1_ry_tag       <=                                                        a0_ry_tag;            
                
// .............................................................................................

        end
  end                 
//==============================================================================================
// peripheral local bus
//==============================================================================================
wire            cache_miss      =                                     b1_miss[1] &   b1_miss[0];
wire            cache_exc       = b1_hit[1] ?                          b1_exc[1] :    b1_exc[0];
wire            cache_hit       =                                      b1_hit[1] |    b1_hit[0];
wire            cache_locked    =                                   b1_locked[1] | b1_locked[0];
wire            cache_cr_wid    =                                         b1_tag[1] ^ b1_tag[0];
//==============================================================================================
// stage (a)2
//==============================================================================================       
wire    [4:0]   f_cr_state      =                                                  b1_isw[11:7];
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a2_stb                  <=                                                              'd0;
    a2_tid                  <=                                                              'd0;
    a2_asid                 <=                                                              'd0;
    a2_pid                  <=                                                              'd0;
    a2_isw                  <=                                                              'd0;
    
    a2_st                   <=                                                              'd0;
    a2_ld                   <=                                                              'd0;
    a2_sign                 <=                                                              'd0;
    a2_size                 <=                                                              'd0;

    a2_v_addr               <=                                                              'd0;
    a2_cancel               <=                                                              'b0;
    a2_pass                 <=                                                              'b0;
    a2_lsh                  <=                                                              'b0;
    a2_twin                 <=                                                              'b0;

    a2_cr_stb               <=                                                              'b0;
    a2_cr_rep               <=                                                              'b0;
    a2_cr_state             <=                                                              'b0;
    a2_cr_empty             <=                                                              'b0;
    a2_cr_wr                <=                                                              'b0;
    a2_cr_tid               <=                                                              'b0;
    a2_cr_wid               <=                                                              'b0;
    a2_cr_tag               <=                                                              'b0;
    a2_cr_r_addr            <=                                                              'd0;
    a2_cr_p_addr            <=                                                              'd0;

    a2_cr_k_ena             <=                                                             2'b0;
    a2_cr_k_force           <=                                                             1'b0;
    a2_cr_kop               <=                                                             2'b0;
    a2_cr_ksh               <=                                                             1'b0;
    a2_cr_k_dir             <=                                                             4'b0;
    a2_cr_k_addr            <=                                                            32'd0;

    a2_ry_ena               <=                                                             2'd0;
    a2_ry_addr              <=                                                             5'd0;
    a2_ry_tag               <=                                                             2'd0;
  end        
 else  
  begin    
    a2_stb                  <=                                                           b1_stb;
    a2_tid                  <=                                                           b1_tid;
    a2_asid                 <=                                                          b1_asid;
    a2_pid                  <=                                                           b1_pid;
    a2_isw                  <=                                                           b1_isw;
    a2_isz                  <=                                                           b1_isz;
    a2_iva                  <=                                                           b1_iva;
    
    a2_st                   <=                                                            b1_st;
    a2_ld                   <=                                                            b1_ld;
    a2_sign                 <=                                                          b1_sign;
    a2_size                 <=                                                          b1_size;
    a2_twin                 <=                                                          b1_twin; 
    
    a2_v_addr               <=                                                        b1_v_addr;
    
    // cache request    
    
    a2_cr_asid              <=                                                          b1_asid;
    a2_cr_k_force           <=                                                       b1_k_force;

    casex({b1_stb,  f_cr_state, cache_miss,cache_exc,cache_locked,cache_hit})
        
    //********************** check for page state *********************************************
        
    10'b1_00000_0001: // PAGE_HIT
    begin
    a2_cr_state             <= b1_k_ena ?                                5'b01000 :    5'b00000;                
    a2_cr_rep               <= b1_k_ena ?                                    1'b1 :      b1_pbr;                
    a2_cr_stb               <= b1_k_ena ?                                    1'b1 :        1'b0; 
    a2_cr_k_ena             <= b1_k_ena ?                                    1'b1 :        1'b0;
    a2_pass                 <= b1_k_ena ?                                    1'b0 :        1'b1; 
    a2_cancel               <= b1_k_ena ?                                    1'b1 :        1'b0; 
    a2_lsh                  <=                                                 b1_pbr || b1_lsh;
    a2_cr_kop[0]            <= b1_k_ena ?                                b1_k_dte :        1'b0;
    a2_cr_kop[1]            <= b1_k_ena ?                                b1_k_dte :        1'b0;
    a2_cr_ksh               <= b1_k_ena ?                                 b1_twin :        1'b0;
    end
    
    10'b1_00000_001x: // PAGE_LOCKED
    begin
    a2_cr_state             <=                                                         5'b00001;
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b0;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end
    
    10'b1_00000_0101: // PAGE_HIT + PAGE_EXC
    begin
    a2_cr_state             <=                                                         5'b00000;
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b0;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end
    
    10'b1_00000_1xxx: // PAGE_MISS
    begin
    a2_cr_state             <=                                                         5'b00010;
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b1;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end
    
    //********************** wait for page unlock **********************************************
    
    10'b1_00001_xx1x: // PAGE_LOCKED
    begin
    a2_cr_state             <=                                                         5'b00001;
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b0; 
    a2_cr_k_ena             <=                                                             1'b0;                             
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end

    10'b1_00001_0001: // PAGE_HIT
    begin
     if(b1_k_ena ) // page/dword/barrier-operations 
        begin    
        a2_cr_state             <=                                                     5'b01000;
        a2_cr_rep               <=                                                         1'b1;
        a2_cr_stb               <=                                                         1'b1;
        a2_cr_k_ena             <=                                                         1'b1;
        a2_pass                 <=                                                         1'b0;
        a2_cancel               <=                                                         1'b1;
        a2_lsh                  <=                                                         1'b0;
        a2_cr_kop[0]            <=                                                     b1_k_dte;
        a2_cr_kop[1]            <=                                                     b1_k_dte;
        a2_cr_ksh               <=                                                      b1_twin;
        end                                                                                     
     else
        begin    
        a2_cr_state             <=                                                     5'b00000;
        a2_cr_rep               <=                                                       b1_pbr;
        a2_cr_stb               <=                                                         1'b0;
        a2_cr_k_ena             <=                                                         1'b0;
        a2_pass                 <=                                                         1'b1;
        a2_cancel               <=                                                         1'b0;
        a2_lsh                  <=                                             b1_pbr || b1_lsh;
        a2_cr_kop[0]            <=                                                     b1_k_dte;
        a2_cr_kop[1]            <=                                                     b1_k_dte;
        a2_cr_ksh               <=                                                      b1_twin;
        end
    end
    
    10'b1_00001_0101: // PAGE_HIT + PAGE_EXC
    begin
    a2_cr_state             <=                                                         5'b00000;
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b0;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end

    10'b1_00001_1000: // PAGE_MISS
    begin
    a2_cr_state             <=                                                         5'b00010;
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b1;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end

    //********************** wait for page lock ************************************************

    10'b1_00010_xx0x: // PAGE_UNLOCKED
    begin
    a2_cr_state             <=                                                         5'b00010;
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b0;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end

    10'b1_00010_xx1x: // PAGE_LOCKED
    begin
    a2_cr_state             <=                                                         5'b00100;
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b0;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end
    
    //********************** wait for page load ************************************************
    
    10'b1_00100_xx1x: // PAGE_LOCKED
    begin
    a2_cr_state             <=                                                         5'b00100;    
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b0;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end

    10'b1_00100_0001: // PAGE_HIT
    begin
    a2_cr_state             <= b1_k_ena ?                                5'b01000 :    5'b00000;    
    a2_cr_rep               <= b1_k_ena ?                                    1'b1 :      b1_pbr;
    a2_cr_stb               <= b1_k_ena ?                                    1'b1 :        1'b0;
    a2_cr_k_ena             <= b1_k_ena ?                                    1'b1 :        1'b0;
    a2_pass                 <= b1_k_ena ?                                    1'b0 :        1'b1;
    a2_cancel               <= b1_k_ena ?                                    1'b1 :        1'b0;
    a2_lsh                  <=                                                 b1_pbr || b1_lsh;
    a2_cr_kop[0]            <= b1_k_ena ?                                b1_k_dte :        1'b0;
    a2_cr_kop[1]            <= b1_k_ena ?                                b1_k_dte :        1'b0;
    a2_cr_ksh               <= b1_k_ena ?                                 b1_twin :        1'b0;
    end

    10'b1_00100_0101: // PAGE_HIT + PAGE_EXC
    begin
    a2_cr_state             <=                                                         5'b00000;    
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b0;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end

    //********************** wait for page lock for K-Operation ********************************

    10'b1_01000_xx0x: // PAGE_UNLOCKED
    begin
    a2_cr_state             <=                                                         5'b01000;
    a2_cr_rep               <=                                                             1'b1;
    a2_cr_stb               <=                                                             1'b0;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end

    10'b1_01000_xx1x: // PAGE_LOCKED
    begin
    a2_cr_state             <=                                                         5'b00000;
    a2_cr_rep               <=                                                             1'b0;
    a2_cr_stb               <=                                                             1'b0;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                           b1_lsh;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end
    
    //********************** idle **************************************************************
    
    10'b0_xxxxx_xxxx: // 
    begin
    a2_cr_state             <=                                                         5'b00000;    
    a2_cr_rep               <=                                                             1'b0;
    a2_cr_stb               <=                                                             1'b0;
    a2_cr_k_ena             <=                                                             1'b0;
    a2_pass                 <=                                                             1'b0;
    a2_cancel               <=                                                             1'b1;
    a2_lsh                  <=                                                             1'b0;
    a2_cr_kop[0]            <=                                                             1'b0;
    a2_cr_kop[1]            <=                                                             1'b0;
    a2_cr_ksh               <=                                                             1'b0;
    end                                                                                         
    
    //******************************************************************************************
    endcase
    
    if(cache_miss)          
        begin
            a2_cr_empty             <= cache_cr_wid ?                        b1_empty[1] :  b1_empty[0];
            a2_cr_wr                <=                                                            b1_st;
            a2_cr_tid               <=                                                           b1_tid;
            a2_cr_wid               <= cache_cr_wid ?                               1'b1 :         1'b0;
            a2_cr_tag               <= cache_cr_wid ?                         !b1_tag[1] :   !b1_tag[0];
            a2_cr_p_addr            <= cache_cr_wid ?                       b1_p_addr[1] : b1_p_addr[0];
    
            a2_cr_k_dir             <=                                                         b1_k_dir;
        end 
    else    
        begin
            a2_cr_empty             <=                                                             1'b0;
            a2_cr_wr                <=                                                            b1_st;
            a2_cr_tid               <=                                                           b1_tid;
            a2_cr_wid               <= b1_hit[1]    ?                               1'b1 :         1'b0;
            a2_cr_tag               <= b1_hit[1]    ?                          b1_tag[1] :    b1_tag[0];
            a2_cr_p_addr            <= b1_hit[1]    ?                       b1_p_addr[1] : b1_p_addr[0];
    
            a2_cr_k_dir             <=                                                         b1_k_dir;
        end 

    a2_cr_r_addr            <=                                                        b1_v_addr;
    a2_cr_k_addr            <=                                                        b1_k_addr;
        
    a2_c_ena                <=                                       !cache_locked && cache_hit;
    a2_c_tid                <=                                                           b1_tid;
    casex(b1_hit)
    2'bx1:   a2_c_wid       <=                                                             2'd0;
    2'b10:   a2_c_wid       <=                                                             2'd1;
    default: a2_c_wid       <=                                                             2'd0;
    endcase

    a2_c_page               <=                                                  b1_v_addr[12:6];
    a2_c_wen                <=                                 cache_hit && (|(b1_mask&b1_ben));

    // byte 7
    a2_c_b7_wen             <=                             b1_mask[7] && cache_hit && b1_ben[7];
    a2_c_b7_addr            <=                                       b1_v_addr[5:3] + b1_adc[7];
    a2_c_b7_data            <=                                                   b1_data[63:56];    
    // byte 6
    a2_c_b6_wen             <=                             b1_mask[6] && cache_hit && b1_ben[6];
    a2_c_b6_addr            <=                                       b1_v_addr[5:3] + b1_adc[6];
    a2_c_b6_data            <=                                                   b1_data[55:48];
    // byte 5
    a2_c_b5_wen             <=                             b1_mask[5] && cache_hit && b1_ben[5];
    a2_c_b5_addr            <=                                       b1_v_addr[5:3] + b1_adc[5];
    a2_c_b5_data            <=                                                   b1_data[47:40];
    // byte 4
    a2_c_b4_wen             <=                             b1_mask[4] && cache_hit && b1_ben[4];
    a2_c_b4_addr            <=                                       b1_v_addr[5:3] + b1_adc[4];
    a2_c_b4_data            <=                                                   b1_data[39:32];
    // byte 3
    a2_c_b3_wen             <=                             b1_mask[3] && cache_hit && b1_ben[3];                
    a2_c_b3_addr            <=                                       b1_v_addr[5:3] + b1_adc[3];                  
    a2_c_b3_data            <=                                                   b1_data[31:24];
    // byte 2
    a2_c_b2_wen             <=                             b1_mask[2] && cache_hit && b1_ben[2];
    a2_c_b2_addr            <=                                       b1_v_addr[5:3] + b1_adc[2];
    a2_c_b2_data            <=                                                   b1_data[23:16];
    // byte 1
    a2_c_b1_wen             <=                             b1_mask[1] && cache_hit && b1_ben[1];
    a2_c_b1_addr            <=                                       b1_v_addr[5:3] + b1_adc[1];
    a2_c_b1_data            <=                                                   b1_data[15: 8];
    // byte 0
    a2_c_b0_wen             <=                             b1_mask[0] && cache_hit && b1_ben[0];
    a2_c_b0_addr            <=                                       b1_v_addr[5:3] + b1_adc[0];
    a2_c_b0_data            <=                                                   b1_data[ 7: 0];    
// .... product Ry path ........................................................................
       
    a2_ry_ena               <=                                                        b1_ry_ena;
    a2_ry_addr              <=                                                       b1_ry_addr;
    a2_ry_tag               <=                                                        b1_ry_tag;

    casex({b1_hi,b1_pbr,b1_twin,b1_size,b1_v_addr[2:0]})

// TWIN with no HI and no PBR
    8'b0_0_1_xx_xxx: a2_ry_benA  <=                                                      4'b1111;

// lo
    // byte
    8'b0_1_0_00_xxx: a2_ry_benA  <=                                                      4'b1111;
    // half
    8'b0_1_0_01_000: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_0_01_001: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_0_01_010: a2_ry_benA  <=                                                      4'b1111;                                    
    8'b0_1_0_01_011: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_0_01_100: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_0_01_101: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_0_01_110: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_0_01_111: a2_ry_benA  <=                                                      4'b1111;
    // word
    8'b0_1_0_10_000: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_0_10_001: a2_ry_benA  <=                                                      4'b1110;
    8'b0_1_0_10_010: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_0_10_011: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_0_10_100: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_0_10_101: a2_ry_benA  <=                                                      4'b1110;
    8'b0_1_0_10_110: a2_ry_benA  <=                                                      4'b1100;
    8'b0_1_0_10_111: a2_ry_benA  <=                                                      4'b1000;
    
    // twin                                                                                     
    
    // byte
    8'b0_1_1_00_xxx: a2_ry_benA  <=                                                      4'b1111;                  
    // half                                                                                                  
    8'b0_1_1_01_000: a2_ry_benA  <=                                                      4'b1111;            
    8'b0_1_1_01_001: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_1_01_010: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_1_01_011: a2_ry_benA  <=                                                      4'b1110;
    8'b0_1_1_01_100: a2_ry_benA  <=                                                      4'b1110;
    8'b0_1_1_01_101: a2_ry_benA  <=                                                      4'b1110;
    8'b0_1_1_01_110: a2_ry_benA  <=                                                      4'b0000;
    8'b0_1_1_01_111: a2_ry_benA  <=                                                      4'b0000;
    // word
    8'b0_1_1_10_000: a2_ry_benA  <=                                                      4'b1111;
    8'b0_1_1_10_001: a2_ry_benA  <=                                                      4'b1110;
    8'b0_1_1_10_010: a2_ry_benA  <=                                                      4'b1100;
    8'b0_1_1_10_011: a2_ry_benA  <=                                                      4'b1000;
    8'b0_1_1_10_100: a2_ry_benA  <=                                                      4'b0000;
    8'b0_1_1_10_101: a2_ry_benA  <=                                                      4'b0000;
    8'b0_1_1_10_110: a2_ry_benA  <=                                                      4'b0000;
    8'b0_1_1_10_111: a2_ry_benA  <=                                                      4'b0000;
// hi   
    // byte 
    8'b1_x_0_00_xxx: a2_ry_benA  <=                                                      4'b1111;
    // half
    8'b1_x_0_01_000: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_01_001: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_01_010: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_01_011: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_01_100: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_01_101: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_01_110: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_01_111: a2_ry_benA  <=                                                      4'b0001;
    // word
    8'b1_x_0_10_000: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_10_001: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_10_010: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_10_011: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_10_100: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_0_10_101: a2_ry_benA  <=                                                      4'b0001;
    8'b1_x_0_10_110: a2_ry_benA  <=                                                      4'b0011;
    8'b1_x_0_10_111: a2_ry_benA  <=                                                      4'b0111;
// twin
    // byte
    8'b1_x_1_00_xxx: a2_ry_benA  <=                                                      4'b1111;
    // half
    8'b1_x_1_01_000: a2_ry_benA  <=                                                      4'b0000; 
    8'b1_x_1_01_001: a2_ry_benA  <=                                                      4'b0000; 
    8'b1_x_1_01_010: a2_ry_benA  <=                                                      4'b0000; 
    8'b1_x_1_01_011: a2_ry_benA  <=                                                      4'b0000; 
    8'b1_x_1_01_100: a2_ry_benA  <=                                                      4'b0000; 
    8'b1_x_1_01_101: a2_ry_benA  <=                                                      4'b0001; 
    8'b1_x_1_01_110: a2_ry_benA  <=                                                      4'b1111; 
    8'b1_x_1_01_111: a2_ry_benA  <=                                                      4'b1111; 
    // word
    8'b1_x_1_10_000: a2_ry_benA  <=                                                      4'b0000;
    8'b1_x_1_10_001: a2_ry_benA  <=                                                      4'b0001;
    8'b1_x_1_10_010: a2_ry_benA  <=                                                      4'b0011;
    8'b1_x_1_10_011: a2_ry_benA  <=                                                      4'b0111;
    8'b1_x_1_10_100: a2_ry_benA  <=                                                      4'b1111;
    8'b1_x_1_10_101: a2_ry_benA  <=                                                      4'b1111;
    8'b1_x_1_10_110: a2_ry_benA  <=                                                      4'b1111;
    8'b1_x_1_10_111: a2_ry_benA  <=                                                      4'b1111;

    default:         a2_ry_benA  <=                                                      4'b1111;
    endcase

    casex({b1_hi,b1_pbr,b1_twin,b1_size,b1_v_addr[2:0]})
// TWIN with no HI and no PBR
    8'b0_0_1_xx_xxx: a2_ry_benB  <=                                                      4'b1111;
// lo
    // twin
    // byte
    8'b0_1_1_00_000: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_00_001: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_00_010: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_00_011: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_00_100: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_00_101: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_00_110: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_00_111: a2_ry_benB  <=                                                      4'b1111;
    // half
    8'b0_1_1_01_000: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_01_001: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_01_010: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_01_011: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_01_100: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_01_101: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_01_110: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_01_111: a2_ry_benB  <=                                                      4'b1111;
    // word
    8'b0_1_1_10_000: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_10_001: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_10_010: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_10_011: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_10_100: a2_ry_benB  <=                                                      4'b1111;
    8'b0_1_1_10_101: a2_ry_benB  <=                                                      4'b1110;
    8'b0_1_1_10_110: a2_ry_benB  <=                                                      4'b1100;
    8'b0_1_1_10_111: a2_ry_benB  <=                                                      4'b1000;
// hi   
    // twin
    // byte
    8'b1_x_1_00_xxx: a2_ry_benB  <=                                                      4'b0000;
    // half
    8'b1_x_1_01_000: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_01_001: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_01_010: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_01_011: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_01_100: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_01_101: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_01_110: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_01_111: a2_ry_benB  <=                                                      4'b0001;
    // word
    8'b1_x_1_10_000: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_10_001: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_10_010: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_10_011: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_10_100: a2_ry_benB  <=                                                      4'b0000;
    8'b1_x_1_10_101: a2_ry_benB  <=                                                      4'b0001;
    8'b1_x_1_10_110: a2_ry_benB  <=                                                      4'b0011;
    8'b1_x_1_10_111: a2_ry_benB  <=                                                      4'b0111;
    
    default:         a2_ry_benB  <=                                                      4'b0000;
    endcase
// .............................................................................................
  end
//==============================================================================================
// flush pipe
//==============================================================================================
assign  fco_inst_lsf         =                                                        a2_cr_rep;
assign  fco_inst_lva         =                                                           a2_iva;
assign  fco_inst_lsw         =                   {a2_isw[15:13],a2_lsh,a2_cr_state,a2_isw[6:0]};
//==============================================================================================
// buffer for cache requests
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b3_cr_req               <=                                                             1'b0;
    b3_cr_tid               <=                                                             1'b0;
    b3_cr_asid              <=                                                             4'b0;
    b3_cr_wid               <=                                                             2'b0;
    b3_cr_tag               <=                                                             2'b0;
    b3_cr_kop               <=                                                             2'b0;
    b3_cr_ksh               <=                                                             1'b0;
    b3_cr_k_ena             <=                                                              'd0;
    b3_cr_k_force           <=                                                              'd0;
    b3_cr_mode              <=                                                             4'b0;
    b3_cr_page              <=                                                             7'b0;
    b3_cr_r_addr            <=                                                            32'd0;
    b3_cr_p_addr            <=                                                            32'd0;
    b3_cr_k_addr            <=                                                            32'd0;
  end
 else
  begin
    b3_cr_req               <=                                                        a2_cr_stb;
    b3_cr_tid               <=                                                        a2_cr_tid;
    b3_cr_asid              <=                                                       a2_cr_asid;
    b3_cr_wid               <=                                                        a2_cr_wid;
    b3_cr_tag               <=                                                        a2_cr_tag;
    b3_cr_kop               <=                                                        a2_cr_kop;
    b3_cr_ksh               <=                                                        a2_cr_ksh;    
    b3_cr_k_ena             <=                                                      a2_cr_k_ena;
    b3_cr_k_force           <=                                                    a2_cr_k_force;
    b3_cr_mode              <=    (a2_cr_empty) ?                               9'b00_1010_00_0: // page load
                                  (a2_cr_k_ena && a2_cr_k_dir[0] ) ?            9'b00_1001_00_0: // page update
                                  (a2_cr_k_ena && a2_cr_k_dir[1] ) ?            9'b00_1100_10_0: // page store
                                  (a2_cr_k_ena && a2_cr_k_dir[2] ) ?            9'b00_1010_00_0: // page load
                                  (a2_cr_k_ena && a2_cr_k_dir[3] ) ?            9'b00_1100_01_0: // page flush
                                                                                9'b00_1110_00_0; // page exchange
    b3_cr_page              <=                                               a2_cr_r_addr[12:6]; 
    if(a2_cr_ksh)
        begin       
            b3_cr_p_addr    <=                                        {a2_cr_p_addr[31:3],3'd0};
            b3_cr_r_addr    <=                                        {a2_cr_r_addr[31:3],3'd0}; 
            b3_cr_k_addr    <=                                        {a2_cr_k_addr[31:3],3'd0};
        end 
    else 
        begin       
            b3_cr_p_addr    <=                                        {a2_cr_p_addr[31:6],6'd0};
            b3_cr_r_addr    <=                                        {a2_cr_r_addr[31:6],6'd0}; 
            b3_cr_k_addr    <=                                        {a2_cr_k_addr[31:6],6'd0};
        end 
  end
//==============================================================================================
// data cache memory
//==============================================================================================      
// page write flag memory
//----------------------------------------------------------------------------------------------
eco32_core_lsu_dcu_pwf 
# // parameters
( 
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)
)
pwf
(
.clk            (clk),
.rst            (rst),

.i_wen          (a2_c_wen),
.i_tid          (a2_c_tid),
.i_wid          (a2_c_wid),
.i_page         (a2_c_page),
.i_cr_wid       (a2_cr_wid),

.o_pwf          (b3_cr_pwf),

.w_clr          (cache_pf_w_clr),
.w_wen          (cache_pf_w_wen),
.w_tid          (cache_pf_w_tid),              
.w_wid          (cache_pf_w_wid),
.w_page         (cache_pf_w_page)  
); 
//----------------------------------------------------------------------------------------------
// 8 memory banks for 8 bytes of data word
//----------------------------------------------------------------------------------------------
eco32_core_lsu_dcu_mem 
#
(
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH) 
)
dcu_mem_byte7
(
.clk            (clk),
.rst            (rst),

.i_wen          (a2_c_b7_wen),
.i_tid          (a2_c_tid),
.i_wid          (a2_c_wid),
.i_page         (a2_c_page),
.i_offset       (a2_c_b7_addr),
.i_data         (a2_c_b7_data),

.xi_stb         (cache_mm_w_stb),
.xi_tid         (cache_mm_w_tid),
.xi_wen         (cache_mm_w_wen),
.xi_wid         (cache_mm_w_wid),
.xi_page        (cache_mm_w_page),
.xi_offset      (cache_mm_w_offset),
.xi_data        (cache_mm_w_data[63:56]),

.xo_val         (cache_mm_r_stb),
.xo_ben         (cache_mm_r_ben[7]),
.xo_data        (cache_mm_r_data[63:56]),

.o_ben          (),
.o_data         (b3_data[63:56])
);   
//----------------------------------------------------------------------------------------------
eco32_core_lsu_dcu_mem 
#
(
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)   
)
dcu_mem_byte6
(
.clk            (clk),
.rst            (rst),

.i_wen          (a2_c_b6_wen),
.i_tid          (a2_c_tid),
.i_wid          (a2_c_wid),
.i_page         (a2_c_page),
.i_offset       (a2_c_b6_addr),
.i_data         (a2_c_b6_data),

.xi_stb         (cache_mm_w_stb),
.xi_wen         (cache_mm_w_wen),
.xi_tid         (cache_mm_w_tid),
.xi_wid         (cache_mm_w_wid),
.xi_page        (cache_mm_w_page),
.xi_offset      (cache_mm_w_offset),
.xi_data        (cache_mm_w_data[55:48]),

.xo_val         (),
.xo_ben         (cache_mm_r_ben[6]),
.xo_data        (cache_mm_r_data[55:48]),

.o_ben          (),
.o_data         (b3_data[55:48])
);   
//----------------------------------------------------------------------------------------------
eco32_core_lsu_dcu_mem 
#
(
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)    
)
dcu_mem_byte5
(
.clk            (clk),
.rst            (rst),

.i_wen          (a2_c_b5_wen),
.i_tid          (a2_c_tid),
.i_wid          (a2_c_wid),
.i_page         (a2_c_page),
.i_offset       (a2_c_b5_addr),
.i_data         (a2_c_b5_data),

.xi_stb         (cache_mm_w_stb),
.xi_wen         (cache_mm_w_wen),
.xi_tid         (cache_mm_w_tid),
.xi_wid         (cache_mm_w_wid),
.xi_page        (cache_mm_w_page),
.xi_offset      (cache_mm_w_offset),
.xi_data        (cache_mm_w_data[47:40]),                                                                                          
                                                                                                                               
.xo_val         (),
.xo_ben         (cache_mm_r_ben[5]),
.xo_data        (cache_mm_r_data[47:40]),

.o_ben          (),
.o_data         (b3_data[47:40])
);   
//----------------------------------------------------------------------------------------------
eco32_core_lsu_dcu_mem 
#
(
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)   
)
dcu_mem_byte4
(
.clk            (clk),
.rst            (rst),

.i_wen          (a2_c_b4_wen),
.i_tid          (a2_c_tid),
.i_wid          (a2_c_wid),
.i_page         (a2_c_page),
.i_offset       (a2_c_b4_addr),
.i_data         (a2_c_b4_data),

.xi_stb         (cache_mm_w_stb),
.xi_wen         (cache_mm_w_wen),
.xi_tid         (cache_mm_w_tid),
.xi_wid         (cache_mm_w_wid),
.xi_page        (cache_mm_w_page),
.xi_offset      (cache_mm_w_offset),
.xi_data        (cache_mm_w_data[39:32]),

.xo_val         (),
.xo_ben         (cache_mm_r_ben[4]),
.xo_data        (cache_mm_r_data[39:32]),

.o_ben          (),
.o_data         (b3_data[39:32])
);   
//----------------------------------------------------------------------------------------------
eco32_core_lsu_dcu_mem 
#
(
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)   
)
dcu_mem_byte3
(
.clk            (clk),
.rst            (rst),

.i_wen          (a2_c_b3_wen),
.i_tid          (a2_c_tid),
.i_wid          (a2_c_wid),
.i_page         (a2_c_page),
.i_offset       (a2_c_b3_addr),
.i_data         (a2_c_b3_data),

.xi_stb         (cache_mm_w_stb),
.xi_wen         (cache_mm_w_wen),
.xi_tid         (cache_mm_w_tid),
.xi_wid         (cache_mm_w_wid),
.xi_page        (cache_mm_w_page),
.xi_offset      (cache_mm_w_offset),
.xi_data        (cache_mm_w_data[31:24]),

.xo_val         (),
.xo_ben         (cache_mm_r_ben[3]),
.xo_data        (cache_mm_r_data[31:24]),

.o_ben          (),
.o_data         (b3_data[31:24])
);   
//----------------------------------------------------------------------------------------------
eco32_core_lsu_dcu_mem 
#
(
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)    
)
dcu_mem_byte2
(
.clk            (clk),
.rst            (rst),

.i_wen          (a2_c_b2_wen),
.i_tid          (a2_c_tid),
.i_wid          (a2_c_wid),
.i_page         (a2_c_page),
.i_offset       (a2_c_b2_addr),
.i_data         (a2_c_b2_data),

.xi_stb         (cache_mm_w_stb),
.xi_wen         (cache_mm_w_wen),
.xi_tid         (cache_mm_w_tid),
.xi_wid         (cache_mm_w_wid),
.xi_page        (cache_mm_w_page),
.xi_offset      (cache_mm_w_offset),
.xi_data        (cache_mm_w_data[23:16]),

.xo_val         (),
.xo_ben         (cache_mm_r_ben[2]),
.xo_data        (cache_mm_r_data[23:16]),

.o_ben          (),
.o_data         (b3_data[23:16])
);   
//----------------------------------------------------------------------------------------------
eco32_core_lsu_dcu_mem 
#
(
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)   
)
dcu_mem_byte1
(
.clk            (clk),
.rst            (rst),

.i_wen          (a2_c_b1_wen),
.i_tid          (a2_c_tid),
.i_wid          (a2_c_wid),
.i_page         (a2_c_page),
.i_offset       (a2_c_b1_addr),
.i_data         (a2_c_b1_data),

.xi_stb         (cache_mm_w_stb),
.xi_wen         (cache_mm_w_wen),
.xi_tid         (cache_mm_w_tid),
.xi_wid         (cache_mm_w_wid),
.xi_page        (cache_mm_w_page),
.xi_offset      (cache_mm_w_offset),
.xi_data        (cache_mm_w_data[15:8]),

.xo_val         (),
.xo_ben         (cache_mm_r_ben[1]),
.xo_data        (cache_mm_r_data[15:8]),

.o_ben          (),
.o_data         (b3_data[15:8])
);   
//----------------------------------------------------------------------------------------------
eco32_core_lsu_dcu_mem 
#
(
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)   
)
dcu_mem_byte0
(
.clk            (clk),
.rst            (rst),

.i_wen          (a2_c_b0_wen),
.i_tid          (a2_c_tid),
.i_wid          (a2_c_wid),
.i_page         (a2_c_page),
.i_offset       (a2_c_b0_addr),
.i_data         (a2_c_b0_data),

.xi_stb         (cache_mm_w_stb),
.xi_tid         (cache_mm_w_tid),
.xi_wen         (cache_mm_w_wen),
.xi_wid         (cache_mm_w_wid),
.xi_page        (cache_mm_w_page),
.xi_offset      (cache_mm_w_offset),
.xi_data        (cache_mm_w_data[7:0]),

.xo_val         (),
.xo_ben         (cache_mm_r_ben[0]),
.xo_data        (cache_mm_r_data[7:0]),

.o_ben          (),
.o_data         (b3_data[7:0])
);   
//==============================================================================================
//stage (b)3
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b3_stb                  <=                                                             1'd0;
    b3_tid                  <=                                                             1'b0;
    b3_pid                  <=                                                             1'b0;
    b3_isw                  <=                                                            16'b0;
    b3_isz                  <=                                                              'b0;
    b3_iva                  <=                                                              'b0;
    b3_asid                 <=                                                              'b0;

    b3_st                   <=                                                             1'b0;
    b3_ld                   <=                                                             1'b0;
    b3_sign                 <=                                                             1'b0;
    b3_size                 <=                                                             1'b0;
    b3_twin                 <=                                                             1'b0;
    b3_v_addr               <=                                                            32'd0;

    b3_ry_ena               <=                                                             2'd0;
    b3_ry_benA              <=                                                             4'd0;
    b3_ry_benB              <=                                                             4'd0;
    b3_ry_addr              <=                                                             5'd0;
    b3_ry_tag               <=                                                             2'd0;
    b3_ry_abort             <=                                                             1'd0;
  end   
 else  
  begin    
    b3_stb                  <=                                       a2_ld && a2_pass && a2_stb;
    b3_tid                  <=                                                           a2_tid;
    b3_pid                  <=                                                           a2_pid;
    b3_isw                  <=                                                           a2_isw;
    b3_isz                  <=                                                           a2_isz;
    b3_iva                  <=                                                           a2_iva;
    b3_asid                 <=                                                          a2_asid;
    
    b3_st                   <=                                                            a2_st;
    b3_ld                   <=                                                            a2_ld;
    b3_sign                 <=                                                          a2_sign;
    b3_size                 <=                                                          a2_size;
    b3_twin                 <=                                                          a2_twin;
    b3_v_addr               <=                                                        a2_v_addr;
    
// .... product Ry path ........................................................................

    b3_ry_ena               <= (a2_stb) ?                                      a2_ry_ena : 2'b0;
    b3_ry_benA              <= (a2_stb) ?                                     a2_ry_benA : 4'd0;
    b3_ry_benB              <= (a2_stb) ?                                     a2_ry_benB : 4'd0;
    b3_ry_addr              <= (a2_stb) ?                                     a2_ry_addr : 5'd0;
    b3_ry_tag               <= (a2_stb) ?                                      a2_ry_tag : 2'b0;
    b3_ry_abort             <= (a2_stb) ?                                      a2_cancel : 1'b0;
    
// .............................................................................................
  end                                                                               
//==============================================================================================
//stage (a)4
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a4_stb                  <=                                                             1'd0;
    a4_tid                  <=                                                             1'b0;
    a4_pid                  <=                                                             1'b0;
    a4_isw                  <=                                                            16'b0;
    a4_isz                  <=                                                              'b0;
    a4_iva                  <=                                                              'b0;
    a4_asid                 <=                                                              'b0;

    a4_st                   <=                                                             1'b0;
    a4_ld                   <=                                                             1'b0;
    a4_sign                 <=                                                             1'b0;
    a4_size                 <=                                                             1'b0;
    a4_v_addr               <=                                                            32'd0;
    a4_data64               <=                                                            64'd0;
                
    a4_ry_ena               <=                                                             2'd0;
    a4_ry_benA              <=                                                             4'd0;
    a4_ry_benB              <=                                                             4'd0;
    a4_ry_addr              <=                                                             5'd0;
    a4_ry_tag               <=                                                             2'd0;
    a4_ry_abort             <=                                                             1'd0;
    
    a4_ry_Lo_mxd            <=                                                              'd0;
    a4_ry_Lo_mxs            <=                                                              'd0;
    a4_ry_Lo_mxm            <=                                                              'd0;
    
    a4_ry_Hi_mxd            <=                                                              'd0;
    a4_ry_Hi_mxs            <=                                                              'd0;
    a4_ry_Hi_mxm            <=                                                              'd0;
  end   
 else  
  begin    
    a4_stb                  <=                                                           b3_stb;
    a4_tid                  <=                                                           b3_tid;
    a4_pid                  <=                                                           b3_pid;
    a4_isw                  <=                                                           b3_isw;
    a4_isz                  <=                                                           b3_isw;
    a4_iva                  <=                                                           b3_iva;
    a4_asid                 <=                                                          b3_asid;
    
    a4_st                   <=                                                            b3_st;
    a4_ld                   <=                                                            b3_ld;
    a4_sign                 <=                                                          b3_sign;
    a4_size                 <=                                                          b3_size;
    a4_v_addr               <=                                                        b3_v_addr;
    
    a4_data64[63:32]        <=                                                   b3_data[63:32];
    a4_data64[31: 0]        <=                                                   b3_data[31: 0];
    
// .... product Ry path ........................................................................
       
    a4_ry_ena               <=                                                        b3_ry_ena;
    a4_ry_benA              <=                                                       b3_ry_benA;
    a4_ry_benB              <=                                                       b3_ry_benB;
    a4_ry_addr              <=                                                       b3_ry_addr;
    a4_ry_tag               <=                                                        b3_ry_tag;
    a4_ry_abort             <=                                                      b3_ry_abort;

    // Lo (AorB)
    
    case({b3_twin,b3_size,b3_v_addr[2:0]})
    6'b0_00_000: a4_ry_Lo_mxd  <=                                                           'd7;
    6'b0_00_001: a4_ry_Lo_mxd  <=                                                           'd6;
    6'b0_00_010: a4_ry_Lo_mxd  <=                                                           'd5;
    6'b0_00_011: a4_ry_Lo_mxd  <=                                                           'd4;
    6'b0_00_100: a4_ry_Lo_mxd  <=                                                           'd3;
    6'b0_00_101: a4_ry_Lo_mxd  <=                                                           'd2;
    6'b0_00_110: a4_ry_Lo_mxd  <=                                                           'd1;
    6'b0_00_111: a4_ry_Lo_mxd  <=                                                           'd0;
                                                                                               
    6'b0_01_000: a4_ry_Lo_mxd  <=                                                           'd6;
    6'b0_01_001: a4_ry_Lo_mxd  <=                                                           'd5;
    6'b0_01_010: a4_ry_Lo_mxd  <=                                                           'd4;
    6'b0_01_011: a4_ry_Lo_mxd  <=                                                           'd3;
    6'b0_01_100: a4_ry_Lo_mxd  <=                                                           'd2;
    6'b0_01_101: a4_ry_Lo_mxd  <=                                                           'd1;
    6'b0_01_110: a4_ry_Lo_mxd  <=                                                           'd0;
    6'b0_01_111: a4_ry_Lo_mxd  <=                                                           'd7;
                                                                                               
    6'b0_10_000: a4_ry_Lo_mxd  <=                                                           'd4;
    6'b0_10_001: a4_ry_Lo_mxd  <=                                                           'd3;
    6'b0_10_010: a4_ry_Lo_mxd  <=                                                           'd2;
    6'b0_10_011: a4_ry_Lo_mxd  <=                                                           'd1;
    6'b0_10_100: a4_ry_Lo_mxd  <=                                                           'd0;
    6'b0_10_101: a4_ry_Lo_mxd  <=                                                           'd7;
    6'b0_10_110: a4_ry_Lo_mxd  <=                                                           'd6;
    6'b0_10_111: a4_ry_Lo_mxd  <=                                                           'd5;
    //twin
    6'b1_00_000: a4_ry_Lo_mxd  <=                                                           'd6;
    6'b1_00_001: a4_ry_Lo_mxd  <=                                                           'd5;
    6'b1_00_010: a4_ry_Lo_mxd  <=                                                           'd4;
    6'b1_00_011: a4_ry_Lo_mxd  <=                                                           'd3;
    6'b1_00_100: a4_ry_Lo_mxd  <=                                                           'd2;
    6'b1_00_101: a4_ry_Lo_mxd  <=                                                           'd1;
    6'b1_00_110: a4_ry_Lo_mxd  <=                                                           'd0;
    6'b1_00_111: a4_ry_Lo_mxd  <=                                                           'd7;
                                                                                               
    6'b1_01_000: a4_ry_Lo_mxd  <=                                                           'd4;
    6'b1_01_001: a4_ry_Lo_mxd  <=                                                           'd3;
    6'b1_01_010: a4_ry_Lo_mxd  <=                                                           'd2;
    6'b1_01_011: a4_ry_Lo_mxd  <=                                                           'd1;
    6'b1_01_100: a4_ry_Lo_mxd  <=                                                           'd0;
    6'b1_01_101: a4_ry_Lo_mxd  <=                                                           'd7;
    6'b1_01_110: a4_ry_Lo_mxd  <=                                                           'd6;
    6'b1_01_111: a4_ry_Lo_mxd  <=                                                           'd5;
                                                                                               
    6'b1_10_000: a4_ry_Lo_mxd  <=                                                           'd0;
    6'b1_10_001: a4_ry_Lo_mxd  <=                                                           'd7;
    6'b1_10_010: a4_ry_Lo_mxd  <=                                                           'd6;
    6'b1_10_011: a4_ry_Lo_mxd  <=                                                           'd5;
    6'b1_10_100: a4_ry_Lo_mxd  <=                                                           'd4;
    6'b1_10_101: a4_ry_Lo_mxd  <=                                                           'd3;
    6'b1_10_110: a4_ry_Lo_mxd  <=                                                           'd2;
    6'b1_10_111: a4_ry_Lo_mxd  <=                                                           'd1;
    endcase

    case({b3_twin,b3_size,b3_v_addr[2:0]})
    6'b0_00_000: a4_ry_Lo_mxs  <=                                                           'd7;
    6'b0_00_001: a4_ry_Lo_mxs  <=                                                           'd6;
    6'b0_00_010: a4_ry_Lo_mxs  <=                                                           'd5;
    6'b0_00_011: a4_ry_Lo_mxs  <=                                                           'd4;
    6'b0_00_100: a4_ry_Lo_mxs  <=                                                           'd3;
    6'b0_00_101: a4_ry_Lo_mxs  <=                                                           'd2;
    6'b0_00_110: a4_ry_Lo_mxs  <=                                                           'd1;
    6'b0_00_111: a4_ry_Lo_mxs  <=                                                           'd0;
                                                                                               
    6'b0_01_000: a4_ry_Lo_mxs  <=                                                           'd7;
    6'b0_01_001: a4_ry_Lo_mxs  <=                                                           'd6;
    6'b0_01_010: a4_ry_Lo_mxs  <=                                                           'd5;
    6'b0_01_011: a4_ry_Lo_mxs  <=                                                           'd4;
    6'b0_01_100: a4_ry_Lo_mxs  <=                                                           'd3;
    6'b0_01_101: a4_ry_Lo_mxs  <=                                                           'd2;
    6'b0_01_110: a4_ry_Lo_mxs  <=                                                           'd1;
    6'b0_01_111: a4_ry_Lo_mxs  <=                                                           'd0;
                                                                                               
    6'b0_10_000: a4_ry_Lo_mxs  <=                                                           'd7;
    6'b0_10_001: a4_ry_Lo_mxs  <=                                                           'd6;
    6'b0_10_010: a4_ry_Lo_mxs  <=                                                           'd5;
    6'b0_10_011: a4_ry_Lo_mxs  <=                                                           'd4;
    6'b0_10_100: a4_ry_Lo_mxs  <=                                                           'd3;
    6'b0_10_101: a4_ry_Lo_mxs  <=                                                           'd2;
    6'b0_10_110: a4_ry_Lo_mxs  <=                                                           'd1;
    6'b0_10_111: a4_ry_Lo_mxs  <=                                                           'd0;
    //twin
    6'b1_00_000: a4_ry_Lo_mxs  <=                                                           'd6;
    6'b1_00_001: a4_ry_Lo_mxs  <=                                                           'd5;
    6'b1_00_010: a4_ry_Lo_mxs  <=                                                           'd4;
    6'b1_00_011: a4_ry_Lo_mxs  <=                                                           'd3;
    6'b1_00_100: a4_ry_Lo_mxs  <=                                                           'd2;
    6'b1_00_101: a4_ry_Lo_mxs  <=                                                           'd1;
    6'b1_00_110: a4_ry_Lo_mxs  <=                                                           'd0;
    6'b1_00_111: a4_ry_Lo_mxs  <=                                                           'd7;
                                                                                               
    6'b1_01_000: a4_ry_Lo_mxs  <=                                                           'd5;
    6'b1_01_001: a4_ry_Lo_mxs  <=                                                           'd4;
    6'b1_01_010: a4_ry_Lo_mxs  <=                                                           'd3;
    6'b1_01_011: a4_ry_Lo_mxs  <=                                                           'd2;
    6'b1_01_100: a4_ry_Lo_mxs  <=                                                           'd1;
    6'b1_01_101: a4_ry_Lo_mxs  <=                                                           'd0;
    6'b1_01_110: a4_ry_Lo_mxs  <=                                                           'd7;
    6'b1_01_111: a4_ry_Lo_mxs  <=                                                           'd6;
                                                                                               
    6'b1_10_000: a4_ry_Lo_mxs  <=                                                           'd3;
    6'b1_10_001: a4_ry_Lo_mxs  <=                                                           'd2;
    6'b1_10_010: a4_ry_Lo_mxs  <=                                                           'd1;
    6'b1_10_011: a4_ry_Lo_mxs  <=                                                           'd0;
    6'b1_10_100: a4_ry_Lo_mxs  <=                                                           'd7;
    6'b1_10_101: a4_ry_Lo_mxs  <=                                                           'd6;
    6'b1_10_110: a4_ry_Lo_mxs  <=                                                           'd5;
    6'b1_10_111: a4_ry_Lo_mxs  <=                                                           'd4;
    endcase
    
    casex({b3_sign,b3_size})
    3'b0_00:  a4_ry_Lo_mxm  <=                                                              'd0;
    3'b0_01:  a4_ry_Lo_mxm  <=                                                              'd1;
    3'b0_10:  a4_ry_Lo_mxm  <=                                                              'd2;
    3'b0_11:  a4_ry_Lo_mxm  <=                                                              'd3;
    
    3'b1_00:  a4_ry_Lo_mxm  <=                                                              'd4;
    3'b1_01:  a4_ry_Lo_mxm  <=                                                              'd5;
    3'b1_10:  a4_ry_Lo_mxm  <=                                                              'd6;
    3'b1_11:  a4_ry_Lo_mxm  <=                                                              'd7;
    endcase
    
    // Hi or first word (for bank A or B)
    
    case({b3_size,b3_v_addr[2:0]})
    5'b00_000: a4_ry_Hi_mxd  <=                                                             'd7;
    5'b00_001: a4_ry_Hi_mxd  <=                                                             'd6;
    5'b00_010: a4_ry_Hi_mxd  <=                                                             'd5;
    5'b00_011: a4_ry_Hi_mxd  <=                                                             'd4;
    5'b00_100: a4_ry_Hi_mxd  <=                                                             'd3;
    5'b00_101: a4_ry_Hi_mxd  <=                                                             'd2;
    5'b00_110: a4_ry_Hi_mxd  <=                                                             'd1;
    5'b00_111: a4_ry_Hi_mxd  <=                                                             'd0;
          
    5'b01_000: a4_ry_Hi_mxd  <=                                                             'd6;
    5'b01_001: a4_ry_Hi_mxd  <=                                                             'd5;
    5'b01_010: a4_ry_Hi_mxd  <=                                                             'd4;
    5'b01_011: a4_ry_Hi_mxd  <=                                                             'd3;
    5'b01_100: a4_ry_Hi_mxd  <=                                                             'd2;
    5'b01_101: a4_ry_Hi_mxd  <=                                                             'd1;
    5'b01_110: a4_ry_Hi_mxd  <=                                                             'd0;
    5'b01_111: a4_ry_Hi_mxd  <=                                                             'd7;
         
    5'b10_000: a4_ry_Hi_mxd  <=                                                             'd4;
    5'b10_001: a4_ry_Hi_mxd  <=                                                             'd3;
    5'b10_010: a4_ry_Hi_mxd  <=                                                             'd2;
    5'b10_011: a4_ry_Hi_mxd  <=                                                             'd1;
    5'b10_100: a4_ry_Hi_mxd  <=                                                             'd0;
    5'b10_101: a4_ry_Hi_mxd  <=                                                             'd7;
    5'b10_110: a4_ry_Hi_mxd  <=                                                             'd6;
    5'b10_111: a4_ry_Hi_mxd  <=                                                             'd5;
    endcase

    case({b3_size,b3_v_addr[2:0]})
    5'b00_000: a4_ry_Hi_mxs  <=                                                             'd7;
    5'b00_001: a4_ry_Hi_mxs  <=                                                             'd6;
    5'b00_010: a4_ry_Hi_mxs  <=                                                             'd5;
    5'b00_011: a4_ry_Hi_mxs  <=                                                             'd4;
    5'b00_100: a4_ry_Hi_mxs  <=                                                             'd3;
    5'b00_101: a4_ry_Hi_mxs  <=                                                             'd2;
    5'b00_110: a4_ry_Hi_mxs  <=                                                             'd1;
    5'b00_111: a4_ry_Hi_mxs  <=                                                             'd0;
          
    5'b01_000: a4_ry_Hi_mxs  <=                                                             'd7;
    5'b01_001: a4_ry_Hi_mxs  <=                                                             'd6;
    5'b01_010: a4_ry_Hi_mxs  <=                                                             'd5;
    5'b01_011: a4_ry_Hi_mxs  <=                                                             'd4;
    5'b01_100: a4_ry_Hi_mxs  <=                                                             'd3;
    5'b01_101: a4_ry_Hi_mxs  <=                                                             'd2;
    5'b01_110: a4_ry_Hi_mxs  <=                                                             'd1;
    5'b01_111: a4_ry_Hi_mxs  <=                                                             'd0;
    
    5'b10_000: a4_ry_Hi_mxs  <=                                                             'd7;
    5'b10_001: a4_ry_Hi_mxs  <=                                                             'd6;
    5'b10_010: a4_ry_Hi_mxs  <=                                                             'd5;
    5'b10_011: a4_ry_Hi_mxs  <=                                                             'd4;
    5'b10_100: a4_ry_Hi_mxs  <=                                                             'd3;
    5'b10_101: a4_ry_Hi_mxs  <=                                                             'd2;
    5'b10_110: a4_ry_Hi_mxs  <=                                                             'd1;
    5'b10_111: a4_ry_Hi_mxs  <=                                                             'd0;
    endcase
    
    casex({b3_sign,b3_size})
    3'b0_00:  a4_ry_Hi_mxm  <=                                                              'd0;
    3'b0_01:  a4_ry_Hi_mxm  <=                                                              'd1;
    3'b0_10:  a4_ry_Hi_mxm  <=                                                              'd2;
    3'b0_11:  a4_ry_Hi_mxm  <=                                                              'd3;
    
    3'b1_00:  a4_ry_Hi_mxm  <=                                                              'd4;
    3'b1_01:  a4_ry_Hi_mxm  <=                                                              'd5;
    3'b1_10:  a4_ry_Hi_mxm  <=                                                              'd6;
    3'b1_11:  a4_ry_Hi_mxm  <=                                                              'd7;
    endcase
    
// .............................................................................................
  end      
//==============================================================================================
//stage (b)5
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b5_stb                      <=                                                         1'b0;
    b5_tid                      <=                                                         1'b0;
    b5_pid                      <=                                                         2'b0;
    b5_isw                      <=                                                         1'b0;        
    b5_asid                     <=                                                          'b0;        
                                                                            
    b5_ry_stb0                  <=                                                         1'b0;
    b5_ry_stb1                  <=                                                         1'b0;

    b5_ry_enaA                  <=                                                         2'd0;
    b5_ry_benA                  <=                                                         4'd0;
    b5_ry_tagA                  <=                                                         1'd0;

    b5_ry_enaB                  <=                                                         2'd0;
    b5_ry_benB                  <=                                                         4'd0;
    b5_ry_modB                  <=                                                         1'd0;
    b5_ry_tagB                  <=                                                         1'd0;
  
    b5_ry_addr                  <=                                                         5'd0;
    
    b5_ry_Lo                     =                                                        32'd0;
    b5_ry_Hi                     =                                                        32'd0;
  end   
 else  
  begin    
    b5_stb                      <=                                                       a4_stb;
    b5_tid                      <=                                                       a4_tid;                                        
    b5_pid                      <=                                                       a4_pid;
    b5_isw                      <=                                                       a4_isw;        
    b5_asid                     <=                                                      a4_asid;        
    
// .... product Ya path ........................................................................

    b5_ry_stb0                  <=                                       !a4_tid & (|a4_ry_ena);
    b5_ry_stb1                  <=                                        a4_tid & (|a4_ry_ena);

    b5_ry_addr                  <=                                                   a4_ry_addr;
    
    b5_ry_enaA                  <= (a4_ry_abort) ?      {a4_ry_ena[0],1'b0} : {2{a4_ry_ena[0]}};      
    b5_ry_benA                  <=                                                   a4_ry_benA;
    b5_ry_tagA                  <=                                                 a4_ry_tag[0];
                                                                                                                                                                                                                      
    
    b5_ry_enaB                  <= (a4_ry_abort) ?      {a4_ry_ena[1],1'b0} : {2{a4_ry_ena[1]}};
    b5_ry_benB                  <=                                                   a4_ry_benB;
    b5_ry_modB                  <=                                                   &a4_ry_ena;
    b5_ry_tagB                  <=                                                 a4_ry_tag[1];

    // Lo : bank A or B  
    
    begin : b5_ry_data_Lo 
        case(a4_ry_Lo_mxd)
        3'd0: b5_ry_Lo_d     =                             {                 a4_data64[31: 0]}; 
        3'd1: b5_ry_Lo_d     =                             {                 a4_data64[39: 8]};
        3'd2: b5_ry_Lo_d     =                             {                 a4_data64[47:16]};
        3'd3: b5_ry_Lo_d     =                             {                 a4_data64[55:24]};
        3'd4: b5_ry_Lo_d     =                             {                 a4_data64[63:32]};
        3'd5: b5_ry_Lo_d     =                             {a4_data64[ 7: 0],a4_data64[63:40]};
        3'd6: b5_ry_Lo_d     =                             {a4_data64[15: 0],a4_data64[63:48]};
        3'd7: b5_ry_Lo_d     =                             {a4_data64[23: 0],a4_data64[63:56]};
        endcase              
        
        case(a4_ry_Lo_mxs)
        3'd0: b5_ry_Lo_s     =                                                   a4_data64[ 7];
        3'd1: b5_ry_Lo_s     =                                                   a4_data64[15];
        3'd2: b5_ry_Lo_s     =                                                   a4_data64[23];
        3'd3: b5_ry_Lo_s     =                                                   a4_data64[31];
        3'd4: b5_ry_Lo_s     =                                                   a4_data64[39];
        3'd5: b5_ry_Lo_s     =                                                   a4_data64[47];
        3'd6: b5_ry_Lo_s     =                                                   a4_data64[55];
        3'd7: b5_ry_Lo_s     =                                                   a4_data64[63];
        endcase
        
        case(a4_ry_Lo_mxm)
        3'b0_00: b5_ry_Lo      =                        {            24'b0, b5_ry_Lo_d[ 7: 0]};
        3'b0_01: b5_ry_Lo      =                        {            16'b0, b5_ry_Lo_d[15: 0]};
        3'b0_10: b5_ry_Lo      =                        {                   b5_ry_Lo_d[31: 0]};
        3'b0_11: b5_ry_Lo      =                        {                   b5_ry_Lo_d[31: 0]};
        3'b1_00: b5_ry_Lo      =                        { {24{b5_ry_Lo_s}}, b5_ry_Lo_d[ 7: 0]};
        3'b1_01: b5_ry_Lo      =                        { {16{b5_ry_Lo_s}}, b5_ry_Lo_d[15: 0]};
        3'b1_10: b5_ry_Lo      =                        {                   b5_ry_Lo_d[31: 0]};
        3'b1_11: b5_ry_Lo      =                        {                   b5_ry_Lo_d[31: 0]};
        endcase     
    end     

    // Hi : only bank B                                                                                                                                              
    
    begin : b5_ry_data_Hi
        case(a4_ry_Hi_mxd)
        3'd0: b5_ry_Hi_d     =                             {                 a4_data64[31: 0]}; 
        3'd1: b5_ry_Hi_d     =                             {                 a4_data64[39: 8]};
        3'd2: b5_ry_Hi_d     =                             {                 a4_data64[47:16]};
        3'd3: b5_ry_Hi_d     =                             {                 a4_data64[55:24]};
        3'd4: b5_ry_Hi_d     =                             {                 a4_data64[63:32]};
        3'd5: b5_ry_Hi_d     =                             {a4_data64[ 7: 0],a4_data64[63:40]};
        3'd6: b5_ry_Hi_d     =                             {a4_data64[15: 0],a4_data64[63:48]};
        3'd7: b5_ry_Hi_d     =                             {a4_data64[23: 0],a4_data64[63:56]};
        endcase    
        
        case(a4_ry_Hi_mxs)
        3'd0: b5_ry_Hi_s     =                                                   a4_data64[ 7];
        3'd1: b5_ry_Hi_s     =                                                   a4_data64[15];
        3'd2: b5_ry_Hi_s     =                                                   a4_data64[23];
        3'd3: b5_ry_Hi_s     =                                                   a4_data64[31];
        3'd4: b5_ry_Hi_s     =                                                   a4_data64[39];
        3'd5: b5_ry_Hi_s     =                                                   a4_data64[47];
        3'd6: b5_ry_Hi_s     =                                                   a4_data64[55];
        3'd7: b5_ry_Hi_s     =                                                   a4_data64[63];
        endcase
        
        case(a4_ry_Hi_mxm)
        3'b0_00: b5_ry_Hi      =                        {            24'b0, b5_ry_Hi_d[ 7: 0]};
        3'b0_01: b5_ry_Hi      =                        {            16'b0, b5_ry_Hi_d[15: 0]};
        3'b0_10: b5_ry_Hi      =                        {                   b5_ry_Hi_d[31: 0]};
        3'b0_11: b5_ry_Hi      =                        {                   b5_ry_Hi_d[31: 0]};
        3'b1_00: b5_ry_Hi      =                        { {24{b5_ry_Hi_s}}, b5_ry_Hi_d[ 7: 0]};
        3'b1_01: b5_ry_Hi      =                        { {16{b5_ry_Hi_s}}, b5_ry_Hi_d[15: 0]};
        3'b1_10: b5_ry_Hi      =                        {                   b5_ry_Hi_d[31: 0]};
        3'b1_11: b5_ry_Hi      =                        {                   b5_ry_Hi_d[31: 0]};
        endcase     
    end     
    
// .............................................................................................
  end                                                          
//==============================================================================================
//   
//============================================================================================== 
// pragma translate_off
initial
  begin         
    $display( "%m: TODO: eco32_core_lsu_dcm oczekuje 5-cio bitowego i_page a jest 7-mio bitowy" );          
  end
// pragma translate_on   
//---------------------------------------------------------------------------------------------- 
eco32_core_lsu_dcm
#
(
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH),
.FORCE_RST          (FORCE_RST)   
)
dcm_box
(
.clk                (clk),
.rst                (rst),   
.rdy                (rdy),   

.ep_i_stb           (ep_i_stb),
.ep_i_sof           (ep_i_sof),
.ep_i_iid           (ep_i_iid),
.ep_i_data          (ep_i_data),

.ep_o_br            (ep_o_br), 
.ep_o_bg            (ep_o_bg), 

.ep_o_stb           (ep_o_stb),
.ep_o_sof           (ep_o_sof),
.ep_o_iid           (ep_o_iid),
.ep_o_data          (ep_o_data),
.ep_o_rdy           (ep_o_rdy),
.ep_o_rdyE          (ep_o_rdyE),

.i_stb              (b3_cr_req), 
.i_tid              (b3_cr_tid), 
.i_wid              (b3_cr_wid), 
.i_tag              (b3_cr_tag), 
.i_mode             (b3_cr_mode),
.i_dirty            (b3_cr_pwf),
.i_page             (b3_cr_page),
.i_k_ena            (b3_cr_k_ena),
.i_k_force          (b3_cr_k_force),
.i_k_op             (b3_cr_kop),
.i_k_sh             (b3_cr_ksh),
.i_r_addr           (b3_cr_r_addr),
.i_p_addr           (b3_cr_p_addr),
.i_k_addr           (b3_cr_k_addr),
.i_rdy              (), 

.pt_w_stb           (cache_pt_w_stb),
.pt_w_tid           (cache_pt_w_tid),
.pt_w_eor           (),
.pt_w_wid           (cache_pt_w_wid),
.pt_w_page          (cache_pt_w_page),                         
.pt_w_data          (cache_pt_w_data),

.pf_w_clr           (cache_pf_w_clr),    
.pf_w_wen           (cache_pf_w_wen),    
.pf_w_tid           (cache_pf_w_tid),    
.pf_w_wid           (cache_pf_w_wid),    
.pf_w_page          (cache_pf_w_page),   

.mm_w_stb           (cache_mm_w_stb),      
.mm_w_wen           (cache_mm_w_wen),      
.mm_w_tid           (cache_mm_w_tid),      
.mm_w_wid           (cache_mm_w_wid),      
.mm_w_page          (cache_mm_w_page),     
.mm_w_offset        (cache_mm_w_offset),   
.mm_w_data          (cache_mm_w_data),     
               
.mm_r_stb           (cache_mm_r_stb),      
.mm_r_ben           (cache_mm_r_ben),      
.mm_r_data          (cache_mm_r_data)      
);     
//==============================================================================================
// write back
//==============================================================================================
assign  wb_stb0             =                                                        b5_ry_stb0; 
assign  wb_stb1             =                                                        b5_ry_stb1; 

assign  wb_enaA             =                                                        b5_ry_enaA; 
assign  wb_benA             =                                                        b5_ry_benA; 
assign  wb_tagA             =                                                        b5_ry_tagA;

assign  wb_enaB             =                                                        b5_ry_enaB; 
assign  wb_benB             =                                                        b5_ry_benB; 
assign  wb_modB             =                                                        b5_ry_modB;
assign  wb_tagB             =                                                        b5_ry_tagB;
                     
assign  wb_addr             =                                                        b5_ry_addr; 
assign  wb_dataL            =                                                          b5_ry_Lo;
assign  wb_dataH            =                                                          b5_ry_Hi;
//==============================================================================================  
endmodule