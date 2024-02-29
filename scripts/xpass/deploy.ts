import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(
    "SKALE | Nebula Gaming Hub Testnet Balance => ",
    await deployer.getBalance()
  );

  const xPassFactory = await ethers.getContractFactory("GameXPass");
  const xPassContract = await xPassFactory.deploy(deployer.address);
  await xPassContract.deployed();

  const xPassDistributeFactory = await ethers.getContractFactory(
    "XPassDistribute"
  );
  const xPassDistributeContract = await xPassDistributeFactory.deploy(
    xPassContract.address
  );
  await xPassDistributeContract.deployed();

  const setMinter = await xPassContract
    .connect(deployer)
    .setMinter(true, xPassDistributeContract.address);
  await setMinter.wait();

  let contractAddresses = new Map<string, string>();
  contractAddresses.set("XPASS      => ", xPassContract.address);
  contractAddresses.set("DISTRIBUTE => ", xPassDistributeContract.address);
  contractAddresses.set("DEPLOYER   => ", deployer.address);
  console.table(contractAddresses);
}

/*
npx hardhat run scripts/xpass/deploy.ts --network nebula-testnet
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
