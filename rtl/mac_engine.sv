`timescale 1ns/1ps
// Four parallel INT8 MAC lanes (one per output channel / filter).
// All lanes share the activation `a`; each lane has its own weight.
module mac_engine #(parameter int LANES = 4) (
    input  logic                       clk,
    input  logic                       rst,
    input  logic                       clr,
    input  logic                       en,
    input  logic signed [7:0]          a,
    input  logic signed [7:0]          w   [LANES],
    output logic signed [31:0]         acc [LANES]
);
    genvar i;
    generate
        for (i = 0; i < LANES; i++) begin : g_lane
            mac_lane u_lane (.clk, .rst, .clr, .en, .a, .w(w[i]), .acc(acc[i]));
        end
    endgenerate
endmodule
