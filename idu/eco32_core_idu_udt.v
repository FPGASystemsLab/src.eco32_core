//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//----------------------------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
module eco32_core_idu_udt
(
 input  wire     [5:0]  i_mopc,
 input  wire     [3:0]  i_sopc,
 input  wire            i_m,
 input  wire            i_p0,
 input  wire            i_p1,     
 
 input  wire     [4:0]  i_ra,
 input  wire            i_ba,     

 input  wire     [4:0]  i_rb,
 input  wire            i_bb,     

 input  wire     [4:0]  i_rc,
 input  wire            i_bc,     
 
 input  wire     [4:0]  i_ry,
 input  wire            i_by,     
 
 output  wire           o_udi,
 output  wire    [3:0]  o_mode
);
//==============================================================================================
// variables
//==============================================================================================
reg  [3:0]  mode;
reg         ena;
//==============================================================================================
// mapping table for r1 pipe 
//==============================================================================================
always@(*)
    casex(i_mopc)   
    6'h00:          {ena,mode}  <=  {   1'd0,   4'd0}; // sub/add
    6'h01:          {ena,mode}  <=  {   1'd0,   4'd0}; // dec.cc/inc.cc
    6'h02:          {ena,mode}  <=  {   1'd0,   4'd0}; // subcc/addcc
    6'h03:          {ena,mode}  <=  {   1'd0,   4'd0}; // subucc/adducc

    6'h04:          {ena,mode}  <=  {   1'd0,   4'd0}; // and/andhi
    6'h05:          {ena,mode}  <=  {   1'd0,   4'd0}; // or/orhi
    6'h06:          {ena,mode}  <=  {   1'd0,   4'd0}; // xor/xorhi
    6'h07:          {ena,mode}  <=  {   1'd0,   4'd0}; // andcc/andcchi

    6'h08:          {ena,mode}  <=  {   1'd0,   4'd0}; // (f)min,(f)max/(f)minmax  
    6'h09:          {ena,mode}  <=  {   1'd0,   4'd0}; // -/-      
    6'h0A:          {ena,mode}  <=  {   1'd0,   4'd0}; // sat/-      
    6'h0B:          {ena,mode}  <=  {   1'd0,   4'd0}; // move.cc/-    

    6'h0C:          {ena,mode}  <=  {   1'd0,   4'd0}; // mul16l   (r,r,imm),      mul32l   (r,r,imm)        
    6'h0D:          {ena,mode}  <=  {   1'd0,   4'd0}; // mul16hl  (a:b,r,imm),    mul32hl  (a:b,r,imm)      
    6'h0E:          {ena,mode}  <=  {   1'd0,   4'd0}; // mulf16   (r,r,imm),      mulf32   (r,r,imm)        
    6'h0F:          {ena,mode}  <=  {   1'd0,   4'd0}; // div32l   (r,r,imm),      div32hl  (a:b,r,imm)      
                                                                                                           
    6'h10:          {ena,mode}  <=  {   1'd0,   4'd0}; // fsub     (r,r,imm),      fadd     (r,r,imm)        
    6'h11:          {ena,mode}  <=  {   1'd0,   4'd0}; // fmul     (r,r,imm),      fdiv     (r,r,imm)        
    6'h12:          {ena,mode}  <=  {   1'd0,   4'd0}; // fmulsub  (r,r,r,a:b),    fmuladd  (r,r,r,a:b)      
    6'h13:          {ena,mode}  <=  {   1'd0,   4'd0}; // fmul.ab  (a:b,r,r,a:b),  -                           
                                                                                                           
    6'h14:          {ena,mode}  <=  {   1'd0,   4'd0}; // mul16sub (r,r,r,a:b),    mul16add (r,r,r,a:b)      
    6'h15:          {ena,mode}  <=  {   1'd0,   4'd0}; // mul16.ab (a:b,r,r,a:b),  mul32.ab (a:b,r,r,a:b)    
    6'h16:          {ena,mode}  <=  {   1'd0,   4'd0}; // mulf16sub(r,r,r,a:b),    mulf16add(r,r,r,a:b)      
    6'h17:          {ena,mode}  <=  {   1'd0,   4'd0}; // mulf16.ab(a:b,r,r,a:b),  mulf32.ab(a:b,r,r,a:b)    
                                                                                                           
    6'h18:          {ena,mode}  <=  {   1'd0,   4'h0}; // lea      (r,r,r,r),      -                         
    6'h19:          {ena,mode}  <=  {   1'd0,   4'h0}; // leai     (r,a:b,imm),    -                         
