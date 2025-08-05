`ifndef CNT_UNIT_V
`define CNT_UNIT_V

`include "reg.v"

//-----------------------------------------------------------------------------
// Module: cnt_unit
// Description: 
//   Counter unit for timer module.
//   Supports programmable start value, up/down count, wraparound,
//   and external clock edge (TMR_Edge) based counting.
//
// Parameters:
//   - CNT_WIDTH (from `define): Counter bit width (e.g., 8)
//   - TCNT_RST  (from `define): Reset value of the counter
//
// Inputs:
//   - pclk             : System clock
//   - preset_n         : Active-low reset
//   - TMR_Edge         : Clock edge pulse from selected timer source
//   - count_start_value: Value to load into TCNT
//   - count_load       : Signal to trigger load
//   - count_enable     : Enable counting
//   - count_up_down    : Count direction (0: up, 1: down)
//
// Outputs:
//   - TCNT             : Current counter value
//
//-----------------------------------------------------------------------------

module cnt_unit (
  input  wire                  pclk,              // System clock
  input  wire                  preset_n,          // Active-low synchronous reset

  input  wire                  TMR_Edge,          // Clock edge from selected clock source
  input  wire [`CNT_WIDTH-1:0] count_start_value, // Load value when count_load is asserted
  input  wire                  count_load,        // Load enable
  input  wire                  count_enable,      // Enable counting
  input  wire                  count_up_down,     // 0 = up count, 1 = down count

  output reg  [`CNT_WIDTH-1:0] TCNT               // Current count value
);  

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      TCNT <= `TCNT_RST;  // Reset counter to default value
    end
    else if (count_load) begin
      TCNT <= count_start_value; 
    end
    else if (count_enable && TMR_Edge) begin
      if (!count_up_down) begin
        // Up count: wrap to 0 when max
        TCNT <= (TCNT == {`CNT_WIDTH{1'b1}}) ? {`CNT_WIDTH{1'b0}} : TCNT + 1'b1;
      end else begin
        // Down count: wrap to max when 0
        TCNT <= (TCNT == {`CNT_WIDTH{1'b0}}) ? {`CNT_WIDTH{1'b1}} : TCNT - 1'b1;
      end
    end
    else begin
      TCNT <= TCNT;  // Hold current value
    end
  end

endmodule
`endif
