require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-solhint");
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import '@openzeppelin/hardhat-upgrades';
import { HardhatUserConfig, HttpNetworkUserConfig } from "hardhat/types";
require("hardhat-gas-reporter");
require("solidity-coverage");
require("./scripts/tasks");


const config: HardhatUserConfig & { etherscan: any } = {
  networks: {
    develop: {
      url: "http://localhost:8545",
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.KOVAN_PRIVATE_KEY],
      gas: "auto"
    } as HttpNetworkUserConfig,
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.GOERLI_PRIVATE_KEY],
      gas: "auto"
    } as HttpNetworkUserConfig,
    coverage: {
      url: "http://localhost:8555"
    }
  },
  solidity: {
    compilers: [{
      version: "0.7.3",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }, {
      version: "0.6.8"
    }, {
      version: "0.5.17",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }]
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  mocha: {
    timeout: 100000
  }
};

module.exports = config;