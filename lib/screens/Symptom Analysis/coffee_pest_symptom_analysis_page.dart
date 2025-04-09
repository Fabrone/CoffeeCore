import 'package:coffeecore/screens/Pest%20Management/coffee_pest_management_page.dart';
import 'package:flutter/material.dart';

class CoffeePestSymptomAnalysisPage extends StatefulWidget {
  final Map<String, List<String>> selectedSymptoms;

  const CoffeePestSymptomAnalysisPage({required this.selectedSymptoms, super.key});

  @override
  State<CoffeePestSymptomAnalysisPage> createState() => _CoffeePestSymptomAnalysisPageState();
}

class _CoffeePestSymptomAnalysisPageState extends State<CoffeePestSymptomAnalysisPage> {
  bool _isLoading = false;

  // Detailed pest symptoms for deeper analysis
  final Map<String, List<String>> pestSymptoms = {
    'Coffee Berry Borer': [
      'Small entry holes in coffee cherries',
      'Larvae inside cherries, often with frass',
      'Premature fruit drop with tiny holes',
      'Discolored or damaged beans inside cherries',
    ],
    'Coffee Leaf Miner': [
      'Silvery tunnels or trails on leaves',
      'Leaves with irregular, winding patterns',
      'Premature leaf drop with miner damage',
      'Tiny larvae visible inside leaf tissue',
    ],
    'Coffee Antestia Bug': [
      'Deformed or discolored cherries',
      'Tiny insects on fruit surfaces',
      'Premature fruit drop due to sap-sucking',
      'Sticky honeydew on fruits or leaves',
    ],
    'Coffee Stem Borer': [
      'Small holes bored into stems',
      'Sawdust-like frass around stem base',
      'Visible larvae inside stems',
      'Weakened or snapping branches',
    ],
    'Root-Knot Nematodes': [
      'Swollen or knotted roots',
      'Wilting despite adequate watering',
      'Tiny worms in soil near roots',
      'Yellowing lower leaves',
    ],
    'White Flies': [
      'Tiny white insects under leaves',
      'Sticky honeydew with ants present',
      'Leaves curling or yellowing',
      'Sooty mold on leaf surfaces',
    ],
    'Coffee Mealybug': [
      'White, waxy insects on leaves or stems',
      'Sticky honeydew and sooty mold',
      'Leaves curling or wilting',
      'Ants tending mealybugs',
    ],
    'Caterpillars': [
      'Irregular holes in leaves or fruits',
      'Skeletonized leaves with veins intact',
      'Visible caterpillars on plant',
      'Silk threads on affected areas',
    ],
    'Coffee Weevil': [
      'Small holes in stored coffee beans',
      'Damaged or hollowed-out beans',
      'Presence of weevils in storage',
      'Reduced bean quality',
    ],
    'Ants': [
      'Presence of ants tending pests',
      'Sticky honeydew on leaves or fruits',
      'Increased pest activity (e.g., mealybugs)',
      'No direct damage but pest protection',
    ],
  };

  void _analyzePests() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    Map<String, int> pestMatches = {};
    pestSymptoms.forEach((pest, symptoms) {
      int matches = 0;
      widget.selectedSymptoms.forEach((section, selected) {
        matches += selected.where((symptom) => symptoms.contains(symptom)).length;
      });
      if (matches > 0) pestMatches[pest] = matches;
    });

    if (pestMatches.isEmpty) {
      _showResult('No specific pest identified. Explore pest management options.', null);
      return;
    }

    String topPest = pestMatches.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    int matchCount = pestMatches[topPest]!;
    double confidence = (matchCount / pestSymptoms[topPest]!.length) * 100;

    _showResult(
      'The symptoms most closely match $topPest (Confidence: ${confidence.toStringAsFixed(1)}%).',
      topPest,
    );

    setState(() => _isLoading = false);
  }

  void _showResult(String message, String? pestName) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pest Analysis Result'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoffeePestManagementPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F4E37),
                foregroundColor: Colors.white,
              ),
              child: Text(pestName != null ? 'Manage $pestName' : 'Explore Pest Management'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
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
        title: const Text('Pest Symptom Analysis', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Symptoms for Deeper Pest Analysis:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6F4E37)),
                  ),
                  const SizedBox(height: 8),
                  ...widget.selectedSymptoms.entries.map((entry) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ...entry.value.map((symptom) => Text('• $symptom')),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F4E37))),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _analyzePests,
        backgroundColor: const Color(0xFF6F4E37),
        tooltip: 'Analyze Pests',
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }
}