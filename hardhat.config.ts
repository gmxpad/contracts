import "@nomicfoundation/hardhat-toolbox";
import { config as dotenvConfig } from "dotenv";
import "hardhat-deploy";
import type { HardhatUserConfig } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import { resolve } from "path";
import "hardhat-diamond-abi";
import "@nomiclabs/hardhat-etherscan";
import "./tasks/accounts";

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });

const mnemonic: string | undefined = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}

const privatekey: string | undefined = process.env.PRIVATE_KEY;
if (!privatekey) {
  throw new Error("Please set your private key in a .env file");
}

const chainIds = {
  mainnet: 1,
  ganache: 1337,
  hardhat: 31337,
  chaos: 1351057110,
  nebula: 1482601649,
  "nebula-testnet": 37084624,
};

function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
  let jsonRpcUrl: string;
  switch (chain) {
    case "mainnet":
      jsonRpcUrl = "https://1rpc.io/eth";
      break;
    case "chaos":
      jsonRpcUrl =
        "https://staging-v3.skalenodes.com/v1/staging-fast-active-bellatrix";
      break;
    case "nebula":
      jsonRpcUrl = "https://mainnet.skalenodes.com/v1/green-giddy-denebola";
      break;
    case "nebula-testnet":
      jsonRpcUrl = "https://testnet.skalenodes.com/v1/lanky-ill-funny-testnet";
      break;
    default:
      jsonRpcUrl = "";
      break;
  }
  return {
    accounts: {
      count: 10,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chainIds[chain],
    url: jsonRpcUrl,
  };
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",

  diamondAbi: {
    strict: false,
    name: "DiamondABI",
    include: ["Stake", "Query", "Settings", "Create", "Ipo"],
    exclude: [],
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      skale: process.env.SKALE_API_KEY || "skalenetwork",
    },
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: "./contracts",
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.hardhat,
    },
    ganache: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.ganache,
      url: "http://localhost:8545",
    },
    mainnet: getChainConfig("mainnet"),
    chaos: getChainConfig("chaos"),
    nebula: getChainConfig("nebula"),
    "nebula-testnet": getChainConfig("nebula-testnet"),
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.20",
    settings: {
      evmVersion: "paris",
      metadata: {
        bytecodeHash: "none",
      },
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
};

export default config;
