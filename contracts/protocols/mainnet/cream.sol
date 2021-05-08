pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface CTokenInterface {
    function exchangeRateStored() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function borrowBalanceStored(address) external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function underlying() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function getCash() external view returns (uint256);
}

interface TokenInterface {
    function decimals() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);
}

interface OrcaleComp {
    function getUnderlyingPrice(address) external view returns (uint256);
}

interface ComptrollerLensInterface {
    function markets(address)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function claimComp(address) external;

    function compAccrued(address) external view returns (uint256);

    function borrowCaps(address) external view returns (uint256);

    function borrowGuardianPaused(address) external view returns (bool);

    function oracle() external view returns (address);

    function compSpeeds(address) external view returns (uint256);
}

interface CompReadInterface {
    struct CompBalanceMetadataExt {
        uint256 balance;
        uint256 votes;
        address delegate;
        uint256 allocated;
    }

    function getCompBalanceMetadataExt(
        TokenInterface comp,
        ComptrollerLensInterface comptroller,
        address account
    ) external returns (CompBalanceMetadataExt memory);
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

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
}

contract Helpers is DSMath {
    /**
     * @dev get Cream Comptroller
     */
    function getComptroller() public pure returns (ComptrollerLensInterface) {
        return
            ComptrollerLensInterface(
                0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258
            );
    }

    /**
     * @dev get Cream Open Feed Oracle Address
     */
    function getOracleAddress() public view returns (address) {
        return getComptroller().oracle();
    }

    /**
     * @dev get Cream Read Address
     */
    function getCreamReadAddress() public pure returns (address) {
        return 0xd400e22dcA840CC7E342DF1d9945684bBd587659;
    }

    /**
     * @dev get ETH Address
     */
    function getCrETHAddress() public pure returns (address) {
        return 0xD06527D5e56A3495252A528C4987003b712860eE;
    }

    /**
     * @dev get Cream Token Address
     */
    function getCreamToken() public pure returns (TokenInterface) {
        return TokenInterface(0x2ba592F78dB6436527729929AAf6c908497cB200);
    }

    struct CreamData {
        uint256 tokenPriceInEth;
        uint256 tokenPriceInUsd;
        uint256 exchangeRateStored;
        uint256 balanceOfUser;
        uint256 borrowBalanceStoredUser;
        uint256 totalBorrows;
        uint256 totalSupplied;
        uint256 borrowCap;
        uint256 supplyRatePerBlock;
        uint256 borrowRatePerBlock;
        uint256 collateralFactor;
        uint256 creamSpeed;
        bool isCreamEnabled;
        bool isBorrowPaused;
    }
}

contract Resolver is Helpers {
    function getPriceInEth(CTokenInterface crToken)
        public
        view
        returns (uint256 priceInETH, uint256 priceInUSD)
    {
        uint256 decimals =
            getCrETHAddress() == address(crToken)
                ? 18
                : TokenInterface(crToken.underlying()).decimals();
        uint256 price =
            OrcaleComp(getOracleAddress()).getUnderlyingPrice(address(crToken));
        uint256 ethPrice =
            OrcaleComp(getOracleAddress()).getUnderlyingPrice(
                getCrETHAddress()
            );
        priceInUSD = price / 10**(18 - decimals);
        priceInETH = wdiv(priceInUSD, ethPrice);
    }

    function getCreamData(address owner, address[] memory crAddress)
        public
        view
        returns (CreamData[] memory)
    {
        CreamData[] memory tokensData = new CreamData[](crAddress.length);
        ComptrollerLensInterface troller = getComptroller();
        for (uint256 i = 0; i < crAddress.length; i++) {
            CTokenInterface crToken = CTokenInterface(crAddress[i]);
            (uint256 priceInETH, uint256 priceInUSD) = getPriceInEth(crToken);
            (, uint256 collateralFactor, bool isCreamEnabled) =
                troller.markets(address(crToken));
            uint256 _totalBorrowed = crToken.totalBorrows();
            tokensData[i] = CreamData(
                priceInETH,
                priceInUSD,
                crToken.exchangeRateStored(),
                crToken.balanceOf(owner),
                crToken.borrowBalanceStored(owner),
                _totalBorrowed,
                add(_totalBorrowed, crToken.getCash()),
                troller.borrowCaps(crAddress[i]),
                crToken.supplyRatePerBlock(),
                crToken.borrowRatePerBlock(),
                collateralFactor,
                troller.compSpeeds(crAddress[i]),
                isCreamEnabled,
                troller.borrowGuardianPaused(crAddress[i])
            );
        }

        return tokensData;
    }

    function getPosition(address owner, address[] memory crAddress)
        public
        returns (
            CreamData[] memory,
            CompReadInterface.CompBalanceMetadataExt memory
        )
    {
        return (
            getCreamData(owner, crAddress),
            CompReadInterface.CompBalanceMetadataExt(0, 0, address(0), 0)
            // CompReadInterface(getCreamReadAddress()).getCompBalanceMetadataExt(
            //     getCreamToken(),
            //     getComptroller(),
            //     owner
            // )
        );
    }
}

contract InstaCreamResolver is Resolver {
    string public constant name = "Cream-Resolver-v1.0";
}
