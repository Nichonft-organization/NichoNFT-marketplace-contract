# NFTBlackList ()
npx hardhat verify --network testnet 0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E
# NichoNFT ()
npx hardhat verify --network testnet 0x5f09d0bd12adAC216528a6D32100A91A86089C54
# NichoNFTMarketplace (_blacklist, _nichonft)
npx hardhat verify --network testnet 0x32451a44ca8AAD554Fa8f3Ef3fF833E65EdA1895 "0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E" "0x5f09d0bd12adAC216528a6D32100A91A86089C54"
# NichoNFTAuction (_blacklist, _nichonftmarketplace)
npx hardhat verify --network testnet 0x3F659c5D792347CaE847350af5e9345f83E3028b "0xBf6232b66dcCfA5EFCd43F0bcAEd743e21822b1E" "0x32451a44ca8AAD554Fa8f3Ef3fF833E65EdA1895"
# CollectionFactory (_nichonftmarketplace)
npx hardhat verify --network testnet 0x5968c6FED8d45912F02Dc294ba1FeeCC8994047A "0x32451a44ca8AAD554Fa8f3Ef3fF833E65EdA1895" 