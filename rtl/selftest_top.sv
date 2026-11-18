`timescale 1ns/1ps
// On-board self-test for the MAC engine (Urbana board).
// Releasing the reset button (J2) streams 50 precomputed 3x3 dot products through
// mac_engine and checks every lane against Python's answers (python/gen_selftest.py).
//   HEX A: "----" while running, then "PASS" or "FAIL"
//   HEX B: clock cycles the whole test took (hex, 100 MHz)
// INJECT_FAULT flips one input bit so simulation can show the test really catches errors.
module selftest_top #(parameter bit INJECT_FAULT = 0) (
    input  logic       Clk,
    input  logic       reset_rtl_0,
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB
);
    localparam int TRIALS = 50, TAPS = 9, LANES = 4;

    // Button -> synchronized active-high reset
    logic [1:0] rst_sync;
    logic       rst;
    always_ff @(posedge Clk) rst_sync <= {rst_sync[0], reset_rtl_0};
    assign rst = rst_sync[1];

    // {a, w0, w1, w2, w3} per tap; {acc0, acc1, acc2, acc3} per trial
    logic [39:0]  vec_rom [TRIALS*TAPS];
    logic [127:0] exp_rom [TRIALS];
    initial begin
        $readmemh("selftest_vec.mem", vec_rom);
        $readmemh("selftest_exp.mem", exp_rom);
    end

    typedef enum logic [1:0] {ISSUE, DRAIN, CHECK, DONE} state_t;
    state_t     state;
    logic [8:0] addr;     // tap index into vec_rom
    logic [3:0] k;        // tap within the current trial
    logic [5:0] t;        // trial
    logic [7:0] errors;   // mismatching lanes so far
    logic       done, pass;

    // Engine inputs are registered (ROM -> reg -> MAC), so the MAC path stays reg-to-reg.
    logic               clr, en;
    logic signed [7:0]  a;
    logic signed [7:0]  w   [LANES];
    logic signed [31:0] acc [LANES];

    mac_engine #(.LANES(LANES)) u_mac (.clk(Clk), .rst, .clr, .en, .a, .w, .acc);

    logic [2:0] mismatches;
    always_comb begin
        mismatches = '0;
        for (int l = 0; l < LANES; l++)
            mismatches += 3'(acc[l] != $signed(exp_rom[t][127-32*l -: 32]));
    end

    // Timing per trial: ISSUE x9 (tap k reaches the engine one cycle later),
    // DRAIN (last tap accumulates), CHECK (acc is final) -> 11 cycles.
    always_ff @(posedge Clk) begin
        if (rst) begin
            state <= ISSUE; addr <= '0; k <= '0; t <= '0; errors <= '0;
            clr <= 1'b0; en <= 1'b0;
        end else begin
            clr <= 1'b0; en <= 1'b0;
            case (state)
                ISSUE: begin
                    a <= vec_rom[addr][39:32] ^ ((INJECT_FAULT && addr == 13) ? 8'h01 : 8'h00);
                    for (int l = 0; l < LANES; l++) w[l] <= vec_rom[addr][31-8*l -: 8];
                    clr  <= (k == 0);
                    en   <= 1'b1;
                    addr <= addr + 1;
                    if (k == TAPS-1) begin k <= '0; state <= DRAIN; end
                    else k <= k + 1;
                end
                DRAIN: state <= CHECK;
                CHECK: begin
                    errors <= errors + mismatches;
                    if (t == TRIALS-1) state <= DONE;
                    else begin t <= t + 1; state <= ISSUE; end
                end
                DONE: ;
            endcase
        end
    end

    assign done = (state == DONE);
    assign pass = done && (errors == 0);

    logic [31:0] cycles;
    cycle_counter u_cyc (.clk(Clk), .rst, .clear(1'b0), .run(!done), .count(cycles));

    // Displays (digit 0 = leftmost). Segment bits: {dp, g, f, e, d, c, b, a}.
    localparam logic [7:0] SEG_P = 8'h73, SEG_A = 8'h77, SEG_S = 8'h6D, SEG_F = 8'h71,
                           SEG_I = 8'h06, SEG_L = 8'h38, SEG_DASH = 8'h40;
    logic [7:0] digA [4];
    logic [7:0] digB [4];
    always_comb begin
        if (!done)     digA = '{SEG_DASH, SEG_DASH, SEG_DASH, SEG_DASH};
        else if (pass) digA = '{SEG_P, SEG_A, SEG_S, SEG_S};
        else           digA = '{SEG_F, SEG_A, SEG_I, SEG_L};
        for (int i = 0; i < 4; i++) digB[i] = hex_to_seg(cycles[15-4*i -: 4]);
    end

    seg_display u_hexA (.clk(Clk), .rst, .seg(digA), .hex_seg(hex_segA), .hex_grid(hex_gridA));
    seg_display u_hexB (.clk(Clk), .rst, .seg(digB), .hex_seg(hex_segB), .hex_grid(hex_gridB));

    function automatic logic [7:0] hex_to_seg(input logic [3:0] n);
        case (n)
            4'h0: return 8'h3F;  4'h1: return 8'h06;  4'h2: return 8'h5B;  4'h3: return 8'h4F;
            4'h4: return 8'h66;  4'h5: return 8'h6D;  4'h6: return 8'h7D;  4'h7: return 8'h07;
            4'h8: return 8'h7F;  4'h9: return 8'h6F;  4'hA: return 8'h77;  4'hB: return 8'h7C;
            4'hC: return 8'h39;  4'hD: return 8'h5E;  4'hE: return 8'h79;  default: return 8'h71;
        endcase
    endfunction
endmodule
