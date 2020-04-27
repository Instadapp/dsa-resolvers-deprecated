pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface OasisInterface {
    function getMinSell(TokenInterface pay_gem) external view returns (uint);
    function getBuyAmount(address dest, address src, uint srcAmt) external view returns(uint);
	function getPayAmount(address src, address dest, uint destAmt) external view returns (uint);
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
}


contract Helpers {
    /**
     * @dev get Ethereum address
     */
    function getAddressETH() public pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}


contract OasisHelpers is Helpers {
    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev Return Oasis Address
     */
    function getOasisAddr() internal pure returns (address) {
        return 0x794e6e91555438aFc3ccF1c5076A74F42133d08D;
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == getAddressETH() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
        _sell = sell == getAddressETH() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    }
}


contract Resolver is OasisHelpers {

    function getBuyAmount(address buyAddr, address sellAddr, uint sellAmt) public view returns (uint buyAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        buyAmt = OasisInterface(getOasisAddr()).getBuyAmount(address(_buyAddr), address(_sellAddr), sellAmt);
    }

    function getSellAmount(address buyAddr, address sellAddr, uint buyAmt) public view returns (uint sellAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        sellAmt = OasisInterface(getOasisAddr()).getPayAmount(address(_sellAddr), address(_buyAddr), buyAmt);
    }

    function getMinSellAmount(address sellAddr) public view returns (uint minAmt) {
        (, TokenInterface _sellAddr) = changeEthAddress(getAddressETH(), sellAddr);
        minAmt = OasisInterface(getOasisAddr()).getMinSell(_sellAddr);
    }

}


contract InstaOasisResolver is Resolver {
    string public constant name = "Oasis-Resolver-v1";
}