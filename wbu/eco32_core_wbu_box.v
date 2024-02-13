
//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_wbu_box
#(                                                                                                                      
parameter               FLOAT_HW        =                  "ON", // "ON", "OFF"                                         
parameter               FLOAT_ADV_HW    =                  "ON", // "ON", "OFF" 
parameter               FORCE_RST       =                     0                                                               
)
(
 input  wire            clk,
 input  wire            rst,   
 output wire            rdy,
 //.................................
 output wire            fco_wbu_af,
 //.................................
 input  wire            a_stb,
 
 input  wire     [1:0]  a_enaA,
 input  wire            a_tagA,
 
 input  wire     [1:0]  a_enaB,
 input  wire            a_tagB,
 input  wire            a_modB,
 
 input  wire     [4:0]  a_addr,
 input  wire    [31:0]  a_dataL,
 input  wire    [31:0]  a_dataH,
 //.................................
 input  wire            b0_stb,
 
 input  wire     [1:0]  b0_enaA,
 input  wire     [3:0]  b0_benA,
 input  wire            b0_tagA,
 
 input  wire     [1:0]  b0_enaB,
 input  wire     [3:0]  b0_benB,
 input  wire            b0_tagB,
 input  wire            b0_modB,
 
 input  wire     [4:0]  b0_addr,
 input  wire    [31:0]  b0_dataL,
 input  wire    [31:0]  b0_dataH,
 //.................................
 input  wire            b1_stb,
 
 input  wire     [1:0]  b1_enaA,
 input  wire     [3:0]  b1_benA,
 input  wire            b1_tagA,
 
 input  wire     [1:0]  b1_enaB,
 input  wire     [3:0]  b1_benB,
 input  wire            b1_tagB,
 input  wire            b1_modB,
 
 input  wire     [4:0]  b1_addr,
 input  wire    [31:0]  b1_dataL,
 input  wire    [31:0]  b1_dataH,
 //.................................
 input  wire            b2_stb,
 
 input  wire     [1:0]  b2_enaA,
 input  wire     [3:0]  b2_benA,
 input  wire            b2_tagA,
 
 input  wire     [1:0]  b2_enaB,
 input  wire     [3:0]  b2_benB,
 input  wire            b2_tagB,
 input  wire            b2_modB,
 
 input  wire     [4:0]  b2_addr,
 input  wire    [31:0]  b2_dataL,
 input  wire    [31:0]  b2_dataH,
//.................................
 input  wire            xp_stb,
 
 input  wire     [1:0]  xp_enaA,
 input  wire            xp_tagA,
 
 input  wire     [1:0]  xp_enaB,
 input  wire            xp_tagB,
 input  wire            xp_modB,
 
 input  wire     [4:0]  xp_addr,
 input  wire    [31:0]  xp_dataL,
 input  wire    [31:0]  xp_dataH,
//.................................
 input  wire            fp_stb,
 
 input  wire     [1:0]  fp_enaA,
 input  wire            fp_tagA,
 
 input  wire     [1:0]  fp_enaB,
 input  wire            fp_tagB,
 input  wire            fp_modB,
 
 input  wire     [4:0]  fp_addr,
 input  wire    [31:0]  fp_dataL,
 input  wire    [31:0]  fp_dataH,
//.................................
 output wire            o_clr,
 output wire     [4:0]  o_addr,     
 
 output wire     [1:0]  o_a_ena,     
 output wire     [3:0]  o_a_ben,     
 output wire    [31:0]  o_a_data,     
 output wire            o_a_tag,     
 
 output wire     [1:0]  o_b_ena,     
 output wire     [3:0]  o_b_ben,     
 output wire    [31:0]  o_b_data,     
 output wire            o_b_tag
//.................................
);                                    
//=============================================================================================
// parameters check
//=============================================================================================   
// pragma translate_off      
initial
    begin                                                                                     
        if((FLOAT_HW != "ON") && (FLOAT_HW != "OFF")) 
            begin
            $display( "!!!ERROR!!! FLOAT_HW = %s, is out of range (\"ON\" \"OFF\")", FLOAT_HW ); 
            $finish;
            end                                                                              
        if((FLOAT_ADV_HW != "ON") && (FLOAT_ADV_HW != "OFF")) 
            begin
            $display( "!!!ERROR!!! FLOAT_ADV_HW = %s, is out of range (\"ON\" \"OFF\")", FLOAT_ADV_HW ); 
            $finish;
            end       
    end
