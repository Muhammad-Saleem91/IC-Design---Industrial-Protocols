`include "AHB_Lite_Master.v"
`include "AHB_Decoder.v"
`include "AHB_Slave_1.v"
`include "AHB_Slave_2.v"
`include "AHB_MUX.v"

module AHB_TOP (
    input        HCLK,
    input        HRESETn,
    // Processor-side interface
    input  [31:0] PADDR,
    input  [31:0] PWDATA,
    input         PWRITE,
    input  [2:0]  PSIZE,
    input  [1:0]  PTRANS,
    input  [2:0]  PBURST,
    output        PDONE
);

    wire [31:0] HADDR, HWDATA, HRDATA, HRDATA_1, HRDATA_2;
    wire        HWRITE, HREADY, HRESP, HRESP_Slave_1, HRESP_Slave_2;
    wire [2:0]  HSIZE, HBURST;
    wire [1:0]  HTRANS, HSELx_slaves, HSELx_Mux;
    wire        HREADYOUT_1, HREADYOUT_2;

    AHB_Lite_Master master (
        .HCLK(HCLK), .HRESETn(HRESETn),
        .PADDR(PADDR), .PWDATA(PWDATA), .PWRITE(PWRITE),
        .PSIZE(PSIZE), .PTRANS(PTRANS), .PBURST(PBURST),
        .HADDR(HADDR), .HWDATA(HWDATA), .HWRITE(HWRITE),
        .HSIZE(HSIZE), .HTRANS(HTRANS), .HBURST(HBURST),
        .HREADY(HREADY), .HRESP(HRESP), .HRDATA(HRDATA),
        .PDONE(PDONE)
    );

    AHB_Decoder decoder (
        .HADDR(HADDR),
        .HSELx_slaves(HSELx_slaves),
        .HSELx_Mux(HSELx_Mux)
    );

    AHB_Slave_1 slave1 (
        .HCLK(HCLK), .HRESETn(HRESETn),
        .HADDR(HADDR), .HWDATA(HWDATA),
        .HSELx_slaves(HSELx_slaves),
        .HWRITE(HWRITE), .HSIZE(HSIZE), .HTRANS(HTRANS),
        .HBURST(HBURST), .HREADY(HREADY),
        .HREADYOUT(HREADYOUT_1), .HRESP(HRESP_Slave_1), .HRDATA(HRDATA_1)
    );

    AHB_Slave_2 slave2 (
        .HCLK(HCLK), .HRESETn(HRESETn),
        .HADDR(HADDR), .HWDATA(HWDATA),
        .HSELx_slaves(HSELx_slaves),
        .HWRITE(HWRITE), .HSIZE(HSIZE), .HTRANS(HTRANS),
        .HBURST(HBURST), .HREADY(HREADY),
        .HREADYOUT(HREADYOUT_2), .HRESP(HRESP_Slave_2), .HRDATA(HRDATA_2)
    );

    AHB_MUX mux (
        .HCLK(HCLK), .HRESETn(HRESETn),
        .HRESP_Slave_1(HRESP_Slave_1), .HREADYOUT_1(HREADYOUT_1), .HRDATA_Slave_1(HRDATA_1),
        .HRESP_Slave_2(HRESP_Slave_2), .HREADYOUT_2(HREADYOUT_2), .HRDATA_Slave_2(HRDATA_2),
        .HSELx_Mux(HSELx_Mux),
        .HRDATA(HRDATA), .HREADY(HREADY), .HRESP(HRESP)
    );

endmodule
