# Pulsechain Contract Verification Framework

## How to use
1. Clone this repository
2. Install `yarn` (Google it if you have no clue what this is)
3. Run `yarn install` to install dependencies
4. Add your contracts inside the `contracts` directory.
5. Modify the `hardhat.config.js` file as needed.
6. Modify the `scripts/verify.js` script for your contract.
7. Run `yarn verify`
8. You may get a list of missing dependencies at this stage if so you may need to run `yarn add --dev` and include the list of dependencies shown.
e.g.  yarn add --dev "@types/mocha@>=9.1.0" "@typechain/ethers-v5@^10.1.0" "@typechain/hardhat@^6.1.2" "solidity-coverage@^0.8.1" "ts-node@>=8.0.0" "typechain@^8.1.0" "typescript@>=4.5.0"
