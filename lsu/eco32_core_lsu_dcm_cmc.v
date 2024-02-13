//=============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================================
`default_nettype none
//---------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================================
module eco32_core_lsu_dcm_cmc
# // parameters
( 
 parameter                          PAGE_ADDR_WIDTH = 'd5
)
// ports
(
input   wire                        clk,
input   wire                        rst,

input   wire                        rx_hdr_stb,
output  wire                        rx_hdr_ack,
input   wire                        rx_data_stb,
output  wire                        rx_data_flush,
input   wire                [71:0]  rx_data,
input   wire                [ 3:0]  rx_iid,

input   wire                        tx_stb,
input   wire                        tx_clr,
input   wire                        tx_tid,
input   wire                        tx_wid,
input   wire [PAGE_ADDR_WIDTH-1:0]  tx_page,
output  wire                        tx_ack,

output  wire                        mm_w_stb,
output  wire                        mm_w_wen,
output  wire                        mm_w_tid,
output  wire                        mm_w_wid,
output  wire [PAGE_ADDR_WIDTH-1:0]  mm_w_page,
output  wire                 [2:0]  mm_w_offset,
output  wire                [63:0]  mm_w_data,

input   wire                        req_stb,
input   wire                 [3:0]  req_rid,
input   wire                        req_tid,
input   wire                        req_wid,
input   wire                        req_tag,
input   wire [PAGE_ADDR_WIDTH-1:0]  req_page,
input   wire                [31:0]  req_v_addr,

output  wire                        ack_stb,
output  wire                 [3:0]  ack_rid,
output  wire                        ack_tid,
output  wire                        ack_wid,
output  wire [PAGE_ADDR_WIDTH-1:0]  ack_page,
output  wire                [31:0]  ack_ph_addr,
input   wire                        ack_rdy 
);      
//=============================================================================================
// parameters
//=============================================================================================
localparam      _PAW        =                                                  PAGE_ADDR_WIDTH;    
//=============================================================================================
// variables
//=============================================================================================
integer         mm_state;
//---------------------------------------------------------------------------------------------
reg             fr_len;   
reg             fr_tid;   
reg      [3:0]  fr_rid;   
reg             fr_ack;   
//---------------------------------------------------------------------------------------------
reg [_PAW-1:0]  buff_page [31:0];
reg             buff_tid  [31:0];
reg             buff_wid  [31:0];
reg             buff_tag  [31:0];
reg      [2:0]  buff_off  [31:0];
//---------------------------------------------------------------------------------------------
reg             mm_stb;   
reg             mm_clr;
reg             mm_wen;   
reg             mm_wid;   
reg             mm_tid;   
reg [_PAW-1:0]  mm_page;  
reg      [2:0]  mm_offset;
reg      [3:0]  mm_cnt;   
reg     [63:0]  mm_data;        
//---------------------------------------------------------------------------------------------
reg             mm1_stb;   
reg             mm1_wen;   
reg             mm1_wid;   
reg             mm1_tid;   
reg [_PAW-1:0]  mm1_page;  
reg      [2:0]  mm1_offset;
reg     [63:0]  mm1_data;       
//---------------------------------------------------------------------------------------------
reg             mm2_stb;   
reg             mm2_wen;   
reg             mm2_wid;   
reg             mm2_tid;   
reg [_PAW-1:0]  mm2_page;  
reg      [2:0]  mm2_offset;
reg     [63:0]  mm2_data;       
//---------------------------------------------------------------------------------------------
reg      [2:0]  buff_tx_ack;    
//---------------------------------------------------------------------------------------------
reg             buff_rx_data_flush;
//---------------------------------------------------------------------------------------------
reg             buff_ack_stb;    
reg             buff_ack_ack;    
reg      [3:0]  buff_ack_rid;    
reg             buff_ack_tid;    
reg             buff_ack_wid;    
reg [_PAW-1:0]  buff_ack_page;   
reg     [31:0]  buff_ack_ph_addr;
reg             buff_ack_rdy;     
//=============================================================================================
localparam MM_WAIT      = 'h00;

localparam MM_PRESET    = 'h10;
localparam MM_FLUSH     = 'h11;

localparam MM_HEADER    = 'h20;
localparam MM_SETUP     = 'h21;
localparam MM_PAGE8     = 'h22;
localparam MM_PAGE1     = 'h23;

localparam MM_ACK       = 'h30;
//=============================================================================================
wire      f_rxr         =                                                           rx_hdr_stb;
wire      f_txr         =                                                               tx_stb;
wire      f_page8       =                                                               fr_len;
wire      f_eop8        =                                                            mm_cnt[3];
wire      f_eop1        =                                                            mm_cnt[3];
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                        mm_state   <=                                          MM_WAIT;
 else case(mm_state)  
 MM_WAIT:       if(f_rxr)       mm_state   <=                                        MM_HEADER; 
           else if(f_txr)       mm_state   <=                                        MM_PRESET;
//.......................
 MM_PRESET:                     mm_state   <=                                         MM_FLUSH;
 MM_FLUSH:      if(f_eop8)      mm_state   <=                                          MM_WAIT; 
//.......................
 MM_HEADER:                     mm_state   <=                                         MM_SETUP;
 MM_SETUP:      if(f_page8)     mm_state   <=                                         MM_PAGE8;
           else                 mm_state   <=                                         MM_PAGE1;
//.......................
 MM_PAGE8:      if(f_eop8)      mm_state   <=                                           MM_ACK; 
//.......................
 MM_PAGE1:      if(f_eop1)      mm_state   <=                                           MM_ACK; 
//.......................
 MM_ACK:                        mm_state   <=                                          MM_WAIT;
//.......................
 endcase
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)
    begin
        fr_tid          <=                                                                1'd0;
        fr_rid          <=                                                                4'd0;
        fr_len          <=                                                                1'd0;
        fr_ack          <=                                                                1'd0;
    end
 else if(mm_state==MM_HEADER)
    begin
        fr_tid          <=                                                       rx_iid[    0];
        fr_rid          <=                                                      rx_data[43:40];
        fr_len          <=                                                      rx_data[   39];
        fr_ack          <=                                                                1'd1;
    end     
 else
    begin
        fr_ack          <=                                                                1'd0;
    end
//---------------------------------------------------------------------------------------------
assign      rx_hdr_ack   =                                                              fr_ack;
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
        buff_off  [{req_tid,req_rid}] <=                                       req_v_addr[5:3];
    end
//---------------------------------------------------------------------------------------------
wire [_PAW-1:0] x_page       =                                      buff_page[{fr_tid,fr_rid}];
wire            x_tid        =                                      buff_tid [{fr_tid,fr_rid}];
wire            x_wid        =                                      buff_wid [{fr_tid,fr_rid}];
wire            x_tag        =                                      buff_tag [{fr_tid,fr_rid}];
wire    [2:0]   x_off        =                                      buff_off [{fr_tid,fr_rid}];
//=============================================================================================
// cache mem port
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)
    begin
        mm_stb          <=                                                                 'd0;
        mm_clr          <=                                                                 'd0;
        mm_wen          <=                                                                 'd0;
        mm_wid          <=                                                                 'd0;
        mm_tid          <=                                                                 'd0;
        mm_page         <=                                                                 'd0;
        mm_offset       <=                                                                 'd0;
        mm_cnt          <=                                                                 'd0;
        mm_data         <=                                                                 'd0;
    end
 else if(mm_state==MM_PRESET) 
    begin
        mm_stb          <=                                                                1'd0;
        mm_clr          <=                                                              tx_clr;
        mm_wen          <=                                                                1'b0;
        mm_wid          <=                                                              tx_wid;
        mm_tid          <=                                                              tx_tid;
        mm_page         <=                                                             tx_page;
        mm_offset       <=                                                                3'd7;
        mm_cnt          <=                                                                4'd7;
    end
 else if(mm_state==MM_FLUSH && !f_eop8) 
    begin
        mm_stb          <=                                                                1'b1;
        mm_wen          <=                                                              mm_clr;
        mm_offset       <=                                                    mm_offset + 3'd1;                                        
        mm_cnt          <=                                                    mm_cnt    - 4'd1;
        mm_data         <=                                                                 'd0;
    end
 else if(mm_state==MM_SETUP) 
    begin
        mm_stb          <=                                                                1'd0;
        mm_clr          <=                                                                1'd0;
        mm_wen          <=                                                                1'b0;
        mm_wid          <=                                                               x_wid;
        mm_tid          <=                                                               x_tid;
        mm_page         <=                                                              x_page;
        mm_offset       <= (fr_len) ?                                         3'd7 : x_off-'d1;
        mm_cnt          <= (fr_len) ?                                         4'd7 :      4'b0;
    end
 else if(mm_state==MM_PAGE8 && !f_eop8 && rx_data_stb) 
    begin
        mm_stb          <=                                                                1'b1;
        mm_wen          <=                                                                1'd1;
        mm_offset       <=                                                    mm_offset + 3'd1;
        mm_cnt          <=                                                    mm_cnt    - 4'd1;
        mm_data         <=                                                       rx_data[63:0];
    end
 else if(mm_state==MM_PAGE1 && !f_eop1 && rx_data_stb) 
    begin
        mm_stb          <=                                                                1'b1;
        mm_wen          <=                                                                1'd1;
        mm_offset       <=                                                               x_off;
        mm_cnt          <=                                                    mm_cnt    - 4'd1;
        mm_data         <=                                                       rx_data[63:0];
    end
 else
    begin
        mm_stb          <=                                                                 'd0;
        mm_clr          <=                                                                 'd0;
        mm_wen          <=                                                                 'd0;
    end
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                        buff_rx_data_flush <=                                      'd0;
 else if(mm_state==MM_PAGE1)    buff_rx_data_flush <=                                      'd1;
 else if(mm_state==MM_PAGE8)    buff_rx_data_flush <=                                      'd1;
 else                           buff_rx_data_flush <=                                      'd0;
//---------------------------------------------------------------------------------------------
assign  rx_data_flush =                                                     buff_rx_data_flush;                         
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)
    begin
        mm1_stb          <=                                                                'd0;
        mm1_wen          <=                                                                'd0;
        mm1_wid          <=                                                                'd0;
        mm1_tid          <=                                                                'd0;
        mm1_page         <=                                                                'd0;
        mm1_offset       <=                                                                'd0;
        mm1_data         <=                                                                'd0;
    end
 else  
    begin
        mm1_stb          <=                                                             mm_stb;
        mm1_wen          <=                                                             mm_wen;
        mm1_wid          <=                                                             mm_wid;
        mm1_tid          <=                                                             mm_tid;
        mm1_page         <=                                                            mm_page;
        mm1_offset       <=                                                          mm_offset;
        mm1_data         <=                                                            mm_data;
    end
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)
    begin
        mm2_stb          <=                                                                'd0;
        mm2_wen          <=                                                                'd0;
        mm2_wid          <=                                                                'd0;
        mm2_tid          <=                                                                'd0;
        mm2_page         <=                                                                'd0;
        mm2_offset       <=                                                                'd0;
        mm2_data         <=                                                                'd0;
    end
 else  
    begin
        mm2_stb          <=                                                            mm1_stb;
        mm2_wen          <=                                                            mm1_wen;
        mm2_wid          <=                                                            mm1_wid;
        mm2_tid          <=                                                            mm1_tid;
        mm2_page         <=                                                           mm1_page;
        mm2_offset       <=                                                         mm1_offset;
        mm2_data         <=                                                           mm1_data;
    end
//---------------------------------------------------------------------------------------------
assign  mm_w_stb      =                                                                mm2_stb;
assign  mm_w_wen      =                                                                mm2_wen;
assign  mm_w_tid      =                                                                mm2_tid;
assign  mm_w_wid      =                                                                mm2_wid;
assign  mm_w_page     =                                                               mm2_page;
assign  mm_w_offset   =                                                             mm2_offset;
assign  mm_w_data     =                                                               mm2_data;
//=============================================================================================
// tx ack buffer
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)
    begin                                                                                     
        buff_tx_ack   =                                                                    'd0;
    end
 else
    begin                                                                                     
        buff_tx_ack   =                               {buff_tx_ack[1:0],(mm_state==MM_PRESET)};
    end
//=============================================================================================
assign  tx_ack        =                                                         buff_tx_ack[2];
//=============================================================================================
// cache mem write finished
//=============================================================================================
always@(posedge clk or posedge rst)
 if(rst)
    begin                                                                                     
        buff_ack_stb       <=                                                              'd0;    
        buff_ack_rid       <=                                                              'd0;
        buff_ack_tid       <=                                                              'd0;
        buff_ack_wid       <=                                                              'd0;
        buff_ack_page      <=                                                              'd0;
        buff_ack_ph_addr   <=                                                            32'd0;
    end
 else 
    begin
        buff_ack_stb       <=                                               (mm_state==MM_ACK);    
        buff_ack_rid       <=                                                           fr_rid;
        buff_ack_tid       <=                                                            x_tid;
        buff_ack_wid       <=                                                            x_wid;
        buff_ack_page      <=                                                           x_page;                                                          
        buff_ack_ph_addr   <=                                                            32'd0;
    end
//=============================================================================================
assign  ack_stb       =                                                           buff_ack_stb;    
assign  ack_rid       =                                                           buff_ack_rid;
assign  ack_tid       =                                                           buff_ack_tid;
assign  ack_wid       =                                                           buff_ack_wid;
assign  ack_page      =                                                          buff_ack_page;
assign  ack_ph_addr   =                                                       buff_ack_ph_addr;
//=============================================================================================
endmodule