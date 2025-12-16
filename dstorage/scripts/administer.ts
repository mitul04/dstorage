import { network } from "hardhat";
import * as fs from "fs";
import path from "path";

async function main() {
  console.log("🌐 Connecting to Network Administration Console...");

  // 1. Connect as Admin
  const conn = await network.connect("localhost");
  const { ethers } = conn as any; 
  const [admin] = await ethers.getSigners();

  // 2. Load Addresses
  const deployPath = path.join(process.cwd(), "deployed-addresses.json");
  if (!fs.existsSync(deployPath)) {
    throw new Error("❌ Error: deployed-addresses.json not found.");
  }
  const addresses = JSON.parse(fs.readFileSync(deployPath, "utf8"));
  
  // 3. Connect to Registry
  const registry = await ethers.getContractAt("StorageNodeRegistry", addresses.storageNodeRegistry, admin);

  // 4. Get the List of All Nodes
  console.log("📥 Fetching node list from blockchain...");
  const allNodeAddresses = await registry.getAllNodes();
  
  console.log(`\nFound ${allNodeAddresses.length} Registered Nodes`);
  console.log("========================================================================================");
  console.log("IP ADDRESS           | CAPACITY (Free/Total) | REP | STATUS     | LAST SEEN");
  console.log("----------------------------------------------------------------------------------------");

  let totalNetworkStorage = 0;

  // 5. Loop through every node
  for (const nodeAddr of allNodeAddresses) {
      const profile = await registry.nodes(nodeAddr);

      // A. Calculate Storage
      const freeGB = Number(profile.freeCapacity) / (1024 ** 3);
      const totalGB = Number(profile.totalCapacity) / (1024 ** 3);
      totalNetworkStorage += totalGB;

      // B. Check Health (Threshold: 1 hour)
      const lastSeenSeconds = Number(profile.lastHeartbeat);
      const now = Math.floor(Date.now() / 1000);
      const timeDiff = now - lastSeenSeconds;
      
      let status = "🔴 DEAD";
      if (timeDiff < 3600) status = "🟢 ONLINE";       // < 1 hour
      else if (timeDiff < 86400) status = "⚠️ WARNING"; // < 24 hours

      // C. Format Time
      const dateStr = new Date(lastSeenSeconds * 1000).toLocaleTimeString();

      // D. Format Columns
      const ip = profile.ipAddress.padEnd(20);
      const cap = `${freeGB.toFixed(0)}/${totalGB.toFixed(0)} GB`.padEnd(21);
      const rep = `${profile.reputation}`.padEnd(3);
      const stat = status.padEnd(10);
      
      console.log(`${ip} | ${cap} | ${rep} | ${stat} | ${dateStr}`);
  }

  console.log("========================================================================================");
  console.log(`🌍 TOTAL NETWORK CAPACITY: ${totalNetworkStorage.toFixed(2)} GB`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});