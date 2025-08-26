import 'dart:async';
import 'package:coffeecore/screens/Disease%20Management/coffee_disease_intervention_page.dart';
import 'package:coffeecore/screens/Disease%20Management/coffee_user_disease_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:coffeecore/models/coffee_disease_models.dart';

class CoffeeDiseaseManagementPage extends StatefulWidget {
  final String? diseaseName;
  final String? coffeeStage;

  const CoffeeDiseaseManagementPage({this.diseaseName, this.coffeeStage, super.key});

  @override
  State<CoffeeDiseaseManagementPage> createState() => _CoffeeDiseaseManagementPageState();
}

class _CoffeeDiseaseManagementPageState extends State<CoffeeDiseaseManagementPage> {
  static final Color coffeeBrown = Colors.brown[700]!;
  static final Color backgroundColor = Colors.brown[50]!;
  String? _selectedStage;
  String? _selectedDisease;
  CoffeeDiseaseData? _diseaseData;
  bool _showDiseaseDetails = false;
  bool _isLoading = false;
  Map<String, List<bool>> additionalSymptoms = {};
  Map<String, List<Map<String, dynamic>>> filteredDiseaseSymptoms = {};
  Map<String, List<String>> allSelectedSymptoms = {};
  List<String> matchingDiseases = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _hintsKey = GlobalKey();

