//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_idu_cwd
(
 input  wire            clk,
 input  wire            rst,
 
 input  wire            i_stb,
 input  wire            i_tid,
 input  wire     [1:0]  i_pid,
 input  wire    [15:0]  i_isw,
 input  wire    [31:0]  i_iva,     
 
 input  wire            i_opc_cnd_ena,
 input  wire     [5:0]  i_opc_cnd_val,
 input  wire    [31:0]  i_opc_vect,
 input  wire            i_evt_req,
 
 output wire     [7:0]  o_cc_cw,
 output wire     [5:0]  o_ar_cw,
 output wire     [3:0]  o_lo_cw,
 output wire     [4:0]  o_sh_cw,
 output wire     [4:0]  o_sh_val,
 output wire     [5:0]  o_mm_cw,
 output wire     [1:0]  o_ds_cw,
 output wire     [9:0]  o_bc_cw,
 output wire    [14:0]  o_ls_cw,
 output wire    [20:0]  o_jp_cw,
 output wire     [9:0]  o_jp_arg,
 output wire     [2:0]  o_dc_cw,
 output wire     [3:0]  o_fr_cw,
 output wire     [7:0]  o_fl_cw,
 output wire     [6:0]  o_ft_cw,
 output wire     [5:0]  o_ml_cw,
 output wire     [8:0]  o_cr_cw
);                             
//==============================================================================================
// parameters
//==============================================================================================
parameter   [7:0]   CODE_ID             =                                                   'd0;
parameter           FORCE_RST           =                                                     0;
//==============================================================================================
// variables
//==============================================================================================         
// stage (b)                                                                                             
//----------------------------------------------------------------------------------------------
reg             b1_stb;
reg             b1_tid;
reg             b1_evt;
reg      [1:0]  b1_pid;
reg     [15:0]  b1_isw;
reg     [31:0]  b1_iva;
reg     [86:0]  b1_opc_vect;

reg      [7:0]  b1_cc_cw;
reg      [5:0]  b1_ar_cw;
reg      [3:0]  b1_lo_cw;
reg      [4:0]  b1_sh_cw;
reg      [4:0]  b1_sh_val;
reg     [14:0]  b1_ls_cw;
reg     [20:0]  b1_jp_cw; 
// pragma translate_off
initial
  begin         
    $display( "%m: TODO: b1_jp_cw jest 21-bitowy a ma tylko 11 waznych bitow, dlaczego?" );          
  end
// pragma translate_on   
//---------------------------------------------------------------------------------------------- 
reg      [9:0]  b1_jp_arg;
reg      [2:0]  b1_dc_cw;
reg      [3:0]  b1_fr_cw;
reg      [5:0]  b1_ml_cw;
reg      [7:0]  b1_fl_cw;
reg      [6:0]  b1_ft_cw;
reg      [6:0]  b1_mm_cw;
reg      [1:0]  b1_ds_cw;
reg      [8:0]  b1_cr_cw;
reg      [9:0]  b1_bc_cw;
//==============================================================================================
// aliases
//==============================================================================================
wire    [4:0]   f_ra        =                                                 i_opc_vect[23:19];
wire            f_ba        =                                                 i_opc_vect[   24];

wire    [4:0]   f_rb        =                                                 i_opc_vect[ 5: 1];
wire            f_bb        =                                                 i_opc_vect[    6];

wire    [4:0]   f_rc        =                                                 i_opc_vect[11: 7];
wire            f_bc        =                                                 i_opc_vect[   12];

wire    [4:0]   f_ry        =                                                 i_opc_vect[17:13];
wire            f_by        =                                                 i_opc_vect[   18];

wire            f_cc_force  =                                                     i_opc_cnd_ena;
wire    [4:0]   f_cc        =                                                     i_opc_cnd_val;

