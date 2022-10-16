// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// Interface for NFTBlackList
interface INFTBlackList {
    function getRoyaltyFeePercentage() external view returns (uint royalty);
    function getCreator() external view returns (address);
}