  final List<String> _stages = [
    'Vegetative Stage',
    'Flowering & Fruit Development',
    'Post-harvest / Storage',
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
      'Coffee Berry Disease',
      'Anthracnose',
      'Coffee Sooty Mold',
      'Bacterial Blight',
    ],
    'Post-harvest / Storage': [],
  };

  // Disease symptoms for iterative analysis (from CoffeeDiseaseSymptomAnalysisPage)
  final Map<String, Map<String, List<Map<String, dynamic>>>> diseaseSymptoms = {
    'Coffee Leaf Rust': {
      'Leaves': [
        {'symptom': 'Orange-yellow rust spots on leaf undersides', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Premature leaf drop with no pest signs', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Reduced photosynthesis from leaf damage', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Spots spreading in humid conditions', 'weight': 0.8, 'cluster': 'unique'},
      ],
    },
    'Coffee Wilt Disease': {
      'Roots': [
        {'symptom': 'Blackened or rotten roots', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Dark streaks at stem base', 'weight': 0.9, 'cluster': 'unique'},
      ],
      'Leaves': [
        {'symptom': 'Yellowing leaves with no pest damage', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Plant collapses suddenly', 'weight': 0.9, 'cluster': 'unique'},
      ],
    },
    'Coffee Berry Disease': {
      'Fruits': [
        {'symptom': 'Black, sunken lesions on cherries', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Premature fruit drop with fungal signs', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Rotting cherries with no insect holes', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Spots worsening in wet weather', 'weight': 0.8, 'cluster': 'unique'},
      ],
    },
    'Cercospora Leaf Spot': {
      'Leaves': [
        {'symptom': 'Black or brown spots with yellow halos', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Premature leaf drop with no insects', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Spots on leaves in humid conditions', 'weight': 0.8, 'cluster': 'unique'},
        {'symptom': 'Reduced leaf vigor', 'weight': 0.6, 'cluster': 'shared'},
      ],
    },
    'Brown Eye Spot': {
      'Leaves': [
        {'symptom': 'Round brown spots with yellow halos', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Leaves dropping early without pest marks', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Spots on leaves in wet seasons', 'weight': 0.8, 'cluster': 'unique'},
        {'symptom': 'No insect activity visible', 'weight': 0.6, 'cluster': 'shared'},
      ],
    },
    'Anthracnose': {
      'Fruits': [
        {'symptom': 'Fruit cracking with dark lesions', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Sunken, black spots on cherries', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Rotting fruits with no pest entry', 'weight': 0.9, 'cluster': 'unique'},
      ],
      'Stems/Branches': [
        {'symptom': 'Branch lesions in severe cases', 'weight': 0.8, 'cluster': 'unique'},
      ],
    },
    'Phytophthora Root Rot': {
      'Roots': [
        {'symptom': 'Soft, mushy roots with a foul smell', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Stunted growth in wet conditions', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'No pest larvae in roots', 'weight': 0.6, 'cluster': 'shared'},
      ],
      'Leaves': [
        {'symptom': 'Yellowing leaves with root decay', 'weight': 0.7, 'cluster': 'shared'},
      ],
    },
    'Bacterial Blight': {
      'Leaves': [
        {'symptom': 'Water-soaked, wilting leaves', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Dark lesions on leaves', 'weight': 0.8, 'cluster': 'shared'},
      ],
      'Stems/Branches': [
        {'symptom': 'Oozing sap from stems', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Dark lesions on stems', 'weight': 0.8, 'cluster': 'shared'},
        {'symptom': 'Rapid wilting in wet weather', 'weight': 0.8, 'cluster': 'unique'},
      ],
    },
    'Coffee Sooty Mold': {
      'Leaves': [
        {'symptom': 'Sooty black mold on leaf surfaces', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Sticky honeydew with fungal growth', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Reduced photosynthesis, no direct pest damage', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Mold linked to pest activity', 'weight': 0.8, 'cluster': 'unique'},
      ],
    },
    'Fusarium Root Rot': {
      'Roots': [
        {'symptom': 'Blackened or rotten roots', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Brittle stems near base', 'weight': 0.9, 'cluster': 'unique'},
      ],
      'Leaves': [
        {'symptom': 'Yellowing leaves from root decay', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Wilting with no pest signs', 'weight': 0.7, 'cluster': 'shared'},
      ],
    },
  };

  // Disease details (same as original)
  final Map<String, Map<String, dynamic>> _diseaseDetails = {
    'Coffee Leaf Rust': {
      'description': 'A fungal disease that primarily affects the leaves of coffee plants.',
      'symptoms': 'Orange-yellow spots on the underside of leaves, leaf drop.',
      'chemicalControls': ['Copper-based', 'Trifloxystrobin', 'Tebuconazole'],
      'mechanicalControls': ['Pruning of infected leaves'],
      'biologicalControls': ['Resistant varieties (e.g., SL28)'],
      'possibleCauses': ['High humidity', 'Warm temperatures (20-28°C)', 'Dense foliage'],
      'preventiveMeasures': ['Improve air circulation', 'Apply mulch', 'Use resistant varieties'],
      'lifecycleImages': [
        'assets/diseases/coffee_leaf_rust1.png',
        'assets/diseases/coffee_leaf_rust2.png',
        'assets/diseases/coffee_leaf_rust3.png',
        'assets/diseases/coffee_leaf_rust4.png',
      ],
    },
    'Coffee Wilt Disease': {
      'description': 'A soil-borne fungal infection that causes rapid wilting and death of coffee plants.',
      'symptoms': 'Sudden wilting, yellowing of leaves, and rotting of roots.',
      'chemicalControls': ['Thiophanate methyl', 'Carbendazim'],
      'mechanicalControls': ['Removal of infected plants'],
      'biologicalControls': ['Soil sterilization'],
      'possibleCauses': ['Wet soil', 'Poor drainage', 'Contaminated tools'],
      'preventiveMeasures': ['Improve drainage', 'Sanitize tools', 'Avoid overwatering'],
      'lifecycleImages': [
        'assets/diseases/coffee_wilt_disease1.png',
        'assets/diseases/coffee_wilt_disease2.png',
        'assets/diseases/coffee_wilt_disease3.png',
        'assets/diseases/coffee_wilt_disease4.png',
      ],
    },
    'Coffee Berry Disease': {
      'description': 'A fungal disease that causes dark lesions on coffee berries.',
      'symptoms': 'Black lesions on coffee cherries, premature fruit drop.',
      'chemicalControls': ['Azoxystrobin', 'Tebuconazole', 'Difenoconazole'],
      'mechanicalControls': ['Pruning and sanitation'],
      'biologicalControls': [],
      'possibleCauses': ['High rainfall', 'Warm temperatures', 'Poor sanitation'],
      'preventiveMeasures': ['Regular pruning', 'Remove fallen berries', 'Improve air flow'],
      'lifecycleImages': [
        'assets/diseases/coffee_berry_disease1.png',
        'assets/diseases/coffee_berry_disease2.png',
        'assets/diseases/coffee_berry_disease3.png',
        'assets/diseases/coffee_berry_disease4.png',
        'assets/diseases/coffee_berry_disease5.png',
        'assets/diseases/coffee_berry_disease6.png',
        'assets/diseases/coffee_berry_disease7.png',
        'assets/diseases/coffee_berry_disease8.png',
      ],
    },
    'Cercospora Leaf Spot': {
      'description': 'A fungal disease that affects coffee leaves.',
      'symptoms': 'Dark brown to black lesions with yellow halos on the leaves.',
      'chemicalControls': ['Chlorothalonil', 'Mancozeb', 'Copper-based'],
      'mechanicalControls': ['Pruning of infected leaves'],
      'biologicalControls': [],
      'possibleCauses': ['High humidity', 'Overcrowded plants', 'Nutrient deficiency'],
      'preventiveMeasures': ['Balance fertilization', 'Prune regularly', 'Avoid overhead watering'],
      'lifecycleImages': [
        'assets/diseases/cercospora_leaf_spot1.png',
        'assets/diseases/cercospora_leaf_spot2.png',
        'assets/diseases/cercospora_leaf_spot3.png',
        'assets/diseases/cercospora_leaf_spot4.png',
      ],
    },
    'Brown Eye Spot': {
      'description': 'A form of Cercospora disease affecting coffee plants.',
      'symptoms': 'Round brown lesions surrounded by yellow halos, premature leaf drop.',
      'chemicalControls': ['Mancozeb', 'Chlorothalonil', 'Copper-based'],
      'mechanicalControls': ['Removal of infected leaves'],
      'biologicalControls': [],
      'possibleCauses': ['Wet conditions', 'Poor air circulation', 'Nutrient imbalance'],
      'preventiveMeasures': ['Improve ventilation', 'Monitor soil nutrients', 'Remove debris'],
      'lifecycleImages': [
        'assets/diseases/brown_eye_spot1.png',
        'assets/diseases/brown_eye_spot2.png',
        'assets/diseases/brown_eye_spot3.png',
        'assets/diseases/brown_eye_spot4.png',
      ],
    },
    'Anthracnose': {
      'description': 'A fungal disease that affects coffee fruits, causing lesions and decay.',
      'symptoms': 'Sunken, dark lesions on fruit and branches.',
      'chemicalControls': ['Azoxystrobin', 'Tebuconazole', 'Difenoconazole'],
      'mechanicalControls': ['Removal of affected fruit'],
      'biologicalControls': [],
      'possibleCauses': ['High rainfall', 'Warm weather', 'Injured fruit'],
      'preventiveMeasures': ['Harvest carefully', 'Sanitize tools', 'Prune affected areas'],
      'lifecycleImages': [
        'assets/diseases/anthracnose1.png',
        'assets/diseases/anthracnose2.png',
        'assets/diseases/anthracnose3.png',
        'assets/diseases/anthracnose4.png',
        'assets/diseases/anthracnose5.png',
        'assets/diseases/anthracnose6.png',
      ],
    },
    'Phytophthora Root Rot': {
      'description': 'A waterborne pathogen that attacks the roots of coffee plants, causing rot.',
      'symptoms': 'Yellowing of leaves, stunted growth, root decay, and poor plant vigor.',
      'chemicalControls': ['Metalaxyl', 'Phosphonates'],
      'mechanicalControls': ['Proper drainage to avoid waterlogging'],
      'biologicalControls': [],
      'possibleCauses': ['Excessive water', 'Poor drainage', 'High rainfall'],
      'preventiveMeasures': ['Improve soil drainage', 'Avoid planting in low areas', 'Mulch roots'],
      'lifecycleImages': [
        'assets/diseases/phytophthora_root_rot1.png',
        'assets/diseases/phytophthora_root_rot2.png',
        'assets/diseases/phytophthora_root_rot3.png',
        'assets/diseases/phytophthora_root_rot4.png',
        'assets/diseases/phytophthora_root_rot5.png',
        'assets/diseases/phytophthora_root_rot6.png',
        'assets/diseases/phytophthora_root_rot7.png',
      ],
    },
    'Bacterial Blight': {
      'description': 'A bacterial infection that affects the coffee plant.',
      'symptoms': 'Water-soaked lesions on leaves and stems, leading to wilting.',
      'chemicalControls': ['Copper-based bactericides'],
      'mechanicalControls': ['Removal of infected plant parts'],
      'biologicalControls': [],
      'possibleCauses': ['Wet conditions', 'Wounds from pruning', 'Contaminated tools'],
      'preventiveMeasures': ['Sanitize equipment', 'Avoid overhead irrigation', 'Prune in dry weather'],
      'lifecycleImages': [
        'assets/diseases/bacterial_blight1.png',
        'assets/diseases/bacterial_blight2.png',
        'assets/diseases/bacterial_blight3.png',
        'assets/diseases/bacterial_blight4.png',
      ],
    },
    'Coffee Sooty Mold': {
      'description': 'A fungal disease caused by mold growing on honeydew from sap-sucking insects.',
      'symptoms': 'Black sooty growth on leaves and branches, reduced photosynthesis.',
      'chemicalControls': ['Insecticides (for sap-sucking pests)'],
      'mechanicalControls': ['Cleaning affected parts'],
      'biologicalControls': [],
      'possibleCauses': ['Presence of pests (e.g., mealybugs)', 'High humidity', 'Poor ventilation'],
      'preventiveMeasures': ['Control pest populations', 'Improve air circulation', 'Clean leaves'],
      'lifecycleImages': [
        'assets/diseases/coffee_sooty_mold1.png',
        'assets/diseases/coffee_sooty_mold2.png',
        'assets/diseases/coffee_sooty_mold3.png',
        'assets/diseases/coffee_sooty_mold4.png',
        'assets/diseases/coffee_sooty_mold5.png',
        'assets/diseases/coffee_sooty_mold6.png',
        'assets/diseases/coffee_sooty_mold7.png',
      ],
    },
    'Fusarium Root Rot': {
      'description': 'A soil-borne fungal disease that attacks the roots and lower stems of coffee plants.',
      'symptoms': 'Wilting, yellowing, and dieback of plants, with roots showing signs of rotting.',
      'chemicalControls': ['Thiophanate methyl', 'Carbendazim'],
      'mechanicalControls': ['Proper drainage', 'Removal of infected plants'],
      'biologicalControls': [],
      'possibleCauses': ['Wet soil', 'Poor drainage', 'Contaminated soil'],
      'preventiveMeasures': ['Enhance drainage', 'Rotate crops', 'Remove infected plants'],
      'lifecycleImages': [
        'assets/diseases/fusarium_root_rot1.png',
        'assets/diseases/fusarium_root_rot2.png',
        'assets/diseases/fusarium_root_rot3.png',
        'assets/diseases/fusarium_root_rot4.png',
        'assets/diseases/fusarium_root_rot5.png',
        'assets/diseases/fusarium_root_rot6.png',
        'assets/diseases/fusarium_root_rot7.png',
        'assets/diseases/fusarium_root_rot8.png',
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _selectedStage = widget.coffeeStage;
    _selectedDisease = widget.diseaseName;
    if (_selectedDisease != null) {
      _updateDiseaseDetails();
      _showDiseaseDetails = true; // Auto-show details if disease is pre-selected
    }
    _initializeAdditionalSymptoms();
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

  void _initializeAdditionalSymptoms() {
    if (_selectedDisease == null) {
      // Identify diseases with at least one matching symptom (if any provided)
      matchingDiseases = [];
      for (var disease in diseaseSymptoms.keys) {
        bool hasMatch = false;
        for (var section in allSelectedSymptoms.keys) {
          if (diseaseSymptoms[disease]!.containsKey(section)) {
            for (var symptom in allSelectedSymptoms[section]!) {
              if (diseaseSymptoms[disease]![section]!.any((s) => s['symptom'] == symptom)) {
                hasMatch = true;
                break;
              }
            }
          }
          if (hasMatch) break;
        }
        if (hasMatch) {
          matchingDiseases.add(disease);
        }
      }

      // Initialize additional symptoms for matching diseases
      filteredDiseaseSymptoms = {};
      for (var disease in matchingDiseases) {
        for (var section in diseaseSymptoms[disease]!.keys) {
          if (!filteredDiseaseSymptoms.containsKey(section)) {
            filteredDiseaseSymptoms[section] = [];
          }
          var additional = diseaseSymptoms[disease]![section]!.where((s) => !allSelectedSymptoms[section]!.contains(s['symptom'])).toList();
          filteredDiseaseSymptoms[section]!.addAll(additional);
        }
      }

      // Remove duplicate symptoms and ensure non-empty sections
      for (var section in filteredDiseaseSymptoms.keys.toList()) {
        filteredDiseaseSymptoms[section] = filteredDiseaseSymptoms[section]!.toSet().toList();
        if (filteredDiseaseSymptoms[section]!.isEmpty) {
          filteredDiseaseSymptoms.remove(section);
        }
      }

      // Initialize checkbox states
      for (var section in filteredDiseaseSymptoms.keys) {
        additionalSymptoms[section] = List.filled(filteredDiseaseSymptoms[section]!.length, false);
      }
    }
  }

  void _resetSymptoms() {
    setState(() {
      for (var section in additionalSymptoms.keys) {
        additionalSymptoms[section] = List.filled(additionalSymptoms[section]!.length, false);
      }
    });
  }

  void _analyzeDiseases() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    // Update allSelectedSymptoms with additional symptoms
    allSelectedSymptoms = {};
    for (var section in filteredDiseaseSymptoms.keys) {
      if (!allSelectedSymptoms.containsKey(section)) {
        allSelectedSymptoms[section] = [];
      }
      for (int i = 0; i < filteredDiseaseSymptoms[section]!.length; i++) {
        if (additionalSymptoms[section]![i]) {
          allSelectedSymptoms[section]!.add(filteredDiseaseSymptoms[section]![i]['symptom']);
        }
      }
    }

    // Analyze diseases
    Map<String, Map<String, dynamic>> diseaseMatches = {};
    for (var disease in diseaseSymptoms.keys) {
      double score = 0.0;
      List<String> matchedSymptoms = [];
      for (var section in diseaseSymptoms[disease]!.keys) {
        for (var symptom in allSelectedSymptoms[section] ?? []) {
          var matchingSymptom = diseaseSymptoms[disease]![section]!.firstWhere(
            (s) => s['symptom'] == symptom,
            orElse: () => {'symptom': '', 'weight': 0.0, 'cluster': ''},
          );
          if (matchingSymptom['symptom'].isNotEmpty) {
            double weight = matchingSymptom['weight'] as double;
            if (matchingSymptom['cluster'] == 'unique') {
              weight *= 1.2; // Boost unique symptoms
            }
            score += weight;
            matchedSymptoms.add('${matchingSymptom['symptom']} (${matchingSymptom['cluster']}, Weight: ${matchingSymptom['weight']})');
          }
        }
      }
      if (score > 0) {
        double maxScore = diseaseSymptoms[disease]!.values.fold(0.0, (sum, symptoms) => sum + symptoms.fold(0.0, (s, sym) => s + (sym['cluster'] == 'unique' ? sym['weight'] * 1.2 : sym['weight'])));
        diseaseMatches[disease] = {
          'score': score,
          'matchedSymptoms': matchedSymptoms,
          'confidence': (score / maxScore) * 100,
        };
      }
    }

    if (diseaseMatches.isEmpty) {
      _showResult('No specific disease identified. Explore disease management options.', [], null, null);
      setState(() => _isLoading = false);
      return;
    }

    var sortedDiseases = diseaseMatches.entries.toList()
      ..sort((a, b) => b.value['score'].compareTo(a.value['score']));
    var topDiseases = sortedDiseases.take(3).toList();

    // Update matching diseases for display
    matchingDiseases = topDiseases.map((e) => e.key).toList();

    // Check if a single disease is dominant
    bool isConclusive = topDiseases.length == 1 || (topDiseases.length > 1 && topDiseases[0].value['score'] > topDiseases[1].value['score'] * 1.2);

    if (isConclusive) {
      StringBuffer resultMessage = StringBuffer();
      List<Widget> navigationButtons = [];
      var diseaseEntry = topDiseases[0];
      String disease = diseaseEntry.key;
      double score = diseaseEntry.value['score'];
      double confidence = diseaseEntry.value['confidence'];
      List<String> matchedSymptoms = diseaseEntry.value['matchedSymptoms'];
      resultMessage.writeln('Top Matching Disease:');
      resultMessage.writeln('$disease (Score: ${score.toStringAsFixed(1)}, Confidence: ${confidence.toStringAsFixed(1)}%)');
      resultMessage.writeln('Matching Symptoms:');
      for (var symptom in matchedSymptoms) {
        resultMessage.writeln('  • $symptom');
      }
      // Infer coffee stage
      String? coffeeStage;
      for (var stage in _stageDiseases.keys) {
        if (_stageDiseases[stage]!.contains(disease)) {
          coffeeStage = stage;
          break;
        }
      }
      setState(() {
        _selectedDisease = disease;
        _selectedStage = coffeeStage;
        _updateDiseaseDetails();
        _showDiseaseDetails = true;
      });
      navigationButtons.add(
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHints());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: coffeeBrown,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('View $disease Details'),
        ),
      );
      _showResult(resultMessage.toString(), navigationButtons, disease, coffeeStage);
    } else {
      // Inconclusive: show additional symptoms for top diseases
      filteredDiseaseSymptoms = {};
      for (var disease in matchingDiseases) {
        for (var section in diseaseSymptoms[disease]!.keys) {
          if (!filteredDiseaseSymptoms.containsKey(section)) {
            filteredDiseaseSymptoms[section] = [];
          }
          var additional = diseaseSymptoms[disease]![section]!.where((s) => !allSelectedSymptoms[section]!.contains(s['symptom'])).toList();
          filteredDiseaseSymptoms[section]!.addAll(additional);
        }
      }
      // Remove duplicates and empty sections
      for (var section in filteredDiseaseSymptoms.keys.toList()) {
        filteredDiseaseSymptoms[section] = filteredDiseaseSymptoms[section]!.toSet().toList();
        if (filteredDiseaseSymptoms[section]!.isEmpty) {
          filteredDiseaseSymptoms.remove(section);
        }
      }
      for (var section in filteredDiseaseSymptoms.keys) {
        additionalSymptoms[section] = List.filled(filteredDiseaseSymptoms[section]!.length, false);
      }

      StringBuffer resultMessage = StringBuffer();
      List<Widget> navigationButtons = [];
      resultMessage.writeln('Multiple diseases match the symptoms:');
      for (var diseaseEntry in topDiseases) {
        String disease = diseaseEntry.key;
        double score = diseaseEntry.value['score'];
        double confidence = diseaseEntry.value['confidence'];
        List<String> matchedSymptoms = diseaseEntry.value['matchedSymptoms'];
        resultMessage.writeln('$disease (Score: ${score.toStringAsFixed(1)}, Confidence: ${confidence.toStringAsFixed(1)}%)');
        resultMessage.writeln('Matching Symptoms:');
        for (var symptom in matchedSymptoms) {
          resultMessage.writeln('  • $symptom');
        }
        resultMessage.writeln();
      }
      if (filteredDiseaseSymptoms.isEmpty) {
        resultMessage.writeln('No additional symptoms available to narrow down the disease.');
        resultMessage.writeln('Explore disease management for the identified diseases or select different symptoms.');
        navigationButtons.add(
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                _selectedDisease = null;
                _diseaseData = null;
                _showDiseaseDetails = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: coffeeBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Explore Disease Management'),
          ),
        );
      } else {
        resultMessage.writeln('Select additional symptoms below to narrow down the disease.');
        navigationButtons.add(
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                _analyzeDiseases(); // Re-run analysis
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: coffeeBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continue Analysis'),
          ),
        );
      }
      _showResult(resultMessage.toString(), navigationButtons, null, null);
    }

    setState(() => _isLoading = false);
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
          lifecycleImages: List<String>.from(_diseaseDetails[_selectedDisease!]!['lifecycleImages']),
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

  void _showResult(String message, List<Widget> navigationButtons, String? topDisease, String? coffeeStage) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disease Analysis Result', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analysis Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: coffeeBrown)),
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          actions: [
            ...navigationButtons,
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: coffeeBrown)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Disease Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: coffeeBrown,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            color: backgroundColor,
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedDisease == null) ...[
                    Text(
                      'Closely Matching Diseases',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: coffeeBrown),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: matchingDiseases.isEmpty
                              ? [
                                  const Text(
                                    'No diseases identified yet. Select a stage and disease or analyze symptoms.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ]
                              : matchingDiseases.map((disease) => Text('• $disease', style: const TextStyle(fontSize: 14))).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Additional Symptoms for Deeper Analysis',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: coffeeBrown),
                    ),
                    const SizedBox(height: 8),
                    if (filteredDiseaseSymptoms.isEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'No additional symptoms available. Try selecting a disease manually or exploring disease management.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                    else
                      ...filteredDiseaseSymptoms.entries.map((entry) {
                        String section = entry.key;
                        List<Map<String, dynamic>> symptoms = entry.value;
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: coffeeBrown),
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(symptoms.length, (index) {
                                  return CheckboxListTile(
                                    title: Text(symptoms[index]['symptom'], style: const TextStyle(fontSize: 14)),
                                    value: additionalSymptoms[section]![index],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        additionalSymptoms[section]![index] = value!;
                                      });
                                    },
                                    activeColor: coffeeBrown,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    dense: true,
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _resetSymptoms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: coffeeBrown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reset Additional Symptoms'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildDropdown('Coffee Stage', _stages, _selectedStage, (val) {
                    setState(() {
                      _selectedStage = val;
                      _selectedDisease = null;
                      _diseaseData = null;
                      _showDiseaseDetails = false;
                      _initializeAdditionalSymptoms();
                    });
                  }),
                  const SizedBox(height: 16),
                  _buildDropdown('Select Disease', _selectedStage != null ? _stageDiseases[_selectedStage]! : [], _selectedDisease, (val) {
                    setState(() {
                      _selectedDisease = val;
                      _updateDiseaseDetails();
                      _showDiseaseDetails = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHints());
                    });
                  }),
                  if (_diseaseData != null) ...[
                    const SizedBox(height: 16),
                    _buildLifecycleCarousel(_diseaseData!.lifecycleImages),
                  ],
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
                    child: Text(
                      _showDiseaseDetails ? 'Hide Disease Management Details' : 'View Disease Management Details',
                      style: TextStyle(
                        color: coffeeBrown,
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
                      backgroundColor: coffeeBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              backgroundColor: coffeeBrown,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Manage Disease'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(coffeeBrown)),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedDisease == null
          ? FloatingActionButton(
              onPressed: _isLoading ? null : _analyzeDiseases,
              backgroundColor: coffeeBrown,
              tooltip: 'Analyze Diseases',
              child: const Icon(Icons.search, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: coffeeBrown),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLifecycleCarousel(List<String> images) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Disease Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: coffeeBrown)),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.asset(
                      images[index],
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 120),
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

  Widget _buildHintCard(String title, String content, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: coffeeBrown, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: coffeeBrown)),
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