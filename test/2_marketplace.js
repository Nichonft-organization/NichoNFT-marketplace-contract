const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { sleep } = require("./utils");
// Nicho Token
const initialSupply = "5000";
const initialSupplyWei = ethers.utils.parseEther(initialSupply);

// NichoNFT Token
const uri = "https://nichonft.com";

const price = "0.1";
const priceWei = ethers.utils.parseEther(price);

describe("NFT Marketplace contract", function () {
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

        // Fixtures can return anything you consider useful for your tests
        return { 
            NFTBlackListContract, NichoNFTMarketplaceContract, NichoNFTContract, 
            NichoNFTAuctionContract, CollectionFactoryContract, 
            owner, addr1, addr2 
        };
    }

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {
        // If the callback function is async, Mocha will `await` it.
        it("Should set the right owner", async function () {
            const { NFTBlackListContract, NichoNFTMarketplaceContract, NichoNFTContract, owner } = await loadFixture(deployFixture);

            // This test expects the owner variable stored in the contract to be
            // equal to our Signer's owner.            
            expect(await NFTBlackListContract.owner()).to.equal(owner.address);
            expect(await NichoNFTMarketplaceContract.owner()).to.equal(owner.address);
            expect(await NichoNFTContract.owner()).to.equal(owner.address);
        });

        it("Should assign correct addresses on contract configurations", async function () {
            const { 
                NFTBlackListContract, NichoNFTMarketplaceContract,
                NichoNFTContract, NichoNFTAuctionContract, CollectionFactoryContract
            } = await loadFixture(deployFixture);

            expect(await NichoNFTMarketplaceContract.blacklistContract()).to.equal(NFTBlackListContract.address);
            expect(await NichoNFTMarketplaceContract.nichonftAuctionContract()).to.equal(NichoNFTAuctionContract.address);
            expect(await NichoNFTMarketplaceContract.factory()).to.equal(CollectionFactoryContract.address);
            expect(await CollectionFactoryContract.nichonftmarketplaceContract()).to.equal(NichoNFTMarketplaceContract.address);

            expect(await NichoNFTContract.nichonftMarketplaceContract()).to.equal(NichoNFTMarketplaceContract.address);
        });
    });

    // You can nest describe calls to create subsections.
    describe("Transactions: Fixed Sale", function () {
        it("BNB: Purchase should not work for not minted NFT", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(
                deployFixture
            );
            // Addr1 purchase NFT that has been minted by owner.
            // We use .connect(signer) to send a transaction from another account
            await expect(
                NichoNFTMarketplaceContract.connect(addr1).buy(
                    NichoNFTContract.address, 0, 
                    { value: priceWei }
                )
            ).to.be.revertedWith("Token: not listed on marketplace");

        });

        it("BNB: Purchase should not work with less payment", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(
                deployFixture
            );
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);
            // Addr1 purchase NFT that has been minted by owner.
            // We use .connect(signer) to send a transaction from another account
            await expect(
                NichoNFTMarketplaceContract.connect(addr1).buy(
                    NichoNFTContract.address, 0, 
                    { value: priceWei.div(2) }
                )
            ).to.be.revertedWith("Error, the amount is lower than price");
        });

        it("BNB: Purchase should work for minted NFT right away even though higher payment by refund extra funds", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(
                deployFixture
            );
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);

            // Addr1 purchase NFT that has been minted by owner.
            // We use .connect(signer) to send a transaction from another account
            await expect(
                NichoNFTMarketplaceContract.connect(addr1).buy(
                    NichoNFTContract.address, 0, 
                    { value: priceWei.mul(2) }
                )
            ).to.changeEtherBalance(owner, priceWei);

            // owner nft balance -1
            expect(
                await NichoNFTContract.balanceOf(owner.address)
            ).to.equal(0)
            // addr nft balance +1
            expect(
                await NichoNFTContract.balanceOf(addr1.address)
            ).to.equal(1)
        });

        it("BNB: Purchase should work for minted NFT right away ", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(
                deployFixture
            );
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);

            // Addr1 purchase NFT that has been minted by owner.
            // We use .connect(signer) to send a transaction from another account
            await expect(
                NichoNFTMarketplaceContract.connect(addr1).buy(
                    NichoNFTContract.address, 0, 
                    { value: priceWei }
                )
            ).to.changeEtherBalance(owner, priceWei);

            // owner nft balance -1
            expect(
                await NichoNFTContract.balanceOf(owner.address)
            ).to.equal(0)
            // addr nft balance +1
            expect(
                await NichoNFTContract.balanceOf(addr1.address)
            ).to.equal(1)
        });

        it("BNB: Double Purchase should not work ", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(
                deployFixture
            );
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);

            // Addr1 purchase NFT that has been minted by owner.
            // We use .connect(signer) to send a transaction from another account
            await NichoNFTMarketplaceContract.connect(addr1).buy(
                NichoNFTContract.address, 0, 
                { value: priceWei }
            )
            
            // Owner gonna buy back from addr1 again.
            await expect(
                NichoNFTMarketplaceContract.buy(
                    NichoNFTContract.address, 0, 
                    { value: priceWei }
                )
            ).to.be.revertedWith("Token: not listed on marketplace")
        });

        it("Listing NFT and purchase, it should work (bnb)", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(
                deployFixture
            );
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);

            // Addr1 purchase NFT that has been minted by owner.
            // We use .connect(signer) to send a transaction from another account
            await NichoNFTMarketplaceContract.connect(addr1).buy(
                NichoNFTContract.address, 0, 
                { value: priceWei }
            )
            
            // Listing NFT from addr1
            await NichoNFTContract.connect(addr1).approve(NichoNFTMarketplaceContract.address, 0);
            await NichoNFTMarketplaceContract.connect(addr1).listItemToMarket(
                NichoNFTContract.address,
                0,
                priceWei.mul(5)
            );

            // Purchase Listed NFT again by owner

            await NichoNFTMarketplaceContract.buy(
                NichoNFTContract.address, 0, 
                { value: priceWei.mul(5) }
            )
            
        });

        it("Only token owner should be able to update listing", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(
                deployFixture
            );
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);
            // Price update
            await expect(
                NichoNFTMarketplaceContract.connect(addr1).listItemToMarket(
                    NichoNFTContract.address,
                    0,
                    priceWei.mul(5)
                )
            ).to.be.revertedWith("Token Owner: you are not a token owner")
        });

        it("Update Listing should work (Price update)", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(
                deployFixture
            );
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);
            // Price  update
            await NichoNFTMarketplaceContract.listItemToMarket(
                NichoNFTContract.address,
                0,
                priceWei.mul(2)
            );
            // check info
            expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, 0)).isListed).to.equal(true)
            expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, 0)).price).to.equal(priceWei.mul(2))

            await NichoNFTMarketplaceContract.connect(addr1).buy(
                NichoNFTContract.address, 0, { value: priceWei.mul(2) }
            )
        });

        it("Update Listing should work (Cancel)", async function () {
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(
                deployFixture
            );
            // MINT
            await NichoNFTContract.mint(uri, owner.address, priceWei, uri);

            // Cancel Listing
            await NichoNFTMarketplaceContract.cancelListing(
                NichoNFTContract.address, 0
            );
            // check info
            expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, 0)).isListed).to.equal(false)
            expect((await NichoNFTMarketplaceContract.getItemInfo(NichoNFTContract.address, 0)).price).to.equal(priceWei.mul(0))

            // After cancel, buyer cannot purchase
            // We use .connect(signer) to send a transaction from another account
            await expect(
                NichoNFTMarketplaceContract.connect(addr1).buy(
                    NichoNFTContract.address, 0, 
                    { value: priceWei.div(2) }
                )
            ).to.be.revertedWith("Token: not listed on marketplace");
        });
    });

    // You can nest describe calls to create subsections.
    describe("Transaction: Batch List", function () {
        // `it` is another Mocha function. This is the one you use to define each
        // of your tests. It receives the test name, and a callback function.
        //
        // If the callback function is async, Mocha will `await` it.
        it("Batch list should work", async function () {
            // We use loadFixture to setup our environment, and then assert that
            // things went well
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(deployFixture);
            
            const batchAmount = 3;
            await NichoNFTContract.batchSNMint(uri, owner.address, priceWei, batchAmount, uri);

            let addresses=[];
            let ids=[];
            for(let i=0; i < batchAmount; i++) {
                addresses.push(NichoNFTContract.address);
                ids.push(i);

                // Purchase all first by addr1
                await NichoNFTMarketplaceContract.connect(addr1).buy(
                    NichoNFTContract.address, i, 
                    { value: priceWei }
                )
            }

            await expect(
                NichoNFTMarketplaceContract.connect(addr1).batchListItemToMarket(
                    addresses,
                    ids,
                    priceWei
                )
            ).to.be.revertedWith("First, Approve NFT");
                
            await NichoNFTContract.connect(addr1).setApprovalForAll(NichoNFTMarketplaceContract.address, true);

            await NichoNFTMarketplaceContract.connect(addr1).batchListItemToMarket(
                addresses,
                ids,
                priceWei
            );
        });
    });

    // You can nest describe calls to create subsections.
    describe("Transaction: Offering", function () {
        it("Token owner cannot create offer for his NFT.", async function () {
            // We use loadFixture to setup our environment, and then assert that
            // things went well
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(deployFixture);

            const batchAmount = 2;
            await NichoNFTContract.batchSNMint(uri, owner.address, priceWei, batchAmount, uri);

            await expect(
                NichoNFTMarketplaceContract.createOffer(
                    NichoNFTContract.address,
                    0,
                    60*5, // 5mins
                    { value: priceWei }
                )
            ).to.be.revertedWith("Owner cannot create offer");
        });

        it("BNB: Create offer and Accept offer should work.", async function () {
            // We use loadFixture to setup our environment, and then assert that
            // things went well
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(deployFixture);

            const batchAmount = 3;
            await NichoNFTContract.batchSNMint(uri, owner.address, priceWei, batchAmount, uri);

            for(let i=0; i < batchAmount; i++) {
                await NichoNFTMarketplaceContract.connect(addr1).createOffer(
                    NichoNFTContract.address,
                    i,
                    60*5, // 5mins
                    { value: priceWei }
                )

                await expect(
                    NichoNFTMarketplaceContract.acceptOffer(
                        NichoNFTContract.address,
                        i,
                        addr1.address
                    )
                ).to.changeEtherBalance(owner, priceWei);
            }
        });

        it("Accept should not work after canceled", async function () {
            // We use loadFixture to setup our environment, and then assert that
            // things went well
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(deployFixture);

            const batchAmount = 1;
            await NichoNFTContract.batchSNMint(uri, owner.address, priceWei, batchAmount, uri);

            for(let i=0; i < batchAmount; i++) {

                await NichoNFTMarketplaceContract.connect(addr1).createOffer(
                    NichoNFTContract.address,
                    i,
                    60*5, // 5mins
                    { value: priceWei }
                )

                await NichoNFTMarketplaceContract.connect(addr1).cancelOffer(
                    NichoNFTContract.address,
                    i
                )
                // Double cancel should not work
                await expect(
                    NichoNFTMarketplaceContract.connect(addr1).cancelOffer(
                        NichoNFTContract.address,
                        i
                    )
                ).to.be.revertedWith("Already withdrawed");
                
                // After withdraw offer, accept offer should not work.
                await expect(
                    NichoNFTMarketplaceContract.acceptOffer(
                        NichoNFTContract.address,
                        i,
                        addr1.address
                    )
                ).to.be.revertedWith("Offer creator withdrawed");

                
            }
        });

        it("Accept should not work for the expired offer", async function () {
            // We use loadFixture to setup our environment, and then assert that
            // things went well
            const { NichoNFTMarketplaceContract, NichoNFTContract, owner, addr1 } = await loadFixture(deployFixture);

            const batchAmount = 1;
            await NichoNFTContract.batchSNMint(uri, owner.address, priceWei, batchAmount, uri);
            // return;
            for(let i=0; i < batchAmount; i++) {
                await NichoNFTMarketplaceContract.connect(addr1).createOffer(
                    NichoNFTContract.address,
                    i,
                    5, // 5s
                    { value: priceWei }
                )
                console.log("==> Sleep: 5s")
                await sleep(6 * 1000);
                console.log("==> Sleep ends")
                
                // For the expired offer, accept offer should not work.
                await expect(
                    NichoNFTMarketplaceContract.acceptOffer(
                        NichoNFTContract.address,
                        i,
                        addr1.address
                    )
                ).to.be.revertedWith("Offer already expired");                
            }
        });
    });

    // You can nest describe calls to create subsections.
    describe("Transaction: Auction Sale", function () {

    });
});