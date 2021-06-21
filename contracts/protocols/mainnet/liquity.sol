pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TroveManagerLike {
  function getBorrowingRateWithDecay() external view returns (uint);
  function getTCR(uint _price) external view returns (uint);
  function getCurrentICR(address _borrower, uint _price) external view returns (uint);
  function checkRecoveryMode(uint _price) external view returns (bool);
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

interface StakingLike {
  function stakes(address owner) external view returns (uint);
  function getPendingETHGain(address _user) external view returns (uint);
  function getPendingLUSDGain(address _user) external view returns (uint);
}

interface PoolLike {
  function getETH() external view returns (uint);
}

contract DSMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, "math-not-safe");
  }
}

contract Helpers is DSMath {
  TroveManagerLike internal constant troveManager =
    TroveManagerLike(0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2);

  StabilityPoolLike internal constant stabilityPool = 
    StabilityPoolLike(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);

  StakingLike internal constant staking =
    StakingLike(0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d);

  PoolLike internal constant activePool =
    PoolLike(0xDf9Eb223bAFBE5c5271415C75aeCD68C21fE3D7F);
  
  PoolLike internal constant defaultPool =
    PoolLike(0x896a3F03176f05CFbb4f006BfCd8723F2B0D741C);

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

  struct System {
    uint borrowFee;
    uint ethTvl;
    uint tcr;
    bool isInRecoveryMode;
  }
}


contract Resolver is Helpers {
  function getTrove(address owner, uint oracleEthPrice) public view returns (Trove memory) {
    (uint debt, uint collateral, , ) = troveManager.getEntireDebtAndColl(owner);
    uint icr = troveManager.getCurrentICR(owner, oracleEthPrice);
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

  function getPosition(address owner, uint oracleEthPrice) external view returns (Position memory) {
    Trove memory trove = getTrove(owner, oracleEthPrice);
    StabilityDeposit memory stability = getStabilityDeposit(owner);
    Stake memory stake = getStake(owner);
    return Position(trove, stability, stake);
  }

  function getSystemState(uint oracleEthPrice) external view returns (System memory) {
    uint borrowFee = troveManager.getBorrowingRateWithDecay();
    uint ethTvl = add(activePool.getETH(), defaultPool.getETH());
    uint tcr = troveManager.getTCR(oracleEthPrice);
    bool isInRecoveryMode = troveManager.checkRecoveryMode(oracleEthPrice);
    return System(borrowFee, ethTvl, tcr, isInRecoveryMode);
  }
}

contract InstaLiquityResolver is Resolver {
  string public constant name = "Liquity-Resolver-v1";
}
