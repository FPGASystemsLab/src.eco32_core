//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_idu_rfu_box
(
 input  wire            clk,
 input  wire            rst,

 input  wire            i_tid,
 
 input  wire     [4:0]  i_r0_addr,
 input  wire            i_r0_ena,
 input  wire            i_r0_bank,
 input  wire            i_r0_mode,
 input  wire    [31:0]  i_r0_const,
 
 input  wire     [4:0]  i_r1_addr,          
 input  wire            i_r1_ena,
 input  wire            i_r1_bank,
 input  wire            i_r1_mode,
 input  wire    [31:0]  i_r1_const,

 input  wire     [4:0]  i_r2_addr,          
 input  wire            i_r2_ena,
 input  wire            i_r2_bank,
 input  wire            i_r2_mode,
 input  wire    [31:0]  i_r2_const,

 input  wire     [4:0]  i_r3_addr,          
 input  wire            i_r3_ena,
 input  wire            i_r3_bank,
 input  wire            i_r3_mode,
 input  wire    [31:0]  i_r3_const,

 input  wire     [4:0]  i_ry_addr,                 
 input  wire     [1:0]  i_ry_ena,

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
 output wire     [1:0]  o_ry_locked
);                             
//==============================================================================================
// parameters
//==============================================================================================
parameter   [7:0]   CODE_ID             =                                                   'd0;
parameter           FORCE_RST           =                                                     0;
//==============================================================================================
// variables
//==============================================================================================
wire     [4:0]  i_r_addr   [0:3];          
wire            i_r_ena    [0:3];          
wire            i_r_bank   [0:3];
wire            i_r_mode   [0:3];
//----------------------------------------------------------------------------------------------
wire    [31:0]  rd0_a_data  [0:3];
wire            rd0_a_tagx  [0:3];
wire            rd0_a_tagy  [0:3];

wire            rd0_ya_tagx;
wire            rd0_ya_tagy;
//----------------------------------------------------------------------------------------------
wire    [31:0]  rd0_b_data  [0:3];
wire            rd0_b_tagx  [0:3];
wire            rd0_b_tagy  [0:3];

wire            rd0_yb_tagx;
wire            rd0_yb_tagy;
//----------------------------------------------------------------------------------------------
wire    [31:0]  rd1_a_data  [0:3];
wire            rd1_a_tagx  [0:3];
wire            rd1_a_tagy  [0:3];

wire            rd1_ya_tagx;
wire            rd1_ya_tagy;
//----------------------------------------------------------------------------------------------
wire    [31:0]  rd1_b_data  [0:3];
wire            rd1_b_tagx  [0:3];
wire            rd1_b_tagy  [0:3];

wire            rd1_yb_tagx;
wire            rd1_yb_tagy;
//----------------------------------------------------------------------------------------------
// output stage (should be b-phase) 
//----------------------------------------------------------------------------------------------
reg             b1_r_locked [0:3];
reg     [31:0]  b1_r_data   [0:3];

reg      [1:0]  b1_ry_ena;
reg      [4:0]  b1_ry_addr;
reg      [1:0]  b1_ry_locked;
reg      [1:0]  b1_ry_tag;
//==============================================================================================
// register banks (TH0:A_B and TH1:A_B)
//==============================================================================================
assign          i_r_addr [0]    =                                                     i_r0_addr;
assign          i_r_ena  [0]    =                                                      i_r0_ena;
assign          i_r_bank [0]    =                                                     i_r0_bank;
assign          i_r_mode [0]    =                                                     i_r0_mode;
//---------------------------------------------------------------------------------------------                                          
assign          i_r_addr [1]    =                                                     i_r1_addr;
assign          i_r_ena  [1]    =                                                      i_r1_ena;
assign          i_r_bank [1]    =                                                     i_r1_bank;
assign          i_r_mode [1]    =                                                     i_r1_mode;
///---------------------------------------------------------------------------------------------                                          
assign          i_r_addr [2]    =                                                     i_r2_addr;
assign          i_r_ena  [2]    =                                                      i_r2_ena;
assign          i_r_bank [2]    =                                                     i_r2_bank;
assign          i_r_mode [2]    =                                                     i_r2_mode;
///---------------------------------------------------------------------------------------------                                          
assign          i_r_addr [3]    =                                                     i_r3_addr;
assign          i_r_ena  [3]    =                                                      i_r3_ena;
assign          i_r_bank [3]    =                                                     i_r3_bank;
assign          i_r_mode [3]    =                                                     i_r3_mode;
///---------------------------------------------------------------------------------------------                                          
// register banks
//----------------------------------------------------------------------------------------------                                          
generate     
    genvar p; 

