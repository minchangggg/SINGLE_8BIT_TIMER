`ifndef IP_TIMER_V
`define IP_TIMER_V

`include "reg_def.v"
// `DATA_WIDTH = 8
`include "rw_register.v"
`include "detect_cnt_edge.v"
`include "logic_control.v"
`include "cnt_unit.v"
`include "ovf_udf_comp.v"

// -----------------------------------------------------------------------------
// Module: ip_TIMER
// Description:
//   Top-level module for a simple APB timer peripheral. This module
//   connects all the sub-modules, including the APB register file,
//   the counter unit, and the control logic.
// -----------------------------------------------------------------------------
module ip_TIMER #(
  parameter ADDR_WIDTH = 8
)(
  input  wire [3:0]             CLK_IN,    // 4 divided clocks from PCLK
  
  // APB interface
  input  wire                   PCLK,    // System clock
  input  wire                   PRESETn, // Active-low reset
  input  wire                   PSEL,
  input  wire                   PENABLE,
  input  wire                   PWRITE,
  input  wire [ADDR_WIDTH-1:0]  PADDR,
  input  wire [`DATA_WIDTH-1:0] PWDATA,
  output wire [`DATA_WIDTH-1:0] PRDATA,
  output wire                   PREADY,
  output wire                   PSLVERR,

  // Output flags
  output wire                   TMR_OVF,
  output wire                   TMR_UDF
);
  
  // ------------------------------------------------------------------
  // Internal Wires for module connections
  // ------------------------------------------------------------------
  // Internal SFR storage
  wire [`DATA_WIDTH-1:0] TDR_reg;
  wire [`DATA_WIDTH-1:0] TCR_reg;
  wire [`DATA_WIDTH-1:0] TSR_reg;
  wire [`DATA_WIDTH-1:0] TCNT_reg;
  
  // Wires for control signals from logic_control module
  wire [`DATA_WIDTH-1:0] count_start_value;
  wire                   count_load;
  wire                   count_enable;
  wire                   count_up_down;
  
  wire [1:0]             cks;
  // Wire for clock edge from detect_cnt_edge module
  wire                   TMR_Edge;
  
  // Wires for flags from ovf_udf_comp
  wire                   TMR_OVF_int;
  wire                   TMR_UDF_int;

  // ══════════════════════════════════════════════════════════════════════════════════════════════
  // 1. APB READ/WRITE REGISTER CONTROLLER
  //   - This module acts as the interface to the APB bus and
  //     stores the values of the internal registers (TDR, TCR, TSR).
  rw_reg_register #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_rw_register (
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
    
    .TCNT      (TCNT_reg),      // Connects to the output of the counter unit
    .TDR_reg   (TDR_reg),       // Outputs the internal TDR register value
    .TCR_reg   (TCR_reg),       // Outputs the internal TCR register value
    .TSR_reg   (TSR_reg)        // Outputs the internal TSR register value
  );

  // ══════════════════════════════════════════════════════════════════════════════════════════════
  // 2. CLOCK DIVIDER EDGE DETECTION LOGIC
  //   - This module selects the appropriate clock from CLK_IN based on
  //     the 'cks' signal and generates a single-cycle edge pulse.
  detect_cnt_edge u_detect_cnt_edge (
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .CLK_IN    (CLK_IN),
    .cks       (cks),
    .TMR_Edge  (TMR_Edge)
  );

  // ══════════════════════════════════════════════════════════════════════════════════════════════
  // 3. LOGIC CONTROL (FSM for control signal generation)
  //   - This module takes the control register (TCR_reg) and status flags,
  //     and generates all the necessary control signals for other modules.
  logic_control u_logic_control (
    .TDR               (TDR_reg),
    .TCR               (TCR_reg),
    .TSR               (TSR_reg),
    .TMR_OVF           (TMR_OVF_int),
    .TMR_UDF           (TMR_UDF_int),
    
    .count_start_value (count_start_value),
    .count_load        (count_load),
    .count_enable      (count_enable),
    .count_up_down     (count_up_down),
    .cks               (cks)
  );

  // ══════════════════════════════════════════════════════════════════════════════════════════════
  // 4. TIMER COUNTER UNIT
  //   - This is the main counter. It receives control signals and
  //     updates its count value (TCNT_reg).
  cnt_unit u_cnt_unit (
    .pclk              (PCLK),
    .preset_n          (PRESETn),
    .TMR_Edge          (TMR_Edge),
    
    .count_start_value (count_start_value),
    .count_load        (count_load),
    .count_enable      (count_enable),
    .count_up_down     (count_up_down),
    
    .CNT               (TCNT_reg)
  );

  // ══════════════════════════════════════════════════════════════════════════════════════════════
  // 5. OVERFLOW/UNDERFLOW COMPARATOR
  //   - This module compares the current and previous TCNT value
  //     to detect overflow/underflow
  ovf_udf_comp u_ovf_udf_comp (
    .pclk          (PCLK),
    .preset_n      (PRESETn),
    
    .count_enable  (count_enable),
    .count_up_down (count_up_down),
    
    .CNT           (TCNT_reg),
    
    .TMR_OVF       (TMR_OVF_int),
    .TMR_UDF       (TMR_UDF_int)
  );

  // Map internal flags to the top-level outputs
  assign TMR_OVF = TMR_OVF_int;
  assign TMR_UDF = TMR_UDF_int;
endmodule

`endif // IP_TIMER_V
