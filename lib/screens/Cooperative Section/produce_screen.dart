import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

// Model class for ProduceData collection
class ProduceData {
  final String id; // Document ID (userId)
  final String farmerName;
  final String contact;
  final String farmArea;
  final String produce;
  final Timestamp timestamp;

  ProduceData({
    required this.id,
    required this.farmerName,
    required this.contact,
    required this.farmArea,
    required this.produce,
    required this.timestamp,
  });

  // Convert ProduceData to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'FarmerName': farmerName,
      'Contact': contact,
      'FarmArea': farmArea,
      'Produce': produce,
      'timestamp': timestamp,
    };
  }

  // Create ProduceData from Firestore document
  factory ProduceData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProduceData(
      id: doc.id,
      farmerName: data['FarmerName'] ?? 'N/A',
      contact: data['Contact'] ?? 'N/A',
      farmArea: data['FarmArea'] ?? 'N/A',
      produce: data['Produce'] ?? '-',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class ProduceScreen extends StatefulWidget {
  final String cooperativeName;

  const ProduceScreen({super.key, required this.cooperativeName});

  @override
  State<ProduceScreen> createState() => _ProduceScreenState();
}

class _ProduceScreenState extends State<ProduceScreen> {
  static final Color coffeeBrown = Colors.brown[700]!;
  final Logger logger = Logger(printer: PrettyPrinter());
  final TextEditingController _farmSizeController = TextEditingController();
  String? _userId;
  String? _farmerName;
  String? _phoneNumber;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    if (_userId == null) {
      setState(() {
        _feedbackMessage = 'No user logged in';
      });
      return;
    }

    try {
      String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('${formattedCoopName}_users')
          .doc(_userId)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _feedbackMessage = 'User not found in cooperative';
        });
        return;
      }

      setState(() {
        _farmerName = userDoc['fullName'] ?? 'N/A';
        _phoneNumber = userDoc['phoneNumber'] ?? 'N/A';
      });
    } catch (e) {
      logger.e('Error fetching user details: $e');
      setState(() {
        _feedbackMessage = 'Error loading user details: $e';
      });
    }
  }

  Future<void> _addFarmSize() async {
    if (_userId == null || _farmerName == null || _phoneNumber == null) {
      setState(() {
        _feedbackMessage = 'User details not loaded';
      });
      return;
    }

    final farmSize = _farmSizeController.text.trim();
    if (farmSize.isEmpty) {
      setState(() {
        _feedbackMessage = 'Please enter farm size';
      });
      return;
    }

    try {
      String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
      final produceData = ProduceData(
        id: _userId!,
        farmerName: _farmerName!,
        contact: _phoneNumber!,
        farmArea: farmSize,
        produce: '-',
        timestamp: Timestamp.now(),
      );

      await FirebaseFirestore.instance
          .collection('${formattedCoopName}_ProduceData')
          .doc(_userId)
          .set(produceData.toMap());

      await _logActivity('Added farm size $farmSize for user $_userId in cooperative ${widget.cooperativeName}');
      setState(() {
        _feedbackMessage = 'Farm size added successfully';
        _farmSizeController.clear();
      });
    } catch (e) {
      logger.e('Error adding farm size: $e');
      setState(() {
        _feedbackMessage = 'Error adding farm size: $e';
      });
    }
  }

  Future<void> _editFarmSize(String docId, String currentFarmSize) async {
    _farmSizeController.text = currentFarmSize;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Farm Size'),
        content: TextField(
          controller: _farmSizeController,
          decoration: InputDecoration(
            labelText: 'Farm Size (e.g., 2.5 acres)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: coffeeBrown),
            onPressed: () {
              if (_farmSizeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a farm size')),
                );
                return;
              }
              Navigator.pop(dialogContext, _farmSizeController.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
        await FirebaseFirestore.instance
            .collection('${formattedCoopName}_ProduceData')
            .doc(docId)
            .update({
          'FarmArea': result,
          'timestamp': Timestamp.now(),
        });
        await _logActivity('Updated farm size to $result for user $docId in cooperative ${widget.cooperativeName}');
        setState(() {
          _feedbackMessage = 'Farm size updated successfully';
        });
      } catch (e) {
        logger.e('Error updating farm size: $e');
        setState(() {
          _feedbackMessage = 'Error updating farm size: $e';
        });
      }
    }
    _farmSizeController.clear();
  }

  Future<void> _logActivity(String action) async {
    try {
      String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
      await FirebaseFirestore.instance
          .collection('cooperatives')
          .doc(formattedCoopName)
          .collection('logs')
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
    _farmSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_feedbackMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_feedbackMessage!)));
        setState(() => _feedbackMessage = null);
      });
    }

    String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Produce - ${widget.cooperativeName}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: coffeeBrown,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        color: Colors.brown[50],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Farm Size',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _farmSizeController,
                      decoration: InputDecoration(
                        labelText: 'Farm Size (e.g., 2.5 acres)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: coffeeBrown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _addFarmSize,
                      child: const Text('Add Farm Size'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('${formattedCoopName}_ProduceData')
                    .doc(_userId) // Fetch only the user's document
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    logger.e('Error loading produce data: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text(
                        'No produce data added yet.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  // Convert single document to a list for DataTable
                  final produceData = ProduceData.fromDocument(snapshot.data!);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columns: const [
                          DataColumn(
                            label: Text('Farmer Name', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Farm Area', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Produce', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                        rows: [
                          DataRow(cells: [
                            DataCell(Text(produceData.farmerName)),
                            DataCell(Text(produceData.contact)),
                            DataCell(Text(produceData.farmArea)),
                            DataCell(Text(produceData.produce)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _editFarmSize(produceData.id, produceData.farmArea);
                                },
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}