//----------------------------------------------------------------------------------------------                                          
// th0
//----------------------------------------------------------------------------------------------                                          
    for (p=0; p<4; p = p + 1)
        begin : regbank_th0_r  
            eco32_core_idu_rfu_reg A_data
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_data (wr0_a_data),   .w_ena(wr0_a_ena[0] || wr0_clr),  .w_ben(wr0_a_ben),  .w_addr(wr0_addr), 
            .o_data (rd0_a_data[p])
            );                             
            
            eco32_core_idu_rfu_reg B_data
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_data (wr0_b_data),   .w_ena(wr0_b_ena[0] || wr0_clr),  .w_ben(wr0_b_ben),  .w_addr(wr0_addr),        
            .o_data (rd0_b_data[p])
            );                             
         
            eco32_core_idu_rfu_tag A_tag_x
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_tag  (wr0_a_tag),    .w_ena(wr0_a_ena[1] || wr0_clr),    .w_addr(wr0_addr),    
            .o_tag  (rd0_a_tagx[p])
            );                             
        
            eco32_core_idu_rfu_tag A_tag_y
            (                        
            .clk    (clk),                                                                          
            .i_addr (i_r_addr[p]), 
            .w_tag  (lc_ry_tag[0] & !wr0_clr),  .w_ena(lc_ry_enaT0[0] || wr0_clr),   .w_addr(wr0_clr ? wr0_addr : lc_ry_addr),    
            .o_tag  (rd0_a_tagy[p])
            );                             
        
            eco32_core_idu_rfu_tag B_tag_x
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_tag  (wr0_b_tag),    .w_ena(wr0_b_ena[1] || wr0_clr),    .w_addr(wr0_addr),    
            .o_tag  (rd0_b_tagx[p])
            );                             
        
            eco32_core_idu_rfu_tag B_tag_y
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_tag  (lc_ry_tag[1] & !wr0_clr), .w_ena(lc_ry_enaT0[1] || wr0_clr), .w_addr(wr0_clr ? wr0_addr : lc_ry_addr),    
            .o_tag  (rd0_b_tagy[p])
            );                             
        end
		
	if(1)	
        begin : regbank_th0_ry
            eco32_core_idu_rfu_tag A_tag_x
            (                        
            .clk    (clk),  
            .i_addr (i_ry_addr),   
            .w_tag  (wr0_a_tag),    .w_ena(wr0_a_ena[1] || wr0_clr),        .w_addr(wr0_addr),    
            .o_tag  (rd0_ya_tagx)
            );                             
        
            eco32_core_idu_rfu_tag A_tag_y
            (                        
            .clk    (clk),                                                                          
            .i_addr (i_ry_addr),   
            .w_tag  (lc_ry_tag[0] & !wr0_clr),  .w_ena(lc_ry_enaT0[0] || wr0_clr),   .w_addr(wr0_clr ? wr0_addr : lc_ry_addr),    
            .o_tag  (rd0_ya_tagy)
            );                             
        
            eco32_core_idu_rfu_tag B_tag_x
            (                        
            .clk    (clk),  
            .i_addr (i_ry_addr),   
            .w_tag  (wr0_b_tag),    .w_ena(wr0_b_ena[1] || wr0_clr),        .w_addr(wr0_addr),    
            .o_tag  (rd0_yb_tagx)
            );                             
        
            eco32_core_idu_rfu_tag B_tag_y
            (                        
            .clk    (clk),  
            .i_addr (i_ry_addr),   
            .w_tag  (lc_ry_tag[1] & !wr0_clr), .w_ena(lc_ry_enaT0[1] || wr0_clr),    .w_addr(wr0_clr ? wr0_addr : lc_ry_addr),    
            .o_tag  (rd0_yb_tagy)
            );                             
        end

