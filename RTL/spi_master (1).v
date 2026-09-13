`timescale 1ns/1ps

module spi_master (
    input        clk,
    input        reset,
    input        start,
    input [15:0] tx_data,
    input        transfer_16,
    input [1:0]  spi_mode,
    input [15:0] clk_div,
    input        miso,
    output reg [15:0] rx_data,
    output reg        busy,
    output reg        done,
    output reg        error,
    output reg        mosi,
    output reg        sclk,
    output reg        cs
);

localparam TIMEOUT_CYCLES = 1000;

reg [15:0] tx_shift;
reg [15:0] rx_shift;
reg [15:0] divider_value;
reg [15:0] div_count;
reg [31:0] timeout_count;
reg [4:0] bit_count;
reg width16;
reg [1:0] mode;
reg finish_after_sample;

wire cpol;
wire cpha;
wire last_bit;

assign cpol = mode[1];
assign cpha = mode[0];
assign last_bit = width16 ? (bit_count == 5'd15) : (bit_count == 5'd7);

always @(negedge clk or posedge reset) begin
    if (reset) begin
        tx_shift <= 16'h0000;
        rx_shift <= 16'h0000;
        rx_data <= 16'h0000;
        divider_value <= 16'd2;
        div_count <= 16'd0;
        timeout_count <= 32'd0;
        bit_count <= 5'd0;
        width16 <= 1'b1;
        mode <= 2'b00;
        finish_after_sample <= 1'b0;
        busy <= 1'b0;
        done <= 1'b0;
        error <= 1'b0;
        mosi <= 1'b0;
        sclk <= 1'b0;
        cs <= 1'b1;
    end
    else begin
        done <= 1'b0;

        if (!busy) begin
            cs <= 1'b1;
            sclk <= cpol;
            mosi <= 1'b0;
            div_count <= 16'd0;
            timeout_count <= 32'd0;
            finish_after_sample <= 1'b0;

            if (start) begin
                busy <= 1'b1;
                error <= 1'b0;
                cs <= 1'b0;
                mode <= spi_mode;
                width16 <= transfer_16;

                if (clk_div < 16'd2)
                    divider_value <= 16'd2;
                else
                    divider_value <= clk_div;

                tx_shift <= tx_data;
                rx_shift <= 16'h0000;
                bit_count <= 5'd0;
                sclk <= spi_mode[1];

                if (spi_mode[0] == 1'b0) begin
                    if (transfer_16)
                        mosi <= tx_data[15];
                    else
                        mosi <= tx_data[7];
                end
                else begin
                    mosi <= 1'b0;
                end
            end
        end
        else begin
            if (start)
                error <= 1'b1;

            if (timeout_count >= TIMEOUT_CYCLES) begin
                busy <= 1'b0;
                done <= 1'b1;
                error <= 1'b1;
                cs <= 1'b1;
                sclk <= cpol;
                mosi <= 1'b0;
                div_count <= 16'd0;
                timeout_count <= 32'd0;
                bit_count <= 5'd0;
            end
            else begin
                timeout_count <= timeout_count + 1'b1;

                if (div_count >= divider_value - 1'b1) begin
                    div_count <= 16'd0;

                    // leading edge
                    if (sclk == cpol) begin
                        // deferred completion for CPHA=1, one half period after the last sample
                        if (finish_after_sample) begin
                            busy <= 1'b0;
                            done <= 1'b1;
                            cs <= 1'b1;
                            sclk <= cpol;
                            mosi <= 1'b0;
                            finish_after_sample <= 1'b0;
                            timeout_count <= 32'd0;
                            bit_count <= 5'd0;
                        end
                        // CPHA=0: sample MISO
                        else if (cpha == 1'b0) begin
                            rx_shift <= {rx_shift[14:0], miso};

                            if (last_bit) begin
                                rx_data <= {rx_shift[14:0], miso};
                                finish_after_sample <= 1'b1;
                            end
                            else begin
                                bit_count <= bit_count + 1'b1;
                            end
                        end
                        // CPHA=1: change MOSI
                        else begin
                            if (width16) begin
                                mosi <= tx_shift[15];
                                tx_shift <= {tx_shift[14:0], 1'b0};
                            end
                            else begin
                                mosi <= tx_shift[7];
                                tx_shift <= {8'h00, tx_shift[7:1]};
                            end
                        end

                        if (!finish_after_sample)
                            sclk <= ~sclk;
                    end
                    // trailing edge
                    else begin
                        // CPHA=0: change MOSI
                        if (cpha == 1'b0) begin
                            if (finish_after_sample) begin
                                busy <= 1'b0;
                                done <= 1'b1;
                                cs <= 1'b1;
                                sclk <= cpol;
                                mosi <= 1'b0;
                                finish_after_sample <= 1'b0;
                                timeout_count <= 32'd0;
                                bit_count <= 5'd0;
                            end
                            else begin
                                if (width16) begin
                                    tx_shift <= {tx_shift[14:0], 1'b0};
                                    mosi <= tx_shift[14];
                                end
                                else begin
                                    tx_shift <= {8'h00, tx_shift[6:0]};
                                    mosi <= tx_shift[6];
                                end

                                sclk <= ~sclk;
                            end
                        end
                        // CPHA=1: sample MISO, defer completion to next leading edge
                        else begin
                            rx_shift <= {rx_shift[14:0], miso};

                            if (last_bit) begin
                                rx_data <= {rx_shift[14:0], miso};
                                finish_after_sample <= 1'b1;
                                sclk <= ~sclk;
                            end
                            else begin
                                bit_count <= bit_count + 1'b1;
                                sclk <= ~sclk;
                            end
                        end
                    end
                end
                else begin
                    div_count <= div_count + 1'b1;
                end
            end
        end
    end
end

endmodule
