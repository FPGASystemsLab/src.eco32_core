//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
module eco32_core_lsu_dcu_way
# // parameters
( 
 parameter              PAGE_ADDR_WIDTH = 'd5,
 parameter        FORCE_RST       =   0
)
// ports
(
 input  wire                        clk,
 input  wire                        rst,

 input  wire                        i_stb,
 input  wire                        i_tid,
 input  wire                 [1:0]  i_pid,
 input  wire                 [3:0]  i_asid,
 input  wire                [31:0]  i_v_addr,
 
 input  wire                        wr_pt_stb,
 input  wire                        wr_pt_tid,
 input  wire [PAGE_ADDR_WIDTH-1:0]  wr_pt_page,
 input  wire                [38:0]  wr_pt_descriptor,
 
 output wire                [31:0]  o_v_addr,
 output wire                        o_hit,
 output wire                        o_miss,
 output wire                        o_locked,
 output wire                        o_empty,
 output wire                        o_wrt,
 output wire                        o_tag,

 output wire                        o_exc,
 output wire                 [3:0]  o_exc_ida,
 output wire                 [3:0]  o_exc_idp,
 output wire                 [3:0]  o_exc_idt
);                             
//==============================================================================================
// local params
//==============================================================================================
localparam      _PAW        =                                                   PAGE_ADDR_WIDTH;    
//==============================================================================================
// variables
//==============================================================================================
wire    [38:0]  i_entry;     
//----------------------------------------------------------------------------------------------
// stage a0
//----------------------------------------------------------------------------------------------
reg             a0_stb;
reg             a0_tid;
reg      [1:0]  a0_pid;

reg      [3:0]  a0_asid;
reg     [38:0]  a0_entry;    
reg     [31:0]  a0_v_addr;   

wire            a0_way_valid; 
wire    [31:0]  a0_way_v_addr;
wire            a0_way_av;  
wire            a0_way_locked;  
wire            a0_way_tag;  
wire            a0_way_wrt;  
wire     [1:0]  a0_way_pid; 
wire            a0_way_exe; 
wire            a0_way_rd;  
wire            a0_way_wr;  
wire            a0_way_dbg; 
wire     [5:0]  a0_way_asid;                                                                                            
wire            a0_way_aerr;                                                                                                
//----------------------------------------------------------------------------------------------
// stage b1 : pt & tlb
//----------------------------------------------------------------------------------------------
reg             b1_stb;
reg             b1_tid;
reg      [1:0]  b1_pid;
reg     [31:0]  b1_v_addr;   

reg             b1_hit; 
reg             b1_miss;                                                                          
reg             b1_locked;                                                                        
reg             b1_empty; 
reg             b1_wrt; 
reg             b1_tag; 

reg             b1_exc; 
reg      [3:0]  b1_exc_ida; 
reg      [3:0]  b1_exc_idp; 
reg      [3:0]  b1_exc_idt; 

reg     [38:0]  b1_entry;    

reg             b1_ext;
reg     [31:0]  b1_data;     
//==============================================================================================
// instructon cache table
//==============================================================================================
eco32_core_lsu_dcu_pt
#(
.PAGE_ADDR_WIDTH (PAGE_ADDR_WIDTH)
)
ict
(
.clk            (clk),                                                                                

.i_tid          (i_tid),
.i_page         (i_v_addr[_PAW-1+6:6]),

.wr_ena         (wr_pt_stb),
.wr_tid         (wr_pt_tid),
.wr_page        (wr_pt_page),
.wr_descriptor  (wr_pt_descriptor),

.o_descriptor   (i_entry)
);                                         
//==============================================================================================
// stage (a)0 
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a0_stb              <=                                                                 1'b0;
    a0_tid              <=                                                                 1'b1;
    a0_pid              <=                                                                2'b11;
    a0_asid             <=                                                                 6'd0;
    a0_v_addr           <=                                                        32'hF000_0000; 
    a0_entry            <=                                                        32'h0000_0000; 
    a0_asid             <=                                                                 1'b0;
  end   
 else  
  begin
    a0_stb              <=                                                                i_stb;
    a0_tid              <=                                                                i_tid;
    a0_pid              <=                                                                i_pid;
    a0_asid             <=                                                               i_asid;
    a0_entry            <=                                                              i_entry; 
    a0_asid             <=                                                                 1'b0;
    a0_v_addr           <=                                                             i_v_addr; 
  end      
