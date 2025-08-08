`ifndef RW_REG_CONTROL_V
`define RW_REG_CONTROL_V

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
//   - TMR_OVF       : Overflow flag (from comparator).
//   - TMR_UDF       : Underflow flag (from comparator).
//
// Outputs:
//   - PRDATA        : APB read data bus.
//   - PREADY        : APB ready signal, high when a transfer is complete.
//   - PSLVERR       : APB slave error signal, high for an invalid address.
//   - TDR_reg       : Internal Timer Data Register value.
//   - TCR_reg       : Internal Timer Control Register value.
//   - TSR_reg       : Internal Timer Status Register value.
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
  
  output wire [`DATA_WIDTH-1:0] PRDATA,
  output wire                   PREADY,
  output wire                   PSLVERR,

  // INTERNAL REGISTER VALUES (to be used by other modules)
  input  wire [`DATA_WIDTH-1:0] TCNT,
  output wire [`DATA_WIDTH-1:0] TDR_reg,
  output wire [`DATA_WIDTH-1:0] TCR_reg,
  output wire [`DATA_WIDTH-1:0] TSR_reg,

  // STATUS FLAGS
  input  wire                   TMR_OVF,
  input  wire                   TMR_UDF
);
  
  // Internal wires for connecting sub-modules
  wire apb_pready;
  wire apb_pslverr;
  wire [2:0] w_reg;

  // ------------------------------------------------------------------
  // Module Instantiations
  // ------------------------------------------------------------------
  
  // APB Transaction FSM
  // This module manages the APB handshake and generates pready/pslverr signals.
  APB_trans #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_apb_trans (
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .psel      (PSEL),
    .penable   (PENABLE),
    .pwrite    (PWRITE),
    .paddr     (PADDR),
    .pready    (apb_pready),
    .pslverr   (apb_pslverr)
  );

  // Write Address Decoder
  // This module decodes the write address to select the target register.
  sel_w_reg #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_sel_w_reg (
    .paddr (PADDR),
    .w_reg (w_reg)
  );

  // Write Logic Module
  // This module handles writing to TDR, TCR, and TSR registers.
  // It also manages the TSR flag updates from external signals.
  rw_write_logic #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_rw_write_logic (
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .pready    (apb_pready),
    .psel      (PSEL),
    .penable   (PENABLE),
    .pwrite    (PWRITE),
    .pwdata    (PWDATA),
    .paddr     (PADDR),
    .TMR_OVF   (TMR_OVF),
    .TMR_UDF   (TMR_UDF),
    .TDR_reg   (TDR_reg),
    .TCR_reg   (TCR_reg),
    .TSR_reg   (TSR_reg)
  );

  // Read Logic Module
  // This module handles reading from all registers (TDR, TCR, TSR, TCNT).
  rw_read_logic #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_rw_read_logic (
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .pready    (apb_pready),
    .psel      (PSEL),
    .penable   (PENABLE),
    .pwrite    (PWRITE),
    .paddr     (PADDR),
    .TDR       (TDR_reg),
    .TCR       (TCR_reg),
    .TSR       (TSR_reg),
    .TCNT      (TCNT),
    .prdata    (PRDATA)
  );
  
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
  output reg  [`DATA_WIDTH-1:0] prdata
);

  wire read_en;
  assign read_en = psel & penable & !pwrite & pready;

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
      prdata <= {`DATA_WIDTH{1'b0}};
    else begin
      if (read_en) begin
        case (paddr)
          `TDR_ADDR  : prdata <= TDR;
          `TCR_ADDR  : prdata <= TCR;
          `TSR_ADDR  : prdata <= TSR;
          `TCNT_ADDR : prdata <= TCNT;
          default    : prdata <= {`DATA_WIDTH{1'b0}};
        endcase
      end
    end
  end
endmodule


// -----------------------------------------------------------
// Sub-module: rw_write_logic
// Description: Handles all write transactions from APB to the registers.
//              Also manages updates to TSR from external flags.
// -----------------------------------------------------------
module rw_write_logic #(
  parameter ADDR_WIDTH = 8
)(
  input  wire                   pclk,
  input  wire                   preset_n,
  input  wire                   pready,
  input  wire                   psel,
  input  wire                   penable,
  input  wire                   pwrite,
  input  wire [ADDR_WIDTH-1:0]  paddr,
  input  wire [`DATA_WIDTH-1:0] pwdata,
  input  wire                   TMR_OVF,
  input  wire                   TMR_UDF,
  output reg  [`DATA_WIDTH-1:0] TDR_reg,
  output reg  [`DATA_WIDTH-1:0] TCR_reg,
  output reg  [`DATA_WIDTH-1:0] TSR_reg
);

  wire write_en;
  assign write_en = psel & penable & pwrite & pready;

  // Logic to handle reserved bits before writing to registers
  wire [`DATA_WIDTH-1:0] wdata_tcr = {pwdata[7], 1'b0, pwdata[5:4], 2'b0, pwdata[1:0]};
  wire [`DATA_WIDTH-1:0] wdata_tsr = {6'b0, pwdata[1:0]};

  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      TDR_reg <= {`DATA_WIDTH{1'b0}};
      TCR_reg <= {`DATA_WIDTH{1'b0}};
      TSR_reg <= {`DATA_WIDTH{1'b0}};
    end else begin
      if (write_en) begin
        // This is a write cycle
        case (paddr)
          `TDR_ADDR  : TDR_reg <= pwdata;         // Write to TDR
          `TCR_ADDR  : TCR_reg <= wdata_tcr;      // Write to TCR
          `TSR_ADDR  : TSR_reg <= wdata_tsr;      // Write to TSR
          default    : begin end
        endcase
      end else begin
        // Update TSR with flags when not in a write cycle
        TSR_reg <= {6'b0, TMR_UDF, TMR_OVF};
      end
    end
  end
endmodule


// -----------------------------------------------------------
// Sub-module: sel_w_reg (Write Register Select)
// -----------------------------------------------------------
module sel_w_reg #(
  parameter ADDR_WIDTH = 8
)(
  input  wire [ADDR_WIDTH-1:0] paddr,
  output reg  [2:0]            w_reg
);
  always @(*) begin
    case (paddr)
      `TDR_ADDR  : w_reg = 3'b001;
      `TCR_ADDR  : w_reg = 3'b010;
      `TSR_ADDR  : w_reg = 3'b100;
      default    : w_reg = 3'b000;
    endcase
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
  output reg                    pready,
  output reg                    pslverr
);
  // FSM state encoding for APB protocol
  localparam IDLE   = 2'b00;
  localparam SETUP  = 2'b01;
  localparam ACCESS = 2'b10;
  reg [1:0]  cur_state, next_state;

  // FSM: State transition
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
      cur_state <= IDLE;
    else
      cur_state <= next_state;
  end

  // FSM: Next state logic
  always @(*) begin
    case (cur_state)
      IDLE:    next_state = (psel && !penable) ? SETUP : IDLE;
      SETUP:   next_state = (psel &&  penable) ? ACCESS : SETUP;
      ACCESS:  next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end

  // Output logic: pready and pslverr
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      pready  <= 1'b0;
      pslverr <= 1'b0;
    end else begin
      // Default values every cycle
      pready  <= 1'b0;
      pslverr <= 1'b0;
      if (cur_state == ACCESS) begin
        pready  <= 1'b1;
        // Check for invalid address
        if (pwrite) begin
          if (paddr != `TDR_ADDR && paddr != `TCR_ADDR && paddr != `TSR_ADDR)
            pslverr <= 1'b1;
        end else begin
          if (paddr != `TDR_ADDR && paddr != `TCR_ADDR && paddr != `TSR_ADDR && paddr != `TCNT_ADDR)
            pslverr <= 1'b1;
        end
      end
    end
  end
endmodule

`endif // RW_REG_CONTROL_V
