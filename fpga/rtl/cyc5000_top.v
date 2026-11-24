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
        assign LED = {5'b00000, slow_led, btn_sync[1], blink};
   

endmodule
