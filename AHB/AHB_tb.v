`include "AHB_TOP.v"

module AHB_tb ();

    reg        HCLK, HRESETn;
    reg [31:0] PADDR, PWDATA;
    reg        PWRITE;
    reg [2:0]  PSIZE;
    reg [1:0]  PTRANS;
    reg [2:0]  PBURST;
    wire       PDONE;

    AHB_TOP top (
        .HCLK(HCLK), .HRESETn(HRESETn),
        .PADDR(PADDR), .PWDATA(PWDATA), .PWRITE(PWRITE),
        .PSIZE(PSIZE), .PTRANS(PTRANS), .PBURST(PBURST),
        .PDONE(PDONE)
    );

    initial HCLK = 0;
    always #10 HCLK = ~HCLK;

    // VCD Dump
    initial begin
        $dumpfile("ahb_waves.vcd");
        $dumpvars(0, AHB_tb);
    end

    // Utility task: single non-burst transfer
    task single_transfer;
        input [31:0] addr;
        input [31:0] wdata;
        input        write;
        input [2:0]  size;
        input        slave2;
        begin
            PADDR  = addr;
            PWDATA = wdata;
            PWRITE = write;
            PSIZE  = size;
            PTRANS = 2'b10;
            PBURST = 3'b000;
            if (slave2) #80;
            else        #40;
            PTRANS = 2'b00;
            #20;
        end
    endtask

    initial begin
        // Reset
        HRESETn = 0;
        PADDR   = 0; PWDATA = 0; PWRITE = 0;
        PSIZE   = 0; PTRANS = 0; PBURST = 0;
        #20;
        HRESETn = 1;
        #20;

        // TC1: Single Write
        single_transfer(32'h00000004, 32'hA5, 1, 3'b000, 0);
        single_transfer(32'h00000008, 32'hB6C7D8E9, 1, 3'b010, 0);
        PTRANS = 2'b00; #40;

        // TC2: Single Read
        single_transfer(32'h00000004, 0, 0, 3'b000, 0);
        single_transfer(32'h00000008, 0, 0, 3'b010, 0);
        PTRANS = 2'b00; #40;

        // TC3: Wait-state Write
        single_transfer(32'h40000004, 32'hAA, 1, 3'b000, 1);
        single_transfer(32'h40000010, 32'hA5B6, 1, 3'b001, 1);
        single_transfer(32'h40000020, 32'hDEADBEEF, 1, 3'b010, 1);
        single_transfer(32'h40000004, 0, 0, 3'b000, 1);
        single_transfer(32'h40000020, 0, 0, 3'b010, 1);
        PTRANS = 2'b00; #40;

        // TC4: INCR4 Burst
        PADDR  = 32'h00000100;
        PWDATA = 32'hAABBCCDD;
        PWRITE = 1;
        PSIZE  = 3'b010;
        PTRANS = 2'b10;
        PBURST = 3'b011;
        #20;
        PWDATA = 32'h11223344; #20;
        PWDATA = 32'h55667788; #20;
        PWDATA = 32'h99AABBCC; #20;
        PTRANS = 2'b00; #40;

        PADDR  = 32'h00000100;
        PWRITE = 0;
        PSIZE  = 3'b010;
        PTRANS = 2'b10;
        PBURST = 3'b011;
        #20;
        #20;
        #20;
        #20;
        PTRANS = 2'b00; #40;

        // TC5: Error Response
        PADDR  = 32'hC0000000;
        PWRITE = 0;
        PSIZE  = 3'b000;
        PTRANS = 2'b10;
        PBURST = 3'b000;
        #60;
        PTRANS = 2'b00;
        #40;

        $finish;
    end

endmodule