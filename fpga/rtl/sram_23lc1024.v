// SPI master for the Microchip 23LC1024 (1 Mbit SPI SRAM), SPI mode 0,
// default sequential mode. One transaction = one 16-bit word:
//   write: 0x02 | 24-bit byte address | 16 data bits   (48 SCK cycles)
//   read : 0x03 | 24-bit byte address | 16 data bits in (48 SCK cycles)
// Word address addr (16 bits) -> byte address {addr, 1'b0}: 64 K words = 128 KB.
// SI changes while SCK is low; the SRAM samples SI on the SCK rising edge.
// The SRAM drives SO after the SCK falling edge; we sample it on the rising edge.
// SCK = clk / (2 * SCK_HALF_CYCLES) = 12 MHz / 4 = 3 MHz (23LC1024 limit: 20 MHz).
module sram_23lc1024 #(
    parameter integer SCK_HALF_CYCLES = 2
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,      // one-cycle request; ignored while busy
    input  wire        we,         // 1 = write, 0 = read
    input  wire        wrmr,       // 1 = write MODE register = 0x40 (sequential), 16 bits only
    input  wire        rstio,      // 1 = RSTIO 0xFF (back to SPI mode from SDI/SQI), 8 bits only
    input  wire [15:0] addr,       // word address
    input  wire [15:0] wdata,
    output reg  [15:0] rdata,
    output wire        busy,
    output reg         done,       // one-cycle pulse at the end of a transaction
    output reg         cs_n,
    output reg         sck,
    output reg         si,
    input  wire        so
);

    reg [47:0] sh     = 48'd0;
    reg [5:0]  bits   = 6'd0;      // SCK rising edges still to come
    reg [7:0]  div    = 8'd0;
    reg        active = 1'b0;
    reg        rd     = 1'b0;
    reg        so_r   = 1'b0;      // SO synchronised to clk

    assign busy = active;

    always @(posedge clk)
        so_r <= so;

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            cs_n   <= 1'b1;
            sck    <= 1'b0;
            si     <= 1'b0;
            active <= 1'b0;
            div    <= 8'd0;
        end else if (!active) begin
            sck  <= 1'b0;
            cs_n <= 1'b1;
            if (start) begin
                if (rstio) begin
                    sh   <= {8'hFF, 40'd0};          // RSTIO: reset to SPI mode
                    bits <= 6'd8;
                    rd   <= 1'b0;
                end else if (wrmr) begin
                    sh   <= {8'h01, 8'h40, 32'd0};   // WRMR, sequential mode
                    bits <= 6'd16;
                    rd   <= 1'b0;
                end else begin
                    sh   <= {(we ? 8'h02 : 8'h03), 7'd0, addr, 1'b0, (we ? wdata : 16'h0000)};
                    bits <= 6'd48;
                    rd   <= ~we;
                end
                si     <= rstio;           // bit 47 of the frame: 1 for 0xFF, 0 for 0x01/0x02/0x03
                cs_n   <= 1'b0;
                active <= 1'b1;
                div    <= 8'd0;
            end
        end else if (div == SCK_HALF_CYCLES - 1) begin
            div <= 8'd0;
            if (!sck) begin
                if (bits == 6'd0) begin    // all 48 bits done: end the transaction
                    cs_n   <= 1'b1;
                    active <= 1'b0;
                    done   <= 1'b1;
                end else begin
                    sck  <= 1'b1;          // rising edge: SRAM samples SI, we sample SO
                    bits <= bits - 6'd1;
                    if (rd && bits <= 6'd16)
                        rdata <= {rdata[14:0], so_r};
                end
            end else begin
                sck <= 1'b0;               // falling edge: present the next bit
                sh  <= {sh[46:0], 1'b0};
                si  <= sh[46];
            end
        end else begin
            div <= div + 8'd1;
        end
    end

endmodule
