`timescale 1ns / 1ps  // <unit>/<precision>

module seven_seg_cntrl_tb ();

  int checks = 0;
  int errors = 0;

  logic clk = 0;
  logic rst_n;
  logic [15:0] digits;
  logic [6:0] seg;
  logic [3:0] an;

  logic [3:0] an_old = 4'b0000;
  int n_low;

  always #5 clk = ~clk;
  assign n_low = $countones(~an);

  seven_seg_cntrl #(
      .CNT_WIDTH(3)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .digits(digits),
      .seg(seg),
      .an(an)
  );

  // Independent glyph reference (active-high, bit order g f e d c b a).
  function automatic logic [6:0] exp_glyph(input logic [3:0] v);
    case (v)
      4'h0: exp_glyph = 7'b011_1111;
      4'h1: exp_glyph = 7'b000_0110;
      4'h2: exp_glyph = 7'b101_1011;
      4'h3: exp_glyph = 7'b100_1111;
      4'h4: exp_glyph = 7'b110_0110;
      4'h5: exp_glyph = 7'b110_1101;
      4'h6: exp_glyph = 7'b111_1101;
      4'h7: exp_glyph = 7'b000_0111;
      4'h8: exp_glyph = 7'b111_1111;
      4'h9: exp_glyph = 7'b110_1111;
      4'hA: exp_glyph = 7'b111_0111;
      4'hB: exp_glyph = 7'b111_1100;
      4'hC: exp_glyph = 7'b011_1001;
      4'hD: exp_glyph = 7'b101_1110;
      4'hE: exp_glyph = 7'b111_1001;
      4'hF: exp_glyph = 7'b111_0001;
    endcase
  endfunction

  task automatic do_reset();
    rst_n = 1'b0;
    @(posedge clk);
    @(posedge clk);
    rst_n = 1'b1;
  endtask  // Automatic

  task automatic check_an(input logic [3:0] an, input logic [3:0] exp_an);
    checks++;
    if (an !== exp_an) begin
      errors++;
      $error("t=%0t an mismatch: got=%b, exp=%b", $time, an, exp_an);
    end
  endtask  // Automatic

  task automatic check_seg(input logic [6:0] seg, input logic [6:0] exp_seg);
    checks++;
    if (seg !== exp_seg) begin
      errors++;
      $error("t=%0t seg mismatch: got=%b, exp=%b", $time, seg, exp_seg);
    end
  endtask  // Automatic

  task automatic do_verdict();
    if (errors == 0) begin
      $display("PASS: %0d checks, %0d mismatches", checks, errors);
    end else begin
      $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    end
    $finish;
  endtask  // Automatic

  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, seven_seg_cntrl_tb);
    digits = 16'h0000;
    do_reset();

    // Decode sweep
    for (int v = 0; v < 16; v++) begin
      digits = {4{v[3:0]}};
      @(negedge clk);
      @(negedge clk);
      check_seg(seg, ~exp_glyph(v[3:0]));
    end

    do_verdict();
  end

  always @(negedge clk) begin
    if (!rst_n) begin
      // Reset blanks the display
      check_seg(seg, ~7'b000_0000);
    end else checks++;
    // Ensure an one-cold
    if (n_low !== 1) begin
      errors++;
      $error("t=%0t multiple-an mismatch: got=%b", $time, an);
    end

    // Ensure legal an transitions
    an_old <= an;
    if (an !== an_old) begin
      checks++;
      case (an_old)
        4'b1110: check_an(an, 4'b1101);
        4'b1101: check_an(an, 4'b1011);
        4'b1011: check_an(an, 4'b0111);
        4'b0111: check_an(an, 4'b1110);
        default: begin
          if (an_old !== 4'b0000)
            $error("t=%0t transitions mismatch: an=%b, an_old=%b", $time, an, an_old);
        end
      endcase
    end
  end

endmodule
