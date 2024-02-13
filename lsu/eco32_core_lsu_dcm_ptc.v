//=============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================================
`default_nettype none
//---------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================================
module eco32_core_lsu_dcm_ptc
# // parameters
( 
 parameter                  PAGE_ADDR_WIDTH = 'd5,
 parameter                  FORCE_RST       =   0
)
// ports
(
input   wire                        clk,
input   wire                        rst,
output  wire                        rdy,

input   wire                        req_stb,
input   wire                        req_end,
output  wire                        req_ack,    
input   wire                 [3:0]  req_rid,
input   wire                        req_tid,
input   wire                        req_wid,
input   wire                        req_tag,
input   wire [PAGE_ADDR_WIDTH-1:0]  req_page,
input   wire                [31:0]  req_v_addr,
output  wire                        req_rdy,    

input   wire                        ack_stb,
input   wire                 [3:0]  ack_rid,
input   wire                        ack_tid,
input   wire                [31:0]  ack_ph_addr,
output  wire                        ack_rdy,    

output  wire                        ptw_stb,
output  wire                        ptw_tid,    
output  wire                        ptw_eor,    
output  wire                        ptw_wid,    
output  wire [PAGE_ADDR_WIDTH-1:0]  ptw_page,   
output  wire                [38:0]  ptw_data,

output  wire                        pwf_clr,
output  wire                        pwf_wen,
output  wire                        pwf_tid,    
output  wire                        pwf_wid,    
output  wire [PAGE_ADDR_WIDTH-1:0]  pwf_page
);      
//=============================================================================================
// parameters
//=============================================================================================
localparam      _PAW        =                                                  PAGE_ADDR_WIDTH; 
//=============================================================================================
// variables
//=============================================================================================
reg             pt0_clr; 
reg             pt0_stb; 
reg             pt0_tid; 
reg             pt0_eor; 
reg             pt0_wid; 
reg [_PAW-1:0]  pt0_page;
reg     [38:0]  pt0_data; 
reg [_PAW+2:0]  pt0_cnt;             
//---------------------------------------------------------------------------------------------
reg             r0_stb;     
reg             r0_end;
reg             r0_rdy;
reg      [3:0]  r0_rid;     
reg             r0_tid;     
reg             r0_wid;     
reg             r0_tag;     
reg [_PAW-1:0]  r0_page;    
reg     [31:0]  r0_v_addr;  
//---------------------------------------------------------------------------------------------
reg             r1_stb;     
reg             r1_end;
reg      [3:0]  r1_rid;     
reg             r1_tid;     
reg             r1_wid;     
reg             r1_tag;     
reg [_PAW-1:0]  r1_page;    
reg     [31:0]  r1_v_addr;  
//---------------------------------------------------------------------------------------------
reg [_PAW-1:0]  buff_page [31:0];
reg             buff_tid  [31:0];
reg             buff_wid  [31:0];
reg             buff_tag  [31:0];
reg     [31:0]  buff_v_a  [31:0];
//---------------------------------------------------------------------------------------------
reg             pt1_clr; 
reg             pt1_stb; 
reg             pt1_tid; 
reg             pt1_eor; 
reg             pt1_wid; 
reg [_PAW-1:0]  pt1_page;
reg     [38:0]  pt1_data; 
//---------------------------------------------------------------------------------------------
reg             pt2_clr; 
reg             pt2_stb; 
reg             pt2_tid; 
reg             pt2_eor; 
reg             pt2_wid; 
reg [_PAW-1:0]  pt2_page;
reg     [38:0]  pt2_data; 
//=============================================================================================
// page table controler
//=============================================================================================
localparam PT_START     = 'h00;
localparam PT_CLEAN     = 'h01;

localparam PT_WAIT      = 'h10;
//=============================================================================================
assign req_ack = (r0_stb && req_stb) || (r0_end && req_end);
assign req_rdy = r0_rdy;

assign ack_rdy = 1'b1;
//---------------------------------------------------------------------------------------------
// stage 0
//---------------------------------------------------------------------------------------------          
always@(posedge clk or posedge rst)                                                                       
 if(rst)
    begin
        r0_stb       <=      'd0;
        r0_end       <=      'd0;
        r0_rid       <=      'd0;
        r0_tid       <=      'd0;
        r0_wid       <=      'd0;
        r0_tag       <=      'd0;
        r0_page      <=      'd0;
        r0_v_addr    <=      'd0;
        r0_rdy       <=      'd1;
    end
 else if((req_stb && !r0_stb) || (req_end && !r0_end))
    begin
        r0_stb       <=      req_stb;
        r0_end       <=      req_end;
        r0_rid       <=      req_rid;
        r0_tid       <=      req_tid;
        r0_wid       <=      req_wid;
        r0_tag       <=      req_tag;    
        r0_page      <=      req_page;
        r0_v_addr    <=      req_v_addr;
        r0_rdy       <=      1'b0;
    end
 else if((r0_stb || r0_end)&& !ack_stb)
    begin                                                                                                                   
        r0_stb       <=      'd0;                                                                                           
        r0_end       <=      'd0;
        r0_rdy       <=      'd1;
    end   
//---------------------------------------------------------------------------------------------
// stage 1
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)
    begin
        r1_stb       <=      'd0;
        r1_end       <=      'd0;
        r1_rid       <=      'd0;
        r1_tid       <=      'd0;
        r1_wid       <=      'd0;
        r1_tag       <=      'd0;
        r1_page      <=      'd0;
        r1_v_addr    <=      'd0;
    end
 else
    begin
        r1_stb       <=      r0_stb;
        r1_end       <=      r0_end;
        r1_rid       <=      r0_rid;
        r1_tid       <=      r0_tid;
        r1_wid       <=      r0_wid;
        r1_tag       <=      r0_tag;
        r1_page      <=      r0_page;
        r1_v_addr    <=      r0_v_addr;
    end                                                                                                                                                                            
//=============================================================================================
// request buffer
//=============================================================================================
always@(posedge clk)
 if(req_stb)
    begin
        buff_page [{req_tid,req_rid}] <=                                              req_page;
        buff_tid  [{req_tid,req_rid}] <=                                               req_tid;
        buff_wid  [{req_tid,req_rid}] <=                                               req_wid;
        buff_tag  [{req_tid,req_rid}] <=                                               req_tag;
        buff_v_a  [{req_tid,req_rid}] <=                                            req_v_addr;
    end
//---------------------------------------------------------------------------------------------
wire [_PAW-1:0] x_page       =                                    buff_page[{ack_tid,ack_rid}];
wire            x_tid        =                                    buff_tid [{ack_tid,ack_rid}];
wire            x_wid        =                                    buff_wid [{ack_tid,ack_rid}];
wire            x_tag        =                                    buff_tag [{ack_tid,ack_rid}];
wire   [31:0]   x_v_a        =                                    buff_v_a [{ack_tid,ack_rid}];
//=============================================================================================
// page update
//=============================================================================================
assign          rdy          =                                                 pt0_cnt[_PAW+2];
wire [_PAW+2:0] cnt_update   =                   pt0_cnt + {{(_PAW+1){1'd0}},!pt0_cnt[_PAW+2]};
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                
  begin
    pt0_clr          <=                                                                     'b0;
    pt0_stb          <=                                                                     'd0;
    pt0_tid          <=                                                                     'd0;
    pt0_eor          <=                                                                     'b0;
    pt0_wid          <=                                                                     'd0;
    pt0_page         <=                                                                     'd0;
    pt0_data         <=                                                                     'd0;
    pt0_cnt          <=                                                                     'd0;
  end
 else if(!rdy)
  begin  
    pt0_clr          <=                                                                     'b1;
    pt0_stb          <=                                                                     'b1;
    pt0_tid          <=                                                         pt0_cnt[_PAW+1];
    pt0_eor          <=                                                                    1'b0;
    pt0_wid          <=                                                           pt0_cnt[_PAW];
    pt0_page         <=                                                       pt0_cnt[_PAW-1:0];
    pt0_data         <=                                                                   39'd0;
    pt0_cnt          <=                                                              cnt_update;
  end   
 else if(ack_stb)
  begin  
    pt0_clr          <=                                                                     'b0;
    pt0_stb          <=                                                                     'b1;
    pt0_tid          <=                                                                   x_tid;
    pt0_eor          <=                                                                    1'b1;
    pt0_wid          <=                                                                   x_wid;
    pt0_page         <=                                                                  x_page;
    pt0_data         <=        {7'd0,x_v_a[31:11],1'b1,2'b10,x_tag,1'b0,{2{x_v_a[31]}},4'b1110};
    pt0_cnt          <=                                                              cnt_update;
  end   
 else if(r0_stb)
  begin  
    pt0_clr          <=                                                                     'b0;
    pt0_stb          <=                                                                     'b1;
    pt0_tid          <=                                                                  r0_tid;
    pt0_eor          <=                                                                     'b0;
    pt0_wid          <=                                                                  r0_wid;
    pt0_page         <=                                                                 r0_page;
    pt0_data         <=          {7'd0,21'd0,1'b0,2'b01,r0_tag,1'b0,{2{r0_v_addr[31]}},4'b0000};
    pt0_cnt          <=                                                              cnt_update;
  end   
 else if(r0_end)
  begin  
    pt0_clr          <=                                                                     'b0;
    pt0_stb          <=                                                                     'b1;
    pt0_tid          <=                                                                  r0_tid;
    pt0_eor          <=                                                                     'b0;
    pt0_wid          <=                                                                  r0_wid;
    pt0_page         <=                                                                 r0_page;
    pt0_data         <={7'd0,r0_v_addr[31:11],1'b1,2'b10,r0_tag,1'b0,{2{r0_v_addr[31]}},4'b1110};
    pt0_cnt          <=                                                              cnt_update;
  end   
 else
  begin                                                                                                 
    pt0_clr          <=                                                                     'd0;        
    pt0_stb          <=                                                                     'd0;
    pt0_tid          <=                                                                     'd0;
    pt0_eor          <=                                                                     'd0;
    pt0_wid          <=                                                                     'd0;
    pt0_page         <=                                                                     'd0;
    pt0_data         <=                                                                     'd0;
    pt0_cnt          <=                                                              cnt_update;
  end   
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                
  begin
    pt1_clr          <=                                                                     'd0;
    pt1_stb          <=                                                                     'd0;
    pt1_tid          <=                                                                     'd0;
    pt1_eor          <=                                                                     'b0;
    pt1_wid          <=                                                                     'd0;
    pt1_page         <=                                                                     'd0;
    pt1_data         <=                                                                     'd0;
  end
 else
  begin  
    pt1_clr          <=                                                                 pt0_clr;
    pt1_stb          <=                                                                 pt0_stb;
    pt1_tid          <=                                                                 pt0_tid;
    pt1_eor          <=                                                                 pt0_eor;
    pt1_wid          <=                                                                 pt0_wid;
    pt1_page         <=                                                                pt0_page;
    pt1_data         <=                                                                pt0_data;
  end   
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                
  begin
    pt2_clr          <=                                                                     'd0;
    pt2_stb          <=                                                                     'd0;
    pt2_tid          <=                                                                     'd0;
    pt2_eor          <=                                                                     'b0;
    pt2_wid          <=                                                                     'd0;
    pt2_page         <=                                                                     'd0;
    pt2_data         <=                                                                     'd0;
  end
 else
  begin  
    pt2_clr          <=                                                                 pt1_clr;
    pt2_stb          <=                                                                 pt1_stb;
    pt2_tid          <=                                                                 pt1_tid;
    pt2_eor          <=                                                                 pt1_eor;
    pt2_wid          <=                                                                 pt1_wid;
    pt2_page         <=                                                                pt1_page;
    pt2_data         <=                                                                pt1_data;
  end   
//=============================================================================================
// page table port
//=============================================================================================
assign  ptw_stb      =                                                                  pt2_stb;
assign  ptw_tid      =                                                                  pt2_tid;
assign  ptw_eor      =                                                                  pt2_eor;
assign  ptw_wid      =                                                                  pt2_wid;
assign  ptw_page     =                                                                 pt2_page;
assign  ptw_data     =                                                                 pt2_data;
//=============================================================================================
// page write flag table port
//=============================================================================================
assign  pwf_clr      =                                                                  pt2_clr;
assign  pwf_wen      =                                                                  pt2_stb;
assign  pwf_tid      =                                                                  pt2_tid;
assign  pwf_wid      =                                                                  pt2_wid;
assign  pwf_page     =                                                                 pt2_page;
//=============================================================================================
endmodule