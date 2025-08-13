// STATUS: OK

`ifndef POS_CNT_EDGE_DETECT_V
`define POS_CNT_EDGE_DETECT_V

// -----------------------------------------------------------------------------
// Module: pos_cnt_edge_detect
//
// Description:
//	 - This module combines the clock selection logic with edge detection.
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
module pos_cnt_edge_detect (
  input  wire      pclk,
  input  wire      preset_n,
  input  wire [3:0] CLK_IN,
  input  wire [1:0] cks,
  output wire       TMR_Edge
);
  // Internal signal to connect the two sub-modules
  wire TMR_CLK_IN;

  // Instantiate the clock selection module
  clk_sel_synced_alt u_clk_sel_synced_alt (
    .pclk       (pclk),
    .preset_n   (preset_n),
    .CLK_IN     (CLK_IN),
    .cks        (cks),
    .TMR_CLK_IN (TMR_CLK_IN)
  );

  // Instantiate the edge detection module
  pos_edge_detect_synced u_pos_edge_detect_synced (
    .pclk       (pclk),
    .preset_n   (preset_n),
    .TMR_CLK_IN (TMR_CLK_IN),
    .TMR_Edge   (TMR_Edge)
  );
endmodule

// -----------------------------------------------------------------------------
// Module: pos_edge_detect_synced
// Description:
//   - Performs a one-stage synchronization of the selected clock to pclk.
//   - Detects the rising edge and generates a one-cycle pulse.
// -----------------------------------------------------------------------------
module pos_edge_detect_synced (
  input  wire pclk,
  input  wire preset_n,
  input  wire TMR_CLK_IN,  
  output wire TMR_Edge
);
  // Delayed version of TMR_CLK_IN using DFF
  reg TMR_CLK_IN_d;
  
  // Asynchronous reset for the synchronizer FF
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
      TMR_CLK_IN_d <= 1'b0;       // Reset delayed signal
    else
      TMR_CLK_IN_d <= TMR_CLK_IN; // Capture previous state
  end
  
  // Generate a one-clock-cycle pulse on the rising edge
  assign TMR_Edge = TMR_CLK_IN & (~TMR_CLK_IN_d);

endmodule

// -----------------------------------------------------------------------------
// Module: clk_sel_synced_alt
// Description:
//   - Registers the clock select input (cks).
//   - Selects one of the 4 divided clocks using the registered cks value.
//   - Registers the selected clock output with asynchronous reset.
// -----------------------------------------------------------------------------
module clk_sel_synced_alt (
  input  wire      pclk,
  input  wire      preset_n,
  input  wire [3:0] CLK_IN,
  input  wire [1:0] cks, // clk_select signal
  output reg       TMR_CLK_IN
);
  // Internal signals for synchronization and edge detection
  reg [1:0] cks_r;
  reg TMR_CLK_IN_mux_out;

  // Register the clock select signal
  // This is a synchronous reset to ensure consistent behavior across FFs.
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
      cks_r <= 2'b0;
    else
      cks_r <= cks;
  end
  
  // Clock Select MUX (Combinational Logic)
  always @(*) begin
    case (cks_r)
      2'b00: TMR_CLK_IN_mux_out = CLK_IN[0];
      2'b01: TMR_CLK_IN_mux_out = CLK_IN[1];
      2'b10: TMR_CLK_IN_mux_out = CLK_IN[2];
      2'b11: TMR_CLK_IN_mux_out = CLK_IN[3];
      default: TMR_CLK_IN_mux_out = 1'b0;
    endcase
  end
  
  // Final output register with asynchronous reset
  // This ensures TMR_CLK_IN is a registered output and is cleared immediately on reset.
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
      TMR_CLK_IN <= 1'b0;
    else
      TMR_CLK_IN <= TMR_CLK_IN_mux_out;
  end
endmodule

`endif // POS_CNT_EDGE_DETECT_V
