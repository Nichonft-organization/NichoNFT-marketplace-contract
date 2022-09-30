/**
 * Submitted for verification at BscScan.com on 2022-09-29
 */

// File: contracts/NichoNFTAuction.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarketplaceHelper.sol";
import "./interfaces/INichoNFTMarketplace.sol";

contract NichoNFTAuction is Ownable, MarketplaceHelper{
    INichoNFTMarketplace nichonftmarketplaceContract;
    /**
     * @dev Emitted when `buyer` place bid on auction on marketplace
     */
    event AuctionBids(
        address token_address,
        uint token_id,
        address indexed creator,
        uint price,
        PayType pay_type,
        uint80 auction_id
    );

    /**
     * @dev Cancel the placed bid
     */
    event BidCancels(
        address token_address,
        uint token_id, 
        address indexed creator,
        uint80 auction_id
    );
    
    // Auction Item
    // token address => token id => auction item
    mapping(address => mapping(uint256 => AuctionItem)) private auctionItems;

    // Bid Item
    // token address => token id => bidder => bid_info
    mapping(address => mapping(uint256 => mapping(address => BidItem))) private bidItems;

    // Initialize configurations
    constructor(
        address _blacklist,
        address _nicho,
        INichoNFTMarketplace _nichonftmarketplaceContract
    ) MarketplaceHelper(_blacklist, _nicho) {
        nichonftmarketplaceContract = _nichonftmarketplaceContract;
    }

    /**
     * Create auction
     */
    function createAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 startPrice,
        uint256 duration,
        PayType payType
    ) external onlyTokenOwner(tokenAddress, tokenId) notBlackList(tokenAddress, tokenId) {

        address _tokenAddress = tokenAddress;
        uint256 _tokenId = tokenId;
        uint256 _startPrice = startPrice;
        PayType _payType = payType;

        require(duration >= 30, "Auction: too short period");
        require(checkApproval(_tokenAddress, _tokenId), "First, Approve NFT");

        AuctionItem storage auctionItem = auctionItems[_tokenAddress][_tokenId];
        require(
            msg.sender != auctionItem.creator || 
            auctionItem.isLive == false ||
            auctionItem.expireTs <= block.timestamp,
            "Auction: exist"
        );

        uint256 _expireTs = block.timestamp + duration;
        uint80 currentAuctionId = auctionItem.id;
        uint80 nextAuctionId = currentAuctionId + 1;

        auctionItem.id = nextAuctionId;
        auctionItem.highPrice = _startPrice;
        auctionItem.expireTs = _expireTs;
        auctionItem.isLive = true;
        auctionItem.payType = _payType;
        auctionItem.creator = msg.sender;

        // unlist from fixed sale
        nichonftmarketplaceContract.cancelListFromAuctionCreation(
            _tokenAddress, 
            _tokenId
        );
        // emit whenever token owner created auction
         
        nichonftmarketplaceContract.emitListedNFTFromAuctionContract(
            _tokenAddress, 
            _tokenId, 
            msg.sender, 
            _startPrice, 
            _payType, 
            _expireTs, 
            nextAuctionId
        );
    }

    /**
     * @dev Place bid on auctions with bnb
     */
    function placeBid(
        address tokenAddress,
        uint256 tokenId
    ) external payable {
        _placeBid(
            tokenAddress,
            tokenId,
            msg.value,
            PayType.BNB
        );
    }

    /**
     * @dev Place bid on auctions with bnb
     */
    function placeBidWithNicho(
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        require(
            nicho.allowance(msg.sender, address(this)) >= price, 
            "PlaceBidWithNicho: increase allowance"
        );

        _placeBid(
            tokenAddress,
            tokenId,
            price,
            PayType.NICHO
        );
    }

    // Place bid logic
    function _placeBid(
        address tokenAddress,
        uint256 tokenId,
        uint256 price,
        PayType _payType
    ) private notBlackList(tokenAddress, tokenId) {
        address _tokenAddress = tokenAddress;
        uint256 _tokenId = tokenId;
        uint256 _price = price;

        AuctionItem memory auctionItem = auctionItems[_tokenAddress][_tokenId];
        BidItem memory bidItem = bidItems[_tokenAddress][_tokenId][msg.sender];

        require(auctionItem.payType == _payType, "PlaceBid: invalid pay type");
        require(bidItem.price == 0, "PlaceBid: cancel previous one");
        require(auctionItem.isLive, "PlaceBid: auction does not exist");
        require(auctionItem.expireTs >= block.timestamp, "PlaceBid: auction ended");
        require(auctionItem.highPrice < price, "PlaceBid: should be higher price");

        AuctionItem storage _auctionItem = auctionItems[_tokenAddress][_tokenId];
        _auctionItem.highPrice = _price;

        BidItem storage _bidItem = bidItems[_tokenAddress][_tokenId][msg.sender];
        _bidItem.auctionId = auctionItem.id;
        _bidItem.payType = _payType;
        _bidItem.price = _price;

        emit AuctionBids(_tokenAddress, _tokenId, msg.sender, _price, _payType, auctionItem.id);
    }

    /**
     * @dev Cancel the placed bid
     */
    function cancelBid(
        address tokenAddress,
        uint256 tokenId
    ) external {
        address _tokenAddress = tokenAddress;
        uint256 _tokenId = tokenId;
        uint256 _price = bidItems[_tokenAddress][_tokenId][msg.sender].price;
        require(_price > 0, "PlaceBid: not placed yet");

        BidItem storage _bidItem = bidItems[_tokenAddress][_tokenId][msg.sender];
        _bidItem.price = 0;

        if (_bidItem.payType == PayType.BNB) {
            payable(msg.sender).transfer(_price);
        }

        emit BidCancels(_tokenAddress, _tokenId, msg.sender, _bidItem.auctionId);
    }


    /**
     * @dev Accept the placed bid
     */
    function AcceptBid(
        address tokenAddress,
        uint256 tokenId,
        address bidder
    ) external 
        onlyTokenOwner(tokenAddress, tokenId) 
        notBlackList(tokenAddress, tokenId) 
    {
        address _tokenAddress = tokenAddress;
        uint256 _tokenId = tokenId;
        address _bidder = bidder;

        BidItem memory bidItem = bidItems[_tokenAddress][_tokenId][_bidder];
        require(bidItem.price > 0, "AcceptBid: not placed yet");

        AuctionItem memory auctionItem = auctionItems[_tokenAddress][_tokenId];
        require(auctionItem.isLive, "AcceptBid: auction does not exist");
        require(auctionItem.id == bidItem.auctionId, "AcceptBid: too old bid");
        require(auctionItem.expireTs >= block.timestamp, "PlaceBid: auction ended");


        AuctionItem storage _auctionItem = auctionItems[_tokenAddress][_tokenId];
        _auctionItem.isLive = false;
        
        BidItem storage _bidItem = bidItems[_tokenAddress][_tokenId][_bidder];
        uint _price = _bidItem.price;
        _bidItem.price = 0;

        IERC721(_tokenAddress).transferFrom(msg.sender, _bidder, _tokenId);
        if (_bidItem.payType == PayType.BNB) {
            payable(msg.sender).transfer(_price);
        } else {
            nicho.transferFrom(bidder, msg.sender, _price);
        }
        // when accept auction bid, need to emit TradeActivity
        nichonftmarketplaceContract.emitTradeActivityFromAuctionContract(
            _tokenAddress, _tokenId, msg.sender, _bidder, _price, bidItem.payType
        );
    }

    // get auction ItemInfo
    function getAuctionItemInfo(address tokenAddress, uint tokenId)
        external
        view
        returns (AuctionItem memory item)
    {
        item = auctionItems[tokenAddress][tokenId];
    }


    function getAuctionStatus(address tokenAddress, uint tokenId)
        external
        view
        returns (bool)
    {
        return auctionItems[tokenAddress][tokenId].isLive;
    }

    // get auction ItemInfo
    function getBidItemInfo(address tokenAddress, uint tokenId, address bidder)
        external
        view
        returns (BidItem memory item)
    {
        item = bidItems[tokenAddress][tokenId][bidder];
    }

    function cancelAuctionFromFixedSaleCreation(
        address tokenAddress, 
        uint tokenId
    ) external {
        require(msg.sender == address(nichonftmarketplaceContract), "Invalid nichonft marketplace contract");
        AuctionItem storage item = auctionItems[tokenAddress][tokenId];
        item.isLive = false;
    }

    /**
     * @dev pause market auction
     */
    function pause(bool _pause) external onlyOwner {
        isPaused = _pause;
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
