const fs = require('fs');
const { web3, ethers } = require('hardhat');
const CONFIG = require("../scripts/credentials.json");
// const nftABI = (JSON.parse(fs.readFileSync('./artifacts/contracts/NFT.sol/NFT.json', 'utf8'))).abi;

contract("Utility Deployment", () => {
    let nft;
    let tx;

    const provider = new ethers.providers.JsonRpcProvider(CONFIG["RINKEBY"]["URL"]);
    const signer = new ethers.Wallet(CONFIG["RINKEBY"]["PKEY"]);
    const account = signer.connect(provider);

    before(async () => {
      const Utility = await ethers.getContractFactory("UtilityContract");
      utility = await Utility.deploy();
      await utility.deployed();

      console.log("Utility deployed at address: ",utility.address);

    })

    // after(async () => {
    //     console.log('\u0007');
    //     console.log('\u0007');
    //     console.log('\u0007');
    //     console.log('\u0007');
    // })

    it ("should print contract address", async () => {
      console.log("Utility deployed at address: ",nft.address);
      
    });
})