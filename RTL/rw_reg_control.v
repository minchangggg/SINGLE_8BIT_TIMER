`ifndef RW_REG_CONTROL_V
`define RW_REG_CONTROL_V

`include "reg_def.v"
// `DATA_WIDTH = 8

// -----------------------------------------------------------------------------
// Module: rw_reg_control
// Description:
//   - This module implements a read/write register block that interfaces with
//   the APB (Advanced Peripheral Bus) protocol. It handles address decoding,
//   data transfers, and manages four internal Special Function Registers (SFRs).
//
// Parameters:
//   - ADDR_WIDTH : Width of the APB address bus.
//
// Inputs:
//   - pclk      : APB system clock.
//   - presetn   : Active-low asynchronous reset.
//   - psel      : APB peripheral select signal.
//   - penable   : APB enable signal, high during the ACCESS phase.
//   - pwrite    : APB write enable (1 for write, 0 for read).
//   - paddr     : APB address bus.
//   - pwdata    : APB write data bus.
//
// Outputs:
//   - prdata    : APB read data bus.
//   - pready    : APB ready signal, high when a transfer is complete.
//   - pslverr   : APB slave error signal, high for an invalid address.
//
// Internal SFRs: TDR, TCR, TSR, TCNT
// -----------------------------------------------------------------------------

