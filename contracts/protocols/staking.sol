pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
  function decimals() external view returns (uint);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint);
}

interface IStakingRewards {
  function balanceOf(address) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function earned(address) external view returns (uint256);
}

interface SynthetixMapping {
  struct StakingData {
    address stakingPool;
    address stakingToken;
  }
  function stakingMapping(bytes32) external view returns(StakingData memory);
}

contract CurveStakingHelpers {
  /**
   * @dev Return InstaDApp Staking Mapping Addresses
   */
  function getMappingAddr() internal virtual view returns (address) {
    return 0x772590F33eD05b0E83553650BF9e75A04b337526; // InstaMapping Address
  }

  function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
    require(bytes(str).length != 0, "string-empty");
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      result := mload(add(str, 32))
    }
  }

}

contract Resolver is CurveStakingHelpers {

  function getPosition(address user, string memory stakingPoolName) public view returns (
    uint stakedBal,
    uint stakedTotalSupply,
    uint rewardsEarned,
    uint tokenBal,
    uint tokenTotalSupply
  ) {
    bytes32 stakingType = stringToBytes32(stakingPoolName);
    SynthetixMapping.StakingData memory stakingData = SynthetixMapping(getMappingAddr()).stakingMapping(stakingType);
    require(stakingData.stakingPool != address(0) && stakingData.stakingToken != address(0), "Wrong Staking Name");
    IStakingRewards stakingContract = IStakingRewards(stakingData.stakingPool);
    TokenInterface stakingToken = TokenInterface(stakingData.stakingToken);

    stakedBal = stakingContract.balanceOf(user);
    stakedBal = stakingContract.totalSupply();
    rewardsEarned = stakingContract.earned(user);
    tokenBal = stakingToken.balanceOf(user);
    tokenBal = stakingToken.totalSupply();
  }

}

contract InstaCurveStakingResolver is Resolver {
  string public constant name = "Synthetix-Staking-Resolver-v1";
}
