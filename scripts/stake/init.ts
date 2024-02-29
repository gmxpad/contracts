import { ethers } from "hardhat";
import DiamondABI from "../../artifacts/hardhat-diamond-abi/HardhatDiamondABI.sol/DiamondABI.json";

const {
  Amounts,
  AmountMultipliers,
  Times,
  TimeMultiplers,
} = require("../../libs/facets.ts");

async function main() {
  const [deployer] = await ethers.getSigners();

  const DIAMOND_CONTRACT = "0xDd32E902AE551CBA07016AAb66debCd077Ccfb77";
  const GMXP_TOKEN_CONTRACT = "0xdD3932ad40716aBa856694a42A23EB66e1A57BF9";
  const XX_TOKEN_CONTRACT = "0xa5Fe0D55d33f6179790fA620F81Fe27463334f6B";

  const gmxpadDiamond = await ethers.getContractAt(
    "DiamondABI",
    DIAMOND_CONTRACT
  );

  const gmxpTokenContract = await ethers.getContractAt(
    "GMXPToken",
    GMXP_TOKEN_CONTRACT
  );

  const xxTokenContract = await ethers.getContractAt(
    "XXToken",
    XX_TOKEN_CONTRACT
  );

  const addAmounts = await gmxpadDiamond
    .connect(deployer)
    .addAmounts(Amounts, AmountMultipliers);
  await addAmounts.wait();

  const addTimes = await gmxpadDiamond
    .connect(deployer)
    .addTimes(Times, TimeMultiplers);
  await addTimes.wait();

  const setToken0 = await gmxpadDiamond
    .connect(deployer)
    .setToken0(gmxpTokenContract.address);
  await setToken0.wait();
  console.log("Settled Token0 👍", await gmxpTokenContract.name());

  const setToken1 = await gmxpadDiamond
    .connect(deployer)
    .setToken1(xxTokenContract.address);
  await setToken1.wait();
  console.log("Settled Token1 👍", await xxTokenContract.name());

  const isActive: boolean = true;
  const setPoolActive = await gmxpadDiamond
    .connect(deployer)
    .setPoolActive(isActive);
  await setPoolActive.wait();
  console.log("Pool Status => ", isActive);

  let contractAddresses = new Map<string, string>();
  contractAddresses.set("DIAMOND    => ", gmxpadDiamond.address);
  contractAddresses.set("GMXP TOKEN => ", gmxpTokenContract.address);
  contractAddresses.set("XX TOKEN   => ", xxTokenContract.address);
  contractAddresses.set("DEPLOYER   => ", deployer.address);
  console.table(contractAddresses);
}

/*
npx hardhat run scripts/stake/init.ts --network nebula-testnet
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
