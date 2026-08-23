module handshake_top (
    input wire clk,
    input wire rst_n,
    input wire sw_valid,
    input wire btn_ready,
    output wire [3:0] leds
);

    wire internal_valid;
    wire internal_ready;
    wire [3:0] internal_data;

    producer prod_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ready(internal_ready),
        .valid_in(sw_valid),
        .valid_out(internal_valid),
        .data(internal_data)
    );

    consumer cons_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid(internal_valid),
        .ready_in(btn_ready),
        .data_in(internal_data),
        .ready_out(internal_ready),
        .leds(leds)
    );

endmodule