wire    [3:0]   f_vec       =                                          {1'b0,i_opc_vect[ 2: 0]};
wire    [3:0]   f_vra       =                                                     {f_ra[ 3: 0]};
wire    [3:0]   f_vry       =                                                     {f_ry[ 3: 0]};
//----------------------------------------------------------------------------------------------
wire    [5:0]   f_mopc      =                                                 i_opc_vect[31:26];
wire    [3:0]   f_sopc      =                                                 i_opc_vect[ 5: 2];
//----------------------------------------------------------------------------------------------
wire            f_e         =                                                         i_evt_req;
wire            f_m         =                                                 i_opc_vect[   25];                                              
wire            f_p0        =                                                 i_opc_vect[    0];                
wire            f_p1        =                                                 i_opc_vect[    6];
wire            f_p2        =                                                 i_opc_vect[    1];
wire            f_ie        =                                                 i_opc_vect[    2];
wire            f_cr        =                                                 i_opc_vect[    1];
wire    [1:0]   f_vt        =                                                 i_opc_vect[17:16];     

wire    [1:0]   f_p20       =                                                 i_opc_vect[ 1: 0];                     
wire            f_kt        =                                  (f_ra == f_rc) && (f_ba == f_bc);
//----------------------------------------------------------------------------------------------
wire    [2:0]   f_xa        =                                                 i_opc_vect[21:19];              
wire    [2:0]   f_xb        =                                                 i_opc_vect[24:22];
//==============================================================================================
// mapping tables
//==============================================================================================
//==============================================================================================
// stage (a)0:  
//==============================================================================================
always@(posedge clk or posedge rst)
 if(rst) 
  begin
    b1_stb              <=                                                                 1'b0;
    b1_tid              <=                                                                 1'b0;
    b1_evt              <=                                                                 1'b0;
    b1_pid              <=                                                                 2'b0;
    b1_isw              <=                                                                16'b0;        
    b1_iva              <=                                                        32'h0000_0000; 
    b1_opc_vect         <=                                                                  'd0; 
    
    b1_ar_cw            <=                                                                  'd0;
    b1_lo_cw            <=                                                                  'd0;
    b1_sh_cw            <=                                                                  'd0;
    b1_sh_val           <=                                                                  'd0;
    b1_ls_cw            <=                                                                  'd0;
    b1_cc_cw            <=                                                                  'd0;
    b1_jp_cw            <=                                                                  'd0;
    b1_jp_arg           <=                                                                  'd0;
    b1_dc_cw            <=                                                                  'd0;
    b1_fr_cw            <=                                                                  'd0;
    b1_ml_cw            <=                                                                  'd0;      
    b1_fl_cw            <=                                                                  'd0;
    b1_ft_cw            <=                                                                  'd0;
    b1_mm_cw            <=                                                                  'd0;
    b1_ds_cw            <=                                                                  'd0;
    b1_cr_cw            <=                                                                  'd0;
    b1_bc_cw            <=                                                                  'd0;
  end
 else
  begin  
    b1_stb              <=                                                                i_stb;
    b1_tid              <=                                                                i_tid;
    b1_pid              <=                                                                i_pid;
    b1_isw              <=                                                                i_isw;
    b1_iva              <=                                                                i_iva;
    b1_opc_vect         <=                                                           i_opc_vect;

// --- arithmetic ------------------------------------------------------------------------------

    casex(f_mopc)                            // abs     usig    opcH    opcL     c1      ena
    6'h00:          b1_ar_cw        <=       {  1'b0,   1'b0,    f_m,    f_m,    1'b0,   1'b1  }; // sub        /add
    6'h01:          b1_ar_cw        <=       {  1'b0,   1'b0,    f_m,    f_m,    1'b0,   1'b1  }; // dec        /inc
    6'h02:          b1_ar_cw        <=       {  1'b0,   1'b0,    f_m,    f_m,    1'b0,   1'b1  }; // sub        /add cc
    6'h03:          b1_ar_cw        <=       {  1'b0,   1'b1,    f_m,    f_m,    1'b0,   1'b1  }; // subu       /addu cc

    6'h0B:          b1_ar_cw        <=       {  1'b0,   1'b0,   !f_m,   1'b1,    1'b0,   1'b1  }; // ld.cc      /ld.cc.ab

    8'h1C:          //SubOpcode I0
        casex(f_sopc)                       //  abs     usig    opcH,   opcL    c1      ena
        4'h0:        b1_ar_cw       <=      {   1'b0,   1'b0,    f_m,   f_m,    f_p0,   1'b1  }; // sub         /add
        4'h1:        b1_ar_cw       <=      {   1'b0,   1'b0,    f_m,   f_m,    f_p0,   1'b1  }; // dec         /inc
        4'h2:        b1_ar_cw       <=      {   1'b0,   1'b0,    f_m,   f_m,    f_p0,   1'b1  }; // sub         /add cc
        4'h3:        b1_ar_cw       <=      {   1'b0,   1'b1,    f_m,   f_m,    f_p0,   1'b1  }; // subu        /addu cc

        4'h9:        b1_ar_cw       <=      {   1'b1,   1'b0,    f_m,   f_m,    f_p0,   1'b1  }; // abs         /abs
        4'hB:        b1_ar_cw       <=      {   1'b0,   1'b0,   1'b1,  1'b1,    1'b0,   1'b1  }; // ld.cc       /ld.cc.ab
        default:     b1_ar_cw       <=      {   1'b0,   1'b0,   1'b0,  1'b0,    1'b0,   1'b0  };
        endcase

    8'h1D:          //SubOpcode I1
        casex(f_sopc)                       //  abs     usig    opcH,   opcL    c1      ena
        4'h0:        b1_ar_cw       <=      {   1'b0,   1'b0,   f_p1,   f_m,    f_p0,   1'b1  }; // subsub      /addadd
        default:     b1_ar_cw       <=      {   1'b0,   1'b0,   1'b0,  1'b0,    1'b0,   1'b0  };
        endcase

    // li/lra
    6'h38:          b1_ar_cw        <=      {   1'b0,   1'b0,   1'b1,  1'b1,    1'b0,   1'b1  }; // li/lihi
    6'h39:          b1_ar_cw        <=      {   1'b0,   1'b0,   1'b1,  1'b1,    1'b0,   1'b1  }; // lra/lrahi

    default:        b1_ar_cw        <=      {   1'b0,   1'b0,   1'b0,  1'b0,    1'b0,   1'b0  };
    endcase


