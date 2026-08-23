module AHB_Decoder (
    input  [31:0] HADDR,
    output reg [1:0] HSELx_slaves,
    output reg [1:0] HSELx_Mux
);

    always @(*) begin
        case (HADDR[31:30])
            2'b00:   HSELx_slaves = 2'b00;
            2'b01:   HSELx_slaves = 2'b01;
            2'b10:   HSELx_slaves = 2'b10;
            2'b11:   HSELx_slaves = 2'b11;
            default: HSELx_slaves = 2'b00;
        endcase
        HSELx_Mux = HSELx_slaves;
    end

endmodule
