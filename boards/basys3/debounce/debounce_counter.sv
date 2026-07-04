module debounce_counter #(
    parameter logic [23:0] DEBOUNCE_MAX = 10_000_000
) (
    input logic clk,
    input logic rst_n,
    input logic btn_in,  // Direct button input
    output logic btn_press,  // 1-cycle pulse on a clean press
    output logic [15:0] led
);

  logic btn_s1;  // First FF
  logic btn_s2;  // Second FF
  logic btn_clean;  // Stable output
  logic [15:0] scale;
  logic [23:0] cnt;

  logic btn_clean_prev;

  // 2-FF synchronizer
  always_ff @(posedge clk) begin
    btn_s1 <= btn_in;
    btn_s2 <= btn_s1;
  end

  // Debouncer
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      cnt       <= '0;
      btn_clean <= 1'b0;
    end else if (btn_s2 != btn_clean) begin  // input differs -> time how long
      if (cnt == DEBOUNCE_MAX) begin
        cnt       <= '0;
        btn_clean <= btn_s2;
      end else cnt <= cnt + 1'b1;
    end else cnt <= '0;
  end

  // Edge detector
  always_ff @(posedge clk) btn_clean_prev <= btn_clean;
  assign btn_press = btn_clean & ~btn_clean_prev;

  // Press counter
  always_ff @(posedge clk) begin
    if (!rst_n) scale <= '0;
    else if (btn_press) scale <= scale + 1'b1;
  end

  assign led = scale;
endmodule
