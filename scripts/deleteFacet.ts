import hre, { ethers } from "hardhat";
const { getSelectors, FacetCutAction } = require("../libs/diamond.js");

async function deleteFacet() {
  console.log("");
  const [deployer] = await ethers.getSigners();
  console.log(
    "SKALE | Nebula Gaming Hub Testnet Balance => ",
    await deployer.getBalance()
  );
  const gmxDiamondFactory = await ethers.getContractFactory("GameXPad");
  const gmxDiamondContract = await gmxDiamondFactory.attach("");
  await gmxDiamondContract.deployed();

  const cut = [];
  const FacetName = "Stake";
  const facet = await ethers.getContractAt(
    FacetName,
    gmxDiamondContract.address
  );
  await facet.deployed();

  console.log(`${FacetName} deployed: ${facet.address}`);
  cut.push({
    facetAddress: ethers.constants.AddressZero,
    action: FacetCutAction.Remove,
    functionSelectors: getSelectors(facet),
  });

  const diamondCutFacet = await ethers.getContractAt(
    "DiamondCutFacet",
    gmxDiamondContract.address
  );

  console.log("");
  console.log("Writing diamond cut...");
  const tx = await diamondCutFacet.diamondCut(
    cut,
    ethers.constants.AddressZero,
    "0x"
  );
  await tx.wait();

  console.log("Success.");
}

/*
npx hardhat run scripts/deleteFacet.ts --network nebula-testnet
*/

deleteFacet().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
