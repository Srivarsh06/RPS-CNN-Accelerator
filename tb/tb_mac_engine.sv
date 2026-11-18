`timescale 1ns/1ps
// Self-checking testbench: 4 lanes compute a 9-tap dot product (one 3x3 window)
// and are compared against a behavioral reference.
module tb_mac_engine;
    logic clk = 0, rst = 1, clr = 0, en = 0;
    logic signed [7:0]  a;
    logic signed [7:0]  w   [4];
    logic signed [31:0] acc [4];
    int ref_acc [4];
    int errors = 0;

    mac_engine #(.LANES(4)) dut (.*);
    always #5 clk = ~clk;

    initial begin
        repeat (3) @(posedge clk); #1 rst = 0;
        for (int trial = 0; trial < 50; trial++) begin
            for (int k = 0; k < 9; k++) begin
                a = $urandom_range(0, 255) - 128;            // signed INT8
                for (int l = 0; l < 4; l++) w[l] = $urandom_range(0, 255) - 128;
                clr = (k == 0); en = 1;
                for (int l = 0; l < 4; l++)
                    ref_acc[l] = (k == 0) ? a * w[l] : ref_acc[l] + a * w[l];
                @(posedge clk); #1;
            end
            en = 0; clr = 0; @(posedge clk); #1;
            for (int l = 0; l < 4; l++)
                if (acc[l] !== ref_acc[l]) begin
                    errors++;
                    $display("MISMATCH trial %0d lane %0d: got %0d exp %0d", trial, l, acc[l], ref_acc[l]);
                end
        end
        if (errors == 0) $display("PASS: mac_engine matched reference on 50 trials x 4 lanes");
        else             $display("FAIL: %0d mismatches", errors);
        $finish;
    end
endmodule
