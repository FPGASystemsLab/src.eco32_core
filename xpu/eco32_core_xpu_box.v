//=============================================================================
//    Main contributors
//      - Jakub Siast         <mailto:jakubsiast@gmail.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_xpu_box
#(                                                        
parameter           DSP             =                                                 "DSP48A1", // "DSP48E", "DSP48E1", "DSP48A1", "MUL18x18", "MUL25x18"
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
wire        f_int16_stb  =  i_ml_cw[ 0];
wire        f_int32_stb  =  i_ml_cw[ 1];
wire        f_int16_sub  =  i_ml_cw[ 2]; 
wire        f_int16_add  =  i_ml_cw[ 3] || i_ml_cw[ 4]; 
wire        f_int16_lea  =  i_ml_cw[ 4];
wire        f_op_signed  = !i_ml_cw[ 5];  
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
(* shreg_extract = "NO"  *) reg             a0_stb;
(* shreg_extract = "NO"  *) reg             a0_tid;
(* shreg_extract = "NO"  *) reg     [ 1:0]  a0_pid;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_v_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_opcode;
(* shreg_extract = "NO"  *) reg     [ 4:0]  a0_dst_addr;
(* shreg_extract = "NO"  *) reg     [ 1:0]  a0_dst_ena;
(* shreg_extract = "NO"  *) reg     [ 1:0]  a0_dst_tag;    
                              
(* shreg_extract = "NO"  *) reg             a0_int16_stb; 
(* shreg_extract = "NO"  *) reg             a0_int16_add; 
(* shreg_extract = "NO"  *) reg             a0_int16_lea;
(* shreg_extract = "NO"  *) reg             a0_int16_sub;
(* shreg_extract = "NO"  *) reg             a0_int32_stb; 
(* shreg_extract = "NO"  *) reg             a0_op_signed; 

(* shreg_extract = "NO"  *) reg  [34:0]     a0_mul_opa;                                                                                                                    
(* shreg_extract = "NO"  *) reg  [24:0]     a0_mul_opb;                                                                                                                
(* shreg_extract = "NO"  *) reg  [34:0]     a0_mul_opc;                                                                                                                
(* shreg_extract = "NO"  *) reg  [24:0]     a0_mul_opd;  

(* shreg_extract = "NO"  *) reg     [31:0]  a0_ra_data; 
(* shreg_extract = "NO"  *) reg     [31:0]  a0_rb_data;  
(* shreg_extract = "NO"  *) reg     [31:0]  a0_rc_data; 
(* shreg_extract = "NO"  *) reg     [31:0]  a0_rd_data; 

                            wire            a0x_ins_valid;                                            
//==============================================================================================
// stage b (1) variables
//==============================================================================================
(* shreg_extract = "NO"  *) reg             b1_stb;
(* shreg_extract = "NO"  *) reg             b1_tid;
(* shreg_extract = "NO"  *) reg     [ 1:0]  b1_dst_ena;
(* shreg_extract = "NO"  *) reg     [ 1:0]  b1_dst_tag;
(* shreg_extract = "NO"  *) reg     [ 1:0]  b1_pid;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_v_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_opcode; 
(* shreg_extract = "NO"  *) reg     [ 4:0]  b1_dst_addr;
(* shreg_extract = "NO"  *) reg             b1_int16_stb; 
(* shreg_extract = "NO"  *) reg             b1_int16_add;
(* shreg_extract = "NO"  *) reg             b1_int16_lea;
(* shreg_extract = "NO"  *) reg             b1_int16_sub;
(* shreg_extract = "NO"  *) reg             b1_int32_stb;
(* shreg_extract = "NO"  *) reg             b1_op_signed;       
                                                  
(* shreg_extract = "NO"  *) reg     [31:0]  b1_ra_data;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_rb_data;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_rc_data;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_rd_data;              
//==============================================================================================  
// stage a (2) variables
//============================================================================================== 
(* shreg_extract = "NO"  *) reg             a2_stb;
(* shreg_extract = "NO"  *) reg             a2_tid;
(* shreg_extract = "NO"  *) reg     [ 1:0]  a2_dst_ena;
(* shreg_extract = "NO"  *) reg     [ 1:0]  a2_dst_tag;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_pid;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_v_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_opcode;
(* shreg_extract = "NO"  *) reg      [4:0]  a2_dst_addr;  
                              
