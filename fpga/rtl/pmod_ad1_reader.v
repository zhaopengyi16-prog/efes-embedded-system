// Single-channel reader for the Digilent Pmod AD1 (one AD7476A, output D0).
//
// AD7476A frame: CS falling starts the conversion. DOUT then presents
// 4 leading zeros followed by 12 data bits, MSB first; each SCLK falling edge
// moves DOUT to the next bit. This master keeps SCLK idle high and captures
// SDATA on the same clock edge on which it drives SCLK low, so it reads the
// bit that was valid during the preceding high phase (bits 15 .. 0).
//
// Default timing at a 50 MHz system clock:
//   SCLK = 50 MHz / (2 * SCLK_HALF_CYCLES) = 12.5 MHz (AD7476A limit: 20 MHz)
//   one conversion is about 1.4 us, so 100 kS/s leaves ample margin.
// Status: behavioral simulation only. Board pins, voltage levels and real
// timing margins have not been verified on hardware.
module pmod_ad1_reader #(
    parameter integer SCLK_HALF_CYCLES = 2,   // system clocks per SCLK half period
    parameter integer QUIET_CYCLES     = 3    // CS-high gap after a frame (>= 50 ns)
) (
    input  wire        clk,
    input  wire        rst,            // synchronous, active high
    input  wire        start,          // one-cycle request; ignored while busy
    input  wire        sdata,          // AD7476A DOUT (Pmod AD1 D0)
    output reg         cs_n,
    output reg         sclk,
    output reg  [11:0] sample,         // last converted value
    output reg         sample_valid,   // one-cycle pulse when sample updates
    output wire        busy
);

    localparam [1:0] S_IDLE    = 2'd0,
                     S_CONVERT = 2'd1,
                     S_QUIET   = 2'd2;

    reg [1:0]  state;
    reg [7:0]  div_cnt;
    reg [4:0]  bit_cnt;
    reg [15:0] shift_reg;
    reg [7:0]  quiet_cnt;

    assign busy = (state != S_IDLE);

    always @(posedge clk) begin
        sample_valid <= 1'b0;

        if (rst) begin
            state     <= S_IDLE;
            cs_n      <= 1'b1;
            sclk      <= 1'b1;
            div_cnt   <= 8'd0;
            bit_cnt   <= 5'd0;
            shift_reg <= 16'd0;
            quiet_cnt <= 8'd0;
            sample    <= 12'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    cs_n <= 1'b1;
                    sclk <= 1'b1;
                    if (start) begin
                        cs_n    <= 1'b0;
                        div_cnt <= 8'd0;
                        bit_cnt <= 5'd0;
                        state   <= S_CONVERT;
                    end
                end

                S_CONVERT: begin
                    if (div_cnt == SCLK_HALF_CYCLES - 1) begin
                        div_cnt <= 8'd0;
                        if (sclk) begin
                            // Falling edge: capture the current bit before the ADC moves on.
                            shift_reg <= {shift_reg[14:0], sdata};
                            sclk      <= 1'b0;
                            bit_cnt   <= bit_cnt + 5'd1;
                        end else begin
                            sclk <= 1'b1;
                            if (bit_cnt == 5'd16) begin
                                cs_n         <= 1'b1;
                                sample       <= shift_reg[11:0];
                                sample_valid <= 1'b1;
                                quiet_cnt    <= 8'd0;
                                state        <= S_QUIET;
                            end
                        end
                    end else begin
                        div_cnt <= div_cnt + 8'd1;
                    end
                end

                S_QUIET: begin
                    if (quiet_cnt == QUIET_CYCLES - 1)
                        state <= S_IDLE;
                    else
                        quiet_cnt <= quiet_cnt + 8'd1;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
