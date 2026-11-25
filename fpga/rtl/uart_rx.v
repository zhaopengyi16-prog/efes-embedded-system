// UART receiver, 8N1, LSB first.
// `valid` pulses for one clock when a byte with a correct stop bit is received.
module uart_rx #(
    parameter integer CLKS_PER_BIT = 104
) (
    input  wire       clk,
    input  wire       rst,        // synchronous, active high
    input  wire       rx,         // asynchronous serial input, idle high
    output reg  [7:0] data,
    output reg        valid
);

    // Two-stage synchronizer for the asynchronous input.
    reg [1:0] rx_sync = 2'b11;
    always @(posedge clk) rx_sync <= {rx_sync[0], rx};
    wire rxs = rx_sync[1];

    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0]  state   = IDLE;
    reg [15:0] clk_cnt = 16'd0;
    reg [2:0]  bit_idx = 3'd0;
    reg [7:0]  shift   = 8'd0;

    always @(posedge clk) begin
        valid <= 1'b0;
        if (rst) begin
            state   <= IDLE;
            clk_cnt <= 16'd0;
        end else begin
            case (state)
                IDLE: if (!rxs) begin                 // falling edge: start bit
                    state   <= START;
                    clk_cnt <= 16'd0;
                end
                START: if (clk_cnt == CLKS_PER_BIT / 2 - 1) begin
                    clk_cnt <= 16'd0;                 // middle of start bit
                    if (!rxs) begin
                        state   <= DATA;
                        bit_idx <= 3'd0;
                    end else
                        state <= IDLE;                // glitch, not a start bit
                end else
                    clk_cnt <= clk_cnt + 16'd1;
                DATA: if (clk_cnt == CLKS_PER_BIT - 1) begin
                    clk_cnt <= 16'd0;                 // middle of a data bit
                    shift   <= {rxs, shift[7:1]};     // LSB arrives first
                    if (bit_idx == 3'd7)
                        state <= STOP;
                    bit_idx <= bit_idx + 3'd1;
                end else
                    clk_cnt <= clk_cnt + 16'd1;
                STOP: if (clk_cnt == CLKS_PER_BIT - 1) begin
                    clk_cnt <= 16'd0;
                    state   <= IDLE;
                    if (rxs) begin                    // valid stop bit
                        data  <= shift;
                        valid <= 1'b1;
                    end
                end else
                    clk_cnt <= clk_cnt + 16'd1;
            endcase
        end
    end

endmodule
