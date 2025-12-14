module tb_top;

  logic clk = 0;
  logic resetn = 0;

  soc_top dut (
    .clk(clk),
    .resetn(resetn)
  );

  // 100 MHz clock
  always #5 clk = ~clk;

  initial begin
    // Reset for a few cycles
    repeat (5) @(posedge clk);
    resetn = 1;

    // Timeout safety
    repeat (200000) @(posedge clk);
    $display("TIMEOUT (no PASS/FAIL).");
    $finish;
  end

endmodule
