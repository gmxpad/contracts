import { ethers } from "hardhat";
import DiamondABI from "../../artifacts/hardhat-diamond-abi/HardhatDiamondABI.sol/DiamondABI.json";

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
  const gmxpLiqAmount = ethers.utils.parseEther("100000");
  const xxLiqAmount = ethers.utils.parseEther("100000");

  const approveGMXP = await gmxpTokenContract
    .connect(deployer)
    .approve(gmxpadDiamond.address, gmxpLiqAmount);
  await approveGMXP.wait();
  console.log("Approved $GMXP Tokens => ", gmxpLiqAmount);

  const approveXX = await xxTokenContract
    .connect(deployer)
    .approve(gmxpadDiamond.address, xxLiqAmount);
  await approveXX.wait();
  console.log("Approved $XX Tokens => ", xxLiqAmount);

  const gmxAddLiq = await gmxpadDiamond
    .connect(deployer)
    .addToken0Liquidity(gmxpLiqAmount);
  await gmxAddLiq.wait();
  console.log("Added $GMXP Tokens => ", gmxpLiqAmount);

  const xxAddLiq = await gmxpadDiamond
    .connect(deployer)
    .addToken1Liquidity(xxLiqAmount);
  await xxAddLiq.wait();
  console.log("Added $XX Tokens => ", xxLiqAmount);

  let contractAddresses = new Map<string, string>();
  contractAddresses.set("DIAMOND    => ", gmxpadDiamond.address);
  contractAddresses.set("GMXP TOKEN => ", gmxpTokenContract.address);
  contractAddresses.set("XX TOKEN   => ", xxTokenContract.address);
  contractAddresses.set("DEPLOYER   => ", deployer.address);
  console.table(contractAddresses);
}

/*
npx hardhat run scripts/stake/addLiquidity.ts --network nebula-testnet
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
