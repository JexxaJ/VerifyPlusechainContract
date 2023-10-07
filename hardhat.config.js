require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",

    // Additional compiler settings
    // settings: {
    //   optimizer: {
    //     enabled: false,
    //     runs: 200
    //   },
    //   outputSelection: {
    //    "*": {
    //       "": [
    //         "ast"
    //       ],
    //       "*": [
    //         "abi",
    //         "metadata",
    //         "devdoc",
    //         "userdoc",
    //         "storageLayout",
    //         "evm.legacyAssembly",
    //         "evm.bytecode",
    //         "evm.deployedBytecode",
    //         "evm.methodIdentifiers",
    //         "evm.gasEstimates",
    //         "evm.assembly"
    //       ]
    //     }
    //   }      
    // }

  },
  networks: {
    pulse: {
      chainId: 943,
      url: "https://rpc.v4.testnet.pulsechain.com",
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
  chainId: 943,
  urls: {
    apiURL: "https://scan.v4.testnet.pulsechain.com/api",
    browserURL: "https://scan.v4.testnet.pulsechain.com/",
  },
}