(* shreg_extract = "NO"  *) reg             a2_int16_stb; 
(* shreg_extract = "NO"  *) reg             a2_int16_add;
(* shreg_extract = "NO"  *) reg             a2_int16_lea;
(* shreg_extract = "NO"  *) reg             a2_int16_sub;
(* shreg_extract = "NO"  *) reg             a2_int32_stb;   
(* shreg_extract = "NO"  *) reg             a2_op_signed;      

(* shreg_extract = "NO"  *) reg     [31:0]  a2_ra_data;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_rb_data;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_rc_data;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_rd_data;         
//==============================================================================================
// stage b (3) variables
//============================================================================================== 
(* shreg_extract = "NO"  *) reg             b3_stb;
(* shreg_extract = "NO"  *) reg             b3_tid;
(* shreg_extract = "NO"  *) reg     [ 1:0]  b3_dst_ena;
(* shreg_extract = "NO"  *) reg     [ 1:0]  b3_dst_tag;
(* shreg_extract = "NO"  *) reg      [1:0]  b3_pid;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_v_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_opcode;
(* shreg_extract = "NO"  *) reg      [4:0]  b3_dst_addr;  
                              
(* shreg_extract = "NO"  *) reg             b3_int16_stb; 
(* shreg_extract = "NO"  *) reg             b3_int16_add;
(* shreg_extract = "NO"  *) reg             b3_int16_lea;
(* shreg_extract = "NO"  *) reg             b3_int16_sub;
(* shreg_extract = "NO"  *) reg             b3_int32_stb; 
(* shreg_extract = "NO"  *) reg             b3_op_signed;  

(* shreg_extract = "NO"  *) reg     [31:0]  b3_ra_data;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_rb_data;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_rc_data;
(* shreg_extract = "NO"  *) reg     [31:0]  b3_rd_data;    

                            wire    [59:0]  b3_ab_mul_data;
                            wire    [59:0]  b3_cd_mul_data; 

                            wire    [63:0]  b3x_int32_res;  
                              
(* shreg_extract = "NO"  *) reg             b3_wb_A_ena; 
(* shreg_extract = "NO"  *) reg             b3_wb_B_ena; 
(* shreg_extract = "NO"  *) reg             b3_wb_BA_ena;  
//==============================================================================================
// stage aw4 (4) prepering results for wb0
//==============================================================================================  
(* shreg_extract = "NO"  *) reg             aw4_stb;
(* shreg_extract = "NO"  *) reg             aw4_tid;
(* shreg_extract = "NO"  *) reg     [ 1:0]  aw4_dst_ena;
(* shreg_extract = "NO"  *) reg     [ 1:0]  aw4_dst_tag;
(* shreg_extract = "NO"  *) reg      [1:0]  aw4_pid;
(* shreg_extract = "NO"  *) reg     [31:0]  aw4_v_addr;
(* shreg_extract = "NO"  *) reg     [31:0]  aw4_opcode; 
(* shreg_extract = "NO"  *) reg      [4:0]  aw4_dst_addr;
                              
(* shreg_extract = "NO"  *) reg             aw4_int16_stb; 
(* shreg_extract = "NO"  *) reg             aw4_int16_add;
(* shreg_extract = "NO"  *) reg             aw4_int16_lea;
(* shreg_extract = "NO"  *) reg             aw4_int16_sub;
(* shreg_extract = "NO"  *) reg             aw4_int32_stb;
(* shreg_extract = "NO"  *) reg             aw4_op_signed; 
                             
(* shreg_extract = "NO"  *) reg             aw4_A_ena;  
(* shreg_extract = "NO"  *) reg             aw4_t0_ena;
(* shreg_extract = "NO"  *) reg             aw4_t1_ena;
(* shreg_extract = "NO"  *) reg     [ 4:0]  aw4_rg_addr;     
(* shreg_extract = "NO"  *) reg     [ 1:0]  aw4_tag;     
(* shreg_extract = "NO"  *) reg             aw4_B_ena;      
(* shreg_extract = "NO"  *) reg             aw4_B_mod; 
                                
