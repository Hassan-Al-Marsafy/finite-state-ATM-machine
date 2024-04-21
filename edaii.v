`define true 1'b1
`define false 1'b0

`define FOUND 1'b0
`define AUTHENTICATE 1'b1

`define WAITING               3'b000
`define IDLE                  3'b001
`define MENU                  3'b010
`define BALANCE               3'b011
`define WITHDRAW              3'b100
`define DEPOSIT               3'b101
`define TRANSACTION           3'b110
`define LANGUAGE_STATE        3'b111

`define ENGLISH       1'b0
`define FRENCH        1'b1

module Timers (
  input wire clk,
  input wire rst,
  output reg timerExpired
);
  reg [15:0] currentState;
  reg [15:0] nextState;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      currentState <= 16'd0;
      nextState <= 16'd0;
      timerExpired <= 1'b0;
    end 
    else begin
      currentState <= nextState;

      if (currentState < 16'b1111111111111111) begin
        nextState <= currentState + 1;
      end 
      else begin
        timerExpired <= 1'b1;
        nextState <= 16'd0; 
      end
    end
  end

endmodule

module authentication(
  input [11:0] accountNum,
  input [13:0] pin,
  input action,
  input rejected,
  output reg  isAuth,
  output reg [3:0] accIndex
);


  reg [11:0] account_Db [0:9];
  reg [13:0] pin_Db [0:9];

  //initializing the database with arbitrary accounts
  //PASSWORD MAXIMUM 999
  initial begin
    account_Db[0] = 12'd2749; pin_Db[0] = 13'd0000;
    account_Db[1] = 12'd2175; pin_Db[1] = 13'd0001;
    account_Db[2] = 12'd2429; pin_Db[2] = 13'd0010;
    account_Db[3] = 12'd2125; pin_Db[3] = 13'd0011;
    account_Db[4] = 12'd2178; pin_Db[4] = 13'd0100;
    account_Db[5] = 12'd2647; pin_Db[5] = 13'd0101;
    account_Db[6] = 12'd2816; pin_Db[6] = 13'd0110;
    account_Db[7] = 12'd2910; pin_Db[7] = 13'd0111;
    account_Db[8] = 12'd2299; pin_Db[8] = 13'd1000;
    account_Db[9] = 12'd2689; pin_Db[9] = 13'd1001;
    end

  always @ (posedge rejected) begin
    if(rejected == `true)
      isAuth = 1'bx;
  end

  integer i;
  always @(accountNum or pin) begin
      isAuth = `false;
      accIndex = 0;


      for(i = 0; i < 10; i = i+1) begin


          if(accountNum == account_Db[i]) begin
              
              if(action == `FOUND) begin
                isAuth = `true;
                accIndex = i;
              end

              if(action == `AUTHENTICATE) begin
                if(pin == pin_Db[i]) begin
                  isAuth = `true;
                  accIndex = i;

                end
              end
          end    
      end
  end

endmodule

//

module ATM(
  input clk,
  input exit,
  input reset,
  input language,
  input [11:0] accountNum,
  input [13:0] pin,
  input [11:0] destinationAcc, 
  input [2:0]menuOption,
  input [19:0] amount, 
  output reg error,
  output reg [19:0] balance,
  output reg LANGUAGE_Output
  );


  
  reg [19:0] balance_Db [0:9];
  initial begin
 
     balance_Db[0] = 20'd1000;
     balance_Db[1] = 20'd1000;
     balance_Db[2] = 20'd1000;
     balance_Db[3] = 20'd1000;
     balance_Db[4] = 20'd1000;
     balance_Db[5] = 20'd1000;
     balance_Db[6] = 20'd1000;
     balance_Db[7] = 20'd1000;
     balance_Db[8] = 20'd1000;
     balance_Db[9] = 20'd1000;

  end
  
  // Timer
  wire timerExpired;
  Timers timer_inst (
    .clk(clk),
    .rst(reset),
    .timerExpired(timerExpired)
  );
  
  reg [2:0] currState = `IDLE;
  reg [2:0] nextState = `WAITING;
  reg [2:0] timerState = `IDLE;
  
  wire [3:0] accIndex;
  wire [3:0] destinationAccIndex;
  wire isAuthenticated;
  wire wasFound;
  
  reg rejected = `false;

  authentication authaccountNumModule(accountNum, pin, `AUTHENTICATE, rejected, isAuthenticated, accIndex);
  authentication findaccountNumModule(destinationAcc, 0, `FOUND, rejected, wasFound, destinationAccIndex);


always@(posedge clk or negedge reset) begin
    if (!reset)begin
        currState<=`IDLE;
		timerState <= `IDLE;
    end
    else begin
        currState <= nextState;
		// Timer transitions
      case (timerState)
        `IDLE: timerState <= (currState == `LANGUAGE_STATE) ?
		`WAITING: timerState <= (timerExpired) ? `IDLE : `WAITING;
      endcase
	end
    end







  //main block of module with asynchronous exit

  always @( isAuthenticated or menuOption or exit or currState or accountNum or pin or amount or language) begin

    if(isAuthenticated==`false) begin
        currState=`WAITING;
        balance=20'b0;
        error=`true;
    end
	
	//timer expiration
	if (timerState == `WAITING && currState != `LANGUAGE_STATE) begin
      error = `true;  
      timerState = `IDLE; 
    end
    

	error = `false;
    if(exit == `true) begin

      nextState = `IDLE;

      rejected = `true;      
    end
    
    
    


      case (currState)


      `WAITING: begin
        if (isAuthenticated == `true) begin
          nextState = `LANGUAGE_STATE;

        end
        else if(isAuthenticated == `false) begin

          error=`true;
          nextState = `WAITING;
        end
      end


      `BALANCE: begin
        error=`false;
        balance = balance_Db[accIndex];

        nextState = `WAITING;
      end


      `DEPOSIT: begin
          
            balance_Db[accIndex] = balance_Db[accIndex] + amount;
            nextState = `WAITING;
            error = `false;
            balance = balance_Db[accIndex];
         
      end


      `WITHDRAW: begin
          if (amount <= balance_Db[accIndex]) begin
            balance_Db[accIndex] = balance_Db[accIndex] - amount;
            balance = balance_Db[accIndex];
            nextState = `WAITING;
            error = `false;

          end
          else begin
            nextState = `WAITING;
            error = `true;
          end
      end


      `TRANSACTION: begin
        if ((amount <= balance_Db[accIndex]) & (wasFound == `true) & (balance_Db[accIndex] + amount < 2048)) begin
            currState = `MENU;
            error = `false;
            balance_Db[destinationAccIndex] = balance_Db[destinationAccIndex] + amount;
            balance_Db[accIndex] = balance_Db[accIndex] - amount;

        end
        else begin
            currState = `MENU;
            error = `true;
        end
      end

      `MENU:begin
        if((menuOption >= 0) & (menuOption <= 7))begin 
        currState = menuOption;
      end else
      currState = menuOption;
      end

      `IDLE:begin
        nextState=`WAITING;
      end

      `LANGUAGE_STATE: begin
	nextState=`MENU;
    if(language == 0) begin 
        LANGUAGE_Output = `ENGLISH;
    end
    else if(language == 1) begin
        LANGUAGE_Output = `FRENCH;
    end
    else begin
        LANGUAGE_Output = `ENGLISH; 
    end

	end

    endcase 
		

  end
 // psl assert always((!reset) -> next(currState == `IDLE )) @(posedge clk);
 // psl assert always((exit == `true) -> next(nextState == `IDLE )) @(posedge clk);
 // psl assert always((currState == `WAITING && isAuthenticated == `true ) -> next(nextState == `LANGUAGE_STATE )) @(posedge clk);
 // psl assert always((currState == `WAITING && isAuthenticated == `false ) -> next(nextState == `WAITING )) @(posedge clk);
 // psl assert always((currState == `BALANCE) -> next(nextState == `WAITING && balance == balance_Db[accIndex] )) @(posedge clk);
 // psl assert always((currState == `DEPOSIT ) -> next(nextState == `WAITING && balance_Db[accIndex] == balance_Db[accIndex] + amount )) @(posedge clk);
 // psl assert always((currState == `IDLE ) -> next(nextState == `WAITING )) @(posedge clk);
endmodule
