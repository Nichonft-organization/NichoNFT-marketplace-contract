require('dotenv').config();

const NichoAuction = artifacts.require("NichoAuction");
const NichoNFT = "0x2a5b48077aBCA8cFC25644688fE82BcCdA0062c7";

module.exports = function (deployer) {
  deployer.deploy(NichoAuction, NichoNFT);
};

// Mainnet May 25th
// Verified: https://bscscan.com/address/0x1f846842E86AB07d4464A6AD09d6723474FBe268#code

// 2022-05-11
// https://testnet.bscscan.com/address/0x2312813Ff03853a07f19BA5f529cB050BEc28F75#code

// 2022-05-11
// https://testnet.bscscan.com/address/0x36A2c23C75B9F6361b5867333e6878f969851DbD#code

// 2022-05-10
// https://testnet.bscscan.com/address/0x4a947b34Ce20b04637FC6045d59eB1e2DC7ae3DC#code
// 2022-05-06
// https://testnet.bscscan.com/address/0x8EC639a47C3f36129cCEFbe8169580001922a0De#code

// 2022-04-27
// https://testnet.bscscan.com/address/0xFE46dB783a6621ece4FEf783b6589C2d2d878a59#code