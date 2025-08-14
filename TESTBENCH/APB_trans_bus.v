`include "reg_def.v"
// `DATA_WIDTH = 8

// ------------------------------------------
// APB Transaction Tasks
// ------------------------------------------

module APB_trans_bus #(
  parameter ADDR_WIDTH = 8
)(
  input wire       			   PCLK, PRESETn, 
  input wire 	   			   PREADY, PSLVERR,
  input wire [`DATA_WIDTH-1:0] PRDATA,
  output reg       			   PSEL, PENABLE, PWRITE,
  output reg [ADDR_WIDTH-1:0]  PADDR, 
  output reg [`DATA_WIDTH-1:0] PWDATA
);
  // Initial block to handle reset and set default values
  initial begin
    PSEL    = 1'b0;
    PENABLE = 1'b0;
    PWRITE  = 1'b0;
    PADDR   = {ADDR_WIDTH{1'b0}};
    PWDATA  = {`DATA_WIDTH{1'b0}};
  end

  // Always block for reset handling
  always @(negedge PRESETn) begin
    PSEL    = 1'b0;
    PENABLE = 1'b0;
    PWRITE  = 1'b0;
    PADDR   = {ADDR_WIDTH{1'b0}};
    PWDATA  = {`DATA_WIDTH{1'b0}};
  end

  // APB write task
  task apb_write (
    input [ADDR_WIDTH-1:0]  addr, 
    input [`DATA_WIDTH-1:0] data
  );
    begin
      @(posedge PCLK);
      // Setup phase: PSEL is high, PENABLE is low
      PADDR   = addr;
      PWDATA  = data;
      PWRITE  = 1'b1;
      PSEL    = 1'b1;
      PENABLE = 1'b0;

      @(posedge PCLK);
      // Access phase: PENABLE goes high
      PENABLE = 1'b1;
      // Wait for PREADY to be high to end the transaction
      wait (PREADY);

      @(posedge PCLK); 
      // After the transaction is complete, end the cycle
      PSEL    = 1'b0;
      PENABLE = 1'b0;
      #1;
      if (PSLVERR == 1'b1) 
        $display("!!! APB_WRITE Error: PSLVERR was asserted during transaction.");
      else
        $display ("Read transfer finished ", "\n");
    end
  endtask

  // APB read task with output data
  task apb_read (
    input [ADDR_WIDTH-1:0] addr,
    output [`DATA_WIDTH-1:0] data_out
  );
    begin
      @(posedge PCLK);
      // Setup phase: PSEL is high, PENABLE is low
      PADDR   = addr;
      PWRITE  = 1'b0;
      PSEL    = 1'b1;
      PENABLE = 1'b0;

      @(posedge PCLK);
      // Access phase: PENABLE goes high
      PENABLE = 1'b1;
      // Wait for PREADY to be high to end the transaction
      wait (PREADY);
      // Assign the read data to the output variable
      data_out = PRDATA;

      @(posedge PCLK);
      // After the transaction is complete, end the cycle
      PSEL    = 1'b0;
      PENABLE = 1'b0;
      #1;
      if (PSLVERR == 1'b1) 
        $display("!!! APB_WRITE Error: PSLVERR was asserted during transaction.");
      else
        $display ("Read transfer finished ", "\n");
    end
  endtask

  // --------------------------------------------------------------------------
  // Custom Testbench Helper Tasks
  // --------------------------------------------------------------------------

  // Task to read TCNT and verify its value
  // NOTE: This task assumes the TCNT register address is defined as `TCNT_ADDR`
  //       in `reg_def.v`. Please verify this address.
  task check_tcnt_value(
    input [`DATA_WIDTH-1:0] expected_value
  );
    reg [`DATA_WIDTH-1:0] actual_value;
    begin
      apb_read(`TCNT_ADDR, actual_value);
      if (actual_value == expected_value) begin
        $display("CHECK TCNT PASSED: Giá trị TCNT hiện tại đúng. Nhận được 0x%0h, mong đợi 0x%0h.",
                 actual_value, expected_value);
      end else begin
        $display("CHECK TCNT FAILED: Giá trị TCNT hiện tại sai. Nhận được 0x%0h, mong đợi 0x%0h.",
                 actual_value, expected_value);
      end
    end
  endtask

  // Task to read TSR and check the overflow and underflow flags
  task check_ovf_udf_flags(
    input ovf_expected, 
    input udf_expected
  );
    reg [`DATA_WIDTH-1:0] tsr_value;
    reg ovf_actual, udf_actual;
    begin
      apb_read(`TSR_ADDR, tsr_value);
      ovf_actual = tsr_value[0]; // Assuming bit 0 is OVF
      udf_actual = tsr_value[1]; // Assuming bit 1 is UDF

      if ((ovf_actual == ovf_expected) && (udf_actual == udf_expected)) begin
        $display("CHECK FLAGS PASSED: Cờ OVF/UDF đúng. OVF=%b/%b, UDF=%b/%b.",
                 ovf_actual, ovf_expected, udf_actual, udf_expected);
      end else begin
        $display("CHECK FLAGS FAILED: Cờ OVF/UDF sai. Nhận được OVF=%b, UDF=%b. Mong đợi OVF=%b, UDF=%b.",
                 ovf_actual, udf_actual, ovf_expected, udf_expected);
      end
    end
  endtask
  
endmodule