// pragma translate_on                            
//==============================================================================================
// variables
//==============================================================================================
reg             clr_ena;
reg      [5:0]  clr_addr;
//----------------------------------------------------------------------------------------------
reg             m0_stb;
reg             m0_clr;
reg      [4:0]  m0_addr;

reg      [1:0]  m0_a_ena;   
reg      [3:0]  m0_a_ben;   
reg     [31:0]  m0_a_data; 
reg             m0_a_tag; 

reg      [1:0]  m0_b_ena;   
reg      [3:0]  m0_b_ben;   
reg             m0_b_mode; 
reg     [31:0]  m0_b_data; 
reg             m0_b_tag;   
//----------------------------------------------------------------------------------------------
reg             wb_clr;
reg      [4:0]  wb_addr;

reg      [1:0]  wb_a_ena;   
reg      [3:0]  wb_a_ben;   
reg     [31:0]  wb_a_data; 
reg             wb_a_tag; 

reg      [1:0]  wb_b_ena;   
reg      [3:0]  wb_b_ben;   
reg             wb_b_mode; 
reg     [31:0]  wb_b_data; 
reg             wb_b_tag;   
//----------------------------------------------------------------------------------------------
reg             m1_stb;
reg             m1_clr;
reg      [4:0]  m1_addr;

reg      [1:0]  m1_a_ena;   
reg      [3:0]  m1_a_ben;   
reg     [31:0]  m1_a_data; 
reg             m1_a_tag; 

reg      [1:0]  m1_b_ena;   
reg      [3:0]  m1_b_ben;   
reg             m1_b_mode; 
reg     [31:0]  m1_b_data; 
reg             m1_b_tag;    
//----------------------------------------------------------------------------------------------
wire            c_stb;
wire            c_ack;

wire            c_clr;
wire     [4:0]  c_addr;

wire     [1:0]  c_a_ena;   
wire    [31:0]  c_a_data; 
wire            c_a_tag; 

wire     [1:0]  c_b_ena;   
wire            c_b_mode; 
wire    [31:0]  c_b_data; 
wire            c_b_tag;  
                         
//==============================================================================================
// clear
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    clr_ena                 <=                                                             1'd1;
    clr_addr                <=                                                             6'd0;
  end
 else if(clr_ena) 
  begin                                                                         
    clr_ena                 <=                                                     ~clr_addr[5];
    clr_addr                <=                                                  clr_addr + 6'd1;
  end
//==============================================================================================
assign  rdy                  =                                                         !clr_ena;
//==============================================================================================
// mux 0
//==============================================================================================
wire    [1:0]   m0_sel       =  (clr_ena)?                                                2'b10:
                                (b0_stb )?                                                2'b00:
                                (b1_stb )?                                                2'b01:
                             /* (b2_stb )? */                                             2'b11;
