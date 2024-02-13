//==============================================================================================
//    Main contributors
//      - Adam Luczak         <mailto:adam.luczak@outlook.com>
//==============================================================================================
`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns                            
//==============================================================================================
// hierarchy:
// processor core (TOP)
// + instruction fetch 
//   + instruction cache way 
//     + page desritption table
//==============================================================================================
module eco32_core_ifu_way_cft
(
input   wire     [5:0]  mopc, 
input   wire            m, 
input   wire            p0, 

output  wire     [2:0]  o_mux_hi,
output  wire     [1:0]  o_mux_mi,
output  wire     [2:0]  o_mux_lo
);                             
//==============================================================================================
// parameters
//==============================================================================================
localparam       [2:0]  LX_LO_13    = 3'b000;
localparam       [2:0]  LX_ADR_11   = 3'b001;
localparam       [2:0]  LX_ADR_10   = 3'b010;
localparam       [2:0]  LX_ZERO     = 3'b011;

localparam       [1:0]  MX_MI_6     = 2'b00;
localparam       [1:0]  MX_LO_SGN   = 2'b01;
localparam       [1:0]  MX_ZERO     = 2'b11;

localparam       [2:0]  HX_LO_SGN   = 3'b000;
localparam       [2:0]  HX_MI_SGN   = 3'b001;
localparam       [2:0]  HX_SIG_6    = 3'b010;
localparam       [2:0]  HX_UNS_6    = 3'b011;
localparam       [2:0]  HX_LO_13    = 3'b100;
localparam       [2:0]  HX_ZERO     = 3'b111;
//==============================================================================================
// variables
//==============================================================================================   
reg     [2:0] L;
reg     [1:0] M;
reg     [2:0] H;
//==============================================================================================
// table
//==============================================================================================
always@(*)
    casex({mopc,m,p0})
    {6'h00,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h01,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h02,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h03,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
                                                                                    
    {6'h04,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h05,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h06,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h07,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };

    {6'h08,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h09,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h0A,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h0B,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
                                                                                                
    {6'h0C,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h0D,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h0E,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h0F,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };

    {6'h10,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_13,  MX_ZERO,    LX_ZERO   };
    {6'h11,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_13,  MX_ZERO,    LX_ZERO   };
    {6'h12,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_13,  MX_ZERO,    LX_ZERO   };
    {6'h13,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_13,  MX_ZERO,    LX_ZERO   };
    
    {6'h14,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   };
    {6'h15,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   };               
    {6'h16,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   };
    {6'h17,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   };              
    
    {6'h18,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // lea
    {6'h19,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_LO_13  }; // leai
    {6'h1A,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // S0
    {6'h1B,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // S1
    
    {6'h1C,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // I0
    {6'h1D,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // I1
    {6'h1E,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // F0
    {6'h1F,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // F1
    //                    
    {6'h20,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  }; //ld
    {6'h21,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h22,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h23,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
     
    {6'h24,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  }; //ld
    {6'h25,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h26,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h27,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };

    {6'h28,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  }; //st
    {6'h29,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h2A,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
    {6'h2B,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_LO_13  };
     
    {6'h2C,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_ADR_10 }; // update
    {6'h2D,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_ADR_10 }; // store
    {6'h2E,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_ADR_10 }; // load
    {6'h2F,1'bx,1'bx}:      {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_ADR_10 }; // flush

    {6'h30,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   };
    {6'h31,1'bx,1'b1}:      {H,M,L}     <=                  {HX_ZERO,   MX_MI_6,    LX_ADR_11 }; // abs
        {6'h31,1'bx,1'b0}:  {H,M,L}     <=                  {HX_MI_SGN, MX_MI_6,    LX_ADR_11 }; // rel
    {6'h32,1'bx,1'b1}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ADR_11 }; // abs
        {6'h32,1'bx,1'b0}:  {H,M,L}     <=                  {HX_LO_SGN, MX_LO_SGN,  LX_ADR_11 }; // rel
    {6'h33,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ADR_10 }; // abs
    
    {6'h34,1'bx,1'b1}:      {H,M,L}     <=                  {HX_UNS_6,  MX_MI_6,    LX_ADR_11 }; // abs
        {6'h34,1'bx,1'b0}:  {H,M,L}     <=                  {HX_SIG_6,  MX_MI_6,    LX_ADR_11 }; // rel
    {6'h35,1'bx,1'b1}:      {H,M,L}     <=                  {HX_ZERO,   MX_MI_6,    LX_ADR_11 }; // abs
        {6'h35,1'bx,1'b0}:  {H,M,L}     <=                  {HX_MI_SGN, MX_MI_6,    LX_ADR_11 }; // rel
    {6'h36,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ADR_10 }; // abs
    {6'h37,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ADR_10 };
     
    {6'h38,1'b0,1'bx}:      {H,M,L}     <=                  {HX_MI_SGN, MX_MI_6,    LX_LO_13  }; // ldi
        {6'h38,1'b1,1'bx}:  {H,M,L}     <=                  {HX_LO_13,  MX_MI_6,    LX_ZERO   }; // ldi
    {6'h39,1'b0,1'bx}:      {H,M,L}     <=                  {HX_MI_SGN, MX_MI_6,    LX_LO_13  }; // lra
        {6'h39,1'b1,1'bx}:  {H,M,L}     <=                  {HX_LO_13,  MX_MI_6,    LX_ZERO   }; // lra
    {6'h3A,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // Ex0
    {6'h3B,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // Ex1
                                                                                                    
    {6'h3C,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // M0
    {6'h3D,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // M1
    {6'h3E,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // M2
    {6'h3F,1'bx,1'bx}:      {H,M,L}     <=                  {HX_ZERO,   MX_ZERO,    LX_ZERO   }; // M3
    
    default:    {H,M,L}     <=                              {HX_ZERO,   MX_ZERO,    LX_ZERO   };
    endcase
        
//==============================================================================================
// output
//==============================================================================================
assign  o_mux_lo    =   L;
assign  o_mux_mi    =   M;
assign  o_mux_hi    =   H;
//==============================================================================================
endmodule
