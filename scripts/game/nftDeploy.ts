import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const XGameCardFactory = await ethers.getContractFactory("XGameCard");
  const XGameContract = await XGameCardFactory.deploy(deployer.address);
  await XGameContract.deployed();

  let contractAddresses = new Map<string, string>();
  contractAddresses.set("NFT CONTRACT => ", XGameContract.address);
  contractAddresses.set("DEPLOYER     => ", deployer.address);
  console.table(contractAddresses);
}

/*
npx hardhat run scripts/game/nftDeploy.ts --network nebula-testnet
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
