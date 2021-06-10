pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IGUniPool {
    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getMintAmounts(uint256 amount0Max, uint256 amount1Max)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function getPositionID() external view returns (bytes32 positionID);
}

interface GUniResolver {

    function getPoolUnderlyingBalances(IGUniPool pool)
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getUnderlyingBalances(
        IGUniPool pool,
        uint256 balance
    ) external view returns (uint256 amount0, uint256 amount1);

    function getRebalanceParams(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        uint16 slippageBPS
    ) external view returns (
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold
    );

}

struct StakingRewardsInfo {
    address stakingRewards;
    uint rewardAmount;
}
interface StakingFactoryInterface {

    function stakingRewardsInfoByStakingToken(address) external view returns(StakingRewardsInfo memory);

}

interface StakingInterface {
    function totalSupply() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
}


contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

}

contract Helpers is DSMath {

    StakingFactoryInterface public constant getStakingFactory = StakingFactoryInterface(0xf39eC5a471edF20Ecc7db1c2c34B4C73ab4B2C19);
    GUniResolver public constant gelatoRouter = GUniResolver(0xC8b92036cf2bfc5aD2116c9b9Fb3cee2d3b3dc89);

    struct UserData {
        address pool; // address of pool contract
        address staking; // address of staking contract
        address token0Addr; // address of token 0
        address token1Addr; // address of token 1
        uint poolTokenSupply; // Total supply of Pool token
        uint poolToken0Bal; // balance of total pool for token0
        uint poolToken1Bal; // balance of total pool for token1
        uint poolTokenSupplyStaked; // total pool token locked in staking contract
        uint stakingToken0Bal; // total balance of token0 in Staking
        uint stakingToken1Bal; // total balance of token1 in Staking
        uint rewardRate; // INST distributing per second
        uint token0Bal; // balance of token 0 of user
        uint token1Bal; // balance of token 1 of user
        uint earned; // INST earned from staking
        uint stakedBal; // user's pool token bal in staking contract
        uint poolBal; // ideal pool token in user's DSA
        uint totalBal; // stakedBal + poolTknBal
    }

}

contract Resolver is Helpers {

    function getSinglePosition(address user, address pool) public view returns(UserData memory _data) {
        _data.pool = pool;
        StakingInterface stakingContract = StakingInterface(getStakingFactory.stakingRewardsInfoByStakingToken(pool).stakingRewards);
        _data.staking = address(stakingContract);
        IGUniPool poolContract = IGUniPool(pool);
        _data.token0Addr = address(poolContract.token0());
        _data.token1Addr = address(poolContract.token1());
        if (_data.staking == address(0)) {
            _data.earned = 0;
            _data.stakedBal = 0;
        } else {
            _data.earned = stakingContract.earned(user);
            _data.stakedBal = stakingContract.balanceOf(user);
        }
        _data.poolBal = poolContract.balanceOf(user);
        _data.totalBal = add(_data.stakedBal, _data.poolBal);
        (_data.token0Bal, _data.token1Bal) = gelatoRouter.getUnderlyingBalances(poolContract, _data.totalBal);
        _data.poolTokenSupply = poolContract.balanceOf(user);
        (_data.poolToken0Bal, _data.poolToken1Bal) = gelatoRouter.getPoolUnderlyingBalances(poolContract);
        _data.poolTokenSupplyStaked = stakingContract.totalSupply();
        (_data.stakingToken0Bal, _data.stakingToken1Bal) = gelatoRouter.getUnderlyingBalances(poolContract, _data.poolTokenSupplyStaked);
        _data.rewardRate = stakingContract.rewardRate();
    }

    function getPosition(address user, address[] memory pools) public view returns(UserData[] memory _data) {
        for (uint i = 0; i < pools.length; i++) {
            _data[i] = getSinglePosition(user, pools[i]);
        }
    }

    // @param slippage in 18 decimal where 100% = 1e18.
    function getSwapAndDepositParams(
        address pool, 
        uint amount0In,
        uint amount1In,
        uint slippage
    ) public view returns (
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold
    ) {
        uint slippageBPS = slippage / 1e16;
        (zeroForOne, swapAmount, swapThreshold) = gelatoRouter.getRebalanceParams(IGUniPool(pool), amount0In, amount1In, uint16(slippageBPS));
    }

    /**
     * @param burnPercent in 18 decimal where 100% = 1e18.
     * @param slippage in 18 decimal where 100% = 1e18.
    */
    function getWithdrawParams(address user, address pool, uint burnPercent, uint slippage) public view returns (uint burnAmt, uint amount0, uint amount1, uint amount0Min, uint amount1Min) {
        UserData memory _data = getSinglePosition(user, pool);
        burnAmt = wmul(_data.totalBal, burnPercent);
        amount0 = wmul(_data.token0Bal, burnPercent);
        amount1 = wmul(_data.token1Bal, burnPercent);
        amount0Min = wmul(amount0, sub(1e18, slippage));
        amount1Min = wmul(amount1, sub(1e18, slippage));
    }

}
