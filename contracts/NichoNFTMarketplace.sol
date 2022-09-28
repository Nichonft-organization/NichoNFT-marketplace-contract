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

    // Listed item on marketplace
    struct Item {
        bool isListed;
        uint256 price;
        PayType payType;        
    }

    // token address => tokenId => item
    mapping (address => mapping(uint256 => Item)) public items;


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

    // Initialize configurations
    constructor(
        INFTBlackList _blacklist, 
        // INichoNFT _nichonft,
        IERC20 _nicho
    ) {
        blacklistContract = _blacklist;
        // nichonftContract = _nichonft;
        nicho = _nicho;
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

    // List an NFT/NFTs on marketplace as same price with fixed price sale
    function listItemToMarket(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 askingPrice,
        PayType _payType
    ) external 
      notBlackList(tokenAddress, tokenId)  
      onlyTokenOwner(tokenAddress, tokenId) 
    {
        require(_payType != PayType.NONE, "Invalid pay type");

        IERC721 tokenContract = IERC721(tokenAddress);
        // Token owner need to approve NFT on Token Contract first so that Listing works.
        require(tokenContract.getApproved(tokenId) == address(this), "First, Approve NFT");

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

            emit ListCancel(_tokenAddress, _tokenId, msg.sender, false);
        } else {
            require(_payType != PayType.NONE, "Invalid pay type");

            IERC721 tokenContract = IERC721(_tokenAddress);
            // Token owner need to approve NFT on Token Contract first so that Listing works.
            require(tokenContract.getApproved(_tokenId) == address(this), "First, Approve NFT");

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
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.getApproved(tokenId) == address(this), "Not approved from owner.");
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

    // Withdraw ERC20 tokens
    // For unusual case, if customers sent their any ERC20 tokens into marketplace, we need to send it back to them
    function withdrawTokens(address _token, uint256 _amount) external onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Wrong amount");

        IERC20(_token).transfer(msg.sender, _amount);
    }

    // For unusual/emergency case,
    function withdrawBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}