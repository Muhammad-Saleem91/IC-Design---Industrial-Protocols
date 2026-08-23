module master (
    input wire       presetn,          // Active-low reset
    input wire       pclk,             // Clock signal
    input wire       transfer,         // Transfer signal to initiate a transaction
    input wire       read,             // Read enable signal
    input wire       write,            // Write enable signal
    input wire [8:0] apb_write_paddr,  // Write address
    input wire [7:0] apb_write_data,   // Write data
    input wire [8:0] apb_read_paddr,   // Read address
    input wire       pready,           // Slave ready signal
    input wire       pslverr,          // Slave error signal
    input wire [7:0] prdata,           // Data from slave during read

    output reg       psel1,             // Select signal for slave 1
    output reg       psel2,             // Select signal for slave 2
    output reg       penable,           // Enable signal for the current transfer
    output reg       pwrite,            // Write signal (1 = write, 0 = read)
    output reg [8:0] paddr,             // Address signal for slave
    output reg [7:0] pwdata,            // Data to slave during write
    output reg [7:0] apb_read_data_out  // Data output during read
);

  // Internal state encoding
  parameter IDLE = 2'b00;
  parameter SETUP = 2'b01;
  parameter ENABLE = 2'b10;

  reg [1:0] state;  // Current state
  reg [1:0] next_state;  // Next state

  // Registered signals to hold values during ENABLE state
  reg       psel1_reg;
  reg       psel2_reg;
  reg       pwrite_reg;
  reg [8:0] paddr_reg;
  reg [7:0] pwdata_reg;
  reg       read_reg;  // To remember if current operation is read
  reg       transfer_reg;  // Register transfer signal to detect completion

  // Sequential state transition logic
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      state <= IDLE;
      // Reset registered signals
      psel1_reg <= 0;
      psel2_reg <= 0;
      pwrite_reg <= 0;
      paddr_reg <= 9'b0;
      pwdata_reg <= 8'b0;
      read_reg <= 0;
      transfer_reg <= 0;
      apb_read_data_out <= 8'b0;
    end else begin
      state <= next_state;
      transfer_reg <= transfer;

      // Latch values during SETUP state
      if (state == SETUP) begin
        if (read && !write) begin
          paddr_reg  <= apb_read_paddr;
          psel1_reg  <= (apb_read_paddr[8] == 0);
          psel2_reg  <= (apb_read_paddr[8] == 1);
          pwrite_reg <= 0;
          read_reg   <= 1;
          pwdata_reg <= 8'b0;  // Clear write data during read
        end else if (write && !read) begin
          paddr_reg  <= apb_write_paddr;
          psel1_reg  <= (apb_write_paddr[8] == 0);
          psel2_reg  <= (apb_write_paddr[8] == 1);
          pwrite_reg <= 1;
          pwdata_reg <= apb_write_data;
          read_reg   <= 0;
        end else begin
          // Neither read nor write - clear all
          psel1_reg  <= 0;
          psel2_reg  <= 0;
          pwrite_reg <= 0;
          paddr_reg  <= 9'b0;
          pwdata_reg <= 8'b0;
          read_reg   <= 0;
        end
      end

      // Clear registered signals when transfer completes
      if ((state == ENABLE) && pready) begin
        // Transfer complete - clear select signals
        // This ensures PSEL is only active during the transfer
        if (!transfer) begin
          psel1_reg <= 0;
          psel2_reg <= 0;
        end
      end

      // Capture read data during ENABLE state when pready is high
      if (state == ENABLE && pready && read_reg) begin
        apb_read_data_out <= prdata;
      end
    end
  end
  // Combinational next state logic
  always @(*) begin
    case (state)
      IDLE: begin
        if (transfer) next_state = SETUP;
        else next_state = IDLE;
      end
      SETUP: begin
        next_state = ENABLE;  // Always move to ENABLE from SETUP
      end
      ENABLE: begin
        if (pready) next_state = (transfer) ? SETUP : IDLE;
        else next_state = ENABLE;
      end
      default: next_state = IDLE;
    endcase
  end
  // Output and state-dependent control logic
  always @(*) begin
    // Default assignments to prevent latches
    psel1   = 0;
    psel2   = 0;
    penable = 0;
    pwrite  = 0;
    paddr   = 9'b0;
    pwdata  = 8'b0;
    case (state)
      IDLE: begin
        // No activity in IDLE
      end
      SETUP: begin
        penable = 0;
        if (read && !write) begin
          paddr  = apb_read_paddr;
          psel1  = (apb_read_paddr[8] == 0);
          psel2  = (apb_read_paddr[8] == 1);
          pwrite = 0;
          pwdata = 8'b0;  // Clear data during read
        end else if (write && !read) begin
          paddr  = apb_write_paddr;
          psel1  = (apb_write_paddr[8] == 0);
          psel2  = (apb_write_paddr[8] == 1);
          pwrite = 1;
          pwdata = apb_write_data;
        end else begin
          // No operation
          psel1  = 0;
          psel2  = 0;
          pwrite = 0;
          paddr  = 9'b0;
          pwdata = 8'b0;
        end
      end
      ENABLE: begin
        penable = 1;
        // Use registered values to maintain signals
        psel1   = psel1_reg;
        psel2   = psel2_reg;
        pwrite  = pwrite_reg;
        paddr   = paddr_reg;
        pwdata  = pwdata_reg;
      end
    endcase
  end
endmodule
