// UART transmitter, 8N1, LSB first.
// Pulse `start` for one clock with `data` valid; `busy` is high while sending.
// CLKS_PER_BIT = clock frequency / baud rate (12 MHz / 115200 = 104).
module uart_tx #(
    parameter integer CLKS_PER_BIT = 104
) (
    input  wire       clk,
    input  wire       rst,        // synchronous, active high
    input  wire       start,      // one-cycle request; ignored while busy
    input  wire [7:0] data,
    output reg        tx,         // serial line, idle high
    output wire       busy
);

    reg [9:0]  shift   = 10'h3FF; // {stop, data[7:0], start}
    reg [3:0]  bit_idx = 4'd0;    // bits left to send
    reg [15:0] clk_cnt = 16'd0;

    assign busy = (bit_idx != 4'd0);

    always @(posedge clk) begin
        if (rst) begin
            tx      <= 1'b1;
            bit_idx <= 4'd0;
            clk_cnt <= 16'd0;
        end else if (!busy) begin
            tx <= 1'b1;
            if (start) begin
                shift   <= {1'b1, data, 1'b0};
                bit_idx <= 4'd10;
                clk_cnt <= 16'd0;
            end
        end else begin
            tx <= shift[0];                       // drive the current bit
            if (clk_cnt == CLKS_PER_BIT - 1) begin
                clk_cnt <= 16'd0;
                shift   <= {1'b1, shift[9:1]};    // next bit
                bit_idx <= bit_idx - 4'd1;
            end else begin
                clk_cnt <= clk_cnt + 16'd1;
            end
        end
    end

endmodule
