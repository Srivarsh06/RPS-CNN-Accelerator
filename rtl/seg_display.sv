`timescale 1ns/1ps
// Multiplexed 4-digit 7-segment driver for the Urbana HEX displays.
// seg[i] is the active-high pattern {dp, g, f, e, d, c, b, a} for digit i (0 = leftmost);
// the board's segment and grid lines are active-low. Blank while rst.
module seg_display (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] seg [4],
    output logic [7:0] hex_seg,
    output logic [3:0] hex_grid
);
    logic [16:0] counter;   // digit changes every 2^15 cycles (~0.33 ms at 100 MHz)
    always_ff @(posedge clk)
        if (rst) counter <= '0;
        else     counter <= counter + 1;

    always_comb begin
        if (rst) begin
            hex_seg  = '1;
            hex_grid = '1;
        end else begin
            hex_seg  = ~seg[counter[16:15]];
            hex_grid = ~(4'b0001 << counter[16:15]);
        end
    end
endmodule
