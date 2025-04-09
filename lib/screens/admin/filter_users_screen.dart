import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FilterUsersScreen extends StatefulWidget {
  const FilterUsersScreen({super.key});

  @override
  State<FilterUsersScreen> createState() => _FilterUsersScreenState();
}

class _FilterUsersScreenState extends State<FilterUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortField = 'fullName';
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetails(Map<String, dynamic> userData, String uid) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(userData['fullName'] ?? 'User Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Full Name: ${userData['fullName'] ?? 'N/A'}'),
              Text('Email: ${userData['email'] ?? 'N/A'}'),
              Text('County: ${userData['county'] ?? 'N/A'}'),
              Text('Constituency: ${userData['constituency'] ?? 'N/A'}'),
              Text('Ward: ${userData['ward'] ?? 'N/A'}'),
              Text('Phone Number: ${userData['phoneNumber'] ?? 'N/A'}'),
              Text('Status: ${userData['isDisabled'] == true ? 'Disabled' : 'Active'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Filter Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 3, 39, 4),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildSortSection(),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by County, Constituency, Ward, or Full Name',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          filled: true,
          fillColor: Colors.grey[100],
          hintStyle: const TextStyle(color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        ),
        style: const TextStyle(color: Colors.black),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildSortSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('Users: 0', style: TextStyle(fontWeight: FontWeight.bold));
              final filteredUsers = _filterUsers(snapshot.data!.docs);
              return Text('Users: ${filteredUsers.length}', style: const TextStyle(fontWeight: FontWeight.bold));
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterUsers(List<QueryDocumentSnapshot> docs) {
    final searchText = _searchController.text.toLowerCase();
    return docs.map((doc) => doc.data() as Map<String, dynamic>).where((user) {
      final county = user['county']?.toString().toLowerCase() ?? '';
      final constituency = user['constituency']?.toString().toLowerCase() ?? '';
      final ward = user['ward']?.toString().toLowerCase() ?? '';
      final fullName = user['fullName']?.toString().toLowerCase() ?? '';
      return county.contains(searchText) ||
          constituency.contains(searchText) ||
          ward.contains(searchText) ||
          fullName.contains(searchText);
    }).toList();
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
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

        var filteredUsers = _filterUsers(snapshot.data!.docs);

        filteredUsers.sort((a, b) => _sortAscending
            ? (a[_sortField] ?? '').compareTo(b[_sortField] ?? '')
            : (b[_sortField] ?? '').compareTo(a[_sortField] ?? ''));

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final uid = snapshot.data!.docs.firstWhere((doc) => doc['email'] == user['email']).id;
            return _buildUserTile(user, uid);
          },
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, String uid) {
    return GestureDetector(
      onTap: () => _showUserDetails(user, uid),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['fullName'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Email: ${user['email'] ?? 'N/A'}'),
                ],
              ),
            ),
            if (_sortField != 'fullName')
              Expanded(
                flex: 1,
                child: Text(
                  _sortField == 'county'
                      ? user['county'] ?? 'N/A'
                      : _sortField == 'constituency'
                          ? user['constituency'] ?? 'N/A'
                          : user['ward'] ?? 'N/A',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}