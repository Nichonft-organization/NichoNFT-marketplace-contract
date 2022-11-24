#NFTBlackList ()
npx hardhat verify --network mainnet 0xb95930a2f8068893E4d2d23A673a0b049ADd2254 

# NichoNFT ()
npx hardhat verify --network mainnet 0x09262090b30AF49332f697f3601050065EFF647b 

# NichoNFTMarketplace (_blacklist, _nichonft, factory)
npx hardhat verify --network mainnet 0xE4083CC4Bc7224F00b8f288d3a8616a325144C4a  "0xb95930a2f8068893E4d2d23A673a0b049ADd2254" "0x09262090b30AF49332f697f3601050065EFF647b" "0xbeba016c86683A2D35eb3e6553Ed0a6cA730500D"

# NichoNFTAuction (_blacklist, _nichonftmarketplace, factory)
npx hardhat verify --network mainnet 0xEA5d5ed29AD686b06c2F52DcFcaA8D80a453A558  "0xb95930a2f8068893E4d2d23A673a0b049ADd2254" "0xE4083CC4Bc7224F00b8f288d3a8616a325144C4a" "0xbeba016c86683A2D35eb3e6553Ed0a6cA730500D"
# CollectionFactory (_nichonftmarketplace)
npx hardhat verify --network mainnet 0xbeba016c86683A2D35eb3e6553Ed0a6cA730500D

#0xd296628e818fbccad52e615181eb53f667e43a48
# npx hardhat verify --network testnet 0x907dc3a77a6d85b37b70c37772a1172675921ae1 "0x4a3cf8ea5ef071d61b2d5d53757a0c0cda687860" "0xAC4153304102bAA1Aa2DED5721aB34F3F7D4322E" "RoyalTest" "ROYALTEST" "100"