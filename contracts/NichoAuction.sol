/**
 * Submitted for verification at BscScan.com on 2022-04-09
 */

// File: contracts/Auction.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IOERC721.sol";

// NichoNFT interface
interface INichoNFT {
    function commissionFee() external view returns (uint256);
    function denominator() external view returns (uint256);
    function _feeAddress() external view returns (address payable);
    function whitelist(address wallet) external view returns (bool);
    function blackList(address tokenAddress, uint256 tokenId) external view returns (bool);
}

contract NichoAuction is Ownable{
    INichoNFT public NichoNFT;

    struct Buyer {
        address owner;
        uint256 bidPrice;
    }

    // Auction Item
    struct Item {
        address creator; //address of creator
        address tokenAddress; // token address
        uint256 tokenId; // token id
        string uri; //IPFS URL
        uint256 highPrice;
        uint256 deadline;
        uint256 createdTs;
        bool exists;
        Buyer[] buyers;
    }
    // Param for auction creation
    struct ItemParam {
        address tokenAddress; 
        uint256 tokenId; 
        uint256 desiredMinPrice;
        uint256 deadline;
    }

    // OfferItem
    struct OfferItem {
        address creator;
        uint256 price;
        uint256 expireTs;
        uint256 createdAt;
        bool isCancel;
    }

    // Auction ID counter
    uint256 public auctionCounter = 0;
    // Auction ID => Auction Item
    mapping(uint256 => Item) public items;
    // Token Address => TokenId => Auction ID
    mapping(address => mapping(uint256 => uint256)) public tokenIdToAuctionId;

    // Offer List
    // Token address => Token id => creator => offer item
    mapping(address => mapping(uint256 => mapping(address => OfferItem))) public offerItems;

    modifier notBlackList(address tokenAddress, uint256 _tokenId) {
        require(NichoNFT.blackList(tokenAddress, _tokenId) == false, "TokenId is in blackList");
        _;
    }

    modifier tokenOwner(address tokenAddress, uint256 tokenId) {
        IOERC721 token = IOERC721(tokenAddress);

        require(msg.sender == token.ownerOf(tokenId), "You are not a token owner");
        _;
    }
    
    modifier auctionOwner(uint256 auctionId) {
        Item memory item = items[auctionId];
        IOERC721 token = IOERC721(item.tokenAddress);
        require(token.ownerOf(item.tokenId) == msg.sender, "Only AuctionOwner");
        _;
    }

    modifier onlyTokenOwner(address tokenAddress, uint256 tokenId) {
        IOERC721 token = IOERC721(tokenAddress);
        require(token.ownerOf(tokenId) == msg.sender, "Only token owner");
        _;
    }

    modifier auctionNotExist(address tokenAddress, uint256 tokenId) {
        uint256 auctionId = tokenIdToAuctionId[tokenAddress][tokenId];
        Item memory item = items[auctionId];
        require(item.exists != true, "Auction Exists");
        _;
    }

    modifier auctionStarted(uint256 auctionId) {
        Item memory item = items[auctionId];
        require(block.timestamp > item.createdTs, "Auction not started");
        _;
    }

    modifier auctionNotEnded(uint256 auctionId) {
        Item memory item = items[auctionId];
        require(block.timestamp <= item.deadline, "Auction ended");
        _;
    }

    modifier auctionEnded(uint256 auctionId) {
        Item memory item = items[auctionId];
        require(block.timestamp > item.deadline, "Auction not ended");
        _;
    }

    modifier auctionExist(uint256 auctionId) {
        Item memory item = items[auctionId];
        require(item.exists, "Auction does not exist");
        _;
    }

    // Auction event
    event AddItem(uint256 auctionId, address tokenAddress, uint256 tokenId, string uri, uint256 price, address creator, uint256 deadline);
    event ItemCancel(uint256 auctionId);
    event PlacedBid(uint256 auctionId, address bidder, uint256 bidPrice, address tokenAddress, uint256 tokenId, uint256 bidderId);
    event SoldOut(uint256 auctionId, uint256 soldPrice, address seller, address winner);
    event CancelBid(uint256 auctionId, uint256 bidderId, address bidCreator);

    // Offer event
    event OfferCreated(address tokenAddress, uint256 tokenId, address creator, uint256 offerPrice, string uri, uint256 deadline);
    event OfferSoldOut(address tokenAddress, uint256 tokenId, address seller, address buyer, uint256 offerPrice);
    event OfferCancel(address tokenAddress, uint256 tokenId, address creator);
    
    constructor(address _nichoNFT) {
        NichoNFT = INichoNFT(_nichoNFT);
    }

    receive() external payable {}

    function addAuctionItem(ItemParam memory itemParam) 
        tokenOwner(itemParam.tokenAddress, itemParam.tokenId)
        auctionNotExist(itemParam.tokenAddress, itemParam.tokenId)
        external {
            uint256 itemDeadLine = itemParam.deadline;
            uint256 itemPrice = itemParam.desiredMinPrice;

            require(itemDeadLine > block.timestamp, "Invalid deadline");

            IOERC721 tokenObject = IOERC721(itemParam.tokenAddress);
            // require(tokenObject.getApproved(tokenId) == address(this), "Token should be approved");

            string memory uri = tokenObject.tokenURI(itemParam.tokenId);

            auctionCounter++;
            uint256 auctionId = auctionCounter;
            {
                Item storage item = items[auctionId];
                item.creator = msg.sender;
                item.tokenAddress = itemParam.tokenAddress;
                item.tokenId = itemParam.tokenId;
                item.uri = uri;
                item.highPrice = itemPrice;
                item.deadline = itemDeadLine;
                item.createdTs = block.timestamp;
                item.exists = true;
            }
            
            tokenIdToAuctionId[itemParam.tokenAddress][itemParam.tokenId] = auctionCounter;

            emit AddItem(auctionId, itemParam.tokenAddress, itemParam.tokenId, uri, itemPrice, msg.sender, itemDeadLine);
    }

    function cancelAuctionItem(uint256 auctionId)
        auctionOwner(auctionId)
        auctionExist(auctionId)
        external {
            Item storage item = items[auctionId];
            item.exists = false;
            emit ItemCancel(auctionId);
    }

    function placeBid(uint256 auctionId)
        auctionExist(auctionId)
        auctionStarted(auctionId)
        auctionNotEnded(auctionId)
        external payable {
            Item storage item = items[auctionId];
            IOERC721 nftToken = IOERC721(item.tokenAddress);
            require(nftToken.ownerOf(item.tokenId) != msg.sender, "Creator not able to place bid");
            require(msg.value > item.highPrice, "Price need to be higher than highest bid price");

            item.highPrice = msg.value;
            Buyer memory buyer = Buyer(msg.sender, msg.value);

            uint256 bidderId = item.buyers.length;

            item.buyers.push(buyer);

            emit PlacedBid(auctionId, msg.sender, msg.value, item.tokenAddress, item.tokenId, bidderId);
        }

    function acceptBid(uint256 auctionId, uint256 bidderId)
        auctionOwner(auctionId)
        auctionExist(auctionId)
        auctionEnded(auctionId)
        external {
            Item storage item = items[auctionId];
            require(item.buyers.length >= bidderId + 1, "Bidder does not exist");
            item.exists = false;
            Buyer storage buyer = item.buyers[bidderId];
            
            if (IOERC721(item.tokenAddress).getApproved(item.tokenId) == address(this)) {
                IOERC721(item.tokenAddress).safeTransferFrom(msg.sender, buyer.owner, item.tokenId);

                bool isInWhiteList = NichoNFT.whitelist(msg.sender) || NichoNFT.whitelist(buyer.owner);
                // commission cut
                uint _commissionValue = buyer.bidPrice * NichoNFT.commissionFee() / NichoNFT.denominator() / 100 ;
                if (isInWhiteList) _commissionValue = 0;
                uint _sellerValue = buyer.bidPrice - _commissionValue;
                if (_commissionValue > 0) {
                    NichoNFT._feeAddress().transfer(_commissionValue);
                }

                payable(msg.sender).transfer(_sellerValue);
                emit SoldOut(auctionId, buyer.bidPrice, msg.sender, buyer.owner);
                emit CancelBid(auctionId, bidderId, buyer.owner);

                buyer.bidPrice = 0;
            } else {
                revert("Approve NFT");
            }
        }

    
    function cancelBid(uint256 auctionId, uint256 bidderId)
        auctionEnded(auctionId)
        external {

            Buyer storage buyer = items[auctionId].buyers[bidderId];
            require(buyer.owner == msg.sender, "You are not allowed");
            require(buyer.bidPrice > 0, "You already withdrawed");
            uint256 withdrawAmount = buyer.bidPrice;
            buyer.bidPrice = 0;
            
            payable(msg.sender).transfer(withdrawAmount);
            emit CancelBid(auctionId, bidderId, msg.sender);
        }

    
    function getBidsByBidder(uint256 auctionId)
        external view returns(Buyer[] memory){
            Item memory item = items[auctionId];

            Buyer[] memory buyers;
            uint256 index = 0;
            for(uint256 i = 0; i < item.buyers.length; i++) {
                Buyer memory buyer = item.buyers[i];
                if (buyer.owner == msg.sender && buyer.bidPrice > 0) {
                    buyers[index] = buyer;
                    index++;
                }
            }

            return buyers;
        }

    function isNFTListedToAuction(address tokenAddress, uint256 tokenId)
        external view returns(bool) {
            // IOERC721 token = IOERC721(tokenAddress);
            uint256 auctionId = tokenIdToAuctionId[tokenAddress][tokenId];
            Item memory item = items[auctionId];
            return item.exists;
        }

    function createOffer(address tokenAddress, uint256 tokenId, uint256 deadline) 
        external payable {
            require(msg.value > 0, "Invalid amount");
            require(deadline >= block.timestamp, "Invalid deadline");
            
            OfferItem storage item = offerItems[tokenAddress][tokenId][msg.sender];
            require(item.price == 0 || item.isCancel, "You already created offer");

            item.creator = msg.sender;
            item.price = msg.value;
            item.expireTs = deadline;
            item.isCancel = false;
            item.createdAt = block.timestamp;

            IOERC721 tokenObject = IOERC721(tokenAddress);
            string memory uri = tokenObject.tokenURI(tokenId);

            emit OfferCreated(tokenAddress, tokenId, msg.sender, msg.value, uri, deadline);
        }

    function acceptOffer(address tokenAddress, uint256 tokenId, address offerCreator) 
        onlyTokenOwner(tokenAddress, tokenId)
        external {
            OfferItem storage item = offerItems[tokenAddress][tokenId][offerCreator];
            require(item.isCancel == false, "Offer creator withdrawed");
            require(item.expireTs >= block.timestamp, "Offer already expired");
            if (IOERC721(tokenAddress).getApproved(tokenId) == address(this)) {
                IOERC721(tokenAddress).safeTransferFrom(msg.sender, item.creator, tokenId);

                bool isInWhiteList = NichoNFT.whitelist(msg.sender) || NichoNFT.whitelist(IOERC721(tokenAddress).ownerOf(tokenId));
                // commission cut
                uint _commissionValue = item.price * NichoNFT.commissionFee() / NichoNFT.denominator() / 100 ;
                if (isInWhiteList) _commissionValue = 0;
                uint _sellerValue = item.price - _commissionValue;
                if (_commissionValue > 0) {
                    NichoNFT._feeAddress().transfer(_commissionValue);
                }
                payable(msg.sender).transfer(_sellerValue);
                item.isCancel = true;
            } else {
                revert("Approve NFT");
            }

            emit OfferSoldOut(tokenAddress, tokenId, msg.sender, item.creator, item.price);
        }

    function cancelOffer(address tokenAddress, uint256 tokenId)
        external {
            OfferItem storage item = offerItems[tokenAddress][tokenId][msg.sender];
            require(item.isCancel == false, "Already cancel");
            item.isCancel = true;

            payable(msg.sender).transfer(item.price);
            emit OfferCancel(tokenAddress, tokenId, msg.sender);
        }

    function withdrawETH(uint256 amount) external onlyOwner {
        uint256 ethAmount = address(this).balance;
        require(ethAmount >= amount, "Insufficient amount");
        payable(msg.sender).transfer(amount);
    }

    // Withdraw ERC20 tokens
    // For unusual case, if customers sent their any ERC20 tokens into marketplace, we need to send it back to them
    function withdrawTokens(address _token, uint256 _amount) external onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Wrong amount");

        IERC20(_token).transfer(msg.sender, _amount);
    }
    // For unusual case,
    function withdrawBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
