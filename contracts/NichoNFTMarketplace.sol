/**
 * Submitted for verification at BscScan.com on 2022-09-29
 */

// File: contracts/NichoNFTMarketplace.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

// Openzeppelin libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./MarketplaceHelper.sol";
import "./interfaces/INichoNFTAuction.sol";

// NichoNFT marketplace
contract NichoNFTMarketplace is Ownable, MarketplaceHelper, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    INichoNFTAuction nichonftAuctionContract;

    // Offer Item
    struct OfferItem {
        uint256 price;
        uint256 expireTs;
        bool isLive;
        PayType payType;
    }

    // Marketplace Listed Item
    // token address => tokenId => item
    mapping(address => mapping(uint256 => Item)) private items;

    // Offer Item
    // token address => token id => creator => offer item
    mapping(address => mapping(uint256 => mapping(address => OfferItem))) private offerItems;

    // NichoNFT and other created owned-collections need to list it while minting.
    // nft contract address => tokenId => item
    mapping(address => bool) public directListable;

    /**
     * @dev Emitted when `token owner` list/mint/auction NFT on marketplace
     * - expire_at: in case of auction sale
     * - auction_id: in case of auction sale
     */
    event ListedNFT(
        address token_address,
        uint token_id,
        address indexed creator,
        uint price,
        PayType pay_type,

        uint expire_at, 
        uint80 auction_id
    );

    /**
     * @dev Emitted when `token owner` cancel NFT from marketplace
     */
    event ListCancel(
        address token_address,
        uint token_id,
        address indexed owner,
        bool is_listed
    );

    /**
     * @dev Emitted when create offer for NFT on marketplace
     */
    event Offers(
        address token_address,
        uint token_id,
        address indexed creator,
        uint price,
        uint expire_at,
        PayType pay_type
    );

    /**
     * @dev Emitted when `Offer creator` cancel offer of NFT on marketplace
     */
    event OfferCancels(
        address token_address,
        uint token_id,
        address indexed creator
    );

    /**
     * @dev Emitted when `token owner` list NFT on marketplace
     */
    event TradeActivity(
        address token_address,
        uint token_id,
        address indexed previous_owner,
        address indexed new_owner,
        uint price,
        PayType pay_type
    );

    // Initialize configurations
    constructor(
        address _blacklist,
        address _nicho,
        address _nichonft,
        INichoNFTAuction _nichonftAuctionContract
    ) MarketplaceHelper(_blacklist, _nicho) {
        directListable[_nichonft] = true;
        nichonftAuctionContract = _nichonftAuctionContract;
    }


    // Middleware to check if NFT is already listed on not.
    modifier onlyListed(address tokenAddress, uint256 tokenId) {
        Item memory item = items[tokenAddress][tokenId];
        require(item.isListed == true, "Token: not listed on marketplace");

        address tokenOwner = IERC721(tokenAddress).ownerOf(tokenId);
        require(item.creator == tokenOwner, "You are not creator");
        _;
    }

    // Middleware to check if NFT is already listed on not.
    modifier onlyListableContract() {
        require(
            directListable[msg.sender] == true,
            "Listable: not allowed to list"
        );
        _;
    }

    // List NFTs on marketplace as same price with fixed price sale
    function batchListItemToMarket(
        address[] calldata tokenAddress,
        uint256[] calldata tokenId,
        uint256 askingPrice,
        PayType _payType
    ) external {
        require(
            tokenAddress.length == tokenId.length,
            "Array size does not match"
        );
        require(_payType != PayType.NONE, "Invalid pay type");

        for (uint idx = 0; idx < tokenAddress.length; idx++) {
            address _tokenAddress = tokenAddress[idx];
            uint _tokenId = tokenId[idx];

            // List
            listItemToMarket(_tokenAddress, _tokenId, askingPrice, _payType);
        }
    }

    // List an NFT on marketplace as same price with fixed price sale
    function listItemToMarket(
        address tokenAddress,
        uint256 tokenId,
        uint256 askingPrice,
        PayType _payType
    )
        public
        notBlackList(tokenAddress, tokenId)
        onlyTokenOwner(tokenAddress, tokenId)
    {
        address _tokenAddress = tokenAddress;
        uint256 _tokenId = tokenId;
        // Listing
        require(_payType != PayType.NONE, "Invalid pay type");

        // Token owner need to approve NFT on Token Contract first so that Listing works.
        require(checkApproval(_tokenAddress, _tokenId), "First, Approve NFT");


        Item storage item = items[_tokenAddress][_tokenId];
        item.price = askingPrice;
        item.payType = _payType;
        item.isListed = true;
        // creator
        item.creator = msg.sender;

        // cancel auction
        nichonftAuctionContract.cancelAuctionFromFixedSaleCreation(_tokenAddress, _tokenId);

        emit ListedNFT(_tokenAddress, _tokenId, msg.sender, askingPrice, _payType, 0, 0);
    }

    // List an NFT/NFTs on marketplace as same price with fixed price sale
    function listItemToMarketFromMint(
        address tokenAddress,
        uint256 tokenId,
        uint256 askingPrice,
        PayType _payType,
        address _creator
    ) external onlyListableContract {
        Item storage item = items[tokenAddress][tokenId];
        item.price = askingPrice;
        item.payType = _payType;
        item.isListed = true;

        // creator
        item.creator = _creator;

        emit ListedNFT(tokenAddress, tokenId, _creator, askingPrice, _payType, 0, 0);
    }

    // Cancel nft listing
    function cancelListing(
        address tokenAddress,
        uint tokenId
    )   external
        onlyTokenOwner(tokenAddress, tokenId)
    {
        // scope for _token{Id, Address}, price, avoids stack too deep errors
        uint _tokenId = tokenId;
        address _tokenAddress = tokenAddress;

        if (items[_tokenAddress][_tokenId].isListed) {
            Item storage item = items[_tokenAddress][_tokenId];
            item.isListed = false;
            item.price = 0;
        }

        if (nichonftAuctionContract.getAuctionStatus(_tokenAddress, _tokenId) == true) {            
            // cancel auction
            nichonftAuctionContract.cancelAuctionFromFixedSaleCreation(_tokenAddress, _tokenId);
        }

        emit ListCancel(_tokenAddress, _tokenId, msg.sender, false);
    }

    /**
     * @dev Purchase the listed NFT with BNB.
     */
    function buy(address tokenAddress, uint tokenId)
        external
        payable
        nonReentrant
        notBlackList(tokenAddress, tokenId)
        onlyListed(tokenAddress, tokenId)
    {
        _validate(tokenAddress, tokenId, PayType.BNB, msg.value);

        IERC721 tokenContract = IERC721(tokenAddress);
        address _previousOwner = tokenContract.ownerOf(tokenId);
        address _newOwner = msg.sender;

        _trade(tokenAddress, tokenId, msg.value);

        emit TradeActivity(
            tokenAddress,
            tokenId,
            _previousOwner,
            _newOwner,
            msg.value,
            PayType.BNB
        );
    }

    /**
     * @dev Purchase the listed NFT with Nicho Token.
     */
    function buyWithNichoToken(
        address tokenAddress,
        uint tokenId,
        uint amount // Token amount
    )
        external
        nonReentrant
        notBlackList(tokenAddress, tokenId)
        onlyListed(tokenAddress, tokenId)
    {
        _validate(tokenAddress, tokenId, PayType.NICHO, amount);

        IERC721 tokenContract = IERC721(tokenAddress);
        address _previousOwner = tokenContract.ownerOf(tokenId);
        address _newOwner = msg.sender;

        _trade(tokenAddress, tokenId, amount);

        emit TradeActivity(
            tokenAddress,
            tokenId,
            _previousOwner,
            _newOwner,
            amount,
            PayType.NICHO
        );
    }

    /**
     * @dev Check validation for Trading conditions
     *
     * Requirement:
     *
     * - `amount` is token amount, should be greater than equal seller price
     */
    function _validate(
        address tokenAddress,
        uint tokenId,
        PayType _payType,
        uint256 amount
    ) private view {
        require(
            checkApproval(tokenAddress, tokenId),
            "Not approved from owner."
        );

        IERC721 tokenContract = IERC721(tokenAddress);
        require(
            tokenContract.ownerOf(tokenId) != msg.sender,
            "Token owner can not buy your NFTs."
        );

        Item memory item = items[tokenAddress][tokenId];
        require(
            item.payType == _payType,
            "Coin type is not correct for this purchase."
        );
        require(amount >= item.price, "Error, the amount is lower than price");
    }

    /**
     * @dev Execute Trading once condition meets.
     *
     * Requirement:
     *
     * - `amount` is token amount, should be greater than equal seller price
     */
    function _trade(
        address tokenAddress,
        uint tokenId,
        uint amount
    ) internal {
        IERC721 tokenContract = IERC721(tokenAddress);

        address payable _buyer = payable(msg.sender);
        address _seller = tokenContract.ownerOf(tokenId);

        Item storage item = items[tokenAddress][tokenId];
        uint price = item.price;
        uint remainAmount = amount.sub(price);

        // Transfer coin to seller from buyer
        if (item.payType == PayType.BNB) {
            // From marketplace contract to seller
            payable(_seller).transfer(price);

            // If buyer sent more than price, we send them back their rest of funds
            if (remainAmount > 0) {
                _buyer.transfer(remainAmount);
            }
        } else {
            // Transfer NICHO from buyer to seller
            nicho.transferFrom(msg.sender, _seller, price);

            // If buyer sent more than price, it will be refunded back (remain amount)
        }

        // Transfer NFT from seller to buyer
        tokenContract.safeTransferFrom(_seller, msg.sender, tokenId);

        // Update Item
        item.isListed = false;
        item.price = 0;
        item.payType = PayType.NONE;
    }

    // Create offer with BNB
    function createOffer(
        address tokenAddress,
        uint256 tokenId,
        uint256 deadline // count in seconds
    ) external payable {
        _createOffer(
            tokenAddress,
            tokenId,
            deadline, // count in seconds
            msg.value,
            PayType.BNB
        );
    }

    // Create offer with Nicho
    function createOfferWithNicho(
        address tokenAddress,
        uint256 tokenId,
        uint256 deadline, // count in seconds
        uint256 amount
    ) external {
        require(
            nicho.allowance(msg.sender, address(this)) >= amount,
            "ERC20: exceed allowance"
        );
        _createOffer(
            tokenAddress,
            tokenId,
            deadline, // count in seconds
            amount,
            PayType.NICHO
        );
    }

    // Create offer logic
    function _createOffer(
        address tokenAddress,
        uint256 tokenId,
        uint256 deadline,
        uint256 amount,
        PayType _payType
    ) private {
        require(amount > 0, "Invalid amount");
        // 30 seconds
        require(deadline >= 5, "Invalid deadline");
        IERC721 nft = IERC721(tokenAddress);
        require(
            nft.ownerOf(tokenId) != msg.sender,
            "Owner cannot create offer"
        );

        OfferItem storage item = offerItems[tokenAddress][tokenId][msg.sender];
        require(
            item.price == 0 || item.isLive == false,
            "You've already created offer"
        );

        uint expireAt = block.timestamp + deadline;

        item.price = amount;
        item.expireTs = expireAt;
        item.isLive = true;
        item.payType = _payType;

        emit Offers(
            tokenAddress,
            tokenId,
            msg.sender,
            amount,
            expireAt,
            _payType
        );
    }

    /**
     * @dev NFT owner accept the offer created by buyer
     * Requirement:
     * - offerCreator: creator address that have created offer.
     */
    function acceptOffer(
        address tokenAddress,
        uint256 tokenId,
        address offerCreator
    )
        external
        notBlackList(tokenAddress, tokenId)
        onlyTokenOwner(tokenAddress, tokenId)
    {
        OfferItem memory item = offerItems[tokenAddress][tokenId][offerCreator];
        require(item.isLive, "Offer creator withdrawed");
        require(item.expireTs >= block.timestamp, "Offer already expired");
        require(checkApproval(tokenAddress, tokenId), "First, approve NFT");

        IERC721(tokenAddress).safeTransferFrom(
            msg.sender,
            offerCreator,
            tokenId
        );

        uint oldPrice = item.price;
        OfferItem memory itemStorage = offerItems[tokenAddress][tokenId][
            offerCreator
        ];

        itemStorage.isLive = false;
        itemStorage.price = 0;

        if (item.payType == PayType.BNB) {
            payable(msg.sender).transfer(item.price);
        } else if (item.payType == PayType.NICHO) {
            nicho.transferFrom(offerCreator, msg.sender, oldPrice);
        }

        Item storage marketItem = items[tokenAddress][tokenId];

        // Update Item
        marketItem.isListed = false;
        marketItem.price = 0;
        marketItem.payType = PayType.NONE;
        // emit OfferSoldOut(tokenAddress, tokenId, msg.sender, item.creator, item.price);


        emit TradeActivity(
            tokenAddress,
            tokenId,
            offerCreator,
            msg.sender,
            oldPrice,
            item.payType
        );
    }

    /**
     * @dev Offer creator cancel offer
     */
    function cancelOffer(address tokenAddress, uint256 tokenId) external {
        require(
            offerItems[tokenAddress][tokenId][msg.sender].isLive,
            "Already withdrawed"
        );
        OfferItem storage item = offerItems[tokenAddress][tokenId][msg.sender];

        uint oldPrice = item.price;
        item.isLive = false;
        item.price = 0;

        if (item.payType == PayType.BNB) {
            payable(msg.sender).transfer(oldPrice);
        }

        emit OfferCancels(tokenAddress, tokenId, msg.sender);
    }

    //----------- Calls from auction contract ------------
    /**
     * @dev when auction is created, cancel fixed sale
     */
    function cancelListFromAuctionCreation(
        address tokenAddress, uint256 tokenId
    ) external {
        require(msg.sender == address(nichonftAuctionContract), "Invalid nichonft contract");
        Item storage item = items[tokenAddress][tokenId];
        item.isListed = false;
        item.price = 0;
    }

    /**
     * @dev emit whenever token owner created auction
     */
    function emitListedNFTFromAuctionContract(
        address _tokenAddress, 
        uint256 _tokenId, 
        address _creator, 
        uint256 _startPrice, 
        PayType _payType, 
        uint256 _expireTs, 
        uint80  _nextAuctionId
    ) external {
        require(
            msg.sender == address(nichonftAuctionContract), 
            "Invalid nichonft contract"
        );
        
        emit ListedNFT(
            _tokenAddress, 
            _tokenId, 
            _creator,
            _startPrice, 
            _payType, 
            _expireTs, 
            _nextAuctionId
        );
    }

    /**
     * @dev when auction is created, cancel fixed sale
     */
    function emitTradeActivityFromAuctionContract(
        address _tokenAddress, 
        uint256 _tokenId, 
        address _prevOwner, 
        address _newOwner, 
        uint256 _price, 
        PayType _payType
    ) external {
        require(
            msg.sender == address(nichonftAuctionContract), 
            "Invalid nichonft contract"
        );

        emit TradeActivity(
            _tokenAddress,
            _tokenId, 
            _prevOwner, 
            _newOwner, 
            _price, 
            _payType
        );
        
    }

    /**
     * @dev Get offer created based on NFT (address, id)
     */
    function getOfferItemInfo(
        address tokenAddress,
        uint tokenId,
        address sender
    ) external view returns (OfferItem memory item) {
        item = offerItems[tokenAddress][tokenId][sender];
    }

    // get ItemInfo listed on marketplace
    function getItemInfo(address tokenAddress, uint tokenId)
        external
        view
        returns (Item memory item)
    {
        item = items[tokenAddress][tokenId];
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

    // For unusual/emergency case,
    function withdrawETH(uint _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Wrong amount");

        payable(msg.sender).transfer(_amount);
    }
}