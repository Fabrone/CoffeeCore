import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class CollectionManagementScreen extends StatefulWidget {
  final String collectionName;

  const CollectionManagementScreen({required this.collectionName, super.key});

  @override
  State<CollectionManagementScreen> createState() => _CollectionManagementScreenState();
}

class _CollectionManagementScreenState extends State<CollectionManagementScreen> {
  String _sortField = 'fullName';
  bool _sortAscending = true;

  Future<void> _deleteDocument(String docId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture before async
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to delete this document? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true), // Just signal confirmation
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await FirebaseFirestore.instance.collection(widget.collectionName).doc(docId).delete();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Document deleted successfully!')));
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error deleting document: $e')));
      }
    }
  }

  Future<void> _editDocument(String docId, Map<String, dynamic> currentData) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final Map<String, TextEditingController> controllers = {};
    currentData.forEach((key, value) {
      if (key != 'profileImage') {
        controllers[key] = TextEditingController(text: value?.toString() ?? '');
      }
    });

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Document $docId', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: controllers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controllers.map((key, controller) => MapEntry(key, controller.text))),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await FirebaseFirestore.instance.collection(widget.collectionName).doc(docId).update(result);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Document updated successfully!')));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error updating document: $e')));
      }
    }

    controllers.forEach((_, controller) => controller.dispose());
  }

  void _showUserDetails(String uid, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['fullName'] ?? 'User Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['profileImage'] != null)
                Center(
                  child: Image.memory(
                    base64Decode(data['profileImage']),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text('Full Name: ${data['fullName'] ?? 'N/A'}'),
              Text('Email: ${data['email'] ?? 'N/A'}'),
              Text('County: ${data['county'] ?? 'N/A'}'),
              Text('Constituency: ${data['constituency'] ?? 'N/A'}'),
              Text('Ward: ${data['ward'] ?? 'N/A'}'),
              Text('Phone Number: ${data['phoneNumber'] ?? 'N/A'}'),
              Text('Status: ${data['isDisabled'] == true ? 'Disabled' : 'Active'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _resetPassword(data['email'] ?? ''),
            child: const Text('Reset Password'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(String email) async {
    try {
      if (email.isEmpty) throw 'Email is required';
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending password reset: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.collectionName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 3, 39, 4),
        foregroundColor: Colors.white,
      ),
      body: widget.collectionName == 'Users' ? _buildUsersTable() : _buildGenericList(),
    );
  }

  Widget _buildUsersTable() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _sortField,
                items: const [
                  DropdownMenuItem(value: 'fullName', child: Text('Full Name')),
                  DropdownMenuItem(value: 'county', child: Text('County')),
                  DropdownMenuItem(value: 'constituency', child: Text('Constituency')),
                  DropdownMenuItem(value: 'ward', child: Text('Ward')),
                ],
                onChanged: (value) => setState(() => _sortField = value!),
                style: const TextStyle(color: Colors.black),
              ),
              IconButton(
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () => setState(() => _sortAscending = !_sortAscending),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .orderBy(_sortField, descending: !_sortAscending)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No users found.'));
              }

              final users = snapshot.data!.docs;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('County', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Constituency', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ward', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final uid = doc.id;
                      return DataRow(
                        onSelectChanged: (selected) {
                          if (selected == true) {
                            _showUserDetails(uid, data);
                          }
                        },
                        cells: [
                          DataCell(
                            data['profileImage'] != null
                                ? Image.memory(
                                    base64Decode(data['profileImage']),
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.person, size: 28),
                          ),
                          DataCell(Text(data['fullName'] ?? 'N/A')),
                          DataCell(Text(data['email'] ?? 'N/A')),
                          DataCell(Text(data['county'] ?? 'N/A')),
                          DataCell(Text(data['constituency'] ?? 'N/A')),
                          DataCell(Text(data['ward'] ?? 'N/A')),
                          DataCell(Text(data['phoneNumber'] ?? 'N/A')),
                          DataCell(Text(data['isDisabled'] == true ? 'Disabled' : 'Active')),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editDocument(uid, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDocument(uid),
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenericList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(widget.collectionName).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No documents found.'));
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(doc.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data.entries
                    .where((e) => e.key != 'profileImage')
                    .map((e) => '${e.key}: ${e.value}')
                    .join(', ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editDocument(doc.id, data),
                      tooltip: 'Edit Document',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDocument(doc.id),
                      tooltip: 'Delete Document',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}