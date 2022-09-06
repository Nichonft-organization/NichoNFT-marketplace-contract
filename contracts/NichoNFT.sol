/**
 * Submitted for verification at BscScan.com on 2022-04-2
 */

// File: contracts/NichoNFT.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IOERC721.sol";
import "./CreatorNFT.sol";

contract NichoNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // CommissionFee percent is 2.5%
    uint256 public commissionFee = 25;
    uint256 public denominator = 10;

    struct Item {
        uint256 id;
        address creater;
        string uri;
    }
    // token address => tokenId => item
    mapping(address => mapping(uint256 => Item)) public Items;

    address payable public _feeAddress;
    // user wallet => inBlackList  for charity
    mapping(address => bool) public whitelist;

    // token address => tokenId => inBlackList
    mapping(address => mapping(uint => bool)) public blackList;
    // token address => tokenId => price
    mapping(address => mapping(uint => uint)) public price;

    event Purchase(
        address tokenAddress,
        address indexed previousOwner,
        address indexed newOwner,
        uint price,
        uint nftID,
        string uri
    );

    event Added(
        address indexed minter,
        address tokenAddress,
        uint price,
        uint nftID,
        string uri
    );

    event PriceUpdate(
        address tokenAddress,
        address indexed owner,
        uint oldPrice,
        uint newPrice,
        uint nftID
    );

    event UpdateListStatus(
        address tokenAddress,
        address indexed owner,
        uint nftID,
        bool isListed
    );

    event UpdateBlackList(
        address tokenAddress,
        uint256 nftID,
        bool isBlackList
    );

    constructor(address _owner) ERC721("NichoNFT", "NICHO") {
        require(_owner != address(0x0), "Invalid address");
        _feeAddress = payable(_owner);
    }

    modifier notBlackList(address tokenAddress, uint256 _tokenId) {
        require(
            blackList[tokenAddress][_tokenId] == false,
            "TokenId is in blackList"
        );
        _;
    }

    // Create item
    function mint(
        string memory _tokenURI,
        address _toAddress,
        uint _price
    ) public returns (uint) {
        require(_toAddress != address(0x0), "Invalid address");

        uint _tokenId = totalSupply();
        price[address(this)][_tokenId] = _price;

        _safeMint(_toAddress, _tokenId);

        approve(address(this), _tokenId);

        Item storage item = Items[address(this)][_tokenId];
        item.uri = _tokenURI;
        item.id = _tokenId;
        item.creater = _toAddress;

        emit Added(_toAddress, address(this), _price, _tokenId, _tokenURI);

        return _tokenId;
    }

    function addItemToMarket(
        address tokenAddress,
        uint256 tokenId,
        uint256 askingPrice
    ) external {
        require(
            Items[tokenAddress][tokenId].creater == address(0),
            "Item is already up sale"
        );

        IOERC721 tokenContract = IOERC721(tokenAddress);
        require(
            tokenContract.ownerOf(tokenId) == msg.sender,
            "Not right to add nft"
        );
        require(
            tokenContract.getApproved(tokenId) == address(this),
            "Approve NFT"
        );

        Item storage item = Items[tokenAddress][tokenId];
        item.uri = tokenContract.tokenURI(tokenId);
        item.id = tokenId;
        item.creater = msg.sender;

        price[tokenAddress][tokenId] = askingPrice;

        emit Added(
            msg.sender,
            tokenAddress,
            askingPrice,
            tokenId,
            tokenContract.tokenURI(tokenId)
        );
    }

    // Batch creation same images and different names
    function batchDNMint(
        string[] calldata _tokenURI,
        address _toAddress,
        uint _price,
        uint _amount
    ) external {
        require(_amount > 0, "wrong amount");
        require(_tokenURI.length == _amount, "Invalid params");

        for (uint idx = 0; idx < _amount; idx++) {
            mint(_tokenURI[idx], _toAddress, _price);
        }
    }

    // Batch option with same name and images
    function batchSNMint(
        string memory _tokenURI,
        address _toAddress,
        uint _price,
        uint _amount
    ) external {
        require(_amount > 0, "wrong amount");

        for (uint idx = 0; idx < _amount; idx++) {
            mint(_tokenURI, _toAddress, _price);
        }
    }

    // Batch option with different images and increased nftID
    function batchIDMint(
        string memory _baseTokenURI,
        address _toAddress,
        uint _price,
        uint _amount
    ) external {
        require(_amount > 0, "wrong amount");

        for (uint idx = 0; idx < _amount; idx++) {
            string memory _tokenURI = getTokenURIWithID(_baseTokenURI, idx);
            mint(_tokenURI, _toAddress, _price);
        }
    }

    function getTokenURIWithID(string memory _baseTokenURI, uint nftID)
        private
        pure
        returns (string memory)
    {
        require(bytes(_baseTokenURI).length > 0, "Invalid base URI");

        return string(abi.encodePacked(_baseTokenURI, nftID.toString()));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return Items[address(this)][tokenId].uri;
    }

    // TokenId
    function buy(address tokenAddress, uint _id)
        external
        payable
        notBlackList(tokenAddress, _id)
    {
        _validate(tokenAddress, _id);
        IOERC721 tokenContract = IOERC721(tokenAddress);

        address _previousOwner = tokenContract.ownerOf(_id);
        address _newOwner = msg.sender;

        _trade(tokenAddress, _id);

        emit Purchase(
            tokenAddress,
            _previousOwner,
            _newOwner,
            price[tokenAddress][_id],
            _id,
            tokenContract.tokenURI(_id)
        );
    }

    function _validate(address tokenAddress, uint _id) internal {
        IOERC721 tokenContract = IOERC721(tokenAddress);
        require(
            tokenContract.getApproved(_id) == address(this),
            "Not approved from owner"
        );
        require(
            msg.value >= price[tokenAddress][_id],
            "Error, the amount is lower"
        );
        require(
            msg.sender != tokenContract.ownerOf(_id),
            "Can not buy what you own"
        );
    }

    function _trade(address tokenAddress, uint _id) internal {
        IOERC721 tokenContract = IOERC721(tokenAddress);

        bool isInWhiteList = whitelist[msg.sender] ||
            whitelist[tokenContract.ownerOf(_id)];

        address payable _buyer = payable(msg.sender);
        address payable _owner = payable(tokenContract.ownerOf(_id));

        if (tokenAddress == address(this)) _transfer(_owner, _buyer, _id);
        else tokenContract.safeTransferFrom(_owner, msg.sender, _id);

        // commission cut
        uint _commissionValue = (price[tokenAddress][_id] * commissionFee) /
            denominator /
            100;

        if (isInWhiteList) _commissionValue = 0;

        uint _sellerValue = price[tokenAddress][_id] - _commissionValue;

        _owner.transfer(_sellerValue);

        if (_commissionValue > 0) {
            _feeAddress.transfer(_commissionValue);
        }

        // If buyer sent more than price, we send them back their rest of funds
        if (msg.value > price[tokenAddress][_id]) {
            _buyer.transfer(msg.value - price[tokenAddress][_id]);
        }
    }

    // Update owner's NFT price
    function updatePrice(
        address tokenAddress,
        uint _tokenId,
        uint _price
    ) public notBlackList(tokenAddress, _tokenId) returns (bool) {
        // Item memory item = Items[tokenAddress][_tokenId];
        // require(item.id == _tokenId, "Not added into market");
        uint oldPrice = price[tokenAddress][_tokenId];
        IOERC721 tokenContract = IOERC721(tokenAddress);

        // require(oldPrice != _price, "This price already set");
        require(
            msg.sender == tokenContract.ownerOf(_tokenId),
            "Error, you are not the owner"
        );
        price[tokenAddress][_tokenId] = _price;

        emit PriceUpdate(tokenAddress, msg.sender, oldPrice, _price, _tokenId);
        return true;
    }

    // Update the fee address
    function updateFeeAddress(address newFeeAddress) external onlyOwner {
        require(_feeAddress != newFeeAddress, "Fee address: already set");
        require(
            newFeeAddress != address(0x0),
            "Zero address is not allowed for fee address"
        );

        _feeAddress = payable(newFeeAddress);
    }

    // BlackList
    function addBlackList(address tokenAddress, uint256 _tokenId)
        external
        onlyOwner
    {
        require(
            blackList[tokenAddress][_tokenId] == false,
            "Already in blacklist"
        );
        blackList[tokenAddress][_tokenId] = true;

        emit UpdateListStatus(tokenAddress, msg.sender, _tokenId, false);
        emit UpdateBlackList(tokenAddress, _tokenId, true);
    }

    function removeBlackList(address tokenAddress, uint256 _tokenId)
        external
        onlyOwner
    {
        require(blackList[tokenAddress][_tokenId], "Not exist in blacklist");

        blackList[tokenAddress][_tokenId] = false;

        emit UpdateBlackList(tokenAddress, _tokenId, false);
    }

    // WhiteList
    function addWhiteList(address charity) external onlyOwner {
        require(whitelist[charity] == false, "Already in whitelist");
        whitelist[charity] = true;
    }

    function removeWhiteList(address charity) external onlyOwner {
        require(whitelist[charity] == true, "Already in whitelist");
        whitelist[charity] = false;
    }

    function updateFee(uint256 _fee) external onlyOwner {
        require(commissionFee != _fee, "Already set");
        commissionFee = _fee;
    }

    // Withdraw ERC20 tokens
    // For unusual case, if customers sent their any ERC20 tokens into marketplace, we need to send it back to them
    function withdrawTokens(address _token, uint256 _amount)
        external
        onlyOwner
    {
        require(
            IERC20(_token).balanceOf(address(this)) >= _amount,
            "Wrong amount"
        );

        IERC20(_token).transfer(msg.sender, _amount);
    }

    // For unusual case,
    function withdrawBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //-----------------------------------------------------------------------------------------
    /**
     * For migration part
     */

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
     */
    function deploy() external {
        uint id = collectionId[msg.sender];
        CreatorNFT nftContract = new CreatorNFT(msg.sender);
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
     * @notice This will batch list all minted NFTs in the marketplace from the collection contract
     * @param _collection -> this is the deployed collection contract address
     */
    function batchList(CreatorNFT _collection) external {
        // see how many items in the collection contract
        uint totalItems = _collection.getTotalSupply();

        // transfer all the tokens to marketplace and update the price and Item for listing
        for (uint _tokenId = 0; _tokenId < totalItems; _tokenId++) {
            // transfer from the collection contract (already approved after minting)
            _collection.transferFrom(msg.sender, address(this), _tokenId);

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
