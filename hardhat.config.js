// require('dotenv').config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3");
// require("solidity-coverage");
// require("hardhat-gas-reporter");
// require('hardhat-deploy');
require("@nomiclabs/hardhat-etherscan");
// require("@tenderly/hardhat-tenderly")

const fs = require('fs');

async function readCSV(filePath) {
  if (!fs.existsSync(filePath)) throw Error("Please create snapshot.csv first");
  return fs.readFileSync(filePath).toString()
      .split("\n")
      .map((row) => {
        return row.split(",").map((cell) => {
          return cell
              .replace(/"/g, '')
              .replace(/'/g, '')
              .replace(/\n/g, '')
              .replace(/\r/g, '')
              .trim()
        });
      });
}

async function cleanAmount(amount) {
  return (parseFloat(amount) * 10000).toFixed(0) + "00000000000000"; // accurate upto 4 decimal points only
}

task("airdrop", "Distribute balance of current deployed token to all the users of old token")
    .addParam("token", "Latest deployed token address")
    .setAction(async taskArgs => {
      let data = await readCSV('./snapshot.csv')
      data = data.slice(1); // remove header row
      // create instance of token
      const token = await ethers.getContractAt("SeaToken", taskArgs.token);

      for (const row of data) {
        if (row.length !== 3) continue; // make sure row is not empty or malformed
        const address = row[0];
        const amount = await cleanAmount(row[1]);
        console.log(`Transferring ${amount} Sea to ${address}`);
        await token.transfer(address, amount);
      }
    });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.1",
    settings: {
      optimizer: {
        enabled: false,
        runs: 200
      }
    }
  },
  tenderly: {
		username: "angadsinghagarwal",
		project: "sea"
	},
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.BSCSCAN_API_KEY // for this to work go to => <project-root>/node_modules/@nomiclabs/hardhat-etherscan/src/network/prober.ts and update mainnet etherscan api urls to bscscan ones
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 20
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  networks: {
    // hardhat: {
    //   forking: {
    //     url: process.env.NODE_RPC_URL
    //   }
    // },
    // BSCTestnet: {
    //   url: process.env.NODE_RPC_URL,
    //   accounts: process.env.PRIVATE_KEY,
    //   networkCheckTimeout: 20000,
    //   skipDryRun: true,
    //   gas: 7000000,
    //   gasPrice: 25000000000,
    //   network_id: 97
    // },
    // BSCMainnet: {
    //   url: process.env.NODE_RPC_URL,
    //   accounts: process.env.PRIVATE_KEY,
    //   networkCheckTimeout: 20000,
    //   skipDryRun: true,
    //   gas: 7000000,
    //   gasPrice: 5000000000,
    //   network_id: 56
    // },
  }
};

