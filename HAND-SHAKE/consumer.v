module consumer (
    input wire clk,
    input wire rst_n,
    input wire valid,
    input wire ready_in,
    input wire [3:0] data_in,
    output reg ready_out,
    output reg [3:0] leds
);

    always @(posedge clk) begin
        if (!rst_n) begin
            ready_out <= 1'b0;
            leds <= 4'd0;
        end else begin
            ready_out <= ready_in;
            
            if (valid && ready_out) begin
                leds <= data_in;
            end
        end
    end
endmodule