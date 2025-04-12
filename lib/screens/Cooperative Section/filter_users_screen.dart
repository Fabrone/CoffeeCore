import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class FilterUsersScreen extends StatefulWidget {
  final String cooperativeName;

  const FilterUsersScreen({super.key, required this.cooperativeName});

  @override
  State<FilterUsersScreen> createState() => _FilterUsersScreenState();
}

class _FilterUsersScreenState extends State<FilterUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final logger = Logger(printer: PrettyPrinter());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Users', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name or Email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('${formattedCoopName}_users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  logger.e('Error in filter users: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['fullName'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final uid = users[index].id;
                    return ListTile(
                      title: Text(user['fullName'] ?? 'No Name'),
                      subtitle: Text(user['email'] ?? 'No Email'),
                      trailing: Text('UID: $uid'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}