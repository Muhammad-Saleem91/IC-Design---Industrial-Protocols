`timescale 1ns / 1ps

module tb_handshake_top();

    reg clk;
    reg rst_n;
    reg sw_valid;
    reg btn_ready;
    
    wire [3:0] leds;

    handshake_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .sw_valid(sw_valid),
        .btn_ready(btn_ready),
        .leds(leds)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("handshake.vcd");
        $dumpvars(0, tb_handshake_top);

        clk = 0;
        sw_valid = 0;
        btn_ready = 0;
        rst_n = 0;
        
        #20; 
        rst_n = 1;
        #20;

        btn_ready = 1;
        sw_valid = 0;
        #30; 
        btn_ready = 0; 
        #20;

        sw_valid = 1;
        #30; 

        btn_ready = 1; 
        #40; 

        sw_valid = 0;
        btn_ready = 0;
        #30;
        
        sw_valid = 1;
        #10;
        btn_ready = 1;
        #10;
        btn_ready = 0;
        sw_valid = 0;

        #50;
        $finish;
    end

endmodule