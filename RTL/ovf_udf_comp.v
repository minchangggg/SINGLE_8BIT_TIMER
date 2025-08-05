// Timer Overflow and Underflow Comparator
module ovf_udf_comp #(
  parameter DATA_WIDTH = 8
)(
  input  wire       		   pclk,            // System clock
  input  wire       		   preset_n,        // Active-low synchronous reset
  
  input  wire [DATA_WIDTH-1:0] TCNT,            // Current counter value
  input  wire       		   count_enable,    // Count enable signal
  input  wire       		   count_up_down,   // 0: count up, 1: count down
  
  input  wire 				   clr_ovf,			// Clear overflow flag
  input  wire 				   clr_udf,			// Clear underflow flag
  
  output reg        		   TMR_OVF,         // Overflow flag
  output reg        		   TMR_UDF          // Underflow flag
);
  
  reg [7:0] TCNT_d;  // previous TCNT

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      // Reset all flags
      TMR_OVF  <= 1'b0;
      TMR_UDF  <= 1'b0;
      TCNT_d   <= {DATA_WIDTH{1'b0}};
    end else begin
      // Clear flags if requested
      TMR_OVF <= (clr_ovf) ? 1'b0 : TMR_OVF;
      TMR_UDF <= (clr_udf) ? 1'b0 : TMR_UDF; 
      
      // Detect overflow/underflow only if enabled
      if (count_enable) begin
      // Check counting direction
        if (!count_up_down) begin 
          // Counting up: TCNT == 8'hFF means the counter is about to overflow.
          // The real overflow would happen on the next count (TCNT wraps to 8'h00).
          if (TCNT_d == {DATA_WIDTH{1'b1}} && TCNT == {DATA_WIDTH{1'b0}})
            TMR_OVF <= 1'b1;
          else 
            TMR_OVF <= TMR_OVF;
          // clear UDF trong mode up
          TMR_UDF <= 1'b0; 
        end else begin                 
          // Counting down: TCNT == 8'h00 means the counter is about to underflow.
          // The real underflow would happen on the next count (TCNT wraps to 8'hFF).
          if (TCNT_d == {DATA_WIDTH{1'b0}} && TCNT == {DATA_WIDTH{1'b1}})
            TMR_UDF <= 1'b1;
          else 
            TMR_UDF <= TMR_UDF;
          // clear OVF trong mode down
          TMR_OVF <= 1'b0; 
        end
      end 
      // No counting → hold them
      else begin
        TMR_OVF  <= TMR_OVF;
        TMR_UDF  <= TMR_UDF;
      end
      
      // Save current value
      TCNT_d <= TCNT;
  end

endmodule
