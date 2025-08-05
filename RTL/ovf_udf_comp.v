module ovf_udf_comp (
  input  wire       pclk,            // System clock
  input  wire       preset_n,        // Active-low synchronous reset
  input  wire [7:0] TCNT,            // Current counter value
  input  wire       count_enable,    // Count enable signal
  input  wire       count_up_down,   // 0: count up, 1: count down
  output reg        TMR_OVF,         // Overflow flag
  output reg        TMR_UDF          // Underflow flag
);

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      // Reset all flags
      TMR_OVF  <= 1'b0;
      TMR_UDF  <= 1'b0;
    end else if (count_enable) begin
      // Check counting direction
      if (count_up_down == 1'b0) begin  // Counting up
        // NOTE: TCNT == 8'hFF means the counter is about to overflow.
        // The real overflow would happen on the next count (TCNT wraps to 8'h00).
        TMR_OVF  <= (TCNT == 8'hFF);  // Pre-overflow indication
        TMR_UDF  <= 1'b0;             // No underflow in count-up mode
      end else begin                  // Counting down
        // NOTE: TCNT == 8'h00 means the counter is about to underflow.
        // The real underflow would happen on the next count (TCNT wraps to 8'hFF).
        TMR_OVF  <= 1'b0;             // No overflow in count-down mode
        TMR_UDF  <= (TCNT == 8'h00);  // Pre-underflow indication
      end
    end else begin
      // No counting → Clear flags (alternatively, you could hold them)
      TMR_OVF  <= 1'b0;
      TMR_UDF  <= 1'b0;
    end
  end

endmodule
