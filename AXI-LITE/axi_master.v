module axi_master #(
    parameter ADDRESS_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                     ACLK,
    input  wire                     ARESETN,
    
    input  wire                     START_READ,
    input  wire                     START_WRITE,
    input  wire [ADDRESS_WIDTH-1:0] address,
    input  wire [DATA_WIDTH-1:0]    W_data,

    output reg  [ADDRESS_WIDTH-1:0] ARADDR,
    output reg                      ARVALID,
    input  wire                     ARREADY,

    input  wire [DATA_WIDTH-1:0]    RDATA,
    input  wire [1:0]               RRESP,
    input  wire                     RVALID,
    output reg                      RREADY,

    output reg  [ADDRESS_WIDTH-1:0] AWADDR,
    output reg                      AWVALID,
    input  wire                     AWREADY,

    output reg  [DATA_WIDTH-1:0]    WDATA,
    output reg  [3:0]               WSTRB,
    output reg                      WVALID,
    input  wire                     WREADY,

    input  wire [1:0]               BRESP,
    input  wire                     BVALID,
    output reg                      BREADY
);

    localparam IDLE          = 3'b000;
    localparam RADDR_CHANNEL = 3'b001;
    localparam RDATA_CHANNEL = 3'b010;
    localparam WRITE_CHANNEL = 3'b011;
    localparam WRESP_CHANNEL = 3'b100;

    reg [2:0] state, next_state;

    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) state <= IDLE;
        else state <= next_state;
    end

    // FSM State Transitions[cite: 4]
    always @(*) begin
        next_state = state; 
        case (state)
            IDLE: begin
                if (START_READ) next_state = RADDR_CHANNEL;
                else if (START_WRITE) next_state = WRITE_CHANNEL;
            end
            RADDR_CHANNEL: begin
                if (ARVALID && ARREADY) next_state = RDATA_CHANNEL;
            end
            RDATA_CHANNEL: begin
                if (RVALID && RREADY) next_state = IDLE;
            end
            WRITE_CHANNEL: begin
                if (AWVALID && AWREADY && WVALID && WREADY) next_state = WRESP_CHANNEL;
            end
            WRESP_CHANNEL: begin
                if (BVALID && BREADY) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ARADDR  <= 0; ARVALID <= 0; RREADY  <= 0;
            AWADDR  <= 0; AWVALID <= 0; WDATA   <= 0;
            WSTRB   <= 4'b0000; WVALID  <= 0; BREADY  <= 0;
        end else begin
            // Default assignments to drop signals after handshakes
            ARVALID <= 0; RREADY  <= 0;
            AWVALID <= 0; WVALID  <= 0; BREADY  <= 0;

            case (next_state)
                IDLE: begin 
                end
                RADDR_CHANNEL: begin
                    ARADDR  <= address;
                    ARVALID <= 1; 
                end
                RDATA_CHANNEL: begin
                    RREADY <= 1; 
                end
                WRITE_CHANNEL: begin
                    AWADDR  <= address;
                    AWVALID <= 1;
                    WDATA   <= W_data;
                    WSTRB   <= 4'b1111; 
                    WVALID  <= 1;
                end
                WRESP_CHANNEL: begin
                    BREADY <= 1; 
                end
            endcase
        end
    end
endmodule