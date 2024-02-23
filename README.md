# flutter_dapp_sample

A new Flutter project.

## Getting Started

To run this project you'll need some requirement:

- nodejs with npm installed
- installing hardhat with  `npm install --save-dev hardhat` 
- make sure that the hardhat toolbox is also installed `npm install --save-dev @nomicfoundation/hardhat-toolbox`

- make sure to configure `hardhat.config.js`:
```javascript
/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-toolbox");// added this
module.exports = {
  solidity: "0.8.24",
};
```

- make sure that the `deploy.js` script is as follows:
```javascript
async function main() {

const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  
  //deploy storage contract (first deployed contract)
  const storage = await ethers.deployContract("Storage"); // class must match names when deploying
  console.log('Deploying storage ...');
  
  let storageAddress = await storage.getAddress();

  console.log('storage deployed to:', storageAddress);
  

  //deploy bounty contract
  const logic = await ethers.deployContract("Logic");
  console.log('Deploying logic ...');
  
  let logicAddress = await logic.getAddress();

  console.log('logic deployed to:', logicAddress);



  console.log( "storage: " + storageAddress );
  console.log( "logic: " + logicAddress ); 
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

- hardhat require you to have `contracts` folder available in the root project so make sure that .sol files are in the folder.

- to launch an ethereum test chain open a terminal in the same directory and run `npx hardhat node`

- to connect the flutter web app to use the test chain open another terminal and `flutter run web -d chrome` or `flutter run -d web-server`

- to deploy a smart contract run it script with `npx hardhat run --network localhost scripts/deploy.js` you may need to compile before with `npx hardhat compile`
