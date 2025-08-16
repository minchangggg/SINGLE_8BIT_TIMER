`ifndef __APB_TRANS_BUS_V__
`define __APB_TRANS_BUS_V__

`include "reg_def.v"

module APB_trans_bus #(
  parameter ADDR_WIDTH = 8
)(
  input wire                   PCLK, PRESETn,
  input wire 				   PREADY, PSLVERR,
  input wire [`DATA_WIDTH-1:0] PRDATA,
  
  output reg 				   PSEL, PENABLE, PWRITE,
  output reg [ADDR_WIDTH-1:0]  PADDR,
  output reg [`DATA_WIDTH-1:0] PWDATA
);
  // Initial block to handle reset and set default values
  initial begin
    PSEL = 1'b0;
    PENABLE = 1'b0;
    PWRITE = 1'b0;
    PADDR = {ADDR_WIDTH{1'b0}};
    PWDATA = {`DATA_WIDTH{1'b0}};
  end

  // Always block for reset handling
  always @(negedge PRESETn) begin
    PSEL    <= 1'b0;
    PENABLE <= 1'b0;
    PWRITE  <= 1'b0;
    PADDR   <= {`DATA_WIDTH{1'b1}};
    PWDATA  <= {`DATA_WIDTH{1'b0}};
  end

  // APB write task
  task apb_write (
    input [ADDR_WIDTH-1:0] addr,
    input [`DATA_WIDTH-1:0] data
  );
    begin
      @(posedge PCLK);
      // Setup phase
      PADDR   <= addr;
      PWDATA  <= data;
      PWRITE  <= 1'b1;
      PSEL    <= 1'b1;
      PENABLE <= 1'b0;

      @(posedge PCLK);
      // Access phase
      PENABLE <= 1'b1;
      
      // Wait for PREADY to be high to end the transaction
      wait (PREADY);
      @(posedge PCLK);
      // After the transaction is complete, end the cycle
      PSEL <= 1'b0;
      PENABLE <= 1'b0;
      PWDATA <= {`DATA_WIDTH{1'b0}};     
    end
  endtask

  // APB read task (Đã sửa lỗi race condition)
  task apb_read (
    input      [ADDR_WIDTH-1:0] addr,
    output reg [`DATA_WIDTH-1:0] data_out
  );
    begin
      @(posedge PCLK);
      // Setup phase
      PADDR <= addr;
      PWRITE <= 1'b0;
      PSEL <= 1'b1;
      PENABLE <= 1'b0;

      @(posedge PCLK);
      // Access phase
      PENABLE <= 1'b1;
      
      // Wait for PREADY to be high to end the transaction
      wait (PREADY);
      @(posedge PCLK);
      // After the transaction is complete, end the cycle
      data_out = PRDATA;
      PSEL <= 1'b0;
      PENABLE <= 1'b0;     
    end
  endtask

  // --------------------------------------------------------------------------
  // Custom Testbench Helper Tasks (Đã sửa để truyền biến ra chính xác hơn)
  // --------------------------------------------------------------------------

  // -------------------
  // Check TCNT value
  // -------------------
  task check_tcnt_value(
    input [`DATA_WIDTH-1:0] expected_value
  );
    reg [`DATA_WIDTH-1:0] actual_value;
    begin
      // Truyền biến 'actual_value' vào task và đọc giá trị trả về
      apb_read(`TCNT_ADDR, actual_value);
      if (actual_value == expected_value)
        $display("CHECK TCNT PASSED: 0x%0h", actual_value);
      else
        $display("CHECK TCNT FAILED: got=0x%0h, expected=0x%0h",
          actual_value, expected_value);
    end
  endtask

  // -------------------
  // Check OVF/UDF flags
  // -------------------
  task check_ovf_udf_flags(
    input ovf_expected,
    input udf_expected
  );
    reg [`DATA_WIDTH-1:0] tsr_value;
    reg ovf_actual, udf_actual;
    begin
      // Truyền biến 'tsr_value' vào task và đọc giá trị trả về
      apb_read(`TSR_ADDR, tsr_value);
      ovf_actual = tsr_value[`TMR_OVF_BIT];
      udf_actual = tsr_value[`TMR_UDF_BIT];
      if ((ovf_actual == ovf_expected) && (udf_actual == udf_expected))
        $display("CHECK FLAGS PASSED: OVF=%b, UDF=%b", ovf_actual, udf_actual);
      else
        $display("CHECK FLAGS FAILED: got OVF=%b, UDF=%b, expected OVF=%b, UDF=%b",
          ovf_actual, udf_actual, ovf_expected, udf_expected);
    end
  endtask

endmodule

`endif // __APB_TRANS_BUS_V__
