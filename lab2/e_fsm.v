`timescale 1ns / 1ps

module fsm(
    input wire       clk,
    input wire       rst,
    input wire       coin_in,
    input wire       cancel,
    // selection: 2'b00: no selection, 2'b01: water, 2'b10: coke, 2'b11: coffee;
    input wire [1:0] selection,
    // drink_out: 2'b00: none, 2'b01: dispense water, 2'b10: dispense coke, 2'b11: dispense coffee;
    output reg [1:0] drink_out,
    output reg [1:0] refund
    );


// Use traffic light controller as a kind of skeleton for this

// Define states; total of three. What is the machine doing? 
parameter IDLE = 2'b00; // Idle (not doing anything)
parameter ACCEPTING_COINS = 2'b01; // Accepting coins
parameter USER_INPUT_NEEDED = 2'b10; // Waiting for user input
parameter REFUND_COINS = 2'b11; // Refunding coins

// Now that we have defined the states, we need to set constants for each drink price.
parameter water_price = 1;
parameter coke_price = 2;
parameter coffee_price = 3;

// Define internal registers to store various state and data information necessary for operation
reg [1:0] state;
reg [1:0] coins_inserted;
reg [1:0] selected_drink;

// Now begin the processes
always @(posedge clk, posedge rst)
   if (rst) begin
      state <= IDLE;
      drink_out <= 2'b00;
      refund <= 2'b00;
      coins_inserted <= 2'b00;
      selected_drink <= 2'b00;
   end else begin
      case (state)
         //Start with the idle state
         IDLE : begin
            if (coin_in && (coins_inserted < 2'b11)) begin
               state <= ACCEPTING_COINS;
               coins_inserted <= coins_inserted + 1;
            end else if (cancel) begin
               //Cancel the purchase and refund the coins
               state <= REFUND_COINS;
               refund <= coins_inserted;
               coins_inserted <= 2'b00;
            end else if (selection != 2'b00) begin
               //User has made a selection, but no coins inserted, do nothing
            end
         end
         
         ACCEPTING_COINS: begin
            //keep accepting coins, allow a max of 3
            if (coin_in && (coins_inserted < 2'b11)) begin
               coins_inserted <= coins_inserted + 1;
            end else if (coin_in) begin
               // Max coins inserted, stay in accepting coins
            end else if (cancel) begin
               // Cancel purchase and refund coins
               state <= REFUND_COINS;
               refund <= coins_inserted;
               coins_inserted <= 2'b00;
            end else if (selection != 2'b00) begin
               // User made a selection, move to waiting for user action
               state <= USER_INPUT_NEEDED;
               selected_drink <= selection;
            end
         end
         
         USER_INPUT_NEEDED: begin
         // Wait for user action after coins have been inserted
            if (cancel) begin
               // Cancel purchase, refund coins
               state <= REFUND_COINS;
               refund <= coins_inserted;
               coins_inserted <= 2'b00;
            end else if (selection != 2'b00) begin
               // User made a selection
               case (selected_drink)
                  2'b01: if (coins_inserted >= water_price) begin
                     drink_out <= selected_drink;
                     coins_inserted <= coins_inserted - water_price;
                     state <= IDLE;
                  end
                  
                  2'b10: if (coins_inserted >= coke_price) begin
                     drink_out <= selected_drink;
                     coins_inserted <= coins_inserted - coke_price;
                     state <= IDLE;
                     end
                 
                 2'b11: if (coins_inserted >= coffee_price) begin
                    drink_out <= selected_drink;
                    coins_inserted <= coins_inserted - coffee_price;
                    state <= IDLE;
                    end 
              default: //Invalid selection, do nothing
           endcase
        end
    end
         
         REFUND_COINS: begin
            // Refund coins and return to idle state
            coins_inserted <= 2'b00;
            refund <= 2'b00;
            state <= IDLE;
         end
         
         default: begin
            // Default to idle if state undefined
            state <= IDLE;
         end
      endcase
   end


endmodule

