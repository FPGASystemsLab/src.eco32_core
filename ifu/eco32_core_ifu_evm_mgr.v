//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_ifu_evm_mgr
(
input   wire            clk,          
input   wire            rst,          

input   wire            i_stb,                  
input   wire     [3:0]  i_erx,
input   wire     [3:0]  i_eid,
output  wire            i_ack,

output  wire            o_req,       
output  wire     [3:0]  o_eid,       
output  wire     [3:0]  o_erx,
input   wire            o_ack,

input   wire            sys_event_ena
);                             
//==============================================================================================                                     
// parameters
//==============================================================================================
parameter               FORCE_RST   =     0;
//============================================================================================== 
// variables                                                                                      
//==============================================================================================  
reg             event_req;
reg             event_ena;
integer         event_state;           
reg      [3:0]  event_eid;      
reg      [3:0]  event_erx;
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst)                        event_req   <=                                              'd0;
 else                           event_req   <=                           i_stb && sys_event_ena;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        event_ena   <=                                              'd0;
 else                           event_ena   <=                                    sys_event_ena;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        event_state <=                                              'd0;
 else case(event_state)                                                                                                  
 0:         if(event_req)       event_state <=                                              'd1;                          
 1:                             event_state <=                                              'd2; // load params
 2:         if(o_ack)           event_state <=                                              'd3; // wait for ack
 3:         if(!event_ena)      event_state <=                                              'd4; // wait for event disabling     
 4:         if( event_ena)      event_state <=                                              'd5; // wait for event enabling  
 5:                             event_state <=                                              'd0; // goto wait    
 endcase
//----------------------------------------------------------------------------------------------
wire                            f_lde        =                                 event_state == 1;
//----------------------------------------------------------------------------------------------                     
always@(posedge clk or posedge rst)
 if(rst)                        event_eid   <=                                             4'd0;
 else if(f_lde)                 event_eid   <=                                            i_eid;        
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                        event_erx   <=                                             4'd0;
 else if(f_lde)                 event_erx   <=                                            i_erx;        
//----------------------------------------------------------------------------------------------
assign                          i_ack        =                                 event_state == 1;
//==============================================================================================   
// output th0
//==============================================================================================   
assign                          o_req        =                                 event_state=='d2;
assign                          o_eid        =                                        event_eid;
assign                          o_erx        =                                        event_erx;
//==============================================================================================   
endmodule