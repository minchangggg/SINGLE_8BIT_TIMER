`ifndef RW_REG_CONTROL_V
`define RW_REG_CONTROL_V

// FSM state encoding for APB protocol
`define IDLE   2'b00
`define SETUP  2'b01
`define ACCESS 2'b10

`include "reg_def.v"
// `DATA_WIDTH = 8

// -----------------------------------------------------------------------------
// Module: rw_reg_control
// Description:
//   This is the top-level module for the APB register file. It acts as a
//   wrapper, instantiating and connecting the sub-modules for read and write
//   logic. This modular design separates concerns for improved readability
//   and maintainability.
//
// Parameters:
//   - ADDR_WIDTH : Width of the APB address bus.
//
// Inputs:
//   - PCLK          : APB system clock.
//   - PRESETn       : Active-low asynchronous reset.
//   - PSEL          : APB peripheral select signal.
//   - PENABLE       : APB enable signal, high during the ACCESS phase.
//   - PWRITE        : APB write enable (1 for write, 0 for read).
//   - PADDR         : APB address bus.
//   - PWDATA        : APB write data bus.
//   - TCNT          : Current counter value (from counter unit).
//
// Outputs:
//   - PRDATA        : APB read data bus.
//   - PREADY        : APB ready signal, high when a transfer is complete.
//   - PSLVERR       : APB slave error signal, high for an invalid address.
//   - TDR           : Internal Timer Data Register value.
//   - TCR           : Internal Timer Control Register value.
//   - TSR           : Internal Timer Status Register value.
// -----------------------------------------------------------------------------
module rw_reg_control #(
  parameter ADDR_WIDTH = 8
)(
  // APB INTERFACE SIGNALS
  input  wire                   PCLK,
  input  wire                   PRESETn,
  input  wire                   PSEL,
  input  wire                   PENABLE,
  input  wire                   PWRITE,
  input  wire [ADDR_WIDTH-1:0]  PADDR,
  input  wire [`DATA_WIDTH-1:0] PWDATA,
  
  output wire  [`DATA_WIDTH-1:0] PRDATA,
  output wire                    PREADY,
  output wire                    PSLVERR,

  // INTERNAL REGISTER VALUES (to be used by other modules)
  input  wire [`DATA_WIDTH-1:0] TCNT,
  output wire [`DATA_WIDTH-1:0] TDR,
  output wire [`DATA_WIDTH-1:0] TCR,
  output wire [`DATA_WIDTH-1:0] TSR
);
  reg [`DATA_WIDTH-1:0] reg_TDR;
  reg [`DATA_WIDTH-1:0] reg_TCR;
  reg [`DATA_WIDTH-1:0] reg_TSR;

  // Internal wires for connecting sub-modules
  wire [1:0] 			 apb_pcurrstate;  
  wire        			 apb_pready;	  
  wire      			 apb_pslverr;	  
  wire [`DATA_WIDTH-1:0] read_prdata; // Internal wire to connect read logic output to top-level PRDATA
  
  // ------------------------------------------------------------------
  // Module Instantiations
  // ------------------------------------------------------------------
  
  // APB Transaction FSM
  // This module manages the APB handshake and generates pready/pslverr signals.
  APB_trans #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_apb_trans (
    // input
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .psel      (PSEL),
    .penable   (PENABLE),
    .pwrite    (PWRITE),
    .paddr     (PADDR),
    // output
    .pcurrstate(apb_pcurrstate),
    .pready    (apb_pready),
    .pslverr   (apb_pslverr)
  );

  // Write Logic Module
  // This module handles writing to TDR, TCR, and TSR registers.
  rw_write_logic #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_rw_write_logic (
    // input
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .psel      (PSEL),
    .penable   (PENABLE),
    .pwrite    (PWRITE),
    .paddr     (PADDR),
    .pwdata    (PWDATA),
    .pcurrstate(apb_pcurrstate),
    // output
    .TDR       (reg_TDR),
    .TCR       (reg_TCR),
    .TSR       (reg_TSR)
  );

  // Read Logic Module
  // This module handles reading from all registers (TDR, TCR, TSR, TCNT).
  rw_read_logic #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_rw_read_logic (
    // input
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .pready    (apb_pready),
    .psel      (PSEL),
    .penable   (PENABLE),
    .pwrite    (PWRITE),
    .paddr     (PADDR),
    .TDR       (reg_TDR),
    .TCR       (reg_TCR),
    .TSR       (reg_TSR),
    .TCNT      (TCNT),
    .pcurrstate(apb_pcurrstate),
    // output
    .prdata    (read_prdata)
  );
  
  // ------------------------------------------------------------------
  // Register reset logic: initialize internal registers on reset
  // ------------------------------------------------------------------
  
  // Assign top-level outputs
  assign PREADY  = apb_pready;
  assign PSLVERR = apb_pslverr;
  assign PRDATA  = read_prdata; 
  assign TDR     = reg_TDR;
  assign TCR     = reg_TCR;
  assign TSR     = reg_TSR;
endmodule

