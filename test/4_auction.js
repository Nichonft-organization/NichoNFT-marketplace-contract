const { expect } = require("chai");
const { ethers } = require("hardhat");
// const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { sleep } = require("./utils");

// Nicho Token
const initialSupply = "5000";
const initialSupplyWei = ethers.utils.parseEther(initialSupply);

// NichoNFT Token
const uri = "https://nichonft.com";
// Deploy Fee
const feePrice = "0.05";
const feePriceWei = ethers.utils.parseEther(feePrice);
// Deploy Fee
const price = "0.1";
const priceWei = ethers.utils.parseEther(price);

describe("NFT auction Contract", function () {

    let NFTBlackListContract;
    let NichoNFTContract;
    let NichoNFTAuctionContract;
    let NichoNFTMarketplaceContract;
    let DeployedCollectionContract;

    let owner;
    let addr1;
    let addr2;
    let addr3;

    // We define a fixture to reuse the same setup in every test. We use
    // loadFixture to run this setup once, snapshot that state, and reset Hardhat
    // Network to that snapshot in every test.
    async function deployEverythings() {
        
        // Get the ContractFactory and Signers here.
        [owner, addr1, addr2, addr3] = await ethers.getSigners();
        
        // Deploy NFTBlackList contract
        const NFTBlackList = await ethers.getContractFactory("NFTBlackList");
        NFTBlackListContract = await NFTBlackList.deploy();
        await NFTBlackListContract.deployed();

        // Deploy NichoNFT contract
        const NichoNFT = await ethers.getContractFactory("NichoNFT");
        NichoNFTContract = await NichoNFT.deploy();
        await NichoNFTContract.deployed();

        // Deploy NichoNFT Marketplace contract
        const NichoNFTMarketplace = await ethers.getContractFactory("NichoNFTMarketplace");
        NichoNFTMarketplaceContract = await NichoNFTMarketplace.deploy(
            NFTBlackListContract.address,
            NichoNFTContract.address
        );
        await NichoNFTMarketplaceContract.deployed();

        // Deploy NichoNFT auction contract
        const NichoNFTAuction = await ethers.getContractFactory("NichoNFTAuction");
        NichoNFTAuctionContract = await NichoNFTAuction.deploy(
            NFTBlackListContract.address,
            NichoNFTMarketplaceContract.address
        );
        await NichoNFTAuctionContract.deployed();

        // Deploy Collection contract
        const CollectionFactory = await ethers.getContractFactory("CollectionFactory");
        CollectionFactoryContract = await CollectionFactory.deploy(NichoNFTMarketplaceContract.address);
        await CollectionFactoryContract.deployed();        

        await NichoNFTContract.setMarketplaceContract(NichoNFTMarketplaceContract.address);
        await NichoNFTMarketplaceContract.enableNichoNFTAuction(NichoNFTAuctionContract.address);
        await NichoNFTMarketplaceContract.setFactoryAddress(CollectionFactoryContract.address);

        // Deploy new NFT contract and get that contract object
        await CollectionFactoryContract.deploy("Test NFT", "TestNFT", { value: feePriceWei });            
        const deployedCollectionAddress = await CollectionFactoryContract.getCreatorContractAddress(
            owner.address,
            0
        );
        DeployedCollectionContract = await ethers.getContractAt("CreatorNFT", deployedCollectionAddress);

        // Fixtures can return anything you consider useful for your tests
        return { 
            NFTBlackListContract, NichoNFTMarketplaceContract, NichoNFTContract, 
            NichoNFTAuctionContract, CollectionFactoryContract, DeployedCollectionContract,
            owner, addr1, addr2 
        };
    }
    describe("Deploy all contracts", function () {
        it("Should work with all contracts deployment", async function () {
            await deployEverythings();
        });
    });

    describe("Transactions", function () {
        it("Bid should not be created/canceled before creating auction item", async function () {
            await expect(
                NichoNFTAuctionContract.placeBid(
                    NichoNFTContract.address,
                    0                    
                )
            ).to.be.revertedWith("PlaceBid: auction does not exist");

            await expect(
                NichoNFTAuctionContract.cancelBid(
                    NichoNFTContract.address,
                    0                    
                )
            ).to.be.revertedWith("PlaceBid: not placed yet");    

            await NichoNFTContract.mint(uri, owner.address, priceWei, uri); 
            expect(await NichoNFTContract.totalSupply()).to.equal(1);

            await expect(
                NichoNFTAuctionContract.connect(addr1).createAuction(
                    NichoNFTContract.address,
                    0,
                    priceWei.div(2),
                    5
                )
            ).to.be.revertedWith("Token Owner: you are not a token owner");              
        });

        it("Create auction on same NFT should fail", async function () {
            // create auction            
            await NichoNFTContract.approve(NichoNFTAuctionContract.address, 0);
            await NichoNFTAuctionContract.createAuction(
                NichoNFTContract.address,
                0,
                priceWei.div(2),
                5
            )

            await expect(
                NichoNFTAuctionContract.createAuction(
                    NichoNFTContract.address,
                    0,
                    priceWei.div(2),
                    5
                )
            ).to.be.revertedWith("Auction: exist") ;

            // place bid
            await NichoNFTAuctionContract.connect(addr1).placeBid(
                NichoNFTContract.address,
                0, { value: priceWei }
            );
        });

        it("Token owner cannot place bid on his auction and buyer cannot bid after expired", async function () {
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);
            expect(await NichoNFTContract.totalSupply()).to.equal(2);
            // create auction            
            await NichoNFTContract.approve(NichoNFTAuctionContract.address, 1);
            await NichoNFTAuctionContract.createAuction(
                NichoNFTContract.address,
                1,
                priceWei.div(2),
                5
            )
            // place bid
            await expect(
                NichoNFTAuctionContract.placeBid(
                    NichoNFTContract.address,
                    1, { value: priceWei }                    
                )
            ).to.be.revertedWith("Token owner cannot place bid");   
            
            await sleep(6*1000);

            // place bid
            await expect(
                NichoNFTAuctionContract.connect(addr1).placeBid(
                    NichoNFTContract.address,
                    1, { value: priceWei }
                )
            ).to.be.revertedWith("PlaceBid: auction ended");  
        });

        it("Buyer cannot cancel his bid before ends and Buyer cannot bid with another type of token", async function () {
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);
            expect(await NichoNFTContract.totalSupply()).to.equal(3);

            // create auction            
            await NichoNFTContract.approve(NichoNFTAuctionContract.address, 2);
            await NichoNFTAuctionContract.createAuction(
                NichoNFTContract.address,
                2,
                priceWei.div(2),
                10
            )            

            // Bid
            await NichoNFTAuctionContract.connect(addr1).placeBid(
                NichoNFTContract.address,
                2, { value: priceWei }
            )
            // Bid again
            await expect(
                NichoNFTAuctionContract.connect(addr1).placeBid(
                    NichoNFTContract.address,
                    2, { value: priceWei }
                )
            ).to.be.rejectedWith("PlaceBid: cancel previous one");

            // cancel bid
            await expect(
                NichoNFTAuctionContract.connect(addr1).cancelBid(
                    NichoNFTContract.address,
                    2
                )
            ).to.be.revertedWith("Not able to cancel before ends");  
        });

        it("Trade", async function () {
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);
            expect(await NichoNFTContract.totalSupply()).to.equal(4);

            // create auction            
            await NichoNFTContract.approve(NichoNFTAuctionContract.address, 3);
            await NichoNFTAuctionContract.createAuction(
                NichoNFTContract.address,
                3,
                priceWei.div(3),
                5
            )            

            // Bid
            await NichoNFTAuctionContract.connect(addr1).placeBid(
                NichoNFTContract.address,
                3, { value: priceWei.div(2) }
            )
            
            await NichoNFTAuctionContract.connect(addr2).placeBid(
                NichoNFTContract.address,
                3, { value: priceWei }
            )

            // accept bid
            await expect(
                NichoNFTAuctionContract.acceptBid(
                    NichoNFTContract.address,
                    3,
                    addr2.address
                )
            ).to.changeEtherBalances([owner, addr2], [priceWei, priceWei.mul(0)]);
            // check NFT balances
            expect(await NichoNFTContract.balanceOf(owner.address)).to.be.equal(3);
            expect(await NichoNFTContract.balanceOf(addr2.address)).to.be.equal(1);
            // Cannot bid after trade done

            // accept bid
            await expect(
                NichoNFTAuctionContract.connect(addr3).placeBid(
                    NichoNFTContract.address,
                    3,
                    { value: priceWei }
                )
            ).to.be.revertedWith("PlaceBid: auction does not exist");
        });
    });
});