// Record / playback core using the external 23LC1024 SPI SRAM (replaces the
// block-RAM version in recorder.v). Same UART commands, plus a memory self-test:
//   'r' record  : one ADC sample per 20 kHz tick into SRAM until full (65536 = 3.28 s) or 's'
//   'p' play    : read the recorded samples back to the DAC, one per tick, then stop
//   'g' test sine on (keeps running while recording)
//   's' stop everything; DAC outputs mid-scale (2048)
//   't' SRAM self-test: write a unique pattern to all 65536 words, read it back,
//       then test_pass or test_fail lights up (about 2.2 s)
// Commands are applied only between SRAM transactions, so a transaction is never cut.
module recorder_sram #(
    parameter integer AW = 16                  // 2^AW words in the SRAM
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
    output reg         test_pass,
    output reg         test_fail,
    output wire [3:0]  progress,
    // debug: every word read back during the self-test, for capture_dump
    output wire        dbg_mode,               // 1 while the self-test runs
    output reg  [15:0] dbg_data,
    output reg         dbg_valid,
    // 23LC1024 pins
    output wire        sram_cs_n,
    output wire        sram_sck,
    output wire        sram_si,
    input  wire        sram_so
);

    localparam [2:0] IDLE = 3'd0, REC = 3'd1, PLAY = 3'd2, TW = 3'd3, TR = 3'd4, INIT = 3'd5;
    reg [2:0] state = INIT;

    reg [AW-1:0] addr     = {AW{1'b0}};
    reg [AW-1:0] last     = {AW{1'b0}};
    reg          have_rec = 1'b0;
    reg          pend     = 1'b0;              // an SRAM transaction is in flight
    reg [7:0]    cmd      = 8'd0;
    reg          cmd_v    = 1'b0;
    reg [11:0]   play_q   = 12'd2048;
    reg          lvl_test = 1'b0;              // 'h': hold the SRAM lines at fixed levels

    assign recording = (state == REC);
    assign playing   = (state == PLAY);
    assign progress  = addr[AW-1:AW-4];
    assign dbg_mode  = (state == TW) || (state == TR);

    // ---------- SRAM controller ----------
    reg         s_start = 1'b0;
    reg         s_we    = 1'b0;
    reg         s_wrmr  = 1'b0;
    reg         s_rstio = 1'b0;
    reg         init_wr = 1'b0;                // INIT: 0 = send RSTIO, 1 = send WRMR
    reg  [15:0] s_wdata = 16'd0;
    wire [15:0] s_rdata;
    wire        s_busy, s_done;
    wire        c_cs_n, c_sck, c_si;

    // SCK = 12 MHz / (2 * 4) = 1.5 MHz while debugging the SRAM (was 3 MHz).
    // One 48-bit transaction then takes about 33 us, still inside the 50 us sample period.
    sram_23lc1024 #(.SCK_HALF_CYCLES(4)) u_sram (
        .clk(clk), .rst(rst), .start(s_start), .we(s_we), .wrmr(s_wrmr), .rstio(s_rstio),
        .addr(addr), .wdata(s_wdata), .rdata(s_rdata),
        .busy(s_busy), .done(s_done),
        .cs_n(c_cs_n), .sck(c_sck), .si(c_si), .so(sram_so)
    );

    // Wiring test ('h'): CS low, SCK high, SI high (the opposite of the idle levels),
    // so each line can be checked with a voltmeter at the SRAM pins. 's' ends it.
    assign sram_cs_n = lvl_test ? 1'b0 : c_cs_n;
    assign sram_sck  = lvl_test ? 1'b1 : c_sck;
    assign sram_si   = lvl_test ? 1'b1 : c_si;

    wire [15:0] pattern = addr ^ 16'h5AA5;    // unique value for every word

    always @(posedge clk) begin
        s_start   <= 1'b0;
        dbg_valid <= 1'b0;
        if (rst) begin
            state     <= INIT;
            s_wrmr    <= 1'b0;
            s_rstio   <= 1'b0;
            init_wr   <= 1'b0;
            addr      <= {AW{1'b0}};
            have_rec  <= 1'b0;
            gen_on    <= 1'b0;
            pend      <= 1'b0;
            cmd_v     <= 1'b0;
            test_pass <= 1'b0;
            test_fail <= 1'b0;
            play_q    <= 12'd2048;
            lvl_test  <= 1'b0;
        end else begin
            // latch the latest command
            if (rx_valid && (rx_data == "r" || rx_data == "p" || rx_data == "g" ||
                             rx_data == "s" || rx_data == "t" || rx_data == "h")) begin
                cmd   <= rx_data;
                cmd_v <= 1'b1;
            end

            if (s_done)
                pend <= 1'b0;

            if (cmd_v && !pend && !s_busy && !s_start && state != INIT) begin
                // apply a command only between SRAM transactions
                cmd_v <= 1'b0;
                case (cmd)
                    "r": begin state <= REC;  addr <= {AW{1'b0}}; have_rec <= 1'b0; end
                    "p": if (have_rec) begin state <= PLAY; addr <= {AW{1'b0}}; end
                    "g": gen_on <= 1'b1;
                    "h": begin state <= IDLE; lvl_test <= 1'b1; end
                    "s": begin
                        lvl_test <= 1'b0;
                        if (state == REC && addr != {AW{1'b0}}) begin
                            last     <= addr - 1'b1;
                            have_rec <= 1'b1;
                        end
                        state  <= IDLE;
                        gen_on <= 1'b0;
                    end
                    "t": begin
                        state     <= TW;
                        addr      <= {AW{1'b0}};
                        have_rec  <= 1'b0;
                        test_pass <= 1'b0;
                        test_fail <= 1'b0;
                    end
                    default: ;
                endcase
            end else begin
                case (state)
                    // INIT after reset: RSTIO (0xFF, back to SPI mode), then WRMR (sequential)
                    INIT: if (s_done) begin
                        s_rstio <= 1'b0;
                        s_wrmr  <= 1'b0;
                        if (init_wr)
                            state <= IDLE;
                        else
                            init_wr <= 1'b1;
                    end else if (!pend && !s_busy && !s_start) begin
                        s_rstio <= ~init_wr;
                        s_wrmr  <= init_wr;
                        s_start <= 1'b1;
                        pend    <= 1'b1;
                    end

                    REC: if (s_done) begin
                        if (&addr) begin               // SRAM full
                            last     <= addr;
                            have_rec <= 1'b1;
                            state    <= IDLE;
                        end else
                            addr <= addr + 1'b1;
                    end else if (adc_valid && !pend && !s_busy) begin
                        s_we    <= 1'b1;
                        s_wdata <= {4'd0, adc_sample};
                        s_start <= 1'b1;
                        pend    <= 1'b1;
                    end

                    PLAY: if (s_done) begin
                        play_q <= s_rdata[11:0];
                        if (addr == last)
                            state <= IDLE;
                        else
                            addr <= addr + 1'b1;
                    end else if (tick && !pend && !s_busy) begin
                        s_we    <= 1'b0;
                        s_start <= 1'b1;
                        pend    <= 1'b1;
                    end

                    TW: if (s_done) begin
                        if (&addr) begin
                            addr  <= {AW{1'b0}};
                            state <= TR;
                        end else
                            addr <= addr + 1'b1;
                    end else if (!pend && !s_busy && !s_start) begin
                        s_we    <= 1'b1;
                        s_wdata <= pattern;
                        s_start <= 1'b1;
                        pend    <= 1'b1;
                    end

                    TR: if (s_done) begin
                        dbg_data  <= s_rdata;
                        dbg_valid <= 1'b1;
                        if (s_rdata != pattern)
                            test_fail <= 1'b1;
                        if (&addr) begin
                            test_pass <= ~test_fail & (s_rdata == pattern);
                            addr      <= {AW{1'b0}};
                            state     <= IDLE;
                        end else
                            addr <= addr + 1'b1;
                    end else if (!pend && !s_busy && !s_start) begin
                        s_we    <= 1'b0;
                        s_start <= 1'b1;
                        pend    <= 1'b1;
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
            dac_value <= play_q;
        else if (gen_on)
            dac_value <= sine_value;
        else
            dac_value <= 12'd2048;
    end

endmodule
