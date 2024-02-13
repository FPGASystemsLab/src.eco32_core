//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_idu_r2t
(
 input  wire     [5:0]  i_mopc,
 input  wire     [3:0]  i_sopc,
 input  wire            i_m  /*synthesis syn_keep=1*/,
 input  wire            i_p0 /*synthesis syn_keep=1*/,
 
 input  wire     [4:0]  i_ra,
 input  wire            i_ba,     

 input  wire     [4:0]  i_rb,
 input  wire            i_bb,     

 input  wire     [4:0]  i_rc, 
 input  wire            i_bc,     
 
 input  wire     [4:0]  i_ry,
 input  wire            i_by,     
 
 output  wire           o_ena,
 output  wire           o_bank,
 output  wire    [4:0]  o_addr,
 output  wire           o_mode,
 output  wire    [1:0]  o_c_type
);
//==============================================================================================
// variables
//==============================================================================================
reg         ena;
reg         bank;
reg  [4:0]  addr;
reg         mode; 
reg  [1:0]  c_type; 
//==============================================================================================
// mapping table for r1 pipe 
//==============================================================================================
always@(*)
    casex(i_mopc)   
    6'h00:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // sub/add
    6'h01:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // dec.cc/inc.cc
    6'h02:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // subcc/addcc
    6'h03:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // subucc/adducc
                                                                                        
    6'h04:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // and/andhi
    6'h05:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // or/orhi
    6'h06:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // xor/xorhi
    6'h07:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // andcc/andcchi
                                                                                        
    6'h08:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // min         (r,r,imm)       max       (r,r,imm)    
    6'h09:         {ena,bank,addr,mode}  =  {   1'd1,   i_bc,i_rc,                        1'd0}; // sel.cc      (b:a,r,r)           
    6'h0A:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // --                          -- 
    6'h0B:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // ld.cc       (r,r,imm)       ld.cc.ab  (r,r,imm)    
                                                                                        
    6'h0C:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // mul16       (r,r,IMM),      mul32    (r,r,IMM)        
    6'h0D:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // -                    ,      mul32hl  (b:a,r,IMM)      
    6'h0E:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // mulf16      (r,r,IMM),      mulf32   (r,r,IMM)        
    6'h0F:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // div32l      (r,r,IMM),      div32hl  (b:a,r,IMM)      
                                                                                                                                                   
    6'h10:         {ena,bank,addr,mode}  =  {   1'd0,   1'b1,i_rc,                        1'd1}; // fsub        (r,r,imm),      fadd     (r,r,imm) // float(1)        
    6'h11:         {ena,bank,addr,mode}  =  {   1'd0,   1'b1,i_rc,                        1'd1}; // fmul        (r,r,IMM),      fdiv     (r,r,IMM) 
    6'h12:         {ena,bank,addr,mode}  =  {   1'd1,   1'b1,i_rc,                        1'd0}; // fmulsub     (r,r,r,B:a),    fmuladd  (r,r,r,B:a)      
    6'h13:         {ena,bank,addr,mode}  =  {   1'd1,   1'b1,i_rc,                        1'd0}; // fmul.ab     (b:a,r,r,B:a),  -                          
                                                                                                                                                   
    6'h14:         {ena,bank,addr,mode}  =  {   1'd1,   1'b1,i_rc,                        1'd0}; // mul16sub    (r,r,r,B:a),    mul16add (r,r,r,B:a)      
    6'h15:         {ena,bank,addr,mode}  =  {   1'd1,   1'b1,i_rc,                        1'd0}; // mul16ab     (b:a,r,r,B:a),  mul32.ab (b:a,r,r,B:a)    
    6'h16:         {ena,bank,addr,mode}  =  {   1'd1,   1'b1,i_rc,                        1'd0}; // mulf16sub   (r,r,r,B:a),    mulf16add(r,r,r,B:a)      
    6'h17:         {ena,bank,addr,mode}  =  {   1'd1,   1'b1,i_rc,                        1'd0}; // mulf16.ab   (b:a,r,r,B:a),  mulf32.ab(b:a,r,r,B:a)    
                                                                                                                                                   
    6'h18:         {ena,bank,addr,mode}  =  {   1'd1,   i_bc,i_rc,                        1'd0}; // lea         (r,r,r,R),      -                         
    6'h19:         {ena,bank,addr,mode}  =  {   1'd0,   i_bc,i_rc,                        1'd1}; // leai        (r,b:a,IMM),    -                         
