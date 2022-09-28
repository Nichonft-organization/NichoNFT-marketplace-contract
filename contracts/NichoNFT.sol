/**
 * Submitted for verification at BscScan.com on 2022-04-2
 */

// File: contracts/NichoNFT.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/INichoNFTMarketplace.sol";

contract NichoNFT is ERC721Enumerable, IHelper, Ownable {
    using Strings for uint256;

    // Interface for Nicho NFT Marketplace Contract
    INichoNFTMarketplace public nichonftMarketplaceContract;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(INichoNFTMarketplace _nichonftMarketplace) ERC721("NichoNFT", "NICHO") {
        nichonftMarketplaceContract = _nichonftMarketplace;
    }

    // Create item
    function mint(
        string memory _tokenURI, 
        address _toAddress, 
        uint price, 
        PayType _payType
    ) public returns (uint) {
        require(_toAddress != address(0x0), "Invalid address");

        uint _tokenId = totalSupply(); 

        _safeMint(_toAddress, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        // approve NFT
        approve(address(nichonftMarketplaceContract), _tokenId);

        // List NFT directly
        nichonftMarketplaceContract.listItemToMarket(
            address(this),
            _tokenId,
            price,
            _payType
        );

        return _tokenId;
    }

    /**
     * @dev Batch creation same images and different names
     * 
     * Requirement:
     * 
     * - _amount: NFT amount to mint
     */
    function batchDNMint(
        string[] calldata _tokenURI, 
        address _toAddress, 
        uint _price, 
        uint _amount,
        PayType _payType
    ) external {
        require(_amount > 0, "wrong amount");
        require(_tokenURI.length == _amount, "Invalid params");

        for(uint idx = 0; idx < _amount; idx++) {
            mint(_tokenURI[idx], _toAddress, _price, _payType);
        }
    }

    /**
     * @dev Batch option with same name and images
     * 
     * Requirement:
     * 
     * - _amount: NFT amount to mint
     */
    function batchSNMint(
        string memory _tokenURI, 
        address _toAddress, 
        uint _price, 
        uint _amount,
        PayType _payType
    ) external {
        require(_amount > 0, "wrong amount");

        for(uint idx = 0; idx < _amount; idx++) {
            mint(_tokenURI, _toAddress, _price, _payType);
        }
    }

    /**
     * @dev Batch option with different images and increased nftID
     * 
     * Requirement:
     * 
     * - _amount: NFT amount to mint
     */
    function batchIDMint(
        string memory _baseTokenURI, 
        address _toAddress, 
        uint _price, 
        uint _amount,
        PayType _payType
    ) external {
        require(_amount > 0, "wrong amount");

        for(uint idx = 0; idx < _amount; idx++) {
            string memory _tokenURI = getTokenURIWithID(_baseTokenURI, idx);
            mint(_tokenURI, _toAddress, _price, _payType);
        }
    }

    /// Get TokenURI for batchIDMint
    function getTokenURIWithID(string memory _baseTokenURI, uint tokenId) private pure returns(string memory) {
        require(bytes(_baseTokenURI).length > 0, "Invalid base URI");

        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view  override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _tokenURIs[tokenId];
    }
}