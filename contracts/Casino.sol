pragma solidity 0.4.15;

library SafeMath {
  function mul(uint _a, uint _b) internal constant returns (uint c)
  { if (_a == 0) {
     return 0;
  }
    c = _a * _b;
    require(c / _a == _b);
    return c;
  }
  function div(uint _a, uint _b) internal constant returns (uint){
    require(_b > 0);
    return _a / _b;
  }
  function sub(uint _a, uint _b) internal constant returns (uint){
    require(_b <= _a);
    return _a - _b;
  }
  function add(uint _a, uint _b) internal constant returns (uint c){
    c = _a + _b;
    require(c >= _a);
    return c;
  }
}

contract Casino {
  using SafeMath for uint;
  address owner;
  
  // The minimum bet a user has to make to participate in the game
  uint public minimumBet = 1; // Equal to 1.00 AION
  
  // The maximum bet a user has to make to participate in the game
  uint public maximumBet = 100; // Equal to 100 AION
  
  // The total number of bets the users have made
  uint public numberOfBets;
  
  // The maximum amount of bets can be made for each game
  uint public maxAmountOfBets = 7;
  
  // The total amount of AION bet for this current game
  uint public totalBet;
  
  // The total amount of AION paid out (contract paid out)
  uint public totalPaid;
  
  // The number / animal that won the last game
  uint public lastLuckyAnimal;
  
  // Array of players in each round
  address[] public players;
  
  // Player object
  struct Player {
    uint amountBet;
    uint numberSelected;
  }
  
  // The address of the player and => the user info
  mapping(address => Player) public playerInfo;
  
  // Events that get logged in the blockchain
  event AnimalChosen(uint value);
  event WinnerTransfer(address to, uint value);
  
  // Modifier: Only allow the execution of functions when bets are completed
  modifier onEndGame(){
    if(numberOfBets >= maxAmountOfBets) _;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  // Constructor
  function Casino() public {
    owner = msg.sender;
  }
  
  // Make sure contract has balance > maximumBet so
  // distributePrizes() will be able to execute without failure
  function() public payable {}
  
  // refund all tokens back to owner
  function refund() public onlyOwner {
    uint totalBalance = this.balance;
    owner.transfer(totalBalance);
  }
  
  function kill() public {
    if(msg.sender == owner) selfdestruct(owner);
  }

  function checkPlayerExists(address player) public constant returns (bool){
    for(uint i = 0; i < players.length; i++){
       if(players[i] == player) return true;
    }
    return false;
  }

  function bet(uint numberSelected) payable {
  // Check that the max amount of bets hasn't been met yet
  require(numberOfBets <= maxAmountOfBets);
  
  // Check that the number to bet is within the range
  require(numberSelected >= 1 && numberSelected <= 10);
  
  // Check that the player doesn't exists
  require(checkPlayerExists(msg.sender) == false);
  
  // Check that the amount paid is bigger or equal the minimum bet
  require(msg.value >= minimumBet);
  	
  // Store player's address, bet amount, and animal chose
  playerInfo[msg.sender].amountBet = msg.value;
  playerInfo[msg.sender].numberSelected = numberSelected;
  	
  numberOfBets++; // Increase number of bets placed
  players.push(msg.sender); // Add player into array 
  totalBet += msg.value; // Increase total AION prize pool 
  
  // Check if the round is completed, if so - draw the winning animal 
  if(numberOfBets >= maxAmountOfBets) generateNumberWinner(); 
 }

 function generateNumberWinner() private onEndGame {
  uint numberGenerated = block.number % 10 + 1; // This isn't secure
  lastLuckyAnimal = numberGenerated; // Store animal chosen
  distributePrizes(); // Call function to distribute prizes
}
function distributePrizes() private onEndGame {
    address[100] memory winners; // Create a temporary in memory array with fixed size
    uint count = 0;              // Winner count - how many winners
    uint winnerBetPool = 0;      // Total Winner Bet Pool - used to portion prize amount 

    // Store winners in array, and tally winner bet pool
    for(uint i = 0; i < players.length; i++){
      address playerAddress = players[i];
      if(playerInfo[playerAddress].numberSelected == lastLuckyAnimal){
        winners[count] = playerAddress;
        winnerBetPool += playerInfo[playerAddress].amountBet;
        count++;
      }
    }

    // If winning players, then distribute AION 
    if (count > 0){
      uint winnerAIONAmount = totalBet / count; // How much each winner gets
      for(uint j = 0; j < count; j++){
        if(winners[j] != address(0)) // Check that the address in this fixed array is not empty
        address playerAddressW = winners[j]; // Grab winning addresses
        uint winnerAIONAmount = SafeMath.div(SafeMath.mul(totalBet, playerInfo[playerAddressW].amountBet), winnerBetPool);
        winners[j].transfer(winnerAIONAmount); // Calculate winner proportions to the prize pool

        totalPaid += winnerAIONAmount; // Add to Total Payout
        WinnerTransfer(winners[j], winnerAIONAmount);
      }
      totalBet = 0; // Clear total bets, if no winner - totalBets get rolled over
    }
    
    players.length = 0; // Delete all the players array
    numberOfBets = 0;   // Reset number of bets
    numberRound++;      // Increase Round Number
  }
}
}
