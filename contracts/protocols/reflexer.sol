/**
 *Submitted for verification at Etherscan.io on 2020-07-29
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ManagerLike {
    function collateralTypes(uint) external view returns (bytes32);
    function ownsSAFE(uint) external view returns (address);
    function safes(uint) external view returns (address);
    function safeEngine() external view returns (address);
}

interface GetSafesLike {
    function getSafesAsc(address, address) external view returns (uint[] memory, address[] memory, bytes32[] memory);
}

interface SAFEEngineLike {
    function collateralTypes(bytes32) external view returns (uint, uint, uint, uint, uint);
    function coinBalance(address) external view returns (uint);
    function safes(bytes32, address) external view returns (uint, uint);
    function tokenCollateral(bytes32, address) external view returns (uint);
}

interface TaxCollectorLike {
    function collateralTypes(bytes32) external view returns (uint, uint);
    function globalStabilityFee() external view returns (uint);
}

interface OracleRelayerLike {
    function collateralTypes(bytes32) external view returns (OracleLike, uint, uint);
    function redemptionRate() external view returns (uint);

}

interface OracleLike {
    function getResultWithValidity() external view returns (bytes32, bool);
}

interface InstaReflexerAddress {
    function manager() external view returns (address);
    function safeEngine() external view returns (address);
    function taxCollector() external view returns (address);
    function oracleRelayer() external view returns (address);
    function GetSafes() external view returns (address);
}


contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}


contract Helpers is DSMath {
    /**
     * @dev get MakerDAO MCD Address contract
     */
    function getReflexerAddresses() public pure returns (address) {
        // TODO: Set the actual Reflexer address getter contract
        return 0x0000000000000000000000000000000000000000;
    }

    struct SafeData {
        uint id;
        address owner;
        string colType;
        uint collateral;
        uint debt;
        uint adjustedDebt;
        uint liquidatedCol;
        uint borrowRate;
        uint colPrice;
        uint liquidationRatio;
        address safeAddress;
    }

    struct ColInfo {
        uint borrowRate;
        uint price;
        uint liquidationRatio;
        uint debtCelling;
        uint totalDebt;
    }

    /**
     * @dev Convert String to bytes32.
    */
    function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
        require(bytes(str).length != 0, "String-Empty");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            result := mload(add(str, 32))
        }
    }

    /**
     * @dev Convert bytes32 to String.
    */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes32  _temp;
        uint count;
        for (uint256 i; i < 32; i++) {
            _temp = _bytes32[i];
            if( _temp != bytes32(0)) {
                count += 1;
            }
        }
        bytes memory bytesArray = new bytes(count);
        for (uint256 i; i < count; i++) {
                bytesArray[i] = (_bytes32[i]);
        }
        return (string(bytesArray));
    }


    function getFee(bytes32 collateralType) internal view returns (uint fee) {
        address taxCollector = InstaReflexerAddress(getReflexerAddresses()).taxCollector();
        (uint stabilityFee,) = TaxCollectorLike(taxCollector).collateralTypes(collateralType);
        uint globalStabilityFee = TaxCollectorLike(taxCollector).globalStabilityFee();
        fee = add(stabilityFee, globalStabilityFee);
    }

    function getColPrice(bytes32 collateralType) internal view returns (uint price) {
        address oracleRelayer = InstaReflexerAddress(getReflexerAddresses()).oracleRelayer();
        address safeEngine = InstaReflexerAddress(getReflexerAddresses()).safeEngine();
        (, uint safetyCRatio,) = OracleRelayerLike(oracleRelayer).collateralTypes(collateralType);
        (,,uint spotPrice,,) = SAFEEngineLike(safeEngine).collateralTypes(collateralType);
        price = rmul(safetyCRatio, spotPrice);
    }

    function getColRatio(bytes32 collateralType) internal view returns (uint ratio) {
        address oracleRelayer = InstaReflexerAddress(getReflexerAddresses()).oracleRelayer();
        (, ratio,) = OracleRelayerLike(oracleRelayer).collateralTypes(collateralType);
    }

    function getDebtCeiling(bytes32 collateralType) internal view returns (uint debtCeiling, uint totalDebt) {
        address safeEngine = InstaReflexerAddress(getReflexerAddresses()).safeEngine();
        (uint globalDebt,uint rate,,uint debtCeilingRad,) = SAFEEngineLike(safeEngine).collateralTypes(collateralType);
        debtCeiling = debtCeilingRad / 10 ** 45;
        totalDebt = rmul(globalDebt, rate);
    }
}


