pragma solidity ^0.6.0;

import {DSMath} from "../../common/math.sol";
import {VatLike, SpotLike, JugLike, InstaMcdAddress} from "./interface.sol";


contract Helpers is DSMath {
    /**
     * @dev get MakerDAO MCD Address contract
     */
    function getMcdAddresses() public pure returns (address) {
        return 0xF23196DF1C440345DE07feFbe556a5eF0dcD29F0;
    }

    struct VaultData {
        uint id;
        address owner;
        string colType;
        uint collateral;
        uint art;
        uint debt;
        uint liquidatedCol;
        uint borrowRate;
        uint colPrice;
        uint liquidationRatio;
        address vaultAddress;
    }

    struct ColInfo {
        uint borrowRate;
        uint price;
        uint liquidationRatio;
        uint vaultDebtCelling;
        uint vaultDebtFloor;
        uint vaultTotalDebt;
        uint totalDebtCelling;
        uint TotalDebt;
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


    function getFee(bytes32 ilk) internal view returns (uint fee) {
        address jug = InstaMcdAddress(getMcdAddresses()).jug();
        (uint duty,) = JugLike(jug).ilks(ilk);
        uint base = JugLike(jug).base();
        fee = add(duty, base);
    }

    function getColPrice(bytes32 ilk) internal view returns (uint price) {
        address spot = InstaMcdAddress(getMcdAddresses()).spot();
        address vat = InstaMcdAddress(getMcdAddresses()).vat();
        (, uint mat) = SpotLike(spot).ilks(ilk);
        (,,uint spotPrice,,) = VatLike(vat).ilks(ilk);
        price = rmul(mat, spotPrice);
    }

    function getColRatio(bytes32 ilk) internal view returns (uint ratio) {
        address spot = InstaMcdAddress(getMcdAddresses()).spot();
        (, ratio) = SpotLike(spot).ilks(ilk);
    }

    function getDebtFloorAndCeiling(bytes32 ilk) internal view returns (uint, uint, uint, uint, uint) {
        address vat = InstaMcdAddress(getMcdAddresses()).vat();
        (uint totalArt,uint rate,, uint vaultDebtCellingRad, uint vaultDebtFloor) = VatLike(vat).ilks(ilk);
        uint vaultDebtCelling = vaultDebtCellingRad / 10 ** 45;
        uint vaultTotalDebt = rmul(totalArt, rate);

        uint totalDebtCelling = VatLike(vat).Line();
        uint totalDebt = VatLike(vat).debt();
        return (
            vaultDebtCelling,
            vaultTotalDebt,
            vaultDebtFloor,
            totalDebtCelling,
            totalDebt
        );
    }
}