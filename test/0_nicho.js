const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

const initialSupply = "5000";
const initialSupplyWei = ethers.utils.parseEther(initialSupply);

describe("Nicho Token contract", function () {
    // We define a fixture to reuse the same setup in every test. We use
    // loadFixture to run this setup once, snapshot that state, and reset Hardhat
    // Network to that snapshot in every test.
    async function deployTokenFixture() {
        // Get the ContractFactory and Signers here.
        const Nicho = await ethers.getContractFactory("Nicho");
        const [owner, addr1, addr2] = await ethers.getSigners();

        // To deploy our contract, we just have to call Token.deploy() and await
        // its deployed() method, which happens onces its transaction has been
        // mined.
        const NichoToken = await Nicho.deploy(initialSupplyWei);

        await NichoToken.deployed();

        // Fixtures can return anything you consider useful for your tests
        return { Nicho, NichoToken, owner, addr1, addr2 };
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
            const { NichoToken, owner } = await loadFixture(deployTokenFixture);

            // `expect` receives a value and wraps it in an assertion object. These
            // objects have a lot of utility methods to assert values.

            // This test expects the owner variable stored in the contract to be
            // equal to our Signer's owner.
            expect(await NichoToken.owner()).to.equal(owner.address);
        });

        it("Should assign the total supply of tokens to the owner", async function () {
            const { NichoToken, owner } = await loadFixture(deployTokenFixture);
            const ownerBalance = await NichoToken.balanceOf(owner.address);
            expect(await NichoToken.totalSupply()).to.equal(ownerBalance);
        });
    });

    describe("Transactions", function () {
        it("Should transfer tokens between accounts", async function () {
            const { NichoToken, owner, addr1, addr2 } = await loadFixture(
                deployTokenFixture
            );
            // Transfer 50 tokens from owner to addr1
            await expect(
                NichoToken.transfer(addr1.address, 50)
            ).to.changeTokenBalances(NichoToken, [owner, addr1], [-50, 50]);

            // Transfer 50 tokens from addr1 to addr2
            // We use .connect(signer) to send a transaction from another account
            await expect(
                NichoToken.connect(addr1).transfer(addr2.address, 50)
            ).to.changeTokenBalances(NichoToken, [addr1, addr2], [-50, 50]);
        });

        it("should emit Transfer events", async function () {
            const { NichoToken, owner, addr1, addr2 } = await loadFixture(
                deployTokenFixture
            );

            // Transfer 50 tokens from owner to addr1
            await expect(NichoToken.transfer(addr1.address, 50))
                .to.emit(NichoToken, "Transfer")
                .withArgs(owner.address, addr1.address, 50);

            // Transfer 50 tokens from addr1 to addr2
            // We use .connect(signer) to send a transaction from another account
            await expect(NichoToken.connect(addr1).transfer(addr2.address, 50))
                .to.emit(NichoToken, "Transfer")
                .withArgs(addr1.address, addr2.address, 50);
        });

        it("Should fail if sender doesn't have enough tokens", async function () {
            const { NichoToken, owner, addr1 } = await loadFixture(
                deployTokenFixture
            );
            const initialOwnerBalance = await NichoToken.balanceOf(owner.address);

            // Try to send 1 token from addr1 (0 tokens) to owner (1000 tokens).
            // `require` will evaluate false and revert the transaction.
            
            await NichoToken.connect(addr1).approve(owner.address, 1)
            await expect(
                NichoToken.connect(addr1).transfer(owner.address, 1)
            ).to.be.revertedWith("ERC20: transfer amount exceeds balance");

            // Owner balance shouldn't have changed.
            expect(await NichoToken.balanceOf(owner.address)).to.equal(
                initialOwnerBalance
            );
        });
    });
});