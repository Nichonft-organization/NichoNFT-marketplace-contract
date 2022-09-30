// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

/// Owned collection contract to be deployed from Factory
import "./CreatorNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Mock marketplace contract
 * @notice This is a mock contract to test the functionalities of the contract collection
 */
contract OwnedCollectionFactory is Ownable{
    // testing purposes, need to change back to 0.05
    uint public constant DEPLOY_FEE = 0.05 ether;

    // marketplace address
    address public marketplaceAddress;

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

    constructor(
        address _marketplaceAddress
    ) {
        require(_marketplaceAddress != address(0x0), "Invalid address");
        marketplaceAddress = _marketplaceAddress;
    }

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
            marketplaceAddress,
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

    // Withdraw Fee to admin
    function withdrawETH(uint _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Wrong amount");

        payable(msg.sender).transfer(_amount);
    }
}