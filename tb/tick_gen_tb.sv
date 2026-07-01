module tick_gen_tb ();

  localparam int DIVISOR = 4;

  int   errors = 0;
  int   checks = 0;

  logic clk = 0;
  logic rst;
  logic tick;

  int   cnt;

  always #5 clk = ~clk;

  tick_gen #(
      .DIVISOR(DIVISOR)
  ) dut (
      .clk (clk),
      .rst (rst),
      .tick(tick)
  );

  task automatic do_reset();
    rst = 1;
    @(posedge clk);
    @(posedge clk);
    rst = 0;
  endtask  // Automatic


  task automatic do_verdict();
    if (errors == 0) begin
      $display("PASS: %0d checks, %0d mismatches", checks, errors);
    end else begin
      $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    end
    $finish;
  endtask  // Automatic

  task automatic check(input logic got, input logic exp);
    checks++;
    if (got !== exp) begin
      errors++;
      $error("t=%0t mismatch: got=%b, exp=%b", $time, got, exp);
    end
  endtask  // Automatic


  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tick_gen_tb);
    do_reset();

    repeat (100) begin
      @(posedge clk) cnt++;
    end

    do_verdict();
  end

  always @(negedge clk) begin
    if (~rst) check(tick, (cnt % DIVISOR == DIVISOR - 2));
  end
endmodule