//  6'h1A:          subopcode S0
//  6'h1B:          subopcode S1

//  6'h1C:          subopcode I0
//  6'h1D:          subopcode I1
//  6'h1E:          subopcode F0
//  6'h1F:          subopcode F1
                                                                                                                                                                                                                           
    6'h20:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // ld.ub(r+o)/ld.ub.ab(r+o)
    6'h21:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // ld.uh(r+o)/ld.uh.ab(r+o)
    6'h22:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // ld.uw(r+o)/ld.uw.ab(r+o)
    6'h23:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // ld.d(r+o) /ld.d.ab(r+o)
                                                            
    6'h24:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // ld.sb(r+o)/ld.sb.ab(r+o)
    6'h25:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // ld.sh(r+o)/ld.sh.ab(r+o)
    6'h26:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // ld.sw(r+o)/ld.sw.ab(r+o)
    6'h27:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // ld.d(r+o) /ld.d.ab(r+o)
            
    6'h28:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // st.b(r+o)/st.b.ab(r+o)
    6'h29:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // st.h(r+o)/st.h.ab(r+o)
    6'h2A:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // st.w(r+o)/st.w.ab(r+o)
    6'h2B:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // st.d(r+o)/st.d.ab(r+o) 
                                       
    6'h2C:         {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd1}; // update
    6'h2D:         {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd1}; // store
    6'h2E:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // load
    6'h2F:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // flush
                                                             
    6'h30:         {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // jp.cc(a)/jpal.cc(a)
    6'h31:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // jr.cc(o)/jral.cc(o)
    6'h32:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // jp.cc(r+o)/jpal.cc(r+0)
    6'h33:         {ena,bank,addr,mode}   =  {   i_m,   i_bc,i_rc,                        !i_m}; // syscall
                                                             
    6'h34:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // jp(a)/jpal(o)
    6'h35:         {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // jr(o)/jral(o)
    6'h36:         {ena,bank,addr,mode}   =  {   i_m,   i_bc,i_rc,                        !i_m}; // syscall.cc
    6'h37:         {ena,bank,addr,mode}   =  {   i_m,   i_bc,i_rc,                        !i_m}; // syscall
                                                             
    6'h38:         {ena,bank,addr,mode}   =  {  1'b0,   1'b1,i_rc,                        1'd1}; // ldi(imm)/ldihi(imm)
    6'h39:         {ena,bank,addr,mode}   =  {  1'b0,   1'b1,i_rc,                        1'd1}; // lra(off)/lrahi(off)
//  6'h3A:          extension E0
//  6'h3B:          extension E1