// -----------------------------------------------------------
// Sub-module: rw_read_logic
// Description: Handles all read transactions from APB to the registers.
// -----------------------------------------------------------
module rw_read_logic #(
  parameter ADDR_WIDTH = 8
)(
  input  wire                   pclk,
  input  wire                   preset_n,
  input  wire                   pready,
  input  wire                   psel,
  input  wire                   penable,
  input  wire                   pwrite,
  input  wire [ADDR_WIDTH-1:0]  paddr,
  input  wire [`DATA_WIDTH-1:0] TDR,
  input  wire [`DATA_WIDTH-1:0] TCR,
  input  wire [`DATA_WIDTH-1:0] TSR,
  input  wire [`DATA_WIDTH-1:0] TCNT,
  input  wire [1:0]             pcurrstate,
  
  output reg  [`DATA_WIDTH-1:0] prdata
);

  wire read_en;
  assign read_en = (pcurrstate == `ACCESS) & !pwrite;

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      prdata <= {`DATA_WIDTH{1'b0}};
    end else begin
      if (read_en) begin
        case (paddr)
          `TDR_ADDR  : prdata <= TDR;
          `TCR_ADDR  : prdata <= TCR;
          `TSR_ADDR  : prdata <= TSR;
          `TCNT_ADDR : prdata <= TCNT;
          default    : prdata <= {`DATA_WIDTH{1'b0}};
        endcase
      end else begin
        prdata <= prdata;
      end
    end
  end
endmodule

// -----------------------------------------------------------
// Sub-module: rw_write_logic
// Description: Handles all write transactions from APB to the registers.
// -----------------------------------------------------------
module rw_write_logic #(
  parameter ADDR_WIDTH = 8
)(
  input  wire                   pclk,
  input  wire                   preset_n,
  input  wire                   psel,
  input  wire                   penable,
  input  wire                   pwrite,
  input  wire [ADDR_WIDTH-1:0]  paddr,
  input  wire [`DATA_WIDTH-1:0] pwdata,
  input  wire [1:0]             pcurrstate,
  
  output reg  [`DATA_WIDTH-1:0] TDR,
  output reg  [`DATA_WIDTH-1:0] TCR,
  output reg  [`DATA_WIDTH-1:0] TSR
);
  wire [2:0] w_reg_sel; // Input for write register select
  wire       write_en;
  
  assign w_reg_sel = (paddr == `TDR_ADDR) ? 3'b001 : 
    				 (paddr == `TCR_ADDR) ? 3'b010 : 
    				 (paddr == `TSR_ADDR) ? 3'b100 : 3'b000;
    
  // The `|w_reg_sel` check ensures that there is a selected reg for writing.
  assign write_en = (pcurrstate == `ACCESS) & pwrite & |w_reg_sel;

  // Logic to handle reserved bits before writing to registers
  wire [`DATA_WIDTH-1:0] wdata_tdr;
  wire [`DATA_WIDTH-1:0] wdata_tcr;
  wire [`DATA_WIDTH-1:0] wdata_tsr;
  
  assign wdata_tdr = pwdata;
  assign wdata_tcr = {pwdata[7], 1'b0, pwdata[5:4], 2'b00, pwdata[1:0]};
  assign wdata_tsr = {6'b00, pwdata[1:0]};

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      TDR <= `TDR_RST;
      TCR <= `TCR_RST;
      TSR <= `TSR_RST;
    end else begin
      if (write_en) begin
        TDR <= (w_reg_sel[0]) ? wdata_tdr : TDR;
        TCR <= (w_reg_sel[1]) ? wdata_tcr : TCR;
        TSR <= (w_reg_sel[2]) ? wdata_tsr : TSR;
      end else begin 
        TDR <= TDR;
        TCR <= TCR;
        TSR <= TSR;
      end
    end
  end
endmodule

// -----------------------------------------------------------
// Sub-module: apb_trans (APB Transaction FSM)
// -----------------------------------------------------------
module APB_trans #(
  parameter ADDR_WIDTH = 8
)(
  // SIGNAL FOR APB INTERFACE
  input  wire                   pclk,
  input  wire                   preset_n,
  input  wire                   psel,
  input  wire                   penable,
  input  wire                   pwrite,
  input  wire [ADDR_WIDTH-1:0]  paddr,
  
  output reg [1:0]              pcurrstate,
  output reg                    pready,
  output reg                    pslverr             
);

  reg [1:0] cur_state, next_state;
  wire      invalid_addr;
  
  // Invalid address detection logic
  assign invalid_addr = pwrite ?
      				    (paddr != `TDR_ADDR && paddr != `TCR_ADDR && paddr != `TSR_ADDR) :
      				    (paddr != `TDR_ADDR && paddr != `TCR_ADDR && paddr != `TSR_ADDR && paddr != `TCNT_ADDR);

  // FSM: State transition
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) cur_state <= `IDLE;
    else           cur_state <= next_state;
  end

  // FSM: Next state logic
  always @(*) begin
    case (cur_state)
      `IDLE:   next_state = (psel && !penable) ? `SETUP : `IDLE;
      `SETUP:  next_state = (psel &&  penable) ? `ACCESS : `SETUP;
      `ACCESS: next_state = `IDLE;
      default: next_state = `IDLE;
    endcase
  end
  
  // Output logic: pready and pslverr
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      pready <= 1'b0; 
      pslverr <= 1'b0;
      pcurrstate <= `IDLE;
    end else begin
      pcurrstate <= cur_state;
      if (cur_state == `ACCESS) begin
        pready  <= 1'b1;
        pslverr <= invalid_addr;
      end else begin
        pready <= 1'b0; 
        pslverr <= 1'b0;
      end
    end
  end
 
endmodule

`endif // RW_REG_CONTROL_V
