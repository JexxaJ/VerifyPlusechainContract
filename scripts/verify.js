// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  // Live address of the contract
  const address = '0xaafcab9005e45b054c7b92c7c92ce20ce2264c46'

  // Specific contract inside /contracts. denoted as "Filename.sol:ContractName"
  // Leave blank if there is only one. 
  const contract = 'contracts/voting.sol:Voting'

  // Put constructor args (if any) here for your contract    0x7FF1d7D0c669a2602Ed17059785cA344BB6db925
  const constructorArguments = ["0x25723611B1C4878E2A0e177ab9BF1109c43b9Fd0"]

  if (address === '') {
    throw Error("I can't do it without an address")
  }

  if (contract === '') {
    console.warn("While I can run without specifying the contract, it's error prone. YMMV")
  }

  console.log('Running verify script...')

  await run("verify:verify", {
    address: address,
    contract: contract,
    constructorArguments: constructorArguments
  })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
