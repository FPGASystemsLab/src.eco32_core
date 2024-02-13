//==============================================================================================
//    Main contributors
//      - Jakub Siast <jakubsiast@gmail.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                                                                     
//============================================================================================== 
// 3 CLK T multiplication for DSP48E1 - Virtex6, Series 7
//==============================================================================================
module eco32_core_xpu_mul_35x25_DSP48E1
(
 input  wire         clk,
 input  wire         rst,
                                
 input  wire  [24:0] i_arg_25,  // float 1   
 input  wire  [34:0] i_arg_35,  // float 2    
                                                             
 output wire  [59:0] o_data    // maximal [34:0] x [24:0] multiplication
);
//==============================================================================================
// variables
//==============================================================================================
wire    [47:0] s1_res_l; 
wire    [47:0] s0_bp_l; 
//---------------------------------------------------------------------------------------------- 
reg     [16:0] s2_res_l;   
wire    [47:0] s2_res_h; 
//==============================================================================================  
wire    [24:0] arg_ah   =                                                      i_arg_25[24: 0] ;
wire    [17:0] arg_bl   =                                               { 1'd0,i_arg_35[16: 0]}; 
wire    [17:0] arg_bh   =                                                      i_arg_35[34:17] ;  
//----------------------------------------------------------------------------------------------
DSP48E1 
#
(
    .ALUMODEREG         (0),
    .AUTORESET_PATDET   ("NO_RESET"),             

    .ACASCREG           (1),
    .AREG               (1),
    .A_INPUT            ("DIRECT"),
    
    .ADREG              (0),
    
    .BCASCREG           (1),
    .BREG               (1),
    .B_INPUT            ("DIRECT"),

    .CARRYINREG         (0),
    .CARRYINSELREG      (0),
    .CREG               (0),
    .MASK               (48'h3FFFFFFFFFFF),
    .MREG               (0),    
    
    .DREG               (0),
    
    .INMODEREG          (0),
    
    .OPMODEREG          (0),

    .PATTERN            (48'h000000000000),
    .PREG               (1),
    .SEL_MASK           ("MASK"),
    .SEL_PATTERN        ("PATTERN"),    
    .USE_DPORT          ("FALSE"),
    .USE_MULT           ("MULTIPLY"),
    .USE_PATTERN_DETECT ("NO_PATDET"),
    .USE_SIMD           ("ONE48")
)
mul_l
(
.CLK           (clk), 

.CARRYCASCOUT  (), 
.CARRYOUT      (), 
.MULTSIGNOUT   (), 
.OVERFLOW      (), 


.ACIN          (30'd0), 
.A             ({5'd0, arg_ah}), 
.ACOUT         (), 

.BCIN          (18'd0), 
.B             (arg_bl), 
.BCOUT         (), 

.C             (48'd0),
.CARRYCASCIN   (1'd0), 
.CARRYIN       (1'd0), 
.CARRYINSEL    (3'd0),  

.D             (25'd0),

.INMODE        (5'd0), 

.CEA1          (1'b0), 
.CEA2          (1'b1),
.CEAD          (1'b0), 
.CEALUMODE     (1'b0), 
.CEB1          (1'b0), 
.CEB2          (1'b1), 
.CEC           (1'b0), 
.CECARRYIN     (1'b0), 
.CECTRL        (1'b0), 
.CED           (1'b0),
.CEINMODE      (1'b0), 
.CEM           (1'b0), 
                         
.CEP           (1'b1), 
.MULTSIGNIN    (1'b0), 

.OPMODE        ({7'b011_01_01}), // mux Z = C, mux X&Y = M(ul)

.PCIN          (48'd0), 

.ALUMODE       (4'd0),  // sum
.P             (s1_res_l), 

.PATTERNBDETECT(), 
.PATTERNDETECT (), 
.PCOUT         (s0_bp_l), 
.UNDERFLOW     (), 

.RSTA          (rst), 
.RSTALLCARRYIN (1'b0), 
.RSTALUMODE    (1'b0), 
.RSTB          (rst), 
.RSTC          (1'b0), 
.RSTCTRL       (1'b0),
.RSTD          (1'b0),     
.RSTINMODE     (1'b0),  
.RSTM          (1'b0), 
.RSTP          (rst)
); 
//==============================================================================================
DSP48E1 
#
(
    .ALUMODEREG         (0),
    .AUTORESET_PATDET   ("NO_RESET"),             

    .ACASCREG           (1),
    .AREG               (1),
    .A_INPUT            ("DIRECT"),

    .ADREG              (0),
    
    .BCASCREG           (1),
    .BREG               (1),
    .B_INPUT            ("DIRECT"),

    .CARRYINREG         (0),
    .CARRYINSELREG      (0),
    .CREG               (1),
    .MASK               (48'h3FFFFFFFFFFF),
    .MREG               (1),       

    .DREG               (0),
    
    .INMODEREG          (0),
    
    .OPMODEREG          (0),

    .PATTERN            (48'h000000000000),
    .PREG               (1),
    .SEL_MASK           ("MASK"),
    .SEL_PATTERN        ("PATTERN"),     
    .USE_DPORT          ("FALSE"),
    .USE_MULT           ("MULTIPLY"),
    .USE_PATTERN_DETECT ("NO_PATDET"),
    .USE_SIMD           ("ONE48")
)
mul_h
(
.CLK           (clk), 

.CARRYCASCOUT  (), 
.CARRYOUT      (), 
.MULTSIGNOUT   (), 
.OVERFLOW      (), 


.ACIN          (30'd0), 
.A             ({5'd0, arg_ah}), 
.ACOUT         (), 

.BCIN          (18'd0), 
.B             (arg_bh), 
.BCOUT         (), 

.C             (48'd0),   
.CARRYCASCIN   (1'd0), 
.CARRYIN       (1'd0), 
.CARRYINSEL    (3'd0), 

.D             (25'd0),

.INMODE        (5'd0), 

.CEA1          (1'b0), 
.CEA2          (1'b1), 
.CEAD          (1'b0), 
.CEALUMODE     (1'b0), 
.CEB1          (1'b0), 
.CEB2          (1'b1), 
.CEC           (1'b1), 
.CECARRYIN     (1'b0), 
.CECTRL        (1'b0), 
.CED           (1'b0),
.CEINMODE      (1'b0),
.CEM           (1'b1), 
                         
.CEP           (1'b1), 
.MULTSIGNIN    (1'b0),  

.OPMODE        ({7'b101_01_01}),// mux Z = 17bit shift PCIN, mux X&Y = M(ul) 

.PCIN          (s0_bp_l), 

.ALUMODE       (4'd0), // sum
.P             (s2_res_h), 

.PATTERNBDETECT(), 
.PATTERNDETECT (), 
.PCOUT         (), 
.UNDERFLOW     (), 

.RSTA          (rst), 
.RSTALLCARRYIN (1'b0), 
.RSTALUMODE    (1'b0), 
.RSTB          (rst), 
.RSTC          (rst), 
.RSTCTRL       (1'b0),
.RSTD          (1'b0),     
.RSTINMODE     (1'b0),   
.RSTM          (rst), 
.RSTP          (rst)
);                                                                                                
//---------------------------------------------------------------------------------------------- 
 always@(posedge clk)
            s2_res_l            <=                                               s1_res_l[16:0]; 
//==============================================================================================
// output
//==============================================================================================
assign      o_data              =                                    {s2_res_h[45:0], s2_res_l};
//==============================================================================================
endmodule                                                                                           



//============================================================================================== 
// 3 CLK T multiplication for DSP48E - Virtex5
//==============================================================================================
module eco32_core_xpu_mul_35x25_DSP48E
(
 input  wire         clk,
 input  wire         rst,
                                
 input  wire  [24:0] i_arg_25,  // float 1   
 input  wire  [34:0] i_arg_35,  // float 2    
                                                             
 output wire  [59:0] o_data    // maximal [34:0] x [24:0] multiplication
);
//==============================================================================================
// variables
//==============================================================================================
wire    [47:0] s1_res_l; 
wire    [47:0] s0_bp_l; 
//---------------------------------------------------------------------------------------------- 
reg     [16:0] s2_res_l;   
wire    [47:0] s2_res_h; 
//==============================================================================================  
wire    [24:0] arg_ah   =                                                      i_arg_25[24: 0] ;
wire    [17:0] arg_bl   =                                               { 1'd0,i_arg_35[16: 0]}; 
wire    [17:0] arg_bh   =                                                      i_arg_35[34:17] ;  
//----------------------------------------------------------------------------------------------
DSP48E 
#
(
    .ALUMODEREG         (0),
    .AUTORESET_PATTERN_DETECT        ("FALSE"), 
    .AUTORESET_PATTERN_DETECT_OPTINV ("MATCH"),

    .ACASCREG           (1),
    .AREG               (1),
    .A_INPUT            ("DIRECT"),

    .BCASCREG           (1),
    .BREG               (1),
    .B_INPUT            ("DIRECT"),

    .CARRYINREG         (0),
    .CARRYINSELREG      (0),
    .CREG               (0),
    .MASK               (48'h3FFFFFFFFFFF),
    .MREG               (0),
    .MULTCARRYINREG     (0),

    .OPMODEREG          (0),

    .PATTERN            (48'h000000000000),
    .PREG               (1),
    .SEL_MASK           ("MASK"),
    .SEL_PATTERN        ("PATTERN"),
    .SEL_ROUNDING_MASK  ("SEL_MASK"),
    .USE_MULT           ("MULT"),
    .USE_PATTERN_DETECT ("NO_PATDET"),
    .USE_SIMD           ("ONE48")
)
mul_l
(
.CLK           (clk), 

.CARRYCASCOUT  (), 
.CARRYOUT      (), 
.MULTSIGNOUT   (), 
.OVERFLOW      (), 


.ACIN          (30'd0), 
.A             ({5'd0, arg_ah}), 
.ACOUT         (), 

.BCIN          (18'd0), 
.B             (arg_bl), 
.BCOUT         (), 

.C             (48'd0),
.CARRYCASCIN   (1'd0), 
.CARRYIN       (1'd0), 
.CARRYINSEL    (3'd0), 

.CEA1          (1'b0), 
.CEA2          (1'b1), 
.CEALUMODE     (1'b0), 
.CEB1          (1'b0), 
.CEB2          (1'b1), 
.CEC           (1'b0), 
.CECARRYIN     (1'b0), 
.CECTRL        (1'b0), 
.CEM           (1'b0), 

.CEMULTCARRYIN (1'b0), 
.CEP           (1'b1), 
.MULTSIGNIN    (1'b0), 

.OPMODE        ({7'b011_01_01}), // mux Z = C, mux X&Y = M(ul)

.PCIN          (48'd0), 

.ALUMODE       (4'd0),  // sum
.P             (s1_res_l), 

.PATTERNBDETECT(), 
.PATTERNDETECT (), 
.PCOUT         (s0_bp_l), 
.UNDERFLOW     (), 

.RSTA          (rst), 
.RSTALLCARRYIN (1'b0), 
.RSTALUMODE    (1'b0), 
.RSTB          (rst), 
.RSTC          (1'b0), 
.RSTCTRL       (1'b0), 
.RSTM          (1'b0), 
.RSTP          (rst)
); 
//==============================================================================================
DSP48E 
#
(
    .ALUMODEREG         (0),
    .AUTORESET_PATTERN_DETECT        ("FALSE"), 
    .AUTORESET_PATTERN_DETECT_OPTINV ("MATCH"),

    .ACASCREG           (1),
    .AREG               (1),
    .A_INPUT            ("DIRECT"),

    .BCASCREG           (1),
    .BREG               (1),
    .B_INPUT            ("DIRECT"),

    .CARRYINREG         (0),
    .CARRYINSELREG      (0),
    .CREG               (1),
    .MASK               (48'h3FFFFFFFFFFF),
    .MREG               (1),
    .MULTCARRYINREG     (0),

    .OPMODEREG          (0),

    .PATTERN            (48'h000000000000),
    .PREG               (1),
    .SEL_MASK           ("MASK"),
    .SEL_PATTERN        ("PATTERN"),
    .SEL_ROUNDING_MASK  ("SEL_MASK"),
    .USE_MULT           ("MULT_S"),
    .USE_PATTERN_DETECT ("NO_PATDET"),
    .USE_SIMD           ("ONE48")
)
mul_h
(
.CLK           (clk), 

.CARRYCASCOUT  (), 
.CARRYOUT      (), 
.MULTSIGNOUT   (), 
.OVERFLOW      (), 


.ACIN          (30'd0), 
.A             ({5'd0, arg_ah}), 
.ACOUT         (), 

.BCIN          (18'd0), 
.B             (arg_bh), 
.BCOUT         (), 

.C             (48'd0),   
.CARRYCASCIN   (1'd0), 
.CARRYIN       (1'd0), 
.CARRYINSEL    (3'd0), 

.CEA1          (1'b0), 
.CEA2          (1'b1), 
.CEALUMODE     (1'b0), 
.CEB1          (1'b0), 
.CEB2          (1'b1), 
.CEC           (1'b1), 
.CECARRYIN     (1'b0), 
.CECTRL        (1'b0), 
.CEM           (1'b1), 

.CEMULTCARRYIN (1'b0), 
.CEP           (1'b1), 
.MULTSIGNIN    (1'b0),  

.OPMODE        ({7'b101_01_01}),// mux Z = 17bit shift PCIN, mux X&Y = M(ul) 

.PCIN          (s0_bp_l), 

.ALUMODE       (4'd0), // sum
.P             (s2_res_h), 

.PATTERNBDETECT(), 
.PATTERNDETECT (), 
.PCOUT         (), 
.UNDERFLOW     (), 

.RSTA          (rst), 
.RSTALLCARRYIN (1'b0), 
.RSTALUMODE    (1'b0), 
.RSTB          (rst), 
.RSTC          (rst), 
.RSTCTRL       (1'b0), 
.RSTM          (rst), 
.RSTP          (rst)
);                                                                                               
//---------------------------------------------------------------------------------------------- 
 always@(posedge clk)
            s2_res_l            <=                                               s1_res_l[16:0]; 
//==============================================================================================
// output
//==============================================================================================
assign      o_data              =                                    {s2_res_h[45:0], s2_res_l};
//==============================================================================================
endmodule                                                                                           
                                                                                            
                                                                                  
//==============================================================================================
// 3 CLK T multiplication for definition by *                                                                                     
//==============================================================================================
(* multstyle = "dsp" *) module eco32_core_xpu_mul_35x25_def
(
 input  wire         clk,
 input  wire         rst,
                                
 input  wire signed  [24:0] i_arg_25,  // float 1   
 input  wire signed  [34:0] i_arg_35,  // float 2    
                                                             
 output wire signed  [59:0] o_data    // maximal [34:0] x [24:0] multiplication
) /*synthesis syn_allow_retiming=1 */;
//==============================================================================================
//  params
//==============================================================================================
parameter               FORCE_RST   =     0;
//==============================================================================================
// variables
//==============================================================================================
reg signed     [59:0] s1_res /* synthesis syn_pipeline=1 */;
reg signed     [59:0] s2_res /* synthesis syn_pipeline=1 */;    
reg signed     [59:0] s3_res /* synthesis syn_pipeline=1 */;                                                  
//==============================================================================================   
 always@(posedge rst or posedge clk)
  if(rst)   s1_res              <=                                                        60'd0;
  else      s1_res              <=                                          i_arg_25 * i_arg_35;   
 always@(posedge rst or posedge clk)
  if(rst)   s2_res              <=                                                        60'd0;
  else      s2_res              <=                                                       s1_res;  
 always@(posedge rst or posedge clk)
  if(rst)   s3_res              <=                                                        60'd0;
  else      s3_res              <=                                                       s2_res; 
//============================================================================================== 
assign o_data = s3_res;
//============================================================================================== 
endmodule                                                                                           
                                                                                            
//XPU w synplify dla dla mnoarki 35x25 w Virtex6: 
//instancje DSP :  LUT 209 REG 381 CLK 510    pipeline 2 
//operacja '*'  :  LUT 345 REG 459 CLK 272    pipeline 2 
//operacja '*'  :  LUT 404 REG 669 CLK 407    pipeline 3                                                                                           
                                                                                            
                                                                                            