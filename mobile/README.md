# 📱 D-Storage Mobile Client

A Flutter-based Android application tailored for the Decentralized Cloud Storage project. This app serves as the user interface for uploading files to IPFS and registering ownership on a local Ethereum blockchain.

## ✨ Features
* **Decentralized Identity:** Connects to the blockchain using a local wallet private key.
* **File Upload:** Seamlessly sends files to a local Node.js relay server for IPFS pinning.
* **Blockchain Registry:** automatically signs transactions to register file CIDs on the Smart Contract.
* **My Files:** Fetches and displays the user's personal file history directly from the blockchain.
* **Real-time Balance:** Displays the user's ETH balance with 4-decimal precision.

## 🛠 Tech Stack
* **Framework:** Flutter (Dart)
* **Blockchain Interaction:** `web3dart` & `http`
* **Target Platform:** Android (Physical Device recommended)

## 🚀 Prerequisites
Before running this app, ensure your backend infrastructure is running:
1.  **Hardhat Node** (Port 8545/9545)
2.  **Upload Server** (`upload_server.ts` on Port 3000)
3.  **Daemon/Watcher** (`daemon.ts` for pinning)

## ⚙️ Configuration

### 1. Smart Contract ABI
Ensure the contract ABI is present in `assets/abi.json`.
* **Source:** Copy the ABI array from your backend artifact (`artifacts/contracts/FileRegistry.sol/FileRegistry.json`).
* **Location:** `mobile/assets/abi.json`

### 2. Network & Contract Settings
Open `lib/services/blockchain_service.dart` and update the following static variables to match your local environment:

```dart
class BlockchainService {
  // Your PC's Local IP Address (Run 'ipconfig' on Windows)
  static const String _baseIp = "192.168.31.XX"; 
  
  // The deployed address of the 'FileRegistry' contract
  // (Check the output of your 'deploy.ts' script)
  String contractAddress = "0x..."; 
  
  // Account Private Key (From Hardhat Account #0 or #1)
  final String _privateKey = "0x...";
}
```

## 📦 Installation & Run

**Install Dependencies:**
```bash
flutter pub get
```

**Connect Device:**

* **Recommended:** Use Wireless Debugging (adb tcpip 5555 then adb connect IP_ADDRESS).
* **Alternative:** USB Cable.

**Run the App:**
```bash
flutter run
```

## 🐛 Troubleshooting
### 1. "Connection Timed Out" / "SocketException"
* **Cause:** Windows Firewall is blocking the phone from talking to the laptop.

* **Fix:** Ensure your PC's Network Profile is set to Private (Settings > Network & Internet > Wi-Fi > Properties).

* **Alternative:** Create an Inbound Firewall Rule allowing traffic on ports 3000 and 9545.

### 2. "Internal Error -32603" during Upload
* **Cause:** The app is likely trying to call registerFile on the wrong contract address (e.g., the Token contract instead of the FileRegistry).

* **Fix:** Update contractAddress in blockchain_service.dart with the correct address from your Daemon logs.

### 3. "ADB Device Offline"
* **Cause:** Loose USB cable or unstable connection.

* **Fix:** Switch to Wireless Debugging.

```bash
adb kill-server
adb connect <PHONE_IP>
```

## 📂 Project Structure

* **lib/screens/:** UI pages (Home, Upload, Files).
* **lib/services/:** Logic for Blockchain and HTTP interactions.
* **assets/:** JSON definitions for Smart Contracts.