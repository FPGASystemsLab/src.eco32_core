//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
module eco32_core_ifu_icu_way
# // parameters
( 
 parameter [5:0] PAGE_ADDR_WIDTH = 6'd5,
 parameter                  FORCE_RST       =   0
)
// ports
(
 input  wire                            clk,
 input  wire                            rst,

 input  wire                            i_stb,
 input  wire                            i_tid,
 input  wire                     [1:0]  i_pid,
 input  wire                     [3:0]  i_asid,
 input  wire                    [31:0]  i_v_addr,
 
 input  wire                            mm_wr_stb,
 input  wire                            mm_wr_tid,
 input  wire     [PAGE_ADDR_WIDTH-1:0]  mm_wr_page,
 input  wire                     [2:0]  mm_wr_offset,
 input  wire                    [71:0]  mm_wr_data, 
 
 input  wire                            pt_wr_stb,
 input  wire                            pt_wr_tid,
 input  wire     [PAGE_ADDR_WIDTH-1:0]  pt_wr_page,
 input  wire                    [35:0]  pt_wr_descriptor,
 
 output wire                            o_hit,
 output wire                            o_miss,
 output wire                            o_locked,
 output wire                            o_empty,
 output wire                            o_tag,
 
 output wire                            o_exc,
 output wire                     [3:0]  o_exc_ida,
 output wire                     [3:0]  o_exc_idp,
 output wire                     [3:0]  o_exc_idt,     
 
 output wire                    [71:0]  o_data,
 
 output wire                            o_inst_skip,
 output wire                            o_inst_ext, 
            
 output wire                     [2:0]  o_cmod_lo,  
 output wire                     [1:0]  o_cmod_mi,  
 output wire                     [2:0]  o_cmod_hi  
);                                     
//==============================================================================================
// local params
//==============================================================================================
localparam      _PAW        =                                                   PAGE_ADDR_WIDTH;    
//==============================================================================================
// variables
//==============================================================================================
// stage b1 : pt
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b1_stb;
(* shreg_extract = "NO"  *) reg             b1_tid;
(* shreg_extract = "NO"  *) reg      [1:0]  b1_pid;
(* shreg_extract = "NO"  *) reg      [3:0]  b1_asid;
(* shreg_extract = "NO"  *) reg     [31:0]  b1_iva;
                            wire    [35:0]  b1_entry;    
                            wire    [71:0]  b1_data;    
(* shreg_extract = "NO"  *) reg             b1_col;
//----------------------------------------------------------------------------------------------
// stage a2 : pt
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             a2_stb;
(* shreg_extract = "NO"  *) reg             a2_tid;
(* shreg_extract = "NO"  *) reg      [1:0]  a2_pid;
(* shreg_extract = "NO"  *) reg      [3:0]  a2_asid;
(* shreg_extract = "NO"  *) reg     [31:0]  a2_iva;
(* shreg_extract = "NO"  *) reg     [35:0]  a2_entry;    
(* shreg_extract = "NO"  *) reg             a2_col;
(* shreg_extract = "NO"  *) reg     [71:0]  a2_data;      
(* shreg_extract = "NO"  *) reg             a2_ext3A;
(* shreg_extract = "NO"  *) reg             a2_ext3B;
(* shreg_extract = "NO"  *) reg             a2_ext;

                            wire    [2:0]   a2_mux_hi;
                            wire    [1:0]   a2_mux_mi;
                            wire    [2:0]   a2_mux_lo;
//----------------------------------------------------------------------------------------------
                            wire            a2_way_valid; 
                            wire    [31:0]  a2_way_v_addr;
                            wire            a2_way_av;  
                            wire            a2_way_locked;  
                            wire            a2_way_tag;  
                            wire            a2_way_wrt; 
                            wire     [1:0]  a2_way_pid;                             
                            wire            a2_way_exe; 
                            wire            a2_way_rd;  
                            wire            a2_way_wr;  
                            wire            a2_way_dbg; 
                            wire     [5:0]  a2_way_asid; 
                            wire            a2_way_aerr; 
