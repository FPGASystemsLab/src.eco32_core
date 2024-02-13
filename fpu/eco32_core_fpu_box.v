//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
module eco32_core_fpu_box
(
 input  wire            clk,
 input  wire            rst,   

 // input port from IDU
 
 input  wire            i_stb,
 input  wire            i_tid,
 input  wire     [1:0]  i_pid,
 input  wire     [1:0]  i_isz,
 input  wire    [15:0]  i_isw,
 input  wire    [31:0]  i_iva,
 
 // LSU control word
 
 input  wire     [5:0]  i_fl_cw,
 input  wire     [6:0]  i_ft_cw,
 
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
 
 input  wire            fci_inst_rep,
 input  wire            fci_inst_skip,
 input  wire            fci_inst_lsf,
 input  wire            fci_inst_jpf,
 
 // write back from cache
 
 output wire            wb_stb0,    
 output wire            wb_stb1,    
                                
 output wire     [1:0]  wb_enaA,             
 output wire            wb_tagA,             
                                             
 output wire     [1:0]  wb_enaB,             
 output wire            wb_tagB,             
 output wire            wb_modB,             
                                            
 output wire     [4:0]  wb_addr,            
 output wire    [31:0]  wb_dataL,
 output wire    [31:0]  wb_dataH
);      
//==============================================================================================
// parameters
//==============================================================================================

//==============================================================================================
// variables
//==============================================================================================
reg             a0_stb;
reg             a0_tid;
reg      [1:0]  a0_pid;
reg     [15:0]  a0_isw;
reg      [1:0]  a0_isz;
reg     [31:0]  a0_iva;

reg      [1:0]  a0_ry_ena;
reg      [4:0]  a0_ry_addr;
reg      [1:0]  a0_ry_tag;
//----------------------------------------------------------------------------------------------
reg             b1_stb;
reg             b1_tid;
reg      [1:0]  b1_pid;
reg     [15:0]  b1_isw;
reg      [1:0]  b1_isz;
reg     [31:0]  b1_iva;

reg      [1:0]  b1_ry_ena;
reg      [4:0]  b1_ry_addr;
reg      [1:0]  b1_ry_tag;
//----------------------------------------------------------------------------------------------
reg             a2_stb;
reg             a2_tid;
reg      [1:0]  a2_pid;
reg     [15:0]  a2_isw;
reg      [1:0]  a2_isz;
reg     [31:0]  a2_iva;

reg             a2_ry_stb0;
reg             a2_ry_stb1;
reg      [1:0]  a2_ry_enaA;
reg             a2_ry_tagA;
                           
reg      [1:0]  a2_ry_enaB;
reg             a2_ry_modB;
reg             a2_ry_tagB;
                                                                                                                                                                             
reg      [4:0]  a2_ry_addr;
//----------------------------------------------------------------------------------------------
wire           f_inst_cancel =                                    fci_inst_rep || fci_inst_skip;
//==============================================================================================
// stage (a)0
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a0_stb                  <=                                                             1'b0;
    a0_tid                  <=                                                             1'b0;
    a0_pid                  <=                                                             2'b0;
    a0_isw                  <=                                                            16'b0;        
    a0_isz                  <=                                                             2'b0;        
    a0_iva                  <=                                                            32'b0;        
    
    a0_ry_ena               <=                                                             2'd0;
    a0_ry_addr              <=                                                             5'd0;
    a0_ry_tag               <=                                                             2'd0;
  end
 else
  begin                                                 
    a0_stb                  <=            !f_inst_cancel && (i_fl_cw[0] || i_fl_cw[0]) && i_stb;
    a0_tid                  <=                                                            i_tid;
    a0_pid                  <=                                                            i_pid;
    a0_isw                  <=                                                            i_isw;        
    a0_isz                  <=                                                            i_isz;        
    a0_iva                  <=                                                            i_iva;        
    
// .... product Ry path ........................................................................
       
    a0_ry_ena               <=                                                         2'd0;//i_ry_ena;
    a0_ry_addr              <=                                                        i_ry_addr;
    a0_ry_tag               <=                                                         i_ry_tag;
    
