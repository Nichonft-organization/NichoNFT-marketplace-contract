require('dotenv').config();

const NichoNFT = artifacts.require("NichoNFT");

const FEE_ADDRESS = `${process.env.FEE_ADDRESS}`;

module.exports = function (deployer) {
  deployer.deploy(NichoNFT, FEE_ADDRESS);
};

// Mainnet May 25th
// Verified: https://bscscan.com/address/0x2a5b48077aBCA8cFC25644688fE82BcCdA0062c7#code

// May 24th
// https://testnet.bscscan.com/address/0x15C411103Dd679494b9EebF98f38699a8cd37055#code

// May 10th
// https://testnet.bscscan.com/address/0x68D89a72D9DeeFA21efD0B439B0fB3f7908a760b#code

// Mar 30th
// https://testnet.bscscan.com/address/0x9994D76f9e8eE5db88cf857E58D363B92ccf169f#code

// Mar 29th
// https://testnet.bscscan.com/address/0xe3Accb7B7E38FBA490dA411a7975AE8D49059463#code

// March 16th
// https://testnet.bscscan.com/address/0x5d695DA08ffF3168Df4E8e82B9e3253b35Caa448#code