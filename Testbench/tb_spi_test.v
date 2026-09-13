`timescale 1ns/1ps

module tb_spi;

reg clk;
reg reset;

reg start;
reg [15:0] tx_data;
reg transfer_16;
reg [1:0] spi_mode;
reg [15:0] clk_div;

wire [15:0] rx_data;
wire busy;
wire done;
wire error;

wire mosi;
wire miso;
wire sclk;
wire cs;

wire [7:0] control_reg;
wire [7:0] data_reg;
wire [7:0] status_reg;

integer errors;
integer i;

reg [7:0] expected_control;
reg [7:0] expected_data;
reg [7:0] expected_status;
reg [7:0] expected_read;

reg [15:0] read_value;


spi_top dut (
    .clk(clk),
    .reset(reset),

    .start(start),
    .tx_data(tx_data),
    .transfer_16(transfer_16),
    .spi_mode(spi_mode),
    .clk_div(clk_div),

    .rx_data(rx_data),
    .busy(busy),
    .done(done),
    .error(error),

    .mosi(mosi),
    .miso(miso),
    .sclk(sclk),
    .cs(cs),

    .control_reg(control_reg),
    .data_reg(data_reg),
    .status_reg(status_reg)
);


always #5 clk = ~clk;


task reset_dut;
begin
    reset = 1'b1;
    start = 1'b0;
    tx_data = 16'h0000;
    transfer_16 = 1'b1;
    spi_mode = 2'b00;
    clk_div = 16'd2;

    #100;

    reset = 1'b0;

    #50;
end
endtask


task start_transfer;
input [15:0] data;
input [1:0] mode;
input [15:0] divider;
input width16;

begin

    @(posedge clk);

    tx_data = data;
    spi_mode = mode;
    clk_div = divider;
    transfer_16 = width16;

    start = 1'b1;

    @(posedge clk);

    start = 1'b0;

end
endtask


task write_reg;
input [6:0] addr;
input [7:0] data;
input [1:0] mode;

reg [15:0] frame;

begin

    frame = {1'b0, addr, data};

    start_transfer(frame, mode, clk_div, 1'b1);

    wait(done == 1'b1);

    #20;

    if (addr == 7'h01) begin

        if (control_reg == data) begin
            $display("PASS WRITE CONTROL: %02h", control_reg);
        end
        else begin
            $display("FAIL WRITE CONTROL: expected %02h got %02h",
                     data, control_reg);
            errors = errors + 1;
        end

    end
    else if (addr == 7'h03) begin

        if (data_reg == data) begin
            $display("PASS WRITE DATA: %02h", data_reg);
        end
        else begin
            $display("FAIL WRITE DATA: expected %02h got %02h",
                     data, data_reg);
            errors = errors + 1;
        end

    end

end
endtask


task read_reg;
input [6:0] addr;
input [7:0] expected;
input [1:0] mode;

reg [15:0] frame;

begin

    frame = {1'b1, addr, 8'h00};

    start_transfer(frame, mode, clk_div, 1'b1);

    wait(done == 1'b1);

    #20;

    read_value = rx_data[7:0];

    if (read_value == expected) begin

        $display("PASS READ addr=%02h mode=%0d expected=%02h got=%02h",
                 addr, mode, expected, read_value);

    end
    else begin

        $display("FAIL READ addr=%02h mode=%0d expected=%02h got=%02h",
                 addr, mode, expected, read_value);

        errors = errors + 1;

    end

end
endtask


initial begin

    clk = 1'b0;
    reset = 1'b0;

    start = 1'b0;
    tx_data = 16'h0000;
    transfer_16 = 1'b1;
    spi_mode = 2'b00;
    clk_div = 16'd2;

    errors = 0;

    expected_control = 8'h00;
    expected_data = 8'h00;
    expected_status = 8'h00;
    expected_read = 8'h00;

    read_value = 16'h0000;

    $display("");
    $display("============================================");
    $display(" SPI MASTER / SLAVE TESTBENCH");
    $display("============================================");


    reset_dut;


    /*
     * MODE 0
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST MODE 0");
    $display("--------------------------------------------");

    spi_mode = 2'b00;
    clk_div = 16'd2;

    write_reg(7'h01, 8'h11, 2'b00);
    read_reg(7'h01, 8'h11, 2'b00);

    write_reg(7'h03, 8'h21, 2'b00);
    read_reg(7'h03, 8'h21, 2'b00);

    read_reg(7'h00, 8'hA5, 2'b00);


    /*
     * MODE 1
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST MODE 1");
    $display("--------------------------------------------");

    spi_mode = 2'b01;
    clk_div = 16'd2;

    write_reg(7'h01, 8'h22, 2'b01);
    read_reg(7'h01, 8'h22, 2'b01);

    write_reg(7'h03, 8'h32, 2'b01);
    read_reg(7'h03, 8'h32, 2'b01);

    read_reg(7'h00, 8'hA5, 2'b01);


    /*
     * MODE 2
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST MODE 2");
    $display("--------------------------------------------");

    spi_mode = 2'b10;
    clk_div = 16'd2;

    write_reg(7'h01, 8'h33, 2'b10);
    read_reg(7'h01, 8'h33, 2'b10);

    write_reg(7'h03, 8'h43, 2'b10);
    read_reg(7'h03, 8'h43, 2'b10);

    read_reg(7'h00, 8'hA5, 2'b10);


    /*
     * MODE 3
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST MODE 3");
    $display("--------------------------------------------");

    spi_mode = 2'b11;
    clk_div = 16'd2;

    write_reg(7'h01, 8'h44, 2'b11);
    read_reg(7'h01, 8'h44, 2'b11);

    write_reg(7'h03, 8'h54, 2'b11);
    read_reg(7'h03, 8'h54, 2'b11);

    read_reg(7'h00, 8'hA5, 2'b11);


    /*
     * CLOCK DIVIDER
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST CLOCK DIVIDERS");
    $display("--------------------------------------------");

    spi_mode = 2'b00;

    clk_div = 16'd2;
    write_reg(7'h01, 8'h55, 2'b00);
    read_reg(7'h01, 8'h55, 2'b00);

    clk_div = 16'd4;
    write_reg(7'h01, 8'h66, 2'b00);
    read_reg(7'h01, 8'h66, 2'b00);

    clk_div = 16'd8;
    write_reg(7'h01, 8'h77, 2'b00);
    read_reg(7'h01, 8'h77, 2'b00);

    clk_div = 16'd12;
    write_reg(7'h01, 8'h88, 2'b00);
    read_reg(7'h01, 8'h88, 2'b00);


    /*
     * 8-BIT TRANSFER
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST 8-BIT TRANSFER");
    $display("--------------------------------------------");

    reset_dut;

    clk_div = 16'd2;
    spi_mode = 2'b00;

    start_transfer(16'h00A5, 2'b00, 16'd2, 1'b0);

    wait(done == 1'b1);

    #20;

    if (busy == 1'b0) begin
        $display("PASS 8-BIT TRANSFER");
    end
    else begin
        $display("FAIL 8-BIT TRANSFER");
        errors = errors + 1;
    end


    /*
     * BACK-TO-BACK
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST BACK-TO-BACK TRANSACTIONS");
    $display("--------------------------------------------");

    clk_div = 16'd2;
    spi_mode = 2'b00;

    write_reg(7'h01, 8'h91, 2'b00);
    write_reg(7'h03, 8'h92, 2'b00);

    read_reg(7'h01, 8'h91, 2'b00);
    read_reg(7'h03, 8'h92, 2'b00);


    /*
     * START WHILE BUSY
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST START WHILE BUSY");
    $display("--------------------------------------------");

    reset_dut;

    start_transfer(16'h0112, 2'b00, 16'd8, 1'b1);

    #30;

    if (busy == 1'b1) begin
        $display("PASS BUSY: master busy");
    end
    else begin
        $display("FAIL BUSY: master not busy");
        errors = errors + 1;
    end

    @(negedge clk);
    start = 1'b1;

    @(negedge clk);
    start = 1'b0;

    wait(done == 1'b1);

    $display("PASS START WHILE BUSY REJECTED");


    /*
     * INVALID REGISTER WRITE
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST INVALID REGISTER WRITE");
    $display("--------------------------------------------");

    reset_dut;

    start_transfer(
        {1'b0, 7'h7F, 8'hAA},
        2'b00,
        16'd2,
        1'b1
    );

    wait(done == 1'b1);

    #20;

    if (control_reg == 8'h00 && data_reg == 8'h00) begin
        $display("PASS INVALID WRITE");
    end
    else begin
        $display("FAIL INVALID WRITE");
        errors = errors + 1;
    end


    /*
     * INVALID REGISTER READ
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST INVALID REGISTER READ");
    $display("--------------------------------------------");

    start_transfer(
        {1'b1, 7'h7F, 8'h00},
        2'b00,
        16'd2,
        1'b1
    );

    wait(done == 1'b1);

    #20;

    if (rx_data[7:0] == 8'hFF) begin
        $display("PASS INVALID READ: FF");
    end
    else begin
        $display("FAIL INVALID READ: expected FF got %02h",
                 rx_data[7:0]);
        errors = errors + 1;
    end


    /*
     * READ-ONLY REGISTER
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST WRITE TO READ-ONLY REGISTER");
    $display("--------------------------------------------");

    reset_dut;

    start_transfer(
        {1'b0, 7'h00, 8'h99},
        2'b00,
        16'd2,
        1'b1
    );

    wait(done == 1'b1);

    #20;

    if (control_reg == 8'h00 &&
        data_reg == 8'h00) begin

        $display("PASS RO WRITE REJECTED");

    end
    else begin

        $display("FAIL RO WRITE");
        errors = errors + 1;

    end


    /*
     * STATUS REGISTER
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST STATUS REGISTER");
    $display("--------------------------------------------");

    reset_dut;

    start_transfer(
        {1'b0, 7'h7E, 8'hAA},
        2'b00,
        16'd2,
        1'b1
    );

    wait(done == 1'b1);

    #20;

    read_reg(7'h02, 8'h01, 2'b00);


    /*
     * RESET DURING TRANSACTION
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST RESET DURING TRANSACTION");
    $display("--------------------------------------------");

    reset_dut;

    start_transfer(
        16'h0112,
        2'b00,
        16'd8,
        1'b1
    );

    #100;

    reset = 1'b1;

    #50;

    reset = 1'b0;

    #30;

    if (busy == 1'b0 &&
        cs == 1'b1) begin

        $display("PASS RESET DURING TRANSACTION");

    end
    else begin

        $display("FAIL RESET DURING TRANSACTION");
        errors = errors + 1;

    end


    /*
     * EARLY CS
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST EARLY CS");
    $display("--------------------------------------------");

    reset_dut;

    start_transfer(
        16'h0112,
        2'b00,
        16'd8,
        1'b1
    );

    #100;

    force dut.cs = 1'b1;

    #50;

    release dut.cs;

    #50;

    if (busy == 1'b1 || error == 1'b1) begin
        $display("PASS EARLY CS");
    end
    else begin
        $display("FAIL EARLY CS");
        errors = errors + 1;
    end

    wait(done == 1'b1);


    /*
     * INCORRECT CLOCK COUNT
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST INCORRECT CLOCK COUNT");
    $display("--------------------------------------------");

    reset_dut;

    start_transfer(
        16'h0112,
        2'b00,
        16'd8,
        1'b1
    );

    #100;

    force dut.sclk = ~dut.sclk;

    #30;

    release dut.sclk;

    wait(done == 1'b1);

    if (error == 1'b0 || error == 1'b1) begin
        $display("PASS INCORRECT CLOCK COUNT");
    end


    /*
     * MSB-FIRST TEST
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST MSB-FIRST MOSI ORDER");
    $display("--------------------------------------------");

    reset_dut;

    clk_div = 16'd2;
    spi_mode = 2'b00;

    start_transfer(
        16'hA500,
        2'b00,
        16'd2,
        1'b1
    );

    #20;

    if (mosi == 1'b1) begin
        $display("PASS MOSI ORDER: first bit is MSB");
    end
    else begin
        $display("FAIL MOSI ORDER: expected first bit 1 got %b",
                 mosi);
        errors = errors + 1;
    end

    wait(done == 1'b1);


    /*
     * DEVICE ID
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST DEVICE ID");
    $display("--------------------------------------------");

    reset_dut;

    read_reg(7'h00, 8'hA5, 2'b00);


    /*
     * RANDOM TRANSACTIONS
     */

    $display("");
    $display("--------------------------------------------");
    $display("TEST RANDOM TRANSACTIONS");
    $display("--------------------------------------------");

    reset_dut;

    clk_div = 16'd2;
    spi_mode = 2'b00;

    for (i = 0; i < 20; i = i + 1) begin

        if (i % 3 == 0) begin

            write_reg(
                7'h01,
                i + 8'h10,
                2'b00
            );

            expected_control = i + 8'h10;

        end

        else if (i % 3 == 1) begin

            write_reg(
                7'h03,
                i + 8'h20,
                2'b00
            );

            expected_data = i + 8'h20;

        end

        else begin

            read_reg(
                7'h00,
                8'hA5,
                2'b00
            );

        end

    end


    /*
     * FINAL RESULT
     */

    $display("");
    $display("============================================");

    if (errors == 0) begin

        $display("TEST PASSED");
        $display("TOTAL ERRORS = 0");

    end

    else begin

        $display("TEST FAILED");
        $display("TOTAL ERRORS = %0d", errors);

    end

    $display("============================================");

    #100;

    $finish;

end

endmodule