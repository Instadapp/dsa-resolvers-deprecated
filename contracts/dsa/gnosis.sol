pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface GnosisSafeProxy {
    function NAME() external view returns(string memory);
    function VERSION() external view returns(string memory);
    function nonce() external view returns(uint);
    function getThreshold() external view returns(uint);
    function getOwners() external view returns (address[] memory);
}

interface GnosisFactoryInterface {
    function proxyRuntimeCode() external pure returns (bytes memory);
}


contract Helpers {
    GnosisFactoryInterface gnosisFactoryContract = GnosisFactoryInterface(0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B);
    
    struct MultiSigData {
        address[] owners;
        string version;
        uint nonce;
        uint threshold;
    }

    
    function getContractCode(address _addr) public view returns (bytes memory o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }
}

contract Resolver is Helpers{
    function getGnosisSafeDetails(address safeAddress) public view returns(MultiSigData memory) {
        GnosisSafeProxy safeContract = GnosisSafeProxy(safeAddress);
        return MultiSigData({
            owners: safeContract.getOwners(),
            version: safeContract.VERSION(),
            nonce: safeContract.nonce(),
            threshold: safeContract.getThreshold()
        });
    }

    function getGnosisSafesDetails(address[] memory safeAddresses) public view returns(MultiSigData[] memory) {
        MultiSigData[] memory multiData = new MultiSigData[](safeAddresses.length);
        for (uint i = 0; i < safeAddresses.length; i++) {
            multiData[i] = getGnosisSafeDetails(safeAddresses[i]);
        }
        return multiData;
    }

    function isSafeContract(address safeAddress) public view returns(bool) {
        bytes memory multiSigCode = gnosisFactoryContract.proxyRuntimeCode();
        bytes memory _contractCode = getContractCode(safeAddress);
        return keccak256(abi.encode(multiSigCode)) == keccak256(abi.encode(_contractCode));
    }
}