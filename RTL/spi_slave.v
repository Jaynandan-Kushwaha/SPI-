/*`timescale 1ns/1ps

module spi_slave (
    input        clk,
    input        reset,

    input        sclk,
    input        cs,
    input        mosi,
    input [1:0]  spi_mode,

    output reg   miso,

    output reg [7:0] control_reg,
    output reg [7:0] data_reg,
    output reg [7:0] status_reg
);

reg sclk_prev;

reg [4:0] bit_count;

reg [7:0] header_shift;
reg [7:0] data_shift;

reg read_write;
reg [6:0] reg_addr;

reg [7:0] tx_shift;

reg response_loaded;

wire cpol;
wire cpha;

wire [7:0] header_next;
wire [7:0] data_next;

assign cpol = spi_mode[1];
assign cpha = spi_mode[0];

assign header_next = {
    header_shift[6:0],
    mosi
};

assign data_next = {
    data_shift[6:0],
    mosi
};


always @(posedge clk or posedge reset) begin

    if (reset) begin

        sclk_prev <= 1'b0;

        bit_count <= 5'd0;

        header_shift <= 8'h00;
        data_shift <= 8'h00;

        read_write <= 1'b0;
        reg_addr <= 7'h00;

        tx_shift <= 8'h00;
        response_loaded <= 1'b0;

        miso <= 1'b0;

        control_reg <= 8'h00;
        data_reg <= 8'h00;
        status_reg <= 8'h00;

    end

    else begin

        
        if (cs) begin

            sclk_prev <= sclk;

            bit_count <= 5'd0;

            header_shift <= 8'h00;
            data_shift <= 8'h00;

            read_write <= 1'b0;
            reg_addr <= 7'h00;

            tx_shift <= 8'h00;
            response_loaded <= 1'b0;

            miso <= 1'b0;

        end

        else begin

            
            if (sclk != sclk_prev) begin

                sclk_prev <= sclk;

               
                if (sclk != cpol) begin

                 
                    if (cpha == 1'b0) begin

                        if (bit_count < 5'd8) begin

                            header_shift <= header_next;

                            if (bit_count == 5'd7) begin

                                read_write <= header_next[7];
                                reg_addr <= header_next[6:0];

                                if (header_next[7]) begin

                                    case (header_next[6:0])

                                        7'h00:
                                            tx_shift <= 8'hA5;

                                        7'h01:
                                            tx_shift <= control_reg;

                                        7'h02:
                                            tx_shift <= status_reg;

                                        7'h03:
                                            tx_shift <= data_reg;

                                        default:
                                            tx_shift <= 8'hFF;

                                    endcase

                                    response_loaded <= 1'b1;

                                end

                            end

                        end

                        else begin

                            data_shift <= data_next;

                            if (bit_count == 5'd15) begin

                                if (!read_write) begin

                                    case (reg_addr)

                                        7'h01:
                                            control_reg <= data_next;

                                        7'h03:
                                            data_reg <= data_next;

                                        7'h00:
                                            status_reg[0] <= 1'b1;

                                        7'h02:
                                            status_reg[0] <= 1'b1;

                                        default:
                                            status_reg[0] <= 1'b1;

                                    endcase

                                end

                            end

                        end

                        bit_count <= bit_count + 1'b1;

                    end

                    
                    else begin

                        if (response_loaded) begin

                            miso <= tx_shift[7];

                            tx_shift <= {
                                tx_shift[6:0],
                                1'b0
                            };

                        end

                        else begin

                            miso <= 1'b0;

                        end

                    end

                end

                
                else begin

                   
                    if (cpha == 1'b0) begin

                        if (response_loaded) begin

                            miso <= tx_shift[7];

                            tx_shift <= {
                                tx_shift[6:0],
                                1'b0
                            };

                        end

                        else begin

                            miso <= 1'b0;

                        end

                    end

                    else begin

                        if (bit_count < 5'd8) begin

                            header_shift <= header_next;

                            if (bit_count == 5'd7) begin

                                read_write <= header_next[7];
                                reg_addr <= header_next[6:0];

                                if (header_next[7]) begin

                                    case (header_next[6:0])

                                        7'h00:
                                            tx_shift <= 8'hA5;

                                        7'h01:
                                            tx_shift <= control_reg;

                                        7'h02:
                                            tx_shift <= status_reg;

                                        7'h03:
                                            tx_shift <= data_reg;

                                        default:
                                            tx_shift <= 8'hFF;

                                    endcase

                                    response_loaded <= 1'b1;

                                end

                            end

                        end

                        else begin

                            data_shift <= data_next;

                            if (bit_count == 5'd15) begin

                                if (!read_write) begin

                                    case (reg_addr)

                                        7'h01:
                                            control_reg <= data_next;

                                        7'h03:
                                            data_reg <= data_next;

                                        7'h00:
                                            status_reg[0] <= 1'b1;

                                        7'h02:
                                            status_reg[0] <= 1'b1;

                                        default:
                                            status_reg[0] <= 1'b1;

                                    endcase

                                end

                            end

                        end

                        bit_count <= bit_count + 1'b1;

                    end

                end

            end

        end

    end

end

endmodule*/
`timescale 1ns/1ps

module spi_slave (
    input        clk,
    input        reset,

    input        sclk,
    input        cs,
    input        mosi,
    input [1:0]  spi_mode,

    output reg   miso,

    output reg [7:0] control_reg,
    output reg [7:0] data_reg,
    output reg [7:0] status_reg
);

reg sclk_prev;

reg [4:0] bit_count;

reg [7:0] header_shift;
reg [7:0] data_shift;

reg read_write;
reg [6:0] reg_addr;

reg [7:0] tx_shift;
reg response_loaded;

wire cpol;
wire cpha;

wire [7:0] header_next;
wire [7:0] data_next;

assign cpol = spi_mode[1];
assign cpha = spi_mode[0];

assign header_next = {
    header_shift[6:0],
    mosi
};

assign data_next = {
    data_shift[6:0],
    mosi
};

always @(posedge clk or posedge reset) begin

    if (reset) begin

        sclk_prev <= 1'b0;

        bit_count <= 5'd0;

        header_shift <= 8'h00;
        data_shift <= 8'h00;

        read_write <= 1'b0;
        reg_addr <= 7'h00;

        tx_shift <= 8'h00;
        response_loaded <= 1'b0;

        miso <= 1'b0;

        control_reg <= 8'h00;
        data_reg <= 8'h00;
        status_reg <= 8'h00;

    end

    else begin

        sclk_prev <= sclk;

        if (cs) begin

            bit_count <= 5'd0;

            header_shift <= 8'h00;
            data_shift <= 8'h00;

            read_write <= 1'b0;
            reg_addr <= 7'h00;

            tx_shift <= 8'h00;
            response_loaded <= 1'b0;

            miso <= 1'b0;

        end

        else if (sclk != sclk_prev) begin

            if (cpha == 1'b0) begin

                /*
                 * CPHA = 0
                 * Leading edge: sample MOSI
                 * Trailing edge: prepare MISO
                 */

                if (sclk != cpol) begin

                    if (bit_count < 5'd8) begin

                        header_shift <= header_next;

                        if (bit_count == 5'd7) begin

                            read_write <= header_next[7];
                            reg_addr <= header_next[6:0];

                            if (header_next[7]) begin

                                case (header_next[6:0])

                                    7'h00:
                                        tx_shift <= 8'hA5;

                                    7'h01:
                                        tx_shift <= control_reg;

                                    7'h02:
                                        tx_shift <= status_reg;

                                    7'h03:
                                        tx_shift <= data_reg;

                                    default:
                                        tx_shift <= 8'hFF;

                                endcase

                                response_loaded <= 1'b1;

                            end

                        end

                    end

                    else begin

                        data_shift <= data_next;

                        if (bit_count == 5'd15) begin

                            if (!read_write) begin

                                case (reg_addr)

                                    7'h01:
                                        control_reg <= data_next;

                                    7'h03:
                                        data_reg <= data_next;

                                    7'h00:
                                        status_reg[0] <= 1'b1;

                                    7'h02:
                                        status_reg[0] <= 1'b1;

                                    default:
                                        status_reg[0] <= 1'b1;

                                endcase

                            end

                        end

                    end

                    bit_count <= bit_count + 1'b1;

                end

                else begin

                    if (response_loaded) begin

                        miso <= tx_shift[7];

                        tx_shift <= {
                            tx_shift[6:0],
                            1'b0
                        };

                    end
                    else begin

                        miso <= 1'b0;

                    end

                end

            end

            else begin

                /*
                 * CPHA = 1
                 * Leading edge: prepare MISO
                 * Trailing edge: sample MOSI
                 */

                if (sclk != cpol) begin

                    if (response_loaded) begin

                        miso <= tx_shift[7];

                        tx_shift <= {
                            tx_shift[6:0],
                            1'b0
                        };

                    end
                    else begin

                        miso <= 1'b0;

                    end

                end

                else begin

                    if (bit_count < 5'd8) begin

                        header_shift <= header_next;

                        if (bit_count == 5'd7) begin

                            read_write <= header_next[7];
                            reg_addr <= header_next[6:0];

                            if (header_next[7]) begin

                                case (header_next[6:0])

                                    7'h00:
                                        tx_shift <= 8'hA5;

                                    7'h01:
                                        tx_shift <= control_reg;

                                    7'h02:
                                        tx_shift <= status_reg;

                                    7'h03:
                                        tx_shift <= data_reg;

                                    default:
                                        tx_shift <= 8'hFF;

                                endcase

                                response_loaded <= 1'b1;

                            end

                        end

                    end

                    else begin

                        data_shift <= data_next;

                        if (bit_count == 5'd15) begin

                            if (!read_write) begin

                                case (reg_addr)

                                    7'h01:
                                        control_reg <= data_next;

                                    7'h03:
                                        data_reg <= data_next;

                                    7'h00:
                                        status_reg[0] <= 1'b1;

                                    7'h02:
                                        status_reg[0] <= 1'b1;

                                    default:
                                        status_reg[0] <= 1'b1;

                                endcase

                            end

                        end

                    end

                    bit_count <= bit_count + 1'b1;

                end

            end

        end

    end

end

endmodule