//  6'h3C:          subopcode M0
//  6'h3D:          subopcode M1
//  6'h3E:          subopcode M2
//  6'h3F:          subopcode M3

    //..........................................................................................
    6'h1A: // sub Opcode S0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'b0}; // shll/shlr
        4'h1:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'b0}; // shel/shar
        4'h2:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'b0}; // shml/shmr
        4'h3:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'b0}; // rotl/rotr
                                                            
        4'h4:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h5:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h6:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h7:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
                                                            
        4'h8:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // dsl 
        4'h9:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hA:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hB:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; //
                                                            
        4'hC:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // clz1/clnz1
        4'hD:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // clz4/clnz4
        4'hE:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // clz8/clnz8
        4'hF:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // clz16/clnz16
    endcase 

    //..........................................................................................
    6'h1B: // sub Opcode S1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // 
        4'h1:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // 
        4'h2:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // 
        4'h3:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // 
                                                             
        4'h4:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h5:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h6:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h7:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
                                                             
        4'h8:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // dsl
        4'h9:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hA:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hB:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; //
                                                             
        4'hC:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // clz1/clnz1   
        4'hD:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // clz4/clnz4   
        4'hE:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // clz8/clnz8   
        4'hF:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // clz16/clnz16 
    endcase 

    //..........................................................................................
    6'h1C: // sub Opcode I0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // sub/add
        4'h1:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // dec/sub
        4'h2:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // subcc/adduccc
        4'h3:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // subucc/adducc
                                                                 
        4'h4:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // and     (r,r,r)         andn      (r,r,r)
        4'h5:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // or      (r,r,r)         orn       (r,r,r)   
        4'h6:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // xor     (r,r,r)         xorn      (r,r,r)
        4'h7:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // andcc   (r,r,r)         andncc    (r,r,r)
                                                                 
        4'h8:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // -                       -
        4'h9:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // abs                     absabs
        4'hA:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'b0}; // -                       -
        4'hB:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // ld.cc    (r,r)          ld.cc.ab  (b:a,b:a)
                                                                 
        4'hC:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // mul16    (r,r,R),       mul32l   (r,r,R)    
        4'hD:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // -               ,       mul32hl  (b:a,r,R)  
        4'hE:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // mulf16   (r,r,R),       mulf32   (r,r,R)    
        4'hF:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // div32l   (r,r,R),       div32hl  (b:a,r,R)  
    endcase 

    //..........................................................................................
    6'h1D: // sub Opcode I1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // subsub/subadd           addadd/addsub        
        4'h1:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; //  
        4'h2:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; //  
        4'h3:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; //  
                                                                 
        4'h4:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // 
        4'h5:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // 
        4'h6:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // 
        4'h7:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // 
                                                                 
        4'h8:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h9:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hA:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hB:      {ena,bank,addr,mode}   =  {  i_p0,   i_bc,i_rc,                        1'd0}; // move.cc cr
                                                                 
        4'hC:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hD:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hE:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hF:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
    endcase 
    
    //..........................................................................................
    6'h1E: // sub Opcode F0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // fsub     (r,r,r),        fadd     (r,r,r)  // float(1)    
        4'h1:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // fmul     (r,r,R),        fdiv     (r,r,R)     
        4'h2:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -                   
        4'h3:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -                   
                                                                                                                                 
        4'h4:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // fsin/fcos(r,r),          ftan/fatan(r,r)     
        4'h5:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // flog     (r,r),          fexp     (r,r)      
        4'h6:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -                   
        4'h7:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // fsqrt    (r,r),          f1x      (r,r)      
                                                                                                                              
        4'h8:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // ftoi/itof(r,r),          -                   
        4'h9:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // ftrunc/frounf(r,r),      ffloor/fceil(r,r)   
        4'hA:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -                   
        4'hB:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -                   
                                                                                                                                 
        4'hC:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -                
        4'hD:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd1}; // fabs/fneg(r,r),          -                   // float(1)
        4'hE:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -                   
        4'hF:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -                   
    endcase 

    //..........................................................................................
    6'h1F: // sub Opcode X0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // sad
        4'h1:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
        4'h2:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
        4'h3:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
                                                                                                                     
        4'h4:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'b0}; // bswap.cc (r,r)          bswap.cc.ab (b:a,b:a)
        4'h5:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
        4'h6:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
        4'h7:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
                                                                                                               
        4'h8:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // min/max  (r,r,r)        maxmin.ab (b:a,r,r)  
        4'h9:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
        4'hA:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
        4'hB:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
                                                                                                                     
        4'hC:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
        4'hD:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
        4'hE:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
        4'hF:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // -                        -   
    endcase 
    
    //..........................................................................................
    6'h3C: // sub Opcode M0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // ld.ub(r+r)/ld.ub.ab(r+r)
        4'h1:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // ld.uh(r+r)/ld.uh.ab(r+r)
        4'h2:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // ld.uw(r+r)/ld.uw.ab(r+r)
        4'h3:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // ld.d(r+r) /ld.d.ab(r+r)
                                                                            
        4'h4:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // ld.sb(r+r)/ld.sb.ab(r+r)
        4'h5:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // ld.sh(r+r)/ld.sh.ab(r+r)
        4'h6:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // ld.sw(r+r)/ld.sw.ab(r+r)
        4'h7:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // ld.d(r+r) /ld.d.ab(r+r)
                                                             
        4'h8:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // st.b(r+r)/st.b.ab(r+r)
        4'h9:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // st.h(r+r)/st.h.ab(r+r)
        4'hA:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // st.w(r+r)/st.w.ab(r+r)
        4'hB:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // st.d(r+r)/st.d.ab(r+r) 
                                                             
        4'hC:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // update 
        4'hD:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // store  
        4'hE:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // load   
        4'hF:      {ena,bank,addr,mode}   =  {  1'b1,   i_bc,i_rc,                        1'd0}; // flush  
    endcase 

    //..........................................................................................
    6'h3D: // sub Opcode M1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // ld.ub(r)/ld.ub.ab(r)
        4'h1:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // ld.uh(r)/ld.uh.ab(r)
        4'h2:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // ld.uw(r)/ld.uw.ab(r)
        4'h3:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // ld.d(r) /ld.d.ab(r)
                                                                            
        4'h4:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // ld.sb(r)/ld.sb.ab(r)
        4'h5:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // ld.sh(r)/ld.sh.ab(r)
        4'h6:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // ld.sw(r)/ld.sw.ab(r)
        4'h7:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // ld.d(r) /ld.d.ab(r)
                                                                      
        4'h8:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // st.b(r)/st.b.ab(r)
        4'h9:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // st.h(r)/st.h.ab(r)
        4'hA:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // st.w(r)/st.w.ab(r)
        4'hB:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // st.d(r)/st.d.ab(r) 
                                                                
        4'hC:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hD:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hE:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hF:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
    endcase 

    //..........................................................................................
    6'h3E: // sub Opcode M2
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h1:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h2:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h3:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
                                                                        
        4'h4:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h5:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h6:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h7:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
                                                                      
        4'h8:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h9:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hA:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hB:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
                                                                  
        4'hC:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hD:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hE:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hF:      {ena,bank,addr,mode}   =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
    endcase 

    //..........................................................................................
    6'h3F: // sub Opcode M3
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h1:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h2:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h3:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
                                                                        
        4'h4:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h5:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h6:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h7:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
                                                                      
        4'h8:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'h9:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hA:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hB:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
                                                                  
        4'hC:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hD:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hE:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
        4'hF:      {ena,bank,addr,mode}  =  {  1'b0,   i_bc,i_rc,                        1'd0}; // 
    endcase 
    
    default:       {ena,bank,addr,mode}  = {    1'b0,   1'b1,5'd0,                        1'd0};
    endcase                                    