//----------------------------------------------------------------------------------------------
// stage b3 : pt
//----------------------------------------------------------------------------------------------
(* shreg_extract = "NO"  *) reg             b3_stb;
(* shreg_extract = "NO"  *) reg             b3_tid;
(* shreg_extract = "NO"  *) reg      [1:0]  b3_pid;
(* shreg_extract = "NO"  *) reg     [63:0]  b3_data;
(* shreg_extract = "NO"  *) reg             b3_inst_skip;
(* shreg_extract = "NO"  *) reg             b3_inst_ext;    
(* shreg_extract = "NO"  *) reg      [2:0]  b3_cmod_loE;                           
(* shreg_extract = "NO"  *) reg      [1:0]  b3_cmod_miE;                           
(* shreg_extract = "NO"  *) reg      [2:0]  b3_cmod_hiE;                           

(* shreg_extract = "NO"  *) reg             b3_hit;
(* shreg_extract = "NO"  *) reg             b3_miss;
(* shreg_extract = "NO"  *) reg             b3_locked;
(* shreg_extract = "NO"  *) reg             b3_empty;
(* shreg_extract = "NO"  *) reg             b3_tag;

(* shreg_extract = "NO"  *) reg             b3_exc; 
(* shreg_extract = "NO"  *) reg      [3:0]  b3_exc_ida; 
(* shreg_extract = "NO"  *) reg      [3:0]  b3_exc_idp; 
(* shreg_extract = "NO"  *) reg      [3:0]  b3_exc_idt; 
//==============================================================================================
// alias
//==============================================================================================
wire     [_PAW-1:0] i_page  =                                            {i_v_addr[_PAW-1+6:6]};
//==============================================================================================
// stage b1
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b1_stb              <=                                                                  'b0;
    b1_tid              <=                                                                  'b0;
    b1_pid              <=                                                                  'b0;
    b1_iva              <=                                                                  'b0;
    b1_asid             <=                                                                  'b0;
    b1_col              <=                                                                  'b0;
  end
 else 
  begin
    b1_stb              <=                                                                i_stb;
    b1_tid              <=                                                                i_tid;
    b1_pid              <=                                                                i_pid;
    b1_iva              <=                                                             i_v_addr;
    b1_asid             <=                                                               i_asid;
    b1_col              <=              pt_wr_stb && (pt_wr_tid==i_tid) && (pt_wr_page==i_page);
  end    
//==============================================================================================
// instructon cache table
//==============================================================================================
eco32_core_ifu_icu_way_pt
#(                                                                                                    
.PAGE_ADDR_WIDTH    (PAGE_ADDR_WIDTH)
)
ict
(
.clk                (clk),                                                                                
.rst                (rst),

.i_tid              (i_tid),
.i_page             (i_page),

.wr_ena             (pt_wr_stb),
.wr_tid             (pt_wr_tid),
.wr_page            (pt_wr_page),
.wr_descriptor      (pt_wr_descriptor),

.o_descriptor       (b1_entry)
);     
//==============================================================================================
// instructon cache memory
//==============================================================================================
eco32_core_ifu_icu_way_mem 
#(
.PAGE_ADDR_WIDTH (PAGE_ADDR_WIDTH)
)
icm
(
.clk                (clk),

.i_tid              (i_tid),
.i_page             (i_v_addr[PAGE_ADDR_WIDTH-1+6:6]),                                                              
.i_offset           (i_v_addr[5:3]),
                                                                                                           
.wr_ena             (mm_wr_stb),
.wr_tid             (mm_wr_tid),
.wr_page            (mm_wr_page),
.wr_offset          (mm_wr_offset),
.wr_data            (mm_wr_data),

.o_data             (b1_data)
);
//==============================================================================================
// stage a2
//==============================================================================================   
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    a2_stb              <=                                                                 1'b0;
    a2_tid              <=                                                                 1'b0;
    a2_pid              <=                                                                 2'b0;
    a2_iva              <=                                                                 2'b0;
    a2_asid             <=                                                                 2'b0;
    a2_entry            <=                                                                 2'b0;
    a2_data             <=                                                                 2'b0;
    a2_col              <=                                                                  'b0;
    a2_ext              <=                                                                  'b0;
  end
 else 
  begin
    a2_stb              <=                                                               b1_stb;
    a2_tid              <=                                                               b1_tid;
    a2_pid              <=                                                               b1_pid;
    a2_iva              <=                                                               b1_iva;
    a2_asid             <=                                                              b1_asid;
    a2_entry            <=                                                             b1_entry;
    a2_col              <=                                                               b1_col;
                                                                                                                       
         if(b1_iva[2]==1'b0 && b1_data[66]==1'b0)                                                                      
     begin
        a2_data[63:32]  <=                                                                32'd0;
        a2_data[31: 0]  <=                                                       b1_data[63:32];    
     end
    else if(b1_iva[2]==1'b0 && b1_data[66]==1'b1) 
     begin
        a2_data[63:32]  <=                                                                32'd0;
        a2_data[31: 0]  <=                                                                32'd0;    
     end
    else if(b1_iva[2]==1'b1 && b1_data[66]==1'b0) 
     begin
        a2_data[63:32]  <=                                                                32'd0;
        a2_data[31: 0]  <=                                                       b1_data[31: 0];    
     end
    else if(b1_iva[2]==1'b1 && b1_data[66]==1'b1) 
     begin
        a2_data[63:32]  <=                                                       b1_data[63:32];
        a2_data[31: 0]  <=                                                       b1_data[31: 0];    
     end
     
    a2_ext3A            <=                                                          b1_data[64];
    a2_ext3B            <=                                                          b1_data[65];
    a2_ext              <=                                                          b1_data[66];
  end    
