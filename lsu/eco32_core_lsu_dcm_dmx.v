//=============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================================
`default_nettype none
//---------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================================
module eco32_core_lsu_dcm_dmx
(
input   wire            clk,
input   wire            rst,

input   wire            i_stb,
input   wire            i_sof, 
input   wire    [ 3:0]  i_iid,
input   wire    [71:0]  i_data,

output   wire           rx_hdr_stb,
input    wire           rx_hdr_ack,
output   wire           rx_data_stb,
input    wire           rx_data_flush,
output   wire   [71:0]  rx_data,
output   wire   [ 3:0]  rx_iid
);      
//=============================================================================================
// info
//=============================================================================================
// TID  - target  
//  V       V
// 0x0  - internal 
// 0x1  - internal
// 0x2  - internal
// 0x3  - internal
// 0x4  - internal
// 0x5  - internal
// 0x6  - internal
// 0x7  - internal     

// 0x8  - icache
// 0x9  - dcache
// 0xA  - res
// 0xB  - res
// 0xC  - res
// 0xD  - res  
// 0xE  - event - TLB 
// 0xF  - event - external
//=============================================================================================
// parameters
//=============================================================================================  
parameter           FORCE_RST           =                                                    1;
//=============================================================================================
// variables
//=============================================================================================
reg             s0_stb_cmc;
reg             s0_stb_cmcx;
reg             s0_hdr; 
reg     [71:0]  s0_data;
reg     [ 3:0]  s0_iid;
wire     [1:0]  s0_af_cmc;
//---------------------------------------------------------------------------------------------
reg      [1:0]  buff_af;
//=============================================================================================
wire     [3:0]  rx_sid   =                                                       i_data[47:44];
//---------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)
    begin
        s0_stb_cmc      <=                                                                1'b0;
        s0_stb_cmcx     <=                                                                1'b0;
        s0_hdr          <=                                                                1'b0; 
        s0_data         <=                                                               72'b0;
        s0_iid          <=                                                                4'b0;
    end
 else if(i_stb &  i_sof)
    begin
        s0_stb_cmc      <=                                      (                rx_sid==4'h9);
        s0_stb_cmcx     <=                                      (                rx_sid==4'h9);
        s0_hdr          <=                                                               i_sof;
        s0_data         <=                                                              i_data;
        s0_iid          <=                                                               i_iid;
    end
 else if(i_stb & !i_sof)
    begin
        s0_stb_cmc      <=                                                         s0_stb_cmcx;
        s0_hdr          <=                                                               i_sof;
        s0_data         <=                                                              i_data;
        s0_iid          <=                                                              s0_iid;
    end
 else 
    begin
        s0_stb_cmc      <=                                                                1'b0;
        s0_hdr          <=                                                               i_sof;
        s0_data         <=                                                              i_data;
        s0_iid          <=                                                              s0_iid;                                             
    end
//=============================================================================================
// cmc output
//=============================================================================================
eco32_core_lsu_dcm_pff 
#(
.FORCE_RST          (FORCE_RST)
)
packet_fifo
(
.clk            (clk),
.rst            (rst),   

.i_stb          (s0_stb_cmc),
.i_hdr          (s0_hdr),                                                                                                                                             
.i_data         (s0_data),                                                                                                                                           
.i_iid          (s0_iid),
.i_af           (s0_af_cmc),

.o_hdr_stb      (rx_hdr_stb),
.o_hdr_ack      (rx_hdr_ack),
.o_data_stb     (rx_data_stb),
.o_data_flush   (rx_data_flush),
.o_data         (rx_data),
.o_iid          (rx_iid)
);           
//=============================================================================================   
always@(posedge clk or posedge rst)
 if(rst)        buff_af         <=                                                         'd0;
 else           buff_af         <=                                                   s0_af_cmc;
//=============================================================================================   
endmodule