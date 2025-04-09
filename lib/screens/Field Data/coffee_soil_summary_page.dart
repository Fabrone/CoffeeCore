import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeecore/models/coffee_soil_data.dart';

class CoffeeSoilSummaryPage extends StatefulWidget {
  final String userId;

  const CoffeeSoilSummaryPage({required this.userId, super.key});

  @override
  State<CoffeeSoilSummaryPage> createState() => _CoffeeSoilSummaryPageState();
}

class _CoffeeSoilSummaryPageState extends State<CoffeeSoilSummaryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C2F2F),
        title: const Text('Soil History', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      backgroundColor: const Color(0xFFF5E8C7),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coffee_soil_data')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Error loading data', style: TextStyle(color: Colors.red)));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No soil data available', style: TextStyle(color: Color(0xFF4A2C2A))));

          final entries = snapshot.data!.docs.map((doc) => CoffeeSoilData.fromMap(doc.data() as Map<String, dynamic>)).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) => _buildSoilCard(entries[index], snapshot.data!.docs[index].id),
          );
        },
      ),
    );
  }

  Widget _buildSoilCard(CoffeeSoilData entry, String docId) {
    final now = DateTime.now();
    final canEdit = entry.interventions.isNotEmpty && entry.interventions.any((i) => i['result'] == null && i['followUpDate'].toDate().isBefore(now));
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: ExpansionTile(
        title: Text('${entry.plotId} - ${entry.timestamp.toDate().toString().substring(0, 16)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A))),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (entry.interventions.every((i) => i['result'] == null)) IconButton(
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
                _buildFieldRow('Nitrogen (N)', entry.nutrients['N']?.toString() ?? 'N/A'),
                _buildFieldRow('Phosphorus (P)', entry.nutrients['P']?.toString() ?? 'N/A'),
                _buildFieldRow('Potassium (K)', entry.nutrients['K']?.toString() ?? 'N/A'),
                _buildFieldRow('Magnesium (Mg)', entry.nutrients['Mg']?.toString() ?? 'N/A'),
                _buildFieldRow('Calcium (Ca)', entry.nutrients['Ca']?.toString() ?? 'N/A'),
                _buildFieldRow('Interventions', entry.interventions.isNotEmpty ? entry.interventions.map((i) => '${i['method']} (${i['result'] ?? 'Pending'})').join(', ') : 'None'),
                if (canEdit) ElevatedButton(
                  onPressed: () => _addResult(context, entry, docId),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3A5F0B), foregroundColor: Colors.white),
                  child: const Text('Add Follow-Up Result'),
                ),
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
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A))),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF3A5F0B)))),
        ],
      ),
    );
  }

  Future<void> _editSoilData(BuildContext context, CoffeeSoilData entry, String docId) async {
    final phController = TextEditingController(text: entry.ph?.toString());
    final nitrogenController = TextEditingController(text: entry.nutrients['N']?.toString());
    final phosphorusController = TextEditingController(text: entry.nutrients['P']?.toString());
    final potassiumController = TextEditingController(text: entry.nutrients['K']?.toString());
    final magnesiumController = TextEditingController(text: entry.nutrients['Mg']?.toString());
    final calciumController = TextEditingController(text: entry.nutrients['Ca']?.toString());
    List<Map<String, dynamic>> editedInterventions = List.from(entry.interventions);

    // Store ScaffoldMessengerState before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Soil Data', style: TextStyle(color: Color(0xFF4A2C2A))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: phController, decoration: const InputDecoration(labelText: 'Soil pH'), keyboardType: TextInputType.number),
              TextFormField(controller: nitrogenController, decoration: const InputDecoration(labelText: 'Nitrogen (N)'), keyboardType: TextInputType.number),
              TextFormField(controller: phosphorusController, decoration: const InputDecoration(labelText: 'Phosphorus (P)'), keyboardType: TextInputType.number),
              TextFormField(controller: potassiumController, decoration: const InputDecoration(labelText: 'Potassium (K)'), keyboardType: TextInputType.number),
              TextFormField(controller: magnesiumController, decoration: const InputDecoration(labelText: 'Magnesium (Mg)'), keyboardType: TextInputType.number),
              TextFormField(controller: calciumController, decoration: const InputDecoration(labelText: 'Calcium (Ca)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
        ],
      ),
    );

    if (result == true && mounted) {
      final updatedData = CoffeeSoilData(
        userId: widget.userId,
        plotId: entry.plotId,
        stage: entry.stage,
        ph: phController.text.isNotEmpty ? double.parse(phController.text) : null,
        nutrients: {
          'N': nitrogenController.text.isNotEmpty ? double.parse(nitrogenController.text) : null,
          'P': phosphorusController.text.isNotEmpty ? double.parse(phosphorusController.text) : null,
          'K': potassiumController.text.isNotEmpty ? double.parse(potassiumController.text) : null,
          'Mg': magnesiumController.text.isNotEmpty ? double.parse(magnesiumController.text) : null,
          'Ca': calciumController.text.isNotEmpty ? double.parse(calciumController.text) : null,
        },
        interventions: editedInterventions,
        timestamp: Timestamp.now(),
        structureType: entry.structureType,
      );
      await FirebaseFirestore.instance.collection('coffee_soil_data').doc(docId).set(updatedData.toMap());
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Soil data updated')));
      }
    }
  }

  Future<void> _addResult(BuildContext context, CoffeeSoilData entry, String docId) async {
    final resultController = TextEditingController();

    // Store ScaffoldMessengerState before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final updatedIntervention = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Follow-Up Result', style: TextStyle(color: Color(0xFF4A2C2A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Result', border: OutlineInputBorder()),
              items: const [DropdownMenuItem(value: 'Positive', child: Text('Positive')), DropdownMenuItem(value: 'Negative', child: Text('Negative'))],
              onChanged: (value) => resultController.text = value ?? '',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, {'result': resultController.text}), child: const Text('Save')),
        ],
      ),
    );

    if (updatedIntervention != null && mounted) {
      final updatedInterventions = entry.interventions.map((i) => i['followUpDate'].toDate().isBefore(DateTime.now()) && i['result'] == null ? {...i, 'result': updatedIntervention['result']} : i).toList();
      final updatedData = CoffeeSoilData(
        userId: entry.userId,
        plotId: entry.plotId,
        stage: entry.stage,
        ph: entry.ph,
        nutrients: entry.nutrients,
        interventions: updatedInterventions,
        timestamp: entry.timestamp,
        structureType: entry.structureType,
      );
      await FirebaseFirestore.instance.collection('coffee_soil_data').doc(docId).set(updatedData.toMap());
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Result added')));
      }
    }
  }

  Future<void> _deleteSoilData(BuildContext context, String docId) async {
    // Store ScaffoldMessengerState before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion', style: TextStyle(color: Color(0xFF4A2C2A))),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseFirestore.instance.collection('coffee_soil_data').doc(docId).delete();
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Entry deleted')));
      }
    }
  }
}