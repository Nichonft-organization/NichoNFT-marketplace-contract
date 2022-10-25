# NFTBlackList ()
# npx hardhat verify --network testnet 0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E

# NichoNFT ()
# npx hardhat verify --network testnet 0xbBfA39e0483af0DeC1b07A3A4FdB27EEB34B8E19

# NichoNFTMarketplace (_blacklist, _nichonft)
npx hardhat verify --network testnet 0xAC4153304102bAA1Aa2DED5721aB34F3F7D4322E "0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E" "0xbBfA39e0483af0DeC1b07A3A4FdB27EEB34B8E19" "0x3D6E37786abA862F3bE52F060975e39541e6B50A"

# NichoNFTAuction (_blacklist, _nichonftmarketplace)
npx hardhat verify --network testnet 0x674D5b6C1d3472100F7162D2Cf643B9e0ec08b07 "0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E" "0xAC4153304102bAA1Aa2DED5721aB34F3F7D4322E" "0x3D6E37786abA862F3bE52F060975e39541e6B50A"
# CollectionFactory (_nichonftmarketplace)
npx hardhat verify --network testnet 0x3D6E37786abA862F3bE52F060975e39541e6B50A

#0xd296628e818fbccad52e615181eb53f667e43a48
# npx hardhat verify --network testnet 0x907dc3a77a6d85b37b70c37772a1172675921ae1 "0x4a3cf8ea5ef071d61b2d5d53757a0c0cda687860" "0xAC4153304102bAA1Aa2DED5721aB34F3F7D4322E" "RoyalTest" "ROYALTEST" "100"