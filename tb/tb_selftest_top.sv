`timescale 1ns/1ps
// Runs the on-board self-test twice: as built (must PASS) and with a deliberately
// flipped input bit (must FAIL), proving the checker actually catches errors.
module tb_selftest_top;
    logic Clk = 0, reset = 1;
    always #5 Clk = ~Clk;

    logic [7:0] segA_good, segB_good, segA_bad, segB_bad;
    logic [3:0] gridA_good, gridB_good, gridA_bad, gridB_bad;

    selftest_top #(.INJECT_FAULT(0)) good (.Clk, .reset_rtl_0(reset),
        .hex_segA(segA_good), .hex_gridA(gridA_good), .hex_segB(segB_good), .hex_gridB(gridB_good));
    selftest_top #(.INJECT_FAULT(1)) bad  (.Clk, .reset_rtl_0(reset),
        .hex_segA(segA_bad),  .hex_gridA(gridA_bad),  .hex_segB(segB_bad),  .hex_gridB(gridB_bad));

    initial begin
        repeat (5) @(posedge Clk); #1 reset = 0;
        fork
            wait (good.done && bad.done);
            begin repeat (2000) @(posedge Clk); $display("TIMEOUT: self-test never finished"); $finish; end
        join_any
        @(posedge Clk); #1;
        $display("as built:       %s, %0d lane errors, %0d cycles", good.pass ? "PASS" : "FAIL", good.errors, good.cycles);
        $display("fault injected: %s, %0d lane errors, %0d cycles", bad.pass  ? "PASS" : "FAIL", bad.errors,  bad.cycles);
        if (good.pass && !bad.pass && good.digA[0] == 8'h73 && bad.digA[0] == 8'h71)
            $display("PASS: self-test passes on correct hardware and catches the injected fault");
        else
            $display("FAIL: self-test did not behave as expected");
        $finish;
    end
endmodule
