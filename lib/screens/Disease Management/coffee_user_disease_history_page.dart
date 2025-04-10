import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coffeecore/models/coffee_disease_models.dart';
import 'package:logger/logger.dart';

class CoffeeUserDiseaseHistoryPage extends StatefulWidget {
  const CoffeeUserDiseaseHistoryPage({super.key});

  @override
  State<CoffeeUserDiseaseHistoryPage> createState() => _CoffeeUserDiseaseHistoryPageState();
}

class _CoffeeUserDiseaseHistoryPageState extends State<CoffeeUserDiseaseHistoryPage> {
  final _logger = Logger();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Disease Management History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF6F4E37),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please log in to view history.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Disease Management History', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coffee_disease_interventions')
            .where('userId', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            _logger.e('Error fetching history: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No disease management history available.'));
          }

          final interventions = snapshot.data!.docs.map((doc) {
            try {
              return CoffeeDiseaseIntervention.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null);
            } catch (e) {
              _logger.e('Error parsing intervention ${doc.id}: $e');
              return null;
            }
          }).where((item) => item != null).cast<CoffeeDiseaseIntervention>().toList();

          return Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: interventions.length,
              itemBuilder: (context, index) {
                final intervention = interventions[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Disease: ${intervention.diseaseName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Stage: ${intervention.cropStage}'),
                        Text('Intervention: ${intervention.intervention.isNotEmpty ? intervention.intervention : "None"}'),
                        Text('Amount: ${intervention.amount ?? "N/A"}'),
                        Text('Area: ${intervention.area ?? "N/A"} ${intervention.areaUnit}'),
                        Text('Saved: ${intervention.timestamp.toDate().toString()}'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editIntervention(intervention),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteIntervention(intervention),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _editIntervention(CoffeeDiseaseIntervention intervention) async {
    final controller = TextEditingController(text: intervention.intervention);
    final amountController = TextEditingController(text: intervention.amount ?? '');
    final areaController = TextEditingController(text: intervention.area?.toString() ?? '');
    bool useSQM = intervention.areaUnit == 'SQM';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Intervention'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: controller, decoration: const InputDecoration(labelText: 'Intervention Used')),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount Applied')),
                TextField(controller: areaController, decoration: const InputDecoration(labelText: 'Total Area Affected'), keyboardType: TextInputType.number),
                SwitchListTile(
                  title: const Text('Use SQM'),
                  value: useSQM,
                  onChanged: (value) => setDialogState(() => useSQM = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        await FirebaseFirestore.instance.collection('coffee_disease_interventions').doc(intervention.id).update({
          'intervention': controller.text,
          'amount': amountController.text.isNotEmpty ? amountController.text : null,
          'area': areaController.text.isNotEmpty ? double.parse(areaController.text) : null,
          'areaUnit': useSQM ? 'SQM' : 'Acres',
        });

        await FirebaseFirestore.instance.collection('User_logs').add({
          'userId': intervention.userId,
          'action': 'edit',
          'collection': 'coffee_disease_interventions',
          'documentId': intervention.id,
          'timestamp': Timestamp.now(),
          'details': 'Updated intervention for ${intervention.diseaseName}',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intervention updated successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating intervention: $e')));
        }
      }
    }
  }

  Future<void> _deleteIntervention(CoffeeDiseaseIntervention intervention) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this intervention? It can be restored by an admin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await FirebaseFirestore.instance.collection('coffee_disease_interventions').doc(intervention.id).update({
          'isDeleted': true,
        });

        await FirebaseFirestore.instance.collection('User_logs').add({
          'userId': intervention.userId,
          'action': 'delete',
          'collection': 'coffee_disease_interventions',
          'documentId': intervention.id,
          'timestamp': Timestamp.now(),
          'details': 'Soft-deleted intervention for ${intervention.diseaseName}',
        });

        if (mounted) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Intervention deleted successfully')));
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error deleting intervention: $e')));
        }
      }
    }
  }
}