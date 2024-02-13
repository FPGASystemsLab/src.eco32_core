//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
module eco32_core_ifu_evm_box
(
 input  wire                            clk,
 input  wire                            rst,

 input  wire                            epp_i_stb,
 input  wire                            epp_i_sof,
 input  wire                    [71:0]  epp_i_data,                                       

 input  wire                     [1:0]  sys_event_ena,

 output wire                            evt_th0_req,
 output wire                     [3:0]  evt_th0_eid,
 output wire                     [3:0]  evt_th0_erx,
 input  wire                            evt_th0_ack,
 
 output wire                            evt_th1_req,
 output wire                     [3:0]  evt_th1_eid,
 output wire                     [3:0]  evt_th1_erx,
 input  wire                            evt_th1_ack,
 
 output wire                     [8:0]  wrx
);                                     
//==============================================================================================
//  params
//==============================================================================================
parameter               FORCE_RST   =     0;
//==============================================================================================
// variables
//==============================================================================================
(* shreg_extract = "NO"  *) reg                 s0_stb;    
(* shreg_extract = "NO"  *) reg                 s0_evt_det;
(* shreg_extract = "NO"  *) reg                 s0_evt_stb;
(* shreg_extract = "NO"  *) reg                 s0_hdr;    
(* shreg_extract = "NO"  *) reg     [71:0]  s0_data;   
(* shreg_extract = "NO"  *) reg      [3:0]  s0_sid;
(* shreg_extract = "NO"  *) reg                 s0_tid;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg      [8:0]  s1_stb;
(* shreg_extract = "NO"  *) reg      [3:0]  s1_eid;
(* shreg_extract = "NO"  *) reg      [3:0]  s1_erx;
(* shreg_extract = "NO"  *) reg                 s1_tid;
(* shreg_extract = "NO"  *) reg                 s1_stb0;
(* shreg_extract = "NO"  *) reg                 s1_stb1;
(* shreg_extract = "NO"  *) reg     [71:0]  s1_buff;
//----------------------------------------------------------------------------------------------
// th0
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg      [3:0]  th0_erx_cnt;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg                 th0_evt_stb;
(* shreg_extract = "NO"  *) reg     [3:0]   th0_evt_erx;
(* shreg_extract = "NO"  *) reg     [3:0]   th0_evt_eid;
                                     wire                   th0_evt_af;
//----------------------------------------------------------------------------------------------
                                     wire                   th0_req_stb;
                                     wire       [3:0]   th0_req_erx;
                                     wire       [3:0]   th0_req_eid;
                                     wire           th0_req_ack;
//----------------------------------------------------------------------------------------------
// th1
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg     [3:0]       th1_erx_cnt;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             th1_evt_stb;
(* shreg_extract = "NO"  *) reg       [3:0] th1_evt_erx;
(* shreg_extract = "NO"  *) reg       [3:0] th1_evt_eid;
                            wire            th1_evt_af;
//----------------------------------------------------------------------------------------------
                                     wire               th1_req_stb;
                                     wire       [3:0] th1_req_erx;
                                     wire       [3:0] th1_req_eid;
                                     wire               th1_req_ack;
//==============================================================================================   
// detect event packet
//==============================================================================================   
wire     [3:0]  epp_sid   =                                                   epp_i_data[47:44];
wire            epp_tid   =                                                   epp_i_data[48];
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)
    begin
        s0_stb          <=                                                                1'b0;
        s0_evt_det      <=                                                                1'b0;
        s0_evt_stb      <=                                                                1'b0;
        s0_hdr          <=                                                                1'b0;
        s0_data         <=                                                               72'b0;
        s0_sid          <=                                                                4'd0;
        s0_tid          <=                                                                1'd0;
    end
 else if(epp_i_stb &  epp_i_sof)                                                                                                                                                              
    begin
        s0_stb          <=                                                                1'b1;
        s0_evt_det      <=                                    (epp_sid==4'hE || epp_sid==4'hF);
        s0_evt_stb      <=                                                                1'b0;
        s0_hdr          <=                                                           epp_i_sof;
        s0_data         <=                                                          epp_i_data;
        s0_sid          <=                                                             epp_sid;
        s0_tid          <=                                                             epp_tid;
    end
 else if(epp_i_stb & !epp_i_sof)
    begin
        s0_stb          <=                                                                1'b1;
        s0_evt_det      <=                                                                1'b0;
        s0_evt_stb      <=                                                          s0_evt_det;
        s0_hdr          <=                                                           epp_i_sof;                                        
        s0_data         <=                                                          epp_i_data;
    end
 else 
    begin                                                                                                          
        s0_stb          <=                                                                1'b0;                    
        s0_evt_det      <=                                                                1'b0;
        s0_evt_stb      <=                                                                1'b0;
        s0_hdr          <=                                                           epp_i_sof;
        s0_data         <=                                                          epp_i_data;                                              
        s0_sid          <=                                                                4'd0;
        s0_tid          <=                                                                1'd0;
    end
//==============================================================================================              
// thread0 erx pointer
//==============================================================================================              
always@(posedge clk or posedge rst)
 if(rst)                th0_erx_cnt <=                                                      'd0;
 else if(th0_evt_stb)   th0_erx_cnt <=                                        th0_erx_cnt + 'd1;
//==============================================================================================              
// thread1 erx pointer
//==============================================================================================              
always@(posedge clk or posedge rst)
 if(rst)                th1_erx_cnt <=                                                      'd0;
 else if(th1_evt_stb)   th1_erx_cnt <=                                        th1_erx_cnt + 'd1;
