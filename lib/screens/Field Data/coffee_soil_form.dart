import 'dart:developer' as developer;
import 'package:coffeecore/models/coffee_soil_data.dart';
import 'package:coffeecore/screens/Field%20Data/helpers/nutrient_analysis_helper.dart';
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
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _nutrientStatus = {};
  final Map<String, Map<String, String>> _allRecommendations = {};
  final Map<String, bool> _expandedRecommendations = {};
  
  String _selectedStage = 'Establishment/Seedling';
  int _plantDensity = 1000;
  bool _isPerPlant = false;
  bool _saveWithRecommendations = false;
  
  String? _interventionMethod;
  String? _interventionQuantity;
  String? _interventionUnit;
  DateTime? _interventionFollowUpDate;

  static const List<String> _nutrients = [
    'pH', 'nitrogen', 'phosphorus', 'potassium', 
    'magnesium', 'calcium', 'zinc', 'boron'
  ];

  static const List<String> _stages = [
    'Establishment/Seedling',
    'Vegetative Growth',
    'Flowering and Fruiting',
    'Maturation and Harvesting'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    developer.log('CoffeeSoilForm initialized for user: ${widget.userId}, plot: ${widget.plotId}', name: 'CoffeeSoilForm');
  }

  @override
  void dispose() {
    developer.log('Disposing CoffeeSoilForm controllers', name: 'CoffeeSoilForm');
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (String nutrient in _nutrients) {
      _controllers[nutrient] = TextEditingController();
      _controllers[nutrient]!.addListener(() => _updateAnalysis());
    }
    developer.log('Initialized ${_controllers.length} nutrient controllers', name: 'CoffeeSoilForm');
  }

  void _updateAnalysis() {
    try {
      setState(() {
        _nutrientStatus.clear();
        _allRecommendations.clear();
        
        for (String nutrient in _nutrients) {
          final controller = _controllers[nutrient]!;
          if (controller.text.isNotEmpty) {
            final value = double.tryParse(controller.text);
            if (value != null) {
              final status = NutrientAnalysisHelper.getNutrientStatus(nutrient, value, _selectedStage);
              _nutrientStatus[nutrient] = status;
              
              if (status != 'Optimal') {
                _allRecommendations[nutrient] = NutrientAnalysisHelper.getRecommendations(
                  nutrient, status, _selectedStage
                );
                developer.log('Generated recommendations for $nutrient: $status', name: 'CoffeeSoilForm');
              }
            }
          }
        }
      });
    } catch (e) {
      developer.log('Error updating analysis: $e', name: 'CoffeeSoilForm', error: e);
    }
  }

  Widget _buildNutrientField(String nutrient) {
    final controller = _controllers[nutrient]!;
    final unit = NutrientAnalysisHelper.getNutrientUnit(nutrient, _isPerPlant);
    final status = _nutrientStatus[nutrient];
    final recommendations = _allRecommendations[nutrient];
    final isExpanded = _expandedRecommendations[nutrient] ?? false;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nutrient input field
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '${nutrient.toUpperCase()} ${unit.isNotEmpty ? "($unit)" : ""}',
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF3A5F0B)),
                ),
                suffixIcon: nutrient != 'pH' ? IconButton(
                  icon: Icon(_isPerPlant ? Icons.person : Icons.landscape),
                  onPressed: () => _toggleUnit(nutrient),
                  tooltip: _isPerPlant ? 'Switch to per acre' : 'Switch to per plant',
                ) : null,
              ),
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              onChanged: (_) => _updateAnalysis(),
            ),
            
            // Gauge visualization
            if (controller.text.isNotEmpty && status != null) ...[
              const SizedBox(height: 12),
              _buildGaugeVisualization(nutrient, double.parse(controller.text)),
            ],
            
            // Status display with View Recommendation button
            if (status != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Text(
                      'Status: $status',
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (recommendations != null && recommendations.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _expandedRecommendations[nutrient] = !isExpanded;
                        });
                      },
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                      ),
                      label: Text(
                        isExpanded ? 'Hide' : 'View Recommendations',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3A5F0B),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            // Recommendations (only show when expanded)
            if (recommendations != null && recommendations.isNotEmpty && isExpanded) ...[
              const SizedBox(height: 12),
              _buildRecommendationTabs(nutrient, recommendations),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeVisualization(String nutrient, double value) {
    final ranges = NutrientAnalysisHelper.optimalValues[_selectedStage]?[nutrient];
    if (ranges == null) return const SizedBox.shrink();

    final low = ranges['low'] ?? 0;
    final optimal = ranges['optimal'] ?? 0;
    final high = ranges['high'] ?? 0;
    
    final maxValue = high * 1.5;
    final position = (value / maxValue).clamp(0.0, 1.0);
    
    return Column(
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.orange, Colors.green, Colors.orange, Colors.red],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: position * (MediaQuery.of(context).size.width - 64),
                child: Container(
                  width: 4,
                  height: 20,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(low.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
            Text(optimal.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(high.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationTabs(String nutrient, Map<String, String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommendations:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A)),
          ),
          const SizedBox(height: 8),
          ...recommendations.entries.map((entry) => _buildRecommendationTab(
            nutrient, entry.key, entry.value
          )),
        ],
      ),
    );
  }

  Widget _buildRecommendationTab(String nutrient, String type, String recommendation) {
    final key = '${nutrient}_$type';
    final isExpanded = _expandedRecommendations[key] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ExpansionTile(
        title: Text(
          _getRecommendationTypeTitle(type),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _getRecommendationTypeColor(type),
          ),
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _expandedRecommendations[key] = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF3A5F0B)),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _pasteRecommendationToIntervention(recommendation),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Use as Intervention', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4A2C2A),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pasteRecommendationToIntervention(String recommendation) {
    setState(() {
      _interventionMethod = recommendation;
    });
    developer.log('Pasted recommendation to intervention: ${recommendation.substring(0, 50)}...', name: 'CoffeeSoilForm');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recommendation pasted to intervention method'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getRecommendationTypeTitle(String type) {
    switch (type) {
      case 'natural': return '🌱 Natural Solutions';
      case 'biological': return '🦠 Biological Solutions';
      case 'artificial': return '⚗️ Artificial Solutions';
      case 'application': return '📋 Application Method';
      case 'maintain': return '✅ Maintenance';
      case 'avoid': return '⚠️ Avoid';
      default: return type.toUpperCase();
    }
  }

  Color _getRecommendationTypeColor(String type) {
    switch (type) {
      case 'natural': return Colors.green;
      case 'biological': return Colors.blue;
      case 'artificial': return Colors.orange;
      case 'application': return Colors.purple;
      case 'maintain': return Colors.teal;
      case 'avoid': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Low': return Colors.red;
      case 'High': return Colors.orange;
      case 'Optimal': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _toggleUnit(String nutrient) {
    try {
      final controller = _controllers[nutrient]!;
      if (controller.text.isNotEmpty) {
        final currentValue = double.tryParse(controller.text);
        if (currentValue != null) {
          double convertedValue;
          if (_isPerPlant) {
            convertedValue = NutrientAnalysisHelper.convertToPerAcre(nutrient, currentValue, _plantDensity);
          } else {
            convertedValue = NutrientAnalysisHelper.convertToPerPlant(nutrient, currentValue, _plantDensity);
          }
          controller.text = convertedValue.toStringAsFixed(2);
          developer.log('Toggled unit for $nutrient: ${_isPerPlant ? "per plant" : "per acre"}', name: 'CoffeeSoilForm');
        }
      }
      setState(() => _isPerPlant = !_isPerPlant);
      _updateAnalysis();
    } catch (e) {
      developer.log('Error toggling unit for $nutrient: $e', name: 'CoffeeSoilForm', error: e);
    }
  }

  Future<void> _addIntervention() async {
    try {
      String? method = _interventionMethod;
      String? quantity;
      String? unit;
      DateTime followUpDate = DateTime.now().add(const Duration(days: 30));
      final methodController = TextEditingController(text: method ?? '');
      final quantityController = TextEditingController();
      final unitController = TextEditingController();

      final intervention = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Intervention', style: TextStyle(color: Color(0xFF4A2C2A))),
          content: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Nutrient',
                      border: OutlineInputBorder(),
                    ),
                    items: _nutrientStatus.entries
                        .where((e) => e.value != 'Optimal')
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.key.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null && _allRecommendations[value] != null) {
                        methodController.text = _allRecommendations[value]!['artificial'] ?? '';
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: methodController,
                    decoration: const InputDecoration(
                      labelText: 'Method',
                      border: OutlineInputBorder(),
                      helperText: 'Tap "Use as Intervention" from recommendations to auto-fill',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('Follow-up: ${followUpDate.toString().substring(0, 10)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: followUpDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => followUpDate = picked);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
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
              child: const Text('Save'),
            ),
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
        await _scheduleReminder(
          intervention['followUpDate'],
          'Check soil after applying ${intervention['method']}',
        );
        developer.log('Added intervention: ${intervention['method']}', name: 'CoffeeSoilForm');
      }
    } catch (e) {
      developer.log('Error adding intervention: $e', name: 'CoffeeSoilForm', error: e);
    }
  }

  Future<void> _scheduleReminder(DateTime date, String message) async {
    try {
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
      developer.log('Scheduled reminder for: $date', name: 'CoffeeSoilForm');
    } catch (e) {
      developer.log('Error scheduling reminder: $e', name: 'CoffeeSoilForm', error: e);
    }
  }

  Future<void> _saveForm() async {
    try {
      if (_formKey.currentState!.validate()) {
        developer.log('Saving soil data for user: ${widget.userId}, plot: ${widget.plotId}', name: 'CoffeeSoilForm');
        
        final soilData = CoffeeSoilData(
          userId: widget.userId,
          plotId: widget.plotId,
          stage: _selectedStage,
          ph: _controllers['pH']!.text.isNotEmpty ? double.parse(_controllers['pH']!.text) : null,
          nitrogen: _controllers['nitrogen']!.text.isNotEmpty ? double.parse(_controllers['nitrogen']!.text) : null,
          phosphorus: _controllers['phosphorus']!.text.isNotEmpty ? double.parse(_controllers['phosphorus']!.text) : null,
          potassium: _controllers['potassium']!.text.isNotEmpty ? double.parse(_controllers['potassium']!.text) : null,
          magnesium: _controllers['magnesium']!.text.isNotEmpty ? double.parse(_controllers['magnesium']!.text) : null,
          calcium: _controllers['calcium']!.text.isNotEmpty ? double.parse(_controllers['calcium']!.text) : null,
          zinc: _controllers['zinc']!.text.isNotEmpty ? double.parse(_controllers['zinc']!.text) : null,
          boron: _controllers['boron']!.text.isNotEmpty ? double.parse(_controllers['boron']!.text) : null,
          plantDensity: _plantDensity,
          interventionMethod: _interventionMethod,
          interventionQuantity: _interventionQuantity,
          interventionUnit: _interventionUnit,
          interventionFollowUpDate: _interventionFollowUpDate != null ? Timestamp.fromDate(_interventionFollowUpDate!) : null,
          recommendations: _saveWithRecommendations ? _allRecommendations : null,
          saveWithRecommendations: _saveWithRecommendations,
          timestamp: Timestamp.now(),
          structureType: widget.structureType,
          isDeleted: false,
        );

        final docId = '${widget.userId}_${soilData.timestamp.millisecondsSinceEpoch}';
        await FirebaseFirestore.instance
            .collection('SoilData')
            .doc(docId)
            .set(soilData.toMap());
        
        developer.log('Successfully saved soil data with ID: $docId', name: 'CoffeeSoilForm');
        
        widget.onSave();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_saveWithRecommendations 
                ? 'Soil data saved with recommendations' 
                : 'Soil data saved'),
            ),
          );
        }
        _resetForm();
      }
    } catch (e) {
      developer.log('Error saving soil data: $e', name: 'CoffeeSoilForm', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      for (final controller in _controllers.values) {
        controller.clear();
      }
      _nutrientStatus.clear();
      _allRecommendations.clear();
      _expandedRecommendations.clear();
      _interventionMethod = null;
      _interventionQuantity = null;
      _interventionUnit = null;
      _interventionFollowUpDate = null;
      _saveWithRecommendations = false;
    });
    developer.log('Form reset completed', name: 'CoffeeSoilForm');
  }

  String? _validateNumber(String? value) =>
      value != null && value.isNotEmpty && double.tryParse(value) == null
          ? 'Enter a valid number'
          : null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Growth Stage Selection
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Growth Stage & Plant Density',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStage,
                      decoration: const InputDecoration(
                        labelText: 'Growth Stage',
                        border: OutlineInputBorder(),
                      ),
                      items: _stages.map((stage) => DropdownMenuItem(
                        value: stage,
                        child: Text(stage),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStage = value ?? 'Establishment/Seedling');
                        _updateAnalysis();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _plantDensity.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Plant Density (plants/acre)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final density = int.tryParse(value);
                        if (density != null) {
                          setState(() => _plantDensity = density);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Unit Toggle
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Display Units: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Per Acre')),
                        ButtonSegment(value: true, label: Text('Per Plant')),
                      ],
                      selected: {_isPerPlant},
                      onSelectionChanged: (selection) {
                        setState(() => _isPerPlant = selection.first);
                        _updateAnalysis();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Macronutrients Section
            const Text(
              'Macronutrients',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A)),
            ),
            const SizedBox(height: 8),
            ..._nutrients.take(6).map((nutrient) => _buildNutrientField(nutrient)),
            
            const SizedBox(height: 16),
            
            // Micronutrients Section
            const Text(
              'Micronutrients',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A)),
            ),
            const SizedBox(height: 8),
            ..._nutrients.skip(6).map((nutrient) => _buildNutrientField(nutrient)),
            
            const SizedBox(height: 24),
            
            // Add Intervention Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _nutrientStatus.values.any((status) => status != 'Optimal') ? _addIntervention : null,
                icon: const Icon(Icons.add_circle),
                label: const Text('Add Intervention'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A2C2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            // Intervention Display
            if (_interventionMethod != null) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: ListTile(
                  title: Text('Intervention: $_interventionMethod'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_interventionQuantity != null && _interventionUnit != null)
                        Text('Quantity: $_interventionQuantity $_interventionUnit'),
                      if (_interventionFollowUpDate != null)
                        Text('Follow-up: ${_interventionFollowUpDate!.toString().substring(0, 10)}'),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Save Options
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Save Options',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A)),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Save with recommendations'),
                      subtitle: const Text('Include all recommendations in saved data'),
                      value: _saveWithRecommendations,
                      onChanged: (value) => setState(() => _saveWithRecommendations = value ?? false),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveForm,
                        icon: const Icon(Icons.save),
                        label: Text(_saveWithRecommendations 
                          ? 'Save with Recommendations' 
                          : 'Save Soil Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A2C2A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}