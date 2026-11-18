`timescale 1ns/1ps
// One signed INT8 multiply-accumulate lane.
// acc <= acc + a*w each cycle when en; clr loads 0 first (start of a new dot product).
module mac_lane (
    input  logic               clk,
    input  logic               rst,
    input  logic               clr,   // start new accumulation (acc <= a*w)
    input  logic               en,    // accumulate this cycle
    input  logic signed [7:0]  a,     // activation
    input  logic signed [7:0]  w,     // weight
    output logic signed [31:0] acc
);
    logic signed [15:0] prod;
    assign prod = a * w;

    always_ff @(posedge clk) begin
        if (rst)      acc <= '0;
        else if (clr) acc <= 32'(prod);
        else if (en)  acc <= acc + 32'(prod);
    end
endmodule
