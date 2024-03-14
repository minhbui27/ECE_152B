/*
*		TITLE: CPM
*		AUTHOR: Minh Bui @UCSB'W24
*		DESCRIPTION: command processor module (CPM) final project
*   which reads from rom (written with tcl) and 2 gpio ports, and execute the command given by opcode
*   then writes output to 1 of the 2 gpio ports
*
*/
`timescale 1 ps / 1 ps

module cpm #(
    localparam OP_READ  = 2'b00,
    localparam OP_COMPL = 2'b01,
    localparam OP_ADD   = 2'b10,
    localparam OP_MULT  = 2'b11,
    localparam MEM_BASE = 32'hC0000000
) (
    input logic clk_sm,
    input logic clk_100Mhz,
    input logic rst_n,
    input logic [7:0] op_code,
    input logic [7:0] gpio_mult,
    input logic [7:0] gpio_add,
    output logic [31:0] gpio_rd,
    output logic [31:0] bram_rd_addr,
    input logic [31:0] bram_rd_data
);

  enum logic [2:0] {
    IDLE = 0,
    MEM_READ = 1,
    EXECUTE = 2,
    OUT = 3
  }
      state, nextState;
  logic [7:0] op_code_q_1, op_code_q_2;
  logic [7:0] op_code_exec_q, op_code_exec_d;
  logic [31:0] gpio_rd_q_1, gpio_rd_q_2, gpio_rd_d_1;
  logic [31:0] mem_rd_addr_d, mem_rd_data_q, mem_rd_data_d;
  logic [7:0] gpio_mult_d, gpio_mult_q, gpio_add_d, gpio_add_q;

  assign gpio_rd = gpio_rd_q_2;

  // Adding 1 pipeline stage for gpio add and mult inputs from gpio
  always_ff @(posedge clk_sm or negedge rst_n) begin
    if (~rst_n) begin
      gpio_add_q  <= '0;
      gpio_mult_q <= '0;
    end else begin
      gpio_add_q  <= gpio_add;
      gpio_mult_q <= gpio_mult;
    end
  end

  // Implementing 2DFF synchronizer for cmdreg input 
  always_ff @(posedge clk_sm or negedge rst_n) begin
    if (~rst_n) begin
      op_code_q_1 <= '0;
      op_code_q_2 <= '0;
      gpio_rd_q_2 <= '0;
    end else begin
      gpio_rd_q_2 <= gpio_rd_d_1;
      op_code_q_2 <= op_code_q_1;
      op_code_q_1 <= op_code;
    end
  end

  // state sequencer and decoder
  always_ff @(posedge clk_sm or negedge rst_n) begin : stateSequencer
    if (~rst_n) begin
      state <= IDLE;
      mem_rd_data_q <= '0;
      op_code_exec_q <= '0;
    end else begin
      state <= nextState;
      mem_rd_data_q <= mem_rd_data_d;
      op_code_exec_q <= op_code_exec_d;
    end
  end

  always_comb begin : stateDecoder
    nextState = state;
    gpio_rd_d_1 = gpio_rd_q_2;
    op_code_exec_d = op_code_exec_q;
    mem_rd_data_d = mem_rd_data_q;
    bram_rd_addr = 0;
    unique case (state)
      IDLE: begin
        if (~op_code_q_2[0] && op_code_q_1[0]) begin
          nextState = state.next;
          op_code_exec_d = op_code_q_2;
        end
      end
      MEM_READ: begin
        bram_rd_addr = MEM_BASE + (op_code_exec_q[5:3] << 2);
        nextState = state.next;
      end
      EXECUTE: begin
        mem_rd_data_d = bram_rd_data;
        unique case (op_code_exec_q[7:6])
          OP_READ: begin
            gpio_rd_d_1 = mem_rd_data_d;
          end
          OP_MULT: begin
            gpio_rd_d_1 = mem_rd_data_d * gpio_mult_q;
          end
          OP_ADD: begin
            gpio_rd_d_1 = mem_rd_data_d + 32'(gpio_add_q);
          end
          OP_COMPL: begin
            gpio_rd_d_1 = ~mem_rd_data_d;
          end
        endcase
        nextState = state.next;
      end
      OUT: begin
        if (~op_code[0]) begin
          nextState = state.next;
        end
      end
    endcase
  end

endmodule


