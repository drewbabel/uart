module host_loopback_top_tb ();

  int checks = 0;
  int errors = 0;

  localparam int ClkFreqHz = 100_000_000;
  localparam int BaudRate = 115_200;
  localparam int Oversample = 16;
  localparam int DataBits = 8;

  localparam int ClksPerBit = (ClkFreqHz + BaudRate / 2) / BaudRate;

  logic clk = 0;
  logic rst_btn;
  logic rx_serial;
  logic tx_serial;
  logic [DataBits-1:0] led;
  logic led_err;

  logic [DataBits+1:0] byte_q[$];

  always #5 clk = ~clk;

  host_loopback_top #(
      .CLK_FREQ_HZ(ClkFreqHz),
      .BAUD_RATE  (BaudRate),
      .OVERSAMPLE (Oversample),
      .DATA_BITS  (DataBits)
  ) dut (
      .clk(clk),
      .rst_btn(rst_btn),
      .rx_serial(rx_serial),
      .tx_serial(tx_serial),
      .led(led),
      .led_err(led_err)
  );

  task automatic do_reset();
    rst_btn = 1'b1;
    repeat (5) @(posedge clk);
    rst_btn   = 1'b0;
    rx_serial = 1'b1;  // Idle state
  endtask  // Automatic

  task automatic do_verdict();
    @(posedge clk);
    while (byte_q.size() != 0) @(posedge clk);
    if (errors == 0) begin
      $display("PASS: %0d checks, %0d mismatches", checks, errors);
    end else begin
      $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    end
    $finish;
  endtask  // Automatic

  task automatic check_por();
    int i = 0;

    @(posedge clk);
    checks++;
    if (dut.rst_n !== 1'b0) begin
      $error("t=%0t  POR: rst not asserted at power-on", $time);
      errors++;
    end

    while (dut.rst_n !== 1'b1 && i < 300) begin
      @(posedge clk);
      i++;
    end

    checks++;
    if (dut.rst_n !== 1'b1) begin
      $error("t=%0t  POR: rst not deasserted after %0d cycles", $time, i);
      errors++;
    end
  endtask  // Automatic

  task automatic serial_send(input logic [DataBits-1:0] data);
    logic [DataBits+1:0] framed_data;
    wait (!dut.por && rx_serial);
    framed_data = {1'b1, data, 1'b0};
    byte_q.push_back(framed_data);

    for (int i = 0; i < (DataBits + 2); i++) begin
      rx_serial = framed_data[i];
      repeat (ClksPerBit) @(posedge clk);
    end
  endtask  // Automatic

  task automatic serial_recieve();
    logic [DataBits+1:0] exp;
    logic [DataBits+1:0] got;
    wait (dut.rst_n && !tx_serial);
    repeat (ClksPerBit / 2) @(posedge clk);

    for (int i = 0; i < (DataBits + 2); i++) begin
      got[i] = tx_serial;
      repeat (ClksPerBit) @(posedge clk);
    end

    checks++;
    if (byte_q.size() == 0) begin
      errors++;
      $error("t=%0t byte_q is empty", $time);
    end else begin
      exp = byte_q.pop_front();
      if (got !== exp) begin
        errors++;
        $error("t=%0t data mismatch: got=%b, exp=%b", $time, got, exp);
      end
    end
  endtask  // Automatic

  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, host_loopback_top_tb);
    rst_btn = 1'b0;
    check_por();
    do_reset();

    fork
      serial_send(8'hA5);
      serial_recieve();
    join

    fork
      serial_send(8'h00);
      serial_recieve();
    join

    do_verdict();
  end

endmodule
