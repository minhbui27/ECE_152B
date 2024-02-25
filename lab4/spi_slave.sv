`timescale 1ns / 1ps

module spi_slave(
    input  logic        spi_clk,
    input  logic        rst_n,
    input  logic        cs_n,
    input  logic        spi_i,
    
    output logic         spi_o
    );
    
    logic [31:0] sr;
    logic in_buffer;
    
    parameter sr_default = 32'h1234abcd;
    
    always_ff @(posedge spi_clk or negedge rst_n) begin
        if (!rst_n) begin
            in_buffer <= 1'b0;
        end
        else begin
            in_buffer <= spi_i;
        end
    end
    
    always_ff @(negedge spi_clk or negedge rst_n) begin
        if (!rst_n) begin
            sr <= sr_default;
        end
        else sr <= {sr[30:0], in_buffer};
    end
    
    always_comb begin
        spi_o = sr[31];
    end
    
endmodule

