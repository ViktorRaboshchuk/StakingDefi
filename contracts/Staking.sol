pragma solidity ^ 0.8.17;

contract Staking {
  address public owner;

  struct Position {
    uint positionId;
    address walletAddress;
    uint createdDate;
    uint unlockDate;
    uint percentInterest;
    uint weiStacked;
    uint weiInterest;
    bool open;
  }

  Position position;

  uint public currentPositionId;
  mapping(uint => Position) public positions;
  mapping(address => uint[]) public positionIdsByAddress;
  mapping(uint => uint) public tiers;
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

  function stakeEther(uint numDays) external payable {
    require(tiers[numDays] > 0, "Mapping not found");

    positions[currentPositionId] = Position(
      currentPositionId,
      msg.sender,
      block.timestamp,
      block.timestamp + (numDays * 1 days),
      tiers[numDays],
      msg.value,
      calculateInterest(tiers[numDays], msg.value),
      true
      );

      positionIdsByAddress[msg.sender].push(currentPositionId);
      currentPositionId += 1;
  }

  function calculateInterest(uint basisPoints, uint weiAmount) private pure returns(uint){
    return basisPoints * weiAmount / 10000;
  }

  function modifyLockPeriods(uint numDays, uint basisPoints) external {
    require(owner == msg.sender, "Only owner can modify staking periods");

    tiers[numDays] = basisPoints;
    lockPeriods.push(numDays);
  }

  function getLockPeriods() external view returns(uint[] memory) {
    return lockPeriods;
  }

  function getInterestRate(uint numDays) external view returns(uint) {
    return tiers[numDays];
  }

  function getPositionById(uint positionId) external view returns(Position memory){
    return  positions[positionId];
  }

  function getPositionIdsAddress(address walletAddress) external view returns(uint[] memory){
    return positionIdsByAddress[walletAddress];
  }

  function changeUnlockDate(uint positionId, uint newUnlockDate) external {
    require(owner == msg.sender, "Only owner can modify unlock period");
    positions[positionId].unlockDate = newUnlockDate;
  }

  function closePosition(uint positionId) external {
    require(positions[positionId].walletAddress == msg.sender, "Only creator may modify position");
    require(positions[positionId].open == true, "Position is closed");

    positions[positionId].open = false;

    if(block.timestamp > positions[positionId].unlockDate) {
      uint amount = positions[positionId].weiStacked + positions[positionId].weiInterest;
      /* require(amount > 0, "Nothing to withdraw"); */

      positions[positionId].weiStacked = 0;
      positions[positionId].weiInterest = 0;

      (bool success, ) = payable(msg.sender).call{value: amount}("");
      require(success, "Transfer failed.");
    } else {
      uint amount = positions[positionId].weiStacked;
      /* require(amount > 0, "Nothing to withdraw"); */

      positions[positionId].weiStacked = 0;
      positions[positionId].weiInterest = 0;

      (bool success, ) = payable(msg.sender).call{value: amount}("");
      require(success, "Transfer failed.");
    }

  }
}
