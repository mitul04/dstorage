import { network } from "hardhat";
import * as fs from "fs"; // Import file system

async function main() {
  console.log("Initiating connection...");
  const conn = await network.connect("localhost");
  const { ethers } = conn as any;

  if (!ethers) throw new Error("CRITICAL: 'ethers' object is missing.");

  // 1. Deploy RewardToken
  console.log("Deploying RewardToken...");
  const token = await ethers.deployContract("RewardToken");
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();

  // 2. Deploy StorageNodeRegistry
  console.log("Deploying StorageNodeRegistry...");
  const nodeRegistry = await ethers.deployContract("StorageNodeRegistry", [tokenAddress]);
  await nodeRegistry.waitForDeployment();
  const nodeRegistryAddress = await nodeRegistry.getAddress();

  // 3. Deploy FileRegistry
  console.log("Deploying FileRegistry...");
  const fileRegistry = await ethers.deployContract("FileRegistry");
  await fileRegistry.waitForDeployment();
  const fileRegistryAddress = await fileRegistry.getAddress();

  console.log("Deployment successful!");

  // --- 4. SAVE TO FILE (The Magic Part) ---
  const addresses = {
    rewardToken: tokenAddress,
    storageNodeRegistry: nodeRegistryAddress,
    fileRegistry: fileRegistryAddress,
  };

  // Write to 'deployed-addresses.json' in the root folder
  fs.writeFileSync("deployed-addresses.json", JSON.stringify(addresses, null, 2));
  console.log("✅ Addresses saved to deployed-addresses.json");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});