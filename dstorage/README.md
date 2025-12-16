# dStorage: Decentralized Cloud Storage Network

A Proof-of-Concept decentralized storage network that combines **IPFS** for physical storage with **Ethereum Smart Contracts** for identity, access control, and incentivization.

## 🚀 Project Overview

This system simulates a distributed cloud storage market on a local machine.
* **Storage Nodes:** Autonomous daemons that stake tokens, register on-chain, and pin files automatically.
* **Smart Registry:** Manages node reputation, heartbeats, and file metadata (CID, size, type).
* **Admin Dashboard:** Tools to visualize network health and simulate scale (20+ nodes).

## 🛠️ Tech Stack & Versions

* **Framework:** Hardhat v3 (Beta)
* **Blockchain Interaction:** Ethers.js v6
* **Storage Layer:** IPFS (InterPlanetary File System)
* **Language:** TypeScript / Solidity 0.8.20

## ⚡ Quick Start

1.  **Start the Blockchain:**
    ```bash
    npx hardhat node --port 9545 # port unavailability issue for 8545 
    ```

2.  **Deploy Contracts:**
    ```bash
    npx hardhat run scripts/deploy.ts --network localhost
    ```

3.  **Run a Storage Node (Daemon):**
    ```bash
    npx hardhat run scripts/daemon.ts --network localhost
    ```

4.  **Upload a File:**
    ```bash
    npx hardhat run scripts/upload.ts --network localhost
    ```

5.  **Monitor Network:**
    ```bash
    npx hardhat run scripts/administer.ts --network localhost
    ```