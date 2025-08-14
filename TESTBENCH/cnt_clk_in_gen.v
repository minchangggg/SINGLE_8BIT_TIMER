// Module này chỉ nhận PCLK và PRESETn làm đầu vào và tạo ra CLK_IN
module cnt_clk_in_gen (
  input wire PCLK,
  input wire PRESETn,
  output reg [3:0] CLK_IN
);

  // ------------------------------------------
  // 1. Divided Clock Generation
  // ------------------------------------------
  reg pclk_div2, pclk_div4, pclk_div8, pclk_div16;
  
  initial begin
    pclk_div2  = 1'b0;
    pclk_div4  = 1'b0;
    pclk_div8  = 1'b0;
    pclk_div16 = 1'b0;
  end

  always @(posedge PCLK)      pclk_div2  <= ~pclk_div2;
  always @(posedge pclk_div2) pclk_div4  <= ~pclk_div4;
  always @(posedge pclk_div4) pclk_div8  <= ~pclk_div8;
  always @(posedge pclk_div8) pclk_div16 <= ~pclk_div16;
  
  always @(*) begin
    CLK_IN = {pclk_div16, pclk_div8, pclk_div4, pclk_div2};
  end
endmodule
