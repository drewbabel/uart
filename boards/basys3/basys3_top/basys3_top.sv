// Basys 3 demo harness for the UART transceiver.
// Controls:
//   sw[7:0]  - the byte to send (shown in hex on the two left displays)
//   BTNU (top button)     - press once to send that byte (debounced -> one press, one byte)
//   BTNC (middle button)  - reset
// Display:
//   right two 7-seg digits - the received byte in hex (matches the left = loopback works)
//   led[7:0]               - received byte mirror
//   led[15]                - framing error latched

module basys3_top #(
    parameter logic [23:0] DEBOUNCE_MAX = 10_000_000  // board default; TB shrinks it
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        send_btn,
    input  logic [ 7:0] sw,
    output logic [ 6:0] seg,
    output logic [ 3:0] an,
    output logic [15:0] led
);

  logic       serial;
  logic       send_pulse;

  logic [7:0] rx_byte;
  logic       rx_valid;
  logic       rx_error;

  logic [7:0] rx_latch;  // Holds last received byte for display
  logic       err_latch;

  debounce_counter #(
      .DEBOUNCE_MAX(DEBOUNCE_MAX)
  ) u_send (
      .clk      (clk),
      .rst_n    (rst_n),
      .btn_in   (send_btn),
      .btn_press(send_pulse),
      .led      ()
  );

  uart u_core (
      .clk      (clk),
      .rst_n    (rst_n),
      .tx_data  (sw),
      .tx_valid (send_pulse),
      .tx_ready (),
      .tx_serial(serial),
      .rx_serial(serial),
      .rx_data  (rx_byte),
      .rx_valid (rx_valid),
      .rx_error (rx_error)
  );

  // Latch the received byte / error so the display holds between frames
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      rx_latch  <= '0;
      err_latch <= 1'b0;
    end else begin
      if (rx_valid) rx_latch <= rx_byte;
      if (rx_error) err_latch <= 1'b1;
    end
  end

  seven_seg_cntrl u_disp (
      .clk   (clk),
      .rst_n (rst_n),
      .digits({sw, rx_latch}),
      .seg   (seg),
      .an    (an)
  );

  assign led[7:0]  = rx_latch;
  assign led[14:8] = '0;
  assign led[15]   = err_latch;

endmodule
