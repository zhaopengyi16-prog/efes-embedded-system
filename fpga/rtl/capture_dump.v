// "Poor man's oscilloscope": on the UART command 'c', store the next DEPTH ADC
// samples in block RAM, then send them to the PC as text, one sample per line,
// three hex digits each (000 .. FFF) followed by '\n'.
module capture_dump #(
    parameter integer DEPTH = 1024,
    parameter integer AW    = 10            // address width: 2^AW = DEPTH
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [11:0] sample,
    input  wire        sample_valid,
    input  wire [7:0]  rx_data,
    input  wire        rx_valid,
    output reg  [7:0]  tx_data,
    output reg         tx_start,
    input  wire        tx_busy,
    output wire        capturing
);

    reg [11:0] mem [0:DEPTH-1];             // inferred as block RAM
    reg [AW-1:0] addr = {AW{1'b0}};
    reg [11:0] rd_word = 12'd0;
    reg [1:0]  char_idx = 2'd0;

    localparam IDLE = 3'd0, CAPTURE = 3'd1, READ = 3'd2, LOAD = 3'd3,
               SEND = 3'd4, WAIT1 = 3'd5, WAITB = 3'd6;
    reg [2:0] state = IDLE;

    assign capturing = (state == CAPTURE);

    function [7:0] hex;                     // 4-bit value -> ASCII '0'..'F'
        input [3:0] n;
        hex = (n < 4'd10) ? (8'h30 + n) : (8'h37 + n);
    endfunction

    always @(posedge clk) begin
        tx_start <= 1'b0;
        if (rst) begin
            state <= IDLE;
            addr  <= {AW{1'b0}};
        end else begin
            case (state)
                IDLE: if (rx_valid && rx_data == "c") begin
                    addr  <= {AW{1'b0}};
                    state <= CAPTURE;
                end
                CAPTURE: if (sample_valid) begin
                    mem[addr] <= sample;
                    if (addr == DEPTH - 1) begin
                        addr  <= {AW{1'b0}};
                        state <= READ;
                    end else
                        addr <= addr + 1'b1;
                end
                READ: begin                     // block RAM read takes one clock
                    rd_word  <= mem[addr];
                    char_idx <= 2'd0;
                    state    <= LOAD;
                end
                LOAD: state <= SEND;            // rd_word is valid now
                SEND: begin
                    case (char_idx)
                        2'd0: tx_data <= hex(rd_word[11:8]);
                        2'd1: tx_data <= hex(rd_word[7:4]);
                        2'd2: tx_data <= hex(rd_word[3:0]);
                        default: tx_data <= 8'h0A;   // '\n'
                    endcase
                    tx_start <= 1'b1;
                    state    <= WAIT1;
                end
                WAIT1: state <= WAITB;          // let tx_busy rise
                WAITB: if (!tx_busy) begin
                    if (char_idx != 2'd3) begin
                        char_idx <= char_idx + 2'd1;
                        state    <= SEND;
                    end else if (addr == DEPTH - 1) begin
                        state <= IDLE;          // all samples sent
                    end else begin
                        addr  <= addr + 1'b1;
                        state <= READ;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
