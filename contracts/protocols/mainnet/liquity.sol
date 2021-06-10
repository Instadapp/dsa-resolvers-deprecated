pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TroveManagerLike {
  function getCurrentICR(address _borrower, uint _price) external view returns (uint);
  function getEntireDebtAndColl(address _borrower) external view returns (
    uint debt, 
    uint coll, 
    uint pendingLUSDDebtReward, 
    uint pendingETHReward
  );
}

interface StabilityPoolLike {
  function getCompoundedLUSDDeposit(address _depositor) external view returns (uint);
  function getDepositorETHGain(address _depositor) external view returns (uint);
  function getDepositorLQTYGain(address _depositor) external view returns (uint);
}

abstract contract StakingLike {
  mapping(address => uint) public stakes;
  function getPendingETHGain(address _user) external virtual view returns (uint);
  function getPendingLUSDGain(address _user) external virtual view returns (uint);
}

abstract contract PriceFeedLike {
  uint public lastGoodPrice;
}

contract Helpers {
  TroveManagerLike internal constant troveManager =
    TroveManagerLike(0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2);

  StabilityPoolLike internal constant stabilityPool = 
    StabilityPoolLike(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);

  StakingLike internal constant staking =
    StakingLike(0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d);

  PriceFeedLike internal constant priceFeed = 
    PriceFeedLike(0x4c517D4e2C851CA76d7eC94B805269Df0f2201De);
  
  struct Trove {
    uint collateral;
    uint debt;
    uint icr;
  }

  struct StabilityDeposit {
    uint deposit;
    uint ethGain;
    uint lqtyGain;
  }

  struct Stake {
    uint amount;
    uint ethGain;
    uint lusdGain;
  }

  struct Position {
    Trove trove;
    StabilityDeposit stability;
    Stake stake;
  }
}


contract Resolver is Helpers {
  function getTrove(address owner) public view returns (Trove memory) {
    (uint debt, uint collateral, uint _, uint __) = troveManager.getEntireDebtAndColl(owner);
    uint price = priceFeed.lastGoodPrice();
    uint icr = troveManager.getCurrentICR(owner, price);
    return Trove(collateral, debt, icr);
  }

  function getStabilityDeposit(address owner) public view returns (StabilityDeposit memory) {
    uint deposit = stabilityPool.getCompoundedLUSDDeposit(owner);
    uint ethGain = stabilityPool.getDepositorETHGain(owner);
    uint lqtyGain = stabilityPool.getDepositorLQTYGain(owner);
    return StabilityDeposit(deposit, ethGain, lqtyGain);
  }

  function getStake(address owner) public view returns (Stake memory) {
    uint amount = staking.stakes(owner);
    uint ethGain = staking.getPendingETHGain(owner);
    uint lusdGain = staking.getPendingLUSDGain(owner);
    return Stake(amount, ethGain, lusdGain);
  }

  function getPosition(address owner) external view returns (Position memory) {
    Trove memory trove = getTrove(owner);
    StabilityDeposit memory stability = getStabilityDeposit(owner);
    Stake memory stake = getStake(owner);
    return Position(trove, stability, stake);
  }
}

contract InstaLiquityResolver is Resolver {
  string public constant name = "Liquity-Resolver-v1";
}
