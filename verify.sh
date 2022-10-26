#NFTBlackList ()
npx hardhat verify --network testnet 0x8402c3A22385FD760F9b5E417763318Cbc162520 

# NichoNFT ()
npx hardhat verify --network testnet 0x191837C0D498F1e506CDb5FE81596AE56aFEe71d 

# NichoNFTMarketplace (_blacklist, _nichonft, factory)
npx hardhat verify --network testnet 0xc39f6AE018f4328B1e98b9F72106bfE49e40FE14  "0x8402c3A22385FD760F9b5E417763318Cbc162520" "0x191837C0D498F1e506CDb5FE81596AE56aFEe71d" "0xC3aC6258900619409E0102d06566C1b4E3b3f483"

# NichoNFTAuction (_blacklist, _nichonftmarketplace, factory)
npx hardhat verify --network testnet 0xCD4F8793ce04bDeF0c83727a92112eAf35eCF769  "0x8402c3A22385FD760F9b5E417763318Cbc162520" "0xc39f6AE018f4328B1e98b9F72106bfE49e40FE14" "0xC3aC6258900619409E0102d06566C1b4E3b3f483"
# CollectionFactory (_nichonftmarketplace)
npx hardhat verify --network testnet 0xC3aC6258900619409E0102d06566C1b4E3b3f483

#0xd296628e818fbccad52e615181eb53f667e43a48
# npx hardhat verify --network testnet 0x907dc3a77a6d85b37b70c37772a1172675921ae1 "0x4a3cf8ea5ef071d61b2d5d53757a0c0cda687860" "0xAC4153304102bAA1Aa2DED5721aB34F3F7D4322E" "RoyalTest" "ROYALTEST" "100"