module rw_reg_control #(
  parameter ADDR_WIDTH = 8
)(
  // SIGNAL FOR APB INTERFACE
  input  wire                    PCLK,
  input  wire                    PRESETn,
  input  wire                    PSEL,
  input  wire                    PENABLE,
  input  wire                    PWRITE,
  input  wire [ADDR_WIDTH-1:0]   PADDR,
  input  wire [`DATA_WIDTH-1:0]  PWDATA,
  
  output wire  [`DATA_WIDTH-1:0] PRDATA,
  output wire                    PREADY,
  output wire                    PSLVERR
);
  
  // ------------------------------------------------------------------
  // Internal SFR storage
  // ------------------------------------------------------------------
  reg  [`DATA_WIDTH-1:0] TDR;
  reg  [`DATA_WIDTH-1:0] TCR;
  reg  [`DATA_WIDTH-1:0] TSR;
  reg  [`DATA_WIDTH-1:0] TCNT;
  
  // ------------------------------------------------------------------
  // Wires to connect sub-modules
  // ------------------------------------------------------------------
  // One-hot selection for write (derived from PADDR)
  wire [2:0] w_reg; // [0]=TDR, [1]=TCR, [2]=TSR
  // Wires to hold write data after reserved bits are handled
  wire [`DATA_WIDTH-1:0] wdata_tdr;
  wire [`DATA_WIDTH-1:0] wdata_tcr;
  wire [`DATA_WIDTH-1:0] wdata_tsr;
  // Wires for APB_trans outputs
  wire apb_pready;
  wire apb_pslverr;
  
  // Instantiate the APB FSM module
  APB_trans #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_apb_trans (
    .pclk     (PCLK),
    .preset_n (PRESETn),
    .psel     (PSEL),
    .penable  (PENABLE),
    .pwrite   (PWRITE),
    .paddr    (PADDR),
    .pready   (apb_pready),
    .pslverr  (apb_pslverr)
  );
  
  // Drive the main outputs with the signals from the APB FSM
  assign PREADY  = apb_pready;
  assign PSLVERR = apb_pslverr;

  // Instantiate the register select logic TDR, TCR and TSR
  sel_w_reg #(
    .ADDR_WIDTH(ADDR_WIDTH)           
  ) u_sel_w_reg (
    .paddr (PADDR),
    .w_reg (w_reg)
  );

  // Logic to handle reserved bits before writing to registers
  // Note: No conditional logic here, the WRITE_reg module handle the write enable
  // Reserved bits fixed to 0
//   assign wdata_tdr = PWDATA;
//   assign wdata_tcr = {PWDATA[7], 1'b0, PWDATA[5:4], 2'b00, PWDATA[1:0]};
//   assign wdata_tsr = {6'b00, PWDATA[1:0]};
  assign wdata_tdr = (w_reg[0]) ? PWDATA : TDR;
  assign wdata_tcr = (w_reg[1]) ? {PWDATA[7], 1'b0, PWDATA[5:4], 2'b00, PWDATA[1:0]} : TCR;
  assign wdata_tsr = (w_reg[2]) ? {6'b00, PWDATA[1:0]}: TSR;

  // Instantiate the write modules for TDR, TCR, TSR
  WRITE_reg #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_write_tdr (
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .psel      (PSEL),
    .penable   (PENABLE),
    .pwrite    (PWRITE),  
    .pready    (apb_pready),
    .reg4write (w_reg[0]), 
    .pwdata    (wdata_tdr),   
    .out_pwdata(TDR) 
  );

  WRITE_reg #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_write_tcr (
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .psel      (PSEL),
    .penable   (PENABLE),
    .pwrite    (PWRITE),
    .pready    (apb_pready),
    .reg4write (w_reg[1]), 
    .pwdata    (wdata_tcr),   
    .out_pwdata(TCR)  
  );

  WRITE_reg #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_write_tsr (
    .pclk      (PCLK),
    .preset_n  (PRESETn),
    .psel      (PSEL),
    .penable   (PENABLE),
    .pwrite    (PWRITE),
    .pready    (apb_pready),
    .reg4write (w_reg[2]), 
    .pwdata    (wdata_tsr),   
    .out_pwdata(TSR) 
  );

  // Instantiate the read module
  // Read data TDR, TCR, TSR and TCNT
  READ_reg #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_read_reg (
    .pclk     (PCLK),
    .preset_n (PRESETn),
    .psel     (PSEL),
    .penable  (PENABLE),
    .pwrite   (PWRITE),
    .pready   (apb_pready),
    .paddr    (PADDR),
    .TDR      (TDR), 
    .TCR      (TCR), 
    .TSR      (TSR),
    .TCNT     (TCNT),
    .out_prdata(PRDATA)  
  );
  
  // ------------------------------------------------------------------
  // reset and hold value logic for internal register
  // ------------------------------------------------------------------
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      // Reset internal registers
      TDR  <= `TDR_RST;
      TCR  <= `TCR_RST;
      TSR  <= `TSR_RST;
      TCNT <= `TCNT_RST;
    end else begin
      TDR  <= TDR;
      TCR  <= TCR;
      TSR  <= TSR;
      TCNT <= TCNT;
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
      `TDR_ADDR  : w_reg <= 3'b001;
      `TCR_ADDR  : w_reg <= 3'b010;
      `TSR_ADDR  : w_reg <= 3'b100;
      default    : w_reg <= 3'b000;
    endcase
  end
endmodule

// -----------------------------------------------------------
// Sub-module: write_reg (Write Register)
// -----------------------------------------------------------
module WRITE_reg #(
  parameter ADDR_WIDTH = 8
)(
  input  wire                   pclk,
  input  wire                   preset_n,
  input  wire                   psel,
  input  wire                   penable,
  input  wire                   pwrite,
  input  wire                   reg4write,
  input  wire                   pready,
  input  wire [`DATA_WIDTH-1:0] pwdata,
  output reg  [`DATA_WIDTH-1:0] out_pwdata
);
  // Simplified the write enable logic
  wire write_en;
  assign write_en = (psel & penable & pwrite & pready) & reg4write;
  
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) 
      out_pwdata <= {`DATA_WIDTH{1'b0}};
    else begin
      out_pwdata <= (write_en) ? pwdata : out_pwdata;
    end
  end
endmodule

// -----------------------------------------------------------
// Sub-module: read_reg (Read Register)
// -----------------------------------------------------------
module READ_reg #(
  parameter ADDR_WIDTH = 8
)(
  input  wire                   pclk,
  input  wire                   preset_n,
  input  wire                   psel,
  input  wire                   penable,
  input  wire                   pwrite,
  input  wire [ADDR_WIDTH-1:0]  paddr,
  input  wire                   pready,
  input  wire [`DATA_WIDTH-1:0] TDR, 
  input  wire [`DATA_WIDTH-1:0] TCR, 
  input  wire [`DATA_WIDTH-1:0] TSR,
  input  wire [`DATA_WIDTH-1:0] TCNT,
  output reg  [`DATA_WIDTH-1:0] out_prdata
);
  // Simplified the read enable logic
  wire read_en;
  assign read_en = psel & penable & pready & !pwrite;
  
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) 
      out_prdata <= {`DATA_WIDTH{1'b0}};
    else begin
      if (read_en) begin
        case (paddr)
          `TDR_ADDR  : out_prdata <= TDR;
          `TCR_ADDR  : out_prdata <= TCR;
          `TSR_ADDR  : out_prdata <= TSR;
          `TCNT_ADDR : out_prdata <= TCNT;
          default    : out_prdata <= {`DATA_WIDTH{1'b0}};
        endcase
      end else 
        out_prdata <= out_prdata;
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
  output reg                    pready,
  output reg                    pslverr
);
  // FSM state encoding for APB protocol
  localparam IDLE   = 2'b00,
             SETUP  = 2'b01,
             ACCESS = 2'b10;
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
      IDLE:    next_state = (psel && !penable) ? SETUP  : IDLE;
      SETUP:   next_state = (psel &&  penable) ? ACCESS : SETUP;
      ACCESS:  next_state = IDLE;
        	   // next_state = (!psel) ? IDLE : (!penable) ? SETUP : ACCESS;
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

`endif
