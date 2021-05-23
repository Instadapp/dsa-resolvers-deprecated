pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface AaveProtocolDataProvider {
    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveTokensAddresses(address _asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

interface AaveLendingPool {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralMatic,
            uint256 totalDebtMatic,
            uint256 availableBorrowsMatic,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface AaveAddressProvider {
    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

interface AavePriceOracle {
    function getAssetsPrices(address[] calldata _assets)
        external
        view
        returns (uint256[] memory);
}

interface ATokenInterface {
    function balanceOf(address _user) external view returns (uint256);
}

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint256 constant WAD = 10**18;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
}

contract Helpers is DSMath {
    struct AaveData {
        uint256 collateral;
        uint256 stableDebt;
        uint256 variableDebt;
    }

    struct AaveMaticData {
        uint256 collateral;
        uint256 debt;
    }

    struct data {
        address user;
        AaveData[] tokensData;
    }

    struct datas {
        AaveData[] tokensData;
    }

    struct AtokenAddress {
        address token;
        address atoken;
        address stableDebtToken;
        address variableDebtToken;
    }

    struct TokenPrice {
        uint256 priceInMatic;
        uint256 priceInUsd;
    }

    /**
     * @dev get Aave Provider Address
     */
    function getAaveAddressProvider() internal pure returns (address) {
        return 0xd05e3E715d945B59290df0ae8eF85c1BdB684744; // Matic Mainnet
        // return 0x178113104fEcbcD7fF8669a0150721e231F0FD4B; // Mumbai testnet
    }

    function getAaveProtocolDataProvider() internal pure returns (address) {
        return 0x7551b5D2763519d4e37e8B81929D336De671d46d; // Matic Mainnet
        // return 0xFA3bD19110d986c5e5E9DD5F69362d05035D045B; // Mumbai testnet
    }

    /**
     * @dev get Chainlink Matic price feed Address
     */
    function getChainlinkMaticFeed() internal pure returns (address) {
        return 0xF9680D99D6C9589e2a93a78A04A279e509205945; // Matic mainnet
    }

    /**
     * @dev Return matic address
     */
    function getMaticAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // Matic Address
    }

    /**
     * @dev Return WMatic address
     */
    function getWMaticAddr() internal pure returns (address) {
        return 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // Mainnet WMatic Address
    }
}

contract InstaAaveV2PowerResolver is Helpers {
    function getAtokenAddresses(address[] calldata reserves)
        external
        view
        returns (AtokenAddress[] memory atokenAddress)
    {
        AaveProtocolDataProvider aaveProtocolDataProvider =
            AaveProtocolDataProvider(getAaveProtocolDataProvider());
        atokenAddress = new AtokenAddress[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            address _reserve =
                reserves[i] == getMaticAddr() ? getWMaticAddr() : reserves[i];
            (
                address atoken,
                address stableDebtToken,
                address variableDebtToken
            ) = aaveProtocolDataProvider.getReserveTokensAddresses(_reserve);
            atokenAddress[i] = AtokenAddress(
                _reserve,
                atoken,
                stableDebtToken,
                variableDebtToken
            );
        }
    }

    function getTokensPrices(address[] calldata tokens)
        external
        view
        returns (TokenPrice[] memory tokenPrices, uint256 maticPrice)
    {
        AaveAddressProvider aaveAddressProvider =
            AaveAddressProvider(getAaveAddressProvider());
        uint256[] memory _tokenPrices =
            AavePriceOracle(aaveAddressProvider.getPriceOracle())
                .getAssetsPrices(tokens);
        maticPrice = uint256(
            ChainLinkInterface(getChainlinkMaticFeed()).latestAnswer()
        );
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(
                _tokenPrices[i],
                wmul(_tokenPrices[i], uint256(maticPrice) * 10**10)
            );
        }
    }

    function getMaticPrice() public view returns (uint256 maticPrice) {
        maticPrice = uint256(
            ChainLinkInterface(getChainlinkMaticFeed()).latestAnswer()
        );
    }

    function getAaveDataByReserve(
        address[] memory owners,
        AtokenAddress memory atokenAddress
    ) public view returns (AaveData[] memory) {
        AaveData[] memory tokensData = new AaveData[](owners.length);
        ATokenInterface atokenContract = ATokenInterface(atokenAddress.atoken);
        ATokenInterface stableDebtTokenContract =
            ATokenInterface(atokenAddress.stableDebtToken);
        ATokenInterface variableDebtContract =
            ATokenInterface(atokenAddress.variableDebtToken);
        for (uint256 i = 0; i < owners.length; i++) {
            tokensData[i] = AaveData(
                atokenContract.balanceOf(owners[i]),
                stableDebtTokenContract.balanceOf(owners[i]),
                variableDebtContract.balanceOf(owners[i])
            );
        }

        return tokensData;
    }

    function getPositionByReserves(
        address[] calldata owners,
        AtokenAddress[] calldata atokenAddress
    ) external view returns (datas[] memory) {
        datas[] memory _data = new datas[](atokenAddress.length);
        for (uint256 i = 0; i < atokenAddress.length; i++) {
            _data[i] = datas(getAaveDataByReserve(owners, atokenAddress[i]));
        }
        return _data;
    }

    function getPositionByAddress(address[] memory owners)
        public
        view
        returns (AaveMaticData[] memory tokensData)
    {
        AaveAddressProvider addrProvider =
            AaveAddressProvider(getAaveAddressProvider());
        AaveLendingPool aave = AaveLendingPool(addrProvider.getLendingPool());
        tokensData = new AaveMaticData[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            (uint256 collateral, uint256 debt, , , , ) =
                aave.getUserAccountData(owners[i]);
            tokensData[i] = AaveMaticData(collateral, debt);
        }
    }
}
