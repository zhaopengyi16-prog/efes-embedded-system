// SPI driver for the Microchip MCP4921 12-bit DAC (write-only, SPI mode 0).
// Frame (16 bits, MSB first): 0 | BUF=0 | GA=1 (1x gain) | SHDN=1 (active) | D11..D0
// SDI changes only while SCK is low; the DAC samples it on the SCK rising edge.
// LDAC is tied to GND, so the output updates when CS goes high.
// SCK = clk / (2 * SCK_HALF_CYCLES): 12 MHz / 4 = 3 MHz (MCP4921 limit: 20 MHz).
module mcp4921_dac #(
    parameter integer SCK_HALF_CYCLES = 2
) (
    input  wire        clk,
    input  wire        rst,        // synchronous, active high
    input  wire        start,      // one-cycle request; ignored while busy
    input  wire [11:0] value,      // 0 .. 4095 -> 0 .. VREF
    output reg         cs_n,
    output reg         sck,
    output reg         sdi,
    output wire        busy
);

    reg [15:0] frame  = 16'd0;
    reg [4:0]  bits   = 5'd0;      // bits still to be clocked in by the DAC
    reg [7:0]  div    = 8'd0;
    reg        active = 1'b0;

    assign busy = active;

    always @(posedge clk) begin
        if (rst) begin
            cs_n   <= 1'b1;
            sck    <= 1'b0;
            sdi    <= 1'b0;
            active <= 1'b0;
            div    <= 8'd0;
        end else if (!active) begin
            sck  <= 1'b0;
            cs_n <= 1'b1;
            if (start) begin
                frame  <= {4'b0011, value};
                sdi    <= 1'b0;            // bit 15 of the frame (always 0)
                bits   <= 5'd16;
                cs_n   <= 1'b0;
                active <= 1'b1;
                div    <= 8'd0;
            end
        end else if (div == SCK_HALF_CYCLES - 1) begin
            div <= 8'd0;
            if (!sck) begin
                if (bits == 5'd0) begin    // all 16 bits clocked: end the frame
                    cs_n   <= 1'b1;
                    active <= 1'b0;
                end else begin
                    sck  <= 1'b1;          // rising edge: DAC samples SDI
                    bits <= bits - 5'd1;
                end
            end else begin
                sck   <= 1'b0;             // falling edge: present the next bit
                frame <= {frame[14:0], 1'b0};
                sdi   <= frame[14];
            end
        end else begin
            div <= div + 8'd1;
        end
    end

endmodule
