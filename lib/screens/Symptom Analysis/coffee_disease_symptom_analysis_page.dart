import 'package:coffeecore/screens/Disease%20Management/coffee_disease_management.dart';
import 'package:flutter/material.dart';

class CoffeeDiseaseSymptomAnalysisPage extends StatefulWidget {
  final Map<String, List<String>> selectedSymptoms;

  const CoffeeDiseaseSymptomAnalysisPage({required this.selectedSymptoms, super.key});

  @override
  State<CoffeeDiseaseSymptomAnalysisPage> createState() => _CoffeeDiseaseSymptomAnalysisPageState();
}

class _CoffeeDiseaseSymptomAnalysisPageState extends State<CoffeeDiseaseSymptomAnalysisPage> {
  static final Color coffeeBrown = Colors.brown[700]!;
  static final Color backgroundColor = Colors.brown[50]!;
  bool _isLoading = false;
  Map<String, List<bool>> additionalSymptoms = {};
  Map<String, List<Map<String, dynamic>>> filteredDiseaseSymptoms = {};
  Map<String, List<String>> allSelectedSymptoms = {};
  List<String> matchingDiseases = []; // Store closely matching diseases

  // Comprehensive disease symptoms, organized by plant section, with weights and clusters
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

  // Coffee stages for inference
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

  @override
  void initState() {
    super.initState();
    allSelectedSymptoms = Map.from(widget.selectedSymptoms);
    _initializeAdditionalSymptoms();
  }

  void _initializeAdditionalSymptoms() {
    // Identify diseases with at least one matching symptom
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
    allSelectedSymptoms = Map.from(widget.selectedSymptoms);
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
      navigationButtons.add(
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoffeeDiseaseManagementPage(
                diseaseName: disease,
                coffeeStage: coffeeStage,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: coffeeBrown,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Manage $disease'),
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CoffeeDiseaseManagementPage()),
            ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Disease Symptom Analysis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: coffeeBrown,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            color: backgroundColor,
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  'No diseases identified yet. Select symptoms to analyze.',
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
                          'No additional symptoms available. Try exploring disease management or selecting different symptoms.',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _analyzeDiseases,
        backgroundColor: coffeeBrown,
        tooltip: 'Analyze Diseases',
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }
}