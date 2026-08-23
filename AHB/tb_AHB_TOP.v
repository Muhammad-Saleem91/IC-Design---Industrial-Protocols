`include "AHB_TOP.v"

module tb_AHB_TOP ();
  reg HCLK;
  reg HRESETn;
  reg [31:0] PADDR;
  reg [31:0] PWDATA;
  reg PWRITE;
  reg [2:0] PSIZE;
  reg [1:0] PTRANS;
  reg [2:0] PBURST;
  wire PDONE;

  AHB_TOP dut (
      .HCLK(HCLK),
      .HRESETn(HRESETn),
      .PADDR(PADDR),
      .PWDATA(PWDATA),
      .PWRITE(PWRITE),
      .PSIZE(PSIZE),
      .PTRANS(PTRANS),
      .PBURST(PBURST),
      .PDONE(PDONE)
  );

  always #5 HCLK = ~HCLK;


  initial begin
    HCLK = 0;

    HRESETn = 0;
    PADDR  = 32'd0;
    PWRITE = 0;
    PWDATA = 32'd0;
    PSIZE  = 3'd0;  // 8-bit transfer
    PTRANS = 2'd0;  // NONSEQ transfer
    PBURST = 3'd0;  // SINGLE transfer
    #10;

    HRESETn = 1;
    // set data for a write operation
    PADDR  = 32'h00000001;
    PWRITE = 1;
    PWDATA = 32'hA5;
    PSIZE  = 3'b000;  // 8-bit transfer
    PTRANS = 2'b10;  // NONSEQ transfer
    PBURST = 3'b000;  // SINGLE transfer
    #30;

    // set data for a read operation
    PADDR  = 32'h00000001;
    PWRITE = 0;
    PSIZE  = 3'b000;  // 8-bit transfer
    PTRANS = 2'b10;  // NONSEQ transfer
    PBURST = 3'b000;  // SINGLE transfer
    #30;

    $finish;
  end

endmodule
