`timescale 1ns / 1ps

module axi_tb();

    parameter ADDRESS_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    reg ACLK;
    reg ARESETN;

    reg START_READ;
    reg START_WRITE;
    reg [ADDRESS_WIDTH-1:0] address;
    reg [DATA_WIDTH-1:0]    W_data;

    wire [ADDRESS_WIDTH-1:0] ARADDR;
    wire                     ARVALID;
    wire                     ARREADY;
    
    wire [DATA_WIDTH-1:0]    RDATA;
    wire [1:0]               RRESP;
    wire                     RVALID;
    wire                     RREADY;
    
    wire [ADDRESS_WIDTH-1:0] AWADDR;
    wire                     AWVALID;
    wire                     AWREADY;
    
    wire [DATA_WIDTH-1:0]    WDATA;
    wire [3:0]               WSTRB;
    wire                     WVALID;
    wire                     WREADY;
    
    wire [1:0]               BRESP;
    wire                     BVALID;
    wire                     BREADY;

    axi_master #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) master_inst (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        .START_READ(START_READ),
        .START_WRITE(START_WRITE),
        .address(address),
        .W_data(W_data),
        
        .ARADDR(ARADDR), .ARVALID(ARVALID), .ARREADY(ARREADY),
        .RDATA(RDATA), .RRESP(RRESP), .RVALID(RVALID), .RREADY(RREADY),
        .AWADDR(AWADDR), .AWVALID(AWVALID), .AWREADY(AWREADY),
        .WDATA(WDATA), .WSTRB(WSTRB), .WVALID(WVALID), .WREADY(WREADY),
        .BRESP(BRESP), .BVALID(BVALID), .BREADY(BREADY)
    );

    axi_slave #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) slave_inst (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        
        .ARADDR(ARADDR), .ARVALID(ARVALID), .ARREADY(ARREADY),
        .RDATA(RDATA), .RRESP(RRESP), .RVALID(RVALID), .RREADY(RREADY),
        .AWADDR(AWADDR), .AWVALID(AWVALID), .AWREADY(AWREADY),
        .WDATA(WDATA), .WSTRB(WSTRB), .WVALID(WVALID), .WREADY(WREADY),
        .BRESP(BRESP), .BVALID(BVALID), .BREADY(BREADY)
    );

    // Clock Generation (10ns period)
    initial ACLK = 0;
    always #5 ACLK = ~ACLK;

    // VCD Dump
    initial begin
        $dumpfile("axi_lite_waves.vcd");
        $dumpvars(0, axi_tb);
    end

    initial begin
        // Initialize Stimulus
        START_READ  = 0;
        START_WRITE = 0;
        address     = 0;
        W_data      = 0;
        
        // System Reset
        ARESETN = 0; #20;
        ARESETN = 1; #20;

        // TC1: Standard Write (OKAY)
        address     = 32'h00000010;
        W_data      = 32'hDEADBEEF;
        START_WRITE = 1; #10;
        START_WRITE = 0; 
        wait(BVALID && BREADY); #20; 

        // TC2: Standard Read (OKAY)
        address    = 32'h00000010;
        START_READ = 1; #10;
        START_READ = 0; 
        wait(RVALID && RREADY); #20; 

        // TC3: Out-of-Bounds Write (SLVERR)
        address     = 32'h00000200;
        W_data      = 32'hBAD0BAD0;
        START_WRITE = 1; #10;
        START_WRITE = 0;
        wait(BVALID && BREADY); #20;
        
        // TC4: Out-of-Bounds Read (SLVERR)
        address    = 32'h00000200;
        START_READ = 1; #10;
        START_READ = 0;
        wait(RVALID && RREADY); #40;

        $finish; 
    end

endmodule