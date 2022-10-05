const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

// Nicho Token
const initialSupply = "5000";
const initialSupplyWei = ethers.utils.parseEther(initialSupply);

// NichoNFT Token
const uri = "https://nichonft.com";
// Deploy Fee
const price = "0.05";
const priceWei = ethers.utils.parseEther(price);

describe("Collection Factory Contract", function () {
    // We define a fixture to reuse the same setup in every test. We use
    // loadFixture to run this setup once, snapshot that state, and reset Hardhat
    // Network to that snapshot in every test.
    async function deployFixture() {
        
        // Get the ContractFactory and Signers here.
        const [owner, addr1, addr2] = await ethers.getSigners();

        // Deploy NFTBlackList contract
        const NFTBlackList = await ethers.getContractFactory("NFTBlackList");
        const NFTBlackListContract = await NFTBlackList.deploy();
        await NFTBlackListContract.deployed();

        // Deploy NichoNFT contract
        const NichoNFT = await ethers.getContractFactory("NichoNFT");
        const NichoNFTContract = await NichoNFT.deploy();
        await NichoNFTContract.deployed();

        // Deploy NichoNFT Marketplace contract
        const NichoNFTMarketplace = await ethers.getContractFactory("NichoNFTMarketplace");
        const NichoNFTMarketplaceContract = await NichoNFTMarketplace.deploy(
            NFTBlackListContract.address,
            NichoNFTContract.address
        );
        await NichoNFTMarketplaceContract.deployed();

        // Deploy NichoNFT auction contract
        const NichoNFTAuction = await ethers.getContractFactory("NichoNFTAuction");
        const NichoNFTAuctionContract = await NichoNFTAuction.deploy(
            NFTBlackListContract.address,
            NichoNFTMarketplaceContract.address
        );
        await NichoNFTAuctionContract.deployed();

        // Deploy Collection contract
        const CollectionFactory = await ethers.getContractFactory("CollectionFactory");
        const CollectionFactoryContract = await CollectionFactory.deploy(NichoNFTMarketplaceContract.address);
        await CollectionFactoryContract.deployed();        

        await NichoNFTContract.setMarketplaceContract(NichoNFTMarketplaceContract.address);
        await NichoNFTMarketplaceContract.enableNichoNFTAuction(NichoNFTAuctionContract.address);
        await NichoNFTMarketplaceContract.setFactoryAddress(CollectionFactoryContract.address);

        // Deploy new NFT contract and get that contract object
        await CollectionFactoryContract.deploy("Test NFT", "TestNFT", { value: priceWei });            
        const deployedCollectionAddress = await CollectionFactoryContract.getCreatorContractAddress(
            owner.address,
            0
        );
        const DeployedCollectionContract = await ethers.getContractAt("CreatorNFT", deployedCollectionAddress);

        // Fixtures can return anything you consider useful for your tests
        return { 
            NFTBlackListContract, NichoNFTMarketplaceContract, NichoNFTContract, 
            NichoNFTAuctionContract, CollectionFactoryContract, DeployedCollectionContract,
            owner, addr1, addr2 
        };
    }

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { NichoNFTMarketplaceContract, CollectionFactoryContract, owner } = await loadFixture(deployFixture);

            expect(await NichoNFTMarketplaceContract.factory()).to.equal(CollectionFactoryContract.address);
            expect(await CollectionFactoryContract.nichonftmarketplaceContract()).to.equal(NichoNFTMarketplaceContract.address);
            expect(await CollectionFactoryContract.owner()).to.equal(owner.address);
        });
    });

    describe("Transactions", function () {
        it("Should fail if sender doesn't pay enough deploy fee", async function () {
            const { CollectionFactoryContract, addr1 } = await loadFixture(
                deployFixture
            );

            await expect(
                CollectionFactoryContract.connect(addr1).deploy("Test NFT", "TestNFT", { value: priceWei.div(2) })
            ).to.be.revertedWithCustomError(CollectionFactoryContract, `InvalidDeployFees`);
        });

        it("Deploy new contract should be run", async function () {
            const { NichoNFTMarketplaceContract, DeployedCollectionContract, owner } = await loadFixture(
                deployFixture
            );

            // Check name of new deployed NFT contract
            expect(
                await DeployedCollectionContract.name()
            ).to.equal("Test NFT")

            // Check symbol of new deployed NFT contract
            expect(
                await DeployedCollectionContract.symbol()
            ).to.equal("TestNFT")

            // Check nichonftMarketplaceContract of new deployed contract
            expect(
                await DeployedCollectionContract.nichonftMarketplaceContract()
            ).to.equal(NichoNFTMarketplaceContract.address)

            // Check owner of new deployed contract
            expect(
                await DeployedCollectionContract.getCreator()
            ).to.equal(owner.address)
        });


        it("Should mint NFT and list on marketplace right away", async function () {
            const { NichoNFTMarketplaceContract, DeployedCollectionContract, owner } = await loadFixture(
                deployFixture
            );

            await DeployedCollectionContract.mint(uri, priceWei);
            // Should assign NFT transfer ownership on nftmarketplace
            expect(await DeployedCollectionContract.isApprovedForAll(owner.address, NichoNFTMarketplaceContract.address)).to.equal(true);
            expect(await DeployedCollectionContract.tokenURI(0)).to.equal(uri);
            // Check the marketplace data
            expect((await NichoNFTMarketplaceContract.getItemInfo(DeployedCollectionContract.address, 0)).isListed).to.equal(true)
            expect((await NichoNFTMarketplaceContract.getItemInfo(DeployedCollectionContract.address, 0)).price).to.equal(priceWei)
            // Check the balance
            expect(await DeployedCollectionContract.balanceOf(owner.address)).to.equal(1)            
        });

        it("Should mint batchIDMint and list on marketplace right away", async function () {
            const { NichoNFTMarketplaceContract, DeployedCollectionContract, owner, addr1, addr2 } = await loadFixture(
                deployFixture
            );
            
            const batchAmount = 5;
            const baseURI = uri[uri.length-1] == '/'? uri: uri+"/";
            await DeployedCollectionContract.batchIDMint(baseURI, priceWei, batchAmount);
            for(let i=0; i < batchAmount; i++) {
                // Should assign NFT transfer ownership on nftmarketplace
                expect(await DeployedCollectionContract.isApprovedForAll(owner.address, NichoNFTMarketplaceContract.address)).to.equal(true);
                expect(await DeployedCollectionContract.tokenURI(i)).to.equal(`${baseURI}${i}`);
                // Check the marketplace data
                expect((await NichoNFTMarketplaceContract.getItemInfo(DeployedCollectionContract.address, i)).isListed).to.equal(true)
                expect((await NichoNFTMarketplaceContract.getItemInfo(DeployedCollectionContract.address, i)).price).to.equal(priceWei)
            }         
            // Check the balance
            expect(await DeployedCollectionContract.balanceOf(owner.address)).to.equal(batchAmount)         
        });

        it("Should mint batchSNMint and list on marketplace right away", async function () {
            const { NichoNFTMarketplaceContract, DeployedCollectionContract, owner } = await loadFixture(
                deployFixture
            );
            
            const batchAmount = 5;
            await DeployedCollectionContract.batchSNMint(uri, priceWei, batchAmount);
            for(let i=0; i < batchAmount; i++) {
                // Should assign NFT transfer ownership on nftmarketplace
                expect(await DeployedCollectionContract.isApprovedForAll(owner.address, NichoNFTMarketplaceContract.address)).to.equal(true);
                expect(await DeployedCollectionContract.tokenURI(i)).to.equal(uri);
                // Check the marketplace data
                expect((await NichoNFTMarketplaceContract.getItemInfo(DeployedCollectionContract.address, i)).isListed).to.equal(true)
                expect((await NichoNFTMarketplaceContract.getItemInfo(DeployedCollectionContract.address, i)).price).to.equal(priceWei)                 
            }         
            // Check the balance
            expect(await DeployedCollectionContract.balanceOf(owner.address)).to.equal(batchAmount)         
        });


        it("Should mint batchDNMint and list on marketplace right away", async function () {
            const { NichoNFTMarketplaceContract, DeployedCollectionContract, owner } = await loadFixture(
                deployFixture
            );
            
            const batchAmount = 5;
            let uriArray = [];
            for(let i=0; i < batchAmount; i++) uriArray.push(uri);
            await DeployedCollectionContract.batchDNMint(uriArray, priceWei, batchAmount);

            for(let i=0; i < batchAmount; i++) {
                // Should assign NFT transfer ownership on nftmarketplace
                expect(await DeployedCollectionContract.isApprovedForAll(owner.address, NichoNFTMarketplaceContract.address)).to.equal(true);
                expect(await DeployedCollectionContract.tokenURI(i)).to.equal(uri);
                // Check the marketplace data
                expect((await NichoNFTMarketplaceContract.getItemInfo(DeployedCollectionContract.address, i)).isListed).to.equal(true)
                expect((await NichoNFTMarketplaceContract.getItemInfo(DeployedCollectionContract.address, i)).price).to.equal(priceWei)
                 
            }      
            // Check the balance
            expect(await DeployedCollectionContract.balanceOf(owner.address)).to.equal(batchAmount)            
        });
    });
});