// CYC5000 (Trenz TEI0050, Cyclone V E 5CEBA2U15C8) bring-up top level.
// LED0 blinks at 1 Hz from the 12 MHz on-board clock.
// LED1 mirrors USER_BTN so the button polarity can be checked on the board.
// Reset is generated internally at power-up, so the button is not used as reset
// until its polarity has been confirmed.
module cyc5000_top #(
    parameter integer CLK_HZ = 12_000_000
) (
    input  wire       CLK12M,
    input  wire       USER_BTN,
    input  wire       UART_RX,    // from the on-board FTDI channel B (PC COM port)
    output wire       UART_TX,    // to the on-board FTDI channel B
    output wire       DAC_CS_N,   // MCP4921 pin 2  (header D2)
    output wire       DAC_SCK,    // MCP4921 pin 3  (header D3)
    output wire       DAC_SDI,    // MCP4921 pin 4  (header D4)
    output wire       ADC_CS_N,   // ADC121S021 pin 6 (header D7)
    output wire       ADC_SCLK,   // ADC121S021 pin 4 (header D8)
    input  wire       ADC_SDATA,  // ADC121S021 pin 5 (header D9)
    output wire [7:0] LED
);

    localparam integer HALF_PERIOD = CLK_HZ / 2;   // 0.5 s per LED state

    // Power-on reset: held for 16 clock cycles after configuration.
    reg [3:0] por_cnt = 4'd0;
    wire      rst = ~&por_cnt;
    always @(posedge CLK12M) begin
        if (rst)
            por_cnt <= por_cnt + 4'd1;
    end

    // Two-stage synchronizer for the asynchronous button input.
    reg [1:0] btn_sync = 2'b00;
    always @(posedge CLK12M)
        btn_sync <= {btn_sync[0], USER_BTN};

    // 1 Hz blink: toggle every HALF_PERIOD cycles.
    reg [23:0] blink_cnt = 24'd0;
    reg        blink     = 1'b0;
    always @(posedge CLK12M) begin
        if (rst) begin
            blink_cnt <= 24'd0;
            blink     <= 1'b0;
        end else if (blink_cnt == HALF_PERIOD - 1) begin
            blink_cnt <= 24'd0;
            blink     <= ~blink;
        end else begin
            blink_cnt <= blink_cnt + 24'd1;
        end
    end
    wire tick;
      sample_tick #(.DIVIDE(120)) u_tick (
       .clk (CLK12M),
         .rst (rst),
          .tick(tick)
      );
    reg [16:0] tick_cnt = 17'd0;
    reg        slow_led  = 1'b0;
    always @(posedge CLK12M) begin
        if (rst) begin
            tick_cnt <= 17'd0;
            slow_led  <= 1'b0;
        end else if (tick) begin
            if (tick_cnt == 17'd99999) begin
                tick_cnt <= 17'd0;
                slow_led  <= ~slow_led;
            end else begin
                tick_cnt <= tick_cnt + 17'd1;
            end
        end
    end

    // ---------- UART to the PC through the on-board COM port, 115200 8N1 ----------
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       tx_busy;
    uart_rx #(.CLKS_PER_BIT(CLK_HZ / 115200)) u_rx (
        .clk(CLK12M), .rst(rst), .rx(UART_RX), .data(rx_data), .valid(rx_valid)
    );
    wire [7:0] tx_data;
    wire       tx_start;
    uart_tx #(.CLKS_PER_BIT(CLK_HZ / 115200)) u_tx (
        .clk(CLK12M), .rst(rst), .start(tx_start), .data(tx_data),
        .tx(UART_TX), .busy(tx_busy)
    );

    // ---------- DAC test: 1 kHz sine from a 20-entry table at 20 kS/s ----------
    wire dac_tick;
    sample_tick #(.DIVIDE(CLK_HZ / 20000)) u_dac_tick (   // 12 MHz / 600 = 20 kHz
        .clk(CLK12M), .rst(rst), .tick(dac_tick)
    );

    reg [4:0] sine_idx = 5'd0;
    always @(posedge CLK12M) begin
        if (rst)
            sine_idx <= 5'd0;
        else if (dac_tick)
            sine_idx <= (sine_idx == 5'd19) ? 5'd0 : sine_idx + 5'd1;
    end

    wire [11:0] sine_value;
    sine_lut u_sine (.index(sine_idx), .sine_value(sine_value));

    wire [11:0] dac_value;                 // chosen by the recorder (play / sine / silence)
    wire dac_busy;
    mcp4921_dac u_dac (
        .clk(CLK12M), .rst(rst), .start(dac_tick), .value(dac_value),
        .cs_n(DAC_CS_N), .sck(DAC_SCK), .sdi(DAC_SDI), .busy(dac_busy)
    );

    // ---------- ADC: one conversion on every 20 kHz tick ----------
    wire [11:0] adc_sample;
    wire        adc_valid;
    wire        adc_busy;
    pmod_ad1_reader #(.SCLK_HALF_CYCLES(2)) u_adc (   // SCLK = 12 MHz / 4 = 3 MHz
        .clk(CLK12M), .rst(rst), .start(dac_tick), .sdata(ADC_SDATA),
        .cs_n(ADC_CS_N), .sclk(ADC_SCLK),
        .sample(adc_sample), .sample_valid(adc_valid), .busy(adc_busy)
    );

    // ---------- capture 1024 ADC samples on 'c' and send them to the PC ----------
    wire capturing;
    capture_dump u_scope (
        .clk(CLK12M), .rst(rst),
        .sample(adc_sample), .sample_valid(adc_valid),
        .rx_data(rx_data), .rx_valid(rx_valid),
        .tx_data(tx_data), .tx_start(tx_start), .tx_busy(tx_busy),
        .capturing(capturing)
    );

    // ---------- record / playback ----------
    wire       recording, playing, gen_on;
    wire [3:0] progress;
    recorder u_rec (
        .clk(CLK12M), .rst(rst), .tick(dac_tick),
        .adc_sample(adc_sample), .adc_valid(adc_valid),
        .sine_value(sine_value),
        .rx_data(rx_data), .rx_valid(rx_valid),
        .dac_value(dac_value),
        .recording(recording), .playing(playing), .gen_on(gen_on),
        .progress(progress)
    );

    // LED7 = recording, LED6 = playing, LED5 = test sine on,
    // LED4..LED1 = record/playback position, LED0 = 1 Hz heartbeat.
    assign LED = {recording, playing, gen_on, progress, blink};


endmodule