//----------------------------------------------------------------------------------------------
wire    a2_inst_skip     =                                                 !a2_iva[2] && a2_ext;
wire    a2_inst_ext      =                                                  a2_iva[2] && a2_ext;  
//----------------------------------------------------------------------------------------------
assign  a2_way_asid      =                                                      a2_entry[35:32];

assign  a2_way_v_addr    =                                              {a2_entry[31:11],11'd0};

assign  a2_way_valid     =                                                      a2_entry[   10];
assign  a2_way_av        =                                                      a2_entry[    9];
assign  a2_way_locked    =                                                      a2_entry[    8];

assign  a2_way_tag       =                                                      a2_entry[    7];
assign  a2_way_wrt       =                                                      a2_entry[    6];
assign  a2_way_pid       =                                                      a2_entry[ 5: 4];                

assign  a2_way_exe       =                                                      a2_entry[    3];
assign  a2_way_rd        =                                                      a2_entry[    2];
assign  a2_way_wr        =                                                      a2_entry[    1];
assign  a2_way_dbg       =                                                      a2_entry[    0];
//----------------------------------------------------------------------------------------------
assign  a2_way_aerr      =                                                       |a2_iva[ 1: 0];
//==============================================================================================
wire    way_asid_val     =                                               a2_way_asid == a2_asid;          
wire    way_addr_val     =                        a2_way_v_addr[31:_PAW+6] == a2_iva[31:_PAW+6];          
wire    way_exc_aa       =                             a2_way_aerr && a2_way_valid && a2_way_av;          
wire    way_exc_rd       =                              !a2_way_rd && a2_way_valid && a2_way_av;
wire    way_exc_exe      =                             !a2_way_exe && a2_way_valid && a2_way_av;
wire    way_exc_pid      =                    (a2_way_pid < i_pid) && a2_way_valid && a2_way_av;
//----------------------------------------------------------------------------------------------                                          
wire    way_hit          =            way_asid_val && way_addr_val && a2_way_av && a2_way_valid;
//----------------------------------------------------------------------------------------------
wire    way_locked       =                                              a2_col || a2_way_locked;
//----------------------------------------------------------------------------------------------
wire    way_empty        =                                      !a2_way_locked && !a2_way_valid; 
//----------------------------------------------------------------------------------------------
wire    way_tag          =                                                           a2_way_tag; 
//----------------------------------------------------------------------------------------------
wire    way_exc_page     =              way_exc_aa && way_exc_rd && way_exc_exe  && way_exc_pid; 
wire    way_exc_tlb      =                           way_addr_val && !a2_way_av && a2_way_valid;   
//==============================================================================================
// const table
//==============================================================================================
wire    [5:0]   f2_mopc =                                                        a2_data[31:26];
wire            f2_m    =                                                        a2_data[   25];
wire            f2_p0   =                                                        a2_data[    0];
//----------------------------------------------------------------------------------------------
eco32_core_ifu_way_cft cft
(
.mopc           (f2_mopc),                                                                                                                                           
.m              (f2_m), 
.p0             (f2_p0), 
                                                                                                                
.o_mux_hi       (a2_mux_hi),                                    
.o_mux_mi       (a2_mux_mi),
.o_mux_lo       (a2_mux_lo)
); 
//==============================================================================================
// stage (b)1: pc 
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b3_stb              <=                                                                  'b0;
    b3_tid              <=                                                                  'b0;
    b3_pid              <=                                                                  'b0;
    b3_data             <=                                                                  'b0;
                                                                                                        
    b3_hit              <=                                                                  'b0;
    b3_miss             <=                                                                  'b0;
    b3_locked           <=                                                                  'b0;
    b3_empty            <=                                                                  'b0;
    b3_tag              <=                                                                  'b0;
    
    b3_exc              <=                                                                  'b0;
    b3_exc_ida          <=                                                                  'b0;
    b3_exc_idp          <=                                                                  'b0;
    b3_exc_idt          <=                                                                  'b0;
    
    b3_data             <=                                                                  'b0;
    b3_inst_skip        <=                                                                  'b0;
    b3_inst_ext         <=                                                                  'b0;   

    b3_cmod_loE         <=                                                                  'b0;
    b3_cmod_miE         <=                                                                  'b0;
    b3_cmod_hiE         <=                                                                  'b0;    

    b3_data             <=                                                        64'h0000_0000; 
  end   
 else  
  begin
    b3_stb              <=                                                               a2_stb;
    b3_tid              <=                                                               a2_tid;
    b3_pid              <=                                                               a2_pid;

    b3_hit              <=                                    !way_locked &&  way_hit && a2_stb;
    b3_miss             <=                                    !way_locked && !way_hit && a2_stb;
    b3_locked           <=                                                 way_locked && a2_stb;  
    b3_empty            <=                                   !way_locked && way_empty && a2_stb;  
    b3_tag              <=                                                    way_tag && a2_stb;
    
    b3_exc              <=                              (way_exc_tlb || way_exc_page) && a2_stb;
    b3_exc_ida          <=                                        {way_exc_exe,way_exc_rd,2'd0};
    b3_exc_idp          <=                                        {2'b0,way_exc_aa,way_exc_pid};
    b3_exc_idt          <=                                         {1'b0,1'b0,1'b0,way_exc_tlb};

    b3_data             <=                                                              a2_data;
    b3_inst_skip        <=                    a2_inst_skip && !way_locked &&  way_hit && a2_stb;
    b3_inst_ext         <=                     a2_inst_ext && !way_locked &&  way_hit && a2_stb;   
    
    if(a2_inst_ext)
        begin
         b3_cmod_loE    <=                                     a2_mux_hi=='d4 ? 'd0 : a2_mux_lo;
         b3_cmod_miE    <=                                                                2'b10;
         b3_cmod_hiE    <=                                                               3'b101;    
        end
    else
        begin
         b3_cmod_loE    <=                                                            a2_mux_lo;
         b3_cmod_miE    <=                                                            a2_mux_mi;
         b3_cmod_hiE    <=                                                            a2_mux_hi;    
        end
  end      
//==============================================================================================   
// output
//==============================================================================================   
assign  o_hit               =                                                            b3_hit;
assign  o_miss              =                                                           b3_miss;
assign  o_locked            =                                                         b3_locked;
assign  o_empty             =                                                          b3_empty;
assign  o_tag               =                                                            b3_tag;

assign  o_exc               =                                                            b3_exc;
assign  o_exc_ida           =                                                        b3_exc_ida;
assign  o_exc_idp           =                                                        b3_exc_idp;
assign  o_exc_idt           =                                                        b3_exc_idt;

assign  o_data              =                                                           b3_data;

assign  o_inst_skip         =                                                      b3_inst_skip;
assign  o_inst_ext          =                                                       b3_inst_ext;

assign  o_cmod_lo           =                                                       b3_cmod_loE;
assign  o_cmod_mi           =                                                       b3_cmod_miE;
assign  o_cmod_hi           =                                                       b3_cmod_hiE;
//==============================================================================================   
endmodule