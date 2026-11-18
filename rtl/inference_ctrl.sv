`timescale 1ns/1ps
// TODO (Week 4): FSM sequencing CONV1 -> POOL1 -> CONV2 -> POOL2 -> FC -> ARGMAX.
// Stub so the project compiles; fills in as layers come online.
module inference_ctrl (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    output logic       busy,
    output logic       done,
    output logic [1:0] pred   // 0 rock, 1 paper, 2 scissors, 3 none
);
    typedef enum logic [2:0] {IDLE, CONV1, POOL1, CONV2, POOL2, FC, DONE} state_t;
    state_t state;
    assign busy = (state != IDLE) && (state != DONE);
    assign done = (state == DONE);
    assign pred = 2'd3;

    always_ff @(posedge clk) begin
        if (rst) state <= IDLE;
        else case (state)
            IDLE:  if (start) state <= CONV1;
            CONV1: state <= POOL1;   // placeholders: one cycle per layer
            POOL1: state <= CONV2;
            CONV2: state <= POOL2;
            POOL2: state <= FC;
            FC:    state <= DONE;
            DONE:  state <= IDLE;
            default: state <= IDLE;
        endcase
    end
endmodule
