// Record / playback core of the EFES project.
// UART commands (single ASCII letters):
//   'r'  record: store every ADC sample in block RAM until the RAM is full
//        (2^AW samples = 65536 = 3.28 s at 20 kS/s) or 's' arrives
//   'p'  play: send the recorded samples to the DAC, one per 20 kHz tick, then stop
//   'g'  switch the 1 kHz test sine on (it keeps running while recording)
//   's'  stop everything; the DAC outputs mid-scale (2048 = silence)
// DAC source priority: playback > test sine > mid-scale.
module recorder #(
    parameter integer AW = 16                  // RAM depth = 2^AW samples
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick,                   // 20 kHz sample tick
    input  wire [11:0] adc_sample,
    input  wire        adc_valid,
    input  wire [11:0] sine_value,
    input  wire [7:0]  rx_data,
    input  wire        rx_valid,
    output reg  [11:0] dac_value,
    output wire        recording,
    output wire        playing,
    output reg         gen_on,
    output wire [3:0]  progress                // top 4 address bits, for the LEDs
);

    localparam [1:0] IDLE = 2'd0, REC = 2'd1, PLAY = 2'd2;
    reg [1:0] state = IDLE;

    reg [AW-1:0] addr     = {AW{1'b0}};
    reg [AW-1:0] last     = {AW{1'b0}};       // address of the last recorded sample
    reg          have_rec = 1'b0;             // something has been recorded

    assign recording = (state == REC);
    assign playing   = (state == PLAY);
    assign progress  = addr[AW-1:AW-4];

    // ---------- block RAM: one write port, synchronous read ----------
    reg [11:0] mem [0:(1 << AW) - 1];
    reg [11:0] rd_q;
    wire       we = (state == REC) && adc_valid;
    always @(posedge clk) begin
        if (we)
            mem[addr] <= adc_sample;
        rd_q <= mem[addr];                    // valid one clock after addr changes
    end

    // ---------- control ----------
    always @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            addr     <= {AW{1'b0}};
            have_rec <= 1'b0;
            gen_on   <= 1'b0;
        end else begin
            // commands, accepted in any state
            if (rx_valid) begin
                case (rx_data)
                    "r": begin state <= REC;  addr <= {AW{1'b0}}; end
                    "p": if (have_rec) begin state <= PLAY; addr <= {AW{1'b0}}; end
                    "g": gen_on <= 1'b1;
                    "s": begin
                        if (state == REC && addr != {AW{1'b0}}) begin
                            last     <= addr - 1'b1;   // keep what was recorded so far
                            have_rec <= 1'b1;
                        end
                        state  <= IDLE;
                        gen_on <= 1'b0;
                    end
                    default: ;
                endcase
            end else begin
                case (state)
                    REC: if (adc_valid) begin
                        if (&addr) begin               // RAM full
                            last     <= addr;
                            have_rec <= 1'b1;
                            state    <= IDLE;
                        end else
                            addr <= addr + 1'b1;
                    end
                    PLAY: if (tick) begin
                        if (addr == last)
                            state <= IDLE;
                        else
                            addr <= addr + 1'b1;
                    end
                    default: ;
                endcase
            end
        end
    end

    // ---------- DAC source ----------
    always @(posedge clk) begin
        if (rst)
            dac_value <= 12'd2048;
        else if (state == PLAY)
            dac_value <= rd_q;
        else if (gen_on)
            dac_value <= sine_value;
        else
            dac_value <= 12'd2048;
    end

endmodule
