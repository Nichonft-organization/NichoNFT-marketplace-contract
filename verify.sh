# NFTBlackList ()
# npx hardhat verify --network testnet 0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E

# NichoNFT ()
# npx hardhat verify --network testnet 0x924384699f32af9B9aE33707BDB82b7DB755578a

# NichoNFTMarketplace (_blacklist, _nichonft)
npx hardhat verify --network testnet 0x2B50917a7B6e007910DC0eD95075Db9774dCf674 "0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E" "0x924384699f32af9B9aE33707BDB82b7DB755578a" "0x993Dead7179BeF441cbecE24A465bAfA2eabdD48"

# NichoNFTAuction (_blacklist, _nichonftmarketplace)
npx hardhat verify --network testnet 0xDe095d4590A8e9c575FcCC70985fA3F39e7346A7 "0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E" "0x2B50917a7B6e007910DC0eD95075Db9774dCf674" "0x993Dead7179BeF441cbecE24A465bAfA2eabdD48"
# CollectionFactory (_nichonftmarketplace)
npx hardhat verify --network testnet 0x993Dead7179BeF441cbecE24A465bAfA2eabdD48

#0xd296628e818fbccad52e615181eb53f667e43a48
# npx hardhat verify --network testnet 0x907dc3a77a6d85b37b70c37772a1172675921ae1 "0x4a3cf8ea5ef071d61b2d5d53757a0c0cda687860" "0x2B50917a7B6e007910DC0eD95075Db9774dCf674" "RoyalTest" "ROYALTEST" "100"