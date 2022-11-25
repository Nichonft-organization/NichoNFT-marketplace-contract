/** @type import('hardhat/config').HardhatUserConfig */
require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

// Replace this private key with your Goerli account private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Beware: NEVER put real Ether into testing accounts
const DEPLOYER_KEY = process.env.DEPLOYER_KEY;

// Verify contract
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY;
const POLYGON_API_KEY = process.env.POLYGON_API_KEY;

module.exports = {
  solidity: "0.8.17",
  settings: { optimizer: { enabled: true, runs: 1 } },
  networks: {
    // BNBchain mainnet
    mainnet: {
      url: `https://bsc-dataseed.binance.org`,
      accounts: [DEPLOYER_KEY],
    },
    // Bsc testnet
    testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      accounts: [DEPLOYER_KEY],
    },
    // Polygon mainnet
    polygon: {
      url: `https://polygon-rpc.com`,
      accounts: [DEPLOYER_KEY],
    },
    // Polygon mumbai testnet
    mumbai: {
      url: `https://rpc-mumbai.maticvigil.com/`,
      accounts: [DEPLOYER_KEY],
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
    apiKey: POLYGON_API_KEY,
  },
};
