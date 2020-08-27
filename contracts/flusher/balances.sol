pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
}


contract Resolver {
    struct Balances {
        address flusher;
        uint[] balance;
        bool isDeployed;
    }

    function getBalances(address[] memory flushers, address[] memory tknAddress) public view returns (Balances[] memory) {
        Balances[] memory tokensBal = new Balances[](flushers.length);
        for (uint i = 0; i < flushers.length; i++) {
            uint[] memory bals = new uint[](tknAddress.length);
            for (uint j = 0; j < tknAddress.length; j++) {
                if (tknAddress[j] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                    bals[j] = flushers[i].balance;
                } else {
                    TokenInterface token = TokenInterface(tknAddress[j]);
                    bals[j] = token.balanceOf(flushers[i]);
                }
            }
            tokensBal[i] = Balances({
                flusher: flushers[i],
                balance: bals,
                isDeployed: isContractDeployed(flushers[i]);
            });
        }
        return tokensBal;
    }

    function isContractDeployed(address flusher) public view returns (bool) {
        uint32 size;
        assembly {
        size := extcodesize(flusher)
        }
        return (size > 0);
    }
}


contract InstaFlusherERC20Resolver is Resolver {
    string public constant name = "ERC20-Flusher-Resolver-v1";
}