//============================================================================================== 
// internal const generation
//==============================================================================================  
always@(*)
 begin
    casex({i_mopc, i_sopc})                                                                                              
    {6'h10,4'hx}:   c_type  =  {   1'b0, 1'b1}; // fsub     (r,r,imm),      fadd     (r,r,imm) // float(1)  
    {6'h1E,4'h0}:   c_type  =  {   1'b0, 1'b1}; // fsub     (r,r,r),        fadd     (r,r,r)   // float(1)  
    {6'h1E,4'hD}:   c_type  =  {   1'b0, 1'b1}; // fabs/fneg(r,r),          -                  // float(1)  
    
    {6'h20,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu
    {6'h21,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu
    {6'h22,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu
    {6'h23,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu
          
    {6'h24,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu    
    {6'h25,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu    
    {6'h26,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu    
    {6'h27,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu    
          
    {6'h28,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu    
    {6'h29,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu    
    {6'h2A,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu    
    {6'h2B,4'hx}:   c_type  =  {   1'b1, 1'b0}; // ls/st                                       // lsu    
    
    default:        c_type  =  {   1'b0, 1'b0};
    endcase  
 end
//==============================================================================================
// output
//==============================================================================================
assign      o_ena       =                                                                   ena;
assign      o_bank      =                                                                  bank;
assign      o_addr      =                                                                  addr;
assign      o_mode      =                                                                  mode; 
assign      o_c_type    =                                                                c_type; 
//----------------------------------------------------------------------------------------------
endmodule

