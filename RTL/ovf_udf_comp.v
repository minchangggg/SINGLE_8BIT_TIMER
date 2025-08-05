/*
Notes:
TCNT == 8'hFF → this is only "almost overflow", not actual overflow yet.
True overflow occurs when TCNT == 8'h00 and the previous value was 8'hFF.
Similarly for underflow: FF → 00 indicates overflow, while 00 → FF indicates underflow (when counting down).
*/
module ovf_udf_comp (
  input  wire       pclk,
  input  wire       preset_n,
  input  wire [7:0] TCNT,
  input  wire       count_enable,
  input  wire       count_up_down,
  output reg        TMR_OVF,
  output reg        TMR_UDF
);

  reg [7:0] TCNT_d;  // previous TCNT

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      TMR_OVF <= 1'b0;
      TMR_UDF <= 1'b0;
      TCNT_d  <= 8'h00;
    end else begin
      TCNT_d <= TCNT;  // register previous value
      if (count_enable) begin
        if (count_up_down == 1'b0) begin
          // Detect overflow: previous was FF, now is 00
          TMR_OVF <= (TCNT_d == 8'hFF && TCNT == 8'h00);
          TMR_UDF <= 1'b0;
        end else begin
          // Detect underflow: previous was 00, now is FF
          TMR_OVF <= 1'b0;
          TMR_UDF <= (TCNT_d == 8'h00 && TCNT == 8'hFF);
        end
      end else begin
        TMR_OVF <= 1'b0;
        TMR_UDF <= 1'b0;
      end
    end
  end

endmodule
