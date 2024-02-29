import { ethers } from "hardhat";
import DiamondABI from "../../artifacts/hardhat-diamond-abi/HardhatDiamondABI.sol/DiamondABI.json";

async function main() {
  const [deployer] = await ethers.getSigners();

  const DIAMOND_CONTRACT = "0xDd32E902AE551CBA07016AAb66debCd077Ccfb77";

  const gmxpadDiamond = await ethers.getContractAt(
    "DiamondABI",
    DIAMOND_CONTRACT
  );

  const TSocials = {
    web: "",
    twitter: "",
    telegram: "",
    discord: "",
    whitepaper: "",
    youtube: "",
  };

  const TGamePlatforms = {
    pWeb: "",
    pAndroid: "",
    pWindows: "",
    pMacOS: "",
    pIOS: "",
  };

  const TGameDetails = {
    slug: "",
    name: "",
    developer: "",
    description: "",
    imageBackground: "",
    imagePoster: "",
    imageLogo: "",
    videoTrailer: "",
    socials: TSocials,
    platforms: TGamePlatforms,
    genres: ["MOBA", "MMO"],
  };

  const TGame = {
    isExist: true,
    isView: true,
    isIPO: true,
    details: TGameDetails,
    projectId: 1,
    roundCount: 0,
    totalUserCount: 0,
    totalInvestment: 0,

    round: 1,
    minInvestment: 1e6,
    maxInvestment: 100e6,
    toBeCollectedInvestment: 1000000e6,
    collectedInvestment: 0,
    perSharePrice: 1e6,
    roundScore: 0,
    userCount: 0,
    registerStart: 1708708980,
    registerEnd: 1708708980,
    guaranteedInvestmentStart: 1708708980,
    guaranteedInvestmentEnd: 1708708980,

    nftContract: ethers.constants.AddressZero,
  };

  const createGame = await gmxpadDiamond.connect(deployer).createGame(TGame);
  await createGame.wait();

  let contractAddresses = new Map<string, string>();
  contractAddresses.set("DIAMOND    => ", gmxpadDiamond.address);
  contractAddresses.set("DEPLOYER   => ", deployer.address);
  console.table(contractAddresses);
}

/*
npx hardhat run scripts/game/create.ts --network nebula-testnet
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
