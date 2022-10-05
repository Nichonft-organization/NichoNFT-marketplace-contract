const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

// Nicho Token
const initialSupply = "5000";
const initialSupplyWei = ethers.utils.parseEther(initialSupply);

// NichoNFT Token
const uri = "https://nichonft.com";
const price = "0.1";
const priceWei = ethers.utils.parseEther(price);

describe("NichoNFT contract", function () {
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
        
        // Set marketplace contract to NichoNFT contract
        await NichoNFTContract.setMarketplaceContract(NichoNFTMarketplaceContract.address);

        // Fixtures can return anything you consider useful for your tests
        return { NFTBlackListContract, NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1, addr2 };
    }

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {
        // `it` is another Mocha function. This is the one you use to define each
        // of your tests. It receives the test name, and a callback function.
        //
        // If the callback function is async, Mocha will `await` it.
        it("Should set the right owner", async function () {
            // We use loadFixture to setup our environment, and then assert that
            // things went well
            const { NFTBlackListContract, NichoNFTMarketplaceContract, NichoNFTContract, owner } = await loadFixture(deployFixture);

            // `expect` receives a value and wraps it in an assertion object. These
            // objects have a lot of utility methods to assert values.

            // This test expects the owner variable stored in the contract to be
            // equal to our Signer's owner.
            expect(await NFTBlackListContract.owner()).to.equal(owner.address);
            expect(await NichoNFTMarketplaceContract.owner()).to.equal(owner.address);
            expect(await NichoNFTContract.owner()).to.equal(owner.address);
        });

        it("Should assign correct addresses on contract configurations", async function () {
            const { NFTBlackListContract, NichoNFTMarketplaceContract, NichoNFTContract, owner } = await loadFixture(deployFixture);

            expect(await NichoNFTMarketplaceContract.blacklistContract()).to.equal(NFTBlackListContract.address);
            // expect(await NichoNFTMarketplaceContract.nichonft()).to.equal(NichoNFTContract.address);

            expect(await NichoNFTContract.nichonftMarketplaceContract()).to.equal(NichoNFTMarketplaceContract.address);
        });
    });

    describe("Transactions: mint ", function () {
        it("Should mint NFT and list on marketplace right away", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(
                deployFixture
            );

            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);
            // Should assign NFT transfer ownership on nftmarketplace
            expect(await NichoNFTContract.isApprovedForAll(owner.address, NichoNFTMarketplaceContract.address)).to.equal(true);
            expect(await NichoNFTContract.tokenURI(0)).to.equal(uri);
            // Check the marketplace data
            expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, 0)).isListed).to.equal(true)
            expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, 0)).price).to.equal(priceWei)
            // Check the balance
            expect(await NichoNFTContract.balanceOf(owner.address)).to.equal(1)      
            
            await expect(
                NichoNFTContract.mint(uri, owner.address, priceWei, "")
            ).to.be.revertedWith("Invalid CID")  
            await expect(
                NichoNFTContract.connect(addr1).mint(uri, owner.address, priceWei, uri)
            ).to.be.revertedWith("Invalid collection creator")       
            // should work
            NichoNFTContract.mint(uri, owner.address, priceWei, uri)
        });


        it("Should mint batchIDMint and list on marketplace right away", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1, addr2 } = await loadFixture(
                deployFixture
            );
            
            const batchAmount = 5;
            const baseURI = uri[uri.length-1] == '/'? uri: uri+"/";
            await NichoNFTContract.batchIDMint(baseURI, owner.address, priceWei, batchAmount, uri);
            for(let i=0; i < batchAmount; i++) {
                // Should assign NFT transfer ownership on nftmarketplace
                expect(await NichoNFTContract.isApprovedForAll(owner.address, NichoNFTMarketplaceContract.address)).to.equal(true);
                expect(await NichoNFTContract.tokenURI(i)).to.equal(`${baseURI}${i}`);
                // Check the marketplace data
                expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, i)).isListed).to.equal(true)
                expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, i)).price).to.equal(priceWei)                
            }         
            // Check the balance
            expect(await NichoNFTContract.balanceOf(owner.address)).to.equal(batchAmount)         
        });

        it("Should mint batchSNMint and list on marketplace right away", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner } = await loadFixture(
                deployFixture
            );
            
            const batchAmount = 5;
            await NichoNFTContract.batchSNMint(uri, owner.address, priceWei, batchAmount, uri);
            for(let i=0; i < batchAmount; i++) {
                // Should assign NFT transfer ownership on nftmarketplace
                expect(await NichoNFTContract.isApprovedForAll(owner.address, NichoNFTMarketplaceContract.address)).to.equal(true);
                expect(await NichoNFTContract.tokenURI(i)).to.equal(uri);
                // Check the marketplace data
                expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, i)).isListed).to.equal(true)
                expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, i)).price).to.equal(priceWei)
            }         
            // Check the balance
            expect(await NichoNFTContract.balanceOf(owner.address)).to.equal(batchAmount)         
        });


        it("Should mint batchDNMint and list on marketplace right away", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner } = await loadFixture(
                deployFixture
            );
            
            const batchAmount = 5;
            let uriArray = [];
            for(let i=0; i < batchAmount; i++) uriArray.push(uri);
            await NichoNFTContract.batchDNMint(uriArray, owner.address, priceWei, batchAmount, uri);

            for(let i=0; i < batchAmount; i++) {
                // Should assign NFT transfer ownership on nftmarketplace
                expect(await NichoNFTContract.isApprovedForAll(owner.address, NichoNFTMarketplaceContract.address)).to.equal(true);
                expect(await NichoNFTContract.tokenURI(i)).to.equal(uri);
                // Check the marketplace data
                expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, i)).isListed).to.equal(true)
                expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, i)).price).to.equal(priceWei)
            }      
            // Check the balance
            expect(await NichoNFTContract.balanceOf(owner.address)).to.equal(batchAmount)            
        });
    });
});