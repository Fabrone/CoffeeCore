import 'package:coffeecore/screens/Pest%20Management/coffee_pest_management_page.dart';
import 'package:flutter/material.dart';

class CoffeePestSymptomAnalysisPage extends StatefulWidget {
  final Map<String, List<String>> selectedSymptoms;

  const CoffeePestSymptomAnalysisPage({required this.selectedSymptoms, super.key});

  @override
  State<CoffeePestSymptomAnalysisPage> createState() => _CoffeePestSymptomAnalysisPageState();
}

class _CoffeePestSymptomAnalysisPageState extends State<CoffeePestSymptomAnalysisPage> {
  static final Color coffeeBrown = Colors.brown[700]!;
  static final Color backgroundColor = Colors.brown[50]!;
  bool _isLoading = false;
  Map<String, List<bool>> additionalSymptoms = {};
  Map<String, List<Map<String, dynamic>>> filteredPestSymptoms = {};
  Map<String, List<String>> allSelectedSymptoms = {};
  List<String> matchingPests = []; // Store closely matching pests

  // Comprehensive pest symptoms, organized by plant section, with weights and clusters
  final Map<String, Map<String, List<Map<String, dynamic>>>> pestSymptoms = {
    'Coffee Berry Borer': {
      'Fruits': [
        {'symptom': 'Small entry holes in coffee cherries', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Larvae inside cherries, often with frass', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Premature fruit drop with tiny holes', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Small beetles in cherries', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Powdery frass in cherry cavities', 'weight': 0.8, 'cluster': 'unique'},
      ],
    },
    'Coffee Leaf Miner': {
      'Leaves': [
        {'symptom': 'Silvery tunnels or trails on leaves', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Leaves with irregular, winding patterns', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Premature leaf drop with miner damage', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Tiny larvae visible inside leaf tissue', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Yellowing leaves with serpentine trails', 'weight': 0.8, 'cluster': 'unique'},
      ],
    },
    'Coffee Antestia Bug': {
      'Fruits': [
        {'symptom': 'Deformed or discolored cherries', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Tiny insects on fruit surfaces', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Premature fruit drop due to sap-sucking', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Blackened spots on cherries', 'weight': 0.6, 'cluster': 'shared'},
      ],
      'Leaves': [
        {'symptom': 'Sticky honeydew on leaves', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Ants attracted to leaves', 'weight': 0.6, 'cluster': 'shared'},
      ],
    },
    'Coffee Stem Borer': {
      'Stems/Branches': [
        {'symptom': 'Small holes bored into stems', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Sawdust-like frass around stem base', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Visible larvae inside stems', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Weakened or snapping branches', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Hollowed-out stem interiors', 'weight': 0.8, 'cluster': 'unique'},
      ],
      'Leaves': [
        {'symptom': 'Yellowing leaves above bored stems', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Wilting leaves above affected stems', 'weight': 0.7, 'cluster': 'shared'},
      ],
    },
    'Root-Knot Nematodes': {
      'Roots': [
        {'symptom': 'Swollen or knotted roots', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Wilting despite adequate watering', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Tiny worms in soil near roots', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Yellowing lower leaves', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Stunted root growth', 'weight': 0.8, 'cluster': 'unique'},
      ],
    },
    'White Flies': {
      'Leaves': [
        {'symptom': 'Tiny white insects under leaves', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Sticky honeydew with ants present', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Leaves curling or yellowing', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Sooty mold on leaf surfaces', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Cloud of white insects when plant is disturbed', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Premature leaf drop', 'weight': 0.6, 'cluster': 'shared'},
      ],
    },
    'Coffee Mealybug': {
      'Leaves': [
        {'symptom': 'White, waxy insects on leaves', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Sticky honeydew and sooty mold', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Leaves curling or wilting', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Ants tending mealybugs', 'weight': 0.8, 'cluster': 'unique'},
        {'symptom': 'Cotton-like masses on leaves', 'weight': 0.9, 'cluster': 'unique'},
      ],
      'Stems/Branches': [
        {'symptom': 'White, waxy insects on stems', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Cotton-like masses on stems', 'weight': 0.9, 'cluster': 'unique'},
      ],
    },
    'Caterpillars': {
      'Leaves': [
        {'symptom': 'Irregular holes in leaves', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Skeletonized leaves with veins intact', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Visible caterpillars on leaves', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Silk threads on leaves', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Fecal pellets on leaves', 'weight': 0.8, 'cluster': 'unique'},
      ],
      'Fruits': [
        {'symptom': 'Irregular holes in fruits', 'weight': 0.7, 'cluster': 'shared'},
      ],
      'Flowers': [
        {'symptom': 'Chewed flower buds', 'weight': 0.7, 'cluster': 'shared'},
      ],
    },
    'Coffee Weevil': {
      'Fruits': [
        {'symptom': 'Small holes in stored coffee beans', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Damaged or hollowed-out beans', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Presence of weevils in storage', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Powdery debris in storage', 'weight': 0.8, 'cluster': 'unique'},
        {'symptom': 'Infested beans with larvae', 'weight': 0.9, 'cluster': 'unique'},
      ],
    },
    'Ants': {
      'Leaves': [
        {'symptom': 'Presence of ants tending pests', 'weight': 0.8, 'cluster': 'unique'},
        {'symptom': 'Sticky honeydew on leaves', 'weight': 0.6, 'cluster': 'shared'},
      ],
      'Fruits': [
        {'symptom': 'Sticky honeydew on fruits', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Ant trails on fruits', 'weight': 0.7, 'cluster': 'unique'},
      ],
      'Stems/Branches': [
        {'symptom': 'Ant trails on plant stems', 'weight': 0.7, 'cluster': 'unique'},
      ],
    },
    'Scale Insects': {
      'Leaves': [
        {'symptom': 'Small, flat, oval insects on leaves', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Sticky honeydew on leaves', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Yellowing or wilting leaves', 'weight': 0.6, 'cluster': 'shared'},
        {'symptom': 'Sooty mold from sap-sucking', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Discolored spots under scales', 'weight': 0.7, 'cluster': 'unique'},
      ],
      'Stems/Branches': [
        {'symptom': 'Small, flat, oval insects on stems', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Hard, waxy shells on stems', 'weight': 0.9, 'cluster': 'unique'},
      ],
    },
    'Thrips': {
      'Leaves': [
        {'symptom': 'Silvering or bronzing of leaves', 'weight': 0.9, 'cluster': 'unique'},
        {'symptom': 'Tiny, slender insects on leaves', 'weight': 1.0, 'cluster': 'unique'},
        {'symptom': 'Black fecal spots on leaves', 'weight': 0.8, 'cluster': 'unique'},
        {'symptom': 'Premature leaf drop', 'weight': 0.6, 'cluster': 'shared'},
      ],
      'Fruits': [
        {'symptom': 'Distorted or scarred fruit surfaces', 'weight': 0.8, 'cluster': 'shared'},
      ],
      'Flowers': [
        {'symptom': 'Deformed flower buds', 'weight': 0.7, 'cluster': 'shared'},
        {'symptom': 'Tiny, slender insects on flowers', 'weight': 1.0, 'cluster': 'unique'},
      ],
    },
  };

  // Coffee stages for inference
  final Map<String, List<String>> _stagePests = {
    'Vegetative Stage': [
      'Coffee Leaf Miner',
      'Coffee Stem Borer',
      'Root-Knot Nematodes',
      'White Flies',
      'Coffee Mealybug',
      'Caterpillars',
      'Ants',
      'Scale Insects',
      'Thrips',
    ],
    'Flowering & Fruit Development': [
      'Coffee Berry Borer',
      'Coffee Antestia Bug',
      'White Flies',
      'Coffee Mealybug',
      'Caterpillars',
      'Ants',
      'Scale Insects',
      'Thrips',
    ],
    'Post-harvest / Storage': ['Coffee Weevil'],
  };

  @override
  void initState() {
    super.initState();
    allSelectedSymptoms = Map.from(widget.selectedSymptoms);
    _initializeAdditionalSymptoms();
  }

  void _initializeAdditionalSymptoms() {
    // Identify pests with at least one matching symptom
    matchingPests = [];
    for (var pest in pestSymptoms.keys) {
      bool hasMatch = false;
      for (var section in allSelectedSymptoms.keys) {
        if (pestSymptoms[pest]!.containsKey(section)) {
          for (var symptom in allSelectedSymptoms[section]!) {
            if (pestSymptoms[pest]![section]!.any((s) => s['symptom'] == symptom)) {
              hasMatch = true;
              break;
            }
          }
        }
        if (hasMatch) break;
      }
      if (hasMatch) {
        matchingPests.add(pest);
      }
    }

    // Initialize additional symptoms for matching pests
    filteredPestSymptoms = {};
    for (var pest in matchingPests) {
      for (var section in pestSymptoms[pest]!.keys) {
        if (!filteredPestSymptoms.containsKey(section)) {
          filteredPestSymptoms[section] = [];
        }
        var additional = pestSymptoms[pest]![section]!.where((s) => !allSelectedSymptoms[section]!.contains(s['symptom'])).toList();
        filteredPestSymptoms[section]!.addAll(additional);
      }
    }

    // Remove duplicate symptoms and ensure non-empty sections
    for (var section in filteredPestSymptoms.keys.toList()) {
      filteredPestSymptoms[section] = filteredPestSymptoms[section]!.toSet().toList();
      if (filteredPestSymptoms[section]!.isEmpty) {
        filteredPestSymptoms.remove(section);
      }
    }

    // Initialize checkbox states
    for (var section in filteredPestSymptoms.keys) {
      additionalSymptoms[section] = List.filled(filteredPestSymptoms[section]!.length, false);
    }
  }

  void _resetSymptoms() {
    setState(() {
      for (var section in additionalSymptoms.keys) {
        additionalSymptoms[section] = List.filled(additionalSymptoms[section]!.length, false);
      }
    });
  }

  void _analyzePests() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    // Update allSelectedSymptoms with additional symptoms
    allSelectedSymptoms = Map.from(widget.selectedSymptoms);
    for (var section in filteredPestSymptoms.keys) {
      if (!allSelectedSymptoms.containsKey(section)) {
        allSelectedSymptoms[section] = [];
      }
      for (int i = 0; i < filteredPestSymptoms[section]!.length; i++) {
        if (additionalSymptoms[section]![i]) {
          allSelectedSymptoms[section]!.add(filteredPestSymptoms[section]![i]['symptom']);
        }
      }
    }

    // Analyze pests
    Map<String, Map<String, dynamic>> pestMatches = {};
    for (var pest in pestSymptoms.keys) {
      double score = 0.0;
      List<String> matchedSymptoms = [];
      for (var section in pestSymptoms[pest]!.keys) {
        for (var symptom in allSelectedSymptoms[section] ?? []) {
          var matchingSymptom = pestSymptoms[pest]![section]!.firstWhere(
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
        double maxScore = pestSymptoms[pest]!.values.fold(0.0, (sum, symptoms) => sum + symptoms.fold(0.0, (s, sym) => s + (sym['cluster'] == 'unique' ? sym['weight'] * 1.2 : sym['weight'])));
        pestMatches[pest] = {
          'score': score,
          'matchedSymptoms': matchedSymptoms,
          'confidence': (score / maxScore) * 100,
        };
      }
    }

    if (pestMatches.isEmpty) {
      _showResult('No specific pest identified. Explore pest management options.', [], null, null);
      setState(() => _isLoading = false);
      return;
    }

    var sortedPests = pestMatches.entries.toList()
      ..sort((a, b) => b.value['score'].compareTo(a.value['score']));
    var topPests = sortedPests.take(3).toList();

    // Update matching pests for display
    matchingPests = topPests.map((e) => e.key).toList();

    // Check if a single pest is dominant
    bool isConclusive = topPests.length == 1 || (topPests.length > 1 && topPests[0].value['score'] > topPests[1].value['score'] * 1.2);

    if (isConclusive) {
      StringBuffer resultMessage = StringBuffer();
      List<Widget> navigationButtons = [];
      var pestEntry = topPests[0];
      String pest = pestEntry.key;
      double score = pestEntry.value['score'];
      double confidence = pestEntry.value['confidence'];
      List<String> matchedSymptoms = pestEntry.value['matchedSymptoms'];
      resultMessage.writeln('Top Matching Pest:');
      resultMessage.writeln('$pest (Score: ${score.toStringAsFixed(1)}, Confidence: ${confidence.toStringAsFixed(1)}%)');
      resultMessage.writeln('Matching Symptoms:');
      for (var symptom in matchedSymptoms) {
        resultMessage.writeln('  • $symptom');
      }
      // Infer coffee stage
      String? coffeeStage;
      for (var stage in _stagePests.keys) {
        if (_stagePests[stage]!.contains(pest)) {
          coffeeStage = stage;
          break;
        }
      }
      navigationButtons.add(
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoffeePestManagementPage(
                pestName: pest,
                coffeeStage: coffeeStage,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: coffeeBrown,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Manage $pest'),
        ),
      );
      _showResult(resultMessage.toString(), navigationButtons, pest, coffeeStage);
    } else {
      // Inconclusive: show additional symptoms for top pests
      filteredPestSymptoms = {};
      for (var pest in matchingPests) {
        for (var section in pestSymptoms[pest]!.keys) {
          if (!filteredPestSymptoms.containsKey(section)) {
            filteredPestSymptoms[section] = [];
          }
          var additional = pestSymptoms[pest]![section]!.where((s) => !allSelectedSymptoms[section]!.contains(s['symptom'])).toList();
          filteredPestSymptoms[section]!.addAll(additional);
        }
      }
      // Remove duplicates and empty sections
      for (var section in filteredPestSymptoms.keys.toList()) {
        filteredPestSymptoms[section] = filteredPestSymptoms[section]!.toSet().toList();
        if (filteredPestSymptoms[section]!.isEmpty) {
          filteredPestSymptoms.remove(section);
        }
      }
      for (var section in filteredPestSymptoms.keys) {
        additionalSymptoms[section] = List.filled(filteredPestSymptoms[section]!.length, false);
      }

      StringBuffer resultMessage = StringBuffer();
      List<Widget> navigationButtons = [];
      resultMessage.writeln('Multiple pests match the symptoms:');
      for (var pestEntry in topPests) {
        String pest = pestEntry.key;
        double score = pestEntry.value['score'];
        double confidence = pestEntry.value['confidence'];
        List<String> matchedSymptoms = pestEntry.value['matchedSymptoms'];
        resultMessage.writeln('$pest (Score: ${score.toStringAsFixed(1)}, Confidence: ${confidence.toStringAsFixed(1)}%)');
        resultMessage.writeln('Matching Symptoms:');
        for (var symptom in matchedSymptoms) {
          resultMessage.writeln('  • $symptom');
        }
        resultMessage.writeln();
      }
      if (filteredPestSymptoms.isEmpty) {
        resultMessage.writeln('No additional symptoms available to narrow down the pest.');
        resultMessage.writeln('Explore pest management for the identified pests or select different symptoms.');
        navigationButtons.add(
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CoffeePestManagementPage()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: coffeeBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Explore Pest Management'),
          ),
        );
      } else {
        resultMessage.writeln('Select additional symptoms below to narrow down the pest.');
        navigationButtons.add(
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                _analyzePests(); // Re-run analysis
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

  void _showResult(String message, List<Widget> navigationButtons, String? topPest, String? coffeeStage) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pest Analysis Result', style: TextStyle(fontWeight: FontWeight.bold)),
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
          'Pest Symptom Analysis',
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
                    'Closely Matching Pests',
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
                        children: matchingPests.isEmpty
                            ? [
                                const Text(
                                  'No pests identified yet. Select symptoms to analyze.',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ]
                            : matchingPests.map((pest) => Text('• $pest', style: const TextStyle(fontSize: 14))).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Additional Symptoms for Deeper Analysis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: coffeeBrown),
                  ),
                  const SizedBox(height: 8),
                  if (filteredPestSymptoms.isEmpty)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'No additional symptoms available. Try exploring pest management or selecting different symptoms.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ...filteredPestSymptoms.entries.map((entry) {
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
        onPressed: _isLoading ? null : _analyzePests,
        backgroundColor: coffeeBrown,
        tooltip: 'Analyze Pests',
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }
}