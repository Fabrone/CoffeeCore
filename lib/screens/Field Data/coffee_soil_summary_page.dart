import 'dart:developer' as developer;
import 'package:coffeecore/models/coffee_soil_data.dart';
import 'package:coffeecore/screens/Field%20Data/helpers/nutrient_analysis_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CoffeeSoilSummaryPage extends StatefulWidget {
  final String userId;

  const CoffeeSoilSummaryPage({required this.userId, super.key});

  @override
  State<CoffeeSoilSummaryPage> createState() => _CoffeeSoilSummaryPageState();
}

class _CoffeeSoilSummaryPageState extends State<CoffeeSoilSummaryPage> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'With Recommendations', 'Without Recommendations'];

  @override
  void initState() {
    super.initState();
    developer.log('CoffeeSoilSummaryPage initialized for user: ${widget.userId}', name: 'CoffeeSoilSummaryPage');
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
        title: const Text('Enhanced Soil History',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Container(
            color: const Color(0xFFF0E4D7),
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _filterOptions.map((filter) => DropdownMenuItem(
                value: filter,
                child: Text(filter),
              )).toList(),
              onChanged: (value) {
                setState(() => _selectedFilter = value ?? 'All');
                developer.log('Filter changed to: $value', name: 'CoffeeSoilSummaryPage');
              },
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF5E8C7),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFilteredStream(),
        builder: (context, snapshot) {
          developer.log('StreamBuilder state: ${snapshot.connectionState}', name: 'CoffeeSoilSummaryPage');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            developer.log('Loading soil data...', name: 'CoffeeSoilSummaryPage');
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            developer.log('Error loading data: ${snapshot.error}', name: 'CoffeeSoilSummaryPage', error: snapshot.error);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading data',
                    style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      developer.log('Retrying data load...', name: 'CoffeeSoilSummaryPage');
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData) {
            developer.log('No snapshot data available', name: 'CoffeeSoilSummaryPage');
            return const Center(child: Text('No data available'));
          }
          
          final docs = snapshot.data!.docs;
          developer.log('Retrieved ${docs.length} documents from Firestore', name: 'CoffeeSoilSummaryPage');
          
          if (docs.isEmpty) {
            developer.log('No soil data found for user: ${widget.userId}', name: 'CoffeeSoilSummaryPage');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No soil data available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by adding your first soil analysis',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          try {
            final entries = docs.map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                developer.log('Processing document: ${doc.id}', name: 'CoffeeSoilSummaryPage');
                return CoffeeSoilData.fromMap(data);
              } catch (e) {
                developer.log('Error parsing document ${doc.id}: $e', name: 'CoffeeSoilSummaryPage', error: e);
                rethrow;
              }
            }).toList();
            
            developer.log('Successfully parsed ${entries.length} soil data entries', name: 'CoffeeSoilSummaryPage');
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                try {
                  return _buildEnhancedSoilCard(entries[index], docs[index].id);
                } catch (e) {
                  developer.log('Error building card for index $index: $e', name: 'CoffeeSoilSummaryPage', error: e);
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: const Text('Error loading this entry'),
                      subtitle: Text('Error: $e'),
                    ),
                  );
                }
              },
            );
          } catch (e) {
            developer.log('Error processing documents: $e', name: 'CoffeeSoilSummaryPage', error: e);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error processing data',
                    style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    try {
      developer.log('Creating filtered stream for user: ${widget.userId}, filter: $_selectedFilter', name: 'CoffeeSoilSummaryPage');
      
      Query query = FirebaseFirestore.instance
          .collection('SoilData')
          .where('userId', isEqualTo: widget.userId)
          .where('isDeleted', isEqualTo: false);

      if (_selectedFilter == 'With Recommendations') {
        query = query.where('saveWithRecommendations', isEqualTo: true);
      } else if (_selectedFilter == 'Without Recommendations') {
        query = query.where('saveWithRecommendations', isEqualTo: false);
      }

      query = query.orderBy('timestamp', descending: true);
      
      developer.log('Query created successfully', name: 'CoffeeSoilSummaryPage');
      return query.snapshots();
    } catch (e) {
      developer.log('Error creating filtered stream: $e', name: 'CoffeeSoilSummaryPage', error: e);
      rethrow;
    }
  }

  Widget _buildEnhancedSoilCard(CoffeeSoilData entry, String docId) {
    try {
      final hasRecommendations = entry.recommendations != null && entry.recommendations!.isNotEmpty;
      
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(16),
            childrenPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A5F0B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.plotId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasRecommendations)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb, size: 12, color: Colors.blue[800]),
                        const SizedBox(width: 4),
                        Text(
                          'RECS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  entry.stage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A2C2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(entry.timestamp.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editSoilData(context, entry, docId);
                } else if (value == 'delete') {
                  _deleteSoilData(context, docId);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              _buildNutrientDataSection(entry),
              if (entry.interventionMethod != null) ...[
                const SizedBox(height: 16),
                _buildInterventionSection(entry),
              ],
              if (hasRecommendations) ...[
                const SizedBox(height: 16),
                _buildRecommendationsSection(entry.recommendations!),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      developer.log('Error building enhanced soil card: $e', name: 'CoffeeSoilSummaryPage', error: e);
      return Card(
        child: ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: const Text('Error displaying this entry'),
          subtitle: Text('Error: $e'),
        ),
      );
    }
  }

  Widget _buildNutrientDataSection(CoffeeSoilData entry) {
    final nutrients = [
      {'name': 'pH', 'value': entry.ph, 'unit': ''},
      {'name': 'Nitrogen', 'value': entry.nitrogen, 'unit': 'kg/acre'},
      {'name': 'Phosphorus', 'value': entry.phosphorus, 'unit': 'kg/acre'},
      {'name': 'Potassium', 'value': entry.potassium, 'unit': 'kg/acre'},
      {'name': 'Magnesium', 'value': entry.magnesium, 'unit': 'kg/acre'},
      {'name': 'Calcium', 'value': entry.calcium, 'unit': 'kg/acre'},
      {'name': 'Zinc', 'value': entry.zinc, 'unit': 'g/acre'},
      {'name': 'Boron', 'value': entry.boron, 'unit': 'g/acre'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: Color(0xFF3A5F0B), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Nutrient Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A2C2A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A5F0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entry.plantDensity} plants/acre',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3A5F0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: nutrients.length,
            itemBuilder: (context, index) {
              final nutrient = nutrients[index];
              final value = nutrient['value'] as double?;
              if (value == null) return const SizedBox.shrink();
              
              final status = NutrientAnalysisHelper.getNutrientStatus(
                nutrient['name'].toString().toLowerCase(),
                value,
                entry.stage,
              );
              
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(status).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nutrient['name'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A2C2A),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          value.toStringAsFixed(nutrient['name'] == 'pH' ? 1 : 2),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          nutrient['unit'].toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionSection(CoffeeSoilData entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Intervention Applied',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A2C2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldRow('Method', entry.interventionMethod ?? 'N/A'),
          if (entry.interventionQuantity != null && entry.interventionUnit != null)
            _buildFieldRow('Quantity', '${entry.interventionQuantity} ${entry.interventionUnit}'),
          if (entry.interventionFollowUpDate != null)
            _buildFieldRow(
              'Follow-up Date',
              DateFormat('MMM dd, yyyy').format(entry.interventionFollowUpDate!.toDate()),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(Map<String, dynamic> recommendations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Saved Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A2C2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.entries.map((entry) => _buildRecommendationCard(
            entry.key,
            entry.value as Map<String, dynamic>,
          )),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String nutrient, Map<String, dynamic> recommendations) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(
          nutrient.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A2C2A),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recommendations.entries.map((rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getRecommendationTypeTitle(rec.key),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getRecommendationTypeColor(rec.key),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec.value.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              )).toList(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A2C2A),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF3A5F0B),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRecommendationTypeTitle(String type) {
    switch (type) {
      case 'natural': return '🌱 Natural';
      case 'biological': return '🦠 Biological';
      case 'artificial': return '⚗️ Artificial';
      case 'application': return '📋 Application';
      case 'maintain': return '✅ Maintain';
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

  Future<void> _editSoilData(BuildContext context, CoffeeSoilData entry, String docId) async {
    try {
      developer.log('Starting edit for document: $docId', name: 'CoffeeSoilSummaryPage');
      
      final controllers = <String, TextEditingController>{};
      final nutrients = ['pH', 'nitrogen', 'phosphorus', 'potassium', 'magnesium', 'calcium', 'zinc', 'boron'];
      
      for (String nutrient in nutrients) {
        double? value;
        switch (nutrient) {
          case 'pH': value = entry.ph; break;
          case 'nitrogen': value = entry.nitrogen; break;
          case 'phosphorus': value = entry.phosphorus; break;
          case 'potassium': value = entry.potassium; break;
          case 'magnesium': value = entry.magnesium; break;
          case 'calcium': value = entry.calcium; break;
          case 'zinc': value = entry.zinc; break;
          case 'boron': value = entry.boron; break;
        }
        controllers[nutrient] = TextEditingController(text: value?.toString() ?? '');
      }

      final interventionMethodController = TextEditingController(text: entry.interventionMethod);
      final interventionQuantityController = TextEditingController(text: entry.interventionQuantity);
      final interventionUnitController = TextEditingController(text: entry.interventionUnit);
      DateTime? interventionFollowUpDate = entry.interventionFollowUpDate?.toDate();
      String selectedStage = entry.stage;
      int plantDensity = entry.plantDensity;

      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit Soil Data', style: TextStyle(color: Color(0xFF4A2C2A))),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStage,
                    decoration: const InputDecoration(labelText: 'Growth Stage'),
                    items: const [
                      'Establishment/Seedling',
                      'Vegetative Growth',
                      'Flowering and Fruiting',
                      'Maturation and Harvesting'
                    ].map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
                    onChanged: (value) => selectedStage = value ?? selectedStage,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: plantDensity.toString(),
                    decoration: const InputDecoration(labelText: 'Plant Density (plants/acre)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => plantDensity = int.tryParse(value) ?? plantDensity,
                  ),
                  const SizedBox(height: 16),
                  const Text('Macronutrients', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...nutrients.take(6).map((nutrient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      controller: controllers[nutrient],
                      decoration: InputDecoration(
                        labelText: '${nutrient.toUpperCase()} ${NutrientAnalysisHelper.getNutrientUnit(nutrient, false)}',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  )),
                  const SizedBox(height: 16),
                  const Text('Micronutrients', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...nutrients.skip(6).map((nutrient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      controller: controllers[nutrient],
                      decoration: InputDecoration(
                        labelText: '${nutrient.toUpperCase()} ${NutrientAnalysisHelper.getNutrientUnit(nutrient, false)}',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  )),
                  const SizedBox(height: 16),
                  const Text('Intervention', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: interventionMethodController,
                    decoration: const InputDecoration(labelText: 'Intervention Method'),
                  ),
                  TextFormField(
                    controller: interventionQuantityController,
                    decoration: const InputDecoration(labelText: 'Intervention Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: interventionUnitController,
                    decoration: const InputDecoration(labelText: 'Intervention Unit'),
                  ),
                  ListTile(
                    title: Text('Follow-up: ${interventionFollowUpDate?.toString().substring(0, 10) ?? 'N/A'}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: interventionFollowUpDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        interventionFollowUpDate = picked;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        developer.log('Saving edited soil data for document: $docId', name: 'CoffeeSoilSummaryPage');
        
        final updatedData = CoffeeSoilData(
          userId: widget.userId,
          plotId: entry.plotId,
          stage: selectedStage,
          ph: controllers['pH']!.text.isNotEmpty ? double.parse(controllers['pH']!.text) : null,
          nitrogen: controllers['nitrogen']!.text.isNotEmpty ? double.parse(controllers['nitrogen']!.text) : null,
          phosphorus: controllers['phosphorus']!.text.isNotEmpty ? double.parse(controllers['phosphorus']!.text) : null,
          potassium: controllers['potassium']!.text.isNotEmpty ? double.parse(controllers['potassium']!.text) : null,
          magnesium: controllers['magnesium']!.text.isNotEmpty ? double.parse(controllers['magnesium']!.text) : null,
          calcium: controllers['calcium']!.text.isNotEmpty ? double.parse(controllers['calcium']!.text) : null,
          zinc: controllers['zinc']!.text.isNotEmpty ? double.parse(controllers['zinc']!.text) : null,
          boron: controllers['boron']!.text.isNotEmpty ? double.parse(controllers['boron']!.text) : null,
          plantDensity: plantDensity,
          interventionMethod: interventionMethodController.text.isNotEmpty ? interventionMethodController.text : null,
          interventionQuantity: interventionQuantityController.text.isNotEmpty ? interventionQuantityController.text : null,
          interventionUnit: interventionUnitController.text.isNotEmpty ? interventionUnitController.text : null,
          interventionFollowUpDate: interventionFollowUpDate != null ? Timestamp.fromDate(interventionFollowUpDate!) : null,
          recommendations: entry.recommendations,
          saveWithRecommendations: entry.saveWithRecommendations,
          timestamp: Timestamp.now(),
          structureType: entry.structureType,
          isDeleted: false,
        );
        
        await FirebaseFirestore.instance
            .collection('SoilData')
            .doc(docId)
            .set(updatedData.toMap());
        
        developer.log('Successfully updated soil data for document: $docId', name: 'CoffeeSoilSummaryPage');
        
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Soil data updated successfully')),
          );
        }
      }

      // Dispose controllers
      for (final controller in controllers.values) {
        controller.dispose();
      }
    } catch (e) {
      developer.log('Error editing soil data: $e', name: 'CoffeeSoilSummaryPage', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSoilData(BuildContext context, String docId) async {
    try {
      developer.log('Starting delete for document: $docId', name: 'CoffeeSoilSummaryPage');
      
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion', style: TextStyle(color: Color(0xFF4A2C2A))),
          content: const Text('Are you sure you want to delete this soil analysis entry? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await FirebaseFirestore.instance
            .collection('SoilData')
            .doc(docId)
            .update({'isDeleted': true});
        
        developer.log('Successfully deleted soil data for document: $docId', name: 'CoffeeSoilSummaryPage');
        
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Soil analysis entry deleted')),
          );
        }
      }
    } catch (e) {
      developer.log('Error deleting soil data: $e', name: 'CoffeeSoilSummaryPage', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}