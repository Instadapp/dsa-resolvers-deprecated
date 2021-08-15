// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {DSMath} from "../libs/DSMath.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

interface PriceFeedOracle {
    function fetchPrice() external returns (uint256);
}

interface TroveManagerLike {

    function getEntireDebtAndColl(address _borrower)
        external
        view
        returns (
            uint256 debt,
            uint256 coll,
            uint256 pendingLUSDDebtReward,
            uint256 pendingETHReward
        );
}


contract Helpers {
    using DSMath for uint256;
    TroveManagerLike internal constant troveManager = TroveManagerLike(0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2);

    PriceFeedOracle internal constant priceFeedOracle = PriceFeedOracle(0x4c517D4e2C851CA76d7eC94B805269Df0f2201De);

    struct Trove {
        uint256 collateral;
        uint256 debt;
        uint netValue;
    }
}
 
contract NewLiquityResolver is Helpers {
    using DSMath for uint256;

    function fetchETHPrice() public returns (uint256) {
        return priceFeedOracle.fetchPrice();
    }

    function getTrove(address[] memory owners) public returns (Trove[] memory) {
        uint256 oracleEthPrice = fetchETHPrice();
        Trove[] memory troveArray = new Trove[](owners.length);
        for (uint i = 0; i < owners.length; i++) {
            (uint256 debt, uint256 collateral, , ) = troveManager.getEntireDebtAndColl(owners[i]);
            uint netValue = SafeMath.sub(((collateral.wmul(oracleEthPrice)).wdiv(10**18)), debt);
            troveArray[i] = Trove(collateral, debt, netValue);        
        }
        return troveArray;
    }
}