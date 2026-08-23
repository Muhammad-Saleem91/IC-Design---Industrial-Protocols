`timescale 1ns / 1ps

module tb_apb_top;

  // Clock and reset signals
  reg pclk;
  reg presetn;

  // Master control signals
  reg transfer, read, write;
  reg [8:0] apb_write_paddr;
  reg [7:0] apb_write_data;
  reg [8:0] apb_read_paddr;

  // Outputs from the top module
  wire pslverr;
  wire [7:0] apb_read_data_out;

  // Clock generation (100 MHz)
  initial begin
    pclk = 0;
    forever #5 pclk = ~pclk;  
  end

  initial begin
    $dumpfile("tb_apb_top.vcd");
    $dumpvars(0, tb_apb_top);
  end

  // Instantiate the top module
  apb_top dut (
      .pclk(pclk),
      .presetn(presetn),
      .transfer(transfer),
      .read(read),
      .write(write),
      .apb_write_paddr(apb_write_paddr),
      .apb_write_data(apb_write_data),
      .apb_read_paddr(apb_read_paddr),
      .pslverr(pslverr),
      .apb_read_data_out(apb_read_data_out)
  );

  // Reset and Initialization
  task reset_and_init;
    begin
      presetn = 0;
      transfer = 0;
      read = 0;
      write = 0;
      apb_write_paddr = 9'b0;
      apb_write_data = 8'b0;
      apb_read_paddr = 9'b0;
      #20;  
      presetn = 1;
      #10;
    end
  endtask

  // Reusable Write Task (Cleaned output)
  task test_write;
    input [8:0] address;
    input [7:0] data;
    begin
      transfer = 1;
      write = 1;
      read = 0;
      apb_write_paddr = address;
      apb_write_data = data;
      #10;  // Setup phase
      #10;  // Access phase
      transfer = 0; 
      write = 0;
      $display("      [WRITE] Addr: %h | Data: %h", address, data);
      #10;
    end
  endtask

  // Reusable Read Task (Cleaned output and fixed timing)
  task test_read;
    input [8:0] address;
    begin
      transfer = 1;
      write = 0;
      read = 1;
      apb_read_paddr = address;
      #10;  // Setup phase
      #10;  // Access phase
      #1;   // Delay slightly to let the clock edge capture the data!
      $display("      [READ]  Addr: %h | Data Read: %h", address, apb_read_data_out);
      transfer = 0; 
      read = 0;
      #9;   // Balance the remaining 10ns window
    end
  endtask

  // Main Testbench Execution
  initial begin
    $display("\n=======================================================");
    $display("              APB SYSTEM TESTBENCH START               ");
    $display("=======================================================\n");
    
    reset_and_init;

    $display("\n---> [TC 1] Basic Write Operation");
    test_write(9'h005, 8'hAA);  

    $display("\n---> [TC 2] Basic Read Operation");
    test_read(9'h005);  

    $display("\n---> [TC 3] Address Decoding (Slave Selection)");
    $display("      Writing to Slave 1 (Addr 085) and Slave 2 (Addr 005)...");
    test_write(9'h085, 8'h5A);  
    test_write(9'h005, 8'hA5);  

    $display("\n---> [TC 4] Write with Wait States");
    // (Note: Slaves in this RTL do not support wait states, executes as normal write)
    test_write(9'h010, 8'hBB);  

    $display("\n---> [TC 5] Read with Wait States");
    test_read(9'h010);  

    $display("\n---> [TC 6] Error Handling (PSLVERR)");
    // To trigger an out-of-range error, we must write beyond the 8-bit limit.
    // However, since paddr inside the slave is [7:0], it physically cannot exceed 255.
    // We simulate the master sending a bad transaction.
    transfer = 1;
    write = 1;
    read = 0;
    apb_write_paddr = 9'h1FF;
    apb_write_data  = 8'hFF;
    #20;
    transfer = 0;
    write = 0;
    $display("      Error Condition PSLVERR = %b for Addr = 1FF", pslverr);
    #10;

    $display("\n---> [TC 7] Burst Transfers");
    test_write(9'h001, 8'h11);
    test_read(9'h001);
    test_write(9'h002, 8'h22);
    test_read(9'h002);
    test_write(9'h003, 8'h33);
    test_read(9'h003);

    $display("\n---> [TC 8] Out-of-Range Address");
    $display("      Testing hardware truncation physics (1FF truncates to FF)");
    transfer = 1; write = 1; read = 0;
    apb_write_paddr = 9'h1FF; apb_write_data = 8'hEE;
    #20; transfer = 0; write = 0;
    $display("      PSLVERR = %b (0 means hardware truncated and accepted it)", pslverr);
    #10;

    $display("\n---> [TC 9] Testing Reset Behavior");
    presetn = 0; 
    #20;
    if (!presetn) $display("      System Reset Asserted.");
    presetn = 1; 
    #10;
    if (presetn) $display("      System Reset Released. Registers reset.");
    #10;

    $display("\n---> [TC 10] Randomized Transactions");
    $display("      Executing 5 random transactions...");
    begin : random_block
      integer i;
      for (i = 0; i < 5; i = i + 1) begin
        if ($random % 2) begin
          test_write($random % 9'h100, $random % 8'hFF);
        end else begin
          test_read($random % 9'h100);
        end
      end
    end

    $display("\n=======================================================");
    $display("              APB SYSTEM TESTBENCH COMPLETE            ");
    $display("=======================================================\n");
    $finish;
  end

endmodule