// --- logic -----------------------------------------------------------------------------------
    
    casex(f_mopc)                                                   //  neg     opc     ena 
    6'h04:          b1_lo_cw        <=                              {   1'b0,   2'd0,   1'b1  }; // and lo/hi
    6'h05:          b1_lo_cw        <=                              {   1'b0,   2'd1,   1'b1  }; // or lo/hi
    6'h06:          b1_lo_cw        <=                              {   1'b0,   2'd2,   1'b1  }; // xor lo/hi
    6'h07:          b1_lo_cw        <=                              {   1'b0,   2'd0,   1'b1  }; // and lo/hi cc
    8'h1C: //Sub Opcode I0  
        casex(f_sopc)                                               //  neg     opc     ena 
        5'h04:          b1_lo_cw        <=                          {   f_m,    2'd0,   1'b1  }; // and lo/hi
        5'h05:          b1_lo_cw        <=                          {   f_m,    2'd1,   1'b1  }; // or lo/hi
        5'h06:          b1_lo_cw        <=                          {   f_m,    2'd2,   1'b1  }; // xor lo/hi
        5'h07:          b1_lo_cw        <=                          {   f_m,    2'd0,   1'b1  }; // and lo/hi cc
        default:        b1_lo_cw        <=                          {   f_m,    2'd3,   1'b0  };
        endcase                                                                                  
    
    default:        b1_lo_cw        <=                              {   1'b0,   2'd3,   1'b0  };
    endcase                                                                                  
    
// --- load/store ------------------------------------------------------------------------------
    
    case(f_mopc)                        //k+t   icc            opc      ab      sign    wr      size    ena           
    6'h20:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd0,   1'b1  }; // ld.ub
    6'h21:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd1,   1'b1  }; // ld.uh
    6'h22:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; // ld.uw
    6'h23:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd3,   1'b1  }; // -

    6'h24:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd0,   1'b1  }; // ld.sb
    6'h25:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd1,   1'b1  }; // ld.sh
    6'h26:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd2,   1'b1  }; // ld.sw
    6'h27:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd3,   1'b1  }; // -

    6'h28:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd0,   1'b1  }; // st.b
    6'h29:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd1,   1'b1  }; // st.h
    6'h2A:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd2,   1'b1  }; // st.w
    6'h2B:          b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd3,   1'b1  }; // -
    
    6'h2C:          b1_ls_cw        <=  {f_kt, f_p20,   1'b1,  5'h11,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; //               
    6'h2D:          b1_ls_cw        <=  {f_kt, f_p20,   1'b1,  5'h12,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; //        
    6'h2E:          b1_ls_cw        <=  {f_kt, f_p20,   1'b1,  5'h14,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; //        
    6'h2F:          b1_ls_cw        <=  {f_kt, f_p20,   1'b1,  5'h18,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; //        

    6'h3C:  
        case(f_sopc)                    //k+t   icc            opc      ab      sign    wr      size    ena
        4'h0:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd0,   1'b1  }; // ld.ub
        4'h1:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd1,   1'b1  }; // ld.uh
        4'h2:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; // ld.uw
        4'h3:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd3,   1'b1  }; // -
                                                        
        4'h4:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd0,   1'b1  }; // ld.sb
        4'h5:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd1,   1'b1  }; // ld.sh
        4'h6:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd2,   1'b1  }; // ld.sw
        4'h7:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd3,   1'b1  }; // -
                                                        
        4'h8:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd0,   1'b1  }; // st.b
        4'h9:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd1,   1'b1  }; // st.h
        4'hA:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd2,   1'b1  }; // st.w
        4'hB:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd3,   1'b1  }; // -
                                                                                                                                      
        4'hC:       b1_ls_cw        <=  {f_kt, f_p20,   1'b1,  5'h11,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; //               
        4'hD:       b1_ls_cw        <=  {f_kt, f_p20,   1'b1,  5'h12,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; //        
        4'hE:       b1_ls_cw        <=  {f_kt, f_p20,   1'b1,  5'h14,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; //        
        4'hF:       b1_ls_cw        <=  {f_kt, f_p20,   1'b1,  5'h18,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; // 
        endcase
    
    6'h3D:  
        case(f_sopc)                    //k+t   icc   opc       ab      sign    wr      size    ena           
        4'h0:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd0,   1'b1  }; // ld.ub
        4'h1:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd1,   1'b1  }; // ld.uh
        4'h2:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; // ld.uw
        4'h3:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b0,   2'd3,   1'b1  }; // -
                                                        
        4'h4:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd0,   1'b1  }; // ld.sb
        4'h5:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd1,   1'b1  }; // ld.sh
        4'h6:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd2,   1'b1  }; // ld.sw
        4'h7:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b1,   1'b0,   2'd3,   1'b1  }; // -
                                                        
        4'h8:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd0,   1'b1  }; // st.b
        4'h9:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd1,   1'b1  }; // st.h
        4'hA:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd2,   1'b1  }; // st.w
        4'hB:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   f_m,    1'b0,   1'b1,   2'd3,   1'b1  }; // -
                                                        
        4'hC:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b1,  5'h00,   f_m,    1'b0,   1'b0,   2'd0,   1'b1  }; // -/-
        4'hD:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b1,  5'h00,   f_m,    1'b0,   1'b0,   2'd1,   1'b1  }; // -/-
        4'hE:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b1,  5'h00,   f_m,    1'b0,   1'b0,   2'd2,   1'b1  }; // -/-
        4'hF:       b1_ls_cw        <=  {1'b0,  2'd0,   1'b1,  5'h00,   f_m,    1'b0,   1'b0,   2'd3,   1'b1  }; // -/-
        endcase
        
    default:        b1_ls_cw        <=  {1'b0,  2'd0,   1'b0,  5'h00,   1'b0,   1'b0,   1'b0,   2'b0,   1'b0  }; //
    endcase                                                                                  

// --- decimal sliding -------------------------------------------------------------------------

    casex(f_mopc)                      //chk                set     cond    ena 
    6'h1A: 
        case(f_sopc)
        4'h8:       b1_ds_cw        <= {1'b1,1'b1}; // dsl (r,r)
        default:    b1_ds_cw        <= {1'b0,1'b0};
        endcase 
    
    6'h1B: 
        case(f_sopc)
        4'h8:       b1_ds_cw        <= {1'b0,1'b1}; // dsl (ba,ba)
        default:    b1_ds_cw        <= {1'b0,1'b0};
        endcase 
        
    default:        b1_ds_cw        <= {1'b0,1'b0};
    endcase                                                                               


// --- conditional codes -----------------------------------------------------------------------


    casex(f_mopc)                      //chk                set     cond    ena 
    6'h01:          b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // dec.cc/inc.cc
    6'h02:          b1_cc_cw        <= {1'b0 | f_cc_force,  1'b1,   f_cc,   1'b1 | f_cc_force }; // subcc/addcc
    6'h03:          b1_cc_cw        <= {1'b0 | f_cc_force,  1'b1,   f_cc,   1'b1 | f_cc_force }; // subucc/adducc
    6'h07:          b1_cc_cw        <= {1'b0 | f_cc_force,  1'b1,   f_cc,   1'b1 | f_cc_force }; // andcc/andhicc 
    6'h0B:          b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // ld.cc/ld.cc.ab
    6'h1A: 
        case(f_sopc)
        4'h8:       b1_cc_cw        <= {1'b0 | f_cc_force,  1'b1,   f_cc,   1'b1 | f_cc_force }; // dsl
        default:    b1_cc_cw        <= {1'b0 | f_cc_force,  1'b0,   f_cc,   1'b0 | f_cc_force };
        endcase 
    
    6'h1B: 
        case(f_sopc)
        4'h8:       b1_cc_cw        <= {1'b0 | f_cc_force,  1'b1,   f_cc,   1'b1 | f_cc_force }; // dsl
        default:    b1_cc_cw        <= {1'b0 | f_cc_force,  1'b0,   f_cc,   1'b0 | f_cc_force };
        endcase 
    
    6'h1C: 
        case(f_sopc)
        4'h1:       b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // dec.cc/inc.cc
        4'h2:       b1_cc_cw        <= {1'b0 | f_cc_force,  1'b1,   f_cc,   1'b1 | f_cc_force }; // subcc/addcc
        4'h3:       b1_cc_cw        <= {1'b0 | f_cc_force,  1'b1,   f_cc,   1'b1 | f_cc_force }; // subucc/adducc
        
        4'h7:       b1_cc_cw        <= {1'b0 | f_cc_force,  1'b1,   f_cc,   1'b1 | f_cc_force }; // andcc/andhicc 
        
        4'h9:       b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // abs
         
        4'hB:       b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // ld.cc/ld.cc.ab
        default:    b1_cc_cw        <= {1'b0 | f_cc_force,  1'b0,   f_cc,   1'b0 | f_cc_force };
        endcase 
    6'h1F: 
        case(f_sopc)
        4'h4:       b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // bswap.cc/bswap.cc.ab
        default:    b1_cc_cw        <= {1'b0 | f_cc_force,  1'b0,   f_cc,   1'b0 | f_cc_force };
        endcase 
    // jp
    6'h30:          b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // jr/jp.cc
    6'h31:          b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // jr/jp.cc
    6'h32:          b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // jr/jp.cc
    6'h33:          b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // syscall.cc
    6'h36:          b1_cc_cw        <= {1'b1 | f_cc_force,  1'b0,   f_cc,   1'b1 | f_cc_force }; // syscall.cc
    default:        b1_cc_cw        <= {1'b0 | f_cc_force,  1'b0,   f_cc,   1'b0 | f_cc_force };
    endcase                                                                               

// --- jumps -----------------------------------------------------------------------------------

    casex({f_mopc})                                      //link rel            vt      pid    ena 
    6'h30:          b1_jp_cw        <=  {1'b0,    f_vry,  f_m,  !f_p0,{f_cr,1'd0},   2'b00,  1'b1  }; // jr/jp.cc
    6'h31:          b1_jp_cw        <=  {1'b0,     4'hF,  f_m,  !f_p0,{f_cr,1'd0},   2'b00,  1'b1  }; // jr/jp.cc
    6'h32:          b1_jp_cw        <=  {1'b0,    f_vry,  f_m,  !f_p0,{f_cr,1'd0},   2'b00,  1'b1  }; // jr/jp.cc
    6'h33:          b1_jp_cw        <=  {1'b1,    f_vec, !f_e,   1'b1,{1'b1, f_m},   2'b11,  1'b1  }; // syscall.cc
    
    6'h34:          b1_jp_cw        <=  {1'b0,     4'hF,  f_m,  !f_p0,{f_cr,1'd0},   2'b00,  1'b1  }; // jr/jp
    6'h35:          b1_jp_cw        <=  {1'b0,    f_vra,  f_m,  !f_p0,{f_cr,1'd0},   2'b00,  1'b1  }; // jr/jp
    6'h36:          b1_jp_cw        <=  {1'b1,    f_vec, !f_e,   1'b1,{1'b1, f_m},   2'b11,  1'b1  }; // syscall.cc
    6'h37:          b1_jp_cw        <=  {1'b1,    f_vec, !f_e,   1'b1,{1'b1, f_m},   2'b11,  1'b1  }; // syscall   
    
    default:        b1_jp_cw        <=  {1'b0,     3'd0, 1'b0,   1'b0,      2'd0,    2'b00,  1'b0  }; // 
    endcase
    
    b1_jp_arg                       <=                                        i_opc_vect[22:13];
    
// --- data conversion -------------------------------------------------------------------------
/*!*!*/
    casex({f_mopc,f_sopc})                                              //itof  ftoi    ena 
    10'h1E_8:       b1_dc_cw        <=                              {   f_p0,  !f_p0,   1'b1  }; // ftoi/itof
    default:        b1_dc_cw        <=                              {   1'b0,   1'b0, 1'b0  }; 
    endcase

// --- fractional ------------------------------------------------------------------------------
                                                              // ! fractional 32 not supported !
    casex(f_mopc)                                               //add   sub     ena32   ena16 
    6'h0E:          b1_fr_cw        <=                      {   1'b0,   1'b0,   f_m   , !f_m  }; // mul16f,   mulf32        
    6'h16:          b1_fr_cw        <=                      {    f_m,   !f_m,   1'b0  , 1'b1  }; // mulf16sub,mulf16add                    //
    6'h17:          b1_fr_cw        <=                      {   1'b0,   1'b0,   f_m   , !f_m  }; // mul16f.ab,mulf32.ab
    6'h1C:                                                                                      
        casex(f_sopc)                                           //add   sub     ena32   ena16  
        4'hE:       b1_fr_cw        <=                      {   1'b0,   1'b0,   f_m   , !f_m  }; // mulf16,   mulf32
        default:    b1_fr_cw        <=                      {   1'b0,   1'b0,   1'b0  , 1'b0  };
        endcase
    default:        b1_fr_cw        <=                      {   1'b0,   1'b0,   1'b0  , 1'b0  }; 
    endcase

// --- basic floating point --------------------------------------------------------------------

    casex(f_mopc)                       // abs    neg   simd    div     mul     add     sub     ena 
    6'h10:          b1_fl_cw        <=   {1'b0,  1'b0,  1'b0,  1'b0,   1'b0,    f_m,   !f_m,   1'b1  }; // fadd/fsub
    6'h11:          b1_fl_cw        <=   {1'b0,  1'b0,  1'b0,   f_m,   !f_m,   1'b0,   1'b0,   1'b1  }; // fmul/fdiv
    6'h12:          b1_fl_cw        <=   {1'b0,  1'b0,  1'b1,  1'b0,   1'b0,    f_m,   !f_m,   1'b1  }; // fmuladd/fmulsub
    6'h13:          b1_fl_cw        <=   {1'b0,  1'b0,  1'b1,  1'b0,   !f_m,   1'b0,   1'b0,   1'b1  }; // fmul.ba
    6'h1E:
        case(f_sopc)                    // abs    neg   simd    div     mul     add     sub     ena  
        4'h0:       b1_fl_cw        <=   {f_p1,  f_p0,  1'b0,  1'b0,   1'b0,    f_m,   !f_m,   1'b1  }; // fadd/fsub 
        4'h1:       b1_fl_cw        <=   {f_p1,  f_p0,  1'b0,   f_m,   !f_m,   1'b0,   1'b0,   1'b1  }; // fmul/fdiv
        4'hD:       b1_fl_cw        <=   {f_p1,  f_p0,  1'b0,  1'b0,   1'b1,   1'b0,   1'b0,   1'b1  }; // fabs/fneg
        default:    b1_fl_cw        <=   {1'b0,  1'b0,  1'b0,  1'b0,   1'b0,   1'b0,   1'b0,   1'b0  }; 
        endcase
    default:        b1_fl_cw        <=   {1'b0,  1'b0,  1'b0,   1'b0,   1'b0,   1'b0,   1'b0  }; 
    endcase

// --- trigonometric floating point ------------------------------------------------------------

    casex(f_mopc)                                                       
    6'h1E:
        casex(f_sopc)                                           //nres  fun     mode    ena 
        4'h4:       b1_ft_cw        <=                          {1'b0,  4'h0,   f_p0,   1'b1  }; // 
        4'h5:       b1_ft_cw        <=                          {1'b0,  4'h0,   f_p0,   1'b1  }; // 
        default:    b1_ft_cw        <=                          {1'b0,  4'h0,   1'b0,   1'b0  }; // 
        endcase                                                                                                                      
    default:        b1_ft_cw        <=                          {1'b0,  4'h0,   1'b0,   1'b0  };                                   
    endcase
    
