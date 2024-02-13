//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
module eco32_core_xpu_sh_add_bezDSP
(                                 
 input  wire         clk,
 input  wire         rst,
                                
 input  wire         i_stb,
 
 input  wire  [ 7:0] i_sh_bit,       
 input  wire  [24:0] i_arg_b,     
 input  wire  [24:0] i_arg_a, 
 input  wire         i_sign,  
 
 output wire  [ 7:0] o_exp_decrease,
                             
 output wire  [26:0] o_data,  
 output wire  [ 6:0] o_data_nz_nibble             
);        
//==============================================================================================
//  params
//==============================================================================================
parameter               FORCE_RST   =     0;                                                                                        
//==============================================================================================
// variables
//============================================================================================== 
reg     [ 1:0] s0_arg_a_lsh;       // how many 4 bits position left  shifts to do on arg a
reg     [ 5:0] s0_arg_b_rsh;       // how many 1 bits position right shifts to do on arg b      
reg     [24:0] s0_arg_a; 
reg     [24:0] s0_arg_b;    
//---------------------------------------------------------------------------------------------- 
 always@(posedge clk or posedge rst)
  if(rst)                       s0_arg_a_lsh        <=                                 2'h0;  
  else                          s0_arg_a_lsh        <=                        i_sh_bit[1:0];   
//---------------------------------------------------------------------------------------------- 
 always@(posedge clk or posedge rst)
  if(rst)                       s0_arg_b_rsh        <=                                 6'h0; 
  else                          s0_arg_b_rsh        <=                        i_sh_bit[7:2];  
//---------------------------------------------------------------------------------------------- 
 always@(posedge clk or posedge rst)
  if(rst)                       s0_arg_a            <=                                25'h0; 
  else                          s0_arg_a            <=                        i_arg_a[24:0]; 
//---------------------------------------------------------------------------------------------- 
 always@(posedge clk or posedge rst)
  if(rst)                       s0_arg_b            <=                                25'h0; 
  else if(i_sh_bit > 8'd24)     s0_arg_b            <=                                25'd0; // if exp difference is more than 24 than adding or subtracting should have no result 
  else                          s0_arg_b            <=                        i_arg_b[24:0];    
//==============================================================================================
// variables
//============================================================================================== 
reg     [ 7:0] s1_e_decrease;      // because of shift of arg a left decrease of exp may need to be done        
reg     [24+ 3     :0] s1_arg_a_ls;     // + 3 for zeros
reg     [24+ 3 + 24:0] s1_arg_b_rs;     // +24 for zeros and 3 for sign extention
//---------------------------------------------------------------------------------------------- 
 always@(posedge clk or posedge rst)
  if(rst)
    begin                                                                                       
      s1_arg_a_ls     <=                                                                 43'd0;
      s1_arg_b_rs     <=                                                                 34'd0;
      s1_e_decrease   <=                                                                  8'd0;
    end   
  else
    begin                                                                                           
      case(s0_arg_a_lsh)
      2'b00:     s1_arg_a_ls <=                                        { 3'd0, s0_arg_a       }; 
      2'b01:     s1_arg_a_ls <=                                        { 2'd0, s0_arg_a,  1'd0};
      2'b10:     s1_arg_a_ls <=                                        { 1'd0, s0_arg_a,  2'd0};
      2'b11:     s1_arg_a_ls <=                                        {       s0_arg_a,  3'd0}; 
      endcase   
      case(s0_arg_b_rsh)                                                                           
      6'b000000: s1_arg_b_rs <=                           {{ 3{s0_arg_b[24]}}, s0_arg_b, 24'd0}; 
      6'b000001: s1_arg_b_rs <=                           {{ 7{s0_arg_b[24]}}, s0_arg_b, 20'd0}; 
      6'b000010: s1_arg_b_rs <=                           {{11{s0_arg_b[24]}}, s0_arg_b, 16'd0}; 
      6'b000011: s1_arg_b_rs <=                           {{15{s0_arg_b[24]}}, s0_arg_b, 12'd0}; 
      6'b000100: s1_arg_b_rs <=                           {{19{s0_arg_b[24]}}, s0_arg_b,  8'd0}; 
      //6'b000101: s1_arg_b_rs <=                                          {20'd0, s0_arg_b,  4'd0}; 
      //default:   s1_arg_b_rs <=                                          {24'd0, s0_arg_b       }; //
      default:   s1_arg_b_rs <=                           {{23{s0_arg_b[24]}}, s0_arg_b,  4'd0}; // above two statements can be removed because for s0_arg_b_rsh>5 (shift > 23) s0_arg_b equals zero
      endcase                                                                                       
      s1_e_decrease          <=                                                    s0_arg_a_lsh;
    end                                                                                          
//==============================================================================================   
wire    [27+24:0] s2x_res_a;   
wire    [27+24:0] s2x_res_b;   
wire    [1-1+27+24:0] s2x_res; // 1 for result expansion, -1 because argument a is always positive
                               // and oldest bit will be zero, 27:0 for s1_arg_a_ls, 
                               // and 24 for  s1_arg_a_ls and s1_arg_b_rs    equalization  
reg     [26:0]    s2_res; // result must be on 24 bits (as mantysa has with no sign bit)plus 3 bits because shift on an A argument
wire    [ 6:0]    s2x_nz_nibble_pos;
reg     [ 6:0]    s2_nz_nibble_pos; 
//----------------------------------------------------------------------------------------------   
assign     s2x_res_a                    = {s1_arg_a_ls, 24'd0};     
assign     s2x_res_b                    =                        s1_arg_b_rs;    
assign     s2x_res                      = {s1_arg_a_ls, 24'd0} + s1_arg_b_rs;                                            
assign     s2x_nz_nibble_pos            = {s2x_res[51:49] != 3'd0,  // 
                                           s2x_res[48:45] != 4'd0,
                                           s2x_res[44:41] != 4'd0,
                                           s2x_res[40:37] != 4'd0,
                                           s2x_res[36:33] != 4'd0,
                                           s2x_res[32:29] != 4'd0,
                                           s2x_res[28:25] != 4'd0};  
//---------------------------------------------------------------------------------------------- 
always@(posedge clk or posedge rst)
 if(rst) s2_res      <=                                                                  27'd0;     
 else    s2_res      <=                                                          s2x_res[51:25];      
//----------------------------------------------------------------------------------------------
 always@(posedge clk or posedge rst)
  if(rst) s2_nz_nibble_pos      <=                                                         7'b0; 
  else    s2_nz_nibble_pos      <=                                            s2x_nz_nibble_pos; 
//==============================================================================================
// output
//==============================================================================================  
assign      o_exp_decrease      =                                                 s1_e_decrease;                                                          
//---------------------------------------------------------------------------------------------- 
assign      o_data              =                                                        s2_res; 
assign      o_data_nz_nibble    =                                              s2_nz_nibble_pos;     
//==============================================================================================
endmodule                                                                                           
                                                                                            
                                                                                            
                                                                                            
                                                                                            
                                                                                            