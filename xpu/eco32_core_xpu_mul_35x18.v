//==============================================================================================
//    Main contributors
//      - Jakub Siast <jakubsiast@gmail.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                                                                             
//==============================================================================================
// 3 CLK T multiplication for DSP48A1 - Spartan 6
//==============================================================================================
module eco32_core_xpu_mul_35x18_DSP48A1
(
 input  wire         clk,
 input  wire         rst,
                                
 input  wire  [17:0] i_arg_18,  // float get just 17 bits for spartan 6 DSP   
 input  wire  [34:0] i_arg_35,  // float 2    
                                                             
 output wire  [59:0] o_data    // maximal [34:0] x [24:0] multiplication
);
//==============================================================================================
// variables
//==============================================================================================
//wire    [47:0] s1_res_l;  
//----------------------------------------------------------------------------------------------   
wire    [35:0] s1_res_l;
wire    [47:0] s1_res_l_shifted17;
reg     [16:0] s2_res_l;   
wire    [47:0] s2_res_h; 
//==============================================================================================  
wire    [17:0] arg_a    =                                                      i_arg_18[17: 0] ;
wire    [17:0] arg_bl   =                                               { 1'd0,i_arg_35[16: 0]}; 
wire    [17:0] arg_bh   =                                                      i_arg_35[34:17] ;  
//----------------------------------------------------------------------------------------------
//DSP48A1 
//#
//(                                                               
//.A0REG              (0), // first  A register                           
//.A1REG              (1), // second A register 
//.B0REG              (0), // first  B register                           
//.B1REG              (1), // second B register
//.CREG               (0), // C register
//.CARRYINREG         (0), // Carry in register  
//.DREG               (0), // D register
//.PREG               (0), // main output P register     
//.MREG               (1), // output from bufor register following multiplier
//                                              
//.OPMODEREG          (0), // arithmetic operations mode register                               
//.CARRYINREG         (0), // carry in register 
//.CARRYINSEL           ("CARRYIN"),    //selects the post adder/subtracter carry-in signal
//
//.RSTTYPE          ("SYNC") // synchronous reset (improved timing and circuit stability)
//)
//mul_l
//(                                 
//.CLK           (clk),  
//
//.A             (arg_a ),  // 18-bit data input to multiplier
//.B             (arg_bl),    // 18-bit data input to multiplier
//.C             (48'd0),       // 48-bit data input to post-adder/subtracter
//.CCOUT         (),            // Cascade output of the output carry register
//.CFOUT         (),            // Carry out signal for use in the FPGA logic
//.CIN           (),            // Cascaded, external carry input to the post-adder/subtracter
//.D             (18'd0),       // 18-bit data input to pre-adder/subtracter
//
//.MFOUT         (s1_res_l),    // 36-bit buffered multiplier data output, routable to the FPGA logic
//.P             (),            // Primary data output
//                                                  
//.OPMODE        ({8'b0_0_0_0_00_00}), // mux Z = C, mux X&Y = M(ul) ,                                          
////[7]post-adder/subtracter is an adder or subtracter: 0 but don't care (we don't use pre-adder
////[6]pre-adder/subtracter is an adder or subtracter: 0 but don't care (we don't use pre-adder
////[5]Forces a value on the carry input of the carry-in register (CYI) to the post-adder. Only applicable when CARRYINSEL = OPMODE5
////[4]use of the pre-adder/subtracter: 0  Bypass the pre-adder supplying the data on port B directly to the multiplier
////[3:2]source of the Z input to the post-adder/subtracter: 00 - Specifies to place all zeros (disable the post-adder/subtracter and propagate the multiplier product to P)
////[1:0]source of the X input to the post-adder/subtracter: 00  Specifies to place all zeros (disable the post-adder/subtracter)
//                                                                                     
//.CEA           (1'b1), // clock enable for A port registers   
//.CEB           (1'b1), // clock enable for B port registers    
//.CEC           (1'b0), // clock enable for C port registers
//.CECY          (1'b0), // clock enable for Carry in and Carry out registers   
//.CED           (1'b0), // clock enable for D port registers                    
//.CEM           (1'b1), // clock enable for M output port registers    
//  
//.CEO           (1'b0), // clock enable for OPMODE port registers 
//.CEP           (1'b0), // clock enable for P (main) output port registers 
//   
//.RSTA          (rst), 
//.RSTB          (rst), 
//.RSTC          (1'b0),
//.RSTCY         (1'b0), 
//.RSTD          (1'b0),
//.RSTM          (rst), 
//.RSTO          (1'b0), 
//.RSTP          (1'b0),  
//              
//.BCIN          (18'd0),  
//.BCOUT         (),         
//
//.PCIN          (48'd0),  
//.PCOUT         ()
//);                                                                                                                                                                      
////============================================================================================== 
//assign s1_res_l_shifted17 = {{29{s1_res_l[35]}},s1_res_l[35:17]};
////==============================================================================================
//DSP48A1 
//#
//(                                                               
//.A0REG              (0), // first  A register                           
//.A1REG              (1), // second A register 
//.B0REG              (0), // first  B register                           
//.B1REG              (1), // second B register
//.CREG               (0), // C register
//.CARRYINREG         (0), // Carry in register  
//.DREG               (0), // D register
//.PREG               (1), // main output P register     
//.MREG               (1), // output from bufor register following multiplier
//                                              
//.OPMODEREG          (0), // arithmetic operations mode register                               
//.CARRYINREG         (0), // carry in register 
//.CARRYINSEL           ("CARRYIN"),    //selects the post adder/subtracter carry-in signal
//
//.RSTTYPE          ("SYNC") // synchronous reset (improved timing and circuit stability)
//)
//mul_h
//(                                 
//.CLK           (clk),  
//
//.A             (arg_a ),  // 18-bit data input to multiplier
//.B             (arg_bl),    // 18-bit data input to multiplier
//.C             (s1_res_l_shifted17), // 48-bit data input to post-adder/subtracter
//.CCOUT         (),            // Cascade output of the output carry register
//.CFOUT         (),            // Carry out signal for use in the FPGA logic
//.CIN           (),            // Cascaded, external carry input to the post-adder/subtracter
//.D             (),            // 18-bit data input to pre-adder/subtracter
//
//.MFOUT         (),            // 36-bit buffered multiplier data output, routable to the FPGA logic
//.P             (s2_res_h),    // Primary data output
//                                                  
//.OPMODE        ({8'b0_0_0_0_11_01}), // mux Z = C, mux X&Y = M(ul) ,                                          
////[7]post-adder/subtracter is an adder or subtracter: 0 Specifies post-adder/subtracter to perform an addition operation
////[6]pre-adder/subtracter is an adder or subtracter: 0 but don't care (we don't use pre-adder
////[5]Forces a value on the carry input of the carry-in register (CYI) to the post-adder. Only applicable when CARRYINSEL = OPMODE5
////[4]use of the pre-adder/subtracter: 0  Bypass the pre-adder supplying the data on port B directly to the multiplier
////[3:2]source of the Z input to the post-adder/subtracter: 11 - Use the C port
////[1:0]source of the X input to the post-adder/subtracter: 01  Use the multiplier product
//                                                                                     
//.CEA           (1'b1), // clock enable for A port registers   
//.CEB           (1'b1), // clock enable for B port registers    
//.CEC           (1'b0), // clock enable for C port registers
//.CECY          (1'b0), // clock enable for Carry in and Carry out registers   
//.CED           (1'b0), // clock enable for D port registers                    
//.CEM           (1'b1), // clock enable for M output port registers    
//  
//.CEO           (1'b0), // clock enable for OPMODE port registers 
//.CEP           (1'b1), // clock enable for P (main) output port registers 
//   
//.RSTA          (rst), 
//.RSTB          (rst), 
//.RSTC          (1'b0),
//.RSTCY         (1'b0), 
//.RSTD          (1'b0),
//.RSTM          (rst), 
//.RSTO          (1'b0), 
//.RSTP          (rst),  
//              
//.BCIN          (18'd0),  
//.BCOUT         (),         
//
//.PCIN          (48'd0),  
//.PCOUT         ()
//);                                
DSP48A1 
#
(                                                                 
.A0REG              (0), // first  A register                             
.A1REG              (1), // second A register 
.B0REG              (0), // first  B register                             
.B1REG              (1), // second B register
.CREG               (0), // C register
.CARRYINREG         (0), // Carry in register 
.CARRYOUTREG        (0), // Carry out register  
.DREG               (0), // D register
.PREG               (0), // main output P register   
.MREG               (1), // output from bufor register following multiplier
                                                
.OPMODEREG          (0), // arithmetic operations mode register                             
//.CARRYINREG         (0), // carry in register 
.CARRYINSEL         ("OPMODE5"),    //selects the post adder/subtracter carry-in signal

.RSTTYPE            ("SYNC") // synchronous reset (improved timing and circuit stability)
)
mul_l
(                                   
.CLK           (clk),  

.A             (arg_a ),    // 18-bit data input to multiplier
.B             (arg_bl),    // 18-bit data input to multiplier
.C             (48'd0),     // 48-bit data input to post-adder/subtracter
.CARRYOUT      (),          // Cascade output of the output carry register
.CARRYOUTF     (),          // Carry out signal for use in the FPGA logic
.CARRYIN       (),          // Cascaded, external carry input to the post-adder/subtracter
.D             (18'd0),     // 18-bit data input to pre-adder/subtracter

.M             (s1_res_l),  // 36-bit buffered multiplier data output, routable to the FPGA logic
.P             (),          // Primary data output
                                                    
.OPMODE        ({8'b0_0_0_0_00_00}), // mux Z = C, mux X&Y = M(ul) ,                                            
//[7]post-adder/subtracter is an adder or subtracter: 0 but don't care (we don't use pre-adder
//[6]pre-adder/subtracter is an adder or subtracter: 0 but don't care (we don't use pre-adder
//[5]Forces a value on the carry input of the carry-in register (CYI) to the post-adder. Only applicable when CARRYINSEL = OPMODE5
//[4]use of the pre-adder/subtracter: 0  Bypass the pre-adder supplying the data on port B directly to the multiplier
//[3:2]source of the Z input to the post-adder/subtracter: 00 - Specifies to place all zeros (disable the post-adder/subtracter and propagate the multiplier product to P)
//[1:0]source of the X input to the post-adder/subtracter: 00  Specifies to place all zeros (disable the post-adder/subtracter)
                                                                                       
.CEA           (1'b1), // clock enable for A port registers 
.CEB           (1'b1), // clock enable for B port registers  
.CEC           (1'b0), // clock enable for C port registers
.CECARRYIN     (1'b0), // clock enable for Carry in and Carry out registers 
.CED           (1'b0), // clock enable for D port registers                  
.CEM           (1'b1), // clock enable for M output port registers  
    
.CEOPMODE      (1'b0), // clock enable for OPMODE port registers 
.CEP           (1'b0), // clock enable for P (main) output port registers   
     
.RSTA          (rst), 
.RSTB          (rst), 
.RSTC          (1'b0),
.RSTCARRYIN    (1'b0), 
.RSTD          (1'b0),
.RSTM          (rst), 
.RSTOPMODE     (1'b0), 
.RSTP          (1'b0),  
                
//.BCIN          (18'd0),  
.BCOUT         (),       

.PCIN          (48'd0),  
.PCOUT         ()
);                                                                                                                                                                    
//==============================================================================================   
//assign s1_res_l_shifted17 = {29'd0,s1_res_l[35:17]};
assign s1_res_l_shifted17 = {{30{s1_res_l[34]}},s1_res_l[34:17]};
//==============================================================================================
DSP48A1 
#
(                                                                 
.A0REG              (0), // first  A register                             
.A1REG              (1), // second A register 
.B0REG              (0), // first  B register                             
.B1REG              (1), // second B register
.CREG               (0), // C register
.CARRYINREG         (0), // Carry in register 
.CARRYOUTREG        (0), // Carry out register 
.DREG               (0), // D register
.PREG               (1), // main output P register   
.MREG               (1), // output from bufor register following multiplier
                                                
.OPMODEREG          (0), // arithmetic operations mode register                             
//.CARRYINREG         (0), // carry in register 
.CARRYINSEL         ("OPMODE5"),    //selects the post adder/subtracter carry-in signal

.RSTTYPE            ("SYNC") // synchronous reset (improved timing and circuit stability)
)
mul_h
(                                   
.CLK           (clk),  

.A             (arg_a ),    // 18-bit data input to multiplier
.B             (arg_bh),    // 18-bit data input to multiplier
.C             (s1_res_l_shifted17), // 48-bit data input to post-adder/subtracter
.CARRYOUT      (),          // Cascade output of the output carry register
.CARRYOUTF     (),          // Carry out signal for use in the FPGA logic
.CARRYIN       (),          // Cascaded, external carry input to the post-adder/subtracter
.D             (),          // 18-bit data input to pre-adder/subtracter

.M             (),          // 36-bit buffered multiplier data output, routable to the FPGA logic
.P             (s2_res_h),  // Primary data output
                                                    
.OPMODE        ({8'b0_0_0_0_11_01}),                                        
//[7]post-adder/subtracter is an adder or subtracter: 0 Specifies post-adder/subtracter to perform an addition operation
//[6]pre-adder/subtracter is an adder or subtracter: 0 but don't care (we don't use pre-adder
//[5]Forces a value on the carry input of the carry-in register (CYI) to the post-adder. Only applicable when CARRYINSEL = OPMODE5
//[4]use of the pre-adder/subtracter: 0  Bypass the pre-adder supplying the data on port B directly to the multiplier
//[3:2]source of the Z input to the post-adder/subtracter: 11 - Use the C port
//[1:0]source of the X input to the post-adder/subtracter: 01  Use the multiplier product
                                                                                       
.CEA           (1'b1), // clock enable for A port registers 
.CEB           (1'b1), // clock enable for B port registers  
.CEC           (1'b0), // clock enable for C port registers    
.CECARRYIN     (1'b0), // clock enable for Carry in and Carry out registers 
.CED           (1'b0), // clock enable for D port registers                  
.CEM           (1'b1), // clock enable for M output port registers  
                                                                                                                
.CEOPMODE      (1'b0), // clock enable for OPMODE port registers 
.CEP           (1'b1), // clock enable for P (main) output port registers   
     
.RSTA          (rst), 
.RSTB          (rst), 
.RSTC          (1'b0), 
.RSTCARRYIN    (1'b0), 
.RSTD          (1'b0),
.RSTM          (rst),     
.RSTOPMODE     (1'b0),
.RSTP          (rst),  
                
//.BCIN          (18'd0),  
.BCOUT         (),       

.PCIN          (48'd0),  
.PCOUT         ()
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
reg signed     [59:0] s3_res /* synthesis syn_pipeline=1 */;    
//reg signed     [59:0] s4_res /* synthesis syn_pipeline=1 */;                                                
//==============================================================================================   
 always@(posedge rst or posedge clk)
  if(rst)   s1_res              <=                                                        60'd0;
  else      s1_res              <=                                          i_arg_18 * i_arg_35;   
 always@(posedge rst or posedge clk)
  if(rst)   s2_res              <=                                                        60'd0;
  else      s2_res              <=                                                       s1_res;  
 always@(posedge rst or posedge clk)
  if(rst)   s3_res              <=                                                        60'd0;
  else      s3_res              <=                                                       s2_res;  
// always@(posedge rst or posedge clk)
//  if(rst)   s4_res              <=                                                        60'd0;
//  else      s4_res              <=                                                       s3_res; 
//============================================================================================== 
assign o_data = s3_res;
//============================================================================================== 
endmodule                                                                                        
//XPU w synplify dla mnoarki 35x18 w Spartan6: 
//instancje DSP :  LUT 208 REG 363 CLK 313    pipeline 2 
//operacja '*'  :  LUT 519 REG 685 CLK 277    pipeline 2 
//operacja '*'  :  LUT 518 REG 786 CLK 277    pipeline 3 
//operacja '*'  :  LUT 521 REG 933 CLK 277    pipeline 4                                                                              
                                                                                            
                          
                                                                                            
                                                                                            
                                                                                            
                                                                                            