// --- mul -------------------------------------------------------------------------------------

    casex({f_mopc})                           //unsign  lea     add     sub    i32ena  i16ena                  
    6'h0C:          b1_ml_cw        <=         {1'b0,   1'b0,   1'b0,   1'b0,   f_m,    !f_m  }; // mul16l,  mul32l
    6'h0D:          b1_ml_cw        <=         {1'b0,   1'b0,   1'b0,   1'b0,   f_m,    !f_m  }; // mul16hl, mul32hl  
    6'h14:          b1_ml_cw        <=         {f_p0,   1'b0,   f_m,    !f_m,   1'b0,   1'b1  }; // mul16sub,mul16add     
    6'h15:          b1_ml_cw        <=         {f_p0,   1'b0,   1'b0,   1'b0,   f_m,    !f_m  }; // mul16.ab,mul32.ab
    6'h18:          b1_ml_cw        <=         {f_p0,   1'b1,   1'b0,   1'b0,   1'b0,   !f_m  }; // lea
    6'h19:          b1_ml_cw        <=         {1'b0,   1'b1,   1'b0,   1'b0,   1'b0,   !f_m  }; // leai
    6'h1C:
        casex({f_sopc})                       //unsign  1'b0,   add     sub     i32ena  i16ena  
        6'h0C:      b1_ml_cw        <=         {f_p0,   1'b0,   1'b0,   1'b0,   f_m,    !f_m  }; // mul16l,  mul32l
        6'h0D:      b1_ml_cw        <=         {f_p0,   1'b0,   1'b0,   1'b0,   f_m,    !f_m  }; // mul16hl, mul32hl 
        default:    b1_ml_cw        <=         {1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0  };
        endcase
    default:        b1_ml_cw        <=         {1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0  }; 
    endcase

