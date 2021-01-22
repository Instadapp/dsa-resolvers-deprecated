pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface AaveInterface {
    function getUserReserveData(address _reserve, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentBorrowBalance,
        uint256 principalBorrowBalance,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint256 liquidityRate,
        uint256 originationFee,
        uint256 variableBorrowIndex,
        uint256 lastUpdateTimestamp,
        bool usageAsCollateralEnabled
    );
}

interface AaveProviderInterface {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
    function getPriceOracle() external view returns (address);
}


interface CTokenInterface {
    function exchangeRateStored() external view returns (uint);
    function borrowBalanceStored(address) external view returns (uint);

    function balanceOf(address) external view returns (uint);
}

interface ListInterface {
    function accounts() external view returns (uint64);
    function accountID(address) external view returns (uint64);
    function accountAddr(uint64) external view returns (address);
}

contract Helpers {

    struct AaveData {
        uint collateral;
        uint debt;
    }
    struct data {
        address user;
        AaveData[] tokensData;
    }
    
    struct datas {
        AaveData[] tokensData;
    }

    /**
     * @dev get Aave Provider Address
    */
    function getAaveProviderAddress() internal pure returns (address) {
        return 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8; //mainnet
        // return 0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5; //kovan
    }
}

contract Resolver is Helpers {
    
    function getAaveDataByReserve(address[] memory owners, address reserve, AaveInterface aave) public view returns (AaveData[] memory) {
        AaveData[] memory tokensData = new AaveData[](owners.length);
        for (uint i = 0; i < owners.length; i++) {
            (uint collateral, uint debt,,,,,,,,) = aave.getUserReserveData(reserve, owners[i])
            tokensData[i] = AaveData(
                collateral,
                debt
            );
        }

        return tokensData;
    }

    function getPositionByAddress(
        address[] memory owners,
        address[] memory reserves
    )
        public
        view
        returns (datas[] memory)
    {
        AaveProviderInterface AaveProvider = AaveProviderInterface(getAaveProviderAddress());
        AaveInterface aave = AaveInterface(AaveProvider.getLendingPool());
        datas[] memory _data = new datas[](reserves.length);
        for (uint i = 0; i < cAddress.length; i++) {
            _data[i] = datas(
                getAaveDataByReserve(owners, reserves[i], aave)
            );
        }
        return _data;
    }

}