require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.17",
                settings: {
                    "evmVersion": "london",
                    optimizer: {
                        enabled: false,
                        runs: 200
                    },
                    outputSelection: {
                        "*": {
                            "": [
                                "ast"
                            ],
                            "*": [
                                "abi",
                                "metadata",
                                "devdoc",
                                "userdoc",
                                "storageLayout",
                                "evm.legacyAssembly",
                                "evm.bytecode",
                                "evm.deployedBytecode",
                                "evm.methodIdentifiers",
                                "evm.gasEstimates",
                                "evm.assembly"
                            ]
                        }
                    }
                }
            },
            {
                version: "0.8.20",
                settings: {
                    "evmVersion": "london",
                    optimizer: {
                        enabled: false,
                        runs: 200
                    },
                    outputSelection: {
                        "*": {
                            "": [
                                "ast"
                            ],
                            "*": [
                                "abi",
                                "metadata",
                                "devdoc",
                                "userdoc",
                                "storageLayout",
                                "evm.legacyAssembly",
                                "evm.bytecode",
                                "evm.deployedBytecode",
                                "evm.methodIdentifiers",
                                "evm.gasEstimates",
                                "evm.assembly"
                            ]
                        }
                    }
                }
            }
        ]
    },
    networks: {
        pulse: {
            chainId: 369,
            url: "https://rpc.pulsechain.com",
            gasPrice: 50000000000,
        }
    },
    etherscan: { // needed for contract verification
        apiKey: {
            pulse: '0',
        }
    }
};

require("@nomiclabs/hardhat-etherscan");
const { chainConfig } = require("@nomiclabs/hardhat-etherscan/dist/src/ChainConfig");
chainConfig['pulse'] = {
    chainId: 369,
    urls: {
        apiURL: "https://scan.pulsechain.com/api",
        browserURL: "https://scan.pulsechain.com/",
    },
}