//----------------------------------------------------------------------------------------------                                          
// th1
//----------------------------------------------------------------------------------------------                                          
        
    for (p=0; p<4; p = p + 1)
        begin : regbank_th1_r  
            eco32_core_idu_rfu_reg A_data
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_data (wr1_a_data),               .w_ena(wr1_a_ena[0] || wr1_clr),  .w_ben(wr1_a_ben),    .w_addr(wr1_addr), 
            .o_data (rd1_a_data[p])
            );                             

            eco32_core_idu_rfu_reg B_data
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_data (wr1_b_data),               .w_ena(wr1_b_ena[0] || wr1_clr),  .w_ben(wr1_b_ben),   .w_addr(wr1_addr),        
            .o_data (rd1_b_data[p])
            );                             
            
                eco32_core_idu_rfu_tag A_tag_x
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_tag  (wr1_a_tag),                .w_ena(wr1_a_ena[1] || wr1_clr),    .w_addr(wr1_addr),    
            .o_tag  (rd1_a_tagx[p])
            );                             
        
            eco32_core_idu_rfu_tag A_tag_y
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_tag  (lc_ry_tag[0] & !wr1_clr),  .w_ena(lc_ry_enaT1[0] || wr1_clr),   .w_addr(wr1_clr ? wr1_addr : lc_ry_addr),    
            .o_tag  (rd1_a_tagy[p])
            );                             

            eco32_core_idu_rfu_tag B_tag_x
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_tag  (wr1_b_tag),                .w_ena(wr1_b_ena[1] || wr1_clr),    .w_addr(wr1_addr),    
            .o_tag  (rd1_b_tagx[p])
            );                             
        
            eco32_core_idu_rfu_tag B_tag_y
            (                        
            .clk    (clk),  
            .i_addr (i_r_addr[p]), 
            .w_tag  (lc_ry_tag[1] & !wr1_clr),  .w_ena(lc_ry_enaT1[1] || wr1_clr),   .w_addr(wr1_clr ? wr1_addr : lc_ry_addr),    
            .o_tag  (rd1_b_tagy[p])
            );      
        end            
		
	if(1)	
        begin : regbank_th1_ry
            eco32_core_idu_rfu_tag A_tag_x
            (                        
            .clk    (clk),  
            .i_addr (i_ry_addr),   
            .w_tag  (wr1_a_tag),                .w_ena(wr1_a_ena[1] || wr1_clr),    .w_addr(wr1_addr),    
            .o_tag  (rd1_ya_tagx)
            );                             
        
            eco32_core_idu_rfu_tag A_tag_y
            (                        
            .clk    (clk),  
            .i_addr (i_ry_addr),   
            .w_tag  (lc_ry_tag[0] & !wr1_clr),  .w_ena(lc_ry_enaT1[0] || wr1_clr),   .w_addr(wr1_clr ? wr1_addr : lc_ry_addr),    
            .o_tag  (rd1_ya_tagy)
            );                             

            eco32_core_idu_rfu_tag B_tag_x
            (                        
            .clk    (clk),  
            .i_addr (i_ry_addr),   
            .w_tag  (wr1_b_tag),                .w_ena(wr1_b_ena[1] || wr1_clr),    .w_addr(wr1_addr),    
            .o_tag  (rd1_yb_tagx)
            );                             
        
            eco32_core_idu_rfu_tag B_tag_y
            (                        
            .clk    (clk),  
            .i_addr (i_ry_addr),   
            .w_tag  (lc_ry_tag[1] & !wr1_clr),  .w_ena(lc_ry_enaT1[1] || wr1_clr),   .w_addr(wr1_clr ? wr1_addr : lc_ry_addr),    
            .o_tag  (rd1_yb_tagy)
            );      
        end     
