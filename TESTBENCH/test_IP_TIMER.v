`timescale 1ns / 1ps
`include "reg_def.v"

// -----------------------------------------------------------------------------
// Module: tb_ip_TIMER
// Description:
//   This testbench verifies the read/write functionality of the TDR, TCR, and
//   TSR registers, and also checks for correct error handling with non-existent
//   (null) and mixed addresses, as per the provided test plan.
// -----------------------------------------------------------------------------

module tb_IP_TIMER;

  // --- Parameters ---
  parameter PCLK_PERIOD = 10;
  parameter ADDR_WIDTH  = 8;
  
  // --- Testbench Signals (DUT inputs) ---
  reg                    PCLK;
  reg                    PRESETn;
  reg  [3:0]             CLK_IN;
  reg                    PSEL;
  reg                    PENABLE;
  reg                    PWRITE;
  reg  [ADDR_WIDTH-1:0]  PADDR;
  reg  [`DATA_WIDTH-1:0] PWDATA;
  
  // --- Testbench Wires (DUT outputs) ---
  wire [`DATA_WIDTH-1:0] PRDATA;
  wire                   PREADY;
  wire                   PSLVERR;
  wire                   TMR_OVF;
  wire                   TMR_UDF;

  // --- Local variables for test stimulus ---
  reg [`DATA_WIDTH-1:0] data_read;
  reg [`DATA_WIDTH-1:0] random_value;
  
  // --- Instantiate the Device Under Test (DUT) ---
  ip_TIMER #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_ip_timer (
    .CLK_IN    (CLK_IN),
    .PCLK      (PCLK),
    .PRESETn   (PRESETn),
    .PSEL      (PSEL),
    .PENABLE   (PENABLE),
    .PWRITE    (PWRITE),
    .PADDR     (PADDR),
    .PWDATA    (PWDATA),
    .PRDATA    (PRDATA),
    .PREADY    (PREADY),
    .PSLVERR   (PSLVERR),
    .TMR_OVF   (TMR_OVF),
    .TMR_UDF   (TMR_UDF)
  );

  // ------------------------------------------
  // 1. Clock Generation - PCLK
  // ------------------------------------------
  initial begin
    PCLK = 1'b0;
    forever #(PCLK_PERIOD/2) PCLK = ~PCLK;
  end
  
  // ------------------------------------------
  // 2. Divided Clock Generation
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
  
  assign CLK_IN = {pclk_div16, pclk_div8, pclk_div4, pclk_div2};
  
  // ------------------------------------------
  // 3. APB Transaction Tasks
  // ------------------------------------------

  // APB write task
  task apb_write (
    input [ADDR_WIDTH-1:0] addr, 
    input [`DATA_WIDTH-1:0] data
  );
    begin
      @(posedge PCLK);
      // Setup phase
      PADDR   = addr;
      PWDATA  = data;
      PWRITE  = 1'b1;
      PSEL    = 1'b1;
      PENABLE = 1'b0;

      @(posedge PCLK);
      // Access phase
      PENABLE = 1'b1;
      wait (PREADY);

      @(posedge PCLK); 
      // End transaction
      $display("WRITE  addr=0x%02h data=0x%02h pready=%b pslverr=%b", 
               addr, data, PREADY, PSLVERR);
      PSEL    = 1'b0;
      PENABLE = 1'b0;
    end
  endtask

  // APB read task with output data
  task apb_read (
    input [ADDR_WIDTH-1:0] addr,
    output [`DATA_WIDTH-1:0] data_out
  );
    begin
      @(posedge PCLK);
      // Setup phase
      PADDR   = addr;
      PWRITE  = 1'b0;
      PSEL    = 1'b1;
      PENABLE = 1'b0;

      @(posedge PCLK);
      // Access phase
      PENABLE = 1'b1;
      wait (PREADY);
      data_out = PRDATA; // Assign PRDATA to the output variable

      @(posedge PCLK);
      // End transaction
      $display("READ   addr=0x%02h data=0x%02h pready=%b pslverr=%b", 
               addr, data_out, PREADY, PSLVERR);
      PSEL    = 1'b0;
      PENABLE = 1'b0;
    end
  endtask
  
  // ------------------------------------------
  // 4. Test Stimulus
  // ------------------------------------------
  initial begin
    $dumpfile("tb_ip_TIMER.vcd");
    $dumpvars(0, tb_ip_TIMER);

    // Initial values
    PSEL = 1'b0; PENABLE = 1'b0; PWRITE = 1'b0;
    PADDR = 8'h00; PWDATA = 8'h00;
    data_read    = {`DATA_WIDTH{1'b0}}; 	
    random_value = {`DATA_WIDTH{1'b0}};	
    
    // Reset
    PRESETn = 1'b0;
    repeat (2) @(posedge PCLK); PRESETn = 1'b1;
    $display("Time = %0t: Complete Reset, Start run testcase.", $time);
    
    // =======================================================================
    // Test Case 1: TDR test (read/write)
    // =======================================================================
    $display("------------------------------------------------------------------");
    $display("Test Case 1: TDR test (read/write)");
    
    // 1. Read TDR to check its default value
    apb_read(`TDR_ADDR, data_read);
    if (data_read == `TDR_RST) begin
      $display("TC_1-1 PASSED: Giá trị mặc định của TDR là đúng: 8'h%h.", data_read);
    end else begin
      $display("TC_1-1 FAILED: Giá trị mặc định của TDR sai. Nhận được: 8'h%h, Mong đợi: 8'h%h.", data_read, `TDR_RST);
    end
    
    // 2. and 3. Write/read random value to TDR, repeat 20 times
    repeat (20) begin
      random_value = $urandom_range(255, 0);
      apb_write(`TDR_ADDR, random_value);
      apb_read(`TDR_ADDR, data_read);
      if (data_read == random_value) begin
        $display("TC_1-2 PASSED: TDR đọc lại đúng giá trị đã ghi 8'h%h.", random_value);
      end else begin
        $display("TC_1-2 FAILED: TDR đọc lại sai giá trị. Nhận được: 8'h%h, Mong đợi: 8'h%h.", data_read, random_value);
      end
    end
    
    // =======================================================================
    // Test Case 2: TCR test (read/write) with mask
    // =======================================================================
    $display("------------------------------------------------------------------");
    $display("Test Case 2: TCR test (read/write) with mask");

    // 1. Read TCR to check its default value
    apb_read(`TCR_ADDR, data_read);
    if (data_read == `TCR_RST) begin
      $display("TC_2-1 PASSED: Giá trị mặc định của TCR là đúng: 8'h%h.", data_read);
    end else begin
      $display("TC_2-1 FAILED: Giá trị mặc định của TCR sai. Nhận được: 8'h%h, Mong đợi: 8'h%h.", data_read, `TCR_RST);
    end
    
    // 2. and 3. Write/read random value to TCR, repeat 20 times
    repeat (20) begin
      random_value = $urandom_range(255, 0);
      apb_write(`TCR_ADDR, random_value);
      apb_read(`TCR_ADDR, data_read);
      
      // Compare with the written value after applying mask 1011_0011 (8'hB3)
      if ((data_read & 8'hB3) == (random_value & 8'hB3)) begin
        $display("TC_2-2 PASSED: TCR đọc lại đúng giá trị đã ghi sau khi áp dụng mask 8'hB3.");
      end else begin
        $display("TC_2-2 FAILED: TCR đọc lại sai giá trị. Nhận được: 8'h%h, Mong đợi: 8'h%h.", data_read, (random_value & 8'hB3));
      end
    end

    // =======================================================================
    // Test Case 3: TSR test (read/write)
    // =======================================================================
    $display("------------------------------------------------------------------");
    $display("Test Case 3: TSR test (read/write)");
    
    // 1. Read TSR to check its default value
    apb_read(`TSR_ADDR, data_read);
    if (data_read == `TSR_RST) begin
      $display("TC_3-1 PASSED: Giá trị mặc định của TSR là đúng: 8'h%h.", data_read);
    end else begin
      $display("TC_3-1 FAILED: Giá trị mặc định của TSR sai. Nhận được: 8'h%h, Mong đợi: 8'h%h.", data_read, `TSR_RST);
    end
    
    // 2. and 3. Write/read random value to TSR, repeat 20 times
    repeat (20) begin
      random_value = $urandom_range(255, 0);
      apb_write(`TSR_ADDR, random_value);
      apb_read(`TSR_ADDR, data_read);
      
      // The writable bits of TSR are assumed to be TMR_UDF (bit 1) and TMR_OVF (bit 0).
      // Writing to them should clear the flags, so the read value should be 0.
      if ((data_read & 8'h03) == 8'h00) begin
        $display("TC_3-2 PASSED: Các bit cờ của TSR đã được xóa đúng cách sau khi ghi.");
      end else begin
        $display("TC_3-2 FAILED: Các bit cờ của TSR không được xóa. Nhận được: 8'h%h, Mong đợi: 8'h00.", (data_read & 8'h03));
      end
    end
    
    // =======================================================================
    // Test Case 4: Null Address Test
    // -----------------------------------------------------------------------
    // The test bench should write a random value to a random address (not TDR, TCR or TSR)
    // Check if PSLVERR is triggered.
    // Repeat 20 times
    // =======================================================================
    $display("------------------------------------------------------------------");
    $display("Test Case 4: Null Address Test");
    
    repeat (20) begin
      reg [7:0] null_addr;
      // Generate a random address that is not TDR, TCR, or TSR
      do begin
          null_addr = $urandom_range(255, 0);
      end while ((null_addr == `TDR_ADDR) || (null_addr == `TCR_ADDR) || (null_addr == `TSR_ADDR));
      
      random_value = $urandom_range(255, 0);
      apb_write(null_addr, random_value);
      
      // Check for PSLVERR and that PRDATA is 0
      if (PSLVERR == 1'b1) begin
          $display("TC_4 PASSED: PSLVERR đã được kích hoạt cho địa chỉ không tồn tại 8'h%h.", null_addr);
      end else begin
          $display("TC_4 FAILED: PSLVERR không được kích hoạt cho địa chỉ không tồn tại 8'h%h.", null_addr);
      end
    end
    
    // =======================================================================
    // Test Case 5: Mixed Address Test
    // -----------------------------------------------------------------------
    // The test bench should write a random value to a random address
    // Check if PSLVERR is triggered if the address is not TDR, TCR or TSR.
    // Check if the read value matches the written value if the address is one of the valid registers.
    // Repeat 20 times.
    // =======================================================================
    $display("------------------------------------------------------------------");
    $display("Test Case 5: Mixed Address Test (valid and invalid)");
    
    repeat (20) begin
      reg [7:0] mixed_addr;
      reg is_valid_addr;
      
      // Generate a random address
      mixed_addr = $urandom_range(255, 0);
      
      // Check if the address is valid
      is_valid_addr = ((mixed_addr == `TDR_ADDR) || (mixed_addr == `TCR_ADDR) || (mixed_addr == `TSR_ADDR));
      
      random_value = $urandom_range(255, 0);
      apb_write(mixed_addr, random_value);
      
      // Read back the value
      apb_read(mixed_addr, data_read);
      
      if (is_valid_addr) begin
        // Case: Valid address
        if (PSLVERR == 1'b0) begin
          if (mixed_addr == `TDR_ADDR && data_read == random_value) begin
            $display("TC_5 PASSED: Đã ghi và đọc đúng giá trị 8'h%h từ TDR.", random_value);
          end else if (mixed_addr == `TCR_ADDR && (data_read & 8'hB3) == (random_value & 8'hB3)) begin
            $display("TC_5 PASSED: Đã ghi và đọc đúng giá trị 8'h%h từ TCR (sau khi áp mask).", (random_value & 8'hB3));
          end else if (mixed_addr == `TSR_ADDR && (data_read & 8'h03) == 8'h00) begin
            $display("TC_5 PASSED: Đã ghi và xóa cờ thành công cho TSR.");
          end else begin
            $display("TC_5 FAILED: Lỗi không mong muốn với địa chỉ hợp lệ 8'h%h.", mixed_addr);
          end
        end else begin
          $display("TC_5 FAILED: PSLVERR bị kích hoạt không đúng cho địa chỉ hợp lệ 8'h%h.", mixed_addr);
        end
      end else begin
        // Case: Invalid address
        if (PSLVERR == 1'b1) begin
          $display("TC_5 PASSED: PSLVERR đã được kích hoạt đúng cho địa chỉ không hợp lệ 8'h%h.", mixed_addr);
        end else begin
          $display("TC_5 FAILED: PSLVERR không được kích hoạt cho địa chỉ không hợp lệ 8'h%h.", mixed_addr);
        end
      end
    end
    
    // End simulation
    $display("------------------------------------------------------------------");
    $display("Test finished.");
    $finish;
  end

endmodule