//  6'h1A:          subopcode S0
//  6'h1B:          subopcode S1

//  6'h1C:          subopcode I0
//  6'h1D:          subopcode I1
//  6'h1E:          subopcode F0
//  6'h1F:          subopcode F1

    6'h20:          {ena,mode}  <=  {   1'b0,   4'h0}; // ld.ub(r+o)/ld.ub.ab(r+o)
    6'h21:          {ena,mode}  <=  {   1'b0,   4'h0}; // ld.uh(r+o)/ld.uh.ab(r+o)
    6'h22:          {ena,mode}  <=  {   1'b0,   4'h0}; // ld.uw(r+o)/ld.uw.ab(r+o)
    6'h23:          {ena,mode}  <=  {   1'b0,   4'h0}; // ld.d(r+o) /ld.d.ab(r+o)
              
    6'h24:          {ena,mode}  <=  {   1'b0,   4'h0}; // ld.sb(r+o)/ld.sb.ab(r+o)
    6'h25:          {ena,mode}  <=  {   1'b0,   4'h0}; // ld.sh(r+o)/ld.sh.ab(r+o)
    6'h26:          {ena,mode}  <=  {   1'b0,   4'h0}; // ld.sw(r+o)/ld.sw.ab(r+o)
    6'h27:          {ena,mode}  <=  {   1'b0,   4'h0}; // ld.d(r+o) /ld.d.ab(r+o)
            
    6'h28:          {ena,mode}  <=  {   1'b0,   4'h0}; // st.b(r+o)/st.b.ab(r+o)
    6'h29:          {ena,mode}  <=  {   1'b0,   4'h0}; // st.h(r+o)/st.h.ab(r+o)
    6'h2A:          {ena,mode}  <=  {   1'b0,   4'h0}; // st.w(r+o)/st.w.ab(r+o)
    6'h2B:          {ena,mode}  <=  {   1'b0,   4'h0}; // st.d(r+o)/st.d.ab(r+o) 
            
    6'h2C:          {ena,mode}  <=  {   1'b0,   4'h0}; // 
    6'h2D:          {ena,mode}  <=  {   1'b0,   4'h0}; // 
    6'h2E:          {ena,mode}  <=  {   1'b0,   4'h0}; // 
    6'h2F:          {ena,mode}  <=  {   1'b0,   4'h0}; // 

    6'h30:          {ena,mode}  <=   {  1'd0,   4'h0}; // jp.cc(a)/jpal.cc(a)
    6'h31:          {ena,mode}  <=   {  1'd0,   4'h0}; // jr.cc(o)/jral.cc(o)
    6'h32:          {ena,mode}  <=   {  1'b0,   4'h0}; // jp.cc(r+o)/jpal.cc(r+0)
    6'h33:          {ena,mode}  <=   {  1'b0,   4'h0}; // jp.cc(r+r)/jpal.cc(r+r)
    6'h34:          {ena,mode}  <=   {  1'd0,   4'h0}; // jp(a)/jpal(o)
    6'h35:          {ena,mode}  <=   {  1'd0,   4'h0}; // jr(o)/jral(o)
    6'h36:          {ena,mode}  <=   {  1'b0,   4'h0}; // jp(r+o)/jpal(r+o)
    6'h37:          {ena,mode}  <=   {  1'd0,   4'h0}; // syscall/libcall

    6'h38:          {ena,mode}  <=   {  1'd0,   4'h0}; // ldi(imm)/ldihi(imm)
    6'h39:          {ena,mode}  <=   {  1'd0,   4'h0}; // lra(off)/lrahi(off)
//  6'h3A:          extension E0
//  6'h3B:          reserved

