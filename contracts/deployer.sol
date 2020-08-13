pragma solidity ^0.6.0;

interface IndexInterface {
    function master() external view returns (address);
}

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

interface ConnectorInterface {
    function destruct() external;
}

contract Basics {
    IndexInterface instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    ConnectorsInterface connectorsContract = ConnectorsInterface(0xD6A602C01a023B98Ecfb29Df02FBA380d3B21E0c);
}

contract DeployerAuth is Basics {
    mapping(address => bool) public deployer;

    modifier isChief {
        require(connectorsContract.chief(msg.sender) || msg.sender == instaIndex.master(), "not-an-chief");
        _;
    }

    modifier isDeployer {
        require(deployer[msg.sender], "not-an-deployer");
        _;
    }

    /**
     * @dev Enable a Chief.
     * @param _userAddress Chief Address.
    */
    function enableChief(address _userAddress) external isChief {
        deployer[_userAddress] = true;
    }

    /**
     * @dev Disables a Chief.
     * @param _userAddress Chief Address.
    */
    function disableChief(address _userAddress) external isChief {
        delete deployer[_userAddress];
    }
}

contract ConnectorDeployer is DeployerAuth {
    function deploy(bytes memory code, uint connectorId, address destructConnector) public isDeployer returns (address addr) {
        bytes32 salt = bytes32(connectorId);
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        if (destructConnector != address(0)) ConnectorInterface(destructConnector).destruct();
    }
}