
//edaTB_1.4
//randomEdition
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

module atm_tb();

  reg clk, reset, exit, language;
  reg [11:0] accountNum;
  reg [13:0] pin;
  reg action;
  reg rejected;
  reg [2:0] menuOption;
  reg [11:0] destinationAcc;
  reg [19:0] amount;
  wire [19:0] balance;
  wire error;

  ATM atmModule(clk, exit, reset, language, accountNum, pin, destinationAcc, menuOption, amount, error, balance, LANGUAGE_Output);

	//clk gen
  initial begin
    clk = 1'b0;
	forever
		#1 clk = ~clk;
	end
	
	
	
initial begin
  exit = 1'b0;
  reset = 1'b1;
  language = 1'b0;
  accountNum = 12'b0;
  pin = 12'b0;
  destinationAcc = 12'b0;
  menuOption = 4'b0;
  amount = 20'b0;

  // Direct Test Cases
  // Test case : Valid authentication
  accountNum = 12'd2178;
  pin = 13'd0100;
  action = `AUTHENTICATE;
  @(negedge clk);

  // Test case : Invalid authentication
  accountNum = 12'd1234;
  pin = 13'd5678;
  action = `AUTHENTICATE;
  @(negedge clk);

  // Test case : Language switch
  menuOption = `LANGUAGE_STATE;
  language = 1'b1;
  @(negedge clk);
  // Debugging statements
    

  // Test case : Find account
  destinationAcc = 12'd2816;
  action = `FOUND;
  @(negedge clk);

  // Test case : Withdrawal
  menuOption = `WITHDRAW;
  amount = 500;
  @(negedge clk);
  
  // Test case : Deposit
  menuOption = `DEPOSIT;
  amount = 200;
  @(negedge clk);

  // Test case : Transaction
  menuOption = `TRANSACTION;
  amount = 100;
  destinationAcc = 12'd1234;
  @(negedge clk);
  
   // Test case : Invalid withdrawal amount
  menuOption = `WITHDRAW;
  amount = 1500;
  @(negedge clk);

  // Test case : Invalid deposit amount
  menuOption = `DEPOSIT;
  amount = 3000;
  @(negedge clk);

  // Test case : Invalid transaction amount (exceeds balance limit)
  menuOption = `TRANSACTION;
  amount = 1500;
  destinationAcc = 12'd1234;
  @(negedge clk);

  // Test case : Invalid transaction (destination account not found)
  menuOption = `TRANSACTION;
  amount = 100;
  destinationAcc = 12'd9999;
  @(negedge clk);

  // Test case : Language switch back to English
  language = 1'b0;
  action = `LANGUAGE_STATE;
  @(negedge clk);
  
   // Test case : Exit
  exit = 1'b1;
  @(negedge clk);
  exit = 1'b0;
  @(negedge clk);

// Random Test Cases
  repeat (20) begin
    // Random authentication attempts
    accountNum = $random;
    pin = $random;
    action = `AUTHENTICATE;
    @(negedge clk);

    // Random language switch
    language = $random & 1'b1;
    action = `LANGUAGE_STATE;
    @(negedge clk);

    // Random find account attempts
    destinationAcc = $random;
    action = `FOUND;
    @(negedge clk);

    // Random withdrawal attempts
    menuOption = `WITHDRAW;
    amount = $random % 1000;
    @(negedge clk);

    // Random deposit attempts
    menuOption = `DEPOSIT;
    amount = $random % 1000;
    @(negedge clk);

    // Random transaction attempts
    menuOption = `TRANSACTION;
    amount = $random % 1000;
    destinationAcc = $random;
    @(negedge clk);
  end


$stop();
end
endmodule
