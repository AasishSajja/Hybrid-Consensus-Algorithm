// SPDX-License-Identifier: MIT
pragma solidity <=0.8.11;

contract Auction{ 

    address payable public auctioneer; 
    uint public stblock; //start time
    uint public etblock; //end time;
    bytes32 public previousHash;
    enum Auction_State{Started, Running , Ended , Cancelled}
    Auction_State public auctionState;

    uint public highest_payable_bid;
    uint public bid_Increment;

    address payable public highestBidder;
    mapping (address => uint) public xp;
    mapping(address => uint) public bids;
    constructor(){
        auctioneer = payable(msg.sender);
        auctionState = Auction_State.Running;
        stblock = block.number;
        etblock = stblock + 240;
        bid_Increment = 1 ether;
        xp[tx.origin] = 0; 
        previousHash=0;   }

    modifier notOwner(){
        require(msg.sender != auctioneer,"Owner cannot bid");
        _;
    }

    modifier Owner(){
        require(msg.sender == auctioneer,"Owner cannot bid");
        _;
    }

    modifier started(){
        require(block.number>stblock);
        _;
    }
    modifier beforeEnding(){
        require(block.number<etblock);
        _;
    }

    function cancelAuc() public Owner{
        auctionState = Auction_State.Cancelled;
    }

    function endAuc() public Owner{
        auctionState = Auction_State.Ended;
    }
    
    function min(uint a , uint b) pure private returns (uint){
        if(a<=b)
        return a;
        else
        return b;

    }

    function bid() payable public notOwner started beforeEnding {
        address bidder ;
        bidder=msg.sender;
        require(auctionState == Auction_State.Running);
        require(msg.value>= 1 ether);

        uint currentBid = bids[msg.sender] + msg.value ;
        require(currentBid>highest_payable_bid);
        bids[msg.sender] = currentBid;

        if(currentBid<bids[highestBidder]){
            highest_payable_bid = min(currentBid+bid_Increment,bids[highestBidder]);
        }
        else{
            highest_payable_bid = min(currentBid,bids[highestBidder]+bid_Increment);
            highestBidder = payable(msg.sender);
        }
        xp[bidder]+=1;
    }
    function getBalance(address addr) public view returns(uint) {
        return xp[addr];
    }
    function finalizeAuc() public{
        require(auctionState == Auction_State.Cancelled || auctionState == Auction_State.Ended || block.number>etblock);
        require(msg.sender == auctioneer || bids[msg.sender]>0);

        address payable person;
        uint value;

        if(auctionState == Auction_State.Cancelled){
            person = payable(msg.sender);
            value = bids[msg.sender];
        }
        else{
            if(msg.sender == auctioneer){
                person = auctioneer;
                value = highest_payable_bid;

            }
            else{
                if(msg.sender == highestBidder){
                     person = highestBidder;
                    value = bids[highestBidder]-highest_payable_bid;
                }
                else{
                    person = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[msg.sender]=0;
        person.transfer(value);
    }
    function Block(int transactions)public returns(bytes32 hashin){
        require(msg.sender==highestBidder);
       uint time= block.timestamp;
        hashin= sha256(abi.encodePacked(time,transactions,previousHash));
        previousHash=hashin; 
        return hashin;   
    }
    // function prevHash() public view returns(bytes32){
    //     return previousHash;
    // }
}
