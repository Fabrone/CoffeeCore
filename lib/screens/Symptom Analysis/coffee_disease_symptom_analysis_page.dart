import 'package:coffeecore/screens/Disease%20Management/coffee_disease_management.dart';
import 'package:flutter/material.dart';

class CoffeeDiseaseSymptomAnalysisPage extends StatefulWidget {
  final Map<String, List<String>> selectedSymptoms;

  const CoffeeDiseaseSymptomAnalysisPage({required this.selectedSymptoms, super.key});

  @override
  State<CoffeeDiseaseSymptomAnalysisPage> createState() => _CoffeeDiseaseSymptomAnalysisPageState();
}

class _CoffeeDiseaseSymptomAnalysisPageState extends State<CoffeeDiseaseSymptomAnalysisPage> {
  bool _isLoading = false;

  // Detailed disease symptoms for deeper analysis
  final Map<String, List<String>> diseaseSymptoms = {
    'Coffee Leaf Rust': [
      'Orange-yellow rust spots on leaf undersides',
      'Premature leaf drop with no pest signs',
      'Reduced photosynthesis from leaf damage',
      'Spots spreading in humid conditions',
    ],
    'Coffee Wilt Disease': [
      'Plant collapses suddenly',
      'Blackened or rotten roots',
      'Yellowing leaves with no pest damage',
      'Dark streaks at stem base',
    ],
    'Coffee Berry Disease': [
      'Black, sunken lesions on cherries',
      'Premature fruit drop with fungal signs',
      'Rotting cherries with no insect holes',
      'Spots worsening in wet weather',
    ],
    'Cercospora Leaf Spot': [
      'Black or brown spots with yellow halos',
      'Premature leaf drop with no insects',
      'Spots on leaves in humid conditions',
      'Reduced leaf vigor',
    ],
    'Brown Eye Spot': [
      'Round brown spots with yellow halos',
      'Leaves dropping early without pest marks',
      'Spots on leaves in wet seasons',
      'No insect activity visible',
    ],
    'Anthracnose': [
      'Fruit cracking with dark lesions',
      'Sunken, black spots on cherries',
      'Rotting fruits with no pest entry',
      'Branch lesions in severe cases',
    ],
    'Phytophthora Root Rot': [
      'Soft, mushy roots with a foul smell',
      'Yellowing leaves with root decay',
      'Stunted growth in wet conditions',
      'No pest larvae in roots',
    ],
    'Bacterial Blight': [
      'Water-soaked, wilting leaves',
      'Oozing sap from stems',
      'Dark lesions on leaves and stems',
      'Rapid wilting in wet weather',
    ],
    'Coffee Sooty Mold': [
      'Sooty black mold on leaf surfaces',
      'Sticky honeydew with fungal growth',
      'Reduced photosynthesis, no direct pest damage',
      'Mold linked to pest activity',
    ],
    'Fusarium Root Rot': [
      'Blackened or rotten roots',
      'Wilting with no pest signs',
      'Yellowing leaves from root decay',
      'Brittle stems near base',
    ],
  };

  void _analyzeDiseases() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    Map<String, int> diseaseMatches = {};
    diseaseSymptoms.forEach((disease, symptoms) {
      int matches = 0;
      widget.selectedSymptoms.forEach((section, selected) {
        matches += selected.where((symptom) => symptoms.contains(symptom)).length;
      });
      if (matches > 0) diseaseMatches[disease] = matches;
    });

    if (diseaseMatches.isEmpty) {
      _showResult('No specific disease identified. Explore disease management options.', null);
      return;
    }

    String topDisease = diseaseMatches.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    int matchCount = diseaseMatches[topDisease]!;
    double confidence = (matchCount / diseaseSymptoms[topDisease]!.length) * 100;

    _showResult(
      'The symptoms most closely match $topDisease (Confidence: ${confidence.toStringAsFixed(1)}%).',
      topDisease,
    );

    setState(() => _isLoading = false);
  }

  void _showResult(String message, String? diseaseName) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disease Analysis Result'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoffeeDiseaseManagementPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F4E37),
                foregroundColor: Colors.white,
              ),
              child: Text(diseaseName != null ? 'Manage $diseaseName' : 'Explore Disease Management'),
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
        title: const Text('Disease Symptom Analysis', style: TextStyle(color: Colors.white)),
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
                    'Selected Symptoms for Deeper Disease Analysis:',
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
        onPressed: _isLoading ? null : _analyzeDiseases,
        backgroundColor: const Color(0xFF6F4E37),
        tooltip: 'Analyze Diseases',
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }
}