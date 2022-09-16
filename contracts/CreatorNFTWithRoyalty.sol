// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
contract CreatorNFTWithRoyalty is ERC721URIStorage {
    // helper function
    using Strings for uint256;

    // This event can be catched by the front-end to keep track of any activities
    event Minted(uint indexed tokenId, string indexed tokenUri);

    // assign an ownership
    address private owner;
    // marketplace address for approval
    address private marketplaceAddress;
    // who can receive the royalty
    address private royaltyReceiver;
    // keep track of token id
    uint private tokenCounter;
    // keep track of user royalty in pips (ie 2.50% = 250)
    uint private royaltyFeesPips;
    //keep track of each NFT price
    mapping(uint => uint) private itemPrice;

    // create an instance of ERC721 and ownership
    constructor(
        address _owner,
        address _marketplaceAddress,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        owner = _owner;
        marketplaceAddress = _marketplaceAddress;
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
     * @notice This function will allow creator to set their NFTs with a single price
     *         instead of set the price 1 by 1 manually
     * @param _price -> the price creator want to set
     */
    function setAllNftPrice(uint _price) external validPrice(_price) onlyOwner {
        // set the same price for all NFTs
        uint totalSupply = tokenCounter;
        for (uint i = 0; i < totalSupply; i++) {
            itemPrice[i] = _price;
        }
    }

    /**
     * @notice This mint function will allow users to mint their own NFTs, only creator can mint
     * @dev Token id will start from 0
     * @param _tokenUri -> the address pointing to the off-chain storage
     */
    function mint(string memory _tokenUri) public onlyOwner {
        //perform mint actions
        uint currentTokenId = tokenCounter;
        tokenCounter++;
        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, _tokenUri);
        emit Minted(currentTokenId, _tokenUri);
    }

    /**
     * @notice Mint multiple NFTs in a single transaction with different images
     * @param _tokenUri -> a list of metadata address
     *        _amount -> how many items to mint
     */
    function batchDNMint(string[] calldata _tokenUri, uint _amount)
        external
        validAmount(_amount)
        onlyOwner
    {
        // check the input params
        if (_tokenUri.length != _amount) revert CreatorNFT__InvalidParams();

        // mint for creator
        uint currentTokenId = tokenCounter;
        uint mintAmount = _amount + tokenCounter;
        for (uint i = currentTokenId; i < mintAmount; i++) {
            mint(_tokenUri[i]);
            // approve marketplace to spend NFTs
            approve(marketplaceAddress, i);
        }
    }

    /**
     * @notice Mint a multiple NFTs in a single transaction with single image
     * @param _tokenUri -> a single metadata address
     *        _amount -> how many items to mint
     */
    function batchSNMint(string calldata _tokenUri, uint _amount)
        external
        validAmount(_amount)
        onlyOwner
    {
        // mint for creator
        uint currentTokenId = tokenCounter;
        uint mintAmount = _amount + tokenCounter;
        for (uint i = currentTokenId; i < mintAmount; i++) {
            mint(_tokenUri);
            // approve marketplace to spend NFTs
            approve(marketplaceAddress, i);
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
        uint _amount,
        uint _price
    ) external validAmount(_amount) validPrice(_price) onlyOwner {
        // mint for creator
        uint currentTokenId = tokenCounter;
        uint mintAmount = _amount + tokenCounter;
        for (uint i = currentTokenId; i < mintAmount; i++) {
            // create token uri internally
            string memory tokenUri = getTokenURIWithID(_baseTokenUri, i);
            mint(tokenUri);

            // update price straight away (single price)
            itemPrice[i] = _price;
            // approve marketplace to spend NFTs
            approve(marketplaceAddress, i);
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
     * @dev This function will set the royaly fee state variable in term of pips
     *      (ie 2.55% = 255 _royaltyFeePips),
     *      make sure to check the unit when handling transfer. Also update the royalty
     *      receiver address
     * @param _royaltyFeesPips -> creator can change their royalty anytime
     *        _royaltyReceiver -> who can receive the royalty
     */
    function setReceiverAndRoyalty(
        address _royaltyReceiver,
        uint _royaltyFeesPips
    ) external onlyOwner validPrice(_royaltyFeesPips) {
        royaltyFeesPips = _royaltyFeesPips;
        royaltyReceiver = _royaltyReceiver;
    }

    /**
     * @notice Basic function to retrieve the current royalty of the creator in pips
     * @param _salePrice -> input the current sale price
     * @return receiver -> who is receiving the royality
     *         royaltyFee -> a calculated royalty value in pips
     */
    function getReceiverAndRoyalty(uint _salePrice)
        public
        view
        validPrice(_salePrice)
        returns (address receiver, uint royaltyFee)
    {
        royaltyFee = (_salePrice * royaltyFeesPips) / 10000;
        receiver = royaltyReceiver;
    }

    /**
     * @notice See who own this contract
     * @return owner -> creator who create a collection
     */
    function getCreator() public view returns (address) {
        return owner;
    }

    /**
     * @notice Query the total NFT the creator has minted
     * @return tokenCounter -> total minted NFT ie 2 = 2 NFT minted
     */
    function getTotalSupply() public view returns (uint) {
        return tokenCounter;
    }

    /**
     * @notice This will retrieve the price for a specific NFT
     * @param _tokenId -> which NFT to look for
     * @return itemPrice -> the price of the given NFT
     */
    function getItemPrice(uint _tokenId) public view returns (uint) {
        return itemPrice[_tokenId];
    }
}
