module seven_seg_cntrl #(
    parameter int CNT_WIDTH = 17
) (
    input logic clk,
    input logic rst_n,
    input logic [15:0] digits,  // 4 hex nibbles
    output logic [6:0] seg,
    output logic [3:0] an
);
  // Bit order: g f e d c b a
  localparam logic [6:0] SEG_0 = 7'b011_1111;
  localparam logic [6:0] SEG_1 = 7'b000_0110;
  localparam logic [6:0] SEG_2 = 7'b101_1011;
  localparam logic [6:0] SEG_3 = 7'b100_1111;
  localparam logic [6:0] SEG_4 = 7'b110_0110;
  localparam logic [6:0] SEG_5 = 7'b110_1101;
  localparam logic [6:0] SEG_6 = 7'b111_1101;
  localparam logic [6:0] SEG_7 = 7'b000_0111;
  localparam logic [6:0] SEG_8 = 7'b111_1111;
  localparam logic [6:0] SEG_9 = 7'b110_1111;
  localparam logic [6:0] SEG_A = 7'b111_0111;
  localparam logic [6:0] SEG_B = 7'b111_1100;
  localparam logic [6:0] SEG_C = 7'b011_1001;
  localparam logic [6:0] SEG_D = 7'b101_1110;
  localparam logic [6:0] SEG_E = 7'b111_1001;
  localparam logic [6:0] SEG_F = 7'b111_0001;
  localparam logic [6:0] SegReset = 7'b000_0000;

  logic [CNT_WIDTH-1:0] cnt;
  logic [3:0] dis_num;

  // Refresh counter (~1.52 kHz cnt from 100 MHz clk)
  always_ff @(posedge clk) begin
    if (!rst_n) cnt <= '0;
    else cnt <= cnt + 1'b1;
  end

  // Digit selector (anode)
  always_comb begin
    case (cnt[CNT_WIDTH-1-:2])
      0: an = 4'b1110;
      1: an = 4'b1101;
      2: an = 4'b1011;
      3: an = 4'b0111;
      default: an = 4'b1111;
    endcase
  end

  // Number selector
  always_comb begin
    case (cnt[CNT_WIDTH-1-:2])
      0: dis_num = digits[3:0];
      1: dis_num = digits[7:4];
      2: dis_num = digits[11:8];
      3: dis_num = digits[15:12];
      default: dis_num = 4'b1111;  // Error
    endcase
  end

  // Hex-to-7seg decoder (seg = active-low)
  always_comb begin
    if (!rst_n) seg = ~SegReset;
    else begin
      case (dis_num)
        4'h0: seg = ~SEG_0;
        4'h1: seg = ~SEG_1;
        4'h2: seg = ~SEG_2;
        4'h3: seg = ~SEG_3;
        4'h4: seg = ~SEG_4;
        4'h5: seg = ~SEG_5;
        4'h6: seg = ~SEG_6;
        4'h7: seg = ~SEG_7;
        4'h8: seg = ~SEG_8;
        4'h9: seg = ~SEG_9;
        4'hA: seg = ~SEG_A;
        4'hB: seg = ~SEG_B;
        4'hC: seg = ~SEG_C;
        4'hD: seg = ~SEG_D;
        4'hE: seg = ~SEG_E;
        4'hF: seg = ~SEG_F;
        default: seg = ~SEG_0;
      endcase
    end
  end

endmodule
