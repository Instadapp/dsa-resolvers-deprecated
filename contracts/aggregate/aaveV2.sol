pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../../common/math.sol";

interface AaveProtocolDataProvider {
    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}
interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);
}

contract Variables {
    ChainLinkInterface public constant ethPriceFeed = ChainLinkInterface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    AaveProtocolDataProvider public constant aaveDataProvider = AaveProtocolDataProvider(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
}

contract Resolver is Variables, DSMath {
    function getPosition(address account) external view returns (uint256 networthInUsd) {
        (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            ,
            ,
            ,
            
        ) = aaveDataProvider.getUserAccountData(account);
        
        uint256 ethPrice = mul(uint256(ethPriceFeed.latestAnswer()), 10 ** 10);

        networthInUsd = sub(totalCollateralETH, totalDebtETH);
        networthInUsd = wmul(networthInUsd, ethPrice);
    }
}

contract InstaAaveV2AggregateResolver is Resolver {
    string public constant name = "AaveV2-Aggregate-Resolver-v1.0";
}

