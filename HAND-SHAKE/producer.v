module producer (
    input wire clk,
    input wire rst_n,
    input wire ready,
    input wire valid_in,
    output reg valid_out,
    output reg [3:0] data
);

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data <= 4'd0;
        end else begin
            valid_out <= valid_in; 
            
            if (valid_out && ready) begin 
                data <= data + 4'd1;
            end
        end
    end
endmodule