endgenerate
//==============================================================================================
// stage (b)5:  
//============================================================================================== 
wire            f1_lck_r0a      =                (lc_ry_enaG[0]) && (i_r_addr[0] == lc_ry_addr);
wire            f1_lck_r0b      =                (lc_ry_enaG[1]) && (i_r_addr[0] == lc_ry_addr);
wire            f1_lck_r1a      =                (lc_ry_enaG[0]) && (i_r_addr[1] == lc_ry_addr);
wire            f1_lck_r1b      =                (lc_ry_enaG[1]) && (i_r_addr[1] == lc_ry_addr);
wire            f1_lck_r2a      =                (lc_ry_enaG[0]) && (i_r_addr[2] == lc_ry_addr);
wire            f1_lck_r2b      =                (lc_ry_enaG[1]) && (i_r_addr[2] == lc_ry_addr);
wire            f1_lck_r3a      =                (lc_ry_enaG[0]) && (i_r_addr[3] == lc_ry_addr);
wire            f1_lck_r3b      =                (lc_ry_enaG[1]) && (i_r_addr[3] == lc_ry_addr);
//----------------------------------------------------------------------------------------------                                          
wire            f1_lck_rya      =                (lc_ry_enaG[0]) && (i_ry_addr   == lc_ry_addr);
wire            f1_lck_ryb      =                (lc_ry_enaG[1]) && (i_ry_addr   == lc_ry_addr);
//----------------------------------------------------------------------------------------------                                          
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b1_r_data[0]                <=                                                32'h0000_0000;
    b1_r_data[1]                <=                                                32'h0000_0000;                   
    b1_r_data[2]                <=                                                32'h0000_0000;
    b1_r_data[3]                <=                                                32'h0000_0000;

    b1_r_locked[0]              <=                                                         1'd0;
    b1_r_locked[1]              <=                                                         1'd0;
    b1_r_locked[2]              <=                                                         1'd0;
    b1_r_locked[3]              <=                                                         1'd0;

    b1_ry_ena                   <=                                                         2'd0;
    b1_ry_addr                  <=                                                         5'd0;
    b1_ry_tag                   <=                                                         2'd0;
    b1_ry_locked                <=                                                         2'd0;
  end   
 else  
  begin
    case({i_tid,i_r_mode[0],i_r_bank[0]})     
    {1'b0,2'h0}: b1_r_data[0]   <=                                                rd0_a_data[0];
    {1'b0,2'h1}: b1_r_data[0]   <=                                                rd0_b_data[0];
    {1'b0,2'h2}: b1_r_data[0]   <=                                                   i_r0_const;
    {1'b0,2'h3}: b1_r_data[0]   <=                                                   i_r0_const;
    {1'b1,2'h0}: b1_r_data[0]   <=                                                rd1_a_data[0];
    {1'b1,2'h1}: b1_r_data[0]   <=                                                rd1_b_data[0];
    {1'b1,2'h2}: b1_r_data[0]   <=                                                   i_r0_const;
    {1'b1,2'h3}: b1_r_data[0]   <=                                                   i_r0_const;
    endcase 
    
    case({i_tid,i_r_mode[1],i_r_bank[1]})     
    {1'b0,2'h0}: b1_r_data[1]   <=                                                rd0_a_data[1];
    {1'b0,2'h1}: b1_r_data[1]   <=                                                rd0_b_data[1];
    {1'b0,2'h2}: b1_r_data[1]   <=                                                   i_r1_const;
    {1'b0,2'h3}: b1_r_data[1]   <=                                                   i_r1_const;
    {1'b1,2'h0}: b1_r_data[1]   <=                                                rd1_a_data[1];
    {1'b1,2'h1}: b1_r_data[1]   <=                                                rd1_b_data[1];
    {1'b1,2'h2}: b1_r_data[1]   <=                                                   i_r1_const;
    {1'b1,2'h3}: b1_r_data[1]   <=                                                   i_r1_const;
    endcase 

    case({i_tid,i_r_mode[2],i_r_bank[2]})     
    {1'b0,2'h0}: b1_r_data[2]   <=                                                rd0_a_data[2];
    {1'b0,2'h1}: b1_r_data[2]   <=                                                rd0_b_data[2];
    {1'b0,2'h2}: b1_r_data[2]   <=                                                   i_r2_const;
    {1'b0,2'h3}: b1_r_data[2]   <=                                                   i_r2_const;
    {1'b1,2'h0}: b1_r_data[2]   <=                                                rd1_a_data[2];
    {1'b1,2'h1}: b1_r_data[2]   <=                                                rd1_b_data[2];
    {1'b1,2'h2}: b1_r_data[2]   <=                                                   i_r2_const;
    {1'b1,2'h3}: b1_r_data[2]   <=                                                   i_r2_const;
    endcase 
    
    case({i_tid,i_r_mode[3],i_r_bank[3]})            
    {1'b0,2'h0}: b1_r_data[3]   <=                                                rd0_a_data[3];
    {1'b0,2'h1}: b1_r_data[3]   <=                                                rd0_b_data[3];
    {1'b0,2'h2}: b1_r_data[3]   <=                                                   i_r3_const;
    {1'b0,2'h3}: b1_r_data[3]   <=                                                   i_r3_const;
    {1'b1,2'h0}: b1_r_data[3]   <=                                                rd1_a_data[3];
    {1'b1,2'h1}: b1_r_data[3]   <=                                                rd1_b_data[3];
    {1'b1,2'h2}: b1_r_data[3]   <=                                                   i_r3_const;
    {1'b1,2'h3}: b1_r_data[3]   <=                                                   i_r3_const;
    endcase 
    
