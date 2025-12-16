import { network } from "hardhat";
import * as fs from "fs";
import path from "path";

async function main() {
  console.log("👻 Starting Network Simulation: Populating Ghost Nodes...");

  // 1. Connect and Load Signers
  const conn = await network.connect("localhost");
  const { ethers } = conn as any;
  const allSigners = await ethers.getSigners();
  
  // Separate the "Boss" (Account 0) from the "Ghosts" (Accounts 1-19)
  const [deployer, ...ghosts] = allSigners;

  // 2. Load Addresses
  const deployPath = path.join(process.cwd(), "deployed-addresses.json");
  if (!fs.existsSync(deployPath)) throw new Error("❌ Error: deployed-addresses.json not found.");
  const addresses = JSON.parse(fs.readFileSync(deployPath, "utf8"));

  // 3. Connect to Contracts (As the Deployer first)
  const token = await ethers.getContractAt("RewardToken", addresses.rewardToken, deployer);
  const registry = await ethers.getContractAt("StorageNodeRegistry", addresses.storageNodeRegistry, deployer);

  const stakeAmount = await registry.stakeAmount(); // 500 STOR

  console.log(`\n💰 Distributing Stimulus Packages (Funding ${ghosts.length} nodes)...`);

  // 4. The "Ghost" Loop
  for (let i = 0; i < ghosts.length; i++) {
    const ghost = ghosts[i];
    const ghostIp = `/ip4/192.168.0.${100 + i}/tcp/4001`; // Fake IP
    const isMobile = i % 3 === 0; // Every 3rd node is mobile
    
    // Randomize Capacity between 100GB and 1TB
    const randomGB = Math.floor(Math.random() * (1000 - 100 + 1) + 100);
    const capacityBytes = BigInt(randomGB) * BigInt(1024 ** 3);

    console.log(`   [Node ${i + 1}] Processing ${ghost.address.slice(0, 6)}...`);

    try {
      // A. Check if already registered
      const profile = await registry.nodes(ghost.address);
      if (profile.isRegistered) {
        console.log(`      ⚠️ Already registered. Skipping.`);
        continue;
      }

      // B. FUND THE GHOST (Transfer 500 STOR from Deployer -> Ghost)
      // Note: We check balance first to save gas, though on localhost gas is free.
      const ghostBalance = await token.balanceOf(ghost.address);
      if (ghostBalance < stakeAmount) {
          const fundTx = await token.transfer(ghost.address, stakeAmount);
          await fundTx.wait();
          console.log("      💸 Funded 500 STOR");
      }

      // C. SWITCH IDENTITY (Connect contract as the Ghost)
      const tokenAsGhost = token.connect(ghost);
      const registryAsGhost = registry.connect(ghost);

      // D. APPROVE
      const approveTx = await tokenAsGhost.approve(addresses.storageNodeRegistry, stakeAmount);
      await approveTx.wait();

      // E. REGISTER
      const regTx = await registryAsGhost.registerNode(ghostIp, capacityBytes, isMobile);
      await regTx.wait();
      
      console.log(`      ✅ Registered: ${randomGB}GB | Mobile: ${isMobile}`);

    } catch (err) {
      console.error(`      ❌ Failed: ${err}`);
    }
  }

  console.log("\n🎉 Simulation Complete! Run 'administer.ts' to see the network.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});