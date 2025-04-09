import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:coffeecore/home.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

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

  static final Color coffeeBrown = Colors.brown[700]!; // CoffeeCore theme color

  @override
  void dispose() {
    _cleanupTemporaryFile();
    super.dispose();
  }

  void _cleanupTemporaryFile() {
    if (_selectedPdfPath != null) {
      File(_selectedPdfPath!).deleteSync();
      _selectedPdfPath = null;
    }
  }

  Future<void> _readOnline(String url, String filename) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      setState(() {
        _selectedPdfPath = file.path;
        _currentPage = 0;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading manual: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadFile({String? url, String? localPath, required String filename}) async {
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

      if (url != null) {
        final response = await http.get(Uri.parse(url));
        final bytes = response.bodyBytes;
        await targetFile.writeAsBytes(bytes);
      } else if (localPath != null) {
        final file = File(localPath);
        await file.copy(targetFile.path);
      } else {
        throw Exception('No valid source provided for download');
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
      return true;
    }
    return true;
  }

  Future<int> _getAndroidVersion() async {
    try {
      var platform = Platform.operatingSystemVersion;
      var versionString = platform.split(' ')[1];
      return int.parse(versionString.split('.')[0]);
    } catch (e) {
      return 0;
    }
  }

  void _openDownloadedFile() {
    if (_downloadedFilePath != null) {
      OpenFile.open(_downloadedFilePath!);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _sendMessage(String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar('Please log in to send a message');
      return;
    }
    final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    final fullName = userDoc['fullName'] ?? 'Anonymous';

    final requestRef = FirebaseFirestore.instance.collection('ManualRequests').doc(user.uid);
    await requestRef.set({'userId': user.uid, 'fullName': fullName}, SetOptions(merge: true));

    await requestRef.collection('messages').add({
      'senderId': user.uid,
      'senderName': fullName,
      'message': message,
      'timestamp': Timestamp.now(),
      'isAdmin': false,
      'read': false,
    });
    _showSuccessSnackBar('Message sent successfully!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage())),
        ),
        title: const Text('Coffee Farming Manuals', style: TextStyle(color: Colors.white)), // Updated title
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
                _buildChatSection(),
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

  Widget _buildWelcomeAnimation() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.brown[50], // Light coffee shade
      child: AnimatedTextKit(
        animatedTexts: [
          TyperAnimatedText(
            'Welcome to Coffee Farming Manuals!\nExplore expert-approved guides by coffee specialists to enhance your coffee farming skills.',
            textStyle: TextStyle(fontSize: 18, color: coffeeBrown, fontWeight: FontWeight.bold),
            speed: const Duration(milliseconds: 50),
          ),
        ],
        totalRepeatCount: 1,
      ),
    );
  }

  Widget _buildManualsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Manuals').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final manuals = snapshot.data!.docs;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(16.0),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: manuals.length,
            itemBuilder: (context, index) {
              final manual = manuals[index].data() as Map<String, dynamic>;
              final title = manual['title'] ?? 'Untitled';
              final filename = manual['filename'] ?? '';
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility, color: coffeeBrown),
                      onPressed: () async {
                        final url = await FirebaseStorage.instance.ref('manuals/$filename').getDownloadURL();
                        _readOnline(url, filename);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.download, color: coffeeBrown),
                      onPressed: () async {
                        final url = await FirebaseStorage.instance.ref('manuals/$filename').getDownloadURL();
                        _downloadFile(url: url, filename: filename);
                      },
                    ),
                  ],
                ),
                title: Text(title),
                trailing: Icon(Icons.book, color: coffeeBrown),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPdfViewer() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16.0),
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
          if (_currentPage == _totalPages - 1)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () => _downloadFile(
                  localPath: _selectedPdfPath,
                  filename: 'manual_${DateTime.now().millisecondsSinceEpoch}.pdf',
                ),
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: coffeeBrown,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Please log in to message the admin.', style: TextStyle(color: coffeeBrown)),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message Admin',
              style: TextStyle(fontSize: 16, color: coffeeBrown, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ManualRequests')
                    .doc(user.uid)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text('No messages yet. Start a conversation below.', style: TextStyle(color: coffeeBrown));
                  }
                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index].data() as Map<String, dynamic>;
                      final isUser = message['senderId'] == user.uid;
                      return ListTile(
                        title: Text(
                          message['message'],
                          textAlign: isUser ? TextAlign.right : TextAlign.left,
                          style: TextStyle(color: isUser ? Colors.blue : coffeeBrown), // Admin messages in coffee brown
                        ),
                        subtitle: Text(
                          '${message['senderName']} - ${message['timestamp'].toDate()}',
                          textAlign: isUser ? TextAlign.right : TextAlign.left,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type your message (e.g., request a coffee manual)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _sendMessage(value);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: coffeeBrown),
                  onPressed: () {
                    final controller = TextEditingController.fromValue(const TextEditingValue(text: ''));
                    if (controller.text.isNotEmpty) {
                      _sendMessage(controller.text);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}