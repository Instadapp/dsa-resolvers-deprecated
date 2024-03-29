pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
}

contract Basic {
    ChainLinkInterface ethUsdPriceFeed = ChainLinkInterface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    // ChainLinkInterface ethUsdPriceFeed = ChainLinkInterface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    
    function toUint256(bytes memory _bytes)   
    internal
    pure
    returns (uint256 value) {

        assembly {
        value := mload(add(_bytes, 0x20))
        }
    }
}

contract Resolver is Basic {
    struct PriceData {
        uint price;
        uint decimals;
        bool status;
    }

    function getPrices(address[] memory priceFeeds)
    public
    view
    returns (
        PriceData memory ethPriceInUsd,
        PriceData[] memory tokensPriceInETH
    ) {
        tokensPriceInETH = new PriceData[](priceFeeds.length);
        for (uint i = 0; i < priceFeeds.length; i++) {
            (bool priceStatus, bytes memory priceData) =  priceFeeds[i].staticcall(abi.encodeWithSignature("latestAnswer()"));
            (bool decimalstatus, bytes memory decimalsData) =  priceFeeds[i].staticcall(abi.encodeWithSignature("decimals()"));
            tokensPriceInETH[i] = PriceData({
                price: address(ethUsdPriceFeed) == priceFeeds[i] ? 1 : toUint256(priceData),
                decimals: toUint256(decimalsData),
                status: priceStatus && decimalstatus
            });
        }

        (bool priceStatus, bytes memory priceData) =  address(ethUsdPriceFeed).staticcall(abi.encodeWithSignature("latestAnswer()"));
        (bool decimalstatus, bytes memory decimalsData) =  address(ethUsdPriceFeed).staticcall(abi.encodeWithSignature("decimals()"));


        ethPriceInUsd = PriceData({
                price: toUint256(priceData),
                decimals: toUint256(decimalsData),
                status: priceStatus && decimalstatus
            });
    }
}

contract InstaChainLinkResolver is Resolver {
    string public constant name = "ChainLink-Aggregator-Resolver-v1";
}