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
//   - Clock source selected via synchronized 2-bit control signal (cks)
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
  input  wire       pclk,         // System clock
  input  wire       preset_n,     // Active-low reset

  input  wire [3:0] CLK_IN,       // 4 divided clocks: pclk/2, /4, /8, /16
  input  wire [1:0] cks,          // Clock select

  output wire       TMR_Edge      // One-cycle pulse on selected clock edge
);

  // Synchronize clock select signal to avoid glitch in MUX
  reg [1:0] cks_r;
  always @(posedge pclk or negedge preset_n)
    if (!preset_n)
      cks_r <= 2'b00;
    else
      cks_r <= cks;

  // Select one of the divided clocks using synchronized cks_r
  reg TMR_CLK_IN;
  always @(posedge pclk or negedge preset_n)
    if (!preset_n)
      TMR_CLK_IN <= 1'b0;
    else begin
      case (cks_r)
        2'b00: TMR_CLK_IN <= CLK_IN[0];
        2'b01: TMR_CLK_IN <= CLK_IN[1];
        2'b10: TMR_CLK_IN <= CLK_IN[2];
        2'b11: TMR_CLK_IN <= CLK_IN[3];
      endcase
    end

  // Delay selected clock by one cycle to detect rising edge
  reg TMR_CLK_IN_d;
  always @(posedge pclk or negedge preset_n)
    if (!preset_n)
      TMR_CLK_IN_d <= 1'b0;
    else
      TMR_CLK_IN_d <= TMR_CLK_IN;

  // Generate one-cycle pulse on rising edge of selected clock
  assign TMR_Edge = ~TMR_CLK_IN_d & TMR_CLK_IN;

endmodule
