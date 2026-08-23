module axi_slave #(
    parameter ADDRESS_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                     ACLK,
    input  wire                     ARESETN,

    input  wire [ADDRESS_WIDTH-1:0] ARADDR,
    input  wire                     ARVALID,
    output reg                      ARREADY,

    output reg  [DATA_WIDTH-1:0]    RDATA,
    output reg  [1:0]               RRESP,
    output reg                      RVALID,
    input  wire                     RREADY,

    input  wire [ADDRESS_WIDTH-1:0] AWADDR,
    input  wire                     AWVALID,
    output reg                      AWREADY,

    input  wire [DATA_WIDTH-1:0]    WDATA,
    input  wire [3:0]               WSTRB,
    input  wire                     WVALID,
    output reg                      WREADY,

    output reg  [1:0]               BRESP,
    output reg                      BVALID,
    input  wire                     BREADY
);

    reg [DATA_WIDTH-1:0] memory [0:255];
    
    reg [ADDRESS_WIDTH-1:0] read_addr_reg;
    reg [ADDRESS_WIDTH-1:0] write_addr_reg;

    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ARREADY <= 0; RVALID  <= 0; RDATA   <= 0; RRESP   <= 2'b00;
            AWREADY <= 0; WREADY  <= 0; BVALID  <= 0; BRESP   <= 2'b00;
        end else begin
            // Read Address Phase
            if (ARVALID && !ARREADY && !RVALID) begin
                ARREADY <= 1;
                read_addr_reg <= ARADDR;
            end else begin
                ARREADY <= 0;
            end

            // Read Data Phase
            if (ARREADY && ARVALID) begin
                RVALID <= 1;
                if (read_addr_reg < 256) begin
                    RDATA <= memory[read_addr_reg];
                    RRESP <= 2'b00; 
                end else begin
                    RDATA <= 0;
                    RRESP <= 2'b10; 
                end
            end else if (RVALID && RREADY) begin
                RVALID <= 0; 
            end

            // Write Address Phase
            if (AWVALID && !AWREADY && !BVALID) begin
                AWREADY <= 1;
                write_addr_reg <= AWADDR;
            end else begin
                AWREADY <= 0;
            end

            // Write Data Phase
            if (WVALID && !WREADY && !BVALID) begin
                WREADY <= 1;
            end else begin
                WREADY <= 0;
            end

            // Execute Write and Response
            if (AWREADY && AWVALID && WREADY && WVALID) begin
                if (write_addr_reg < 256) begin
                    memory[write_addr_reg] <= WDATA; 
                    BRESP <= 2'b00; 
                end else begin
                    BRESP <= 2'b10; 
                end
                BVALID <= 1;
            end else if (BVALID && BREADY) begin
                BVALID <= 0; 
            end
        end
    end
endmodule