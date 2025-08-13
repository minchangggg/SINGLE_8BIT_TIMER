// STATUS: OK

`ifndef LOGIC_CONTROL_V
`define LOGIC_CONTROL_V

`include "reg_def.v"
// `DATA_WIDTH = 8

// -----------------------------------------------------------------------------
// Module: logic_control
// Description:
//   This module handles the control logic for the TIMER:
//     - Loads TCNT from TDR when TCR[7] is set
//     - Extracts control signals: count direction, enable, and clock select
//     - Outputs status flags (overflow and underflow) to TSR
//
// Ports:
//   Inputs:
//     - TCR        : 8-bit Timer Control Register
//     - TDR        : 8-bit Timer Data Register
//     - TMR_OVF    : Overflow flag from the counter
//     - TMR_UDF    : Underflow flag from the counter
//   Outputs:
//     - count_start_value : Initial value to load into TCNT
//     - count_up_down     : 1 = up-counting, 0 = down-counting (from TCR[5])
//     - count_enable      : Counter enable signal (from TCR[4])
//     - cks               : 2-bit clock source select (from TCR[1:0])
//     - TSR               : 8-bit Timer Status Register {UDF, OVF}
// -----------------------------------------------------------------------------

module logic_control (
  input  wire [`DATA_WIDTH-1:0] TDR,   			   // Timer Data Register
  input  wire [7:0]             TCR,   			   // Timer Control Register
  output wire [`DATA_WIDTH-1:0] count_start_value, // Value to load into TCNT
  output wire                   count_load,        // Load control
  output wire       		    count_enable,      // Counter enable
  output wire       		    count_up_down,     // Direction control
  output wire [1:0] 		    cks,               // Clock source select
  
  input  wire       		    TMR_OVF,    	   // Overflow flag
  input  wire       		    TMR_UDF, 	       // Underflow flag
  output reg [7:0] 	     	    TSR                // Timer status flags: [UDF, OVF]
);
  
  // Load value to TCNT if TCR[7] is set, otherwise 0
  assign count_start_value = (TCR[`TCR_LOAD_BIT]) ? TDR : {`DATA_WIDTH{1'b0}};
  
  // Extract control signals
  assign count_load     = TCR[`TCR_LOAD_BIT]; 
  assign count_up_down  = TCR[`TCR_UPDOWN_BIT];
  assign count_enable   = TCR[`TCR_EN_BIT];
  assign cks            = {TCR[`TCR_CKS_MSB], TCR[`TCR_CKS_LSB]};

  // Combine underflow and overflow flags into TSR
  always @(*) begin
    TSR = {6'b0, TMR_UDF, TMR_OVF};  // TSR[7:2] = 0, TSR[1] = UDF, TSR[0] = OVF
  end

endmodule

`endif // LOGIC_CONTROL_V
