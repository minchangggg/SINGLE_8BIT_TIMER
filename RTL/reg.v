// -----------------------------------------------------------------------------
// Description:
// * This file defines macro constants for Single 8-bit timer design.
// * It includes register addresses (TDR, TCR, TSR, TCNT), 
//   reset values, and bit positions for control/status fields.
// * These definitions help standardize RTL modules and testbenches.
// -----------------------------------------------------------------------------

`ifndef __REG_V__
`define __REG_V__
// ==============================================
// Common Parameters
// ==============================================
`define CNT_WIDTH 8

// ==============================================
// Default Reset Values
// ==============================================
`define TDR_RST   {`CNT_WIDTH{1'b0}} 		  
`define TCR_RST   8'h00				  
`define TSR_RST   8'h00				  
`define TCNT_RST  {`CNT_WIDTH{1'b0}} 

// ==============================================
// Register Address Map
// ==============================================
`define TDR_ADDR  8'h00
`define TCR_ADDR  8'h01
`define TSR_ADDR  8'h02
`define TCNT_ADDR 8'h03

// ==============================================
// TDR (Timer Data Register)
// ==============================================

// ==============================================
// TCR (Timer Control Register)
// ==============================================
// TCR[7]  : LOAD     | 1: Load TCNT 
// TCR[5]  : UPDOWN   | 0: Up-count, 1: Down-count
// TCR[4]  : EN       | 1: Enable counter
// TCR[1:0]: CKS[1:0] | Clock source select
`define TCR_LOAD_BIT   7
`define TCR_UPDOWN_BIT 5
`define TCR_EN_BIT     4
`define TCR_CKS_MSB    1
`define TCR_CKS_LSB    0

// ==============================================
// TSR (Timer Status Register)
// ==============================================
// Bit positions
// TSR[1] : TMR_UDF | Underflow flag (1: TCNT underflowed, set by HW, clear by SW)
// TSR[0] : TMR_OVF | Overflow flag  (1: TCNT overflowed, set by HW, clear by SW)
`define TMR_UDF_BIT  1     // Underflow Flag
`define TMR_OVF_BIT  0     // Overflow Flag

`endif

