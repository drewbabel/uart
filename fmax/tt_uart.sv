// UART timing harness
module tt_uart (
    input  logic clk,
    input  logic rst_n,
    input  logic si,
    output logic so
);
  localparam int NIN = 10;
  localparam int NOUT = 12;

  logic [NIN-1:0] in_r;
  logic [NOUT-1:0] out_w, out_r;

  always_ff @(posedge clk) in_r <= {in_r[NIN-2:0], si};

  uart dut (
      .clk      (clk),
      .rst_n    (rst_n),
      .tx_data  (in_r[7:0]),
      .tx_valid (in_r[8]),
      .tx_ready (out_w[0]),
      .tx_serial(out_w[1]),
      .rx_serial(in_r[9]),
      .rx_data  (out_w[9:2]),
      .rx_valid (out_w[10]),
      .rx_error (out_w[11])
  );

  always_ff @(posedge clk) out_r <= out_w;
  always_ff @(posedge clk) so <= ^out_r;
endmodule
