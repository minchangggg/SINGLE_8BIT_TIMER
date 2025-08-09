`ifndef DETECT_CNT_EDGE_V
`define DETECT_CNT_EDGE_V

// -----------------------------------------------------------------------------
// Module: detect_cnt_edge
// Description:
//   - This module detects the rising edge of a selected divided clock (CLK_IN)
//     and generates a one-clock-cycle pulse (TMR_Edge) synchronized to pclk.
//
// Inputs:
//   - pclk      : System clock (used to synchronize inputs and output pulse)
//   - preset_n  : Active-low asynchronous reset
//   - CLK_IN    : 4 divided clock inputs (e.g. pclk/2, pclk/4, pclk/8, pclk/16)
//   - cks       : 2-bit clock select input, chooses which CLK_IN to monitor
//
// Output:
//   - TMR_Edge  : One-cycle pulse indicating rising edge detected on selected clock
// -----------------------------------------------------------------------------

module detect_cnt_edge (
  input  wire       pclk,
  input  wire       preset_n,
  input  wire [3:0] CLK_IN,
  input  wire [1:0] cks,
  output reg        TMR_Edge
);
  // Internal signals for synchronization and edge detection	
  reg [1:0] cks_r;
  reg       TMR_CLK_IN;
  reg       TMR_CLK_IN_reg;
  reg       TMR_CLK_IN_d;

  // ------------------------------------------------------------------
  // 1. Clock Select MUX (Combinational Logic)
  //   - Selects one of the divided clocks based on the cks_r signal.
  // ------------------------------------------------------------------
  always @(*) begin
    case (cks_r)
      2'b00: TMR_CLK_IN = CLK_IN[0];
      2'b01: TMR_CLK_IN = CLK_IN[1];
      2'b10: TMR_CLK_IN = CLK_IN[2];
      2'b11: TMR_CLK_IN = CLK_IN[3];
      default: TMR_CLK_IN = 1'b0;
    endcase
  end
  
  // ------------------------------------------------------------------
  // 2. Synchronization and Edge Detection (Sequential Logic)
  //   - Synchronizes the selected clock to pclk and detects the rising edge.
  // ------------------------------------------------------------------ 
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      cks_r <= 2'b0;
      TMR_CLK_IN_reg <= 1'b0;
      TMR_CLK_IN_d   <= 1'b0;
      TMR_Edge       <= 1'b0;
    end else begin
      // Register the clock select signal
      cks_r <= cks;
      // Two-stage synchronizer for the selected clock
      TMR_CLK_IN_reg <= TMR_CLK_IN;
      TMR_CLK_IN_d   <= TMR_CLK_IN_reg;
      // Generate a one-clock-cycle pulse on the rising edge
      TMR_Edge       <= (~TMR_CLK_IN_d) & TMR_CLK_IN_reg;
    end
  end

endmodule

`endif // DETECT_CNT_EDGE_V
