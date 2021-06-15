pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}