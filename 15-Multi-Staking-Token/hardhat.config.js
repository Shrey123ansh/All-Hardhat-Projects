// require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-waffle");
// // The next line is part of the sample project, you don't need it in your
// // project. It imports a Hardhat task definition, that can be used for
// // testing the frontend.
// require("./tasks/faucet");
// const GOERLI_PRIVATE_KEY = "7dbe1c7ed2cabc47bc0691050be444d353f04e7ebc9ab5ac3d75524d3305782d";
// const ALCHEMY_API_KEY = "https://eth-goerli.g.alchemy.com/v2/vcZNmU14W9KF-BWoQpu2Bnncni4MPADV";

// /** @type import('hardhat/config').HardhatUserConfig */
// module.exports = {
//   solidity: "0.8.17",
//   networks: {
//     // hardhat: {
//     //   chainId: 1337 // We set 1337 to make interacting with MetaMask simpler
//     // }
//     goerli: {
//       url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
//       accounts: [GOERLI_PRIVATE_KEY]
//     }
//   }
// };

require("@nomiclabs/hardhat-waffle");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.0",
  },
  paths: {
    artifacts: "./client/src/artifacts",
  }
};
