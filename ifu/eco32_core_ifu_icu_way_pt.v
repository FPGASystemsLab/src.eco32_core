//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
// hierarchy:
// processor core (TOP)
// + instruction fetch 
//   + instruction cache way 
//     + page desritption table
//==============================================================================================
module eco32_core_ifu_icu_way_pt
#
(
parameter [5:0] PAGE_ADDR_WIDTH  = 6'h5
)
(
input  wire                         clk,
input  wire                         rst,

input  wire                         i_tid,
input  wire  [PAGE_ADDR_WIDTH-1:0]  i_page,

input  wire                         wr_ena,
input  wire                         wr_tid,
input  wire  [PAGE_ADDR_WIDTH-1:0]  wr_page,
input  wire                 [35:0]  wr_descriptor,
 
output wire                 [35:0]  o_descriptor
);                             
//==============================================================================================
// parameters
//==============================================================================================
localparam          _PAW                =                                      PAGE_ADDR_WIDTH ;
localparam          _A                  =                           1/*TID*/ + PAGE_ADDR_WIDTH ;
localparam          _T                  =                       1<<(1/*TID*/ + PAGE_ADDR_WIDTH);   
//==============================================================================================
// variables
//==============================================================================================   
(*ramstyle="distributed"*)      reg         [  35 : 0]  ptable [_T-1:0];
                                wire        [_A-1 : 0]  wr_addr;
                                wire        [_A-1 : 0]  rd_addr;
                                reg         [  35 : 0]  rd_descriptor;
//==============================================================================================
// memory
//==============================================================================================
assign  wr_addr         =                                            {wr_page[_PAW-1:0],wr_tid};
assign  rd_addr         =                                            { i_page[_PAW-1:0], i_tid};
//----------------------------------------------------------------------------------------------
always@(posedge clk) 
 begin
    if(wr_ena) ptable[wr_addr]  <= wr_descriptor;
 end                                        
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst) 
 if(rst)        rd_descriptor   <=                                                          'd0;
 else           rd_descriptor   <=                                              ptable[rd_addr];
//----------------------------------------------------------------------------------------------
assign  o_descriptor    =                                                         rd_descriptor;
//==============================================================================================
endmodule