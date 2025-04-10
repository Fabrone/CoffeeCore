import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coffeecore/screens/admin/filter_users_screen.dart';
import 'package:logger/logger.dart';
import 'package:coffeecore/screens/admin/collection_management_screen.dart';
import 'package:coffeecore/screens/admin/admin_pest_management_page.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final logger = Logger(printer: PrettyPrinter());
  final TextEditingController _uidController = TextEditingController();
  List<String> _allCollections = [];

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  Future<void> _fetchCollections() async {
    try {
      setState(() {
        _allCollections = [
          'Users',
          'Admins',
          'MarketOfficers',
          'market_prices',
          'coffee_disease_interventions',
          'coffee_pest_interventions',
          'User_logs',
          'admin_logs',
          'coffee_soil_data',
        ];
      });
    } catch (e) {
      logger.e('Error fetching collections: $e');
    }
  }

  Future<void> _assignRole(String uid, String collection) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      if (!userDoc.exists) throw 'User not found';
      await FirebaseFirestore.instance.collection(collection).doc(uid).set({'added': true});
      _logActivity('Assigned $collection role to $uid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${collection.replaceAll('s', '')} role assigned successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning role: $e')));
      }
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).delete();
      _logActivity('Deleted user $uid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted from Firestore!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
      }
    }
  }

  Future<void> _resetPassword(String email) async {
    try {
      if (email.isEmpty) throw 'Email is required';
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _logActivity('Sent password reset for $email');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending password reset: $e')));
      }
    }
  }

  Future<void> _logActivity(String action) async {
    try {
      await FirebaseFirestore.instance.collection('admin_logs').add({
        'action': action,
        'timestamp': Timestamp.now(),
        'adminUid': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      logger.e('Error logging activity: $e');
    }
  }

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCollectionStats(),
              const SizedBox(height: 20),
              _buildManagementOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Collection Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_allCollections.isEmpty)
              const CircularProgressIndicator()
            else
              ..._allCollections.map((collection) => StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection(collection).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final count = snapshot.data?.docs.length ?? 0;
                      return ListTile(
                        title: Text(collection, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        trailing: Text('$count', style: const TextStyle(fontSize: 16, color: Colors.brown)),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CollectionManagementScreen(collectionName: collection),
                          ),
                        ),
                      );
                    },
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOptions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildOptionCard('Assign User Role', Icons.person_add, () => _showRoleSelectionDialog()),
        _buildOptionCard('Manage Users', Icons.people, () => _showManageUsersScreen()),
        _buildOptionCard('Manage Pests', Icons.bug_report, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPestManagementPage()))),
        _buildOptionCard('Filter Users', Icons.filter_list, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FilterUsersScreen()))),
      ],
    );
  }

  Widget _buildOptionCard(String title, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: onTap == null ? Colors.grey[300] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.brown[700]),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoleSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign User Role', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAssignRoleDialog('Admins');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Assign Admin Role'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAssignRoleDialog('MarketOfficers');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Assign Market Officer Role'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAssignRoleDialog(String collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign ${collection.replaceAll('s', '')} Role', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _uidController,
                decoration: InputDecoration(
                  labelText: 'Enter User UID',
                  hintText: 'e.g., abc123xyz789',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.paste),
              onPressed: () async {
                final clipboardData = await Clipboard.getData('text/plain');
                if (clipboardData != null && clipboardData.text != null) {
                  _uidController.text = clipboardData.text!;
                }
              },
              tooltip: 'Paste UID',
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showUserListDialog(),
              tooltip: 'Select User',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_uidController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a UID')));
                return;
              }
              _assignRole(_uidController.text, collection);
              Navigator.pop(context);
              _uidController.clear();
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showUserListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select User', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No users found.');
              }
              final users = snapshot.data!.docs;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final uid = users[index].id;
                  return ListTile(
                    title: Text(user['fullName'] ?? 'No Name'),
                    subtitle: Text('UID: $uid'),
                    onTap: () {
                      _uidController.text = uid;
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showManageUsersScreen() {
    String? bulkAction;
    List<String> selectedUids = [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            appBar: AppBar(
              title: const Text('Manage Users', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu),
                  onSelected: (value) {
                    setState(() {
                      bulkAction = value;
                      selectedUids.clear();
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Bulk Delete', child: Text('Bulk Delete')),
                    const PopupMenuItem(value: 'Bulk Reset Password', child: Text('Bulk Reset Password')),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('Users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Total Users: ${snapshot.data!.docs.length}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('Users').snapshots(),
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
                              return DataRow(cells: [
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
                                DataCell(
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'Delete') {
                                        _confirmDeleteUser(uid);
                                      }
                                      if (value == 'Reset Password') {
                                        _resetPassword(data['email'] ?? '');
                                      }
                                      if (value == 'Copy UID') {
                                        Clipboard.setData(ClipboardData(text: uid));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('UID copied to clipboard!')),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'Delete', child: Text('Delete User')),
                                      const PopupMenuItem(value: 'Reset Password', child: Text('Reset Password')),
                                      const PopupMenuItem(value: 'Copy UID', child: Text('Copy UID')),
                                    ],
                                    icon: const Icon(Icons.more_vert),
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
                if (bulkAction != null && selectedUids.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (bulkAction == 'Bulk Delete') {
                          for (var uid in selectedUids) {
                            _confirmDeleteUser(uid);
                          }
                        } else if (bulkAction == 'Bulk Reset Password') {
                          for (var uid in selectedUids) {
                            final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
                            await _resetPassword(doc['email'] ?? '');
                          }
                        }
                        setState(() {
                          bulkAction = null;
                          selectedUids.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[700],
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Execute $bulkAction'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteUser(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteUser(uid);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}