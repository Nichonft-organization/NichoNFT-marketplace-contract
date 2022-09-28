require('dotenv').config();

// const Nicho = artifacts.require("Nicho");
// const NFTBlackList = artifacts.require("NFTBlackList");
// const NichoNFTMarketplace = artifacts.require("NichoNFTMarketplace");
// const NichoNFT = artifacts.require("NichoNFT");

module.exports = async function (deployer) {
    console.log("Deployer: ", deployer);

    // /// Deploy Nicho Token
    // const initialSupply = "100000000000000000000"
    // await deployer.deploy(Nicho, initialSupply);
    // const nicho = await Nicho.deployed();
    // console.log("Nicho address:", nicho.address)


    // /// Deploy NFTBlackList
    // await deployer.deploy(NFTBlackList);
    // const blacklist = await NFTBlackList.deployed();
    // console.log("NFTBlackList address:", blacklist.address)

    // /// Deploy marketplace
    // await deployer.deploy(NichoNFTMarketplace, blacklist.address, nicho.address);
    // const marketplace = await NichoNFTMarketplace.deployed();
    // console.log("NichoNFTMarketplace address:", marketplace.address)

    // if(!nicho.address || !blacklist.address || !marketplace.address) {
    //     console.error("something went wrong");
    //     return;
    // }

    /// Deploy NichoNFT Token
    // await deployer.deploy(NichoNFT, "0xAa17b4c0E316FAA543BA2D61F349350912054D63"); // marketplace.address);
    // const nichonft = await NichoNFT.deployed();
    // console.log("NichoNFT address:", nichonft.address)
};

// NichoNFTMarketplace address: 0xAa17b4c0E316FAA543BA2D61F349350912054D63
// NFTBlackList address: 0xB29706d3e001A0898831f98cdedb2C112176574A
// Nicho address: 0x939b6e6342e5216353D885887DeE5e5F2eabA917
// NichoNFT address: 0xb70ee297B05653C5D997F60542B2aaCcC645F64a