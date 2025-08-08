`include "reg_def.v"
// `DATA_WIDTH = 8

module rw_register #(
  parameter ADDR_WIDTH = 8
)(
  // SIGNAL FOR APB INTERFACE
  input  wire                   PCLK,
  input  wire                   PRESETn,
  input  wire                   PSEL,
  input  wire                   PENABLE,
  input  wire                   PWRITE,
  input  wire [ADDR_WIDTH-1:0]  PADDR,
  input  wire [`DATA_WIDTH-1:0] PWDATA,
  
  output reg  [`DATA_WIDTH-1:0] PRDATA,
  output reg                    PREADY,
  output reg                    PSLVERR
);
  reg  [`DATA_WIDTH-1:0] TDR;
  reg  [`DATA_WIDTH-1:0] TCR;
  reg  [`DATA_WIDTH-1:0] TSR;
  reg  [`DATA_WIDTH-1:0] TCNT;
  
  wire [2:0]             w_reg;
  wire [`DATA_WIDTH-1:0] wdata4reg
  
  // Register read/write + output logic
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      // Reset internal registers
      TDR     <= `TDR_RST;
      TCR     <= `TCR_RST;
      TSR     <= `TSR_RST;
      TCNT    <= `TCNT_RST;
    end else begin
      APB_trans #(ADDR_WIDTH) Reg_TDR (
        .pclk     (PCLK),
        .preset_n (PRESETn),
        .psel     (PSEL),
        .penable  (PENABLE),
        .pwrite   (PWRITE),
        .paddr    (PADDR),
        .pready   (PREADY),
        .pslverr  (PSLVERR)
      )

      //select register TDR, TCR and TSR
      sel_w_reg #(ADDR_WIDTH) sel_w_reg (
        .paddr (paddr),
        .w_reg (w_reg)
      );

      //initial register TDR, TCR and TSR
      WRITE_reg #(ADDR_WIDTH) Reg_TDR (
        .pclk      (PCLK),
        .preset_n  (PRESETn),
        .psel      (PSEL),
        .penable   (PENABLE),
        .pwrite    (PWRITE),  
        .pready    (PREADY),
        .reg4write (w_reg[0]), 
        .pwdata    (wdata4reg),   
        .out_pwdata(TDR) 
      );

      WRITE_reg #(ADDR_WIDTH) Reg_TCR (
        .pclk      (PCLK),
        .preset_n  (PRESETn),
        .psel      (PSEL),
        .penable   (PENABLE),
        .pwrite    (PWRITE),
        .pready    (PREADY),
        .reg4write (w_reg[1]), 
        .pwdata    (wdata4reg),   
        .out_pwdata(TCR)  
      );

      WRITE_reg #(ADDR_WIDTH) Reg_TSR (
        .pclk      (PCLK),
        .preset_n  (PRESETn),
        .psel      (PSEL),
        .penable   (PENABLE),
        .pwrite    (PWRITE),
        .pready    (PREADY),
        .reg4write (w_reg[2]), 
        .pwdata    (wdata4reg),   
        .out_pwdata(TSR) 
      );

      // Process reserved bits based on register selection
      assign #1 RBPWDATA = sel_reg[0] ? PWDATA :    // Register 0: all bits writable
        sel_reg[1] ? {PWDATA[7], 1'b0, PWDATA[5:4], 2'b00, PWDATA[1:0]} :  // Reserved bits fixed to 0
        sel_reg[2] ? {PWDATA[7:6], 2'b00, PWDATA[3:2], 2'b00} :            // Another example
        8'h00; // default

        //read data TDR, TCR and TSR
      READ_reg #(ADDR_WIDTH) Reg_TSR (
        .pclk     (PCLK),
        .preset_n (PRESETn),
        .psel     (PSEL),
        .penable  (PENABLE),
        .pwrite   (PWRITE),
        .pready   (PREADY),
        .paddr    (PADDR),
        .TDR      (TDR), 
        .TCR      (TCR), 
        .TSR      (TSR),
        .TCNT     (TCNT),
        .out_rdata(PRDATA)  
      );
    end
endmodule

// ----------------------------------------------------------- OK
module sel_w_reg #(
  parameter ADDR_WIDTH = 2
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

// ----------------------------------------------------------- OK
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
  
  wire write_en;
  assign write_en = pready & pwrite & reg4write;
  
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) 
      out_pwdata <= {`DATA_WIDTH{1'b0}};
    else begin
      out_pwdata <= (write_en) ? pwdata : out_pwdata;
    end
  end
endmodule

// ----------------------------------------------------------- OK
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
  
  wire read_en;
  assign read_en = pready & !pwrite;
  
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      out_rdata <= {`DATA_WIDTH{1'b0}};
    end else if (read_en) begin
      case (paddr)
        `TDR_ADDR  : out_rdata <= TDR;
        `TCR_ADDR  : out_rdata <= TCR;
        `TSR_ADDR  : out_rdata <= TSR;
        `TCNT_ADDR : out_rdata <= TCNT;
        default    : out_rdata <= {`DATA_WIDTH{1'b0}};
      endcase
    end else begin
      out_rdata <= out_rdata;
    end
  end
 
endmodule

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

  // Register read/write + output logic
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
