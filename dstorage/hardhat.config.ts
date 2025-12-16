import { defineConfig } from "hardhat/config";
import hardhatEthers from "@nomicfoundation/hardhat-ethers";

export default defineConfig({
  plugins: [hardhatEthers],
  solidity: {
    version: "0.8.28",
  },
  networks: {
    // ⚠️ CRITICAL UPDATE: Change this to 9545
    // need to run 'npx hardhat node --port 9545'
    localhost: {
      url: "http://127.0.0.1:9545",
    },
  },
});
