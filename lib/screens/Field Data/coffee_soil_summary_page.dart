import 'dart:developer' as developer;
import 'package:coffeecore/models/coffee_soil_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoffeeSoilSummaryPage extends StatefulWidget {
  final String userId;

  const CoffeeSoilSummaryPage({required this.userId, super.key});

  @override
  State<CoffeeSoilSummaryPage> createState() => _CoffeeSoilSummaryPageState();
}

class _CoffeeSoilSummaryPageState extends State<CoffeeSoilSummaryPage> {
  @override
  void initState() {
    super.initState();
    // Enable offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C2F2F),
        title: const Text('Soil History',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      backgroundColor: const Color(0xFFF5E8C7),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coffee_soil_data')
            .where('userId', isEqualTo: widget.userId)
            .where('isDeleted', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            developer.log('Error: ${snapshot.error}',
                name: 'CoffeeSoilSummaryPage');
            return const Center(
                child: Text('Error loading data',
                    style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No soil data available',
                    style: TextStyle(color: Color(0xFF4A2C2A))));
          }

          final entries = snapshot.data!.docs
              .map((doc) => CoffeeSoilData.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) =>
                _buildSoilCard(entries[index], snapshot.data!.docs[index].id),
          );
        },
      ),
    );
  }

  Widget _buildSoilCard(CoffeeSoilData entry, String docId) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: ExpansionTile(
        title: Text(
            '${entry.plotId} - ${entry.timestamp.toDate().toString().substring(0, 16)}',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A2C2A))),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editSoilData(context, entry, docId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSoilData(context, docId),
                    ),
                  ],
                ),
                _buildFieldRow('Stage', entry.stage),
                _buildFieldRow('pH', entry.ph?.toString() ?? 'N/A'),
                _buildFieldRow('Nitrogen (N)', entry.nitrogen?.toString() ?? 'N/A'),
                _buildFieldRow(
                    'Phosphorus (P)', entry.phosphorus?.toString() ?? 'N/A'),
                _buildFieldRow(
                    'Potassium (K)', entry.potassium?.toString() ?? 'N/A'),
                _buildFieldRow(
                    'Magnesium (Mg)', entry.magnesium?.toString() ?? 'N/A'),
                _buildFieldRow('Calcium (Ca)', entry.calcium?.toString() ?? 'N/A'),
                _buildFieldRow('Intervention Method',
                    entry.interventionMethod?.toString() ?? 'None'),
                _buildFieldRow('Intervention Quantity',
                    entry.interventionQuantity?.toString() ?? 'N/A'),
                _buildFieldRow(
                    'Intervention Unit',
                    entry.interventionUnit?.toString() ?? 'N/A'),
                _buildFieldRow(
                    'Intervention Follow-Up',
                    entry.interventionFollowUpDate
                            ?.toDate()
                            .toString()
                            .substring(0, 10) ??
                        'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: Color(0xFF3A5F0B)))),
        ],
      ),
    );
  }

  Future<void> _editSoilData(
      BuildContext context, CoffeeSoilData entry, String docId) async {
    final phController = TextEditingController(text: entry.ph?.toString());
    final nitrogenController =
        TextEditingController(text: entry.nitrogen?.toString());
    final phosphorusController =
        TextEditingController(text: entry.phosphorus?.toString());
    final potassiumController =
        TextEditingController(text: entry.potassium?.toString());
    final magnesiumController =
        TextEditingController(text: entry.magnesium?.toString());
    final calciumController =
        TextEditingController(text: entry.calcium?.toString());
    final interventionMethodController =
        TextEditingController(text: entry.interventionMethod);
    final interventionQuantityController =
        TextEditingController(text: entry.interventionQuantity);
    final interventionUnitController =
        TextEditingController(text: entry.interventionUnit);
    DateTime? interventionFollowUpDate =
        entry.interventionFollowUpDate?.toDate();

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Soil Data',
            style: TextStyle(color: Color(0xFF4A2C2A))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: phController,
                  decoration: const InputDecoration(labelText: 'Soil pH'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: nitrogenController,
                  decoration: const InputDecoration(labelText: 'Nitrogen (N)'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: phosphorusController,
                  decoration: const InputDecoration(labelText: 'Phosphorus (P)'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: potassiumController,
                  decoration: const InputDecoration(labelText: 'Potassium (K)'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: magnesiumController,
                  decoration:
                      const InputDecoration(labelText: 'Magnesium (Mg)'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: calciumController,
                  decoration: const InputDecoration(labelText: 'Calcium (Ca)'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: interventionMethodController,
                  decoration:
                      const InputDecoration(labelText: 'Intervention Method')),
              TextFormField(
                  controller: interventionQuantityController,
                  decoration:
                      const InputDecoration(labelText: 'Intervention Quantity'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: interventionUnitController,
                  decoration:
                      const InputDecoration(labelText: 'Intervention Unit')),
              ListTile(
                title: Text(
                    'Follow-up: ${interventionFollowUpDate?.toString().substring(0, 10) ?? 'N/A'}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: interventionFollowUpDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030));
                  if (picked != null) {
                    interventionFollowUpDate = picked;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (result == true && mounted) {
      final updatedData = CoffeeSoilData(
        userId: widget.userId,
        plotId: entry.plotId,
        stage: entry.stage,
        ph: phController.text.isNotEmpty
            ? double.parse(phController.text)
            : null,
        nitrogen: nitrogenController.text.isNotEmpty
            ? double.parse(nitrogenController.text)
            : null,
        phosphorus: phosphorusController.text.isNotEmpty
            ? double.parse(phosphorusController.text)
            : null,
        potassium: potassiumController.text.isNotEmpty
            ? double.parse(potassiumController.text)
            : null,
        magnesium: magnesiumController.text.isNotEmpty
            ? double.parse(magnesiumController.text)
            : null,
        calcium: calciumController.text.isNotEmpty
            ? double.parse(calciumController.text)
            : null,
        interventionMethod: interventionMethodController.text.isNotEmpty
            ? interventionMethodController.text
            : null,
        interventionQuantity: interventionQuantityController.text.isNotEmpty
            ? interventionQuantityController.text
            : null,
        interventionUnit: interventionUnitController.text.isNotEmpty
            ? interventionUnitController.text
            : null,
        interventionFollowUpDate: interventionFollowUpDate != null
            ? Timestamp.fromDate(interventionFollowUpDate!)
            : null,
        timestamp: Timestamp.now(),
        structureType: entry.structureType,
        isDeleted: false,
      );
      await FirebaseFirestore.instance
          .collection('coffee_soil_data')
          .doc(docId)
          .set(updatedData.toMap());
      if (mounted) {
        scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Soil data updated')));
      }
    }
  }

  Future<void> _deleteSoilData(BuildContext context, String docId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion',
            style: TextStyle(color: Color(0xFF4A2C2A))),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseFirestore.instance
          .collection('coffee_soil_data')
          .doc(docId)
          .update({'isDeleted': true});
      if (mounted) {
        scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Entry deleted')));
      }
    }
  }
}