//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_idu_r0t
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
//==============================================================================================
// mapping table for r0 pipe 
//==============================================================================================
always@(*)
    casex(i_mopc)   
    6'h00:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // sub/add
    6'h01:          {ena,bank,addr,mode}   =  { 1'd1,    i_by,i_ry,                       1'd0}; // dec.cc/inc.cc
    6'h02:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // subcc/addcc
    6'h03:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // subucc/adducc
                                            
    6'h04:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // and/andhi
    6'h05:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // or/orhi
    6'h06:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // xor/xorhi
    6'h07:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // andcc/andcchi
                                            
    6'h08:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // min      (r,r,imm)      max    (r,r,imm)
    6'h09:          {ena,bank,addr,mode}   =  { 1'd0,    i_ba,5'd0,                       1'd0}; // sel.cc                  -      
    6'h0A:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // --
    6'h0B:          {ena,bank,addr,mode}   =  { 1'd0,    i_ba,5'd0,                       1'd0}; // ld.cc    (r,imm)        ld.cc.ba  (b:a,imm)  
                                            
    6'h0C:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // mul16   (r,R,imm),       mul32   (r,R,imm)      
    6'h0D:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // -                   ,    mul32hl  (b:a,R,imm)    
    6'h0E:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // mulf16   (r,R,imm),      mulf32   (r,R,imm)      
    6'h0F:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // div32l   (r,R,imm),      div32hl  (b:a,R,imm)    
                                                                                                            
    6'h10:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // fsub     (r,R,imm),      fadd     (r,R,imm)      
    6'h11:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // fmul     (r,R,imm),      fdiv     (r,R,imm)      
    6'h12:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // fmulsub  (r,R,r,b:a),    fmuladd  (r,R,r,b:a)    
    6'h13:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // fmul.ab  (b:a,R,r,b:a),  -                      
                                                                                                            
    6'h14:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // mul16sub (r,R,r,b:a),    mul16add (r,R,r,b:a)    
    6'h15:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // mul16.ab (b:a,R,r,b:a),  mul32.ab (b:a,R,r,b:a)  
    6'h16:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // mulf16sub(r,R,r,b:a),    mulf16add(r,R,r,b:a)    
    6'h17:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // mulf16.ab(b:a,R,r,b:a),  mulf32.ab(b:a,R,r,b:a)  
                                                                                                            
    6'h18:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // lea      (r,R,r,r),      -                       
    6'h19:          {ena,bank,addr,mode}   =  { 1'd1,    i_ba,i_ra,                       1'd0}; // leai     (r,b:A,imm),    -      
//  6'h1A:          subopcode S0                                                          
//  6'h1B:          subopcode S1                                                          

//  6'h1C:          subopcode I0
//  6'h1D:          subopcode I1
//  6'h1E:          subopcode F0
//  6'h1F:          subopcode F1

    6'h20:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // ld.ub(r+o)/ld.ub.ab(r+o)
    6'h21:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // ld.uh(r+o)/ld.uh.ab(r+o)
    6'h22:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // ld.uw(r+o)/ld.uw.ab(r+o)
    6'h23:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // ld.d(r+o) /ld.d.ab(r+o)
              
    6'h24:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // ld.sb(r+o)/ld.sb.ab(r+o)
    6'h25:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // ld.sh(r+o)/ld.sh.ab(r+o)
    6'h26:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // ld.sw(r+o)/ld.sw.ab(r+o)
    6'h27:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // ld.d(r+o) /ld.d.ab(r+o)
            
    6'h28:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // st.b(r+o)/st.b.ab(r+o)
    6'h29:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // st.h(r+o)/st.h.ab(r+o)
    6'h2A:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // st.w(r+o)/st.w.ab(r+o)
    6'h2B:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // st.d(r+o)/st.d.ab(r+o) 
            
    6'h2C:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // update 
    6'h2D:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // store
    6'h2E:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // load
    6'h2F:          {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                       1'd0}; // flush

    6'h30:          {ena,bank,addr,mode}   =  { i_p0,    i_by,i_ry,                      !i_p0}; // jp.cc(r+r)/jpal.cc(r+r)       
    6'h31:          {ena,bank,addr,mode}   =  { 1'd0,    i_by,5'd0,                      !i_p0}; // jr.cc(o)/jral.cc(o)       
    6'h32:          {ena,bank,addr,mode}   =  { i_p0,    i_by,i_ry,                      !i_p0}; // jp.cc(r+o)/jpal.cc(r+0)    
    6'h33:          {ena,bank,addr,mode}   =  { 1'b0,    i_by,5'd0,                       1'b0}; // syscall
    
    6'h34:          {ena,bank,addr,mode}   =  { 1'd0,    i_ba,i_ra,                      !i_p0}; // jp(a)/jpal(o)              
    6'h35:          {ena,bank,addr,mode}   =  { i_p0,    i_ba,i_ra,                      !i_p0}; // jp(r+o)/jpal(r+0)               
    6'h36:          {ena,bank,addr,mode}   =  { 1'd0,    i_ba,5'd0,                       1'b0}; // syscall.cc
    6'h37:          {ena,bank,addr,mode}   =  { 1'd0,    i_ba,5'd0,                       1'b0}; // syscall
    
    6'h38:          {ena,bank,addr,mode}   =  { 1'd0,    i_by,5'd0,                       1'd0}; // ldi(imm)/ldihi(imm)
    6'h39:          {ena,bank,addr,mode}   =  { 1'b0,    i_by,5'd0,                       1'd1}; // lra(off)/lrahi(off)
