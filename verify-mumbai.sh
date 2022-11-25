#NFTBlackList ()
npx hardhat verify --network mumbai 0x776aBB6989ea7b84a27e9b7455C0d07b070CC041 

# NichoNFT ()
npx hardhat verify --network mumbai 0x32b00Fe6317B2661DB67D4aC90480ff8153835D5 

# NichoNFTMarketplace (_blacklist, _nichonft, factory)
npx hardhat verify --network mumbai 0x5f09d0bd12adAC216528a6D32100A91A86089C54  "0x776aBB6989ea7b84a27e9b7455C0d07b070CC041" "0x32b00Fe6317B2661DB67D4aC90480ff8153835D5" "0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E"

# NichoNFTAuction (_blacklist, _nichonftmarketplace, factory)
npx hardhat verify --network mumbai 0x32451a44ca8AAD554Fa8f3Ef3fF833E65EdA1895  "0x776aBB6989ea7b84a27e9b7455C0d07b070CC041" "0x5f09d0bd12adAC216528a6D32100A91A86089C54" "0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E"
# CollectionFactory (_nichonftmarketplace)
npx hardhat verify --network mumbai 0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E

#0xd296628e818fbccad52e615181eb53f667e43a48
# npx hardhat verify --network testnet 0x907dc3a77a6d85b37b70c37772a1172675921ae1 "0x4a3cf8ea5ef071d61b2d5d53757a0c0cda687860" "0xAC4153304102bAA1Aa2DED5721aB34F3F7D4322E" "RoyalTest" "ROYALTEST" "100"