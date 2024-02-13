//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_lsu_dcu_mem
# // parameters
( 
 parameter  PAGE_ADDR_WIDTH = 'd5
)
// ports
(
input  wire                         clk,
input  wire                         rst,

input  wire                         i_wen,
input  wire                         i_tid,
input  wire                         i_wid,
input  wire  [PAGE_ADDR_WIDTH-1:0]  i_page,
input  wire                  [2:0]  i_offset,     
input  wire                  [7:0]  i_data,

output wire                         o_ben,
output wire                  [7:0]  o_data,

input  wire                         xi_stb,
input  wire                         xi_wen,
input  wire                         xi_tid,
input  wire                         xi_wid,
input  wire  [PAGE_ADDR_WIDTH-1:0]  xi_page,
input  wire                  [2:0]  xi_offset,    
input  wire                  [7:0]  xi_data,

output wire                         xo_val,
output wire                         xo_ben,
output wire                  [7:0]  xo_data
);                             
//==============================================================================================
// parameters
//==============================================================================================  
localparam          _PAW               =                                        PAGE_ADDR_WIDTH;
localparam          _A                 =      (PAGE_ADDR_WIDTH + 1 /*2-wyas*/ + 1 /*2-th*/ + 3);
localparam          _T                 =   1<<(PAGE_ADDR_WIDTH + 1 /*2-wyas*/ + 1 /*2-th*/ + 3);   
//==============================================================================================
// variables
//============================================================================================== 
reg            [8:0]  mem [_T-1:0]; /* synthesis syn_ramstyle="no_rw_check" */                         
//----------------------------------------------------------------------------------------------
wire        [_A-1:0]  ai_addr;
reg            [8:0]  ao_data;
//----------------------------------------------------------------------------------------------
wire        [_A-1:0]  bi_addr;
reg            [8:0]  bo_data;
//----------------------------------------------------------------------------------------------
reg                   rd_ena;
//==============================================================================================
// memory
//==============================================================================================
assign  ai_addr     =                                   {i_wid,i_tid,i_page[_PAW-1:0],i_offset}; 
//==============================================================================================
always@(posedge clk)
    begin
        ao_data             <= mem[ai_addr];
        if(i_wen) 
                mem[ai_addr]<= {1'b1,i_data};
    end 
//----------------------------------------------------------------------------------------------
assign  o_data               = ao_data[7:0];        
assign  o_ben                = ao_data[8];        
//==============================================================================================
assign  bi_addr     =                               {xi_wid,xi_tid,xi_page[_PAW-1:0],xi_offset}; 
wire    bi_wen      =                                                          xi_wen && xi_stb;
//==============================================================================================
always@(posedge clk) 
    begin
        bo_data             <= mem[bi_addr];
        if(xi_wen && xi_stb)    
            mem[bi_addr]    <= {1'b0,xi_data};
    end     
//----------------------------------------------------------------------------------------------
assign  {xo_ben,xo_data}     = bo_data;
//==============================================================================================
always@(posedge clk or posedge rst) 
 if(rst)        rd_ena      <= 1'b0;
 else           rd_ena      <= xi_stb && !xi_wen;
//----------------------------------------------------------------------------------------------
assign          xo_val       = rd_ena;
//==============================================================================================
endmodule