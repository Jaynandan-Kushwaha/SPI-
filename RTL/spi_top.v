`timescale 1ns/1ps

module spi_top (
    input        clk,
    input        reset,

    input        start,
    input [15:0] tx_data,
    input        transfer_16,
    input [1:0]  spi_mode,
    input [15:0] clk_div,

    output [15:0] rx_data,
    output        busy,
    output        done,
    output        error,

    output        mosi,
    output        miso,
    output        sclk,
    output        cs,

    output [7:0] control_reg,
    output [7:0] data_reg,
    output [7:0] status_reg
);

spi_master master_inst (
    .clk(clk),
    .reset(reset),

    .start(start),
    .tx_data(tx_data),
    .transfer_16(transfer_16),
    .spi_mode(spi_mode),
    .clk_div(clk_div),

    .miso(miso),

    .rx_data(rx_data),
    .busy(busy),
    .done(done),
    .error(error),

    .mosi(mosi),
    .sclk(sclk),
    .cs(cs)
);

spi_slave slave_inst (
    .clk(clk),
    .reset(reset),

    .sclk(sclk),
    .cs(cs),
    .mosi(mosi),
    .spi_mode(spi_mode),

    .miso(miso),

    .control_reg(control_reg),
    .data_reg(data_reg),
    .status_reg(status_reg)
);

endmodule