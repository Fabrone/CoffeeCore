import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:coffeecore/home.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class ManualsScreen extends StatefulWidget {
  const ManualsScreen({super.key});

  @override
  State<ManualsScreen> createState() => _ManualsScreenState();
}

class _ManualsScreenState extends State<ManualsScreen> {
  String? _selectedPdfPath;
  bool _isLoading = false;
  String? _downloadedFilePath;
  int _currentPage = 0;
  int _totalPages = 0;
  final Map<String, String> _cachedPdfs = {}; // Cache for downloaded PDFs

  static final Color coffeeBrown = Colors.brown[700]!; // CoffeeCore theme color

  @override
  void initState() {
    super.initState();
    _preloadPdfs(); // Preload PDFs for offline access
  }

  @override
  void dispose() {
    _cleanupTemporaryFiles();
    super.dispose();
  }

  // Clean up all temporary files
  void _cleanupTemporaryFiles() {
    _cachedPdfs.forEach((_, path) {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });
    _cachedPdfs.clear();
    if (_selectedPdfPath != null) {
      final file = File(_selectedPdfPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
      _selectedPdfPath = null;
    }
  }

  // Preload PDFs to cache for offline reading
  Future<void> _preloadPdfs() async {
    try {
      final manuals = await FirebaseFirestore.instance.collection('Manuals').get();
      for (var manual in manuals.docs) {
        final data = manual.data();
        final filename = data['filename'] as String;
        final url = await FirebaseStorage.instance.ref('manuals/$filename').getDownloadURL();
        await _cachePdf(url, filename);
      }
    } catch (e) {
      _showErrorSnackBar('Error preloading manuals: $e');
    }
  }

  // Cache a PDF locally
  Future<void> _cachePdf(String url, String filename) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      _cachedPdfs[filename] = file.path;
    } catch (e) {
      _showErrorSnackBar('Error caching $filename: $e');
    }
  }

  // Read PDF (use cached version if available)
  Future<void> _readOnline(String filename) async {
    setState(() => _isLoading = true);
    try {
      String? filePath = _cachedPdfs[filename];
      if (filePath != null && await File(filePath).exists()) {
        setState(() {
          _selectedPdfPath = filePath;
          _currentPage = 0;
        });
      } else {
        final url = await FirebaseStorage.instance.ref('manuals/$filename').getDownloadURL();
        final response = await http.get(Uri.parse(url));
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        setState(() {
          _selectedPdfPath = file.path;
          _cachedPdfs[filename] = file.path;
          _currentPage = 0;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading manual: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Download PDF to device storage
  Future<void> _downloadFile({required String filename}) async {
    setState(() => _isLoading = true);
    try {
      bool permissionGranted = await _requestStoragePermission();
      if (!permissionGranted) {
        _showErrorSnackBar('Storage permission denied. Cannot download file.');
        return;
      }

      Directory? downloadsDir;
      try {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } catch (e) {
        downloadsDir = await getExternalStorageDirectory();
        if (downloadsDir == null) {
          throw Exception('Unable to access Downloads directory');
        }
      }
      final targetFile = File('${downloadsDir.path}/$filename');

      String? localPath = _cachedPdfs[filename];
      if (localPath != null && await File(localPath).exists()) {
        await File(localPath).copy(targetFile.path);
      } else {
        final url = await FirebaseStorage.instance.ref('manuals/$filename').getDownloadURL();
        final response = await http.get(Uri.parse(url));
        final bytes = response.bodyBytes;
        await targetFile.writeAsBytes(bytes);
      }

      setState(() => _downloadedFilePath = targetFile.path);
      _showSuccessSnackBar('Manual downloaded to $_downloadedFilePath');
      _openDownloadedFile();
    } catch (e) {
      _showErrorSnackBar('Error downloading manual: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Request storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var sdkInt = await _getAndroidVersion();
      if (sdkInt < 33) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          PermissionStatus result = await Permission.storage.request();
          if (!mounted) return false;
          bool shouldProceed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Storage Permission Required'),
              content: Text(
                'This app needs storage access to save manuals to your Downloads folder. Permission status: ${result.isGranted ? 'Granted' : 'Denied'}. Proceed with download?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, result.isGranted),
                  child: const Text('Proceed'),
                ),
              ],
            ),
          ) ?? false;
          return shouldProceed;
        }
        return true;
      }
      // For Android 13+, use manageExternalStorage or rely on Downloads folder
      return true;
    }
    return true;
  }

  // Get Android version
  Future<int> _getAndroidVersion() async {
    try {
      var platform = Platform.operatingSystemVersion;
      var versionString = platform.split(' ')[1];
      return int.parse(versionString.split('.')[0]);
    } catch (e) {
      return 0;
    }
  }

  // Open downloaded file
  void _openDownloadedFile() {
    if (_downloadedFilePath != null) {
      OpenFile.open(_downloadedFilePath!);
    }
  }

  // Show error SnackBar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Show success SnackBar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage())),
        ),
        title: const Text('Coffee Farming Manuals', style: TextStyle(color: Colors.white)),
        backgroundColor: coffeeBrown,
        elevation: 2,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildWelcomeAnimation(),
                _buildManualsList(),
                if (_selectedPdfPath != null) _buildPdfViewer(),
              ],
            ),
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: coffeeBrown)),
        ],
      ),
    );
  }

  // Welcome animation
  Widget _buildWelcomeAnimation() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.brown[50],
      child: AnimatedTextKit(
        animatedTexts: [
          TyperAnimatedText(
            'Welcome to Coffee Farming Manuals!\nExplore expert-approved guides to enhance your coffee farming skills.',
            textStyle: TextStyle(fontSize: 18, color: coffeeBrown, fontWeight: FontWeight.bold),
            speed: const Duration(milliseconds: 50),
          ),
        ],
        totalRepeatCount: 1,
      ),
    );
  }

  // List manuals from Firestore
  Widget _buildManualsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Manuals').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final manuals = snapshot.data!.docs;
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: manuals.length,
            itemBuilder: (context, index) {
              final manual = manuals[index].data() as Map<String, dynamic>;
              final title = manual['title'] ?? 'Untitled';
              final filename = manual['filename'] ?? '';
              return ListTile(
                leading: Icon(Icons.book, color: coffeeBrown),
                title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Tap to read or download', style: TextStyle(color: Colors.grey[600])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility, color: coffeeBrown),
                      onPressed: () => _readOnline(filename),
                      tooltip: 'Read Online',
                    ),
                    IconButton(
                      icon: Icon(Icons.download, color: coffeeBrown),
                      onPressed: () => _downloadFile(filename: filename),
                      tooltip: 'Download',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // PDF viewer
  Widget _buildPdfViewer() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SizedBox(
            height: 500,
            child: PDFView(
              filePath: _selectedPdfPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page!;
                  _totalPages = total!;
                });
              },
              onError: (error) => _showErrorSnackBar('Error viewing PDF: $error'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Page ${_currentPage + 1} of $_totalPages', style: TextStyle(color: coffeeBrown)),
                ElevatedButton.icon(
                  onPressed: () => _downloadFile(
                    filename: 'manual_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coffeeBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}