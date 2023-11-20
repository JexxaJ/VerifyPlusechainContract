// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  // Live address of the contract
  const address = '0x21F279B6de28C98a3093E4D79e11E7b82a2E225C'

  // Specific contract inside /contracts. denoted as "Filename.sol:ContractName"
  // Leave blank if there is only one. 
  const contract = 'contracts/fluffy.sol:FluffySlippersEdition0'

  // Put constructor args (if any) here for your contract
  const constructorArguments = []

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
