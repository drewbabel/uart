// Pins (basys3 host_loopback.xdc): clk=W5 (100 MHz), rst_btn=BTNC(U18),
//   rx_serial=RsRx(B18, PC->FPGA), tx_serial=RsTx(A18, FPGA->PC),
//   led[7:0]=received-byte mirror, led_err=latched framing error (led[15]).

module host_loopback_top #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int BAUD_RATE   = 115_200,
    parameter int OVERSAMPLE  = 16,
    parameter int DATA_BITS   = 8
) (
    input  logic                 clk,
    input  logic                 rst_btn,
    input  logic                 rx_serial,  // RsRx: serial in from the PC
    output logic                 tx_serial,  // RsTx: serial out to the PC
    output logic [DATA_BITS-1:0] led,        // Last received byte, for visual check
    output logic                 led_err     // Latched framing error
);

  // Power-on reset (with BTNC manual reset)
  logic [7:0] por_cnt = '0;
  logic       por;
  assign por = (por_cnt != 8'hFF);
  always_ff @(posedge clk) begin
    if (por) por_cnt <= por_cnt + 8'd1;
  end
  logic rst_n;
  assign rst_n = ~(por | rst_btn);

  logic [DATA_BITS-1:0] tx_data;
  logic                 tx_valid;
  logic                 tx_ready;
  logic [DATA_BITS-1:0] rx_data;
  logic                 rx_valid;
  logic                 rx_error;

  uart #(
      .CLK_FREQ_HZ(CLK_FREQ_HZ),
      .BAUD_RATE  (BAUD_RATE),
      .OVERSAMPLE (OVERSAMPLE),
      .DATA_BITS  (DATA_BITS)
  ) u_core (
      .clk      (clk),
      .rst_n    (rst_n),
      .tx_data  (tx_data),
      .tx_valid (tx_valid),
      .tx_ready (tx_ready),
      .tx_serial(tx_serial),
      .rx_serial(rx_serial),
      .rx_data  (rx_data),
      .rx_valid (rx_valid),
      .rx_error (rx_error)
  );

  // On received byte, latch it and raise tx_valid. Holds request until transmitter accepts
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      tx_data  <= '0;
      tx_valid <= 1'b0;
    end else if (rx_valid) begin
      tx_data  <= rx_data;
      tx_valid <= 1'b1;
    end else if (tx_valid && tx_ready) begin
      tx_valid <= 1'b0;
    end
  end

  // Visual confirmation while the host test runs
  logic [DATA_BITS-1:0] rx_latch;
  logic                 err_latch;
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      rx_latch  <= '0;
      err_latch <= 1'b0;
    end else begin
      if (rx_valid) rx_latch <= rx_data;
      if (rx_error) err_latch <= 1'b1;
    end
  end
  assign led     = rx_latch;
  assign led_err = err_latch;

endmodule
