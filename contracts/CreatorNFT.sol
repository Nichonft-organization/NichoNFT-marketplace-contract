// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/INichoNFTMarketplace.sol";

// checking ownership
error CreatorNFT__InvalidCreator();
// checking if the mint amount is > 0
error CreatorNFT__InvalidMintAmount();
// checking if the mint amount match the number of token uri
error CreatorNFT__InvalidParams();
// checking if the price is >= 0;
error CreatorNFT__InvalidPrice();
// only owner
error CreatorNFT__InvalidOwner();

/**
 * @title Client's own NFT contract
 * @notice This contract provides functionalities for users to mint and set
 *         royality fee when they create NFTs using NichoNFT platform
 */
contract CreatorNFT is ERC721URIStorage, IHelper {
    // helper function
    using Strings for uint256;

    // This event can be catched by the front-end to keep track of any activities
    event Minted(uint indexed tokenId, string indexed tokenUri);

    // Interface for Nicho NFT Marketplace Contract
    INichoNFTMarketplace public nichonftMarketplaceContract;

    // assign an ownership
    address private owner;

    // keep track of token id
    uint private tokenCounter;
    // keep track of user royalty in percentage
    uint private royaltyFee;

    // create an instance of ERC721 and ownership
    constructor(
        address _owner,
        address _marketplaceAddress,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        owner = _owner;
        nichonftMarketplaceContract = INichoNFTMarketplace(_marketplaceAddress);
    }

    // checking if the amount is valid
    modifier validAmount(uint _amount) {
        if (_amount <= 0) revert CreatorNFT__InvalidMintAmount();
        _;
    }

    // checking if the price is valid
    modifier validPrice(uint _price) {
        if (_price <= 0) revert CreatorNFT__InvalidPrice();
        _;
    }

    // make sure only owner can do it
    modifier onlyOwner() {
        if (msg.sender != owner) revert CreatorNFT__InvalidOwner();
        _;
    }

    /**
     * @notice This mint function will allow users to mint their own NFTs, only creator can mint
     * @dev Token id will start from 0
     * @param _tokenUri -> the address pointing to the off-chain storage
     */
    function mint(
        string memory _tokenUri,
        uint price, 
        PayType _payType
    ) public onlyOwner validPrice(price) {
        require(_payType != PayType.NONE, "MINT: Invalid pay type");

        //perform mint actions
        uint currentTokenId = tokenCounter;
        tokenCounter++;
        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, _tokenUri);

        // approve NFT
        // approve(address(nichonftMarketplaceContract), _tokenId);
        if (isApprovedForAll(_msgSender(), address(nichonftMarketplaceContract)) == false) {
            setApprovalForAll(address(nichonftMarketplaceContract), true);
        }

        // List NFT directly
        nichonftMarketplaceContract.listItemToMarketFromMint(
            address(this),
            currentTokenId,
            price,
            _payType,
            msg.sender
        );

        emit Minted(currentTokenId, _tokenUri);
    }

    /**
     * @notice Mint multiple NFTs in a single transaction with different images
     * @param _tokenUri -> a list of metadata address
     *        _amount -> how many items to mint
     */
    function batchDNMint(
        string[] calldata _tokenUri,         
        uint _price, 
        uint _amount,
        PayType _payType
    )
        external
        validAmount(_amount)        
        onlyOwner
    {
        // check the input params
        if (_tokenUri.length != _amount) revert CreatorNFT__InvalidParams();

        // mint for creator
        uint mintAmount = _amount;
        for (uint i = 0; i < mintAmount; i++) {
            mint(_tokenUri[i], _price, _payType);
        }
    }

    /**
     * @notice Mint a multiple NFTs in a single transaction with single image
     * @param _tokenUri -> a single metadata address
     *        _amount -> how many items to mint
     */
    function batchSNMint(
        string calldata _tokenUri, 
        uint _price, 
        uint _amount,
        PayType _payType
    )
        external
        validAmount(_amount)
        onlyOwner
    {
        // mint for creator
        uint mintAmount = _amount;
        for (uint i = 0; i < mintAmount; i++) {
            mint(_tokenUri, _price, _payType);
        }
    }

    /**
     * @notice Mint a multiple NFTs in a single transaction with single image and will be listed to marketplace straight away
     * @param _baseTokenUri -> a base token uri address used for creating multiple token uri
     *        _amount -> how many items to mint
     *        _price -> set the nft price while minting
     */
    function batchIDMint(
        string calldata _baseTokenUri,
        uint _price, 
        uint _amount,
        PayType _payType
    ) external validAmount(_amount) onlyOwner {
        // mint for creator
        uint mintAmount = _amount;
        for (uint i = 0; i < mintAmount; i++) {
            // create token uri internally
            string memory tokenUri = getTokenURIWithID(_baseTokenUri, i);
            mint(tokenUri, _price, _payType);
        }
    }

    /**
     * Function copied from NichoNft.sol to create token uri
     */
    function getTokenURIWithID(string memory _baseTokenURI, uint nftID)
        private
        pure
        returns (string memory)
    {
        require(bytes(_baseTokenURI).length > 0, "Invalid base URI");

        return string(abi.encodePacked(_baseTokenURI, nftID.toString()));
    }

    /**
     * @dev This function will set the royaltyFee state variable in term of %,
     *      make sure to convert the unit when handling transfer
     * @param _royaltyFee -> creator can change their earning anytime
     */
    function setRoyaltyFeePercentage(uint _royaltyFee)
        external
        onlyOwner
    {
        royaltyFee = _royaltyFee;
    }

    /**
     * @notice Basic function to retrieve the current royalty state in percentage
     * @return royalty -> current royalty for user in percentage
     */
    function getRoyaltyFeePercentage() public view returns (uint royalty) {
        royalty = royaltyFee;
    }

    /**
     * @notice See who own this contract
     * @return owner -> creator who create a collection
     */
    function getCreator() public view returns (address) {
        return owner;
    }

    /**
     * @notice See who own this contract
     * @param _owner -> new owner address
     */
    function transferOwnership(address _owner) external onlyOwner {
        require(owner != _owner, "Same owner address");
        require(_owner != address(0x0), "Invalid address");
        owner = _owner;
    }

    /**
     * @notice Query the total NFT the creator has minted
     * @return tokenCounter -> total minted NFT ie 2 = 2 NFT minted
     */
    function getTotalSupply() public view returns (uint) {
        return tokenCounter;
    }
}