module AHB_Slave_1 #(
    parameter MEM_WIDTH = 8, 
    parameter MEM_DEPTH = 1024
) (
    input HCLK,
    input HRESETn,
    input [31:0] HADDR,
    input [31:0] HWDATA,
    input [1:0]  HSELx_slaves,
    input        HWRITE,
    input [2:0]  HSIZE,
    input [1:0]  HTRANS,
    input [2:0]  HBURST,
    input        HREADY,
    output reg        HREADYOUT,
    output reg        HRESP,
    output reg [31:0] HRDATA
);

    reg [MEM_WIDTH-1:0] memory [MEM_DEPTH-1:0];

    reg [31:0] HADDR_Half;
    reg [31:0] HADDR_Full_1;
    reg [31:0] HADDR_Full_2;
    reg [31:0] HADDR_Full_3;

    reg [31:0] HADDR_reg;
    reg        HWRITE_reg;
    reg [2:0]  HSIZE_reg;
    reg [1:0]  HTRANS_reg;
    reg [2:0]  HBURST_reg;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HREADYOUT <= 1'b1;
            HRESP     <= 1'b0;
            HRDATA    <= 32'h0;
        end else if (!HSELx_slaves && HREADY) begin
            if (HWRITE_reg && (HTRANS_reg == 2'b10 || HTRANS_reg == 2'b11)) begin
                if ((HBURST_reg == 3'b000 || HBURST_reg == 3'b001) && HSIZE_reg == 3'b000) begin 
                    memory[HADDR_reg[29:0]] <= HWDATA[7:0];
                end else if ((HBURST_reg == 3'b000 || HBURST_reg == 3'b001) && HSIZE_reg == 3'b001) begin
                    memory[HADDR_reg[29:0]] <= HWDATA[7:0];
                    memory[HADDR_Half]      <= HWDATA[15:8];
                end else if ((HBURST_reg == 3'b000 || HBURST_reg == 3'b001) && HSIZE_reg == 3'b010) begin
                    memory[HADDR_reg[29:0]] <= HWDATA[7:0];
                    memory[HADDR_Full_1]    <= HWDATA[15:8];
                    memory[HADDR_Full_2]    <= HWDATA[23:16];
                    memory[HADDR_Full_3]    <= HWDATA[31:24];
                end
            end else if (!HWRITE && (HTRANS == 2'b10 || HTRANS == 2'b11)) begin
                if ((HBURST == 3'b000 || HBURST == 3'b001) && HSIZE == 3'b000) begin 
                    HRDATA <= {24'h000000, memory[HADDR[29:0]]};
                end else if ((HBURST == 3'b000 || HBURST == 3'b001) && HSIZE == 3'b001) begin
                    HRDATA <= {16'h0000, memory[HADDR_Half], memory[HADDR[29:0]]};
                end else if ((HBURST == 3'b000 || HBURST == 3'b001) && HSIZE == 3'b010) begin
                    HRDATA <= {memory[HADDR_Full_3], memory[HADDR_Full_2], memory[HADDR_Full_1], memory[HADDR[29:0]]};
                end
            end
        end
    end

    always @(posedge HCLK) begin
        if (HREADY && HSELx_slaves == 2'b00) begin 
            HADDR_reg  <= HADDR;
            HWRITE_reg <= HWRITE;
            HSIZE_reg  <= HSIZE;
            HBURST_reg <= HBURST;
            HTRANS_reg <= HTRANS;
        end
    end

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
