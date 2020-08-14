pragma solidity ^0.6.0;

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);
}

interface ConnectorsInterface {
  function chief(address) external view returns (bool);
}

interface IndexInterface {
  function master() external view returns (address);
}


contract Basic {
    address public constant connectors = 0xD6A602C01a023B98Ecfb29Df02FBA380d3B21E0c;
    address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    address public constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint public version = 1;

    modifier isChief {
        require(
        ConnectorsInterface(connectors).chief(msg.sender) ||
        IndexInterface(instaIndex).master() == msg.sender, "not-Chief");
        _;
    }

    event LogAddChainLinkMapping(
        address tokenAddr,
        address chainlinkFeed
    );

    event LogRemoveChainLinkMapping(
        address tokenAddr,
        address chainlinkFeed
    );

    event LogChangeGasPriceFeed(
        address chainlinkFeed
    );

    mapping (address => address) public chainLinkMapping;
    address public gasFastChainLink;

    function _addChainLinkMapping(
        address tokenAddr,
        address chainlinkFeed
    ) internal {
        require(tokenAddr != address(0), "tokenAddr-not-vaild");
        require(chainlinkFeed != address(0), "chainlinkFeed-not-vaild");
        require(chainLinkMapping[tokenAddr] == address(0), "chainlinkFeed-already-added");

        chainLinkMapping[tokenAddr] == chainlinkFeed;
        emit LogAddChainLinkMapping(tokenAddr, chainlinkFeed);
    }

    function _removeChainLinkMapping(address tokenAddr) internal {
        require(tokenAddr != address(0), "tokenAddr-not-vaild");
        require(chainLinkMapping[tokenAddr] != address(0), "chainlinkFeed-not-added-yet");

        emit LogRemoveChainLinkMapping(tokenAddr, chainLinkMapping[tokenAddr]);
        delete chainLinkMapping[tokenAddr];
    }

    function addChainLinkMapping(
        address[] memory tokensAddr,
        address[] memory chainlinkFeeds
    ) public isChief {
        require(tokensAddr.length == chainlinkFeeds.length, "Lenght-not-same");
        for (uint i = 0; i < tokensAddr.length; i++) {
            _addChainLinkMapping(tokensAddr[i], chainlinkFeeds[i]);
        }
    }

    function removeChainLinkMapping(address tokenAddr) public isChief {
        for (uint i = 0; i < tokensAddr.length; i++) {
            _removeChainLinkMapping(tokensAddr[i]);
        }
    }

    function changeGasMapping(address chainlinkFeed) public isChief {
        require(chainlinkFeed != address(0), "chainlinkFeed-not-vaild");
        require(chainlinkFeed != gasFastChainLink, "chainlinkFeed-is-same");
        gasFastChainLink = chainlinkFeed;
        emit LogChangeGasPriceFeed(gasFastChainLink);
    }
}

contract Resolver is Basic {
    function getPrice(address[] memory tokens) public view returns (uint ethPriceInUsd, uint[] memory tokensPriceInETH) {
        tokensPriceInETH = new uint[](tokens.length);
        ethPriceInUsd = uint(ChainLinkInterface(chainLinkMapping[ethAddr]).latestAnswer());
        for (uint i = 0; i < tokens.length; i++) {
            tokensPriceInETH[i] = uint(ChainLinkInterface(chainLinkMapping[tokens[i]]).latestAnswer());
        }
    }

    function getGasPrice() public view returns (uint gasPrice) {
        gasPrice = uint(ChainLinkInterface(gasFastChainLink).latestAnswer());
    }
}

contract InstaChainLinkResolver is Resolver {
    constructor (address[] memory tokensAddr, address[] memory chainlinkFeeds) public {
        addChainLinkMapping(tokensAddr, chainlinkFeeds);
    }

    string public constant name = "ChainLink-Resolver-v1";
}