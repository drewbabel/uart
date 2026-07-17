// UART TX harness
module tt_uart_tx (
    input  logic clk,
    input  logic rst_n,
    input  logic si,
    output logic so
);
  localparam int NIN = 9;
  localparam int NOUT = 2;

  logic [NIN-1:0] in_r;
  logic [NOUT-1:0] out_w, out_r;

  always_ff @(posedge clk) in_r <= {in_r[NIN-2:0], si};

  uart_tx dut (
      .clk      (clk),
      .rst_n    (rst_n),
      .tx_data  (in_r[7:0]),
      .tx_valid (in_r[8]),
      .tx_ready (out_w[0]),
      .tx_serial(out_w[1])
  );

  always_ff @(posedge clk) out_r <= out_w;
  always_ff @(posedge clk) so <= ^out_r;
endmodule
