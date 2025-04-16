import 'package:coffeecore/models/coffee_soil_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class CoffeeSoilForm extends StatefulWidget {
  final String userId;
  final String plotId;
  final String structureType;
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final VoidCallback onSave;

  const CoffeeSoilForm({
    required this.userId,
    required this.plotId,
    required this.structureType,
    required this.notificationsPlugin,
    required this.onSave,
    super.key,
  });

  @override
  State<CoffeeSoilForm> createState() => _CoffeeSoilFormState();
}

class _CoffeeSoilFormState extends State<CoffeeSoilForm> {
  final _formKey = GlobalKey<FormState>();
  final _phController = TextEditingController();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _magnesiumController = TextEditingController();
  final _calciumController = TextEditingController();
  final Map<String, String> _nutrientStatus = {};
  final Map<String, String> _recommendations = {};
  String? _interventionMethod;
  String? _interventionQuantity;
  String? _interventionUnit;
  DateTime? _interventionFollowUpDate;

  static const Map<String, Map<String, double>> _optimalValues = {
    'Establishment/Seedling': {
      'pH': 5.5,
      'nitrogen': 40,
      'phosphorus': 9,
      'potassium': 30,
      'magnesium': 5.5,
      'calcium': 9
    },
    'Vegetative Growth': {
      'pH': 5.5,
      'nitrogen': 56,
      'phosphorus': 17.5,
      'potassium': 54,
      'magnesium': 12.5,
      'calcium': 18.5
    },
    'Flowering and Fruiting': {
      'pH': 5.5,
      'nitrogen': 53.5,
      'phosphorus': 22.5,
      'potassium': 68.5,
      'magnesium': 18.5,
      'calcium': 18.5
    },
    'Maturation and Harvesting': {
      'pH': 5.5,
      'nitrogen': 30,
      'phosphorus': 14.5,
      'potassium': 54,
      'magnesium': 9,
      'calcium': 10.5
    },
  };

  static const Map<String, List<String>> _stages = {
    'Coffee': [
      'Establishment/Seedling',
      'Vegetative Growth',
      'Flowering and Fruiting',
      'Maturation and Harvesting'
    ],
  };

  String _selectedStage = 'Establishment/Seedling';

  @override
  void initState() {
    super.initState();
    _updateAnalysis();
  }

  void _updateAnalysis() {
    setState(() {
      _nutrientStatus.clear();
      _recommendations.clear();
      final optimal = _optimalValues[_selectedStage]!;
      for (var nutrient in [
        'pH',
        'nitrogen',
        'phosphorus',
        'potassium',
        'magnesium',
        'calcium'
      ]) {
        final controller = nutrient == 'pH'
            ? _phController
            : nutrient == 'nitrogen'
                ? _nitrogenController
                : nutrient == 'phosphorus'
                    ? _phosphorusController
                    : nutrient == 'potassium'
                        ? _potassiumController
                        : nutrient == 'magnesium'
                            ? _magnesiumController
                            : _calciumController;
        final value =
            controller.text.isNotEmpty ? double.tryParse(controller.text) : null;
        if (value != null) {
          final optimalValue = optimal[nutrient]!;
          if (value < optimalValue - 1) {
            _nutrientStatus[nutrient] = 'Low';
            _recommendations[nutrient] = _getRecommendation(nutrient, 'raise');
          } else if (value > optimalValue + 1) {
            _nutrientStatus[nutrient] = 'High';
            _recommendations[nutrient] = _getRecommendation(nutrient, 'lower');
          } else {
            _nutrientStatus[nutrient] = 'Optimal';
          }
        }
      }
    });
  }

