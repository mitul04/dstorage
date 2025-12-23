import { network } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import { create } from "ipfs-http-client";
import axios from "axios"; 
import FormData from "form-data";

async function main() {
  console.log("💻 STARTING LAPTOP UPLOAD & SHARE...");

  // --- CONFIG ---
  // 🚨 REPLACE THIS WITH YOUR MOBILE WALLET ADDRESS!
  const MOBILE_ADDRESS = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"; 
  
  // 0. Create dummy file if not exists
  const fileName = "laptop_shared_file.txt";
  const filePath = path.join(process.cwd(), fileName);
  
  // 0. Generate a FRESH file with current timestamp
  const now = new Date();
  const timestamp = now.toLocaleString();
  
  const fileContent = `
  =========================================
  📂 SECURE FILE TRANSFER
  =========================================
  📅 Date: ${now.toDateString()}
  ⏰ Time: ${now.toTimeString()}
  
  💻 Source: Laptop Node (Hardhat)
  📱 Destination: Mobile App
  =========================================
  `;
  
  fs.writeFileSync(filePath, fileContent);
  console.log(`📄 Generated fresh file: ${fileName} (Time: ${timestamp})`);

  // 1. Connect to Blockchain (As Laptop/Deployer)
  const conn = await network.connect("localhost");
  const { ethers } = conn as any;
  const [deployer] = await ethers.getSigners(); 

  const deployPath = path.join(process.cwd(), "deployed-addresses.json");
  const addresses = JSON.parse(fs.readFileSync(deployPath, "utf8"));
  
  const fileRegistry = await ethers.getContractAt("FileRegistry", addresses.fileRegistry, deployer);
  const nodeRegistry = await ethers.getContractAt("StorageNodeRegistry", addresses.storageNodeRegistry, deployer);

  // 2. Find Storage Node (Laptop)
  const nodes = await nodeRegistry.getAllNodes();
  if (nodes.length === 0) { console.error("❌ No nodes found. Run upload-server.ts"); return; }
  const storageNode = nodes[0];

  // 3. Upload to Storage Node (via HTTP to Port 3000)
  console.log("⬆️  Uploading to Storage Node...");
  const form = new FormData();
  form.append("file", fs.createReadStream(filePath));
  
  const response = await axios.post("http://localhost:3000/upload", form, { headers: form.getHeaders() });
  const cid = response.data;
  const fileSize = fs.statSync(filePath).size;
  console.log(`   ✅ CID: ${cid}`);

  // 4. Register on Blockchain (Owner = Laptop)
  console.log("📝 Registering File (Owner: Laptop)...");
  const tx1 = await fileRegistry.registerFile(cid, fileName, "text/plain", fileSize, [storageNode], 1);
  await tx1.wait();

  // 5. SHARE with Mobile
  console.log(`🎁 Sharing with Mobile (${MOBILE_ADDRESS})...`);
  const tx2 = await fileRegistry.shareFile(cid, MOBILE_ADDRESS);
  await tx2.wait();

  console.log("🎉 DONE! Check the 'Received' tab on your mobile app.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});