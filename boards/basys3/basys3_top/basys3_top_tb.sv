module basys3_top_tb ();

  localparam int DebMax = 4;

  int checks = 0;
  int errors = 0;

  logic clk = 0;
  logic rst_n;
  logic send_btn;
  logic [7:0] sw;
  logic [6:0] seg;
  logic [3:0] an;
  logic [15:0] led;

  always #5 clk = ~clk;

  basys3_top #(
      .DEBOUNCE_MAX(24'(DebMax))
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .send_btn(send_btn),
      .sw(sw),
      .seg(seg),
      .an(an),
      .led(led)
  );

  task automatic do_reset();
    rst_n = 1'b0;
    send_btn = 1'b0;
    sw = '0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
  endtask  // Automatic

  // Press once, wait for loopback frame, check received byte + no error
  task automatic send_and_check(input logic [7:0] b);
    sw = b;
    @(posedge clk);
    send_btn = 1'b1;
    repeat (DebMax + 8) @(posedge clk);  // Hold long enough to debounce + fire the pulse
    send_btn = 1'b0;
    repeat (12000) @(posedge clk);  // One 115200-baud frame is ~8680 clks

    checks++;
    if (led[7:0] !== b) begin
      errors++;
      $error("t=%0t rx mismatch: got=%h, exp=%h", $time, led[7:0], b);
    end
    checks++;
    if (led[15] !== 1'b0) begin
      errors++;
      $error("t=%0t unexpected framing error, led[15]=%b", $time, led[15]);
    end

    repeat (DebMax + 8) @(posedge clk);  // Let button settle low before next press
  endtask  // Automatic

  task automatic do_verdict();
    if (errors == 0) begin
      $display("PASS: %0d checks, %0d mismatches", checks, errors);
    end else begin
      $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    end
    $finish;
  endtask  // Automatic

  // Watchdog
  initial begin
    #2_000_000 $fatal(1, "TIMEOUT: sim exceeded max time");
  end

  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, basys3_top_tb);
    do_reset();

    send_and_check(8'hA5);
    send_and_check(8'h5A);
    send_and_check(8'hFF);
    send_and_check(8'h00);  // After a nonzero: proves the latch tracks each frame
    send_and_check(8'h3C);

    do_verdict();
  end

endmodule
