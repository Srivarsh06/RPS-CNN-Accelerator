`timescale 1ns/1ps
// Counts clock cycles while `run` is high; latency = count / f_clk.
module cycle_counter (
    input  logic        clk,
    input  logic        rst,
    input  logic        clear,
    input  logic        run,
    output logic [31:0] count
);
    always_ff @(posedge clk)
        if (rst | clear) count <= '0;
        else if (run)    count <= count + 1;
endmodule