//----------------------------------------------------------------------------------------------
always@(*)
  case(m0_sel)
  2'b10:      
    begin     
        m0_stb               =                                                          clr_ena;
        
        m0_clr               =                                                          clr_ena;
        m0_addr              =                                                    clr_addr[4:0];
    
        m0_a_ena             =                                                             2'b0;
        m0_a_ben             =                                                             4'hF;
        m0_a_data            =                                                            32'd0;
        m0_a_tag             =                                                             1'b0;
    
        m0_b_ena             =                                                             2'b0;
        m0_b_ben             =                                                             4'hF;
        m0_b_mode            =                                                             1'b0;
        m0_b_data            =                                                            32'd0;
        m0_b_tag             =                                                             1'b0;
    end                                                                                                                                                                      
  2'b00:      
    begin     
        m0_stb               =                                                             1'd1;
        m0_clr               =                                                             1'd0;
        m0_addr              =                                                          b0_addr;
    
        m0_a_ena             =                                                          b0_enaA;
        m0_a_ben             =                                                          b0_benA;
        m0_a_data            =                                                         b0_dataL;
        m0_a_tag             =                                                          b0_tagA;  
                                                                                          
        m0_b_ena             =                                                          b0_enaB;
        m0_b_ben             =                                                          b0_benB;
        m0_b_mode            =                                                          b0_modB;
        m0_b_data            =                                                         b0_dataH;
        m0_b_tag             =                                                          b0_tagB;  
    end         
  2'b01:          
    begin     
        m0_stb               =                                                             1'd1;
        m0_clr               =                                                             1'd0;
        m0_addr              =                                                          b1_addr;
    
        m0_a_ena             =                                                          b1_enaA;
        m0_a_ben             =                                                          b1_benA;
        m0_a_data            =                                                         b1_dataL;
        m0_a_tag             =                                                          b1_tagA;  
                                                                                          
        m0_b_ena             =                                                          b1_enaB;
        m0_b_ben             =                                                          b1_benB;
        m0_b_mode            =                                                          b1_modB;
        m0_b_data            =                                                         b1_dataH;
        m0_b_tag             =                                                          b1_tagB;  
    end
  2'b11: 
    begin     
        m0_stb               =                                                             1'd1;
        m0_clr               =                                                             1'd0;
        m0_addr              =                                                          b2_addr;
    
        m0_a_ena             =                                                          b2_enaA;
        m0_a_ben             =                                                          b2_benA;
        m0_a_data            =                                                         b2_dataL;
        m0_a_tag             =                                                          b2_tagA;  
                                                                                          
        m0_b_ena             =                                                          b2_enaB;
        m0_b_ben             =                                                          b2_benB;
        m0_b_mode            =                                                          b2_modB;
        m0_b_data            =                                                         b2_dataH;
        m0_b_tag             =                                                          b2_tagB;  

    end 
  endcase                                                                                          
