//=============================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//=============================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//=============================================================================
module eco32_core_idu_ryt
(
 input  wire     [5:0]  i_mopc, 
 input  wire     [3:0]  i_sopc, 
 input  wire            i_m,    
 input  wire            i_p0,   
 
 input  wire     [4:0]  i_ry,   
 input  wire            i_by,   
 input  wire            i_zy,   
 
 output  wire    [1:0]  o_ena,  
 output  wire    [4:0]  o_addr  
);
//==============================================================================================
// variables
//==============================================================================================
reg  [4:0]  addr;
reg  [1:0]  ena;                               
//----------------------------------------------------------------------------------------------
wire        i_ry_zero   =   i_zy;
//==============================================================================================
// mapping table for r1 pipe 
//==============================================================================================
always@(*)
    casex(i_mopc)                                           
    6'h00:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // sub/add
    6'h01:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // dec.cc/inc.cc
    6'h02:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // subcc/addcc
    6'h03:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // subucc/adducc

    6'h04:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // and/andhi
    6'h05:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // or/orhi
    6'h06:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // xor/xorhi
    6'h07:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // andcc/andcchi

    6'h08:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // (f)min,(f)max/(f)minmax  
    6'h09:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // sel.cc                   sel.cc.ab        
    6'h0A:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -/-      
    6'h0B:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.cc                    ld.cc.ab    
                                                                                           
    6'h0C:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // mul16l   (r,r,imm),      mul32l   (r,r,imm)        
    6'h0D:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // -                 ,      mul32hl  (a:b,r,imm)      
    6'h0E:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // mulf16   (r,r,imm),      mulf32   (r,r,imm)        
    6'h0F:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // div32l   (r,r,imm),      div32hl  (a:b,r,imm)      
                                                                                                                                                   
    6'h10:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // fsub     (r,r,imm),      fadd     (r,r,imm)        
    6'h11:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // fmul     (r,r,imm),      fdiv     (r,r,imm)        
    6'h12:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // fmulsub  (r,r,r,a:b),    fmuladd  (r,r,r,a:b)      
    6'h13:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // fmul.ab  (a:b,r,r,a:b),  -                         
                                                                                                                                                   
    6'h14:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // mul16sub (r,r,r,a:b),    mul16add (r,r,r,a:b)      
    6'h15:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // mul16.ab (a:b,r,r,a:b),  mul32.ab (a:b,r,r,a:b)    
    6'h16:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // mulf16sub(r,r,r,a:b),    mulf16add(r,r,r,a:b)      
    6'h17:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // mulf16.ab(a:b,r,r,a:b),  mulf32.ab(a:b,r,r,a:b)    
                                                                                                                                                   
    6'h18:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // lea      (r,r,r,r),      -                         
    6'h19:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // leai     (r,a:b,imm),    -                         
//  6'h1A:          subopcode S0                     
//  6'h1B:          subopcode S1                     