//----------------------------------------------------------------------------------------------
assign  a0_way_asid      =                                                      a0_entry[35:32];
//----------------------------------------------------------------------------------------------
assign  a0_way_v_addr    =                                              {a0_entry[31:11],11'd0};

assign  a0_way_valid     =                                                       a0_entry[  10];
assign  a0_way_av        =                                                       a0_entry[   9];
//----------------------------------------------------------------------------------------------
assign  a0_way_locked    =                                                       a0_entry[   8];
assign  a0_way_tag       =                                                       a0_entry[   7];
assign  a0_way_wrt       =                                                       a0_entry[   6];
assign  a0_way_pid       =                                                       a0_entry[5: 4];
//----------------------------------------------------------------------------------------------
assign  a0_way_exe       =                                                       a0_entry[   3];
assign  a0_way_rd        =                                                       a0_entry[   2];
assign  a0_way_wr        =                                                       a0_entry[   1];
assign  a0_way_dbg       =                                                       a0_entry[   0];
//----------------------------------------------------------------------------------------------
assign  a0_way_aerr      =                                                     |a0_v_addr[1: 0];
//==============================================================================================
wire    way_asid_val     =                                               a0_way_asid == a0_asid;          
wire    way_addr_val     =                     a0_way_v_addr[31:_PAW+6] == a0_v_addr[31:_PAW+6];
wire    way_exc_aa       =                             a0_way_aerr && a0_way_valid && a0_way_av;          
wire    way_exc_rd       =                              !a0_way_rd && a0_way_valid && a0_way_av;
wire    way_exc_pid      =                   (a0_way_pid < a0_pid) && a0_way_valid && a0_way_av;
//----------------------------------------------------------------------------------------------                                          
wire    way_hit          =            way_asid_val && way_addr_val && a0_way_av && a0_way_valid;
//----------------------------------------------------------------------------------------------
wire    way_miss_addr    =                           !way_addr_val && a0_way_av && a0_way_valid;
wire    way_miss_asid    =                                                        !way_asid_val;
wire    way_miss_way     =                                                        !a0_way_valid;
wire    way_miss         =                       way_miss_addr || way_miss_asid || way_miss_way;
//----------------------------------------------------------------------------------------------
wire    way_locked       =                                                        a0_way_locked;
//----------------------------------------------------------------------------------------------
wire    way_exc_page     =                              way_exc_aa && way_exc_rd && way_exc_pid; 
wire    way_exc_tlb      =                           way_addr_val && !a0_way_av && a0_way_valid;        
//==============================================================================================
// stage (b)1:  
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b1_stb              <=                                                                 1'b0;
    b1_tid              <=                                                                 1'b0;
    b1_pid              <=                                                                 2'b0;
    b1_v_addr           <=                                                                  'd0;
                                                                                                        
    b1_hit              <=                                                                 1'b0;
    b1_miss             <=                                                                 1'b0;
    b1_locked           <=                                                                 1'b0;
    b1_empty            <=                                                                 1'b0;
    
    b1_wrt              <=                                                                 1'b0;
    b1_tag              <=                                                                 1'b0;

    b1_exc              <=                                                                 1'b0;
    b1_exc_ida          <=                                                                 4'b0;
    b1_exc_idp          <=                                                                 4'b0;
    b1_exc_idt          <=                                                                 4'b0;
    b1_entry            <=                                                        32'h0000_0000; 
    
    b1_ext              <=                                                                 1'b0;
    b1_data             <=                                                        32'h0000_0000; 
  end   
 else  
  begin
    b1_stb              <=                                                               a0_stb;
    b1_tid              <=                                                               a0_tid;
    b1_pid              <=                                                               a0_pid;
    b1_v_addr           <=                                                            a0_v_addr;

    b1_hit              <=                    !way_exc_page && way_hit && !way_locked && a0_stb;
    b1_miss             <=                                    way_miss && !way_locked && a0_stb;  
    b1_locked           <=                                                 way_locked && a0_stb;  
    b1_empty            <=                !(a0_way_av && a0_way_valid) && !way_locked && a0_stb;

    b1_wrt              <=                                                           a0_way_wrt;
    b1_tag              <=                                                           a0_way_tag;
    
    b1_exc              <=               (way_exc_tlb || way_exc_page) && !way_locked && a0_stb;
    b1_exc_ida          <=                                               {1'b0,way_exc_rd,2'd0};
    b1_exc_idp          <=                                        {2'b0,way_exc_aa,way_exc_pid};
    b1_exc_idt          <=                                         {1'b0,1'b0,1'b0,way_exc_tlb};

    b1_entry            <=                                                             a0_entry; 
  end      
//==============================================================================================   
// output
//==============================================================================================   
assign  o_v_addr            =                                 {b1_entry[31:11],b1_v_addr[10:0]};
assign  o_hit               =                                                            b1_hit;
assign  o_miss              =                                                           b1_miss;
assign  o_locked            =                                                         b1_locked;
assign  o_empty             =                                                          b1_empty;
assign  o_exc               =                                                            b1_exc;
assign  o_exc_ida           =                                                        b1_exc_ida;
assign  o_exc_idp           =                                                        b1_exc_idp;
assign  o_exc_idt           =                                                        b1_exc_idt;
assign  o_tag               =                                                            b1_tag;
assign  o_wrt               =                                                            b1_wrt;
//==============================================================================================   
endmodule