module efes_top #(
    parameter [24:0] BLINK_HALF_PERIOD_CYCLES = 25'd25000000
) (
    input  wire CLOCK_50,
    input  wire KEY0_N,
    output reg  LEDR0
);

    reg [1:0] reset_sync;
    reg [24:0] blink_counter;

    // Assert reset asynchronously; release it through two clocked stages.
    always @(posedge CLOCK_50 or negedge KEY0_N) begin
        if (!KEY0_N)
            reset_sync <= 2'b00;
        else
            reset_sync <= {reset_sync[0], 1'b1};
    end

    // One clock domain: the counter enables LED updates without creating a clock.
    always @(posedge CLOCK_50) begin
        if (!reset_sync[1]) begin
            blink_counter <= 25'd0;
            LEDR0 <= 1'b0;
        end else if (blink_counter == BLINK_HALF_PERIOD_CYCLES - 25'd1) begin
            blink_counter <= 25'd0;
            LEDR0 <= ~LEDR0;
        end else begin
            blink_counter <= blink_counter + 25'd1;
        end
    end

endmodule