(* shreg_extract = "NO"  *) reg     [31:0]  aw4_int32_res_L;                                                                                                        
(* shreg_extract = "NO"  *) reg     [31:0]  aw4_int32_res_H;                                                                                                        
(* shreg_extract = "NO"  *) reg     [31:0]  aw4_int16_res_A;                                                              
(* shreg_extract = "NO"  *) reg     [31:0]  aw4_int16_res_B;
(* shreg_extract = "NO"  *) reg     [48:0]  aw4_int_add_a;
(* shreg_extract = "NO"  *) reg     [48:0]  aw4_int_add_b;
                            wire    [48:0]  aw4x_res_add;
(* shreg_extract = "NO"  *) reg     [31:0]  aw4_int_add_res; 
(* shreg_extract = "NO"  *) reg     [ 3:0]  aw4_res_mux;                                                        
//==============================================================================================
// stage bw5 (5) prepering results for wb0
//============================================================================================== 
(* shreg_extract = "NO"  *) reg             bw5_stb0;     
(* shreg_extract = "NO"  *) reg             bw5_stb1;     
(* shreg_extract = "NO"  *) reg     [ 4:0]  bw5_addr;     
                        
(* shreg_extract = "NO"  *) reg     [ 1:0]  bw5_enaA;
(* shreg_extract = "NO"  *) reg             bw5_tagA;        
    
(* shreg_extract = "NO"  *) reg     [ 1:0]  bw5_enaB; 
(* shreg_extract = "NO"  *) reg             bw5_tagB; 
(* shreg_extract = "NO"  *) reg             bw5_modB;  
    
