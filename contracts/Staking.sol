//SPDX-License-Identifier: MIT


pragma solidity ^ 0.8.0;


contract Staking{
    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner, "This function is restricted to the owner only");
        _;
    }

    struct Position {
        uint positionId;
        address walletAddress;
        uint createdDate;
        uint unlockDate;
        uint percentageInterest;
        uint weiStaked;
        uint weiInterest;
        bool open;
    }

    Position position;
    uint public currentPositionId;
    mapping(uint  => Position) public positions;
    mapping(address => uint[]) positionIdsByAddress; // to give track of the positions that a user has created , so he himself doesn't have to keep track of that . 

    mapping(uint => uint) public tiers; // data about date and interest rate , duration directly proportional to interest rate

    uint[] public lockPeriods;
    

    constructor() payable {
        owner = msg.sender;
        currentPositionId = 0;

        tiers[30] = 700;
        tiers[90] = 1000;
        tiers[180] = 1200;

        lockPeriods.push(30);
        lockPeriods.push(90);
        lockPeriods.push(180);

    }

    function  calculateInterest(uint basisPoints, uint numDays, uint weiAmount) private pure returns(uint) {
        return basisPoints * weiAmount /10000; // 700 /10000 = 0.07 % * wei  
    }

    function modifyLockPeroids(uint numDays, uint basisPoints) external onlyOwner{
        tiers[numDays]  = basisPoints; 
        lockPeriods.push(numDays);
    }

    function getLockPeriods() external view returns(uint[] memory) {
        return lockPeriods;
    } 

    function getInterestRate(uint numDays) external view returns(uint) {
        
        return tiers[numDays];
    }

    function getPositionById(uint positionId) external view returns(Position memory) {
        return positions[positionId];
    }

    function getPositionIdsForAddress(address walletAddress) external view returns(uint[] memory) {
           return positionIdsByAddress[walletAddress];
    }
    function changeUnlockDate(uint positionId, uint newUnlockDate) external onlyOwner {
        positions[positionId].unlockDate = newUnlockDate; 
    }

    function closePosition(uint positionId) external {
        require(positions[positionId].walletAddress == msg.sender, "Only position creator can modify position");
        require(positions[positionId].open == true, "Position has been closed");

        positions[positionId].open = false;
        if(block.timestamp > positions[positionId].unlockDate) {
            uint amount = positions[positionId].weiInterest * positions[positionId].weiStaked;
            payable(msg.sender).call{value: amount} ("") ;

        } 
        payable(msg.sender).call{value: positions[positionId].weiStaked}("");
    }


    function stakeEther(uint numDays) external payable {
        require(tiers[numDays] > 0 , "Mapping not found");

        positions[currentPositionId] = Position ( 
            currentPositionId,
            msg.sender,
            block.timestamp,
            block.timestamp + (numDays * 1 days),
            tiers[numDays],
            msg.value,
            calculateInterest(tiers[numDays], numDays, msg.value),
            true
        );

        positionIdsByAddress[msg.sender].push(currentPositionId);
        currentPositionId += 1;
    }

}