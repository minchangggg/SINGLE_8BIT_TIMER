`include "reg.v"

module rw_register #(
  parameter ADDR_WIDTH = 2
)(
  input  wire                  pclk,
  input  wire                  preset_n,
  input  wire                  psel,
  input  wire                  penable,
  input  wire                  pwrite,
  input  wire [ADDR_WIDTH-1:0] paddr,
  input  wire [`CNT_WIDTH-1:0] pwdata,
  output reg  [`CNT_WIDTH-1:0] prdata,
  output reg                   pready,
  output reg                   pslverr
);

  // Internal registers mapped via APB
  reg [`CNT_WIDTH-1:0] TDR, TCR, TSR, TCNT;

  // FSM state encoding for APB protocol
  localparam IDLE   = 2'b00,
             SETUP  = 2'b01,
             ACCESS = 2'b10;

  reg [1:0] cur_state, next_state;

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
      ACCESS:  next_state = (!psel) ? IDLE :
                            (!penable) ? SETUP : ACCESS;
      default: next_state = IDLE;
    endcase
  end

  // Register read/write + output logic
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      // Reset internal registers
      TDR     <= TDR_RST;
      TCR     <= TCR_RST;
      TSR     <= TSR_RST;
      TCNT    <= TCNT_RST;

      // Reset APB interface signals
      prdata  <= 8'h00;
      pready  <= 1'b0;
      pslverr <= 1'b0;
    end else begin
      // Default values every cycle
      prdata  <= 8'h00;
      pready  <= 1'b0;
      pslverr <= 1'b0;

      if (cur_state == ACCESS) begin
        // Check for invalid address (>= 4 registers)
        if (paddr >= 4) begin
          pslverr <= 1'b1;  // Invalid address access
          pready  <= 1'b1;
        end else begin
          pready <= 1'b1; // Valid access

          if (pwrite) begin
            // Write operation
            case (paddr)
              2'b00: TDR <= pwdata;
              2'b01: TCR <= pwdata;
              2'b10: TSR <= pwdata;
              2'b11: pslverr <= 1'b1; // TCNT is read-only
            endcase
          end else begin
            // Read operation
            case (paddr)
              2'b00: prdata <= TDR;
              2'b01: prdata <= TCR;
              2'b10: prdata <= TSR;
              2'b11: prdata <= TCNT;
            endcase
          end
        end
      end
    end
  end

endmodule
