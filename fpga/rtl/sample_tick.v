// One-cycle sample-rate pulse generator.
// Default: 50 MHz / 500 = 100 kS/s. Use DIVIDE = 1000 for the 50 kS/s first tests.
module sample_tick #(
    parameter integer DIVIDE = 500   // 2 .. 65535 clock cycles per tick
) (
    input  wire clk,
    input  wire rst,                 // synchronous, active high
    output reg  tick                 // high for exactly one clock cycle
);

    reg [15:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count <= 16'd0;
            tick  <= 1'b0;
        end else if (count == DIVIDE - 1) begin
            count <= 16'd0;
            tick  <= 1'b1;
        end else begin
            count <= count + 16'd1;
            tick  <= 1'b0;
        end
    end

endmodule
