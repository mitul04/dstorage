import { network } from "hardhat";
import * as fs from "fs";
import * as path from "path"; // Added path for robust file handling

async function main() {
  console.log("📡 Connecting to local network...");

  // 1. Connect to Blockchain (Your preserved logic)
  const conn = await network.connect("localhost");
  const { ethers } = conn as any;
  const [deployer] = await ethers.getSigners();

  // 2. Load Addresses from the JSON file
  // Using process.cwd() is safer for finding the file across different shells
  const deployPath = path.join(process.cwd(), "deployed-addresses.json");
  if (!fs.existsSync(deployPath)) {
    throw new Error("❌ Error: deployed-addresses.json not found.");
  }
  const data = fs.readFileSync(deployPath, "utf8");
  const addresses = JSON.parse(data);
  const FILE_REGISTRY_ADDR = addresses.fileRegistry;

  const fileRegistry = await ethers.getContractAt("FileRegistry", FILE_REGISTRY_ADDR);

  // 3. Connect to IPFS
  console.log("🔌 Connecting to IPFS Node...");
  const { create } = await import("ipfs-http-client");
  // NOTE: If you found port 5002 earlier, change this line!
  const ipfs = create({ url: "http://127.0.0.1:5001" });

  // 4. Create and Upload a Real File
  console.log("\n📄 Generating test file...");
  const content = `Hello Decentralized World! Timestamp: ${Date.now()}`;
  
  // Define Metadata (REQUIRED by new Contract)
  const fileName = "smart_test.txt";
  const fileType = "text/plain";
  
  console.log("⬆️  Uploading raw data to IPFS...");
  const result = await ipfs.add(content);
  
  const realCid = result.path;
  const fileSize = result.size; // Capture the size automatically

  console.log(`   ✅ Uploaded to IPFS!`);
  console.log(`   📝 CID:  ${realCid}`);
  console.log(`   📊 Size: ${fileSize} bytes`);

  // 5. Register on Blockchain
  // New Signature: (cid, fileName, fileType, fileSize, hosts)
  const hosts = [deployer.address]; 

  console.log("\n1️⃣  Registering CID on Blockchain...");
  const tx = await fileRegistry.registerFile(
    realCid, 
    fileName, 
    fileType, 
    fileSize, 
    hosts
  );
  await tx.wait();
  console.log(`   ✅ Transaction confirmed: ${tx.hash}`);

  // 6. Verify Metadata
  console.log("\n2️⃣  Verifying Metadata...");
  const fileData = await fileRegistry.getFile(realCid);

  console.log("   --- On-Chain Data ---");
  console.log(`   CID:   ${fileData.cid}`);
  console.log(`   Name:  ${fileData.fileName}`);
  console.log(`   Type:  ${fileData.fileType}`);
  console.log(`   Size:  ${fileData.fileSize}`);
  console.log(`   Hosts: ${fileData.hosts}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});