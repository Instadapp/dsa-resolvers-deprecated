pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

interface IndexInterface {
    function connectors(uint) external view returns (address);
    function master() external view returns (address);
}

contract Sdk {
    ConnectorsInterface public connectorsContract;
    IndexInterface public  indexContract;
    uint public version = 1;

    mapping (string => Connector) public connectors;

    struct Connector {
        address connector;
        Method[] methods;
    }

    struct Method {
        string name;
        string[] args;
    }
}


contract Controllers is Sdk {
    modifier isController {
        require(indexContract.master() == msg.sender || connectorsContract.chief(msg.sender), "not-an-chief");
        _;
    }

    function addConnector(
        string memory connectorName,
        address connector,
        Method[] memory methods
    ) public isController {
        require(connectors[connectorName].connector == address(0), "already-added-connector");
        require(methods.length > 0, "no-methods");
        connectors[connectorName].connector = connector;
        for (uint i = 0; i < methods.length; i++) {
            connectors[connectorName].methods.push(methods[i]);
        }
    }

    function updateConnectorAddress(string memory connectorName,  address connectorAddr) public isController {
        require(connectors[connectorName].connector != address(0), "connector-not-added");
        connectors[connectorName].connector = connectorAddr;
    }

    function addConnectorMethod(string memory connectorName,  Method[]  memory methods) public isController{
        require(connectors[connectorName].connector != address(0), "connector-not-added");
        require(methods.length > 0, "no-methods");
        for (uint i = 0; i < methods.length; i++) {
            connectors[connectorName].methods.push(methods[i]);
        }
    }

    function removeConnectorMethod(string calldata connectorName, string calldata methodName) external isController {
        require(connectors[connectorName].connector != address(0), "connector-not-added");
        Method[] storage methods = connectors[connectorName].methods;
        bool isfound = false;
        for (uint i = 0; i < methods.length; i++) {
            if (keccak256(abi.encodePacked(methodName)) == keccak256(abi.encodePacked(methods[i].name))) {
                isfound = true;
            }
            if (isfound) {
                if ( methods.length - 1 == i) {
                    delete methods[i];
                } else {
                     methods[i] = methods[i + 1];
                }
            }
        }
    }
}


contract SdkResolver is Controllers {
    function getConnector(
        string memory connectorName,
        string memory methodName
    ) public view returns (address connector, Method memory _method){
        require(connectors[connectorName].connector != address(0), "connector-not-added");
        connector = connectors[connectorName].connector;
        Method[] storage methods = connectors[connectorName].methods;
        for (uint i = 0; i < methods.length; i++) {
            if (keccak256(abi.encodePacked(methodName)) == keccak256(abi.encodePacked(methods[i].name))) {
                _method = methods[i];
            }
        }
    }

    function getConnectors(
        string[] memory connectorsName,
        string[] memory methodsName
    ) public view returns (address[] memory _connectors, Method[] memory _methods){
        require(connectorsName.length == methodsName.length, "length-not-equal");
        for (uint i = 0; i < connectorsName.length; i++) {
            (_connectors[i], _methods[i]) = getConnector(connectorsName[i], methodsName[i]);
        }
    }
}

contract InstaSDK is SdkResolver {
    string constant public name = "SDK-v1";

    constructor (address index) public {
        indexContract = IndexInterface(index);
        address connectors = indexContract.connectors(version);
        connectorsContract = ConnectorsInterface(connectors);
    }
}
