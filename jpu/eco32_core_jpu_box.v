//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_jpu_box
(
 input  wire            clk,
 input  wire            rst,   
 
 // iput from IDU
 
 input  wire            i_stb,
 input  wire            i_tid,
 input  wire     [3:0]  i_asid,
 input  wire     [1:0]  i_pid,
 input  wire    [15:0]  i_isw,
 input  wire    [31:0]  i_iva,
 input  wire            i_evt_req,
 input  wire     [3:0]  i_evt_eid,
 
 input  wire    [11:0]  i_jp_cw,     
 
 input  wire    [31:0]  i_r0_data,    
 input  wire    [31:0]  i_r2_data,     
 input  wire    [31:0]  i_r3_data,

 // input from MPU
 
 input  wire            fci_inst_lsf,
 input  wire            fci_inst_skip,
 input  wire            fci_inst_rep,
 output wire            fco_inst_jpf,

 input  wire     [1:0]  jcr_wen,
 input  wire            jcr_tid,
 input  wire     [3:0]  jcr_addr,
 input  wire    [31:0]  jcr_dataL,
 input  wire    [31:0]  jcr_dataH,
 
 // output 
 
 output wire            o_stb,
 output wire            o_evt_ack,
 output wire     [3:0]  o_asid,
 output wire     [1:0]  o_pid,
 output wire    [15:0]  o_isw,
 output wire    [31:0]  o_v_addr 
);                             
//==============================================================================================
//  params
//==============================================================================================
parameter               FORCE_RST   =     0;
//==============================================================================================
// variables
//==============================================================================================
(*ramstyle="distributed" *) reg [31:0] cra [31:0];
(*ramstyle="distributed" *) reg [31:0] crb [31:0];
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             a0_stb;
(* shreg_extract = "NO"  *) reg             a0_tid;
(* shreg_extract = "NO"  *) reg             a0_evt_req;
(* shreg_extract = "NO"  *) reg      [3:0]  a0_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_pid;
(* shreg_extract = "NO"  *) reg     [15:0]  a0_isw;
                                                                                                                                                                                              
(* shreg_extract = "NO"  *) reg             a0_jp_ena;      
(* shreg_extract = "NO"  *) reg             a0_jp_cre;
(* shreg_extract = "NO"  *) reg      [3:0]  a0_jp_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  a0_jp_pid;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_jp_baseGP;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_jp_baseCR;
(* shreg_extract = "NO"  *) reg     [31:0]  a0_jp_offset;
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b1_stb;
(* shreg_extract = "NO"  *) reg             b1_evt_ack;
(* shreg_extract = "NO"  *) reg     [15:0]  b1_isw;

(* shreg_extract = "NO"  *) reg      [3:0]  b1_jp_asid;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_jp_pid;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_jp_v_addr;       
//==============================================================================================
// syscall entry registers 
//==============================================================================================
always@(posedge clk)
 if(jcr_wen[0]) cra [{jcr_tid,jcr_addr}] <=                                           jcr_dataL;
//----------------------------------------------------------------------------------------------
wire    [31:0]  cra_addr     =                                      cra [{i_tid,i_jp_cw[10:7]}];
//----------------------------------------------------------------------------------------------             
always@(posedge clk)                                                                                         
 if(jcr_wen[1]) crb [{jcr_tid,jcr_addr}] <=                                           jcr_dataH;
//----------------------------------------------------------------------------------------------
wire    [31:0]  crb_addr     =                                      crb [{i_tid,i_jp_cw[10:7]}];
//==============================================================================================    
// stage a0
//==============================================================================================    
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         															  
    a0_stb                  <=                                                             1'b0;
    a0_tid                  <=                                                             1'b0;
    a0_evt_req              <=                                                             1'b0;
    a0_asid                 <=                                                             4'b0;
    a0_pid                  <=                                                             2'b0;
    a0_isw                  <=                                                            16'b0;        
   
    a0_jp_cre               <=                                                             1'b0;
    a0_jp_asid              <=                                                             4'b0;
    a0_jp_pid               <=                                                             2'b0;
    a0_jp_baseCR            <=                                                            32'd0;
    a0_jp_baseGP            <=                                                            32'd0;
    a0_jp_offset            <=                                                            32'd0;
  end
 else
  begin
    a0_stb                  <=                                   !b1_stb && i_jp_cw[0] && i_stb;
    a0_tid                  <=                                                            i_tid;
    a0_evt_req              <=                                                        i_evt_req;
    a0_asid                 <=                                                           i_asid;
    a0_pid                  <=                                                            i_pid;
    a0_isw                  <=                                                   crb_addr[15:0];
       
    a0_jp_ena               <=                                                       i_jp_cw[0];
    a0_jp_cre               <=                                                       i_jp_cw[4];
    a0_jp_asid              <=                                                    crb_addr[3:0];
    a0_jp_pid               <=                                                     i_jp_cw[2:1];
    a0_jp_baseCR            <=  (i_jp_cw[11])?    {cra_addr[31:3],3'd0} : {cra_addr[31:2],2'd0};
    a0_jp_baseGP            <=                                                       i_r0_data ;
    a0_jp_offset            <=  (i_jp_cw[4] && i_jp_cw[3]==1'b0)?                    i_r2_data : // EID = const
                                (i_jp_cw[4] && i_jp_cw[3]==1'b1)? {19'd0,i_r2_data[ 9:0],3'd0} : // EID = reg
                                                                                     i_r2_data ; // regular mode
  end
//==============================================================================================
// stage b(1): 
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin                                                                         
    b1_stb                  <=                                                             1'b0;
    b1_isw                  <=                                                            16'b0;
    b1_evt_ack              <=                                                              'b0;
    
    b1_jp_asid              <=                                                             4'b0;
    b1_jp_pid               <=                                                             2'b0;
    b1_jp_v_addr            <=                                                            32'd0;     
  end
 else
  begin
    b1_stb                  <=       !fci_inst_lsf && !fci_inst_rep && !fci_inst_skip && a0_stb;
    b1_isw                  <= (a0_jp_cre)?                                      a0_isw : 16'd0;        
    b1_evt_ack              <=                            !fci_inst_lsf && a0_evt_req && a0_stb;

    b1_jp_asid              <= (1'b1) ?                                    a0_asid : a0_jp_asid;
    b1_jp_pid               <=                                                        a0_jp_pid;
    b1_jp_v_addr            <=      ( a0_jp_cre ?  a0_jp_baseCR : a0_jp_baseGP ) + a0_jp_offset;
  end
//==============================================================================================
// output
//==============================================================================================
assign  o_stb                =                                                           b1_stb;
assign  o_isw                =                                                           b1_isw;
assign  o_evt_ack            =                                                       b1_evt_ack;
assign  o_asid               =                                                       b1_jp_asid;
assign  o_pid                =                                                        b1_jp_pid;
assign  o_v_addr             =                                                     b1_jp_v_addr;       
//----------------------------------------------------------------------------------------------
assign  fco_inst_jpf         =                                                           b1_stb;
//==============================================================================================
endmodule
