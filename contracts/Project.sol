// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Project {

    enum State {initialized, ongoing, completed}

    address owner;                                                                  //to store owner, here = the actual Project owner
    uint256 projectID;                                                              //unused variable, may find a use later
    uint256 constant startRaisingFrom = 12345678765 - 1 days;
    uint256 constant raiseBy = 12345678765;
    State currentState;
    uint256 public currentBal;
    mapping(address => uint) public funds;
    uint sqrtFundsSum;
    address[] uniqueContributors;
    
    //modifier to allow access only to the owner
    modifier isOwner() {
        require(msg.sender == owner, "Cannot allow access other than owner");
        _;
    }
    
    //modifier to allow the function to proceed only if contract is in intended state
    modifier isState(State reqState) {
        require(currentState == reqState, "Contract not in required state");
        _;
    }
    
    //initializes the pID of the project for identifying or mapping other project metadata
    //to any database(eg. IPFS), the projectOwner to payout to, and the currentState to 
    //initialized
    constructor(address projectOwner, uint pID) public {
        projectID = pID;
        owner = projectOwner;
        currentState = State.initialized;
    }
    
    //function to calculate square root of x
    function sqrt(uint x) internal pure returns (uint){
       uint n = x / 2;
       uint lstX = 0;
       while (n != lstX){
           lstX = n;
           n = (n + x/n) / 2; 
       }
       return uint(n);
   }
   
   //function to calculate x raised to the power p
   function pow(uint x, uint p) internal pure returns (uint) {
        if(p == 0)
            return 1;
        if(p % 2 == 1) {
            return pow(x, p-1)*x;
        } else {
            return pow(x, p / 2)*pow(x, p / 2);
        }
    }
    
    //function to change the currentState variable of the contract based on comparing block timestamp 
    //to constant raiseBy and startRaisingFrom to meet isState modifier requirements. Currently only
    //the owner can change the phase but chainlink keeper can be implemented later to automate the 
    //change state process.
    function changeState(uint state) public isOwner {
        if(state == 1){
            require(block.timestamp > startRaisingFrom, "ongoing phase cannot be started");
        } else if(state ==2){
            require(block.timestamp > raiseBy, "completed phase cannot be started");
        }
    }
    
    //function to return the square of the sum of the square root of individual contributions when 
    //requested by the Qfunding contract
    function getSquaredSqrtFundsSum() public {
        for(uint i = 0; i<uniqueContributors.length; i++){
            sqrtFundsSum += sqrt(funds[uniqueContributors[i]]);
        }
        return pow(sqrtFundsSum, 2);
    }
    
    //function to recieve contributions from people adn recording it into the mapping funds. the mapping
    //is required to reference and check if a address has already contributed some amount to prevent
    //user from breaking his contribution into small amounts to cheat quadratic funding. 
    function contribute() public payable isState(State.ongoing) {
        uint amountRecieved = msg.value;
        if(funds[msg.sender] == 0){
            uniqueContributors.push(msg.sender);
            funds[msg.sender] = amountRecieved;
        }else {
            funds[msg.sender] = funds[msg.sender] + amountRecieved;
        }
        //currentBal variable is redundant as the same can achieve by this.balance
        currentBal += amountRecieved;
        
    }
    
    //function to payout the funds collected in this project contract to the projectOwner
    //TODO check with the access specifier
    // function payout() isOwner public payable isState(State.completed) {
    //     uint amount = this.balance;
    //     projectOwner.transfer(amount);
    // }
    
    
    
}