//  6'h3C:          subopcode M0
//  6'h3D:          subopcode M1
//  6'h3E:          reserved
//  6'h3F:          reserved

    //..........................................................................................
    6'h1A: // sub Opcode S0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,mode}  <=  {    1'b0,   4'h0}; // shll/shlr
        4'h1:      {ena,mode}  <=  {    1'b0,   4'h0}; // shel/shar
        4'h2:      {ena,mode}  <=  {    1'b0,   4'h0}; // shml/shmr
        4'h3:      {ena,mode}  <=  {    1'b0,   4'h0}; // rotl/rotr
    
        4'h4:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h5:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h6:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h7:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        
        4'h8:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h9:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hA:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hB:      {ena,mode}  <=  {    1'b1,   4'h0}; //
        
        4'hC:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hD:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hE:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hF:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
    endcase 

    //..........................................................................................
    6'h1B: // sub Opcode S1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h1:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h2:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h3:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
    
        4'h4:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h5:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h6:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h7:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        
        4'h8:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h9:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hA:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hB:      {ena,mode}  <=  {    1'b1,   4'h0}; //
        
        4'hC:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hD:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hE:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hF:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
    endcase 

    //..........................................................................................
    6'h1C: // sub Opcode I0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,mode}  <=  {    1'b0,   4'h0}; // sub/add
        4'h1:      {ena,mode}  <=  {    1'b0,   4'h0}; // dec/sub
        4'h2:      {ena,mode}  <=  {    1'b0,   4'h0}; // subcc/adduccc
        4'h3:      {ena,mode}  <=  {    1'b0,   4'h0}; // subucc/adducc

        4'h4:      {ena,mode}  <=  {    1'b0,   4'h0}; // and
        4'h5:      {ena,mode}  <=  {    1'b0,   4'h0}; // or
        4'h6:      {ena,mode}  <=  {    1'b0,   4'h0}; // xor
        4'h7:      {ena,mode}  <=  {    1'b0,   4'h0}; // andcc
        
        4'h8:      {ena,mode}  <=  {    1'b0,   4'h0}; // min/max/
        4'h9:      {ena,mode}  <=  {    1'b0,   4'h0}; // sel                        sel.ab
        4'hA:      {ena,mode}  <=  {     i_m,   4'h0}; // sat/
        4'hB:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.cc                  ld.cc.ab
        
        4'hC:      {ena,mode}  <=  {    1'b0,   4'h0}; // mul16l   (r,r,r),        mul32l   (r,r,r)    
        4'hD:      {ena,mode}  <=  {    1'b0,   4'h0}; // mul16hl  (a:b,r,r),      mul32hl  (a:b,r,r)  
        4'hE:      {ena,mode}  <=  {    1'b0,   4'h0}; // mulf16   (r,r,r),        mulf32   (r,r,r)    
        4'hF:      {ena,mode}  <=  {    1'b0,   4'h0}; // div32l   (r,r,r),        div32hl  (a:b,r,r)  
    endcase 

    //..........................................................................................
    6'h1D: // sub Opcode I1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h1:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h2:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h3:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
    
        4'h4:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h5:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h6:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h7:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        
        4'h8:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h9:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hA:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hB:      {ena,mode}  <=  {    1'b0,   4'h0}; // move.cc cr
        
        4'hC:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hD:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hE:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hF:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
    endcase 
    
    //..........................................................................................
    6'h1E: // sub Opcode F0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,mode}  <=  {    1'b0,   4'h0}; // fsub     (r,r,r),        fadd     (r,r,r)    
        4'h1:      {ena,mode}  <=  {     i_m,   4'h1}; // fmul     (r,r,r),        fdiv     (r,r,r)    
        4'h2:      {ena,mode}  <=  {    1'b1,   4'h1}; // -                        -                   
        4'h3:      {ena,mode}  <=  {    1'b1,   4'h1}; // -                        -                   
                                                                                                         
        4'h4:      {ena,mode}  <=  {    1'b1,   4'h1}; // fsin/fcos(r,r),          ftan/fatan(r,r)     
        4'h5:      {ena,mode}  <=  {    1'b1,   4'h1}; // flog     (r,r),          fexp     (r,r)      
        4'h6:      {ena,mode}  <=  {    1'b1,   4'h1}; // -                        -                   
        4'h7:      {ena,mode}  <=  {    1'b1,   4'h1}; // fsqrt    (r,r),          f1x      (r,r)      
                                                                                                         
        4'h8:      {ena,mode}  <=  {    1'b1,   4'h1}; // ftoi/itof(r,r),          -                   
        4'h9:      {ena,mode}  <=  {    1'b0,   4'h1}; // ftrunc/frounf(r,r),      ffloor/fceil(r,r)   
        4'hA:      {ena,mode}  <=  {    1'b1,   4'h1}; // -                        -                   
        4'hB:      {ena,mode}  <=  {    1'b1,   4'h1}; //   -                        -                   
                                                                                                         
        4'hC:      {ena,mode}  <=  {    1'b1,   4'h1}; // -                        -                   
        4'hD:      {ena,mode}  <=  {    1'b0,   4'h1}; // fabs/fneg(r,r),          -   
        4'hE:      {ena,mode}  <=  {    1'b1,   4'h1}; // -                        -                   
        4'hF:      {ena,mode}  <=  {    1'b1,   4'h1}; // -                        -                   
    endcase 

    //..........................................................................................
    6'h1F: // sub Opcode F1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'h1:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'h2:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'h3:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
                                                                                         
        4'h4:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'h5:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'h6:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'h7:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
                                                                                         
        4'h8:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'h9:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'hA:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'hB:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
                                                                                         
        4'hC:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'hD:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'hE:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
        4'hF:      {ena,mode}  <=  {    1'b1,   4'h0}; // -                        -   
    endcase 
    
    //..........................................................................................
    6'h3C: // sub Opcode M0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.ub(r+r)/ld.ub.ab(r+r)
        4'h1:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.uh(r+r)/ld.uh.ab(r+r)
        4'h2:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.uw(r+r)/ld.uw.ab(r+r)
        4'h3:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.d(r+r) /ld.d.ab(r+r)
                                                    
        4'h4:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.sb(r+r)/ld.sb.ab(r+r)
        4'h5:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.sh(r+r)/ld.sh.ab(r+r)
        4'h6:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.sw(r+r)/ld.sw.ab(r+r)
        4'h7:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.d(r+r) /ld.d.ab(r+r)
                                                    
        4'h8:      {ena,mode}  <=  {    1'b0,   4'h0}; // st.b(r+r)/st.b.ab(r+r)
        4'h9:      {ena,mode}  <=  {    1'b0,   4'h0}; // st.h(r+r)/st.h.ab(r+r)
        4'hA:      {ena,mode}  <=  {    1'b0,   4'h0}; // st.w(r+r)/st.w.ab(r+r)
        4'hB:      {ena,mode}  <=  {    1'b0,   4'h0}; // st.d(r+r)/st.d.ab(r+r) 
                                                    
        4'hC:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hD:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hE:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hF:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
    endcase 

    //..........................................................................................
    6'h3D: // sub Opcode M1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.ub(r)/ld.ub.ab(r)
        4'h1:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.uh(r)/ld.uh.ab(r)
        4'h2:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.uw(r)/ld.uw.ab(r)
        4'h3:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.d(r) /ld.d.ab(r)
                                                    
        4'h4:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.sb(r)/ld.sb.ab(r)
        4'h5:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.sh(r)/ld.sh.ab(r)
        4'h6:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.sw(r)/ld.sw.ab(r)
        4'h7:      {ena,mode}  <=  {    1'b0,   4'h0}; // ld.d(r) /ld.d.ab(r)
                                                    
        4'h8:      {ena,mode}  <=  {    1'b0,   4'h0}; // st.b(r)/st.b.ab(r)
        4'h9:      {ena,mode}  <=  {    1'b0,   4'h0}; // st.h(r)/st.h.ab(r)
        4'hA:      {ena,mode}  <=  {    1'b0,   4'h0}; // st.w(r)/st.w.ab(r)
        4'hB:      {ena,mode}  <=  {    1'b0,   4'h0}; // st.d(r)/st.d.ab(r) 
                                                    
        4'hC:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hD:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hE:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hF:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
    endcase 

    //..........................................................................................
    6'h3E: // sub Opcode M2
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h1:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h2:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h3:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
                                                    
        4'h4:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h5:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h6:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h7:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
                                                    
        4'h8:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h9:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hA:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hB:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
                                                    
        4'hC:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hD:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hE:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hF:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
    endcase 

    //..........................................................................................
    6'h3F: // sub Opcode M3
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h1:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h2:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h3:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
                                                    
        4'h4:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h5:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h6:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h7:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
                                                    
        4'h8:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'h9:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hA:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hB:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
                                                    
        4'hC:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hD:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hE:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
        4'hF:      {ena,mode}  <=  {    1'b1,   4'h0}; // 
    endcase 
    
    default:       {ena,mode}   <=    { 1'b1,   4'hF}; //
    endcase     
//==============================================================================================
// output
//==============================================================================================
assign      o_udi       =                                                                   ena;
assign      o_mode      =                                                                  mode;
//----------------------------------------------------------------------------------------------
endmodule