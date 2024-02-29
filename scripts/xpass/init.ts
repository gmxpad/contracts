import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(
    "SKALE | Nebula Gaming Hub Testnet Balance => ",
    await deployer.getBalance()
  );

  const DISTRIBUTE_CONTRACT = "0x3DA1F63E7bac343a13edb1A24c3e571989975AaB";

  const BASIC_ZEROADDRESS_MERKLE_ROOT =
    "0xfe932063900ae49360094377a9fda6a136462e57c2fd45690202fd676b3b020a";

  const EVENT_PARAMS = {
    isExist: true,
    isMerkle: false,
    merkleRoot: BASIC_ZEROADDRESS_MERKLE_ROOT,
    userCount: 0,
    tokensToBeDist: 2222,
    tokensDist: 0,
    eventStartTime: 1709219130,
    eventEndTime: 1710515130,
  };

  const distContract = await ethers.getContractAt(
    "XPassDistribute",
    DISTRIBUTE_CONTRACT
  );
  await distContract.deployed();

  const initEvent = await distContract
    .connect(deployer)
    .initPassData(EVENT_PARAMS);
  await initEvent.wait();

  let contractAddresses = new Map<string, string>();
  contractAddresses.set("DISTRIBUTE => ", distContract.address);
  contractAddresses.set("DEPLOYER   => ", deployer.address);
  console.table(contractAddresses);
}

/*
npx hardhat run scripts/xpass/init.ts --network nebula-testnet
*/

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
