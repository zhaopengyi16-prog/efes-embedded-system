// 20-entry sine table: one period of a sine centred at mid-scale (2048),
// amplitude 1800 LSB. At 20 kS/s this gives a 1 kHz tone.
module sine_lut (
    input  wire [4:0]  index,       // 0 .. 19
    output reg  [11:0] sine_value
);
    always @(*) begin
        case (index)
            5'd0 : sine_value = 12'd2048;
            5'd1 : sine_value = 12'd2604;
            5'd2 : sine_value = 12'd3106;
            5'd3 : sine_value = 12'd3504;
            5'd4 : sine_value = 12'd3760;
            5'd5 : sine_value = 12'd3848;
            5'd6 : sine_value = 12'd3760;
            5'd7 : sine_value = 12'd3504;
            5'd8 : sine_value = 12'd3106;
            5'd9 : sine_value = 12'd2604;
            5'd10: sine_value = 12'd2048;
            5'd11: sine_value = 12'd1492;
            5'd12: sine_value = 12'd990;
            5'd13: sine_value = 12'd592;
            5'd14: sine_value = 12'd336;
            5'd15: sine_value = 12'd248;
            5'd16: sine_value = 12'd336;
            5'd17: sine_value = 12'd592;
            5'd18: sine_value = 12'd990;
            5'd19: sine_value = 12'd1492;
            default: sine_value = 12'd2048;
        endcase
    end
endmodule
