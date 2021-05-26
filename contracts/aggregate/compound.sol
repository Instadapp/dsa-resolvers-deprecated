pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";

interface CTokenInterface {
    function exchangeRateCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function balanceOfUnderlying(address account) external returns (uint);

    function underlying() external view returns (address);
    function balanceOf(address) external view returns (uint);
}

interface OracleCompInterface {
    function getUnderlyingPrice(address) external view returns (uint);
}

interface ComptrollerLensInterface {
    function markets(address) external view returns (bool, uint, bool);
    function oracle() external view returns (address);
}

contract Variables {
    ComptrollerLensInterface public constant comptroller = ComptrollerLensInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    address public constant cethAddr = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    uint256 public constant markets = 12;
    function getAllMarkets() public pure returns (bytes20[markets] memory _markets) {
        _markets = [
            bytes20(0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E), // cBAT
            bytes20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643), // cDAI
            bytes20(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5), // cETH
            bytes20(0x39AA39c021dfbaE8faC545936693aC917d5E7563), // cUSDC
            bytes20(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9), // cUSDT
            bytes20(0xC11b1268C1A384e55C48c2391d8d480264A3A7F4), // cWBTC legacy
            bytes20(0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407), // cZRX
            bytes20(0x35A18000230DA775CAc24873d00Ff85BccdeD550), // cUNI
            bytes20(0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4), // cCOMP
            bytes20(0xccF4429DB6322D5C611ee964527D42E5d685DD6a), // cWBTC
            bytes20(0x12392F67bdf24faE0AF363c24aC620a2f67DAd86), // cTUSD
            bytes20(0xFAce851a4921ce59e912d19329929CE6da6EB0c7) // cLINK
            // bytes20(0xf5dce57282a584d2746faf1593d3121fcac444dc), // cSAI
            // bytes20(0x158079ee67fce2f58472a96584a73c7ab9ac95c1) // cREP
        ];
    }
}

contract Resolver is Variables, DSMath {
    function getCompoundNetworth(address account) internal returns (uint256 networth) {
        bytes20[markets] memory allMarkets = getAllMarkets();
        OracleCompInterface oracle = OracleCompInterface(comptroller.oracle());
        uint256 totalBorrowInUsd = 0;
        uint256 totalSupplyInUsd = 0;

        for (uint i = 0; i < markets; i++) {
            CTokenInterface cToken = CTokenInterface(address(allMarkets[i]));
            uint256 priceInUSD = oracle.getUnderlyingPrice(address(cToken));
            uint256 supply = cToken.balanceOfUnderlying(account);
            uint256 supplyInUsd = wmul(supply, priceInUSD);
            totalSupplyInUsd = add(totalSupplyInUsd, supplyInUsd);

            uint256 borrow = cToken.borrowBalanceCurrent(account);
            uint256 borrowInUsd = wmul(borrow, priceInUSD);
            totalBorrowInUsd = add(totalBorrowInUsd, borrowInUsd);
        }

        networth = sub(totalSupplyInUsd, totalBorrowInUsd);
    }

    function getPosition(address account) external returns (uint256 networthInUsd) {
        return getCompoundNetworth(account);
    }

}

contract InstaCompoundAggregateResolver is Resolver {
    string public constant name = "Compound-Aggregate-Resolver-v1.0";
}
