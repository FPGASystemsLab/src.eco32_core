//==============================================================================================
//    Main contributors
//      - Jakub Siast <jakubsiast@gmail.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
(* multstyle = "dsp" *) module eco32_core_xpu_mul_35x18_def
(
 input  wire         clk,
 input  wire         rst,
                                
 input  wire  [17:0] i_arg_18,  // float get just 17 bits for spartan 6 DSP   
 input  wire  [34:0] i_arg_35,  // float 2    
                                                             
 output wire  [59:0] o_data    // maximal [34:0] x [24:0] multiplication
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
//reg signed     [59:0] s3_res /* synthesis syn_pipeline=1 */;  
//reg signed     [59:0] s4_res /* synthesis syn_pipeline=1 */;                                                
//==============================================================================================   
 always@(posedge rst or posedge clk)
  if(rst)   s1_res              <=                                                        60'd0;
  else      s1_res              <=                                          i_arg_18 * i_arg_35;   
 always@(posedge rst or posedge clk)
  if(rst)   s2_res              <=                                                        60'd0;
  else      s2_res              <=                                                       s1_res;  
// always@(posedge rst or posedge clk)
//  if(rst)   s3_res              <=                                                        60'd0;
//  else      s3_res              <=                                                       s2_res;  
// always@(posedge rst or posedge clk)
//  if(rst)   s4_res              <=                                                        60'd0;
//  else      s4_res              <=                                                       s3_res; 
//============================================================================================== 
assign o_data = s2_res;
//============================================================================================== 
endmodule                                                                                        
                                                                                            
                                                                                            
               
//XPU w synplify dla mnoarki 35x18 w Spartan6: 
//instancje DSP :  LUT 208 REG 363 CLK 313    pipeline 2 
//operacja '*'  :  LUT 519 REG 685 CLK 277    pipeline 2 
//operacja '*'  :  LUT 518 REG 786 CLK 277    pipeline 3 
//operacja '*'  :  LUT 521 REG 933 CLK 277    pipeline 4                                                                              
                                                                                            
                                                                                            