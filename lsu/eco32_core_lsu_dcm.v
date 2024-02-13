//=============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================================
`default_nettype none
//---------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================================
module eco32_core_lsu_dcm
# // parameters
( 
 parameter                            PAGE_ADDR_WIDTH = 'd5,
 parameter                        FORCE_RST       =   0
)
// ports
(
input  wire                       clk,
input  wire                       rst,   
output wire                       rdy,

input  wire                       ep_i_stb,
input  wire                       ep_i_sof,
input  wire                 [3:0] ep_i_iid,
input  wire                [71:0] ep_i_data,

output wire                       ep_o_br,
input  wire                       ep_o_bg,

output wire                       ep_o_stb,
output wire                       ep_o_sof,
output wire                 [3:0] ep_o_iid,
output wire                [71:0] ep_o_data, 
input  wire                 [1:0] ep_o_rdy,
input  wire                 [1:0] ep_o_rdyE,

input  wire                       i_stb,
input  wire                       i_tid,       
input  wire                       i_wid,       
input  wire                       i_dirty,
input  wire                 [8:0] i_mode,
input  wire [PAGE_ADDR_WIDTH-1:0] i_page,
input  wire                       i_tag,     
input  wire                       i_k_ena,
input  wire                       i_k_force,
input  wire                 [1:0] i_k_op,          
input  wire                       i_k_sh,         
input  wire                [31:0] i_r_addr,    
input  wire                [31:0] i_p_addr,    
input  wire                [31:0] i_k_addr,    
output wire                       i_rdy,

output wire                       pt_w_stb,
output wire                       pt_w_eor,
output wire                       pt_w_tid,    
output wire                       pt_w_wid,    
output wire [PAGE_ADDR_WIDTH-1:0] pt_w_page,   
output wire                [38:0] pt_w_data,               

output wire                       pf_w_clr,
output wire                       pf_w_wen,
output wire                       pf_w_tid,    
output wire                       pf_w_wid,    
output wire [PAGE_ADDR_WIDTH-1:0] pf_w_page,   

output wire                       mm_w_stb,                
output wire                       mm_w_wen,
output wire                       mm_w_tid,
output wire                       mm_w_wid,
output wire [PAGE_ADDR_WIDTH-1:0] mm_w_page,
output wire                 [2:0] mm_w_offset,
output wire                [63:0] mm_w_data, 

input  wire                       mm_r_stb,
input  wire                 [7:0] mm_r_ben,
input  wire                [63:0] mm_r_data
);      
//=============================================================================================
// parameters
//=============================================================================================
localparam          _PAW                =                                      PAGE_ADDR_WIDTH;
//=============================================================================================
// variables
//=============================================================================================
wire            in_stb; 
wire            in_tid;                                                                                                                                                                         
wire            in_wid; 
wire            in_tag; 
wire            in_dirty; 
wire     [8:0]  in_mode;
wire [_PAW-1:0] in_page;
wire            in_k_ena; 
wire            in_k_force; 
wire     [1:0]  in_k_op; 
wire            in_k_sh; 
wire    [31:0]  in_r_addr;
wire    [31:0]  in_p_addr;
wire    [31:0]  in_k_addr;
wire            in_ack; 
//---------------------------------------------------------------------------------------------
wire            rx_cmc_hdr_stb; 
wire            rx_cmc_hdr_ack; 
wire            rx_cmc_data_stb; 
wire            rx_cmc_data_flush; 
wire    [71:0]  rx_cmc_data;  
wire    [ 3:0]  rx_cmc_iid;
//---------------------------------------------------------------------------------------------
wire            req_stb; 
wire            req_end; 
wire     [3:0]  req_rid; 
wire            req_tid; 
wire            req_wid; 
wire            req_tag; 
wire [_PAW-1:0] req_page;
wire     [31:0] req_v_addr;
wire            req_ack; 
wire            req_rdy; 
//---------------------------------------------------------------------------------------------
wire            ack_stb; 
wire     [3:0]  ack_rid; 
wire            ack_tid; 
wire            ack_wid; 
wire [_PAW-1:0] ack_page;
wire    [31:0]  ack_ph_addr;
wire            ack_rdy;   
//---------------------------------------------------------------------------------------------
wire            mtx_stb;
wire            mtx_clr;                  
wire            mtx_tid;                   
wire            mtx_wid;
wire [_PAW-1:0] mtx_page;
wire            mtx_ack;
//---------------------------------------------------------------------------------------------
wire            ptc_rdy;
wire            ptr_rdy;
reg      [3:0]  rdy_buff;
//==============================================================================================
// buffer for signal RDY
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst)        rdy_buff            <=                                                      'd0;
 else           rdy_buff            <=                      {(ptc_rdy & ptr_rdy),rdy_buff[3:1]};
//----------------------------------------------------------------------------------------------
assign          rdy                  =                                              rdy_buff[0];
//==============================================================================================
// request buffer
//==============================================================================================
eco32_core_lsu_dcm_iff input_fifo
(
.clk            (clk),
.rst            (rst),                                                                                                

.i_stb          (i_stb),
.i_tid          (i_tid),       
.i_wid          (i_wid),     
.i_tag          (i_tag),
.i_dirty        (i_dirty),
.i_mode         (i_mode),
.i_page         (i_page), 
.i_k_ena        (i_k_ena),
.i_k_force      (i_k_force),
.i_k_op         (i_k_op),
.i_k_sh         (i_k_sh),
.i_r_addr       (i_r_addr),    
.i_p_addr       (i_p_addr),    
.i_k_addr       (i_k_addr),    
.i_rdy          (i_rdy),

.o_stb          (in_stb),
.o_tid          (in_tid),       
.o_wid          (in_wid),     
.o_tag          (in_tag),
.o_dirty        (in_dirty),
.o_mode         (in_mode),
.o_page         (in_page),
.o_k_ena        (in_k_ena),
.o_k_force      (in_k_force),
.o_k_op         (in_k_op),
.o_k_sh         (in_k_sh),
.o_r_addr       (in_r_addr),    
.o_p_addr       (in_p_addr),    
.o_k_addr       (in_k_addr),    
.o_ack          (in_ack) 
);                       
//==============================================================================================
eco32_core_lsu_dcm_ptr ptr
(
.clk            (clk),
.rst            (rst),   
.rdy            (ptr_rdy),                                                                                        
                                                                                                                  
.i_stb          (in_stb),
.i_tid          (in_tid),       
.i_wid          (in_wid),     
.i_tag          (in_tag),
.i_dirty        (in_dirty),     
.i_mode         (in_mode),
.i_page         (in_page),
.i_k_ena        (in_k_ena),     
.i_k_force      (in_k_force),     
.i_k_op         (in_k_op),     
.i_k_sh         (in_k_sh),     
.i_r_addr       (in_r_addr),    
.i_p_addr       (in_p_addr),    
.i_k_addr       (in_k_addr),    
.i_ack          (in_ack),

.tx_stb         (mtx_stb),
.tx_clr         (mtx_clr),
.tx_tid         (mtx_tid),
.tx_wid         (mtx_wid),
.tx_page        (mtx_page),
.tx_ack         (mtx_ack),

.mmr_stb        (mm_r_stb),  
.mmr_ben        (mm_r_ben),  
.mmr_data       (mm_r_data),  

.req_stb        (req_stb),
.req_end        (req_end),
.req_rid        (req_rid),
.req_tid        (req_tid),       
.req_wid        (req_wid),                
.req_tag        (req_tag),
.req_v_addr     (req_v_addr),
.req_page       (req_page),
.req_ack        (req_ack),                
.req_rdy        (req_rdy),                

.ack_stb        (ack_stb),
.ack_tid        (ack_tid),
.ack_rid        (ack_rid),

.o_br           (ep_o_br),
.o_bg           (ep_o_bg),

.o_stb          (ep_o_stb),
.o_sof          (ep_o_sof),
.o_iid          (ep_o_iid),
.o_data         (ep_o_data),
.o_rdy          (ep_o_rdy),
.o_rdyE         (ep_o_rdyE)
);                              
//==============================================================================================
eco32_core_lsu_dcm_ptc 
#(
.FORCE_RST          (FORCE_RST)
)
ptc
(
.clk            (clk),
.rst            (rst),  
.rdy            (ptc_rdy),

.req_stb        (req_stb),
.req_end        (req_end),
.req_rid        (req_rid),
.req_tid        (req_tid),       
.req_wid        (req_wid),                
.req_tag        (req_tag),       
.req_page       (req_page),
.req_v_addr     (req_v_addr),               
.req_ack        (req_ack),                
.req_rdy        (req_rdy),    

.ack_stb        (ack_stb),
.ack_rid        (ack_rid),
.ack_tid        (ack_tid),
.ack_ph_addr    (ack_ph_addr),               
.ack_rdy        (ack_rdy),    

.ptw_stb        (pt_w_stb),
.ptw_eor        (pt_w_eor),    
.ptw_tid        (pt_w_tid),    
.ptw_wid        (pt_w_wid),    
.ptw_page       (pt_w_page),   
.ptw_data       (pt_w_data),

.pwf_clr        (pf_w_clr),
.pwf_wen        (pf_w_wen),
.pwf_tid        (pf_w_tid),    
.pwf_wid        (pf_w_wid),    
.pwf_page       (pf_w_page)
);      
//=============================================================================================
// packet de-mux
//=============================================================================================
eco32_core_lsu_dcm_dmx 
#(
.FORCE_RST          (FORCE_RST)
)
dmx
(                                                                         
.clk            (clk),
.rst            (rst),

.i_stb          (ep_i_stb),     
.i_sof          (ep_i_sof),
.i_iid          (ep_i_iid),
.i_data         (ep_i_data),

.rx_hdr_stb     (rx_cmc_hdr_stb),
.rx_hdr_ack     (rx_cmc_hdr_ack),  
.rx_data_stb    (rx_cmc_data_stb),
.rx_data_flush  (rx_cmc_data_flush),  
.rx_data        (rx_cmc_data), 
.rx_iid         (rx_cmc_iid)
);                        
//=============================================================================================
// packet receiver
//=============================================================================================
eco32_core_lsu_dcm_cmc
#
(
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)   
)
cmc
(
.clk            (clk),
.rst            (rst),

.req_stb        (req_stb),
.req_rid        (req_rid),
.req_tid        (req_tid),       
.req_wid        (req_wid),                
.req_tag        (req_tag),
.req_page       (req_page),
.req_v_addr     (req_v_addr),               

.ack_stb        (ack_stb),
.ack_rid        (ack_rid),
.ack_tid        (ack_tid),       
.ack_wid        (ack_wid),                
.ack_ph_addr    (ack_ph_addr),
.ack_page       (ack_page),
.ack_rdy        (ack_rdy),

.tx_stb         (mtx_stb),
.tx_clr         (mtx_clr),
.tx_tid         (mtx_tid),
.tx_wid         (mtx_wid),
.tx_page        (mtx_page),
.tx_ack         (mtx_ack),

.rx_hdr_stb     (rx_cmc_hdr_stb),
.rx_hdr_ack     (rx_cmc_hdr_ack),
.rx_data_stb    (rx_cmc_data_stb),
.rx_data_flush  (rx_cmc_data_flush),
.rx_data        (rx_cmc_data),
.rx_iid         (rx_cmc_iid),

.mm_w_stb       (mm_w_stb),
.mm_w_wen       (mm_w_wen),
.mm_w_tid       (mm_w_tid),
.mm_w_wid       (mm_w_wid),
.mm_w_page      (mm_w_page),
.mm_w_offset    (mm_w_offset),
.mm_w_data      (mm_w_data)
);  
//=============================================================================================
endmodule