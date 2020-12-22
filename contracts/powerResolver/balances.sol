pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
}

interface UnipairInterface {
    function totalSupply() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


contract Resolver {
    struct Balances {
        address owner;
        uint[] balance;
    }

    struct UnipairInfo {
        address token0;
        address token1;
        uint reserve0;
        uint reserve1;
        uint totalSupply;
    }

    function getBalances(address[] memory owners, address[] memory tknAddress) public view returns (Balances[] memory) {
        Balances[] memory tokensBal = new Balances[](owners.length);
        for (uint i = 0; i < owners.length; i++) {
            uint[] memory bals = new uint[](tknAddress.length);
            for (uint j = 0; j < tknAddress.length; j++) {
                if (tknAddress[j] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                    bals[j] = owners[i].balance;
                } else {
                    TokenInterface token = TokenInterface(tknAddress[i]);
                    bals[j] = token.balanceOf(owners[i]);
                }
            }
            tokensBal[i] = Balances({
                owner: owners[i],
                balance: bals
            });
        }
        return tokensBal;
    }

    function getUnipairInfo(
        address[] memory owners,
        address[] memory tknAddress
    ) public view returns (Balances[] memory, UnipairInfo[] memory) {
        Balances[] memory tokensBal = new Balances[](owners.length);
        UnipairInfo[] memory unipair = new UnipairInfo[](tknAddress.length);

        address wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        tokensBal = getBalances(owners, tknAddress);

        for (uint i = 0; i < tknAddress.length; i++) {
            UnipairInterface lp = UnipairInterface(tknAddress[i]);
            address tkn0 = lp.token0() == wethAddr ? ethAddr : lp.token0();
            address tkn1 = lp.token1() == wethAddr ? ethAddr : lp.token1();

            (uint112 res0, uint112 res1, ) = lp.getReserves();
            uint supply = lp.totalSupply();

            unipair[i] = UnipairInfo({
                token0: tkn0,
                token1: tkn1,
                reserve0: res0,
                reserve1: res1,
                totalSupply: supply
            });
        }

        return (tokensBal, unipair);
    }
}


contract InstaPowerERC20Resolver is Resolver {
    string public constant name = "ERC20-Power-Resolver-v1";
}
