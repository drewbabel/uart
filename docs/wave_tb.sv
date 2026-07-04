`timescale 1ns / 1ps
// Throwaway loopback testbench that generates wave.csv for the README waveform figure
// Baud is scaled to 32 clocks per bit so one whole frame fits in a readable image
//
// Regenerate the CSV from the repo root:
//   iverilog -g2012 -s wave_tb -o wave.vvp rtl/*.sv docs/wave_tb.sv && vvp wave.vvp
// then render the PNG with docs/loopback_waveform.py
module wave_tb;
  logic clk = 0, rst_n = 0;
  logic [7:0] tx_data;
  logic tx_valid, tx_ready, serial, rx_valid, rx_error;
  logic [7:0] rx_data;

  uart #(
      .CLK_FREQ_HZ(320_000),
      .BAUD_RATE  (10_000),
      .OVERSAMPLE (16),
      .DATA_BITS  (8)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .tx_data(tx_data),
      .tx_valid(tx_valid),
      .tx_ready(tx_ready),
      .tx_serial(serial),
      .rx_serial(serial),  // External loopback
      .rx_data(rx_data),
      .rx_valid(rx_valid),
      .rx_error(rx_error)
  );

  always #5 clk = ~clk;  // 10 ns period

  integer f;
  initial begin
    f = $fopen("wave.csv", "w");
    $fwrite(f, "t,tx_valid,tx_ready,tx_serial,rx_valid,rx_data,rx_error\n");
    tx_data  = 8'hA5;
    tx_valid = 1'b0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    wait (tx_ready);
    @(posedge clk);
    #1 tx_valid = 1'b1;
    @(posedge clk);
    #1 tx_valid = 1'b0;
  end

  // Sample every clock into the CSV
  always @(posedge clk)
    $fwrite(
        f,
        "%0t,%b,%b,%b,%b,%0d,%b\n",
        $time,
        tx_valid,
        tx_ready,
        serial,
        rx_valid,
        rx_data,
        rx_error
    );

  // Stop a little after the received-byte strobe
  initial begin
    @(posedge rx_valid);
    repeat (20) @(posedge clk);
    $fclose(f);
    $finish;
  end

  // Safety timeout
  initial begin
    #200000;
    $fclose(f);
    $display("TIMEOUT: rx_valid never fired");
    $finish;
  end
endmodule
