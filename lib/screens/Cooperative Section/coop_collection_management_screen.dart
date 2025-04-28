import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:coffeecore/screens/messaging_screen.dart' as messaging;

class CoopCollectionManagementScreen extends StatefulWidget {
  final String cooperativeName;
  final String collectionName;

  const CoopCollectionManagementScreen({
    required this.cooperativeName,
    required this.collectionName,
    super.key,
  });

  @override
  State<CoopCollectionManagementScreen> createState() => _CoopCollectionManagementScreenState();
}

class _CoopCollectionManagementScreenState extends State<CoopCollectionManagementScreen> {
  final logger = Logger(printer: PrettyPrinter());
  String _sortField = 'fullName';
  bool _sortAscending = true;

  Future<void> _deleteDocument(String docId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
              'Are you sure you want to remove this ${widget.collectionName == 'users' ? 'user' : 'market manager'} from the cooperative?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
        await FirebaseFirestore.instance
            .collection('${formattedCoopName}_${widget.collectionName}')
            .doc(docId)
            .delete();
        _logActivity('Removed ${widget.collectionName == 'users' ? 'user' : 'market manager'} $docId from cooperative ${widget.cooperativeName}');
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('${widget.collectionName == 'users' ? 'User' : 'Market Manager'} removed successfully!')));
      }
    } catch (e) {
      logger.e('Error deleting document: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error removing: $e')));
      }
    }
  }

  Future<void> _editDocument(String docId, Map<String, dynamic> currentData) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final Map<String, TextEditingController> controllers = {};
    currentData.forEach((key, value) {
      if (key != 'uid') {
        controllers[key] = TextEditingController(text: value?.toString() ?? '');
      }
    });

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${widget.collectionName == 'users' ? 'User' : 'Market Manager'}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
        String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
        await FirebaseFirestore.instance
            .collection('${formattedCoopName}_${widget.collectionName}')
            .doc(docId)
            .update(result);
        _logActivity('Updated ${widget.collectionName == 'users' ? 'user' : 'market manager'} $docId in cooperative ${widget.cooperativeName}');
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('${widget.collectionName == 'users' ? 'User' : 'Market Manager'} updated successfully!')));
      } catch (e) {
        logger.e('Error updating document: $e');
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error updating: $e')));
      }
    }

    controllers.forEach((_, controller) => controller.dispose());
  }

  Future<void> _resetPassword(String email) async {
    try {
      if (email.isEmpty) throw 'Email is required';
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _logActivity('Sent password reset email to $email in cooperative ${widget.cooperativeName}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent!')));
      }
    } catch (e) {
      logger.e('Error sending password reset: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending password reset: $e')));
      }
    }
  }

  Future<void> _contactMarketManagers() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => messaging.MessagingScreen(
          cooperativeName: widget.cooperativeName,
          initialChat: '${widget.cooperativeName.replaceAll(' ', '_')}_Management',
        ),
      ),
    );
  }

  Future<void> _logActivity(String action) async {
    try {
      String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
      await FirebaseFirestore.instance
          .collection(formattedCoopName)
          .doc('logs')
          .collection('coop_admin_logs')
          .add({
        'action': action,
        'timestamp': Timestamp.now(),
        'adminUid': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      logger.e('Error logging activity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
    String title = widget.collectionName == 'users'
        ? 'Manage Cooperative Users'
        : widget.collectionName == 'marketmanagers'
            ? 'Manage Cooperative Market Managers'
            : 'View Cooperative Coffee Prices';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (widget.collectionName != 'coffeeprices')
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
                  .collection('${formattedCoopName}_${widget.collectionName}')
                  .orderBy(widget.collectionName == 'coffeeprices' ? 'variety' : _sortField, descending: !_sortAscending)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  logger.e('Error in collection ${widget.collectionName}: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text('No ${widget.collectionName == 'users' ? 'users' : widget.collectionName == 'marketmanagers' ? 'market managers' : 'coffee prices'} found.'));
                }

                final docs = snapshot.data!.docs;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: widget.collectionName == 'coffeeprices'
                        ? DataTable(
                            columns: const [
                              DataColumn(label: Text('Variety', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Price (Ksh/kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DataRow(cells: [
                                DataCell(Text(data['variety'] ?? 'N/A')),
                                DataCell(Text((data['price'] as num?)?.toStringAsFixed(2) ?? 'N/A')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.message, color: Colors.green),
                                    onPressed: _contactMarketManagers,
                                    tooltip: 'Contact Market Managers',
                                  ),
                                ),
                              ]);
                            }).toList(),
                          )
                        : DataTable(
                            columns: const [
                              DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('County', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Constituency', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Ward', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final uid = doc.id;
                              return DataRow(cells: [
                                DataCell(Text(data['fullName'] ?? 'N/A')),
                                DataCell(Text(data['email'] ?? 'N/A')),
                                DataCell(Text(data['county'] ?? 'N/A')),
                                DataCell(Text(data['constituency'] ?? 'N/A')),
                                DataCell(Text(data['ward'] ?? 'N/A')),
                                DataCell(Text(data['phoneNumber'] ?? 'N/A')),
                                DataCell(Text(data['isDisabled'] == true ? 'Disabled' : 'Active')),
                                DataCell(
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          _editDocument(uid, data);
                                          break;
                                        case 'delete':
                                          _deleteDocument(uid);
                                          break;
                                        case 'reset':
                                          _resetPassword(data['email'] ?? '');
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'reset',
                                        child: Row(
                                          children: [
                                            Icon(Icons.lock_reset, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Reset Password'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}