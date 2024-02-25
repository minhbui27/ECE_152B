`timescale 1ns / 1ps


module spi_master #(
    localparam FREQUENCY_RATIO = 16,
    localparam TRANSITION_WIDTH = 32,
    localparam CTRL_CONF = 1,
    localparam CTRL_TRAN = 2
)(
    input               clk,
    input               rst_n,
    input  logic [31:0] ctrl,
    input  logic [31:0] data_tx,
    input  logic        spi_i,
    
    output logic  [31:0] data_rd,
    
    output logic         spi_clk,
    output logic         cs_n,
    output logic         spi_o
    );
    
    enum logic [2:0] {IDLE = 0, SET = 1, TRANSITION = 2} state, nextState;
    logic [3:0] spi_clk_counter_d, spi_clk_counter_q;
    logic [$clog2(TRANSITION_WIDTH):0] shift_counter_d, shift_counter_q;
    logic [TRANSITION_WIDTH-1:0] shift_reg_q, shift_reg_d, data_out_d, data_out_q;
    logic w_once_q, w_once_d;
    logic in_buffer;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            spi_clk_counter_q <= '0;
            w_once_q <= 0;
            shift_reg_q <= '0;
            shift_counter_q <= '0;
            data_out_q <= '0;
        end 
        else begin
            w_once_q <= w_once_d;
            shift_reg_q <= shift_reg_d;
            state <= nextState;
            spi_clk_counter_q <= spi_clk_counter_d;
            shift_counter_q <= shift_counter_d;
            data_out_q <= data_out_d;
        end
    end
    
    // spi_clk is high when counter is >= half of freq ratio
    assign spi_clk = spi_clk_counter_q >= (FREQUENCY_RATIO >> 1);
    
    // data_rd is always equal to data_out reg
    assign data_rd = data_out_q;
    
    // spi out to slave is pulled to MSB of shift reg, and slave can sample this async relative to master
    assign spi_o = shift_reg_q[TRANSITION_WIDTH-1];
    
    always_comb begin : state_decode
        nextState = state;
        w_once_d = w_once_q;
        shift_reg_d = shift_reg_q;
        spi_clk_counter_d = 0;
        shift_counter_d = shift_counter_q;
        cs_n = 1;
        data_out_d = data_out_q;
        case(state)
            IDLE: begin
                nextState = SET;
                shift_reg_d = '0;
                w_once_d = 0;
                shift_counter_d = '0;
            end
            SET: begin
                // handle the control logic based on the config values
                if(ctrl == CTRL_CONF) begin
                    shift_reg_d = data_tx;
                    w_once_d = 1;
                end
                if(ctrl == CTRL_TRAN && w_once_d == 1) begin
                    nextState = TRANSITION;
                end
            end
            TRANSITION: begin
                cs_n = 0;
                // Handle the spi clock counter
                if(spi_clk_counter_q == FREQUENCY_RATIO - 1) begin
                    spi_clk_counter_d = 0;
                end
                else spi_clk_counter_d = spi_clk_counter_q + 1;
                
                // On rising edge of spi clock, sample the data from spi_i, and increment the shift counter
                if(spi_clk_counter_q == (FREQUENCY_RATIO >> 1)) begin
                    shift_counter_d = shift_counter_q + 1;
                    shift_reg_d = {shift_reg_q[TRANSITION_WIDTH-2:0],spi_i};
                end
                
                // If shift counter has reached data_width, and the spi_clk cycle has finished, then we are done
                // with transmission, so go to IDLE
                if(shift_counter_q == TRANSITION_WIDTH && (spi_clk_counter_q == FREQUENCY_RATIO - 1)) begin
                    nextState = IDLE;
                    data_out_d = shift_reg_d;
                end
            end
        endcase
    end

endmodule
    
