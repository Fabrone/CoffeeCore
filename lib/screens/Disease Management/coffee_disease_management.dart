import 'dart:async';
import 'package:coffeecore/screens/Disease%20Management/coffee_disease_intervention_page.dart';
import 'package:coffeecore/screens/Disease%20Management/coffee_user_disease_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:coffeecore/models/coffee_disease_models.dart';

class CoffeeDiseaseManagementPage extends StatefulWidget {
  const CoffeeDiseaseManagementPage({super.key});

  @override
  State<CoffeeDiseaseManagementPage> createState() => _CoffeeDiseaseManagementPageState();
}

class _CoffeeDiseaseManagementPageState extends State<CoffeeDiseaseManagementPage> {
  String? _selectedStage;
  String? _selectedDisease;
  CoffeeDiseaseData? _diseaseData;
  bool _showDiseaseDetails = false;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _hintsKey = GlobalKey();

  final List<String> _stages = [
    'Vegetative Stage',
    'Flowering & Fruit Development',
  ];

  final Map<String, List<String>> _stageDiseases = {
    'Vegetative Stage': [
      'Coffee Leaf Rust',
      'Coffee Wilt Disease',
      'Cercospora Leaf Spot',
      'Brown Eye Spot',
      'Phytophthora Root Rot',
      'Bacterial Blight',
      'Coffee Sooty Mold',
      'Fusarium Root Rot',
    ],
    'Flowering & Fruit Development': [
      'Coffee Leaf Rust',
      'Coffee Berry Disease',
      'Anthracnose',
    ],
  };

