// UART RX harness
module tt_uart_rx (
    input  logic clk,
    input  logic rst_n,
    input  logic si,
    output logic so
);
  localparam int NOUT = 10;

  logic rx_serial_r;
  logic [NOUT-1:0] out_w, out_r;

  always_ff @(posedge clk) rx_serial_r <= si;

  uart_rx dut (
      .clk     (clk),
      .rst_n   (rst_n),
      .rx_serial(rx_serial_r),
      .rx_data (out_w[7:0]),
      .rx_valid(out_w[8]),
      .rx_error(out_w[9])
  );

  always_ff @(posedge clk) out_r <= out_w;
  always_ff @(posedge clk) so <= ^out_r;
endmodule
