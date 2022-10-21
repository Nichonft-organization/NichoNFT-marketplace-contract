# NFTBlackList ()
# npx hardhat verify --network testnet 0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E

# NichoNFT ()
# npx hardhat verify --network testnet 0x3bdec7B3A75A150C7Bc7aa4a93a524bDB733F91e

# NichoNFTMarketplace (_blacklist, _nichonft)
npx hardhat verify --network testnet 0x2651B0EDec2a2f68F730F82f20914d51158e9A09 "0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E" "0x3bdec7B3A75A150C7Bc7aa4a93a524bDB733F91e"

# NichoNFTAuction (_blacklist, _nichonftmarketplace)
npx hardhat verify --network testnet 0x5B6A0aFd837424264f4Bdb64cF7ACbb78016b246 "0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E" "0x2651B0EDec2a2f68F730F82f20914d51158e9A09"
# CollectionFactory (_nichonftmarketplace)
npx hardhat verify --network testnet 0xEb66552af4189CA97fb590Ab508fEc765091E254 "0x2651B0EDec2a2f68F730F82f20914d51158e9A09" 

#0xd296628e818fbccad52e615181eb53f667e43a48
# npx hardhat verify --network testnet 0xd296628e818fbccad52e615181eb53f667e43a48 "0x4a3cf8ea5ef071d61b2d5d53757a0c0cda687860" "0x2651B0EDec2a2f68F730F82f20914d51158e9A09" "Test" "Test"