import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/blockchain_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final BlockchainService _service = BlockchainService();
  
  // File State
  String? _fileName;
  PlatformFile? _pickedFile; 
  bool _isUploading = false;
  double _replicationValue = 2.0; // Default to 2 copies

  // Node Selection State
  List<Map<String, dynamic>> _nodes = [];
  Map<String, dynamic>? _selectedNode;
  bool _isLoadingNodes = true;

  @override
  void initState() {
    super.initState();
    _loadNodes();
  }

  // 1. Fetch available nodes from Blockchain
  Future<void> _loadNodes() async {
    await _service.init();
    final nodes = await _service.getAvailableNodes();
    
    if (mounted) {
      setState(() {
        _nodes = nodes;
        _isLoadingNodes = false;
        // Auto-select the first node if available
        if (nodes.isNotEmpty) {
          _selectedNode = nodes[0];
        }
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_pickedFile == null || _selectedNode == null) return;

    setState(() => _isUploading = true);

    try {
      // 2. Construct the specific URL based on User Choice
      final targetIp = _selectedNode!['ip'];
      final targetAddress = _selectedNode!['address'];
      final targetUrl = "$targetIp/upload";
      
      // 3. Upload to THAT specific node
      String? cid = await _service.uploadFileToSpecificNode(
        _pickedFile!.path!, 
        _pickedFile!.name,
        targetUrl
      );

      if (cid != null) {
        // 4. Save to Blockchain (The Protocol handles replication later)
        await _service.storeFileOnChain(
          _pickedFile!.name, 
          cid, 
          _pickedFile!.size,
          _replicationValue.toInt(),
          targetAddress
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Success! File Distributed."),
              backgroundColor: Colors.green,
            ),
          );
          // Reset UI
          setState(() {
            _pickedFile = null;
            _fileName = null;
          });
        }
      } else {
        throw Exception("Upload failed (Node rejected connection)");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    
    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upload File", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Select a node to host your data", 
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // --- 1. NODE SELECTOR DROPDOWN ---
          const Text("Storage Node", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
          const SizedBox(height: 8),
          _isLoadingNodes
              ? const LinearProgressIndicator(color: Color(0xFF6C63FF))
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: _selectedNode,
                      isExpanded: true,
                      hint: const Text("Select a Node"),
                      items: _nodes.map((node) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: node,
                          child: Row(
                            children: [
                              const Icon(Icons.dns, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text("Node ${node['address'].substring(0,6)}..."),
                              const Spacer(),
                              // Show "Reputation" or "IP"
                              Text(
                                "Rep: ${node['reputation']}", 
                                style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedNode = value);
                      },
                    ),
                  ),
                ),

          const SizedBox(height: 20),

          // --- 2. FILE PICKER AREA ---
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6C63FF),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _fileName == null ? Icons.cloud_upload_outlined : Icons.check_circle,
                    size: 50,
                    color: const Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _fileName ?? "Tap to select a file",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _fileName == null ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                  if (_pickedFile != null)
                    Text(
                      "${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // --- NEW: REPLICATION SLIDER ---
          const SizedBox(height: 20),
          const Text("Redundancy Level", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
          Row(
            children: [
              const Icon(Icons.copy_all, color: Colors.grey),
              Expanded(
                child: Slider(
                  value: _replicationValue,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: const Color(0xFF6C63FF),
                  label: "${_replicationValue.toInt()} Nodes",
                  onChanged: (value) {
                    setState(() => _replicationValue = value);
                  },
                ),
              ),
              Text(
                "${_replicationValue.toInt()} Copies", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ],
          ),
          const SizedBox(height: 10),

          // --- 3. UPLOAD BUTTON ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: (_fileName != null && !_isUploading && _selectedNode != null) 
                  ? _uploadFile 
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text("Secure Upload", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}