import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffeecore/screens/Cooperative%20Section/filter_users_screen.dart';

class CoopAdminManagementScreen extends StatefulWidget {
  const CoopAdminManagementScreen({super.key});

  @override
  State<CoopAdminManagementScreen> createState() => _CoopAdminManagementScreenState();
}

class _CoopAdminManagementScreenState extends State<CoopAdminManagementScreen> {
  final logger = Logger(printer: PrettyPrinter());
  final TextEditingController _coopNameController = TextEditingController();
  final TextEditingController _uidController = TextEditingController();
  String? _cooperativeName;
  String? _userId;
  final List<String> _allCollections = ['users', 'marketmanagers'];

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _checkCoopName();
  }

  Future<void> _checkCoopName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedCoopName = prefs.getString('cooperative_name_$_userId');
    if (storedCoopName != null) {
      setState(() {
        _cooperativeName = storedCoopName;
      });
    } else {
      _showCoopNameDialog();
    }
  }

  Future<void> _showCoopNameDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Cooperative Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _coopNameController,
          decoration: InputDecoration(
            labelText: 'Cooperative Name',
            hintText: 'e.g., Green Valley Coffee',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_coopNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a cooperative name')),
                );
                return;
              }
              _saveCoopName(_coopNameController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCoopName(String coopName) async {
    try {
      String formattedCoopName = coopName.replaceAll(' ', '_');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cooperative_name_$_userId', coopName);
      
      // Create the cooperative document
      await FirebaseFirestore.instance.collection('cooperatives').doc(formattedCoopName).set({
        'name': coopName,
        'createdBy': _userId,
        'timestamp': Timestamp.now(),
      });
      
      // Initialize subcollections with a dummy document to ensure they exist
      await FirebaseFirestore.instance
          .collection(formattedCoopName)
          .doc('users')
          .set({'initialized': true});
      await FirebaseFirestore.instance
          .collection(formattedCoopName)
          .doc('marketmanagers')
          .set({'initialized': true});
      
      setState(() {
        _cooperativeName = coopName;
      });
      logger.i('Cooperative $coopName created for user $_userId with subcollections');
    } catch (e) {
      logger.e('Error saving cooperative name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving cooperative name: $e')),
        );
      }
    }
  }

  Future<void> _editCoopName() async {
    _coopNameController.text = _cooperativeName ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Cooperative Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _coopNameController,
          decoration: InputDecoration(
            labelText: 'Cooperative Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_coopNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a cooperative name')),
                );
                return;
              }
              _updateCoopName(_coopNameController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCoopName(String newCoopName) async {
    try {
      String oldFormattedName = _cooperativeName!.replaceAll(' ', '_');
      String newFormattedName = newCoopName.replaceAll(' ', '_');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cooperative_name_$_userId', newCoopName);
      await FirebaseFirestore.instance.collection('cooperatives').doc(newFormattedName).set({
        'name': newCoopName,
        'createdBy': _userId,
        'timestamp': Timestamp.now(),
      });
      // Optionally, delete old cooperative data or transfer it
      await FirebaseFirestore.instance.collection('cooperatives').doc(oldFormattedName).delete();
      setState(() {
        _cooperativeName = newCoopName;
      });
      logger.i('Cooperative name updated to $newCoopName for user $_userId');
    } catch (e) {
      logger.e('Error updating cooperative name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating cooperative name: $e')),
        );
      }
    }
  }

  Future<void> _assignMarketManager(String uid) async {
    if (_cooperativeName == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      if (!userDoc.exists) throw 'User not found';
      final userData = userDoc.data() as Map<String, dynamic>;
      String formattedCoopName = _cooperativeName!.replaceAll(' ', '_');
      await FirebaseFirestore.instance
          .collection(formattedCoopName)
          .doc('marketmanagers')
          .collection('marketmanagers')
          .doc(uid)
          .set({
        'fullName': userData['fullName'] ?? '',
        'county': userData['county'] ?? '',
        'constituency': userData['constituency'] ?? '',
        'ward': userData['ward'] ?? '',
        'phoneNumber': userData['phoneNumber'] ?? '',
        'email': userData['email'] ?? '',
        'uid': uid,
      });
      _logActivity('Assigned Market Manager role to $uid in cooperative $_cooperativeName');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Market Manager assigned successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning Market Manager: $e')),
        );
      }
    }
  }

  Future<void> _logActivity(String action) async {
    try {
      String formattedCoopName = _cooperativeName!.replaceAll(' ', '_');
      await FirebaseFirestore.instance
          .collection(formattedCoopName)
          .doc('logs')
          .collection('coop_admin_logs')
          .add({
        'action': action,
        'timestamp': Timestamp.now(),
        'adminUid': _userId,
      });
    } catch (e) {
      logger.e('Error logging activity: $e');
    }
  }

  @override
  void dispose() {
    _coopNameController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Co-op Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: _cooperativeName == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _cooperativeName!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.brown),
                          onPressed: _editCoopName,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
    String formattedCoopName = _cooperativeName!.replaceAll(' ', '_');
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
            ..._allCollections.map((collection) => StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(formattedCoopName)
                      .doc(collection)
                      .collection(collection)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    final count = snapshot.data?.docs.length ?? 0;
                    return ListTile(
                      title: Text(collection, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      trailing: Text('$count', style: const TextStyle(fontSize: 16, color: Colors.brown)),
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
        _buildOptionCard('Assign Market Manager', Icons.person_add, () => _showAssignMarketManagerDialog()),
        _buildOptionCard('Manage Users', Icons.people, () => _showManageUsersScreen()),
        _buildOptionCard('Filter Users', Icons.filter_list, () => _showFilterUsersScreen()),
      ],
    );
  }

  Widget _buildOptionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.brown[700]),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignMarketManagerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Market Manager', style: TextStyle(fontWeight: FontWeight.bold)),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a UID')),
                );
                return;
              }
              _assignMarketManager(_uidController.text);
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
    if (_cooperativeName == null) return;
    String formattedCoopName = _cooperativeName!.replaceAll(' ', '_');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select User', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(formattedCoopName)
                .doc('users')
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No users found in this cooperative.');
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
    if (_cooperativeName == null) return;
    String formattedCoopName = _cooperativeName!.replaceAll(' ', '_');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Manage Cooperative Users',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.brown[700],
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(formattedCoopName)
                .doc('users')
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No users found in this cooperative.'));
              }

              final users = snapshot.data!.docs;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('County', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Constituency', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ward', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final uid = doc.id;
                      return DataRow(cells: [
                        DataCell(Text(data['fullName'] ?? 'N/A')),
                        DataCell(Text(data['email'] ?? 'N/A')),
                        DataCell(Text(data['county'] ?? 'N/A')),
                        DataCell(Text(data['constituency'] ?? 'N/A')),
                        DataCell(Text(data['ward'] ?? 'N/A')),
                        DataCell(Text(data['phoneNumber'] ?? 'N/A')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteUser(uid),
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
      ),
    );
  }

  void _confirmDeleteUser(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this user from the cooperative?'),
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

  Future<void> _deleteUser(String uid) async {
    if (_cooperativeName == null) return;
    try {
      String formattedCoopName = _cooperativeName!.replaceAll(' ', '_');
      await FirebaseFirestore.instance
          .collection(formattedCoopName)
          .doc('users')
          .collection('users')
          .doc(uid)
          .delete();
      _logActivity('Removed user $uid from cooperative $_cooperativeName');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User removed from cooperative!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing user: $e')),
        );
      }
    }
  }

  void _showFilterUsersScreen() {
    if (_cooperativeName == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterUsersScreen(cooperativeName: _cooperativeName!), // Named parameter
      ),
    );
  }
}