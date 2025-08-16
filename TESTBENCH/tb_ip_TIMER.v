// =============================================================================
// File: tb_ip_TIMER.v
// Description: This testbench verifies the functionality of the ip_TIMER module
//              by simulating an APB bus interface and executing a series of
//              read/write test cases for its registers.
// =============================================================================
`timescale 1ns / 1ps
`include "reg_def.v"        // Register address definitions
`include "cnt_sys_signal.v" 
// `include "cnt_clk_in_gen.v" // Module to generate clock inputs (CLK_IN) for the timer
`include "APB_trans_bus.v"  // APB Bus Functional Model (BFM) for transactions

// Testbench: tb_ip_TIMER
module tb_ip_TIMER;

  // Parameters
  parameter ADDR_WIDTH  = 8;    // Defines the width of the APB address bus

  // DUT input signals
  reg                    PCLK;    // APB clock signal
  reg                    PRESETn; // APB active-low reset signal
  wire [3:0]             CLK_IN;  // 4 different clock sources for the timer
  wire                   PSEL, PENABLE, PWRITE; // APB control signals
  wire [ADDR_WIDTH-1:0]  PADDR;   // APB address bus
  wire [`DATA_WIDTH-1:0] PWDATA;  // APB write data bus

  // DUT output signals
  wire [`DATA_WIDTH-1:0] PRDATA;  // APB read data bus
  wire                   PREADY;  // APB ready signal from the slave
  wire                   PSLVERR; // APB slave error signal
  wire					 TMR_OVF; // Timer overflow output
  wire					 TMR_UDF; // Timer underflow output

  // Local variables for stimulus and checking register
  reg [`DATA_WIDTH-1:0] w_rand_data;
  reg [`DATA_WIDTH-1:0] data_read;
  
  reg [`DATA_WIDTH-1:0] cnt_before_write;
  reg [`DATA_WIDTH-1:0] cnt_after_write;
  
  reg [ADDR_WIDTH-1:0]  null_addr;
  reg [ADDR_WIDTH-1:0]  mixed_addr;

  // ---------------------------------------------------------------------------
  // Instantiate counter system signal (Clock + Reset + CLK_IN[4 sources] Generation)
  // ---------------------------------------------------------------------------
  cnt_sys_signal #(
    .sys_clk_period (10)
  ) u_cnt_sys_signal (
    .sys_clk_w   (PCLK),
    .sys_rst_n_w (PRESETn),
    .clk_in_w    (CLK_IN)
  );

  // ---------------------------------------------------------------------------
  // Instantiate APB transaction bus driver
  // ---------------------------------------------------------------------------
  APB_trans_bus #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_APB_trans_bus (
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    .PSEL    (PSEL),
    .PENABLE (PENABLE),
    .PWRITE  (PWRITE),
    .PADDR   (PADDR),
    .PWDATA  (PWDATA),
    .PRDATA  (PRDATA),
    .PREADY  (PREADY),
    .PSLVERR (PSLVERR)
  );

  // ---------------------------------------------------------------------------
  // Instantiate DUT (ip_TIMER) 
  // ---------------------------------------------------------------------------
  ip_TIMER #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_ip_timer (
    .CLK_IN  (CLK_IN),
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    .PSEL    (PSEL),
    .PENABLE (PENABLE),
    .PWRITE  (PWRITE),
    .PADDR   (PADDR),
    .PWDATA  (PWDATA),
    .PRDATA  (PRDATA),
    .PREADY  (PREADY),
    .PSLVERR (PSLVERR),
    .TMR_OVF (TMR_OVF),
    .TMR_UDF (TMR_UDF)
  );

  // Main Test Sequence
  initial begin
    // Dump simulation waveforms to a VCD file for visualization
    $dumpfile("tb_ip_TIMER.vcd");
    $dumpvars(0, tb_ip_TIMER);

    // Initialize local variables
    w_rand_data      = {`DATA_WIDTH{1'b0}};
    data_read        = {`DATA_WIDTH{1'b0}};
    cnt_before_write = {`DATA_WIDTH{1'b0}};
    cnt_after_write  = {`DATA_WIDTH{1'b0}};
    null_addr        = { ADDR_WIDTH{1'b1}};
    mixed_addr       = { ADDR_WIDTH{1'b1}};
    
    // Wait for the reset to be released
    wait (PRESETn === 1'b1);
    $display("=== Reset completed at %0t ===", $time);

    // =========================================================
    // Test Case 1: TDR (Timer Data Register) Read/Write
    // Objective: Verify that the TDR can be written to and read back correctly.
    // =========================================================
    $display("\n[--- TC1: TDR read/write ---]");
    // 1. Read the default value of TDR and verify it matches the reset value
    u_APB_trans_bus.apb_read(`TDR_ADDR, data_read);
    if (data_read == `TDR_RST)
      $display("TC1-1 PASS: Default TDR value = 0x%h", data_read);
    else
      $display("TC1-1 FAIL: Default TDR value incorrect, expected 0x%h but got 0x%h", `TDR_RST, data_read);

    // 2. Perform two write/readback cycles with random data
    repeat (20) begin
      w_rand_data = $urandom_range(255, 0);
      u_APB_trans_bus.apb_write(`TDR_ADDR, w_rand_data);
      u_APB_trans_bus.apb_read(`TDR_ADDR, data_read);
      if (data_read == w_rand_data)
        $display("TC1-2 PASS: Wrote and read 0x%h correctly", w_rand_data);
      else
        $display("TC1-2 FAIL: Mismatch readback from TDR, expected 0x%h, got 0x%h", w_rand_data, data_read);
    end

    // =========================================================
    // Test Case 2: TCR (Timer Control Register) Read/Write with Mask
    // Objective: Verify that only the writable bits of the TCR can be changed.
    // =========================================================
    $display("\n[--- TC2: TCR read/write mask ---]");
    // 1. Read the default value of TCR and verify it matches the reset value
    u_APB_trans_bus.apb_read(`TCR_ADDR, data_read);
    if (data_read == `TCR_RST)
      $display("TC2-1 PASS: Default TCR value = 0x%h", data_read);
    else
      $display("TC2-1 FAIL: Default TCR value incorrect, expected 0x%h but got 0x%h", `TCR_RST, data_read);

    // 2. Perform two write/readback cycles with a random value and verify the mask
    repeat (20) begin
      w_rand_data = $urandom_range(255, 0);
      u_APB_trans_bus.apb_write(`TCR_ADDR, w_rand_data);
      u_APB_trans_bus.apb_read(`TCR_ADDR, data_read);
      if (data_read == (w_rand_data & `TCR_WRITE_MASK))
        $display("TC2-2 PASS: Wrote 0x%h, read back masked value 0x%h as expected.", w_rand_data, data_read);
      else
        $display("TC2-2 FAIL: Readback value mismatch for TCR. Expected 0x%h, got 0x%h.", (w_rand_data & `TCR_WRITE_MASK), data_read);
    end

    // =========================================================
    // Test Case 3: TSR (Timer Status Register) Read/Write
    // Objective: Verify that only the writable bits of the TSR can be changed.
    // =========================================================
    $display("\n[--- TC3: TSR read/write ---]");
    // 1. Read the default value of TSR and verify it matches the reset value
    u_APB_trans_bus.apb_read(`TSR_ADDR, data_read);
    if (data_read == `TSR_RST)
      $display("TC3-1 PASS: Default TSR value = 0x%h", data_read);
    else
      $display("TC3-1 FAIL: Default TSR value incorrect, expected 0x%h but got 0x%h", `TSR_RST, data_read);

    // 2. Perform two write/readback cycles with a random value and verify the mask
    repeat (20) begin
      w_rand_data = $urandom_range(255, 0);
      u_APB_trans_bus.apb_write(`TSR_ADDR, w_rand_data);
      u_APB_trans_bus.apb_read(`TSR_ADDR, data_read);
      if (data_read == (w_rand_data & `TSR_WRITE_MASK))
        $display("TC3-2 PASS: Wrote 0x%h, read back masked value 0x%h as expected.", w_rand_data, data_read);
      else
        $display("TC3-2 FAIL: Readback value mismatch for TSR. Expected 0x%h, got 0x%h.", (w_rand_data & `TSR_WRITE_MASK), data_read);
    end
    
    // =========================================================
    // Test Case 4: TCNT (Timer Count Register) Read-Only Test
    // Objective: Verify that the TCNT register can be read from but not written to.
    // =========================================================
    $display("\n[--- TC4: Testing the TCNT read-only register ---]");
    
    // 1. Test read functionality.
    // Read the current value of TCNT to save it for later comparison.
    u_APB_trans_bus.apb_read(`TCNT_ADDR, cnt_before_write);
    // Check PSLVERR. After a successful read, PSLVERR must be 0.
    if (PSLVERR == 1'b0) 
      $display("TC3-1 PASS: Successfully read from TCNT address (0x%h).", `TCNT_ADDR);
    else 
      $display("TC3-1 FAIL: Failed to read from TCNT (PSLVERR = 1).", `TCNT_ADDR);

    // 2. Test write functionality.
    // Generate a random value to write.
    w_rand_data = $urandom_range(255, 0); 
    $display("=> Attempting to write value 0x%h to TCNT (0x%h)...", w_rand_data, `TCNT_ADDR);
    // Execute the write transaction.
    u_APB_trans_bus.apb_write(`TCNT_ADDR, w_rand_data);
    // Check PSLVERR. Since TCNT is a read-only register, the write must fail and PSLVERR must be asserted.
    if (PSLVERR)
      $display("TC4-2 PASS: Write to TCNT failed as expected (PSLVERR = 1).");
    else
      $display("TC4-2 FAIL: Write to TCNT succeeded unexpectedly (PSLVERR = 0).");

    // 3. Verify that the value of TCNT was not changed.
    // Read the value of TCNT again.
    u_APB_trans_bus.apb_read(`TCNT_ADDR, cnt_after_write);
    // Compare the value read with the initial value. They must be the same.
    if (cnt_after_write == cnt_before_write)
      $display("TC4-3 PASS: TCNT value is still 0x%h after attempted write.", cnt_after_write);
    else
      $display("TC4-3 FAIL: TCNT value was changed from 0x%h to 0x%h.", cnt_after_write, cnt_after_write); 
    
    // =========================================================
    // Test Case 5: Null Address
    // Objective: Verify that an access to an invalid address asserts PSLVERR.
    // =========================================================
    $display("\n[--- TC5: Null Address ---]");
    repeat (20) begin
      // Generate an address that is not one of the defined register addresses TDR, TCR, TSR
      do null_addr = $urandom_range(255, 0);
      while ((null_addr == `TDR_ADDR) || (null_addr == `TCR_ADDR) || (null_addr == `TSR_ADDR));
      w_rand_data = $urandom_range(255, 0);

      // Perform a write transaction to the invalid address
      u_APB_trans_bus.apb_write(null_addr, w_rand_data);
      // Read from the invalid address to check PSLVERR
      u_APB_trans_bus.apb_read(null_addr, data_read);
      // PSLVERR should be asserted for an invalid address
      if (PSLVERR)
        $display("TC5 PASS: PSLVERR asserted for invalid addr=0x%h", null_addr);
      else
        $display("TC5 FAIL: PSLVERR not asserted for invalid addr=0x%h", null_addr);
    end

    // =========================================================
    // Test Case 6: Mixed Valid/Invalid Address
    // Objective: Verify that the testbench handles both valid and invalid
    //             addresses within a sequence. Note: The behavior of this
    //             test case is dependent on the IP's specific address decoding.
    // =========================================================
    $display("\n[--- TC6: Mixed Address ---]");
    repeat (20) begin
      mixed_addr = $urandom_range(255, 0);
      w_rand_data = $urandom_range(255, 0);

      // Check if the random address is a valid register address
      if ((mixed_addr == `TDR_ADDR) || (mixed_addr == `TCR_ADDR) || (mixed_addr == `TSR_ADDR)) begin
        $display("=> Writing random data 0x%h to valid address 0x%h...", w_rand_data, mixed_addr);
        u_APB_trans_bus.apb_write(mixed_addr, w_rand_data);
        // After a valid access, PSLVERR should NOT be asserted
        if (!PSLVERR)
          $display("TC6 PASS: Write to valid addr 0x%h worked as expected (PSLVERR=0).", mixed_addr);
        else
          $display("TC6 FAIL: Write to valid addr 0x%h failed unexpectedly (PSLVERR=1).", mixed_addr);
      end else begin
        $display("=> Writing random data 0x%h to invalid address 0x%h...", w_rand_data, mixed_addr);
        u_APB_trans_bus.apb_write(mixed_addr, w_rand_data);
        // After an invalid access, PSLVERR should be asserted
        if (PSLVERR)
          $display("TC6 PASS: Write to invalid addr 0x%h failed as expected (PSLVERR=1).", mixed_addr);
        else
          $display("TC6 FAIL: Write to invalid addr 0x%h worked unexpectedly (PSLVERR=0).", mixed_addr);
      end
    end

    // End of Simulation
    $display("\n=== Test finished at %0t ===", $time);
    $finish;
  end

endmodule