//  6'h3A:          extenbank,sion E0                    
//  6'h3B:          reserbank,ved                        

//  6'h3C:          subopcode M0
//  6'h3D:          subopcode M1
//  6'h3E:          reserved
//  6'h3F:          reserved

    //..........................................................................................
    6'h1A: // sub Opcode S0
    //..........................................................................................
    case(i_sopc)
        4'h0:      {ena,bank,addr,mode}   =  { !i_m,    i_ba,i_ra,                        1'b0}; // shll/shlr
        4'h1:      {ena,bank,addr,mode}   =  { !i_m,    i_ba,i_ra,                        1'b0}; // shel/shar
        4'h2:      {ena,bank,addr,mode}   =  { !i_m,    i_ba,i_ra,                        1'b0}; // shml/shmr
        4'h3:      {ena,bank,addr,mode}   =  { !i_m,    i_ba,i_ra,                        1'b0}; // rotl/rotr
                                                        
        4'h4:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h5:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h6:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h7:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
                                                        
        4'h8:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h9:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hA:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hB:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; //
                                                        
        4'hC:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // clo/clz 
        4'hD:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hE:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hF:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
    endcase 

    //..........................................................................................
    6'h1B: // sub Opcode S1                                                                                                  
    //..........................................................................................
    case(i_sopc)
        4'h0:      {ena,bank,addr,mode}   =  {  !i_m,   i_ba,i_ra,                        1'd0}; // 
        4'h1:      {ena,bank,addr,mode}   =  {  !i_m,   i_ba,i_ra,                        1'd0}; // 
        4'h2:      {ena,bank,addr,mode}   =  {  !i_m,   i_ba,i_ra,                        1'd0}; // 
        4'h3:      {ena,bank,addr,mode}   =  {  !i_m,   i_ba,i_ra,                        1'd0}; // 
                                                             
        4'h4:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; // 
        4'h5:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; // 
        4'h6:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; // 
        4'h7:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; // 
                                                             
        4'h8:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; // 
        4'h9:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; // 
        4'hA:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; //                                
        4'hB:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; //                                
                                                             
        4'hC:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; // clo/clz
        4'hD:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; // 
        4'hE:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; // 
        4'hF:      {ena,bank,addr,mode}   =  {  1'b0,   i_ba,i_ra,                        1'd0}; // 
    endcase 
    
    //..........................................................................................
    6'h1C: // sub Opcode I0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // sub/add
        4'h1:      {ena,bank,addr,mode}   =  { 1'b1,    i_by,i_ry,                        1'd0}; // dec/inc
        4'h2:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // subcc/adduccc
        4'h3:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // subucc/adducc
                                                             
        4'h4:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // and
        4'h5:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // or
        4'h6:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // xor
        4'h7:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // andcc
                                                             
        4'h8:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,5'd0,                        1'd0}; // -                        -
        4'h9:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,5'd0,                        1'd0}; // abs                      absabs             
        4'hA:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,5'd0,                        1'd0}; // -                        -
        4'hB:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,5'd0,                        1'd0}; // ld.cc    (r,r)           ld.cc.ab (b:a,b:a)
                                                             
        4'hC:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // mul16    (r,R,r),        mul32    (r,R,r)     
        4'hD:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                 ,      mul32hl  (b:a,R,r)   
        4'hE:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // mulf16   (r,R,r),        mulf32   (r,R,r)     
        4'hF:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // div32l   (r,R,r),        div32hl  (b:a,R,r)   
    endcase 

    //..........................................................................................
    6'h1D: // sub Opcode I1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                            
        4'h0:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // 
        4'h1:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // 
        4'h2:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // 
        4'h3:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // 
                                                             
        4'h4:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // 
        4'h5:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // 
        4'h6:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // 
        4'h7:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // 
                                                             
        4'h8:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; //
        4'h9:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hA:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hB:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // ld.cc cr
                                                             
        4'hC:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hD:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hE:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hF:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
    endcase 

    //..........................................................................................
    6'h1E: // sub Opcode F0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // fsub     (r,R,r),        fadd     (r,R,r) 
        4'h1:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // fmul     (r,R,r),        fdiv     (r,R,r) 
        4'h2:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -                
        4'h3:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -                
                                                             
        4'h4:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // fsin/fcos(r,R),          ftan/fatan(r,R)
        4'h5:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // flog     (r,R),          fexp     (r,R) 
        4'h6:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -              
        4'h7:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // fsqrt    (r,R),          f1x      (r,R) 
                                                             
        4'h8:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // ftoi/itof(r,r),          -                 
        4'h9:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // ftrunc/frounf(r,R),      ffloor/fceil(r,R) 
        4'hA:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // -                        -                 
        4'hB:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // -                        -                 
                                                             
        4'hC:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // -                        -                  
        4'hD:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // fabs/fneg(r,R),          -
        4'hE:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // -                        -                  
        4'hF:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // -                        -                  
    endcase 

    //..........................................................................................
    6'h1F: // sub Opcode X0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // sad                      sad.ba
        4'h1:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
        4'h2:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
        4'h3:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
                                                                                                                                                                                                         
        4'h4:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // bswap.cc (r,r)           bswap.cc.ab (b:a,b:a)
        4'h5:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
        4'h6:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
        4'h7:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
                                                            
        4'h8:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // min/max                  minmax
        4'h9:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
        4'hA:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
        4'hB:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        - 
                                                            
        4'hC:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
        4'hD:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
        4'hE:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
        4'hF:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // -                        -  
    endcase 
    
    //..........................................................................................
    6'h3C: // sub Opcode M0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.ub(r+r)/ld.ub.ab(r+r)
        4'h1:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.uh(r+r)/ld.uh.ab(r+r)
        4'h2:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.uw(r+r)/ld.uw.ab(r+r)
        4'h3:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.d(r+r) /ld.d.ab(r+r)
                                                            
        4'h4:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.sb(r+r)/ld.sb.ab(r+r)
        4'h5:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.sh(r+r)/ld.sh.ab(r+r)
        4'h6:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.sw(r+r)/ld.sw.ab(r+r)
        4'h7:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.d(r+r) /ld.d.ab(r+r)
                                                            
        4'h8:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // st.b(r+r)/st.b.ab(r+r)
        4'h9:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // st.h(r+r)/st.h.ab(r+r)
        4'hA:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // st.w(r+r)/st.w.ab(r+r)
        4'hB:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // st.d(r+r)/st.d.ab(r+r) 
                                                            
        4'hC:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // pageupdate
        4'hD:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // pageload
        4'hE:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // pagestore
        4'hF:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // pageflush
    endcase 

    //..........................................................................................
    6'h3D: // sub Opcode M1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.ub(r)/ld.ub.ab(r)
        4'h1:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.uh(r)/ld.uh.ab(r)
        4'h2:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.uw(r)/ld.uw.ab(r)
        4'h3:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.d(r) /ld.d.ab(r)
                                                            
        4'h4:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.sb(r)/ld.sb.ab(r)
        4'h5:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.sh(r)/ld.sh.ab(r)
        4'h6:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.sw(r)/ld.sw.ab(r)
        4'h7:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // ld.d(r) /ld.d.ab(r)
                                                            
        4'h8:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // st.b(r)/st.b.ab(r)
        4'h9:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // st.h(r)/st.h.ab(r)
        4'hA:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // st.w(r)/st.w.ab(r)
        4'hB:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // st.d(r)/st.d.ab(r) 
                                                            
        4'hC:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // 
        4'hD:      {ena,bank,addr,mode}   =  { 1'b1,    i_ba,i_ra,                        1'd0}; // 
        4'hE:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hF:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
    endcase 

    //..........................................................................................
    6'h3E: // sub Opcode M2
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h1:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h2:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h3:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
                                                            
        4'h4:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h5:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h6:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h7:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
                                                            
        4'h8:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h9:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hA:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hB:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
                                                            
        4'hC:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hD:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hE:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hF:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
    endcase 

    //..........................................................................................
    6'h3F: // sub Opcode M3
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h1:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h2:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h3:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
                                                             
        4'h4:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h5:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h6:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h7:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
                                                             
        4'h8:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'h9:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hA:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hB:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
                                                             
        4'hC:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hD:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hE:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
        4'hF:      {ena,bank,addr,mode}   =  { 1'b0,    i_ba,i_ra,                        1'd0}; // 
    endcase 
    
    default:       {ena,bank,addr,mode}   =   { 1'b0,    i_ba,5'd0,                        1'd0};
    endcase     
//==============================================================================================
// output
//==============================================================================================
assign      o_ena       =                                                                   ena;
assign      o_bank      =                                                                  bank;
assign      o_addr      =                                                                  addr;
assign      o_mode      =                                                                  mode; 
assign      o_c_type    =                                                                  2'd0; 
//----------------------------------------------------------------------------------------------
endmodule