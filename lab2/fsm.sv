`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: UCSB
// Engineer: Minh Bui
// 
// Create Date: 01/28/2024 08:31:17 PM
// Design Name: Vending Machine FSM
// Module Name: fsm
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


module fsm(
    input       clk,
    input       rst,
    input       coin_in,
    input       cancel,
    // selection: 2'b00: no selection, 2'b01: water, 2'b10: coke, 2'b11: coffee;
    input logic [1:0] selection,
    // drink_out: 2'b00: none, 2'b01: dispense water, 2'b10: dispense coke, 2'b11: dispense coffee;
    output logic [1:0] drink_out,
    output logic [1:0] refund
    );
    // declaring two regs for coin_count and selection which are registers I choose to have
    logic [2:0] coin_count_q, coin_count_d;
    logic [2:0] selection_d, selection_q;
    
    // declaring the states
    enum logic [2:0] {IDLE = 0, PURCHASE = 1, REFUND = 2} state, nextState;
    
    // creating ff logic that resets all regs and state when async reset.
    always_ff @(posedge clk or posedge rst) begin : stateSequencer
        if(rst) begin
            state <= IDLE;
            coin_count_q <= 0;
            selection_q <= 0;
        end
        else begin
            state <= nextState;
            coin_count_q <= coin_count_d;
            selection_q <= selection_d;
        end
    end

    // creating the stateDecoder combinational circuit that determines next state and combinational output of each state.
    always_comb begin : stateDecoder
        nextState = state;
        drink_out = 0;
        refund = 0;
        coin_count_d = coin_count_q;
        selection_d = selection;
        // comb logic per state
        unique case(state)
            IDLE: begin 
                if(coin_in) begin
                    nextState = state.next;
                    coin_count_d = 1;
                end
                else nextState = state.first;
            end
            PURCHASE: begin
                if(cancel) nextState = state.next;
                else begin
                    // if the user can afford the selection, then move to the next state and output drink + refund
                    if(selection <= coin_count_q && selection > 0) nextState = state.next;
                    // if the user inserts a coin then update the coin counter accordingly
                    else if(coin_in) coin_count_d = coin_count_q < 3 ? coin_count_q + 1 : 3;
                    else nextState = state;
                end
            end
            REFUND: begin
                drink_out = selection;
                refund = coin_count_q - selection_q;
                coin_count_d = 0;
                nextState = state.next;
            end
        endcase
    end

endmodule