// ---------------------------------------------------------------------------------------------

    case({i_tid,i_r_mode[0],i_r_bank[0]})     
    {1'b0,2'h0}: b1_r_locked[0] <=     i_r_ena[0] & (f1_lck_r0a || rd0_a_tagy[0]^rd0_a_tagx[0]);
    {1'b0,2'h1}: b1_r_locked[0] <=     i_r_ena[0] & (f1_lck_r0b || rd0_b_tagy[0]^rd0_b_tagx[0]);
    {1'b0,2'h2}: b1_r_locked[0] <=                                                         1'd0;
    {1'b0,2'h3}: b1_r_locked[0] <=                                                         1'd0;
    {1'b1,2'h0}: b1_r_locked[0] <=     i_r_ena[0] & (f1_lck_r0a || rd1_a_tagy[0]^rd1_a_tagx[0]);
    {1'b1,2'h1}: b1_r_locked[0] <=     i_r_ena[0] & (f1_lck_r0b || rd1_b_tagy[0]^rd1_b_tagx[0]);
    {1'b1,2'h2}: b1_r_locked[0] <=                                                         1'd0;
    {1'b1,2'h3}: b1_r_locked[0] <=                                                         1'd0;
    endcase 

    case({i_tid,i_r_mode[1],i_r_bank[1]})     
    {1'b0,2'h0}: b1_r_locked[1] <=     i_r_ena[1] & (f1_lck_r1a || rd0_a_tagy[1]^rd0_a_tagx[1]);
    {1'b0,2'h1}: b1_r_locked[1] <=     i_r_ena[1] & (f1_lck_r1b || rd0_b_tagy[1]^rd0_b_tagx[1]);
    {1'b0,2'h2}: b1_r_locked[1] <=                                                         1'd0;
    {1'b0,2'h3}: b1_r_locked[1] <=                                                         1'd0;
    {1'b1,2'h0}: b1_r_locked[1] <=     i_r_ena[1] & (f1_lck_r1a || rd1_a_tagy[1]^rd1_a_tagx[1]);
    {1'b1,2'h1}: b1_r_locked[1] <=     i_r_ena[1] & (f1_lck_r1b || rd1_b_tagy[1]^rd1_b_tagx[1]);
    {1'b1,2'h2}: b1_r_locked[1] <=                                                         1'd0;
    {1'b1,2'h3}: b1_r_locked[1] <=                                                         1'd0;
    endcase 

    case({i_tid,i_r_mode[2],i_r_bank[2]})     
    {1'b0,2'h0}: b1_r_locked[2] <=     i_r_ena[2] & (f1_lck_r2a || rd0_a_tagy[2]^rd0_a_tagx[2]);
    {1'b0,2'h1}: b1_r_locked[2] <=     i_r_ena[2] & (f1_lck_r2b || rd0_b_tagy[2]^rd0_b_tagx[2]);
    {1'b0,2'h2}: b1_r_locked[2] <=                                                         1'd0;
    {1'b0,2'h3}: b1_r_locked[2] <=                                                         1'd0;
    {1'b1,2'h0}: b1_r_locked[2] <=     i_r_ena[2] & (f1_lck_r2a || rd1_a_tagy[2]^rd1_a_tagx[2]);
    {1'b1,2'h1}: b1_r_locked[2] <=     i_r_ena[2] & (f1_lck_r2b || rd1_b_tagy[2]^rd1_b_tagx[2]);
    {1'b1,2'h2}: b1_r_locked[2] <=                                                         1'd0;
    {1'b1,2'h3}: b1_r_locked[2] <=                                                         1'd0;
    endcase 
    
    case({i_tid,i_r_mode[3],i_r_bank[3]})     
    3'b0_00:     b1_r_locked[3] <=     i_r_ena[3] & (f1_lck_r3a || rd0_a_tagy[3]^rd0_a_tagx[3]);
    3'b0_01:     b1_r_locked[3] <=     i_r_ena[3] & (f1_lck_r3b || rd0_b_tagy[3]^rd0_b_tagx[3]);
    3'b0_10:     b1_r_locked[3] <=                                                         1'd0;
    3'b0_11:     b1_r_locked[3] <=                                                         1'd0;
    3'b1_00:     b1_r_locked[3] <=     i_r_ena[3] & (f1_lck_r3a || rd1_a_tagy[3]^rd1_a_tagx[3]);
    3'b1_01:     b1_r_locked[3] <=     i_r_ena[3] & (f1_lck_r3b || rd1_b_tagy[3]^rd1_b_tagx[3]);
    3'b1_10:     b1_r_locked[3] <=                                                         1'd0;
    3'b1_11:     b1_r_locked[3] <=                                                         1'd0;
    endcase
    
