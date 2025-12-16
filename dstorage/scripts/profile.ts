import { network } from "hardhat";
import * as fs from "fs";
import path from "path";

async function main() {
  console.log("🕵️‍♀️ Blockchain Node Inspector starting...\n");

  // 1. Connect
  const conn = await network.connect("localhost");
  const { ethers } = conn as any; 
  const [inquirer] = await ethers.getSigners();
  
  // 2. Load Addresses
  const deployPath = path.join(process.cwd(), "deployed-addresses.json");
  if (!fs.existsSync(deployPath)) {
    throw new Error("❌ Error: deployed-addresses.json not found.");
  }
  const addresses = JSON.parse(fs.readFileSync(deployPath, "utf8"));
  
  // 3. Connect to Registry
  const registry = await ethers.getContractAt("StorageNodeRegistry", addresses.storageNodeRegistry, inquirer);
  const rewardToken = await ethers.getContractAt("RewardToken", addresses.rewardToken, inquirer);

  console.log(`🔎 Inspecting Node: ${inquirer.address}`);

  // 4. READ DATA (The "What do you know?" Step)
  // We access the public mapping 'nodes'
  const profile = await registry.nodes(inquirer.address);
  const balance = await rewardToken.balanceOf(inquirer.address);

  // 5. Display Dashboard
  console.log("---------------------------------------------------");
  console.log("📊 ON-CHAIN PROFILE");
  console.log("---------------------------------------------------");
  
  if (profile.isRegistered) {
      console.log(`✅ Status:       REGISTERED`);
      console.log(`📡 IP Address:   ${profile.ipAddress}`);
      
      // Convert bytes to GB for display
      const totalGB = Number(profile.totalCapacity) / (1024 ** 3);
      const freeGB = Number(profile.freeCapacity) / (1024 ** 3);
      
      console.log(`💾 Capacity:     ${freeGB.toFixed(2)} GB Free / ${totalGB.toFixed(2)} GB Total`);
      console.log(`⭐ Reputation:   ${profile.reputation} / 100`);
      console.log(`📱 Device Type:  ${profile.isMobile ? "Mobile (Tier 2)" : "Desktop (Tier 1)"}`);
      
      // Convert timestamp to readable date
      const date = new Date(Number(profile.lastHeartbeat) * 1000);
      console.log(`❤️ Last Pulse:   ${date.toLocaleTimeString()}`);
      
  } else {
      console.log("❌ Status:       NOT REGISTERED");
      console.log("   (Run daemon.ts to register automatically)");
  }

  console.log("---------------------------------------------------");
  console.log(`💰 Wallet:       ${ethers.formatEther(balance)} STOR`);
  console.log("---------------------------------------------------");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});