import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:coffeecore/models/coffee_pest_models.dart';
import 'package:coffeecore/screens/Pest%20Management/coffee_view_interventions_page.dart';

class CoffeeInterventionPage extends StatefulWidget {
  final CoffeePestData pestData;
  final String cropStage;
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  const CoffeeInterventionPage({
    required this.pestData,
    required this.cropStage,
    required this.notificationsPlugin,
    super.key,
  });

  @override
  State<CoffeeInterventionPage> createState() => _CoffeeInterventionPageState();
}

class _CoffeeInterventionPageState extends State<CoffeeInterventionPage> {
  final _interventionController = TextEditingController();
  final _amountController = TextEditingController();
  final _areaController = TextEditingController();
  bool _useSQM = false;

  Future<void> _saveIntervention() async {
    final user = FirebaseAuth.instance.currentUser;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (user == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }

    if (_interventionController.text.isEmpty && _amountController.text.isEmpty && _areaController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please fill at least one field')));
      return;
    }

    final intervention = CoffeePestIntervention(
      pestName: widget.pestData.name,
      cropStage: widget.cropStage,
      intervention: _interventionController.text,
      area: _areaController.text.isNotEmpty ? double.tryParse(_areaController.text) : null,
      areaUnit: _useSQM ? 'SQM' : 'Acres',
      timestamp: Timestamp.now(),
      userId: user.uid,
      isDeleted: false,
      amount: _amountController.text.isNotEmpty ? _amountController.text : null,
    );

    try {
      await FirebaseFirestore.instance.collection('coffee_pest_interventions').doc().set(intervention.toMap());

      await FirebaseFirestore.instance.collection('User_logs').add({
        'userId': user.uid,
        'action': 'create',
        'collection': 'coffee_pest_interventions',
        'documentId': intervention.id ?? 'new',
        'timestamp': Timestamp.now(),
        'details': 'Created intervention for ${widget.pestData.name}',
      });

      setState(() {
        _interventionController.clear();
        _amountController.clear();
        _areaController.clear();
      });
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Intervention saved successfully')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving intervention: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Pest Intervention', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Intervention Used', _interventionController, 'e.g., Chemical control'),
              const SizedBox(height: 16),
              _buildTextField('Amount Applied', _amountController, 'e.g., 5 ml'),
              const SizedBox(height: 16),
              _buildTextField(
                'Total Area Affected',
                _areaController,
                _useSQM ? 'e.g., 100 (SQM)' : 'e.g., 100 (Acres)',
                isNumber: true,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use Square Meters (SQM)', style: TextStyle(color: Colors.black87)),
                value: _useSQM,
                onChanged: (value) => setState(() => _useSQM = value),
                activeColor: const Color(0xFF6F4E37),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _saveIntervention,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F4E37),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Intervention', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CoffeeViewInterventionsPage(
                          pestData: widget.pestData,
                          notificationsPlugin: widget.notificationsPlugin,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F4E37),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Saved Interventions', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isNumber = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }
}