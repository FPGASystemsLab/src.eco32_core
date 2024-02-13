//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
// hierarchy:
// processor core (TOP)
// + load/store unit
//   + data cache way 
//     + page desritption table
//==============================================================================================
module eco32_core_lsu_dcu_pt
# // parameters
( 
 parameter  PAGE_ADDR_WIDTH = 'd5
)
// ports
(
input  wire                         clk,

input  wire                         i_tid,
input  wire  [PAGE_ADDR_WIDTH-1:0]  i_page,

input  wire                         wr_ena,
input  wire                         wr_tid,
input  wire  [PAGE_ADDR_WIDTH-1:0]  wr_page,
input  wire                 [38:0]  wr_descriptor,
 
output wire                 [38:0]  o_descriptor 
);                             
//==============================================================================================
// local params
//==============================================================================================
localparam      _PAW        =                                                   PAGE_ADDR_WIDTH;    
localparam          _A      =                                               1 + PAGE_ADDR_WIDTH;
localparam          _T      =                                            1<<(1+PAGE_ADDR_WIDTH);       
//==============================================================================================
// variables                                                                                               
//============================================================================================== 
`ifdef ALTERA
 reg         [  38 : 0]  ptable [_T-1:0] /* synthesis syn_ramstyle="no_rw_check,MLAB" */;
`else
 reg         [  38 : 0]  ptable [_T-1:0]/* synthesis syn_ramstyle="select_ram,no_rw_check" */;
`endif          
                                    wire        [_A-1 : 0]  wr_addr;
                                    wire        [_A-1 : 0]  rd_addr;
//==============================================================================================
// memory
//==============================================================================================
assign  wr_addr         =                                            {wr_page[_PAW-1:0],wr_tid};
assign  rd_addr         =                                            { i_page[_PAW-1:0], i_tid};
//----------------------------------------------------------------------------------------------
always@(posedge clk) if(wr_ena) ptable[wr_addr] <= wr_descriptor;
//----------------------------------------------------------------------------------------------
assign  o_descriptor    =                                                       ptable[rd_addr];
//==============================================================================================
endmodule