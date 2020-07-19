pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
  function decimals() external view returns (uint);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint);
}

interface IStakingRewards {
  function balanceOf(address) external view returns (uint256);
  function earned(address) external view returns (uint256);
}

interface Staking {
  function getStakingData(string calldata stakingName)
  external
  view
  returns (
    IStakingRewards stakingContract,
    TokenInterface stakingToken,
    bytes32 stakingType
  );
}

contract CurveStakingHelpers {
  /**
  * @dev Return mapping contract Address
  */
  function getStakingAddr() internal virtual view returns (address) {
    return 0x772590F33eD05b0E83553650BF9e75A04b337526;
  }
}

contract Resolver is CurveStakingHelpers {

  function getPosition(address user, string memory stakingPoolName) public view returns (
    uint stakedBal,
    uint rewardsEarned,
    uint tokenBal
  ) {
    Staking staking = Staking(getStakingAddr());
    (IStakingRewards stakingContract, TokenInterface stakingToken, bytes32 stakingType) = staking.getStakingData(stakingPoolName);
    stakedBal = stakingContract.balanceOf(user);
    rewardsEarned = stakingContract.earned(user);
    tokenBal = stakingToken.balanceOf(user);
  }
}


contract InstaCurveStakingResolver is Resolver {
  string public constant name = "Synthetix-Staking-Resolver-v1";
}
