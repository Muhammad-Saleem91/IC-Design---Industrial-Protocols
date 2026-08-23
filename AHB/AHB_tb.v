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
    always #10 HCLK = ~HCLK; // 20 ns period

    // Utility task: send a single non-burst transfer
    task single_transfer;
        input [31:0] addr;
        input [31:0] wdata;
        input        write;
        input [2:0]  size;
        input        slave2; // 1 = Slave 2 (has wait-state, needs extra cycle)
        begin
            PADDR  = addr;
            PWDATA = wdata;
            PWRITE = write;
            PSIZE  = size;
            PTRANS = 2'b10; // NONSEQ
            PBURST = 3'b000;
            if (slave2) #80; // extra cycle for Slave 2 wait-state
            else        #40; // 2 cycles for Slave 1 (no wait-state)
            PTRANS = 2'b00;
            #20;
        end
    endtask

    initial begin

        // ----------------------------------------------------------------
        // Reset
        // ----------------------------------------------------------------
        HRESETn = 0;
        PADDR   = 0; PWDATA = 0; PWRITE = 0;
        PSIZE   = 0; PTRANS = 0; PBURST = 0;
        #20;
        HRESETn = 1;
        #20;

        // ================================================================
        // TC1 — Single Write (no wait-state, Slave 1)
        // HADDR[31:30]=00 selects Slave 1; Slave 1 has no HREADYOUT stalls
        // ================================================================
        single_transfer(32'h00000004, 32'hA5, 1, 3'b000, 0);
        single_transfer(32'h00000008, 32'hB6C7D8E9, 1, 3'b010, 0);

        PTRANS = 2'b00; #40;

        // ================================================================
        // TC2 — Single Read (no wait-state, Slave 1)
        // Read back the data written in TC1
        // ================================================================
        single_transfer(32'h00000004, 0, 0, 3'b000, 0);
        single_transfer(32'h00000008, 0, 0, 3'b010, 0);

        PTRANS = 2'b00; #40;

        // ================================================================
        // TC3 — Write with Wait-state Insertion (Slave 2)
        // HADDR[31:30]=01 selects Slave 2; Slave 2 inserts 1 HREADYOUT=0
        // cycle before completing each transfer (ws_done flag in Slave 2)
        // ================================================================
        single_transfer(32'h40000004, 32'hAA, 1, 3'b000, 1); // 8-bit write
        single_transfer(32'h40000010, 32'hA5B6, 1, 3'b001, 1); // 16-bit write
        single_transfer(32'h40000020, 32'hDEADBEEF, 1, 3'b010, 1); // 32-bit write

        // Read back to verify data survived the wait-state transfer
        single_transfer(32'h40000004, 0, 0, 3'b000, 1);
        single_transfer(32'h40000020, 0, 0, 3'b010, 1);

        PTRANS = 2'b00; #40;

        // ================================================================
        // TC4 — INCR4 Burst Write then Read (Slave 1, 32-bit)
        // HBURST=011 (INCR4): master auto-increments HADDR by 4 per beat
        // and auto-stops after exactly 4 beats using beat_cnt
        // ================================================================

        // --- INCR4 Write ---
        PADDR  = 32'h00000100;
        PWDATA = 32'hAABBCCDD;
        PWRITE = 1;
        PSIZE  = 3'b010;        // 32-bit
        PTRANS = 2'b10;         // NONSEQ (beat 1)
        PBURST = 3'b011;        // INCR4
        #20;
        // Master transitions to SEQ automatically; provide fresh PWDATA each beat
        PWDATA = 32'h11223344; #20; // beat 2  → HADDR=0x104
        PWDATA = 32'h55667788; #20; // beat 3  → HADDR=0x108
        PWDATA = 32'h99AABBCC; #20; // beat 4  → HADDR=0x10C (master returns IDLE)
        PTRANS = 2'b00; #40;

        // --- INCR4 Read ---
        PADDR  = 32'h00000100;
        PWRITE = 0;
        PSIZE  = 3'b010;
        PTRANS = 2'b10;
        PBURST = 3'b011;
        #20;
        #20; // beat 2
        #20; // beat 3
        #20; // beat 4
        PTRANS = 2'b00; #40;

        // ================================================================
        // TC5 — Invalid Address / Error Response
        // HADDR[31:30]=10 or 11 is unmapped; decoder sets HSELx_Mux[1]=1
        // MUX generates: cycle1 HRESP=1 HREADY=0, cycle2 HRESP=1 HREADY=1
        // ================================================================
        PADDR  = 32'hC0000000; // HADDR[31:30]=11 → unmapped region
        PWRITE = 0;
        PSIZE  = 3'b000;
        PTRANS = 2'b10;
        PBURST = 3'b000;
        #60; // allow both error cycles to be observed on waveform
        PTRANS = 2'b00;
        #40;

        $stop;
    end

endmodule

/*
-- ModelSim wave add commands --
add wave -position insertpoint  \
sim:/AHB_tb/HCLK \
sim:/AHB_tb/HRESETn \
sim:/AHB_tb/PADDR \
sim:/AHB_tb/PWDATA \
sim:/AHB_tb/PWRITE \
sim:/AHB_tb/PSIZE \
sim:/AHB_tb/PTRANS \
sim:/AHB_tb/PBURST \
sim:/AHB_tb/top/master/HADDR \
sim:/AHB_tb/top/master/HWDATA \
sim:/AHB_tb/top/master/HWRITE \
sim:/AHB_tb/top/master/HSIZE \
sim:/AHB_tb/top/master/HTRANS \
sim:/AHB_tb/top/master/HBURST \
sim:/AHB_tb/top/master/HREADY \
sim:/AHB_tb/top/master/HRESP \
sim:/AHB_tb/top/master/HRDATA \
sim:/AHB_tb/top/master/cs \
sim:/AHB_tb/top/master/ns \
sim:/AHB_tb/top/master/beat_cnt \
sim:/AHB_tb/top/slave1/HSELx_slaves \
sim:/AHB_tb/top/slave1/HREADYOUT \
sim:/AHB_tb/top/slave1/HRDATA \
sim:/AHB_tb/top/slave1/memory \
sim:/AHB_tb/top/slave2/curr_state \
sim:/AHB_tb/top/slave2/next_state \
sim:/AHB_tb/top/slave2/HREADYOUT \
sim:/AHB_tb/top/slave2/ws_done \
sim:/AHB_tb/top/slave2/HRDATA \
sim:/AHB_tb/top/slave2/memory_2 \
sim:/AHB_tb/top/mux/HSELx_Mux \
sim:/AHB_tb/top/mux/HREADY \
sim:/AHB_tb/top/mux/HRESP \
sim:/AHB_tb/top/mux/err_phase \
run -all
*/