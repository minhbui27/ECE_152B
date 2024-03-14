`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/08/2024 11:02:51 PM
// Design Name: 
// Module Name: top_level
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_level (
    input clk,
    input rst_n
);

  // internal wires
  logic clk_sm;
  logic [31:0] doutb;
  logic [7:0] cpm_op_code, cpm_gpio_mult, cpm_gpio_add;
  logic [31:0] cpm_gpio_rd, cpm_rd_addr, cpm_rd_data;

  // defining probes
  logic [31:0] probe_bram_addr;
  logic [31:0] probe_bram_data;
  logic [ 7:0] probe_mult;
  logic [ 7:0] probe_add;
  logic [ 7:0] probe_op_code;
  logic [31:0] probe_gpio_rd;

  assign probe_mult = cpm_gpio_mult;
  assign probe_add = cpm_gpio_add;
  assign probe_op_code = cpm_op_code;
  assign probe_bram_addr = cpm_rd_addr;
  assign probe_bram_data = cpm_rd_data;
  assign probe_gpio_rd = cpm_gpio_rd;

  cpm cpm_i (
      .clk_sm(clk_sm),
      .rst_n(rst_n),
      .op_code(cpm_op_code),
      .gpio_mult(cpm_gpio_mult),
      .gpio_add(cpm_gpio_add),
      .gpio_rd(cpm_gpio_rd),
      .bram_rd_addr(cpm_rd_addr),
      .bram_rd_data(cpm_rd_data)
  );
  design_1_wrapper design_1_i (
      .BRAM_PORT_RD_addr(cpm_rd_addr),
      .BRAM_PORT_RD_en(1),
      .GPIO_CMDREG_tri_o(cpm_op_code),
      .GPIO_RD_tri_i(cpm_gpio_rd),
      .clk_sm(clk_sm),
      .gpio_mult_tri_o(cpm_gpio_mult),
      .gpio_offset_tri_o(cpm_gpio_add),
      .probe0_0(probe_bram_addr),
      .probe1_0(probe_bram_data),
      .probe2_0(probe_gpio_rd),
      .probe3_0(probe_op_code),
      .probe4_0(probe_mult),
      .probe5_0(probe_add),
      .doutb_0(cpm_rd_data),
      .reset(rst_n),
      .sys_clock(clk)
  );
endmodule