//==============================================================================================
// write back 
//==============================================================================================
wire    [1:0]   wb_sel       =  (clr_ena)?                                                2'b01:
                                (b0_stb )?                                                2'b01:
                                (b1_stb )?                                                2'b01:
                                (b2_stb )?                                                2'b01:
                                (a_stb  )?                                                2'b10:
                                (c_stb  )?                                                2'b11:
                                                                                          2'b00;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    wb_clr                  <=                                                             1'd0;
    wb_addr                 <=                                                             5'd0;     
    
    wb_a_ena                <=                                                             2'b0;
    wb_a_ben                <=                                                             4'hF;
    wb_a_data               <=                                                            32'd0;
    wb_a_tag                <=                                                             1'b0;
    
    wb_b_ena                <=                                                             2'b0;
    wb_b_ben                <=                                                             4'hF;
    wb_b_mode               <=                                                             1'b0;
    wb_b_data               <=                                                            32'd0;
    wb_b_tag                <=                                                             1'b0;
  end
  else case(wb_sel)
  2'b00:      
    begin     
        wb_clr              <=                                                             1'd0;
        wb_addr             <=                                                             5'd0;
    
        wb_a_ena            <=                                                             2'b0;
        wb_a_ben            <=                                                             4'hF;
        wb_a_data           <=                                                            32'd0;
        wb_a_tag            <=                                                             1'b0;  
                                                                                     
        wb_b_ena            <=                                                             2'b0;
        wb_b_ben            <=                                                             4'hF;
        wb_b_mode           <=                                                             1'b0;
        wb_b_data           <=                                                            32'd0;
        wb_b_tag            <=                                                             1'b0;  
    end         
  2'b01:      
    begin     
        wb_clr              <=                                                           m0_clr;
        wb_addr             <=                                                          m0_addr;
    
        wb_a_ena            <=                                                         m0_a_ena;
        wb_a_ben            <=                                                         m0_a_ben;
        wb_a_data           <=                                                        m0_a_data;
        wb_a_tag            <=                                                         m0_a_tag;  
                                                                                          
        wb_b_ena            <=                                                         m0_b_ena;
        wb_b_ben            <=                                                         m0_b_ben;
        wb_b_mode           <=                                                        m0_b_mode;
        wb_b_data           <=                                                        m0_b_data;
        wb_b_tag            <=                                                         m0_b_tag;  
    end         
  2'b10:      
    begin     
        wb_clr              <=                                                             1'd0;
        wb_addr             <=                                                           a_addr;
    
        wb_a_ena            <=                                                           a_enaA;
        wb_a_ben            <=                                                             4'hF;
        wb_a_data           <=                                                          a_dataL;
        wb_a_tag            <=                                                           a_tagA;  
    
        wb_b_ena            <=                                                           a_enaB;
        wb_b_ben            <=                                                             4'hF;
        wb_b_mode           <=                                                           a_modB;
        wb_b_data           <=                                                          a_dataH;
        wb_b_tag            <=                                                           a_tagB;  
    end                                                                                                                                                                      
  2'b11: // input from second level 
    begin     
        wb_clr              <=                                                             1'b0;
        wb_addr             <=                                                           c_addr;
    
        wb_a_ena            <=                                                          c_a_ena;
        wb_a_ben            <=                                                             4'hF;
        wb_a_data           <=                                                         c_a_data;
        wb_a_tag            <=                                                          c_a_tag;  
                                                                                          
        wb_b_ena            <=                                                          c_b_ena;
        wb_b_ben            <=                                                             4'hF;
        wb_b_mode           <=                                                         c_b_mode;
        wb_b_data           <=                                                         c_b_data;
        wb_b_tag            <=                                                          c_b_tag;  
    end 
  endcase     
//==============================================================================================
// write back level 1
//============================================================================================== 
generate
if((FLOAT_HW == "ON") || (FLOAT_ADV_HW == "ON"))   
    begin : float_wb_fifo   
        eco32_core_wbm_lff fifo
        (
        .clk            (clk),
        .rst            (rst),   
        
        .x_af           (),
        
        // output
        
        .o_stb          (c_stb),
        .o_ack          (c_ack),
         
        .o_clr          (c_clr),
        .o_addr         (c_addr),
         
        .o_a_ena        (c_a_ena),
        .o_a_data       (c_a_data),
        .o_a_tag        (c_a_tag),
         
        .o_b_ena        (c_b_ena),
        .o_b_mode       (c_b_mode),
        .o_b_data       (c_b_data),
        .o_b_tag        (c_b_tag),
        
        // input 
        
        .i_stb          (m1_stb),
         
        .i_clr          (m1_clr),
        .i_addr         (m1_addr),
         
        .i_a_ena        (m1_a_ena),
        .i_a_data       (m1_a_data),
        .i_a_tag        (m1_a_tag),
         
        .i_b_ena        (m1_b_ena),
        .i_b_mode       (m1_b_mode),
        .i_b_data       (m1_b_data),
        .i_b_tag        (m1_b_tag)
        );  
    end
else
    begin: float_wb_fifo_idle 
        assign            c_stb         =                                                  1'd0; 
        assign            c_clr         =                                                  1'd0;
        assign            c_addr        =                                                  5'd0;                                                              
        assign            c_a_ena       =                                                  2'd0;   
        assign            c_a_data      =                                                 32'd0; 
        assign            c_a_tag       =                                                  1'd0; 
        assign            c_b_ena       =                                                  2'd0;   
        assign            c_b_mode      =                                                  1'd0; 
        assign            c_b_data      =                                                 32'd0; 
        assign            c_b_tag       =                                                  1'd0; 
    end