//  6'h1C:          subopcode I0
//  6'h1D:          subopcode I1
//  6'h1E:          subopcode F0
//  6'h1F:          subopcode F1

    6'h20:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.ub(r+o)/ld.ub.ab(r+o)
    6'h21:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.uh(r+o)/ld.uh.ab(r+o)
    6'h22:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.uw(r+o)/ld.uw.ab(r+o)
    6'h23:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.d(r+o) /ld.d.ab(r+o)
              
    6'h24:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.sb(r+o)/ld.sb.ab(r+o)
    6'h25:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.sh(r+o)/ld.sh.ab(r+o)
    6'h26:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.sw(r+o)/ld.sw.ab(r+o)
    6'h27:          {ena,addr}   =  {   {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.d(r+o) /ld.d.ab(r+o)
            
    6'h28:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    1'b0,     1'b0},               i_ry}; // st.b(r+o)/st.b.ab(r+o)
    6'h29:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    1'b0,     1'b0},               i_ry}; // st.h(r+o)/st.h.ab(r+o)
    6'h2A:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    1'b0,     1'b0},               i_ry}; // st.w(r+o)/st.w.ab(r+o)
    6'h2B:          {ena,addr}   =  {   {2{!i_ry_zero}} & {    1'b0,     1'b0},               i_ry}; // st.d(r+o)/st.d.ab(r+o) 
            
    6'h2C:          {ena,addr}   =  {                     {    1'b0,     1'b0},               i_ry}; // cupdate
    6'h2D:          {ena,addr}   =  {                     {    1'b0,     1'b0},               i_ry}; // store
    6'h2E:          {ena,addr}   =  {                     {    1'b0,     1'b0},               i_ry}; // load
    6'h2F:          {ena,addr}   =  {                     {    1'b0,     1'b0},               i_ry}; // flush

    6'h30:          {ena,addr}   =   {                    {    1'b0,      i_m},              5'h1F}; // jp.cc(r+r)/jpal.cc(r+r)      
    6'h31:          {ena,addr}   =   {                    {    1'b0,      i_m},              5'h1F}; // jr.cc(o)/jral.cc(o)          
    6'h32:          {ena,addr}   =   {                    {    1'b0,      i_m},              5'h1F}; // jp.cc(r+o)/jpal.cc(r+0)      
    6'h33:          {ena,addr}   =   {                    {    1'b1,     1'b1},              5'h1F}; // syscall.cc
                                                                                                                                     
    6'h34:          {ena,addr}   =   {                    {    1'b0,      i_m},              5'h1F}; // jp(a)/jpal(o)                
    6'h35:          {ena,addr}   =   {                    {    1'b0,      i_m},              5'h1F}; // jp(r+o)/jpal(r+0)            
    6'h36:          {ena,addr}   =   {                    {    1'b1,     1'b1},              5'h1F}; // syscall.cc                          
    6'h37:          {ena,addr}   =   {                    {    1'b1,     1'b1},              5'h1F}; // syscall

    6'h38:          {ena,addr}   =   {  {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // ldi(imm)/ldihi(imm)
    6'h39:          {ena,addr}   =   {  {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // lra(off)/lrahi(off)
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
        4'h0:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // shll/shlr
        4'h1:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // shel/shar
        4'h2:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // shml/shmr
        4'h3:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // rotl/rotr
    
        4'h4:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h5:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h6:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h7:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        
        4'h8:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // dsl
        4'h9:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hA:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hB:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; //
        
        4'hC:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // clo/clz
        4'hD:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hE:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hF:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
    endcase 

    //..........................................................................................
    6'h1B: // sub Opcode S1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h1:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h2:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h3:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
                                                                                          
        4'h4:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h5:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h6:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h7:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
                                                                                          
        4'h8:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // dsl
        4'h9:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'hA:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'hB:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; //
                                                                                          
        4'hC:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // clo/clz
        4'hD:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'hE:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'hF:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
    endcase 

    //..........................................................................................
    6'h1C: // sub Opcode I0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // sub/add
        4'h1:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // dec/sub
        4'h2:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // subcc/adduccc
        4'h3:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // subucc/adducc
                                                                                          
        4'h4:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // and
        4'h5:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // or
        4'h6:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // xor
        4'h7:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // andcc
                                                                                          
        4'h8:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // -
        4'h9:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // abs     absabs
        4'hA:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // -
        4'hB:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.cc               
                                                                                          
        4'hC:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // mul16l   (r,r,r),        mul32l   (r,r,r)    
        4'hD:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // -               ,        mul32hl  (a:b,r,r)  
        4'hE:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // mulf16   (r,r,r),        mulf32   (r,r,r)    
        4'hF:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // div32l   (r,r,r),        div32hl  (a:b,r,r)  
    endcase 

    //..........................................................................................
    6'h1D: // sub Opcode I1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // addadd/addsub
        4'h1:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'h2:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'h3:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
                                                                                          
        4'h4:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h5:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h6:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h7:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
                                                                                          
        4'h8:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'h9:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'hA:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'hB:      {ena,addr}   =  {    {2{!i_ry_zero}} & {(i_m|i_by)&!i_p0,(i_m|!i_by)&!i_p0},i_ry}; // ld.cc  (y,cr)
                                                                                          
        4'hC:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'hD:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'hE:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
        4'hF:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b1,     1'b1},               i_ry}; // 
    endcase 
    
    //..........................................................................................
    6'h1E: // sub Opcode F0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // fsub     (r,r,r),        fadd     (r,r,r)    
        4'h1:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // fmul     (r,r,r),        fdiv     (r,r,r)    
        4'h2:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -                   
        4'h3:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -                   
                                                                                                                                             
        4'h4:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // fsin/fcos(r,r),          ftan/fatan(r,r)     
        4'h5:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // flog     (r,r),          fexp     (r,r)      
        4'h6:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -                   
        4'h7:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // fsqrt    (r,r),          f1x      (r,r)      
                                                                                                                                             
        4'h8:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // ftoi/itof(r,r),          -                   
        4'h9:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // ftrunc/frounf(r,r),      ffloor/fceil(r,r)   
        4'hA:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -                   
        4'hB:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -                   
                                                                                                                                             
        4'hC:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -                   
        4'hD:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // fabs/fneg(r,r),          -   
        4'hE:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -                   
        4'hF:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -                   
    endcase 

    //..........................................................................................
    6'h1F: // sub Opcode X0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // sad
        4'h1:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -   
        4'h2:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -   
        4'h3:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -   
                                                                                                                             
        4'h4:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // bswap / bswap.ab
        4'h5:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // -                        -   
        4'h6:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // -                        -   
        4'h7:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // -                        -   
                                                                                                                             
        4'h8:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // min/max/
        4'h9:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // -                        -   
        4'hA:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // -                        -   
        4'hB:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // -                        -   
                                                                                                                             
        4'hC:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -   
        4'hD:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -   
        4'hE:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -   
        4'hF:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // -                        -   
    endcase 
    
    //..........................................................................................
    6'h3C: // sub Opcode M0
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.ub(r+r)/ld.ub.ab(r+r)
        4'h1:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.uh(r+r)/ld.uh.ab(r+r)
        4'h2:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.uw(r+r)/ld.uw.ab(r+r)
        4'h3:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.d(r+r) /ld.d.ab(r+r)
                                                                                          
        4'h4:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.sb(r+r)/ld.sb.ab(r+r)
        4'h5:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.sh(r+r)/ld.sh.ab(r+r)
        4'h6:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.sw(r+r)/ld.sw.ab(r+r)
        4'h7:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.d(r+r) /ld.d.ab(r+r)
                                                                                          
        4'h8:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // st.b(r+r)/st.b.ab(r+r)
        4'h9:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // st.h(r+r)/st.h.ab(r+r)
        4'hA:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // st.w(r+r)/st.w.ab(r+r)
        4'hB:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // st.d(r+r)/st.d.ab(r+r) 
                                                                                          
        4'hC:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hD:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hE:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hF:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
    endcase 

    //..........................................................................................
    6'h3D: // sub Opcode M1
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.ub(r)/ld.ub.ab(r)
        4'h1:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.uh(r)/ld.uh.ab(r)
        4'h2:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.uw(r)/ld.uw.ab(r)
        4'h3:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.d(r) /ld.d.ab(r)
                                                                                          
        4'h4:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.sb(r)/ld.sb.ab(r)
        4'h5:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.sh(r)/ld.sh.ab(r)
        4'h6:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.sw(r)/ld.sw.ab(r)
        4'h7:      {ena,addr}   =  {    {2{!i_ry_zero}} & {i_m|i_by,i_m|!i_by},               i_ry}; // ld.d(r) /ld.d.ab(r)
                                                                                          
        4'h8:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b0,     1'b0},               i_ry}; // st.b(r)/st.b.ab(r)
        4'h9:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b0,     1'b0},               i_ry}; // st.h(r)/st.h.ab(r)
        4'hA:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b0,     1'b0},               i_ry}; // st.w(r)/st.w.ab(r)
        4'hB:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    1'b0,     1'b0},               i_ry}; // st.d(r)/st.d.ab(r) 
                                                                                          
        4'hC:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hD:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hE:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hF:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
    endcase 

    //..........................................................................................
    6'h3E: // sub Opcode M2
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h1:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h2:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h3:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
                                                                                          
        4'h4:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h5:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h6:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h7:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
                                                                                          
        4'h8:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h9:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hA:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hB:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
                                                                                          
        4'hC:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hD:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hE:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hF:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
    endcase 

    //..........................................................................................
    6'h3F: // sub Opcode M3
    //..........................................................................................
    case(i_sopc)                                                                                                                                                               
        4'h0:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h1:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h2:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h3:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
                                                                                          
        4'h4:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h5:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h6:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h7:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
                                                                                          
        4'h8:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'h9:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hA:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hB:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
                                                                                          
        4'hC:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hD:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hE:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
        4'hF:      {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry}; // 
    endcase 
    
    default:       {ena,addr}   =  {    {2{!i_ry_zero}} & {    i_by,    !i_by},               i_ry};
    endcase   
//==============================================================================================
// output
//==============================================================================================
assign      o_ena       =                                                                   ena;
assign      o_addr      =                                                                  addr;
//----------------------------------------------------------------------------------------------
endmodule