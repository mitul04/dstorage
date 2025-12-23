import 'dart:io'; // Needed for File type
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../services/blockchain_service.dart';
import '../services/encryption_service.dart';
import '../services/storage_service.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final BlockchainService _service = BlockchainService();
  final EncryptionService _encryptionService = EncryptionService();
  final StorageService _storageService = StorageService(); // 👈 Init Storage Service

  String? _gatewayUrl;
  
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();  
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    // 2. Load Config FIRST to get the Gateway IP
    try {
      final String configString = await rootBundle.loadString('assets/app_config.json');
      final Map<String, dynamic> config = jsonDecode(configString);
      
      // We assume your Node is running on Port 3000 on the same IP as the server
      if (config.containsKey('serverIp')) {
        setState(() {
          _gatewayUrl = "http://${config['serverIp']}:3000";
        });
        print("🌍 Gateway Configured: $_gatewayUrl");
      }
    } catch (e) {
      print("❌ Config Load Error: $e");
    }

    // 1. Load Cache
    final cached = await _service.getCachedFiles();
    _sortFiles(cached);
    
    if (mounted) {
      setState(() {
        _files = cached;
        if (_files.isNotEmpty) _isLoading = false; 
      });
    }

    // 2. Load Network
    await _service.init();
    final fresh = await _service.fetchUserFiles();
    _sortFiles(fresh);

    if (mounted) {
      setState(() {
        _files = fresh;
        _isLoading = false;
      });
    }
  }

  void _sortFiles(List<Map<String, dynamic>> fileList) {
    fileList.sort((a, b) {
       int timeA = int.tryParse(a['timestamp']) ?? 0;
       int timeB = int.tryParse(b['timestamp']) ?? 0;
       return timeB.compareTo(timeA); 
    });
  }

  void _refresh() {
    setState(() => _isLoading = true);
    _initAndLoad();
  }

  String _formatSize(String sizeStr) {
    int bytes = int.tryParse(sizeStr) ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String timestamp) {
    if (timestamp == "0") return "Unknown";
    var dt = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
    String hour = dt.hour.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    return "${dt.day}/${dt.month}/${dt.year} at $hour:$minute";
  }

  // --- ACTION: Show Full Details (Updated with Download) ---
  void _showFileDetails(Map<String, dynamic> file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<dynamic> hosts = file['hosts'] ?? [];
        String targetRep = file['targetReplication'].toString();
        String cid = file['cid'];
        String fileName = file['fileName'];

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, color: Colors.grey[300])),
              const SizedBox(height: 20),
              
              // Filename
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  fileName, 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              
              // CID Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("IPFS CID", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                          Text(cid, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: cid));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CID Copied!")));
                      },
                    )
                  ],
                ),
              ),
              
              // Decryption Key Box (Hidden if not encrypted)
              FutureBuilder<String?>(
                future: _encryptionService.getKeyForCid(cid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
                  final String key = snapshot.data!;
                  return Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3))
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.vpn_key, size: 12, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text("AES-256 DECRYPTION KEY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(key, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20, color: Colors.deepOrange),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: key));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Secret Key Copied!")));
                          },
                        )
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Network Status
              Text("Network Status (${hosts.length}/$targetRep Nodes)", 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
              const SizedBox(height: 8),
              
              hosts.isEmpty 
                  ? const Text("⚠️ No active hosts reported.", style: TextStyle(color: Colors.orange))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: hosts.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.computer, color: Colors.green),
                          title: Text("Node ${index + 1}", style: const TextStyle(fontSize: 12)),
                          subtitle: Text(hosts[index].toString(), style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                        );
                      },
                    ),

              const SizedBox(height: 20),
              
              // 🔽 DOWNLOAD & VIEW BUTTON (Connects to StorageService)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 1. Check if we already have it (Cache)
                    File? file = await _storageService.getCachedFile(cid, fileName);

                    if (file == null) {
                       // 2. If not, Download from Network
                       Navigator.pop(context); // Close sheet to show snackbar clearly
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text("⬇️ Cache miss. Downloading from decentralized network..."), duration: Duration(seconds: 1))
                       );
                       
                       // Perform Download
                       file = await _storageService.downloadFile(cid, fileName, _gatewayUrl!);
                    }

                    // 3. Open File
                    if (file != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("✅ File Ready: ${file.path.split('/').last}"))
                      );
                      await _storageService.openFile(file);
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text("❌ Failed to retrieve file from Gateway."))
                       );
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text("Download & View"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF), 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                ),
              ),
              // 🔼 END BUTTON

              const SizedBox(height: 10),
              
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Keep existing build method exactly as it was) ...
    // Copying the build method from your provided code to ensure completeness
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cloud", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading && _files.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _files.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("No files yet. Upload one!"),
                    TextButton(onPressed: _refresh, child: const Text("Refresh"))
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _initAndLoad,
                color: const Color(0xFF6C63FF),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final List hosts = file['hosts'] ?? [];
                    final String targetRep = (file['targetReplication'] ?? "1").toString();
                    final int targetRepInt = int.tryParse(targetRep) ?? 1;
                    
                    final String imageUrl = "https://ipfs.io/ipfs/${file['cid']}";
                    final bool isImage = file['fileName'].toString().toLowerCase().endsWith('jpg') || 
                                         file['fileName'].toString().toLowerCase().endsWith('png') ||
                                         file['fileName'].toString().toLowerCase().endsWith('jpeg');

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _showFileDetails(file),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                                child: isImage
                                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.broken_image, color: Colors.grey)))
                                  : const Icon(Icons.insert_drive_file, color: Color(0xFF6C63FF), size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(file['fileName'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text("${_formatSize(file['fileSize'])} • ${_formatDate(file['timestamp'])}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: hosts.length >= targetRepInt ? Colors.green[50] : Colors.orange[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: hosts.length >= targetRepInt ? Colors.green : Colors.orange, width: 0.5)
                                        ),
                                        child: Row(children: [
                                          Icon(Icons.cloud_done, size: 12, color: hosts.length >= targetRepInt ? Colors.green : Colors.orange),
                                          const SizedBox(width: 4),
                                          Text("${hosts.length}/$targetRep Nodes", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hosts.length >= targetRepInt ? Colors.green : Colors.orange)),
                                        ]),
                                      ),
                                    ]),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) { if (value == 'details') _showFileDetails(file); },
                                itemBuilder: (BuildContext context) {
                                  return [ const PopupMenuItem(value: 'details', child: Text('View Details')), const PopupMenuItem(value: 'share', child: Text('Share Link')) ];
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}