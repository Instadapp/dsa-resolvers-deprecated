require("dotenv").config();
require("@nomiclabs/hardhat-waffle");

if (!process.env.ALCHEMY_API_KEY) {
  throw new Error("ENV Variable ALCHEMY_API_KEY not set!");
}
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.6.10"
      },
      {
        version: "0.7.3"
      }
    ],
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/" + ALCHEMY_API_KEY,
        blockNumber: 12386345
      }
    }
  },
  mocha: {
    timeout: 100000,
  }
};

