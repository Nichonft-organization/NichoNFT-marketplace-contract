// Deploy on Oct 4th, 2022

const { ethers } = require("hardhat");

// Nicho Token
const initialSupply = "10000000";
const initialSupplyWei = ethers.utils.parseEther(initialSupply);

async function main() {
  const [deployer] = await ethers.getSigners();

  /*
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", ethers.utils.formatEther(await deployer.getBalance()).toString());
  
  // Deploy NFTBlackList contract
  const NFTBlackList = await ethers.getContractFactory("NFTBlackList");
  const NFTBlackListContract = await NFTBlackList.deploy();
  await NFTBlackListContract.deployed();
  console.log("NFTBlackList", NFTBlackListContract.address)

  // Deploy NichoNFT contract
  const NichoNFT = await ethers.getContractFactory("NichoNFT");
  const NichoNFTContract = await NichoNFT.deploy();
  await NichoNFTContract.deployed();
  console.log("NichoNFT", NichoNFTContract.address)

  // Deploy NichoNFT Marketplace contract
  const NichoNFTMarketplace = await ethers.getContractFactory("NichoNFTMarketplace");
  const NichoNFTMarketplaceContract = await NichoNFTMarketplace.deploy(
      NFTBlackListContract.address,
      NichoNFTContract.address
  );
  await NichoNFTMarketplaceContract.deployed();
  console.log("NichoNFTMarketplace", NichoNFTMarketplaceContract.address)

  // Deploy NichoNFT auction contract
  const NichoNFTAuction = await ethers.getContractFactory("NichoNFTAuction");
  const NichoNFTAuctionContract = await NichoNFTAuction.deploy(
      NFTBlackListContract.address,
      NichoNFTMarketplaceContract.address
  );
  await NichoNFTAuctionContract.deployed();
  console.log("NichoNFTAuction", NichoNFTAuctionContract.address)

  // Deploy Collection contract
  const CollectionFactory = await ethers.getContractFactory("CollectionFactory");
  const CollectionFactoryContract = await CollectionFactory.deploy(NichoNFTMarketplaceContract.address);
  await CollectionFactoryContract.deployed();        
  console.log("CollectionFactory", CollectionFactoryContract.address)

  await NichoNFTContract.setMarketplaceContract(NichoNFTMarketplaceContract.address);
  await NichoNFTMarketplaceContract.enableNichoNFTAuction(NichoNFTAuctionContract.address);
  await NichoNFTMarketplaceContract.setFactoryAddress(CollectionFactoryContract.address);
  */


  // Deploy Collection contract
  const CollectionFactory = await ethers.getContractFactory("CollectionFactory");
  const CollectionFactoryContract = await CollectionFactory.deploy("0x32451a44ca8AAD554Fa8f3Ef3fF833E65EdA1895");
  await CollectionFactoryContract.deployed();        
  console.log("CollectionFactory", CollectionFactoryContract.address)
  // Deploy new NFT contract and get that contract object
  // await CollectionFactoryContract.deploy("Test NFT", "TestNFT", { value: feePriceWei });            
  // const deployedCollectionAddress = await CollectionFactoryContract.getCreatorContractAddress(
  //   owner.address,
  //   0
  // );
  // const DeployedCollectionContract = await ethers.getContractAt("CreatorNFT", deployedCollectionAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });