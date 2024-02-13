//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_lsu_dcu_pwf
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
input  wire                         i_cr_wid,

output wire                         o_pwf,

input  wire                         w_clr,
input  wire                         w_wen,
input  wire                         w_tid,
input  wire                         w_wid,
input  wire  [PAGE_ADDR_WIDTH-1:0]  w_page
);                             
//==============================================================================================
// parameters
//==============================================================================================  
localparam          _PAW            =                                         (PAGE_ADDR_WIDTH);
localparam          _A              =                                         (PAGE_ADDR_WIDTH);
localparam          _T              =                                      1<<(PAGE_ADDR_WIDTH);
//==============================================================================================
// variables
//==============================================================================================  
`ifdef ALTERA
reg               t0_pwf_w0 [_T-1:0]/* synthesis syn_ramstyle="no_rw_check,MLAB" */;                
reg               t0_pwf_w1 [_T-1:0]/* synthesis syn_ramstyle="no_rw_check,MLAB" */; 
`else
reg               t0_pwf_w0 [_T-1:0]/* synthesis syn_ramstyle="select_ram,no_rw_check" */;                
reg               t0_pwf_w1 [_T-1:0]/* synthesis syn_ramstyle="select_ram,no_rw_check" */; 
`endif                         
reg               t0_we0;
reg               t0_we1;
reg               t0_di;
reg     [_A-1:0]  t0_addr;
//---------------------------------------------------------------------------------------------- 
`ifdef ALTERA
reg               t1_pwf_w0 [_T-1:0]/* synthesis syn_ramstyle="no_rw_check,MLAB" */;                
reg               t1_pwf_w1 [_T-1:0]/* synthesis syn_ramstyle="no_rw_check,MLAB" */; 
`else
reg               t1_pwf_w0 [_T-1:0]/* synthesis syn_ramstyle="select_ram,no_rw_check" */;                
reg               t1_pwf_w1 [_T-1:0]/* synthesis syn_ramstyle="select_ram,no_rw_check" */; 
`endif                                       
reg               t1_we0;
reg               t1_we1;
reg               t1_di;
reg     [_A-1:0]  t1_addr;
//----------------------------------------------------------------------------------------------
reg               ti_wid;
reg               ti_tid;
//==============================================================================================
// page write detector
//==============================================================================================
// T0 way
//==============================================================================================
always@(posedge clk or posedge rst) 
 if(rst)
    begin
        t0_we0              <=                                                              'd0;
        t0_we1              <=                                                              'd0;
        t0_di         <=                                                                       'd0;
        t0_addr             <=                                                              'd0;
    end     
else if(w_tid==1'd0 & w_clr)
    begin
        t0_we0              <=                                             (w_wid==1'b0) & w_wen;
        t0_we1              <=                                             (w_wid==1'b1) & w_wen;
        t0_di               <=                                                              1'd0;
        t0_addr             <=                                                            w_page;
    end
else if(i_tid==1'd0)
    begin
        t0_we0              <=                                             (i_wid==1'b0) & i_wen;
        t0_we1              <=                                             (i_wid==1'b1) & i_wen;
        t0_di               <=                                                              1'd1;
        t0_addr             <=                                                            i_page;
    end
else if(w_tid==1'd0)
    begin
        t0_we0              <=                                             (w_wid==1'b0) & w_wen;
        t0_we1              <=                                             (w_wid==1'b1) & w_wen;
        t0_di               <=                                                              1'd0;
        t0_addr             <=                                                            w_page;
    end
else 
    begin
        t0_we0              <=                                                              'd0;
        t0_we1              <=                                                              'd0;
        t0_di               <=                                                              'd0;
        t0_addr             <=                                                              'd0;
    end
//----------------------------------------------------------------------------------------------
always@(posedge clk) 
 if(t0_we0) 
     begin  
        t0_pwf_w0 [t0_addr] <= t0_di;
     end
//----------------------------------------------------------------------------------------------
always@(posedge clk) 
 if(t0_we1) 
     begin  
        t0_pwf_w1 [t0_addr] <= t0_di;
     end
//==============================================================================================
// T0 way
//==============================================================================================
always@(posedge clk or posedge rst) 
 if(rst)
    begin
        t1_we0              <=                                                             1'd0;
        t1_we1              <=                                                             1'd0;
        t1_di               <=                                                             1'd0;
        t1_addr             <=                                                              'd0;
    end     
else if(w_tid==1'd1 & w_clr)
    begin
        t1_we0              <=                                            (w_wid==1'b0) & w_wen;
        t1_we1              <=                                            (w_wid==1'b1) & w_wen;
        t1_di               <=                                                             1'd0;
        t1_addr             <=                                                           w_page;
    end
else if(i_tid==1'd1)
    begin
        t1_we0              <=                                            (i_wid==1'b0) & i_wen;
        t1_we1              <=                                            (i_wid==1'b1) & i_wen;
        t1_di               <=                                                             1'd1;
        t1_addr             <=                                                   {i_wid,i_page};
    end
else if(w_tid==1'd1)
    begin
        t1_we0              <=                                            (w_wid==1'b0) & w_wen;
        t1_we1              <=                                            (w_wid==1'b1) & w_wen;
        t1_di               <=                                                             1'd0;
        t1_addr             <=                                                           w_page;
    end
else 
    begin
        t1_we0              <=                                                              'd0;
        t1_we1              <=                                                              'd0;
        t1_di               <=                                                              'd0;
        t1_addr             <=                                                              'd0;
    end
//----------------------------------------------------------------------------------------------
always@(posedge clk) 
 if(t1_we0) 
     begin  
        t1_pwf_w0 [t1_addr] <=                                                            t1_di;
     end
//----------------------------------------------------------------------------------------------
always@(posedge clk) 
 if(t1_we1) 
     begin  
        t1_pwf_w1 [t1_addr] <=                                                            t1_di;
     end
//==============================================================================================
// output
//==============================================================================================
always@(posedge clk or posedge rst) 
 if(rst)
    begin
        ti_wid              <=                                                              'd0;
        ti_tid              <=                                                              'd0;
    end     
else 
    begin
        ti_wid              <=                                                         i_cr_wid;
        ti_tid              <=                                                            i_tid;
    end
//----------------------------------------------------------------------------------------------
wire        pwf_t0           = (ti_wid) ?               t0_pwf_w1[t0_addr] : t0_pwf_w0[t0_addr];
wire        pwf_t1           = (ti_wid) ?               t1_pwf_w1[t1_addr] : t1_pwf_w0[t1_addr];
//----------------------------------------------------------------------------------------------
assign      o_pwf            = (ti_tid) ?                                       pwf_t1 : pwf_t0;
//==============================================================================================
endmodule