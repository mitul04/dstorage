import { network } from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
  console.log("🤖 Storage Node Daemon starting...");

  // 1. Connect to Blockchain
  const conn = await network.connect("localhost");
  const { ethers } = conn as any;
  const [signer] = await ethers.getSigners();
  
  // 2. Load Addresses
  const deploymentPath = path.join(process.cwd(), "deployed-addresses.json");
  if (!fs.existsSync(deploymentPath)) {
    console.error("❌ Error: deployed-addresses.json not found.");
    process.exit(1);
  }
  const addresses = JSON.parse(fs.readFileSync(deploymentPath, "utf-8"));

  // 3. Connect to Contracts
  const storageRegistry = await ethers.getContractAt("StorageNodeRegistry", addresses.storageNodeRegistry, signer);
  const rewardToken = await ethers.getContractAt("RewardToken", addresses.rewardToken, signer);
  const fileRegistry = await ethers.getContractAt("FileRegistry", addresses.fileRegistry, signer);

  console.log(`👤 Operating as Node: ${signer.address}`);

  // 4. Connect to IPFS (The Safe Dynamic Way)
  console.log("🔌 Connecting to Local IPFS Node...");
  const { create } = await import("ipfs-http-client");
  const ipfs = create({ url: "http://127.0.0.1:5001" });

  // ---------------------------------------------------------
  // 5. THE BRAIN: Staking & Registration
  // ---------------------------------------------------------
  const stakeAmount = await storageRegistry.stakeAmount();
  const myProfile = await storageRegistry.nodes(signer.address);

  if (myProfile.isRegistered) {
    console.log("✅ Node is already registered. Resuming operations...");
  } else {
    console.log(`💰 Staking required: ${ethers.formatEther(stakeAmount)} STOR`);
    console.log("📝 Registering Node on-chain...");
    
    // Approve & Register
    const approveTx = await rewardToken.approve(addresses.storageNodeRegistry, stakeAmount);
    await approveTx.wait();
    
    const capacity250GB = 250 * 1024 * 1024 * 1024; 
    const registerTx = await storageRegistry.registerNode(
      "/ip4/127.0.0.1/tcp/4001", 
      capacity250GB,             
      false // isMobile = false
    );
    await registerTx.wait();
    console.log("✅ Registration Successful!");
  }

  // 6. THE PULSE: Heartbeat Loop
  console.log("❤️ Starting Heartbeat Service (1 Hour Interval)...");
  // Send one immediately to prove it works
  try {
     const tx = await storageRegistry.ping();
     await tx.wait();
     console.log("   ✅ Initial Heartbeat sent!");
  } catch(e) { console.log("   ⚠️ Heartbeat skipped (check gas/status)"); }

  setInterval(async () => {
    try {
      console.log("   ... Pinging Registry (I am alive)");
      const tx = await storageRegistry.ping();
      await tx.wait();
    } catch (e) {
      console.error("   ❌ Heartbeat Failed:", e);
    }
  }, 60 * 60 * 1000); 

  // ---------------------------------------------------------
  // 7. THE MUSCLE: Event Listener (Correct Arguments)
  // ---------------------------------------------------------
  console.log(`👀 Watching FileRegistry at: ${addresses.fileRegistry}`);
  
  // New Signature: (cid, fileName, owner)
  fileRegistry.on("FileRegistered", async (cid, fileName, owner) => {
      console.log("---------------------------------------------------");
      console.log(`🔔 EVENT DETECTED: New File Registered!`);
      console.log(`   📂 Name: ${fileName}`); // We can now see the name!
      console.log(`   📝 CID:  ${cid}`);

      console.log("   ⬇️  Pinning file from IPFS network...");
      try {
          await ipfs.pin.add(cid);
          console.log(`   ✅ File successfully PINNED to local storage!`);
          
          // Future: Call storageRegistry.updateCapacity() here
      } catch (err) {
          console.error("   ❌ Failed to pin file.");
      }
  });

  // Keep process alive
  await new Promise(() => {});
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});