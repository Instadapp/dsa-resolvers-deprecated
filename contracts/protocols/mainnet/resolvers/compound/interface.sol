pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface CTokenInterface {
    function exchangeRateStored() external view returns (uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function borrowBalanceStored(address) external view returns (uint);
    function totalBorrows() external view returns (uint);
    
    function underlying() external view returns (address);
    function balanceOf(address) external view returns (uint);
    function getCash() external view returns (uint);
}

interface TokenInterface {
    function decimals() external view returns (uint);
    function balanceOf(address) external view returns (uint);
}


interface OrcaleComp {
    function getUnderlyingPrice(address) external view returns (uint);
}

interface ComptrollerLensInterface {
    function markets(address) external view returns (bool, uint, bool);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function claimComp(address) external;
    function compAccrued(address) external view returns (uint);
    function borrowCaps(address) external view returns (uint);
    function borrowGuardianPaused(address) external view returns (bool);
    function oracle() external view returns (address);
    function compSpeeds(address) external view returns (uint);
}

interface CompReadInterface {
    struct CompBalanceMetadataExt {
        uint balance;
        uint votes;
        address delegate;
        uint allocated;
    }

    function getCompBalanceMetadataExt(
        TokenInterface comp,
        ComptrollerLensInterface comptroller,
        address account
    ) external returns (CompBalanceMetadataExt memory);
}