contract SafeResolver is Helpers {
     function getSafes(address owner) external view returns (SafeData[] memory) {
        address manager = InstaReflexerAddress(getReflexerAddresses()).manager();
        address safeManger = InstaReflexerAddress(getReflexerAddresses()).GetSafes();

        (uint[] memory ids, address[] memory handlers, bytes32[] memory collateralTypes) = GetSafesLike(safeManger).getSafesAsc(manager, owner);
        SafeData[] memory safes = new SafeData[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            (uint collateral, uint debt) = SAFEEngineLike(ManagerLike(manager).safeEngine()).safes(collateralTypes[i], handlers[i]);
            (,uint rate, uint priceMargin,,) = SAFEEngineLike(ManagerLike(manager).safeEngine()).collateralTypes(collateralTypes[i]);
            uint safetyCRatio = getColRatio(collateralTypes[i]);

            safes[i] = SafeData(
                ids[i],
                owner,
                bytes32ToString(collateralTypes[i]),
                collateral,
                debt,
                rmul(debt,rate),
                SAFEEngineLike(ManagerLike(manager).safeEngine()).tokenCollateral(collateralTypes[i], handlers[i]),
                getFee(collateralTypes[i]),
                rmul(priceMargin, safetyCRatio),
                safetyCRatio,
                handlers[i]
            );
        }
        return safes;
    }

    function getSafeById(uint id) external view returns (SafeData memory) {
        address manager = InstaReflexerAddress(getReflexerAddresses()).manager();
        address handler = ManagerLike(manager).safes(id);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(id);

        (uint collateral, uint debt) = SAFEEngineLike(ManagerLike(manager).safeEngine()).safes(collateralType, handler);
        (,uint rate, uint priceMargin,,) = SAFEEngineLike(ManagerLike(manager).safeEngine()).collateralTypes(collateralType);

        uint safetyCRatio = getColRatio(collateralType);

        uint feeRate = getFee(collateralType);
        SafeData memory safe = SafeData(
            id,
            ManagerLike(manager).ownsSAFE(id),
            bytes32ToString(collateralType),
            collateral,
            debt,
            rmul(debt,rate),
            SAFEEngineLike(ManagerLike(manager).safeEngine()).tokenCollateral(collateralType, handler),
            feeRate,
            rmul(priceMargin, safetyCRatio),
            safetyCRatio,
            handler
        );
        return safe;
    }

    function getColInfo(string[] memory name) public view returns (ColInfo[] memory) {
        ColInfo[] memory colInfo = new ColInfo[](name.length);

        for (uint i = 0; i < name.length; i++) {
            bytes32 collateralType = stringToBytes32(name[i]);
            (uint debtCeiling, uint totalDebt) = getDebtCeiling(collateralType);
            colInfo[i] = ColInfo(
                getFee(collateralType),
                getColPrice(collateralType),
                getColRatio(collateralType),
                debtCeiling,
                totalDebt
            );
        }
        return colInfo;
    }

}


contract RedemptionRateResolver is SafeResolver {
    function getRedemptionRate() external view returns (uint redemptionRate) {
        address oracleRelayer = InstaReflexerAddress(getReflexerAddresses()).oracleRelayer();
        redemptionRate = OracleRelayerLike(oracleRelayer).redemptionRate();
    }
}


contract InstaReflexerResolver is RedemptionRateResolver {
    string public constant name = "Reflexer-Resolver-v1";
}