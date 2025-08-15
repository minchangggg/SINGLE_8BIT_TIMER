`ifndef __REG_DEF_V__
`define __REG_DEF_V__

// -----------------------------------------------------------------------------
// Description:
// * This file defines macro constants for Single 8-bit timer design.
// * It includes register addresses (TDR, TCR, TSR, TCNT),
// * reset values, and bit positions for control/status fields.
// * These definitions help standardize RTL modules and testbenches.
// -----------------------------------------------------------------------------

// ==============================================
// Common Parameters
// ==============================================
`define DATA_WIDTH 8

// ==============================================
// Default Reset Values
// ==============================================
`define TDR_RST    {`DATA_WIDTH{1'b0}}
`define TCR_RST    {`DATA_WIDTH{1'b0}}
`define TSR_RST    {`DATA_WIDTH{1'b0}}
`define TCNT_RST   {`DATA_WIDTH{1'b0}}

// ==============================================
// Register Address Map
// ==============================================
`define TDR_ADDR  8'h00
`define TCR_ADDR  8'h01
`define TSR_ADDR  8'h02
`define TCNT_ADDR 8'h03

// ==============================================
// Register Write Masks
// ==============================================
// TCR_WRITE_MASK (8'hB3 = 8'b1011_0011)
// TCR[7] = LOAD
// TCR[5] = UPDOWN
// TCR[4] = EN
// TCR[1:0] = CKS
`define TCR_WRITE_MASK 8'hB3

// TSR_WRITE_MASK (8'h03 = 8'b0000_0011)
// TSR[1] = TMR_UDF (Underflow flag, có thể xóa bằng phần mềm)
// TSR[0] = TMR_OVF (Overflow flag, có thể xóa bằng phần mềm)
// Các bit khác là read-only và không thể ghi.
`define TSR_WRITE_MASK 8'h03

// ==============================================
// TDR (an 8-bit Timer Data Register)
// ==============================================
// No bit definitions needed for TDR as it's a full 8-bit data register.

// ==============================================
// TCR (Timer Control Register) - 8 bits
// ==============================================
// TCR[7]    : LOAD     | 1: Load TCNT
// TCR[5]    : UPDOWN   | 0: Up-count, 1: Down-count
// TCR[4]    : EN       | 1: Enable counter
// TCR[1:0]  : CKS[1:0] | Clock source select
`define TCR_LOAD_BIT    7
`define TCR_UPDOWN_BIT  5
`define TCR_EN_BIT      4
`define TCR_CKS_MSB     1
`define TCR_CKS_LSB     0

// ==============================================
// TSR (an 8-bit Timer Status Register)
// ==============================================
// Bit positions
// TSR[1] : TMR_UDF | Underflow flag (1: TCNT underflowed, set by HW, clear by SW)
// TSR[0] : TMR_OVF | Overflow flag  (1: TCNT overflowed, set by HW, clear by SW)
`define TMR_UDF_BIT  1      // Underflow Flag
`define TMR_OVF_BIT  0      // Overflow Flag

`endif // __REG_DEF_V__
