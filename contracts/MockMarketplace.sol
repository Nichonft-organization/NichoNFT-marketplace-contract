// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./CreatorNFT.sol";

/**
 * @title Mock marketplace contract
 * @notice This is a mock contract to test the functionalities of the contract collection
 */
contract MockMarketplace {
    struct Item {
        uint256 id;
        address creater;
        string uri;
    }
    // token address => tokenId => item
    mapping(address => mapping(uint256 => Item)) public Items;
    mapping(address => mapping(uint => uint)) public price;
    // testing purposes, need to change back to 0.05
    uint public constant DEPLOY_FEE = 0.05 ether;

    event Added(
        address indexed minter,
        address tokenAddress,
        uint price,
        uint nftID,
        string uri
    );
    // make sure only collection owner can batch mint
    error InvalidOwner();
    // throw when the deploy fees is not enough
    error InvalidDeployFees();

    // This event will be emited after a new creator contract has been deployed
    // It will be used to interact with Moralis cloud function and store them in Moralis database
    event Deployed(
        address indexed creatorAddress,
        address indexed contractAddress,
        uint indexed currentCollectionId
    );
    // This state variable will store the deployed contract on-chain
    mapping(address => mapping(uint => address)) private database;
    // This will keep track of the creator's collection, as creator can have multiple collections
    mapping(address => uint) private collectionId;

    /**
     * @notice This function will deploy a brand new contract when creator create a new collection
     *         It will store the deployed address on-chain
     * @dev The collectionId will start from 0
     *      deployFees can be set in the frontend
     * @param _name -> collection name
     *        _symbol -> collection symbol
     *        _deployFees -> base price to create a collection (should be in wei)
     */
    function deploy(string calldata _name, string calldata _symbol)
        external
        payable
    {
        // creator need to pay 0.05 BNB to create his own collection
        if (msg.value < DEPLOY_FEE) revert InvalidDeployFees();
        uint id = collectionId[msg.sender];
        CreatorNFT nftContract = new CreatorNFT(
            msg.sender,
            address(this),
            _name,
            _symbol
        );
        database[msg.sender][id] = address(nftContract);
        collectionId[msg.sender]++;
        emit Deployed(msg.sender, address(nftContract), id);
    }

    /**
     * @notice This function will return the deployed contract address
     * @param _creatorAddress -> identify the creator
     *        _collectionId -> identify the collection
     * @return Deployed address to interact with
     */
    function getCreatorContractAddress(
        address _creatorAddress,
        uint _collectionId
    ) public view returns (address) {
        return database[_creatorAddress][_collectionId];
    }

    /**
     * @notice Get the current collection id. It is useful to keep track of how many collection creator have
     * @dev Collection id start from 0
     * @param _creatorAddress -> identify the creator
     * @return A current id of collection ie. 1 => 1 collections deployed
     */
    function getCurrentCollectionId(address _creatorAddress)
        external
        view
        returns (uint)
    {
        return collectionId[_creatorAddress];
    }

    /**
     * @notice This batchlist function will batch mint NFTs, set the price and batch list to marketplace
     * @param _collection -> this is the deployed collection contract address
     */
    function batchList(CreatorNFT _collection) external {
        // if not owner of this collection, throw error
        if (_collection.getCreator() != msg.sender) revert InvalidOwner();

        // see how many items in the collection contract
        uint totalItems = _collection.getTotalSupply();

        // update the price and Item for listing
        for (uint _tokenId = 0; _tokenId < totalItems; _tokenId++) {
            // set the price in the marketplace
            uint itemPrice = _collection.getItemPrice(_tokenId);
            price[address(_collection)][_tokenId] = itemPrice;

            // update the marketplace items for listing
            string memory tokenUri = _collection.tokenURI(_tokenId);
            Items[address(_collection)][_tokenId] = Item(
                _tokenId,
                msg.sender,
                tokenUri
            );

            // log the details
            emit Added(
                msg.sender,
                address(_collection),
                itemPrice,
                _tokenId,
                tokenUri
            );
        }
    }
    //-----------------------------------------------------------------------------------------
}
