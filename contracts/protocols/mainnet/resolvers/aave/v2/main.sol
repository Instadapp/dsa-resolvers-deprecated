pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { Helpers } from "./helpers.sol";
import { AaveAddressProvider, AaveProtocolDataProvider, AaveLendingPool } from "./interface.sol";

abstract contract Resolver is Helpers {
    function getPosition(address user, address[] memory tokens) public view returns(AaveUserTokenData[] memory, AaveUserData memory) {
        AaveAddressProvider addrProvider = AaveAddressProvider(getAaveAddressProvider());
        uint length = tokens.length;
        address[] memory _tokens = new address[](length);

        for (uint i = 0; i < length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        AaveUserTokenData[] memory tokensData = new AaveUserTokenData[](length);
        (TokenPrice[] memory tokenPrices, uint ethPrice) = getTokensPrices(addrProvider, _tokens);

        for (uint i = 0; i < length; i++) {
            tokensData[i] = getTokenData(
                AaveProtocolDataProvider(getAaveProtocolDataProvider()),
                user,
                _tokens[i],
                tokenPrices[i].priceInEth,
                tokenPrices[i].priceInUsd
            );
        }

        return (tokensData, getUserData(AaveLendingPool(addrProvider.getLendingPool()), user, ethPrice, _tokens));
    }
}

contract InstaAaveV2Resolver is Resolver {
    string public constant name = "AaveV2-Resolver-v1.6";
}
