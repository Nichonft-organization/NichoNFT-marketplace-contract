// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./IHelper.sol";

// This is for other NFT contract
interface INichoNFTMarketplace is IHelper {
    // List an NFT/NFTs on marketplace as same price with fixed price sale
    function listItemToMarketFromMint(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 askingPrice,
        PayType _payType
    ) external;
}