import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

class BlockchainService {
  // Android Emulator -> Physical device
  static const String _baseIp = "192.168.31.48"; // run `ipconfig` to find your local IP

  final String _rpcUrl = "http://$_baseIp:9545"; 
  final String _wsUrl = "ws://$_baseIp:9545"; 

  // Storage Server URL (Port 3000)
  final String _storageUrl = "http://$_baseIp:3000/upload";

  // Account #1 Private Key (Pre-funded with ETH & STOR from our scripts)
  final String _privateKey = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";

  late Web3Client _client;
  late Credentials _credentials;
  late EthereumAddress _ownAddress;
  late DeployedContract _contract;

  Future<void> init() async {
    _client = Web3Client(_rpcUrl, http.Client());
    _credentials = EthPrivateKey.fromHex(_privateKey);
    _ownAddress = await _credentials.extractAddress();
    print("📱 Wallet Connected: $_ownAddress");
    await _loadContract();
  }

  Future<void> _loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; // Use the FileRegistry address from your Daemon logs!

    _contract = DeployedContract(
      ContractAbi.fromJson(abi, "FileRegistry"),
      EthereumAddress.fromHex(contractAddress),
    );
  }

  Future<String> getBalance() async {
    EtherAmount balance = await _client.getBalance(_ownAddress);
    return balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(6);
  }

  Future<String?> uploadFileToStorage(String filePath, String fileName) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_storageUrl));
      request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

      print("📤 Uploading $fileName to $_storageUrl...");
      var response = await request.send();

      if (response.statusCode == 200) {
        var cid = await response.stream.bytesToString();
        print("✅ Storage Success! CID: $cid");
        return cid;
      } else {
        print("❌ Storage Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error uploading: $e");
      return null;
    }
  }

  // 2. Save Record to Blockchain
  Future<void> storeFileOnChain(String fileName, String cid, int fileSize) async {
    try {
      print("🔗 Writing to Blockchain...");
      final function = _contract.function('registerFile'); 
      
      await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [
            cid,                    // 1. _cid
            fileName,               // 2. _fileName
            "unknown",              // 3. _fileType (We'll just use a placeholder for now)
            BigInt.from(fileSize),  // 4. _fileSize
            <EthereumAddress>[]     // 5. _hosts (Empty list - nodes will pick it up later)
          ],
        ),
        chainId: 31337,
      );
      print("🎉 Blockchain Transaction Complete!");
    } catch (e) {
      print("❌ Blockchain Error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserFiles() async {
    try {
      final function = _contract.function('getMyFiles');
      
      // Call the function (READ only, so no gas fees)
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [],
        sender: _ownAddress,
      );

      // The result is a List containing one item: the List of Files.
      // Structure: [[ [file1_data], [file2_data] ]]
      List<dynamic> rawFiles = result[0];

      return rawFiles.map((fileData) {
        return {
          'owner': fileData[0].toString(),
          'cid': fileData[1].toString(),
          'fileName': fileData[2].toString(),
          'fileType': fileData[3].toString(),
          // fileData[4] is hosts (skipped for now)
          'fileSize': fileData[5].toString(),
          'timestamp': fileData[6].toString(),
        };
      }).toList();
      
    } catch (e) {
      print("❌ Error fetching files: $e");
      return [];
    }
  }
}

