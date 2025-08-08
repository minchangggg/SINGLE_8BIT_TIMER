`ifndef DETECT_CNT_EDGE_V
`define DETECT_CNT_EDGE_V

// -----------------------------------------------------------------------------
// Module: detect_cnt_edge
// Description:
//   - This module detects the rising edge of a selected divided clock (CLK_IN)
//   and generates a one-cycle pulse (TMR_Edge) in the pclk domain.
//
// Inputs:
//   - pclk      : System clock
//   - preset_n  : Active-low reset
//   - CLK_IN    : 4 divided clock inputs
//   - cks       : Clock select control signal
//
// Output:
//   - TMR_Edge  : One-clock pulse on selected clock edge
// -----------------------------------------------------------------------------
module detect_cnt_edge (
  input  wire       pclk,
  input  wire       preset_n,
  input  wire [3:0] CLK_IN,
  input  wire [1:0] cks,
  output wire       TMR_Edge
);

  wire [1:0] cks_r;
  wire       TMR_CLK_IN;
  wire       TMR_CLK_IN_reg;
  wire       TMR_CLK_IN_d;
  
  /*cks_r: Là tín hiệu cks sau khi đã được đồng bộ hóa bởi module FF_2bit. 
  Là đầu ra của khối FF đầu tiên, giúp loại bỏ các lỗi tiềm ẩn (glitches) và đảm bảo tín hiệu này ổn định trước khi đưa vào bộ MUX.*/
  /*TMR_CLK_IN: Là một tín hiệu [tổ hợp]. Là đầu ra trực tiếp của (MUX). 
  Giá trị của nó thay đổi ngay lập tức khi tín hiệu cks_r hoặc CLK_IN thay đổi, không phụ thuộc vào xung clock pclk.*/
  /*TMR_CLK_IN_reg: Là một tín hiệu [tuần tự]. Là đầu ra của khối FF thứ hai.
  Tín hiệu này lưu trữ giá trị hiện tại của TMR_CLK_IN sau mỗi chu kỳ pclk (Giá trị của nó chỉ được cập nhật tại cạnh lên của pclk. Giữa hai cạnh lên, nó giữ nguyên giá trị cũ.)*/
  /*TMR_CLK_IN_d: Đây là tín hiệu TMR_CLK_IN_reg sau khi bị trễ thêm một chu kỳ pclk. Nó lưu giữ giá trị của TMR_CLK_IN_reg ở chu kỳ trước. Nó là đầu ra của khối FF thứ ba.*/

  // Synchronize 'cks' to prevent glitches on the MUX select line (using a 2-bit FF)
  FF_nbit #(.WIDTH(2)) u_cks_sync (
    .pclk     (pclk),
    .preset_n (preset_n),
    .D        (cks),
    .Q        (cks_r)
  );

  // MUX selects one of the divided clocks based on the synchronized 'cks'
  assign TMR_CLK_IN = (cks_r == 2'b00) ? CLK_IN[0] :
                      (cks_r == 2'b01) ? CLK_IN[1] :
                      (cks_r == 2'b10) ? CLK_IN[2] :
                                         CLK_IN[3];

  // Register the MUX output (using a 1-bit FF)
  FF_nbit #(.WIDTH(1)) u_tmr_clk_in_reg (
    .pclk     (pclk),
    .preset_n (preset_n),
    .D        (TMR_CLK_IN),
    .Q        (TMR_CLK_IN_reg)
  );

  // Delay the registered clock by one 'pclk' cycle (using a 1-bit FF)
  FF_nbit #(.WIDTH(1)) u_tmr_clk_in_delay (
    .pclk     (pclk),
    .preset_n (preset_n),
    .D        (TMR_CLK_IN_reg),
    .Q        (TMR_CLK_IN_d)
  );

  // Generate a one-cycle pulse on the rising edge
  // This is a standard rising edge detection formula
  assign TMR_Edge = ~TMR_CLK_IN_d & TMR_CLK_IN_reg;

endmodule

// -----------------------------------------------------------------------------
// Module: FF_nbit
// Description:
//   - Parameterized N-bit D-Flip-Flop with asynchronous active-low reset.
//   - Captures D on pclk rising edge, clears Q to zero on preset_n low.
//   - WIDTH parameter sets bit width (default 1).
//
// Parameters:
//   - WIDTH : Bit width, default 1.
//
// Inputs:
//   - pclk     : Clock input.
//   - preset_n : Active-low reset.
//   - D        : Input data.
//
// Outputs:
//   - Q        : Output data.
// -----------------------------------------------------------------------------
module FF_nbit #(
  parameter WIDTH = 1
)(
  input  wire             pclk,
  input  wire             preset_n,
  input  wire [WIDTH-1:0] D,
  output reg  [WIDTH-1:0] Q
);
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
      Q <= {WIDTH{1'b0}};
    else
      Q <= D;
  end
endmodule

`endif