// --- shift -----------------------------------------------------------------------------------

    casex({f_mopc})                                                     
    6'h1A: // shift by reg
        case({f_sopc})                                         //imm   mode    dir     ena 
        4'h0:       b1_sh_cw        <=                          {f_m,   2'b00,   f_p0,  1'b1  }; // shll/shlr
        4'h1:       b1_sh_cw        <=                          {f_m,   2'b10,   f_p0,  1'b1  }; // shml/shmr
        4'h2:       b1_sh_cw        <=                          {f_m,   2'b01,   f_p0,  1'b1  }; // shel/shar
        4'h3:       b1_sh_cw        <=                          {f_m,   2'b11,   f_p0,  1'b1  }; // rotl/rotr       
        default:    b1_sh_cw        <=                          {f_m,   2'b00,   f_p0,  1'b0  }; 
        endcase                                                                                  
        
    6'h1B: // shift by reg
        case({f_sopc})                                         //imm   mode    dir     ena 
        default:    b1_sh_cw        <=                          {f_m,   2'b00,   f_p0,  1'b0  }; 
        endcase
    default:        b1_sh_cw        <=                          {1'b0,  2'b00,   1'b0,  1'b0  }; 
    endcase

    b1_sh_val                       <=                                                f_ra[4:0];

// --- extended ---------------------------------------------------------------------------------

    case(f_mopc)                                    //opc       p1      p0      mod     ena                  
    6'h08:          b1_mm_cw        <=              {2'b00,     1'b0,   1'b0,   f_m,    1'b1   }; // min/max
    6'h09:          b1_mm_cw        <=              {2'b01,     1'b0,   1'b0,   f_m,    1'b1   }; // sel/sel.ab
    6'h0A:          b1_mm_cw        <=              {2'b10,     1'b0,   1'b0,   f_m,    1'b1   }; // -/-
    
    // sub X0
    6'h1F:
        case({f_sopc})                              //opc,      p1      p0,     mod     ena  
        6'h00:      b1_mm_cw        <=              {2'b11,     f_p1,   f_m,    f_p0,   1'b1   }; // sad / sad.ab
        6'h04:      b1_mm_cw        <=              {2'b10,     f_p1,   f_m,    f_p0,   1'b1   }; // bswap.cc/bswap.ab.cc
        6'h08:      b1_mm_cw        <=              {2'b00,     f_p1,   f_m,    f_p0,   1'b1   }; // min/max/minmax
        default:    b1_mm_cw        <=              {2'b00,     f_p1,   f_m,    f_p0,   1'b0   };
        endcase                                                                 
    default:        b1_mm_cw        <=              {2'b00,     1'b0,   1'b0,   1'b0,   1'b0   }; 
    
    endcase

// --- clo/clz ---------------------------------------------------------------------------------

    case(f_mopc)                                    
    // sub S0
    6'h1A:
        case({f_sopc})                              // opc  c2      c1,     clo     ena  
        6'h0C:      b1_bc_cw        <=              { 2'd0, f_xb,   f_xa,    f_m,   1'b1   }; // clo/clz1   / 
        6'h0D:      b1_bc_cw        <=              { 2'd1, f_xb,   f_xa,    f_m,   1'b1   }; // clo/clz4   / 
        6'h0E:      b1_bc_cw        <=              { 2'd2, f_xb,   f_xa,    f_m,   1'b1   }; // clo/clz8   / 
        6'h0F:      b1_bc_cw        <=              { 2'd3, f_xb,   f_xa,    f_m,   1'b1   }; // clo/clz16  / 
        default:    b1_bc_cw        <=              { 2'd0, 3'b0,   3'b0,   1'b0,   1'b0   };
        endcase                                                             
    // sub S1                                                
    6'h1B:                                                   
        case({f_sopc})                              //      c2      c1,     clo     ena  
        6'h0C:      b1_bc_cw        <=              { 2'd0, f_xb,   f_xa,    f_m,   1'b1   }; // clo/clz1   / 
        6'h0D:      b1_bc_cw        <=              { 2'd1, f_xb,   f_xa,    f_m,   1'b1   }; // clo/clz4   / 
        6'h0E:      b1_bc_cw        <=              { 2'd2, f_xb,   f_xa,    f_m,   1'b1   }; // clo/clz8   / 
        6'h0F:      b1_bc_cw        <=              { 2'd3, f_xb,   f_xa,    f_m,   1'b1   }; // clo/clz16  / 
        default:    b1_bc_cw        <=              { 2'd0, 3'b0,   3'b0,   1'b0,   1'b0   };
        endcase                                                             
    default:        b1_bc_cw        <=              { 2'd0, 3'b0,   3'b0,   1'b0,   1'b0   }; 
    endcase
    
// --- cr rd/wr --------------------------------------------------------------------------------

    case(f_mopc)
    6'h30:            b1_cr_cw      <=                  {5'HF,  1'b1,  1'b0,    1'b1,   f_ie & f_cr }; // iret or jaie
    6'h1D: // subopcode I1
        case({f_sopc,f_m,f_p0})                         //addr      bank        rw      ena  
        {4'hB,2'b00}: b1_cr_cw      <=                  {f_rc,  f_bc, !f_bc,    1'b0,   1'b1   }; // ld.cc/ld.cc.ab
        {4'hB,2'b01}: b1_cr_cw      <=                  {f_ry,  f_by, !f_by,    1'b1,   1'b1   }; // ld.cc/ld.cc.ab 
        {4'hB,2'b10}: b1_cr_cw      <=                  {f_rc,  1'b1,  1'b1,    1'b0,   1'b1   }; // ld.cc/ld.cc.ab
        {4'hB,2'b11}: b1_cr_cw      <=                  {f_ry,  1'b1,  1'b1,    1'b1,   1'b1   }; // ld.cc/ld.cc.ab 
        
        default:      b1_cr_cw      <=                  {5'd0,  1'b0,   1'b0,   1'b0,   1'b0   };
        endcase
    default:          b1_cr_cw      <=                  {5'd0,  1'b0,   1'b0,   1'b0,   1'b0   };
    endcase
    
  end
//==============================================================================================
// output
//==============================================================================================
assign  o_cc_cw         =                                                              b1_cc_cw;
assign  o_ar_cw         =                                                              b1_ar_cw;
assign  o_lo_cw         =                                                              b1_lo_cw;
assign  o_sh_cw         =                                                              b1_sh_cw;
assign  o_sh_val        =                                                             b1_sh_val;
assign  o_mm_cw         =                                                              b1_mm_cw;
assign  o_ds_cw         =                                                              b1_ds_cw;
assign  o_bc_cw         =                                                              b1_bc_cw;
assign  o_cr_cw         =                                                              b1_cr_cw;
assign  o_ls_cw         =                                                              b1_ls_cw;
assign  o_jp_cw         =                                                              b1_jp_cw;
assign  o_jp_arg        =                                                             b1_jp_arg;
assign  o_dc_cw         =                                                              b1_dc_cw;
assign  o_fr_cw         =                                                              b1_fr_cw;
assign  o_fl_cw         =                                                              b1_fl_cw;
assign  o_ft_cw         =                                                              b1_ft_cw;
assign  o_ml_cw         =                                                              b1_ml_cw;
assign  o_sh_cw         =                                                              b1_sh_cw;
//==============================================================================================   
endmodule