endgenerate
//==============================================================================================
// mux B - data from float point units
//============================================================================================== 
wire            m1_sel;
//----------------------------------------------------------------------------------------------
generate
if((FLOAT_HW == "ON") && (FLOAT_ADV_HW == "ON"))   
    begin : float_wb_mux                                                                         
        assign          m1_sel       =  (xp_stb)?                                          1'b0:
                                        (fp_stb)?                                          1'b1:
                                                                                           1'b0; 
    end   
else if(FLOAT_HW == "ON")   
    begin : float_wb_from_xpu                                                                    
        assign          m1_sel       =                                                     1'b0;  
    end   
else if(FLOAT_ADV_HW == "ON")   
    begin : float_wb_from_float_advance                                                          
        assign          m1_sel       =                                                     1'b1; 
    end 
endgenerate
//----------------------------------------------------------------------------------------------
assign          c_ack        =                                                    wb_sel==2'b11;
//----------------------------------------------------------------------------------------------
always@(*)
 if(rst) 
  begin                                                                         
    m1_stb                   =                                                             1'd0;
    m1_clr                   =                                                             1'd0;
    m1_addr                  =                                                             5'd0;     
    
    m1_a_ena                 =                                                             2'b0;
    m1_a_ben                 =                                                             4'hF;
    m1_a_data                =                                                            32'd0;
    m1_a_tag                 =                                                             1'b0;
    
    m1_b_ena                 =                                                             2'b0;
    m1_b_ben                 =                                                             4'hF;
    m1_b_mode                =                                                             1'b0;
    m1_b_data                =                                                            32'd0;
    m1_b_tag                 =                                                             1'b0;
  end
  else case(m1_sel)
  1'b0:   
    begin     
        m1_stb               =                                                           xp_stb;
        m1_clr               =                                                             1'd0;
        m1_addr              =                                                          xp_addr;
    
        m1_a_ena             =                                                          xp_enaA;
        m1_a_ben             =                                                             4'hF;
        m1_a_data            =                                                         xp_dataL;
        m1_a_tag             =                                                          xp_tagA;  
                                                                                          
        m1_b_ena             =                                                          xp_enaB;
        m1_b_ben             =                                                             4'hF;
        m1_b_mode            =                                                          xp_modB;
        m1_b_data            =                                                         xp_dataH;
        m1_b_tag             =                                                          xp_tagB;  
    end         
  1'b1:           
    begin     
        m1_stb               =                                                             1'd0;
        m1_clr               =                                                             1'd0;
        m1_addr              =                                                          fp_addr;
    
        m1_a_ena             =                                                          fp_enaA;
        m1_a_ben             =                                                             4'hF;
        m1_a_data            =                                                         fp_dataL;
        m1_a_tag             =                                                          fp_tagA;  
                                                                                          
        m1_b_ena             =                                                          fp_enaB;
        m1_b_ben             =                                                             4'hF;
        m1_b_mode            =                                                          fp_modB;
        m1_b_data            =                                                         fp_dataH;
        m1_b_tag             =                                                          fp_tagB;  
    end
  endcase                                                                                        
//==============================================================================================       
assign  fco_wbu_af       =                                                                 1'b0;
//==============================================================================================       
// output
//==============================================================================================       
assign  o_clr            =                                                               wb_clr;     
assign  o_addr           =                                                              wb_addr;     

assign  o_a_ena          =                                                             wb_a_ena;
assign  o_a_ben          =                                                             wb_a_ben;
assign  o_a_data         =                                                            wb_a_data;
assign  o_a_tag          =                                                             wb_a_tag;     

assign  o_b_ena          =                                                             wb_b_ena;
assign  o_b_ben          = (wb_b_mode) ?                                  wb_b_ben  :  wb_a_ben;
assign  o_b_data         = (wb_b_mode) ?                                  wb_b_data : wb_a_data;
assign  o_b_tag          =                                                             wb_b_tag;     
//==============================================================================================       
endmodule