// .............................................................................................
  end
//==============================================================================================
// stage (b)1
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b1_stb                  <=                                                             1'b0;
    b1_tid                  <=                                                             1'b0;
    b1_pid                  <=                                                             2'b0;
    b1_isw                  <=                                                            16'b0;        
    b1_isz                  <=                                                             2'b0;        
    b1_iva                  <=                                                            32'b0;        
    
    b1_ry_ena               <=                                                             2'd0;
    b1_ry_addr              <=                                                             5'd0;
    b1_ry_tag               <=                                                             2'd0;
  end
 else
  begin                                                 
    b1_stb                  <=                                          !fci_inst_lsf && a0_stb;
    b1_tid                  <=                                                           a0_tid;
    b1_pid                  <=                                                           a0_pid;
    b1_isw                  <=                                                           a0_isw;        
    b1_isz                  <=                                                           a0_isz;        
    b1_iva                  <=                                                           a0_iva;        
    
// .... product Ry path ........................................................................
       
    b1_ry_ena               <=                                                        a0_ry_ena;
    b1_ry_addr              <=                                                       a0_ry_addr;
    b1_ry_tag               <=                                                        a0_ry_tag;
    
// .............................................................................................
  end
//==============================================================================================
// stage (a)2
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a2_stb                  <=                                                             1'b0;
    a2_tid                  <=                                                             1'b0;
    a2_pid                  <=                                                             2'b0;
    a2_isw                  <=                                                            16'b0;        
    a2_isz                  <=                                                             2'b0;        
    a2_iva                  <=                                                            32'b0;        
    
    a2_ry_stb0              <=                                                             1'b0;
    a2_ry_stb1              <=                                                             1'b0;
    a2_ry_enaA              <=                                                             2'd0;
    a2_ry_tagA              <=                                                             1'd0;
    a2_ry_enaB              <=                                                             2'd0;
    a2_ry_modB              <=                                                             1'd0;
    a2_ry_tagB              <=                                                             1'd0;
    a2_ry_addr              <=                                                             5'd0;
  end
 else
  begin                                                 
    a2_stb                  <=                                                           b1_stb;
    a2_tid                  <=                                                           b1_tid;
    a2_pid                  <=                                                           b1_pid;
    a2_isw                  <=                                                           b1_isw;        
    a2_isz                  <=                                                           b1_isz;        
    a2_iva                  <=                                                           b1_iva;        
    
// .... product Ry path ........................................................................
       
    a2_ry_stb0                  <=                                       !b1_tid & (|b1_ry_ena);
    a2_ry_stb1                  <=                                       !b1_tid & (|b1_ry_ena);

    a2_ry_addr                  <=                                                   b1_ry_addr;
    
    a2_ry_enaA                  <=                             {2{!b1_tid}} & {2{b1_ry_ena[0]}};
    a2_ry_tagA                  <=                                                 b1_ry_tag[0];
    
    
    a2_ry_enaB                  <=                             {2{ b1_tid}} & {2{b1_ry_ena[0]}};       
    a2_ry_modB                  <=                                                         1'b0;
    a2_ry_tagB                  <=                                                 b1_ry_tag[1];
    
// .............................................................................................
  end
//==============================================================================================
// write back
//==============================================================================================
assign  wb_stb0              =                                                       a2_ry_stb0; 
assign  wb_stb1              =                                                       a2_ry_stb1; 

assign  wb_enaA              =                                                       a2_ry_enaA; 
assign  wb_tagA              =                                                       a2_ry_tagA;

assign  wb_enaB              =                                                       a2_ry_enaB; 
assign  wb_modB              =                                                       a2_ry_modB;
assign  wb_tagB              =                                                       a2_ry_tagB;

assign  wb_addr              =                                                       a2_ry_addr; 
assign  wb_dataL             =                                                            32'd0;
assign  wb_dataH             =                                                            32'd0;
//==============================================================================================     
endmodule