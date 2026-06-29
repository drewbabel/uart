module tick_gen #(
    parameter int DIVISOR = 4
) (
    input  logic clk,
    input  logic rst,
    output logic tick
);

  logic [$clog2(DIVISOR-1):0] cnt;

  always_ff @(posedge clk) begin
    if (rst) cnt <= 0;
    else cnt <= (cnt == $bits(cnt)'(DIVISOR - 1)) ? 0 : cnt + 1;
  end

  assign tick = (cnt == $bits(cnt)'(DIVISOR - 1));

endmodule
