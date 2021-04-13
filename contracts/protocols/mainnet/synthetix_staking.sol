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

contract CurveStakingHelpers {
    /**
     * @dev Return Curve Token Address
     */
    function getCurveTokenAddr() internal pure returns (address) {
        return 0xC25a3A3b969415c80451098fa907EC722572917F;
    }

    /**
     * @dev Return Curve sUSD Staking Address
     */
    function getCurveStakingAddr() internal pure returns (address) {
        return 0xDCB6A51eA3CA5d3Fd898Fd6564757c7aAeC3ca92;
    }

    /**
    * @dev Return Synthetix Token address.
    */
    function getSnxAddr() internal pure returns (address) {
        return 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    }

}


contract Resolver is CurveStakingHelpers {

    function getStakingPosition(address user) public view returns (
        uint curveBal,
        uint stakedBal,
        uint rewardsEarned,
        uint snxBal
    ) {
        curveBal = TokenInterface(getCurveTokenAddr()).balanceOf(user);
        IStakingRewards stakingContract = IStakingRewards(getCurveStakingAddr());
        stakedBal = stakingContract.balanceOf(user);
        rewardsEarned = stakingContract.earned(user);
        snxBal = TokenInterface(getSnxAddr()).balanceOf(user);
    }
}


contract InstaCurveStakingResolver is Resolver {
    string public constant name = "Curve-SUSD-Staking-Resolver-v1";
}