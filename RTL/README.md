## [NOTE]
<img width="698" height="453" alt="image" src="https://github.com/user-attachments/assets/356f88df-bc27-4c35-b9b9-35cfd1510fc3" />

### Phân biệt về việc dùng khai báo wire và reg
#### Trong logic tổ hợp (combinational logic):
- Chỉ dùng reg trong khối always @(*): Trong Verilog, nếu bạn gán giá trị cho một tín hiệu trong một khối always @(*) (hoặc always @(list) cho logic tổ hợp), tín hiệu đó phải được khai báo là reg. Lý do là do ngữ nghĩa của Verilog: các khối always là các khối thủ tục (procedural), và chỉ reg có thể được gán giá trị trong các khối này. Tuy nhiên, reg ở đây không nhất thiết biểu thị một thanh ghi vật lý (flip-flop), mà chỉ là một kiểu dữ liệu để Verilog xử lý trong khối tổ hợp.
- Ví dụ:
  ```verilog
  reg [2:0] w_reg_sel;
  always @(*) begin
    case (paddr)
      `TDR_ADDR : w_reg_sel = 3'b001;
      `TCR_ADDR : w_reg_sel = 3'b010;
      default   : w_reg_sel = 3'b000;
    endcase
  end
  ```
> Ở đây, w_reg_sel là reg nhưng không tạo ra thanh ghi, nó chỉ mô tả logic tổ hợp.
#### Trong logic tuần tự (sequential logic):
- Chủ yếu dùng reg: Trong các khối always @(posedge clk) (hoặc các khối nhạy với cạnh clock), tín hiệu được gán giá trị thường là reg, vì chúng thường đại diện cho các thanh ghi (flip-flops) lưu trữ trạng thái qua các chu kỳ clock.
- Ví dụ:
  ```verilog
  reg [7:0] TDR;
  always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
      TDR <= `TDR_RST;
    else if (write_en)
      TDR <= wdata_tdr;
  end
  ```
> Ở đây, TDR là reg và đại diện cho một thanh ghi vật lý.
- Không dùng wire trong khối always tuần tự: Bạn không thể gán giá trị cho wire trong khối always @(posedge clk), vì wire chỉ được dùng cho gán liên tục (assign) hoặc kết nối giữa các module. Nếu bạn cố gắng gán wire trong khối always, bạn sẽ gặp lỗi tương tự như lỗi (vlog-2110) Illegal reference to net.
- Tuy nhiên, wire vẫn có thể xuất hiện trong logic tuần tự: wire thường được dùng để kết nối tín hiệu đầu vào hoặc trung gian trong logic tuần tự. Ví dụ:
  ```verilog
  wire write_en;
  assign write_en = (pcurrstate == `ACCESS) & pwrite & |w_reg_sel;
  ```
#### Kết luận 
- Logic tổ hợp:
  + Dùng reg trong khối always @(*) để gán giá trị.
  + Dùng wire cho gán liên tục (assign) hoặc kết nối giữa các module.
  + Không gán wire trong khối always, vì sẽ gây lỗi như (vlog-2110).
- Logic tuần tự:
  + Dùng reg cho các tín hiệu được gán trong khối always @(posedge clk) để lưu trữ trạng thái (thanh ghi).
  + Dùng wire cho các tín hiệu trung gian hoặc đầu vào được tính toán liên tục ngoài khối always.
- SystemVerilog: Nếu bạn dùng SystemVerilog, kiểu logic thay thế cho reg và wire trong hầu hết các trường hợp, giúp giảm sự nhầm lẫn.
- Ví dụ:
  ```verilog
  module example (
    input wire clk, reset_n,
    input wire [7:0] addr,
    output reg [7:0] data_out
  );
    reg [2:0] select;  // Dùng reg cho logic tổ hợp
    wire enable;       // Dùng wire cho gán liên tục
    
    // Logic tổ hợp: phải dùng reg
    always @(*) begin
      case (addr)
        8'h00: select = 3'b001;
        8'h01: select = 3'b010;
        default: select = 3'b000;
      endcase
    end
    
    // Gán liên tục: phải dùng wire
    assign enable = (select != 3'b000);
    
    // Logic tuần tự: phải dùng reg
    always @(posedge clk or negedge reset_n) begin
      if (!reset_n)
        data_out <= 8'h00;
      else if (enable)
        data_out <= addr;
    end
  endmodule
  ```
