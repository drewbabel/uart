module debounce_counter_tb ();

  int   errors = 0;
  int   checks = 0;

  logic clk = 0;
  always #5 clk = ~clk;

  logic rst_n;
  logic btn_in;
  logic [15:0] led;

  logic [15:0] expected_led = 0;

  debounce_counter #(
      .DEBOUNCE_MAX(4)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .btn_in(btn_in),
      .led(led)
  );

  task automatic do_reset();
    #1 rst_n = 0;
    @(posedge clk);
    @(posedge clk);
    #1 rst_n = 1;
    @(posedge clk);
  endtask  // Automatic

  task automatic verdict();
    if (errors == 0) begin
      $display("PASS: %0d checks, %0d mismatches", checks, errors);
    end else begin
      $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    end
    $finish;
  endtask  // Automatic

  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, debounce_counter_tb);
    do_reset();

    // Led scale test
    repeat (15) begin
      #1 btn_in = 1;
      repeat (15) @(posedge clk);
      #1 expected_led = expected_led + 1;
      check_led();
      #1 btn_in = 0;
      repeat (15) @(posedge clk);
      check_led();
    end

    // Short chatter test
    repeat (20) begin
      #1 btn_in = 1;
      repeat ($urandom_range(1, 3)) @(posedge clk);
      check_led();
      #1 btn_in = 0;
      repeat ($urandom_range(1, 3)) @(posedge clk);
      check_led();
    end

    @(posedge clk);

    verdict();
  end

  task automatic check_led();
    checks++;
    if (led !== expected_led) begin
      errors++;
      $error("t=%0t mismatch: got=%0d  exp=%0d", $time, led, expected_led);
    end
  endtask  // Automatic

endmodule