// dest Ry -------------------------------------------------------------------------------------

    
    b1_ry_ena                   <=                                                     i_ry_ena;
    b1_ry_addr                  <=                                                    i_ry_addr;

    case(i_tid)        
    1'b0:   b1_ry_tag[0]        <=                                                 ~rd0_ya_tagy;
    1'b1:   b1_ry_tag[0]        <=                                                 ~rd1_ya_tagy;
    endcase 

    case(i_tid)        
    1'b0:   b1_ry_tag[1]        <=                                                 ~rd0_yb_tagy;
    1'b1:   b1_ry_tag[1]        <=                                                 ~rd1_yb_tagy;
    endcase 
    
    case(i_tid)        
    1'b0:   b1_ry_locked[0]     <=        i_ry_ena[0] & (f1_lck_rya || rd0_ya_tagy^rd0_ya_tagx);
    1'b1:   b1_ry_locked[0]     <=        i_ry_ena[0] & (f1_lck_rya || rd1_ya_tagy^rd1_ya_tagx);
    endcase 

    case(i_tid)        
    1'b0:   b1_ry_locked[1]     <=        i_ry_ena[1] & (f1_lck_ryb || rd0_yb_tagy^rd0_yb_tagx);
    1'b1:   b1_ry_locked[1]     <=        i_ry_ena[1] & (f1_lck_ryb || rd1_yb_tagy^rd1_yb_tagx);
    endcase 
    
// ---------------------------------------------------------------------------------------------
  end      
//==============================================================================================
// output
//==============================================================================================
assign  o_r0_data       =                                                          b1_r_data[0];
assign  o_r0_locked     =                                                        b1_r_locked[0];
assign  o_r1_data       =                                                          b1_r_data[1];
assign  o_r1_locked     =                                                        b1_r_locked[1];
assign  o_r2_data       =                                                          b1_r_data[2];
assign  o_r2_locked     =                                                        b1_r_locked[2];
assign  o_r3_data       =                                                          b1_r_data[3];
assign  o_r3_locked     =                                                        b1_r_locked[3];
//----------------------------------------------------------------------------------------------
assign  o_ry_ena        =                                                             b1_ry_ena;
assign  o_ry_addr       =                                                            b1_ry_addr;
assign  o_ry_tag        =                                                             b1_ry_tag;
assign  o_ry_locked     =                                                          b1_ry_locked;
//==============================================================================================   
endmodule