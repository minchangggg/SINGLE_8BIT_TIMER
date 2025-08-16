`ifndef __SYS_TMR_SIGNAL_V__
`define __SYS_TMR_SIGNAL_V__

// =============================================================================
// Module: sys_signal
// Description: Generates the main system clock and active-low reset signal.
// Parameters:
//   - sys_clk_period: The period of the generated clock in ns.
// Outputs:
//   - sys_clk: The system clock.
//   - sys_rst_n: The active-low reset signal.
// =============================================================================
module sys_signal #(
  parameter sys_clk_period = 10
)(
  output reg sys_clk, sys_rst_n
);
  
  // Clock Generation: sys_clk
  initial begin
    sys_clk = 1'b0;
    forever #(sys_clk_period/2) sys_clk = ~sys_clk;
  end

  // Reset Generation: sys_rst_n
  initial begin          
    sys_rst_n = 1'b0;            // Assert reset
    repeat (2) @(posedge sys_clk); // Wait for a few clock cycles
    sys_rst_n = 1'b1;            // Release reset
  end

endmodule

// =============================================================================
// Module: cnt_clk_in_gen
// Description: Generates four divided clock signals from a single input clock.
// Outputs:
//   - sys_clk: The input clock.
//   - clk_in: A 4-bit bus containing the divided clocks.
// =============================================================================
module cnt_clk_in_gen (
  input wire sys_clk,
  output wire [3:0] clk_in
);

  // Divided Clock Registers
  reg clk_div2, clk_div4, clk_div8, clk_div16;
  
  initial begin
    // Initialize registers to 0
    clk_div2  = 1'b0;
    clk_div4  = 1'b0;
    clk_div8  = 1'b0;
    clk_div16 = 1'b0;
  end

  // Generate divided clocks from the input clock
  always @(posedge sys_clk)   clk_div2  <= ~clk_div2;
  always @(posedge clk_div2)  clk_div4  <= ~clk_div4;
  always @(posedge clk_div4)  clk_div8  <= ~clk_div8;
  always @(posedge clk_div8)  clk_div16 <= ~clk_div16;
  
  // Assign the divided clocks to the output bus
  assign clk_in = {clk_div16, clk_div8, clk_div4, clk_div2};

endmodule

// =============================================================================
// Module: cnt_sys_signal
// Description: Top-level module that instantiates the clock/reset generator
//              and the divided clock generator. This module serves as a
//              convenient wrapper for the testbench.
// Outputs:
//   - sys_clk_w: The main system clock.
//   - sys_rst_n_w: The system reset.
//   - clk_in_w: The four divided clock signals.
// =============================================================================
module cnt_sys_signal #(
  parameter sys_clk_period = 10
)(
  output wire sys_clk_w,
  output wire sys_rst_n_w,
  output wire [3:0] clk_in_w  
);
  
  // Internal wire to connect the two sub-modules
  wire sys_clk_int;
  
  // Instantiate the clock and reset generator
  sys_signal #(
    .sys_clk_period(sys_clk_period)
  ) signal_gen_inst (
    .sys_clk(sys_clk_int),
    .sys_rst_n(sys_rst_n_w)
  );

  // Instantiate the divided clock generator
  cnt_clk_in_gen clk_gen_inst (
    .sys_clk(sys_clk_int),
    .clk_in(clk_in_w)
  );

  // Connect the internal clock wire to the output
  assign sys_clk_w = sys_clk_int;

endmodule

`endif // __SYS_TMR_SIGNAL_V__
