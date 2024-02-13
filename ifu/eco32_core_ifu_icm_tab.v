//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
module eco32_core_ifu_icm_tab
(
input  wire                             clk,

input  wire                             wr_stb,
input  wire                    [3:0]    wr_ptr,
input  wire                   [31:6]    wr_v_addr,
input  wire                    [3:0]    wr_asid,
input  wire                             wr_wid,
input  wire                             wr_tag,
input  wire                             wr_tid,

input  wire                    [3:0]    rd_a_ptr,
output wire                   [31:6]    rd_a_v_addr,
output wire                    [3:0]    rd_a_asid,
output wire                             rd_a_wid,
output wire                             rd_a_tag,
output wire                             rd_a_tid,

input  wire                    [3:0]    rd_b_ptr,
output wire                   [31:6]    rd_b_v_addr,
output wire                             rd_b_wid,
output wire                             rd_b_tid
);                             
//==============================================================================================
// parameters
//==============================================================================================
//==============================================================================================
// variables
//==============================================================================================
(*amstyle = "distributed"*) reg    [31:6] m_vaddr [15:0];
(*amstyle = "distributed"*) reg     [3:0] m_asid  [15:0];
(*amstyle = "distributed"*) reg           m_wid   [15:0];
(*amstyle = "distributed"*) reg           m_tid   [15:0];
(*amstyle = "distributed"*) reg           m_tag   [15:0];
//==============================================================================================
// memory
//==============================================================================================
always@(posedge clk)
if(wr_stb)
    begin
        m_vaddr [wr_ptr]    <= wr_v_addr;
        m_asid  [wr_ptr]    <= wr_asid;
        m_wid   [wr_ptr]    <= wr_wid;
        m_tid   [wr_ptr]    <= wr_tid;
        m_tag   [wr_ptr]    <= wr_tag;
    end
//----------------------------------------------------------------------------------------------
assign  rd_a_v_addr =                                                         m_vaddr[rd_a_ptr];
assign  rd_a_asid   =                                                         m_asid [rd_a_ptr];
assign  rd_a_wid    =                                                         m_wid  [rd_a_ptr];
assign  rd_a_tid    =                                                         m_tid  [rd_a_ptr];
assign  rd_a_tag    =                                                         m_tag  [rd_a_ptr];
//----------------------------------------------------------------------------------------------
assign  rd_b_v_addr =                                                         m_vaddr[rd_b_ptr];
assign  rd_b_wid    =                                                         m_wid  [rd_b_ptr];
assign  rd_b_tid    =                                                         m_tid  [rd_b_ptr];
//==============================================================================================
endmodule