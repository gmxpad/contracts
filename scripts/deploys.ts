import { ethers } from "hardhat";

const { FacetList } = require("../libs/facets.ts");
const { getSelectors, FacetCutAction } = require("../libs/diamond.js");

async function main() {
  console.dir(FacetList);
  console.log("");
  const [deployer] = await ethers.getSigners();
  console.log(
    "SKALE | Nebula Gaming Hub Testnet Balance => ",
    await deployer.getBalance()
  );

  const gmxpadDiamondFactory = await ethers.getContractFactory("GameXPad");
  const gmxpadDiamond = await gmxpadDiamondFactory.deploy();
  await gmxpadDiamond.deployed();

  const gmxpTokenFactory = await ethers.getContractFactory("GMXPToken");
  const gmxpTokenContract = await gmxpTokenFactory.attach(
    "0xdD3932ad40716aBa856694a42A23EB66e1A57BF9"
  );
  await gmxpTokenContract.deployed();

  const xxTokenFactory = await ethers.getContractFactory("XXToken");
  const xxTokenContract = await xxTokenFactory.attach(
    "0xa5Fe0D55d33f6179790fA620F81Fe27463334f6B"
  );
  await xxTokenContract.deployed();

  const cut = [];
  for (const FacetName of FacetList) {
    const Facet = await ethers.getContractFactory(FacetName);
    // @ts-ignore
    const facet = await Facet.deploy();
    await facet.deployed();
    console.log(`${FacetName} facet deployed 👍 => ${facet.address}`);
    cut.push({
      target: facet.address,
      action: FacetCutAction.Add,
      selectors: getSelectors(facet),
    });
  }

  console.log("");
  console.log("Writing diamond cut...");
  const addressZero = ethers.constants.AddressZero;
  const tx = await gmxpadDiamond.diamondCut(cut, addressZero, "0x");
  await tx.wait();
  console.log("Success.");

  let contractAddresses = new Map<string, string>();
  contractAddresses.set("DIAMOND    => ", gmxpadDiamond.address);
  contractAddresses.set("GMXP TOKEN => ", gmxpTokenContract.address);
  contractAddresses.set("XX TOKEN   => ", xxTokenContract.address);
  contractAddresses.set("DEPLOYER   => ", deployer.address);
  console.table(contractAddresses);
}

/*
npx hardhat run scripts/deploys.ts --network nebula-testnet
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