//==============================================================================================              
// send event data via ev_bus to event reg                                                                   
//==============================================================================================   
wire     [3:0]              evx_addr    = s0_tid ?                    th1_erx_cnt : th0_erx_cnt;
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    s1_stb      <=                                                  'd0;
 else if(s0_evt_stb)        s1_stb      <=                                               9'h100;     
 else                       s1_stb      <=                                   {1'b0,s1_stb[8:1]};     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    s1_eid      <=                                                  'd0;
 else if(s0_evt_stb)        s1_eid      <=  (s0_sid == 'hE ) ?                              'd4:     
                                            (s0_sid == 'hF ) ?                              'd4:
                                                                                            'd7;    
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    s1_erx      <=                                                  'd0;
 else if(s0_evt_stb)        s1_erx      <=                                             evx_addr;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    s1_tid      <=                                                  'd0;
 else if(s0_evt_stb)        s1_tid      <=                                               s0_tid;     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    s1_buff     <=                                                  'd0;
 else if(s0_evt_stb)        s1_buff     <=                 {3'd0,s0_tid,evx_addr,s0_data[63:0]};     
 else                       s1_buff     <=                                 {8'd0,s1_buff[71:8]};     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    s1_stb0     <=                                                  'd0;
 else                       s1_stb0     <=                            s1_stb[0] & (s1_tid=='d0);     
//----------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst)
 if(rst)                    s1_stb1     <=                                                  'd0;
 else                       s1_stb1     <=                            s1_stb[0] & (s1_tid=='d1);     
//==============================================================================================   
assign                      wrx         =                              {s1_stb[0],s1_buff[7:0]};    
//==============================================================================================  
always@(posedge clk or posedge rst)
 if(rst)
    begin
        th0_evt_stb     <=                                                                  'd0;
        th0_evt_erx     <=                                                                  'd0;
        th0_evt_eid     <=                                                                  'd0;
    end
 else if(s1_stb0)
    begin
        th0_evt_stb     <=                                                                 1'b1;
        th0_evt_erx     <=                                                               s1_erx;
        th0_evt_eid     <=                                                               s1_eid;
    end
 else 
    begin
        th0_evt_stb     <=                                                                  'd0;
        th0_evt_erx     <=                                                                  'd0;
        th0_evt_eid     <=                                                                  'd0;
    end
//==============================================================================================  
// Thread 0 event handling
//==============================================================================================  
// FIFO for event request (th0)
//---------------------------------------------------------------------------------------------- 
// pragma translate_off
initial
  begin         
    $display( "%m: TODO: eco32_core_ifu_evm_ff oczekuje 5-cio bitowego i_erx a jest 4-ro" );          
  end
// pragma translate_on   
//---------------------------------------------------------------------------------------------- 
eco32_core_ifu_evm_ff evu_input_ff_th0
(
.clk                (clk),          
.rst                (rst),          

.i_stb              (th0_evt_stb),
.i_erx              (th0_evt_erx),
.i_eid              (th0_evt_eid),
.i_af               (th0_evt_af),

.o_stb              (th0_req_stb),
.o_erx              (th0_req_erx),
.o_eid              (th0_req_eid),
.o_ack              (th0_req_ack)
);
//----------------------------------------------------------------------------------------------
// Thread 0 event initiator
//----------------------------------------------------------------------------------------------
eco32_core_ifu_evm_mgr 
#(
.FORCE_RST          (FORCE_RST)
)
 evu_mgr_th0
(
.clk                (clk),          
.rst                (rst),          

.i_stb              (th0_req_stb),
.i_erx              (th0_req_erx),
.i_eid              (th0_req_eid),
.i_ack              (th0_req_ack),

.o_req              (evt_th0_req),       
.o_erx              (evt_th0_erx),
.o_eid              (evt_th0_eid),       
.o_ack              (evt_th0_ack),

.sys_event_ena      (sys_event_ena[0])
);  
//==============================================================================================  
// Thread 0 event handling
//==============================================================================================  
always@(posedge clk or posedge rst)
 if(rst)
    begin
        th1_evt_stb     <=                                                                  'd0;
        th1_evt_erx     <=                                                                  'd0;
        th1_evt_eid     <=                                                                  'd0;
    end
 else if(s1_stb1)
    begin
        th1_evt_stb     <=                                                                 1'b1;
        th1_evt_erx     <=                                                               s1_erx;
        th1_evt_eid     <=                                                               s1_eid;
    end
 else 
    begin
        th1_evt_stb     <=                                                                  'd0;
        th1_evt_erx     <=                                                                  'd0;
        th1_evt_eid     <=                                                                  'd0;
    end
//----------------------------------------------------------------------------------------------
// FIFO for event request (th1)
//----------------------------------------------------------------------------------------------
eco32_core_ifu_evm_ff evu_input_ff_th1
(
.clk                (clk),          
.rst                (rst),          

.i_stb              (th1_evt_stb),
.i_erx              (th1_evt_erx),
.i_eid              (th1_evt_eid),
.i_af               (th1_evt_af),

.o_stb              (th1_req_stb),
.o_erx              (th1_req_erx),
.o_eid              (th1_req_eid),
.o_ack              (th1_req_ack)
);
//----------------------------------------------------------------------------------------------
// Thread 1 event initiator
//----------------------------------------------------------------------------------------------
eco32_core_ifu_evm_mgr 
#(
.FORCE_RST          (FORCE_RST)
)
evu_mgr_th1
(
.clk                (clk),          
.rst                (rst),          

.i_stb              (th1_req_stb),
.i_erx              (th1_req_erx),
.i_eid              (th1_req_eid),
.i_ack              (th1_req_ack),

.o_req              (evt_th1_req),       
.o_eid              (evt_th1_eid),       
.o_erx              (evt_th1_erx),
.o_ack              (evt_th1_ack),

.sys_event_ena      (sys_event_ena[1])
);
//==============================================================================================  
endmodule