module AHB_Lite_Master (
    input  HCLK,
    input  HRESETn,
    // Processor-side inputs
    input  [31:0] PADDR,
    input  [31:0] PWDATA,
    input         PWRITE,
    input  [2:0]  PSIZE,
    input  [1:0]  PTRANS,
    input  [2:0]  PBURST,
    // AHB bus inputs
    input         HREADY,
    input         HRESP,
    input  [31:0] HRDATA,
    // AHB bus outputs
    output reg [31:0] HADDR,
    output reg [31:0] HWDATA,
    output reg        HWRITE,
    output reg [2:0]  HSIZE,
    output reg [1:0]  HTRANS,
    output reg [2:0]  HBURST,
    output reg        PDONE
);

    parameter IDLE   = 2'b00;
    parameter BUSY   = 2'b01;
    parameter NONSEQ = 2'b10;
    parameter SEQ    = 2'b11;

    reg [31:0] HWDATA_reg;
    reg [ 1:0] cs, ns;
    reg [ 1:0] beat_cnt; // counts beats for fixed-length bursts (INCR4)

    // State register
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) cs <= IDLE;
        else if (HREADY) cs <= ns;
    end

    // Next-state logic
    always @(*) begin
        case (cs)
            IDLE: begin
                if (PTRANS == 2'b10) ns = NONSEQ;
                else                  ns = IDLE;
            end
            BUSY: begin
                if      (PTRANS == 2'b11) ns = SEQ;
                else if (PTRANS == 2'b10) ns = NONSEQ;
                else if (PTRANS == 2'b00) ns = IDLE;
                else                      ns = BUSY;
            end
            NONSEQ: begin
                if      (PTRANS == 2'b11)                           ns = SEQ;
                else if (PTRANS == 2'b00)                           ns = IDLE;
                else if (PTRANS == 2'b10 && PBURST == 3'b000)       ns = NONSEQ;
                else                                                 ns = SEQ;
            end
            SEQ: begin
                // INCR4 (HBURST=011): auto-stop after 4 beats
                if      (PBURST == 3'b011 && beat_cnt == 2'd3)      ns = IDLE;
                else if (PTRANS == 2'b00)                           ns = IDLE;
                else if (PTRANS == 2'b10)                           ns = NONSEQ;
                else                                                 ns = SEQ;
            end
            default: ns = IDLE;
        endcase
    end

    // Output logic
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HADDR      <= 32'b0;
            HWDATA_reg <= 32'b0;
            HWRITE     <= 1'b0;
            HSIZE      <= 3'b000;
            HTRANS     <= 2'b00;
            HBURST     <= 3'b000;
            beat_cnt   <= 2'd0;
        end else if (HREADY) begin
            case (cs)
                IDLE: begin
                    HADDR      <= 32'b0;
                    HWDATA_reg <= 32'b0;
                    HWRITE     <= 1'b0;
                    HSIZE      <= 3'b000;
                    HTRANS     <= 2'b00;
                    beat_cnt   <= 2'd0;
                end
                BUSY: begin
                    HADDR      <= PADDR;
                    HWDATA_reg <= PWDATA;
                    HWRITE     <= PWRITE;
                    HSIZE      <= PSIZE;
                    HTRANS     <= PTRANS;
                    HBURST     <= PBURST;
                end
                NONSEQ: begin
                    HADDR      <= PADDR;
                    HWDATA_reg <= PWDATA;
                    HWRITE     <= PWRITE;
                    HSIZE      <= PSIZE;
                    HTRANS     <= PTRANS;
                    HBURST     <= PBURST;
                    // Reset beat counter at start of fixed-length burst
                    beat_cnt   <= (PBURST == 3'b011) ? 2'd1 : 2'd0;
                end
                SEQ: begin
                    // INCR or INCR4: auto-increment address by transfer size
                    if ((PBURST == 3'b001 || PBURST == 3'b011) && PSIZE == 3'b000) begin
                        HADDR      <= HADDR + 1;
                        HWDATA_reg <= {24'h000000, PWDATA[7:0]};
                        HWRITE     <= PWRITE;
                        HSIZE      <= PSIZE;
                        HTRANS     <= 2'b11; // force SEQ on bus
                        HBURST     <= PBURST;
                    end else if ((PBURST == 3'b001 || PBURST == 3'b011) && PSIZE == 3'b001) begin
                        HADDR      <= HADDR + 2;
                        HWDATA_reg <= {16'h0000, PWDATA[15:0]};
                        HWRITE     <= PWRITE;
                        HSIZE      <= PSIZE;
                        HTRANS     <= 2'b11;
                        HBURST     <= PBURST;
                    end else if ((PBURST == 3'b001 || PBURST == 3'b011) && PSIZE == 3'b010) begin
                        HADDR      <= HADDR + 4;
                        HWDATA_reg <= PWDATA;
                        HWRITE     <= PWRITE;
                        HSIZE      <= PSIZE;
                        HTRANS     <= 2'b11;
                        HBURST     <= PBURST;
                    end else if (!PBURST) begin
                        HADDR      <= PADDR;
                        HWDATA_reg <= PWDATA;
                        HWRITE     <= PWRITE;
                        HSIZE      <= PSIZE;
                        HTRANS     <= PTRANS;
                        HBURST     <= PBURST;
                    end
                    // Advance beat counter for INCR4
                    if (PBURST == 3'b011) beat_cnt <= beat_cnt + 1;
                end
            endcase
        end
    end

    // Data phase: delay HWDATA by one cycle to respect AHB pipeline
    always @(posedge HCLK) begin
        if (HREADY) HWDATA <= HWDATA_reg;
    end

    // Transfer-done flag
    always @(*) begin
        if ((cs == NONSEQ || cs == SEQ) && ns == IDLE)
            PDONE = 1'b1;
        else
            PDONE = 1'b0;
    end

endmodule
