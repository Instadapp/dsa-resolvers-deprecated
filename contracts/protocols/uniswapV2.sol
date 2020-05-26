pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function decimals() external view returns (uint);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}


contract Helpers is DSMath {
    /**
     * @dev get Ethereum address
     */
    function getEthAddr() public pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

contract UniswapHelpers is Helpers {
    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev Return uniswap v2 router Address
     */
    function getUniswapAddr() internal pure returns (address) {
        return 0x794e6e91555438aFc3ccF1c5076A74F42133d08D; //Mainnet
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
        _sell = sell == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    }

    function getExpectedBuyAmt(
        address buyAddr,
        address sellAddr,
        uint sellAmt
    ) internal view returns(uint buyAmt) {
        IUniswapV2Router01 router = IUniswapV2Router01(getUniswapAddr());
        address[] memory paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
        uint[] memory amts = router.getAmountsOut(
            sellAmt,
            paths
        );
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(
        address buyAddr,
        address sellAddr,
        uint buyAmt
    ) internal view returns(uint sellAmt) {
        IUniswapV2Router01 router = IUniswapV2Router01(getUniswapAddr());
        address[] memory paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
        uint[] memory amts = router.getAmountsOut(
            buyAmt,
            paths
        );
        sellAmt = amts[1];
    }

    function checkPair(
        IUniswapV2Router01 router,
        address[] memory paths
    ) internal view {
        address pair = IUniswapV2Factory(router.factory()).getPair(paths[0], paths[1]);
        require(pair != address(0), "No-exchange-address");
    }

    function getBuyUnitAmt(
        TokenInterface buyAddr,
        uint expectedAmt,
        TokenInterface sellAddr,
        uint sellAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _sellAmt = convertTo18((sellAddr).decimals(), sellAmt);
        uint _buyAmt = convertTo18(buyAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_buyAmt, _sellAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }

    function getSellUnitAmt(
        TokenInterface sellAddr,
        uint expectedAmt,
        TokenInterface buyAddr,
        uint buyAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _buyAmt = convertTo18(buyAddr.decimals(), buyAmt);
        uint _sellAmt = convertTo18(sellAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_sellAmt, _buyAmt);
        unitAmt = wmul(unitAmt, add(WAD, slippage));
    }

}


contract Resolver is UniswapHelpers {

    function getBuyAmount(address buyAddr, address sellAddr, uint sellAmt, uint slippage) public view returns (uint expectedRate, uint unitAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        expectedRate = getExpectedBuyAmt(address(_buyAddr), address(_sellAddr), sellAmt);
        unitAmt = getBuyUnitAmt(_buyAddr, expectedRate, _sellAddr, sellAmt, slippage);
    }

    function getSellAmount(address buyAddr, address sellAddr, uint buyAmt, uint slippage) public view returns (uint expectedRate, uint unitAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        expectedRate = getExpectedSellAmt(address(_buyAddr), address(_sellAddr), buyAmt);
        unitAmt = getSellUnitAmt(_sellAddr, expectedRate, _buyAddr, buyAmt, slippage);
    }
}


contract InstaUniswapV2Resolver is Resolver {
    string public constant name = "UniswapV2-Resolver-v1";
}