  final Map<String, Map<String, dynamic>> _diseaseDetails = {
    'Coffee Leaf Rust': {
      'description': 'A fungal disease that primarily affects the leaves of coffee plants.',
      'symptoms': 'Orange-yellow spots on the underside of leaves, leaf drop.',
      'chemicalControls': ['Copper-based', 'Trifloxystrobin', 'Tebuconazole'],
      'mechanicalControls': ['Pruning of infected leaves'],
      'biologicalControls': ['Resistant varieties (e.g., SL28)'],
      'possibleCauses': ['High humidity', 'Warm temperatures (20-28°C)', 'Dense foliage'],
      'preventiveMeasures': ['Improve air circulation', 'Apply mulch', 'Use resistant varieties'],
    },
    'Coffee Wilt Disease': {
      'description': 'A soil-borne fungal infection that causes rapid wilting and death of coffee plants.',
      'symptoms': 'Sudden wilting, yellowing of leaves, and rotting of roots.',
      'chemicalControls': ['Thiophanate methyl', 'Carbendazim'],
      'mechanicalControls': ['Removal of infected plants'],
      'biologicalControls': ['Soil sterilization'],
      'possibleCauses': ['Wet soil', 'Poor drainage', 'Contaminated tools'],
      'preventiveMeasures': ['Improve drainage', 'Sanitize tools', 'Avoid overwatering'],
    },
    'Coffee Berry Disease': {
      'description': 'A fungal disease that causes dark lesions on coffee berries.',
      'symptoms': 'Black lesions on coffee cherries, premature fruit drop.',
      'chemicalControls': ['Azoxystrobin', 'Tebuconazole', 'Difenoconazole'],
      'mechanicalControls': ['Pruning and sanitation'],
      'biologicalControls': [],
      'possibleCauses': ['High rainfall', 'Warm temperatures', 'Poor sanitation'],
      'preventiveMeasures': ['Regular pruning', 'Remove fallen berries', 'Improve air flow'],
    },
    'Cercospora Leaf Spot': {
      'description': 'A fungal disease that affects coffee leaves.',
      'symptoms': 'Dark brown to black lesions with yellow halos on the leaves.',
      'chemicalControls': ['Chlorothalonil', 'Mancozeb', 'Copper-based'],
      'mechanicalControls': ['Pruning of infected leaves'],
      'biologicalControls': [],
      'possibleCauses': ['High humidity', 'Overcrowded plants', 'Nutrient deficiency'],
      'preventiveMeasures': ['Balance fertilization', 'Prune regularly', 'Avoid overhead watering'],
    },
    'Brown Eye Spot': {
      'description': 'A form of Cercospora disease affecting coffee plants.',
      'symptoms': 'Round brown lesions surrounded by yellow halos, premature leaf drop.',
      'chemicalControls': ['Mancozeb', 'Chlorothalonil', 'Copper-based'],
      'mechanicalControls': ['Removal of infected leaves'],
      'biologicalControls': [],
      'possibleCauses': ['Wet conditions', 'Poor air circulation', 'Nutrient imbalance'],
      'preventiveMeasures': ['Improve ventilation', 'Monitor soil nutrients', 'Remove debris'],
    },
    'Anthracnose': {
      'description': 'A fungal disease that affects coffee fruits, causing lesions and decay.',
      'symptoms': 'Sunken, dark lesions on fruit and branches.',
      'chemicalControls': ['Azoxystrobin', 'Tebuconazole', 'Difenoconazole'],
      'mechanicalControls': ['Removal of affected fruit'],
      'biologicalControls': [],
      'possibleCauses': ['High rainfall', 'Warm weather', 'Injured fruit'],
      'preventiveMeasures': ['Harvest carefully', 'Sanitize tools', 'Prune affected areas'],
    },
    'Phytophthora Root Rot': {
      'description': 'A waterborne pathogen that attacks the roots of coffee plants, causing rot.',
      'symptoms': 'Yellowing of leaves, stunted growth, root decay, and poor plant vigor.',
      'chemicalControls': ['Metalaxyl', 'Phosphonates'],
      'mechanicalControls': ['Proper drainage to avoid waterlogging'],
      'biologicalControls': [],
      'possibleCauses': ['Excessive water', 'Poor drainage', 'High rainfall'],
      'preventiveMeasures': ['Improve soil drainage', 'Avoid planting in low areas', 'Mulch roots'],
    },
    'Bacterial Blight': {
      'description': 'A bacterial infection that affects the coffee plant.',
      'symptoms': 'Water-soaked lesions on leaves and stems, leading to wilting.',
      'chemicalControls': ['Copper-based bactericides'],
      'mechanicalControls': ['Removal of infected plant parts'],
      'biologicalControls': [],
      'possibleCauses': ['Wet conditions', 'Wounds from pruning', 'Contaminated tools'],
      'preventiveMeasures': ['Sanitize equipment', 'Avoid overhead irrigation', 'Prune in dry weather'],
    },
    'Coffee Sooty Mold': {
      'description': 'A fungal disease caused by mold growing on honeydew from sap-sucking insects.',
      'symptoms': 'Black sooty growth on leaves and branches, reduced photosynthesis.',
      'chemicalControls': ['Insecticides (for sap-sucking pests)'],
      'mechanicalControls': ['Cleaning affected parts'],
      'biologicalControls': [],
      'possibleCauses': ['Presence of pests (e.g., mealybugs)', 'High humidity', 'Poor ventilation'],
      'preventiveMeasures': ['Control pest populations', 'Improve air circulation', 'Clean leaves'],
    },
    'Fusarium Root Rot': {
      'description': 'A soil-borne fungal disease that attacks the roots and lower stems of coffee plants.',
      'symptoms': 'Wilting, yellowing, and dieback of plants, with roots showing signs of rotting.',
      'chemicalControls': ['Thiophanate methyl', 'Carbendazim'],
      'mechanicalControls': ['Proper drainage', 'Removal of infected plants'],
      'biologicalControls': [],
      'possibleCauses': ['Wet soil', 'Poor drainage', 'Contaminated soil'],
      'preventiveMeasures': ['Enhance drainage', 'Rotate crops', 'Remove infected plants'],
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _updateDiseaseDetails() {
    if (_selectedDisease != null && _diseaseDetails.containsKey(_selectedDisease!)) {
      setState(() {
        _diseaseData = CoffeeDiseaseData(
          name: _selectedDisease!,
          description: _diseaseDetails[_selectedDisease!]!['description'],
          symptoms: _diseaseDetails[_selectedDisease!]!['symptoms'],
          chemicalControls: List<String>.from(_diseaseDetails[_selectedDisease!]!['chemicalControls']),
          mechanicalControls: List<String>.from(_diseaseDetails[_selectedDisease!]!['mechanicalControls']),
          biologicalControls: List<String>.from(_diseaseDetails[_selectedDisease!]!['biologicalControls']),
          possibleCauses: List<String>.from(_diseaseDetails[_selectedDisease!]!['possibleCauses']),
          preventiveMeasures: List<String>.from(_diseaseDetails[_selectedDisease!]!['preventiveMeasures']),
        );
      });
    }
  }

  void _scrollToHints() {
    if (_showDiseaseDetails && _hintsKey.currentContext != null) {
      final RenderBox box = _hintsKey.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero).dy + _scrollController.offset - 100;
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Disease Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown('Coffee Stage', _stages, _selectedStage, (val) {
                setState(() {
                  _selectedStage = val;
                  _selectedDisease = null;
                  _diseaseData = null;
                  _showDiseaseDetails = false;
                });
              }),
              const SizedBox(height: 16),
              _buildDropdown('Select Disease', _selectedStage != null ? _stageDiseases[_selectedStage]! : [], _selectedDisease, (val) {
                setState(() {
                  _selectedDisease = val;
                  _updateDiseaseDetails();
                  _showDiseaseDetails = false;
                });
              }),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (_diseaseData != null) {
                    setState(() {
                      _showDiseaseDetails = !_showDiseaseDetails;
                      if (_showDiseaseDetails) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHints());
                      }
                    });
                  } else {
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please select a disease first')));
                  }
                },
                child: const Text(
                  'View Disease Management Details',
                  style: TextStyle(
                    color: Color(0xFF6F4E37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CoffeeUserDiseaseHistoryPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F4E37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('View My Disease History'),
              ),
              if (_showDiseaseDetails && _diseaseData != null) ...[
                const SizedBox(height: 8),
                Column(
                  key: _hintsKey,
                  children: [
                    _buildHintCard('Description', _diseaseData!.description, Icons.info),
                    _buildHintCard('Symptoms', _diseaseData!.symptoms, Icons.warning),
                    _buildHintCard('Chemical Controls', _diseaseData!.chemicalControls.join('\n'), Icons.science),
                    _buildHintCard('Mechanical Controls', _diseaseData!.mechanicalControls.isEmpty ? 'None' : _diseaseData!.mechanicalControls.join('\n'), Icons.build),
                    _buildHintCard('Biological Controls', _diseaseData!.biologicalControls.isEmpty ? 'None' : _diseaseData!.biologicalControls.join('\n'), Icons.eco),
                    _buildHintCard('Possible Causes', _diseaseData!.possibleCauses.join('\n'), Icons.search),
                    _buildHintCard('Preventive Measures', _diseaseData!.preventiveMeasures.join('\n'), Icons.shield),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CoffeeDiseaseInterventionPage(
                                diseaseData: _diseaseData!,
                                cropStage: _selectedStage ?? '',
                                notificationsPlugin: _notificationsPlugin,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F4E37),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Manage Disease'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHintCard(String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF6F4E37), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(content, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}