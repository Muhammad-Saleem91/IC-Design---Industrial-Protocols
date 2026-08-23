// 2-cycle AHB error response for unmapped address regions
module AHB_MUX (
    input HCLK,
    input HRESETn,

    input        HRESP_Slave_1,
    input        HREADYOUT_1,
    input [31:0] HRDATA_Slave_1,

    input        HRESP_Slave_2,
    input        HREADYOUT_2,
    input [31:0] HRDATA_Slave_2,

    input [1:0] HSELx_Mux,

    output reg [31:0] HRDATA,
    output reg        HREADY,
    output reg        HRESP
);

    // err_phase drives the 2-cycle error response:
    //   err_phase=0 → HREADY=0, HRESP=1 (first  cycle)
    //   err_phase=1 → HREADY=1, HRESP=1 (second cycle)
    reg err_phase;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)            err_phase <= 1'b0;
        else if (HSELx_Mux[1])  err_phase <= ~err_phase; // toggle through error cycles
        else                     err_phase <= 1'b0;
    end

    always @(*) begin
        case (HSELx_Mux)
            2'b00: begin
                HRDATA = HRDATA_Slave_1;
                HREADY = HREADYOUT_1;
                HRESP  = HRESP_Slave_1;
            end
            2'b01: begin
                HRDATA = HRDATA_Slave_2;
                HREADY = HREADYOUT_2;
                HRESP  = HRESP_Slave_2;
            end
            default: begin // unmapped region: AHB 2-cycle error response
                HRDATA = 32'h0;
                HRESP  = 1'b1;
                HREADY = err_phase;
            end
        endcase
    end

endmodule