  String _getRecommendation(String nutrient, String action) {
    if (action == 'raise') {
      switch (nutrient) {
        case 'pH':
          return 'Apply lime (calcium carbonate) at 1-2 tons/acre.';
        case 'nitrogen':
          return 'Use urea (46-0-0) or composted manure (20 kg/plant).';
        case 'phosphorus':
          return 'Apply triple superphosphate (0-46-0) at 100-150 kg/acre.';
        case 'potassium':
          return 'Use muriate of potash (0-0-60) at 150-200 kg/acre.';
        case 'magnesium':
          return 'Apply magnesium sulfate (Epsom salt) at 20-30 kg/acre.';
        case 'calcium':
          return 'Use gypsum (calcium sulfate) at 500-1000 kg/acre.';
      }
    } else {
      switch (nutrient) {
        case 'pH':
          return 'Add elemental sulfur (100-200 kg/acre) or organic matter.';
        case 'nitrogen':
          return 'Reduce nitrogen fertilizers; leach with water if possible.';
        case 'phosphorus':
          return 'No direct reduction; avoid further P application.';
        case 'potassium':
          return 'No direct reduction; avoid further K application.';
        case 'magnesium':
          return 'No direct reduction; avoid Mg-rich fertilizers.';
        case 'calcium':
          return 'No direct reduction; avoid Ca-rich amendments.';
      }
    }
    return '';
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final soilData = CoffeeSoilData(
        userId: widget.userId,
        plotId: widget.plotId,
        stage: _selectedStage,
        ph: _phController.text.isNotEmpty
            ? double.parse(_phController.text)
            : null,
        nitrogen: _nitrogenController.text.isNotEmpty
            ? double.parse(_nitrogenController.text)
            : null,
        phosphorus: _phosphorusController.text.isNotEmpty
            ? double.parse(_phosphorusController.text)
            : null,
        potassium: _potassiumController.text.isNotEmpty
            ? double.parse(_potassiumController.text)
            : null,
        magnesium: _magnesiumController.text.isNotEmpty
            ? double.parse(_magnesiumController.text)
            : null,
        calcium: _calciumController.text.isNotEmpty
            ? double.parse(_calciumController.text)
            : null,
        interventionMethod: _interventionMethod,
        interventionQuantity: _interventionQuantity,
        interventionUnit: _interventionUnit,
        interventionFollowUpDate: _interventionFollowUpDate != null
            ? Timestamp.fromDate(_interventionFollowUpDate!)
            : null,
        timestamp: Timestamp.now(),
        structureType: widget.structureType,
        isDeleted: false,
      );

      await FirebaseFirestore.instance
          .collection('coffee_soil_data')
          .doc('${widget.userId}_${soilData.timestamp.millisecondsSinceEpoch}')
          .set(soilData.toMap());
      widget.onSave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Soil data saved')));
      }
      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      _phController.clear();
      _nitrogenController.clear();
      _phosphorusController.clear();
      _potassiumController.clear();
      _magnesiumController.clear();
      _calciumController.clear();
      _nutrientStatus.clear();
      _recommendations.clear();
      _interventionMethod = null;
      _interventionQuantity = null;
      _interventionUnit = null;
      _interventionFollowUpDate = null;
    });
  }

  Future<void> _addIntervention() async {
    String? method;
    String? quantity;
    String? unit;
    DateTime followUpDate = DateTime.now().add(const Duration(days: 30));
    final methodController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();

    final intervention = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Intervention',
            style: TextStyle(color: Color(0xFF4A2C2A))),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'Nutrient', border: OutlineInputBorder()),
                items: _nutrientStatus.entries
                    .where((e) => e.value != 'Optimal')
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.key)))
                    .toList(),
                onChanged: (value) =>
                    methodController.text = _recommendations[value] ?? '',
              ),
              TextField(
                  controller: methodController,
                  decoration: const InputDecoration(labelText: 'Method')),
              TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unit')),
              ListTile(
                title: Text(
                    'Follow-up: ${followUpDate.toString().substring(0, 10)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: followUpDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030));
                  if (picked != null) setState(() => followUpDate = picked);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                method = methodController.text;
                quantity = quantityController.text;
                unit = unitController.text;
                if (method?.isNotEmpty ?? false) {
                  Navigator.pop(context, {
                    'method': method,
                    'quantity': quantity,
                    'unit': unit,
                    'followUpDate': followUpDate
                  });
                }
              },
              child: const Text('Save')),
        ],
      ),
    );

    if (intervention != null) {
      setState(() {
        _interventionMethod = intervention['method'];
        _interventionQuantity = intervention['quantity'];
        _interventionUnit = intervention['unit'];
        _interventionFollowUpDate = intervention['followUpDate'];
      });
      await _scheduleReminder(intervention['followUpDate'],
          'Check soil after applying ${intervention['method']}');
    }
  }

  Future<void> _scheduleReminder(DateTime date, String message) async {
    const androidDetails = AndroidNotificationDetails(
      'soil_reminder',
      'Soil Reminders',
      channelDescription: 'Reminders for soil follow-ups',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    final tzDateTime = tz.TZDateTime.from(date, tz.local);
    await widget.notificationsPlugin.zonedSchedule(
      (widget.userId + widget.plotId + date.toString()).hashCode,
      'Soil Follow-Up for ${widget.plotId}',
      message,
      tzDateTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStage,
              decoration: const InputDecoration(
                  labelText: 'Growth Stage', border: OutlineInputBorder()),
              items: _stages['Coffee']!
                  .map((stage) => DropdownMenuItem(value: stage, child: Text(stage)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedStage = value ?? 'Establishment/Seedling'),
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _phController,
                decoration: _inputDecoration('Soil pH'),
                keyboardType: TextInputType.number,
                validator: _validateNumber,
                onChanged: (_) => _updateAnalysis()),
            _buildStatusRow('pH'),
            TextFormField(
                controller: _nitrogenController,
                decoration: _inputDecoration('Nitrogen (N) kg/acre'),
                keyboardType: TextInputType.number,
                validator: _validateNumber,
                onChanged: (_) => _updateAnalysis()),
            _buildStatusRow('nitrogen'),
            TextFormField(
                controller: _phosphorusController,
                decoration: _inputDecoration('Phosphorus (P) kg/acre'),
                keyboardType: TextInputType.number,
                validator: _validateNumber,
                onChanged: (_) => _updateAnalysis()),
            _buildStatusRow('phosphorus'),
            TextFormField(
                controller: _potassiumController,
                decoration: _inputDecoration('Potassium (K) kg/acre'),
                keyboardType: TextInputType.number,
                validator: _validateNumber,
                onChanged: (_) => _updateAnalysis()),
            _buildStatusRow('potassium'),
            TextFormField(
                controller: _magnesiumController,
                decoration: _inputDecoration('Magnesium (Mg) kg/acre'),
                keyboardType: TextInputType.number,
                validator: _validateNumber,
                onChanged: (_) => _updateAnalysis()),
            _buildStatusRow('magnesium'),
            TextFormField(
                controller: _calciumController,
                decoration: _inputDecoration('Calcium (Ca) kg/acre'),
                keyboardType: TextInputType.number,
                validator: _validateNumber,
                onChanged: (_) => _updateAnalysis()),
            _buildStatusRow('calcium'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addIntervention,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A2C2A),
                  foregroundColor: Colors.white),
              child: const Text('Add Intervention'),
            ),
            if (_interventionMethod != null)
              ListTile(
                title: Text(
                    'Intervention: $_interventionMethod - $_interventionQuantity $_interventionUnit'),
                subtitle: Text(
                    'Follow-up: ${_interventionFollowUpDate?.toString().substring(0, 10) ?? 'N/A'}'),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveForm,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A2C2A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text('Save Soil Data', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF3A5F0B))),
      );

  String? _validateNumber(String? value) =>
      value != null && value.isNotEmpty && double.tryParse(value) == null
          ? 'Enter a valid number'
          : null;

  Widget _buildStatusRow(String nutrient) {
    final status = _nutrientStatus[nutrient];
    final recommendation = _recommendations[nutrient];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null)
            Text(
              '$nutrient Status: $status',
              style: TextStyle(
                  color: status == 'Low'
                      ? Colors.red
                      : status == 'High'
                          ? Colors.orange
                          : Colors.green),
            ),
          if (recommendation != null)
            Text('Recommendation: $recommendation',
                style: const TextStyle(color: Color(0xFF3A5F0B))),
        ],
      ),
    );
  }
}