// -----------------------------------------------------------------------------
// Module: detect_cnt_edge
// Description:
//   This module detects the rising edge of a selected divided clock (CLK_IN)
//   and generates a one-cycle pulse (TMR_Edge) in the pclk domain.
//   It safely synchronizes the clock select signal (cks) before using it,
//   and performs edge detection by delaying the selected clock.
//
// Features:
//   - Supports 4 clock sources: pclk/2, /4, /8, /16 via CLK_IN[3:0]
//   - Clock source selected by 2-bit control cks (synchronized)
//   - Rising edge detection generates a one-cycle TMR_Edge pulse
//
// Inputs:
//   - pclk     : System clock
//   - preset_n : Active-low reset
//   - CLK_IN   : 4 divided clock inputs
//   - cks      : Clock select control signal
//
// Output:
//   - TMR_Edge : One-clock pulse when selected clock has rising edge
// -----------------------------------------------------------------------------

module detect_cnt_edge (
  input  wire       pclk,         // system clock
  input  wire       preset_n,     // active-low reset
  
  input  wire [3:0] CLK_IN,       // 4 divided clocks: pclk/2, /4, /8, /16
  input  wire [1:0] cks,          // select one of the 4 clocks
  
  output wire       TMR_Edge      // one-cycle pulse on pclk domain
);

  // Synchronize clock select signal to avoid glitch in mux
  reg [1:0] cks_r;
  always @(posedge pclk or negedge preset_n)
    if (!preset_n)
      cks_r <= 2'b00;
    else
      cks_r <= cks;

  // Select one of the divided clocks using synchronized cks_r
  wire TMR_CLK_IN;
  assign TMR_CLK_IN = CLK_IN[cks_r];

  // Delay the selected clock by one cycle to detect rising edge
  reg TMR_CLK_IN_d;
  always @(posedge pclk or negedge preset_n)
    if (!preset_n)
      TMR_CLK_IN_d <= 1'b0;
    else
      TMR_CLK_IN_d <= TMR_CLK_IN;

  // Generate one-cycle pulse on rising edge of selected clock
  assign TMR_Edge = ~TMR_CLK_IN_d & TMR_CLK_IN;

endmodule
