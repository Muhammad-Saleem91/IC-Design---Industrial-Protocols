module AHB_Slave_2 #(
    parameter MEM_WIDTH = 8,
    parameter MEM_DEPTH = 64
) (
    input HCLK,
    input HRESETn,

    input [31:0] HADDR,
    input [31:0] HWDATA,

    input [1:0] HSELx_slaves,

    input        HWRITE,
    input [2:0]  HSIZE,
    input [1:0]  HTRANS,
    input [2:0]  HBURST,
    input        HREADY,

    output reg        HREADYOUT,
    output reg        HRESP,
    output reg [31:0] HRDATA
);

    parameter IDLE  = 2'b00;
    parameter WRITE = 2'b01;
    parameter READ  = 2'b10;

    reg [1:0] curr_state, next_state;

    reg [MEM_WIDTH-1:0] memory_2[MEM_DEPTH-1:0];

    reg [31:0] HADDR_reg;
    reg        HWRITE_reg;
    reg [2:0]  HSIZE_reg;
    reg [1:0]  HTRANS_reg;
    reg [2:0]  HBURST_reg;

    reg [31:0] HADDR_Half;
    reg [31:0] HADDR_Full_1;
    reg [31:0] HADDR_Full_2;
    reg [31:0] HADDR_Full_3;

    reg ws_done; // tracks whether the 1-cycle wait-state has been served

    // FSM state register
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) curr_state <= IDLE;
        else          curr_state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        next_state = curr_state;
        case (curr_state)
            IDLE: begin
                if (HREADY && HSELx_slaves == 2'b01 && (HTRANS == 2'b10 || HTRANS == 2'b11)) begin
                    if (HWRITE) next_state = WRITE;
                    else        next_state = READ;
                end
            end
            WRITE: begin
                if (!(HTRANS == 2'b10 || HTRANS == 2'b11)) next_state = IDLE;
                else if (!HWRITE)                           next_state = READ;
                else                                        next_state = WRITE;
            end
            READ: begin
                if (!(HTRANS == 2'b10 || HTRANS == 2'b11)) next_state = IDLE;
                else if (HWRITE)                            next_state = WRITE;
                else                                        next_state = READ;
            end
        endcase
    end

    // Output logic with 1-cycle wait-state insertion per transfer
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA    <= 32'h0;
            HREADYOUT <= 1'b1;
            HRESP     <= 1'b0;
            ws_done   <= 1'b0;
        end else begin
            HRESP <= 1'b0;
            case (curr_state)
                READ: begin
                    if (!ws_done) begin
                        // First cycle in READ: drive HRDATA early, hold bus
                        HREADYOUT <= 1'b0;
                        ws_done   <= 1'b1;
                        if (HBURST == 3'b000 || HBURST == 3'b001) begin
                            case (HSIZE)
                                3'b000: HRDATA <= {24'h000000, memory_2[HADDR[29:0]]};
                                3'b001: HRDATA <= {16'h0000, memory_2[HADDR_Half], memory_2[HADDR[29:0]]};
                                3'b010: HRDATA <= {memory_2[HADDR_Full_3], memory_2[HADDR_Full_2],
                                                   memory_2[HADDR_Full_1], memory_2[HADDR[29:0]]};
                                default: HRDATA <= 32'h0;
                            endcase
                        end
                    end else begin
                        // Second cycle: release bus, HRDATA already valid
                        HREADYOUT <= 1'b1;
                        ws_done   <= 1'b0;
                    end
                end
                WRITE: begin
                    if (!ws_done) begin
                        // First cycle in WRITE: insert wait-state
                        HREADYOUT <= 1'b0;
                        ws_done   <= 1'b1;
                    end else begin
                        // Second cycle: perform write, release bus
                        HREADYOUT <= 1'b1;
                        ws_done   <= 1'b0;
                        if (HBURST_reg == 3'b000 || HBURST_reg == 3'b001) begin
                            case (HSIZE_reg)
                                3'b000: memory_2[HADDR_reg[29:0]] <= HWDATA[7:0];
                                3'b001: begin
                                    memory_2[HADDR_reg[29:0]] <= HWDATA[7:0];
                                    memory_2[HADDR_Half]      <= HWDATA[15:8];
                                end
                                3'b010: begin
                                    memory_2[HADDR_reg[29:0]] <= HWDATA[7:0];
                                    memory_2[HADDR_Full_1]    <= HWDATA[15:8];
                                    memory_2[HADDR_Full_2]    <= HWDATA[23:16];
                                    memory_2[HADDR_Full_3]    <= HWDATA[31:24];
                                end
                            endcase
                        end
                    end
                end
                default: begin
                    HREADYOUT <= 1'b1;
                    ws_done   <= 1'b0;
                end
            endcase
        end
    end

    // Address-phase capture register
    always @(posedge HCLK) begin
        if (HREADY && HSELx_slaves == 2'b01) begin
            HADDR_reg  <= HADDR;
            HWRITE_reg <= HWRITE;
            HSIZE_reg  <= HSIZE;
            HTRANS_reg <= HTRANS;
            HBURST_reg <= HBURST;
        end
    end

    // Sub-word address calculation
    always @(*) begin
        if (HREADY) begin
            if (HWRITE) begin
                HADDR_Half   = HADDR_reg[29:0] + 1;
                HADDR_Full_1 = HADDR_reg[29:0] + 1;
                HADDR_Full_2 = HADDR_reg[29:0] + 2;
                HADDR_Full_3 = HADDR_reg[29:0] + 3;
            end else begin
                HADDR_Half   = HADDR[29:0] + 1;
                HADDR_Full_1 = HADDR[29:0] + 1;
                HADDR_Full_2 = HADDR[29:0] + 2;
                HADDR_Full_3 = HADDR[29:0] + 3;
            end
        end else begin
            HADDR_Half   = HADDR_reg[29:0] + 1;
            HADDR_Full_1 = HADDR_reg[29:0] + 1;
            HADDR_Full_2 = HADDR_reg[29:0] + 2;
            HADDR_Full_3 = HADDR_reg[29:0] + 3;
        end
    end

endmodule
