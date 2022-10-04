// Deploy on Oct 4th, 2022

const { ethers } = require("hardhat");

// Nicho Token
const initialSupply = "10000000";
const initialSupplyWei = ethers.utils.parseEther(initialSupply);

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", ethers.utils.formatEther(await deployer.getBalance()).toString());
  return;
  // Deploy Nicho ERC20 token contract
  const Nicho = await ethers.getContractFactory("Nicho");
  const NichoToken = await Nicho.deploy(initialSupplyWei);
  await NichoToken.deployed();

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
      NichoToken.address,
      NichoNFTContract.address
  );
  await NichoNFTMarketplaceContract.deployed();

  // Deploy NichoNFT auction contract
  const NichoNFTAuction = await ethers.getContractFactory("NichoNFTAuction");
  const NichoNFTAuctionContract = await NichoNFTAuction.deploy(
      NFTBlackListContract.address,
      NichoToken.address,
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
  await CollectionFactoryContract.deploy("Test NFT", "TestNFT", { value: feePriceWei });            
  const deployedCollectionAddress = await CollectionFactoryContract.getCreatorContractAddress(
    owner.address,
    0
  );
  const DeployedCollectionContract = await ethers.getContractAt("CreatorNFT", deployedCollectionAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });