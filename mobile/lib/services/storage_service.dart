import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class StorageService {
  
  // 1. Get the dedicated cache folder
  Future<String> _getDownloadPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${directory.path}/ipfs_cache');
    
    // Create if it doesn't exist
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  // Helper: Construct a filename that includes the CID (uniqueness) and Extension (usability)
  String _getLocalFileName(String cid, String originalFileName) {
    // If original name is "photo.jpg", we save as "QmHash...jpg"
    // If no extension, just use CID
    if (!originalFileName.contains('.')) return cid;
    
    final ext = originalFileName.split('.').last;
    return '$cid.$ext';
  }

  // 2. CHECK: Do we already have this file? (Light Node Behavior)
  Future<File?> getCachedFile(String cid, String originalFileName) async {
    final dirPath = await _getDownloadPath();
    final localName = _getLocalFileName(cid, originalFileName);
    final file = File('$dirPath/$localName');
    
    if (await file.exists()) {
      print("✅ Cache Hit: Found $localName locally.");
      return file;
    }
    return null;
  }

  // 3. DOWNLOAD: Fetch from the Network (Your Laptop Node)
  Future<File?> downloadFile(String cid, String fileName, String gatewayUrl) async {
    try {
      print("⬇️ Cache Miss. Downloading $cid from Gateway...");
      
      // We call the retrieve endpoint on your Node
      final url = Uri.parse('$gatewayUrl/retrieve/$cid'); 
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dirPath = await _getDownloadPath();
        final localName = _getLocalFileName(cid, fileName);
        final file = File('$dirPath/$localName'); 
        
        await file.writeAsBytes(response.bodyBytes);
        print("💾 Saved to Mobile Storage: ${file.path}");
        
        return file;
      } else {
        print("❌ Download Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error downloading: $e");
      return null;
    }
  }

  // 4. ACTION: View the file
  Future<void> openFile(File file) async {
    // OpenFilex uses the extension to determine the app
    final result = await OpenFilex.open(file.path);
    print("📂 Opening File Result: ${result.type} - ${result.message}");
  }
}