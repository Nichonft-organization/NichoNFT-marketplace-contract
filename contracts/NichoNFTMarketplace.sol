/**
 * Submitted for verification at BscScan.com on 2022-09-28
 */

// File: contracts/Marketplace.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

// Openzeppelin libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Own interfaces
// import "./interfaces/INichoNFT.sol";
import "./interfaces/INFTBlackList.sol";
import "./interfaces/INichoNFTMarketplace.sol";

// NichoNFT marketplace
contract NichoNFTMarketplace is Ownable, INichoNFTMarketplace, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    //-- Interfaces --//
    // Blacklist
    INFTBlackList public blacklistContract;
    // NichoNFT
    // INichoNFT public nichonftContract;
    // NICHO Token
    IERC20 public nicho;

    address public nichonft;

    // Listed item on marketplace
    struct Item {
        bool isListed;
        uint256 price;
        PayType payType;        
    }

    // OfferItem
    struct OfferItem {
        uint256 price;
        uint256 expireTs;   
        bool isCancel;
        PayType payType;    
    }
    
    // Marketplace Listed Item
    // token address => tokenId => item
    mapping (address => mapping(uint256 => Item)) public items;

    // Offer Item
    // token address => token id => creator => offer item
    mapping(address => mapping(uint256 => mapping(address => OfferItem))) public offerItems;

    // NichoNFT and other created owned-collections need to list it while minting.
    // nft contract address => tokenId => item
    mapping (address => bool) public directListable;

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
     * @dev Emitted when `token owner` update price of NFT to be listed
     */
    event PriceUpdate(
        address token_address, 
        uint token_id, 
        address indexed owner, 
        uint old_price, 
        uint new_price,
        PayType pay_type
    );

    /**
     * @dev Emitted when `token owner` list NFT on marketplace
     */
    event ListNFT(
        address token_address,
        uint token_id,
        address indexed owner, 
        uint price,
        PayType pay_type
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
    
    // Initialize configurations
    constructor(
        INFTBlackList _blacklist, 
        // INichoNFT _nichonft,
        IERC20 _nicho,
        address _nichonft
    ) {
        blacklistContract = _blacklist;
        // nichonftContract = _nichonft;
        nicho = _nicho;
        nichonft = _nichonft;

        directListable[_nichonft] = true;
    }

    receive() external payable {}

    // Middleware to check if NFT is in blacklist
    modifier notBlackList(address tokenAddress, uint256 tokenId) {
        require(
            blacklistContract.checkBlackList(tokenAddress, tokenId) == false, 
            "This NFT is in blackList"
        );
        _;
    }

    // Middleware to check if msg.sender is token owner
    modifier onlyTokenOwner(address tokenAddress, uint256 tokenId) {
        address tokenOwner = IERC721(tokenAddress).ownerOf(tokenId);

        require(
            tokenOwner == msg.sender,
            "Token Owner: you are not a token owner"
        );
        _;
    }

    // Middleware to check if NFT is already listed on not.
    modifier onlyListed(address tokenAddress, uint256 tokenId) {
        Item memory item = items[tokenAddress][tokenId];

        require(
            item.isListed == true,
            "Token: not listed on marketplace"
        );
        _;
    }

    // Middleware to check if NFT is already listed on not.
    modifier onlyListableContract {        
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
        require(tokenAddress.length == tokenId.length, "Array size does not match");
        require(_payType != PayType.NONE, "Invalid pay type");

        for (uint idx=0; idx < tokenAddress.length; idx++) {
            address _tokenAddress = tokenAddress[idx];
            uint _tokenId = tokenId[idx];

            // List
            listItemToMarket(
                _tokenAddress,
                _tokenId,
                askingPrice,
                _payType
            );
        }
    }

    // List an NFT on marketplace as same price with fixed price sale
    function listItemToMarket(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 askingPrice,
        PayType _payType
    ) public 
      notBlackList(tokenAddress, tokenId)  
      onlyTokenOwner(tokenAddress, tokenId) 
    {
        // Listing
        require(_payType != PayType.NONE, "Invalid pay type");

        // Token owner need to approve NFT on Token Contract first so that Listing works.
        require(
            checkApproval(tokenAddress, tokenId),
            "First, Approve NFT"
        );

        Item storage item = items[tokenAddress][tokenId];
        item.price = askingPrice;
        item.payType = _payType;
        item.isListed = true;

        emit ListNFT(tokenAddress, tokenId, msg.sender, askingPrice, _payType);
    }

    // List an NFT/NFTs on marketplace as same price with fixed price sale
    function listItemToMarketFromMint(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 askingPrice,
        PayType _payType
    ) external onlyListableContract {
        Item storage item = items[tokenAddress][tokenId];
        item.price = askingPrice;
        item.payType = _payType;
        item.isListed = true;

        emit ListNFT(tokenAddress, tokenId, msg.sender, askingPrice, _payType);
    }
    
    // Update owner's NFT price
    function updateListing(
        address tokenAddress, 
        uint tokenId, 
        uint price, 
        PayType payType
    )   external
        notBlackList(tokenAddress, tokenId) 
        onlyTokenOwner(tokenAddress, tokenId)
        onlyListed(tokenAddress, tokenId)
        returns (bool) 
    {
        Item storage item = items[tokenAddress][tokenId];
        // scope for _token{Id, Address}, price, avoids stack too deep errors
        uint _tokenId = tokenId;
        address _tokenAddress = tokenAddress;
        uint _price = price;
        PayType _payType = payType;

        // If price is zero, it means unlist
        if (_price == 0) {
            item.isListed = false;
            item.payType = PayType.NONE;
            item.price = 0;

            emit ListCancel(_tokenAddress, _tokenId, msg.sender, false);
        } else {
            require(_payType != PayType.NONE, "Invalid pay type");

            // Token owner need to approve NFT on Token Contract first so that Listing works.
            require(
                checkApproval(_tokenAddress, _tokenId), 
                "First, Approve NFT"
            );

            // Get old info for sale
            uint oldPrice = item.price;
            PayType oldPayType = item.payType;
            // Validation
            require(oldPrice != _price || oldPayType != _payType, "This price already set");

            // Update price and pay type
            item.payType = _payType;
            item.price = _price;

            emit PriceUpdate(_tokenAddress, _tokenId, msg.sender, oldPrice, _price, _payType);
        }
        return true;
    }

    function checkApproval(address _tokenAddress, uint _tokenId) private view returns(bool) {
        IERC721 tokenContract = IERC721(_tokenAddress);
        return tokenContract.getApproved(_tokenId) == address(this) || tokenContract.isApprovedForAll(tokenContract.ownerOf(_tokenId), address(this));
    }

    /**
     * @dev Purchase the listed NFT with BNB.
     */
    function buy(
        address tokenAddress, 
        uint tokenId
    ) external
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
    ) external
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
        require(tokenContract.ownerOf(tokenId) != msg.sender, "Token owner can not buy your NFTs.");

        Item memory item = items[tokenAddress][tokenId];
        require(item.payType == _payType, "Coin type is not correct for this purchase.");
        require(amount >= item.price, "Error, the amount is lower than price");        
    }

    /**
     * @dev Execute Trading once condition meets.
     * 
     * Requirement:
     * 
     * - `amount` is token amount, should be greater than equal seller price
     */
    function _trade(address tokenAddress, uint tokenId, uint amount) internal {
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
            if (remainAmount >0) {
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
        require(deadline >= 30, "Invalid deadline");
        
        OfferItem storage item = offerItems[tokenAddress][tokenId][msg.sender];
        require(item.price == 0 || item.isCancel, "You've already created offer");

        uint expireAt = block.timestamp + deadline;

        item.price = amount;
        item.expireTs = expireAt;
        item.isCancel = false;
        item.payType = _payType;

        emit Offers(tokenAddress, tokenId, msg.sender, amount, expireAt, _payType);

    }

    function acceptOffer(
        address tokenAddress, 
        uint256 tokenId, 
        address offerCreator
    ) external 
      notBlackList(tokenAddress, tokenId)
      onlyTokenOwner(tokenAddress, tokenId)
    {
        OfferItem memory item = offerItems[tokenAddress][tokenId][offerCreator];
        require(item.isCancel == false, "Offer creator withdrawed");
        require(item.expireTs >= block.timestamp, "Offer already expired");

        require(
            checkApproval(tokenAddress, tokenId),
            "First, approve NFT"
        );

        IERC721(tokenAddress).safeTransferFrom(msg.sender, offerCreator, tokenId);

        OfferItem memory itemStorage = offerItems[tokenAddress][tokenId][offerCreator];

        uint oldPrice = item.price;
        itemStorage.isCancel = true;
        itemStorage.price = 0;
        
        if (item.payType == PayType.BNB) {
            payable(msg.sender).transfer(item.price);
        } else if (item.payType == PayType.NICHO) {
            nicho.transfer(msg.sender, oldPrice);
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

    // Cancel offer
    function cancelOffer(
        address tokenAddress, 
        uint256 tokenId
    ) external {
        require(offerItems[tokenAddress][tokenId][msg.sender].isCancel == false, "Already cancel");
        OfferItem storage item = offerItems[tokenAddress][tokenId][msg.sender];

        uint oldPrice = item.price;
        item.isCancel = true;
        item.price = 0;

        if (item.payType == PayType.BNB) {
            payable(msg.sender).transfer(oldPrice);
        } else if (item.payType == PayType.NICHO) {
            nicho.transfer(msg.sender, oldPrice);
        }

        emit OfferCancels(tokenAddress, tokenId, msg.sender);
    }


    // get OfferItemInfo
    function getOfferItemInfo(address tokenAddress, uint tokenId, address sender) external view returns(OfferItem memory item) {
        item = offerItems[tokenAddress][tokenId][sender];
    }

    // get ItemInfo
    function getItemInfo(address tokenAddress, uint tokenId) external view returns(Item memory item) {
        item = items[tokenAddress][tokenId];
    }

    // Withdraw ERC20 tokens
    // For unusual case, if customers sent their any ERC20 tokens into marketplace, we need to send it back to them
    function withdrawTokens(address _token, uint256 _amount) external onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Wrong amount");

        IERC20(_token).transfer(msg.sender, _amount);
    }

    // For unusual/emergency case,
    function withdrawBNB(uint _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Wrong amount");

        payable(msg.sender).transfer(_amount);
    }
}