(* shreg_extract = "NO"  *) reg     [31:0]  bw5_dataL;
(* shreg_extract = "NO"  *) reg     [31:0]  bw5_dataH;                           
//==============================================================================================                                                                                                                      
generate                                                                                                               
if((DSP == "DSP48A1") || (DSP == "MUL18x18"))
    begin : spartan6_mul_op_abcd
        // mul input data a                                                                                                                        
        assign       ix_mul_opa =(f_int16_stb && f_op_signed)?  {{ 3{i_r0_data[31]}}, i_r0_data[31: 0]}: //{19{i_r0_data[15]}, i_r0_data[15: 0]} 
                                 (f_int16_stb &&!f_op_signed)?  {  3'd0,              i_r0_data[31: 0]}: //{19'd0,             i_r0_data[15: 0]} 
                                 (f_int32_stb && f_op_signed)?  {{ 3{i_r0_data[31]}}, i_r0_data[31: 0]}: // first operand fits into multiplyer input (36x25)
                                 (f_int32_stb &&!f_op_signed)?  {  3'd0,              i_r0_data[31: 0]}: // first operand fits into multiplyer input (36x25) 
                                                                                                 32'd0;   
        // mul input data b                                                                                                                    
        assign       ix_mul_opb =(f_int16_stb && f_op_signed)?  {{ 2{i_r2_data[15]}}, i_r2_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  2'd0,              i_r2_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {  1'd0,              i_r2_data[16: 0]}: // lower 17 bits form 32 bit int - NO sign extended!
                                 (f_int32_stb &&!f_op_signed)?  {  1'd0,              i_r2_data[16: 0]}: // lower 17 bits form 32 bit int                               
                                                                                                 32'd0;
        // mul input data c                                                                                                                    
        assign       ix_mul_opc =(f_int16_stb && f_op_signed)?  {{ 3{i_r1_data[31]}}, i_r1_data[31: 0]}: //{19{i_r2_data[15]}, i_r2_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  3'd0,              i_r1_data[31: 0]}: //{19'd0,             i_r2_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {{ 3{i_r1_data[31]}}, i_r1_data[31: 0]}: // first operand fits into multiplyer input (36x25) 
                                 (f_int32_stb &&!f_op_signed)?  {  3'd0,              i_r1_data[31: 0]}: // first operand fits into multiplyer input (36x25) 
                                                                                                 32'd0;  
        // mul input data d                                                                                                                    
        assign       ix_mul_opd =(f_int16_stb && f_op_signed)?  {{ 2{i_r3_data[15]}}, i_r3_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  2'd0,              i_r3_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {{ 3{i_r3_data[31]}}, i_r3_data[31:17]}: // high 15 bits form 32 bit int -  MAKE sign extended!
                                 (f_int32_stb &&!f_op_signed)?  {  3'd0,              i_r3_data[31:17]}: // high 15 bits form 32 bit int                 
                                                                                                  32'd0;      
    end
else  
    begin : mul_op_abcd 
        // mul input data a 
        assign       ix_mul_opa =(f_int16_stb && f_op_signed)?  {{ 3{i_r0_data[31]}}, i_r0_data[31: 0]}: //{19{i_r0_data[15]}, i_r0_data[15: 0]} 
                                 (f_int16_stb &&!f_op_signed)?  {  3'd0,              i_r0_data[31: 0]}: //{19'd0,             i_r0_data[15: 0]} 
                                 (f_int32_stb && f_op_signed)?  {{ 3{i_r0_data[31]}}, i_r0_data[31: 0]}: // first operand fits into multiplyer input (36x25)
                                 (f_int32_stb &&!f_op_signed)?  {  3'd0,              i_r0_data[31: 0]}: // first operand fits into multiplyer input (36x25) 
                                                                                                  32'd0;   
        // mul input data b                                                                                                                    
        assign       ix_mul_opb =(f_int16_stb && f_op_signed)?  {{ 9{i_r2_data[15]}}, i_r2_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  9'd0,              i_r2_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {  1'd0,              i_r2_data[23: 0]}: // lower 23 bits form 32 bit int - NO sign extended!
                                 (f_int32_stb &&!f_op_signed)?  {  1'd0,              i_r2_data[23: 0]}: // lower 23 bits form 32 bit int                
                                                                                                 32'd0;
                // mul input data c                                                                                                                    
        assign       ix_mul_opc =(f_int16_stb && f_op_signed)?  {{ 3{i_r1_data[31]}}, i_r1_data[31: 0]}: //{19{i_r2_data[15]}, i_r2_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  3'd0,              i_r1_data[31: 0]}: //{19'd0,             i_r2_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {{ 3{i_r1_data[31]}}, i_r1_data[31: 0]}: // first operand fits into multiplyer input (36x25) 
                                 (f_int32_stb &&!f_op_signed)?  {  3'd0,              i_r1_data[31: 0]}: // first operand fits into multiplyer input (36x25) 
                                                                                                  32'd0;  
                // mul input data d                                                                                                                    
        assign       ix_mul_opd =(f_int16_stb && f_op_signed)?  {{ 9{i_r3_data[15]}}, i_r3_data[15: 0]}: 
                                 (f_int16_stb &&!f_op_signed)?  {  9'd0,              i_r3_data[15: 0]}: 
                                 (f_int32_stb && f_op_signed)?  {{17{i_r3_data[31]}}, i_r3_data[31:24]}: // high 8 bits form 32 bit int -  MAKE sign extended!
                                 (f_int32_stb &&!f_op_signed)?  { 17'd0,              i_r3_data[31:24]}: // high 8 bits form 32 bit int             
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
                                                        
        .i_arg_35       (a0_mul_opa),     
        .i_arg_18       (a0_mul_opb), 
        
        .o_data         (b3_ab_mul_data)
        );
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x18_DSP48A1 xmul_cd
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (a0_mul_opc),     
        .i_arg_18       (a0_mul_opd),  

        .o_data         (b3_cd_mul_data)
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
                                                        
        .i_arg_35       (a0_mul_opa),     
        .i_arg_18       (a0_mul_opb), 
        
        .o_data         (b3_ab_mul_data)
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
                                                        
        .i_arg_35       (a0_mul_opc),     
        .i_arg_18       (a0_mul_opd),  

        .o_data         (b3_cd_mul_data)
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
                                                        
        .i_arg_35       (a0_mul_opa),     
        .i_arg_25       (a0_mul_opb), 
        
        .o_data         (b3_ab_mul_data)
        );
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x25_DSP48E xmul_cd
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (a0_mul_opc),     
        .i_arg_25       (a0_mul_opd),  
        
        .o_data         (b3_cd_mul_data)
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
                                                        
        .i_arg_35       (a0_mul_opa),     
        .i_arg_25       (a0_mul_opb), 
        
        .o_data         (b3_ab_mul_data)
        );
//-------------------------------------------------------------------------------------- 
        eco32_core_xpu_mul_35x25_DSP48E1 xmul_cd
        (
        .clk            (clk),
        .rst            (rst),
                                                        
        .i_arg_35       (a0_mul_opc),     
        .i_arg_25       (a0_mul_opd),  
        
        .o_data         (b3_cd_mul_data)
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
                                                        
        .i_arg_35       (a0_mul_opa),     
        .i_arg_25       (a0_mul_opb), 
        
        .o_data         (b3_ab_mul_data)
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
                                                        
        .i_arg_35       (a0_mul_opc),     
        .i_arg_25       (a0_mul_opd),  
        
        .o_data         (b3_cd_mul_data)
        );
//-------------------------------------------------------------------------------------- 
    end   
endgenerate      
//----------------------------------------------------------------------------------------------                                              
assign ix_stb = i_stb & !fci_inst_jpf && (f_int16_stb || f_int32_stb); 
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
                                                                                                     
    a0_mul_opa              <=                                                            35'd0;
    a0_mul_opb              <=                                                            25'd0;                                                             
    a0_mul_opc              <=                                                            35'd0;
    a0_mul_opd              <=                                                            25'd0;
    
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
                                                                                                    
    a0_mul_opa              <=                                                       ix_mul_opa;
    a0_mul_opb              <=                                                       ix_mul_opb;                                                             
    a0_mul_opc              <=                                                       ix_mul_opc;
    a0_mul_opd              <=                                                       ix_mul_opd;
    
    a0_ra_data              <=                                                 i_r0_data[31: 0];                                                                                                   
    a0_rb_data              <=                                                 i_r2_data[31: 0];         
    a0_rc_data              <=                                                 i_r1_data[31: 0];    
    a0_rd_data              <=                                                 i_r3_data[31: 0];                                                                                              
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
// stage b (3)
//============================================================================================== 
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
                                                                           
    b3_ra_data              <=                                                a2_ra_data[31: 0];
    b3_rb_data              <=                                                a2_rb_data[31: 0];
    b3_rc_data              <=                                                a2_rc_data[31: 0];
    b3_rd_data              <=                                                a2_rd_data[31: 0]; 
  end                                                                                        
//----------------------------------------------------------------------------------------------                    
// results collection   
generate                                                                                                            
if((DSP == "DSP48A1") || (DSP == "MUL18x18")) 
    begin : m18x18_mul_int32_res
        assign  b3x_int32_res      = {b3_cd_mul_data[49:0] +  {{19{b3_ab_mul_data[48] & b3_op_signed}}, b3_ab_mul_data[48:17]}, b3_ab_mul_data[16:0]}; 
    end
else
    begin : mul_int32_res
        assign  b3x_int32_res      = {b3_cd_mul_data[39:0] +  {{ 8{b3_ab_mul_data[55] & b3_op_signed}}, b3_ab_mul_data[55:24]}, b3_ab_mul_data[23:0]}; 
    end 
endgenerate  
//==============================================================================================  
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                                              
    b3_wb_A_ena             <=                                                             1'd0; 
    b3_wb_B_ena             <=                                                             1'd0;
    b3_wb_BA_ena            <=                                                             1'd0;
  end
 else  
  begin                                                                                      
    b3_wb_A_ena            <=           ((a2_int16_stb           && a2_dst_ena[0]) || 
                                         (a2_int32_stb           && a2_dst_ena[0]));   
    b3_wb_B_ena            <=           ((a2_int16_stb           && a2_dst_ena[1]) || 
                                         (a2_int32_stb           && a2_dst_ena[1]));
    b3_wb_BA_ena           <=           ((a2_int16_stb           && a2_dst_ena[0] && a2_dst_ena[1]) || 
                                         (a2_int32_stb           && a2_dst_ena[0] && a2_dst_ena[1]));
  end                                                                                                                                                                                               
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
    
    aw4_int32_res_L          <=                                                           32'd0;                                                                                                       
    aw4_int32_res_H          <=                                                           32'd0;                                                                                                       
    aw4_int16_res_A          <=                                                           32'd0;                                                              
    aw4_int16_res_B          <=                                                           32'd0;
                          
    aw4_int_add_res          <=                                                           32'd0;
    aw4_res_mux              <=                                                            4'd0;
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
    
    case(b3_int16_add)                                                      
    1'b0:  aw4_int_add_res   <=                    b3_ab_mul_data[48: 0] - b3_cd_mul_data[48: 0]; // mul16sub
    1'b1:  aw4_int_add_res   <=                    b3_ab_mul_data[48: 0] + b3_cd_mul_data[48: 0]; // mul16add, lea
    endcase     
    
    aw4_int32_res_L          <=                                             b3x_int32_res[31: 0];                                                                                                       
    aw4_int32_res_H          <=                                             b3x_int32_res[63:32];                                                                                                       
    aw4_int16_res_A          <=                                             b3_ab_mul_data[31:0];                                                             
    aw4_int16_res_B          <=                                             b3_cd_mul_data[31:0];
    
    casex({b3_int32_stb, b3_int16_stb, b3_int16_add, b3_int16_sub})  
    4'b1_xxx:  aw4_res_mux   <=                                                       4'd3;// int32
    4'b0_100:  aw4_res_mux   <=                                                       4'd4;// int16
    4'b0_11x:  aw4_res_mux   <=                                                       4'd5;// int16 + , lea, leai
    default:   aw4_res_mux   <=                                                       4'd5;// int16 -  
    endcase                                                                                           
                                                                                                 
    aw4_t0_ena      <=                      (b3_stb && !b3_tid && (b3_wb_A_ena || b3_wb_B_ena));     
    aw4_t1_ena      <=                      (b3_stb &&  b3_tid && (b3_wb_A_ena || b3_wb_B_ena));
                                                                    
    aw4_rg_addr     <=                                                              b3_dst_addr;     
    aw4_tag         <=                                                               b3_dst_tag;    
                                                                    
    aw4_A_ena       <=                                                              b3_wb_A_ena; 
                                                                    
    aw4_B_ena       <=                                                              b3_wb_B_ena;        
    aw4_B_mod       <=                                                             b3_wb_BA_ena; // H:L / B:A mode  
  end                                                                                                                                                                                           
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
    casex(aw4_res_mux)  
    4'd3:   bw5_dataL  <=                                                       aw4_int32_res_L; // int32 L
    4'd4:   bw5_dataL  <=                                                       aw4_int16_res_A; // int16 A
    default:bw5_dataL  <=                                                aw4_int_add_res[31: 0]; // mul16sub             
    endcase  
                                                                                                   
    casex(aw4_res_mux)  
    4'd3:   bw5_dataH  <=                                                       aw4_int32_res_H; // int32 H
    default:bw5_dataH  <=                                                       aw4_int16_res_B; // int16 B 
    endcase                                                                                       
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
// second XPU write back
//==============================================================================================   
assign  wb1_stb0        =                                                                  1'b0;     
assign  wb1_stb1        =                                                                  1'b0;      
assign  wb1_addr        =                                                                  5'd0;      
                                             
assign  wb1_enaA        =                                                                  2'd0; 
assign  wb1_tagA        =                                                                  1'b0;         

assign  wb1_enaB        =                                                                  2'd0; 
assign  wb1_tagB        =                                                                  1'b0; 
assign  wb1_modB        =                                                                  1'b0;  

assign  wb1_dataL       =                                                                 32'd0;
assign  wb1_dataH       =                                                                 32'd0; 
//============================================================================================== 
endmodule                
                         
                         
                         
                         
                         
                         