import hre, { ethers } from "hardhat";
const { getSelectors, FacetCutAction } = require("../libs/diamond.js");

async function updateFacet() {
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
  const FacetName = "Distribution";
  const Facet = await ethers.getContractFactory(FacetName);
  // @ts-ignore
  const facet = await Facet.deploy();
  await facet.deployed();
  console.log(`${FacetName} deployed: ${facet.address}`);
  cut.push({
    target: facet.address,
    action: FacetCutAction.Replace,
    selectors: getSelectors(facet),
  });

  console.log("");
  console.log("Writing diamond cut...");
  const tx = await gmxDiamondContract.diamondCut(
    cut,
    ethers.constants.AddressZero,
    "0x"
  );
  await tx.wait();

  console.log("Success.");
}

/*
npx hardhat run scripts/updateFacet.ts --network nebula-testnet
*/

updateFacet().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
