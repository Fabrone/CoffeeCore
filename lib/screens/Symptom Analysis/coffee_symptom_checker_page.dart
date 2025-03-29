import 'package:coffeecore/screens/Symptom%20Analysis/coffee_disease_symptom_analysis_page.dart';
import 'package:coffeecore/screens/Symptom%20Analysis/coffee_pest_symptom_analysis_page.dart';
import 'package:flutter/material.dart';

class CoffeeSymptomCheckerPage extends StatefulWidget {
  const CoffeeSymptomCheckerPage({super.key});

  @override
  State<CoffeeSymptomCheckerPage> createState() => _CoffeeSymptomCheckerPageState();
}

class _CoffeeSymptomCheckerPageState extends State<CoffeeSymptomCheckerPage> with SingleTickerProviderStateMixin {
  // Symptom data organized by plant section and pest/disease
  final Map<String, Map<String, List<String>>> symptoms = {
    'Roots': {
      'Pests': [
        'Swollen or knotted roots (e.g., nematode galls)',
        'Wilting despite adequate watering (root damage)',
        'Presence of tiny worms or larvae in soil (nematodes)',
        'Roots with small, irregular tunnels or holes',
        'Yellowing lower leaves due to root feeding',
        'Roots appear chewed or scraped',
      ],
      'Diseases': [
        'Blackened or rotten roots (root rot)',
        'Soft, mushy roots with a foul smell',
        'White fungal threads or growth on roots',
        'Stunted growth with dark, sunken root lesions',
        'Roots discolored brown or gray (fungal decay)',
        'Plant collapses suddenly (wilt disease)',
      ],
    },
    'Stems/Branches': {
      'Pests': [
        'Small holes bored into stems (stem borers)',
        'Sawdust-like frass around stem base',
        'Visible larvae or beetles inside stems',
        'Girdling or ring-like cuts on stems',
        'Branches snapping or weakening',
        'Swollen galls on stems (insect activity)',
      ],
      'Diseases': [
        'Dark, sunken cankers or lesions on stems',
        'White or gray mold covering stems',
        'Stems splitting or cracking abnormally',
        'Oozing sap or gummy residue from stems',
        'Black streaks or rot at stem base (wilt)',
        'Brittle, dry stems with no pest signs',
      ],
    },
    'Leaves': {
      'Pests': [
        'Irregular holes or chewing marks on leaves',
        'Silvery tunnels or trails (leaf miners)',
        'Sticky honeydew with ants present',
        'Tiny insects (whiteflies, mealybugs) under leaves',
        'Leaves curling or rolling up (sap-suckers)',
        'Skeletonized leaves with veins intact',
      ],
      'Diseases': [
        'Orange-yellow rust spots on leaf undersides',
        'Black or brown spots with yellow halos',
        'Powdery white coating on leaves (mold)',
        'Water-soaked, wilting leaves (blight)',
        'Sooty black mold on leaf surfaces',
        'Premature leaf drop with no insect signs',
      ],
    },
    'Fruits': {
      'Pests': [
        'Small entry holes in coffee cherries (berry borer)',
        'Larvae or worms inside cherries',
        'Deformed or discolored cherries (bug feeding)',
        'Premature fruit drop with insect damage',
        'Chewed or missing fruit parts',
        'Tiny insects on fruit surfaces (e.g., antestia bugs)',
      ],
      'Diseases': [
        'Black, sunken lesions on cherries (berry disease)',
        'Soft, rotting cherries with fungal growth',
        'Brown spots or shriveled berries',
        'White or gray mold on fruit surfaces',
        'Fruit cracking with dark lesions (anthracnose)',
        'Foul odor from decaying cherries',
      ],
    },
    'Flowers': {
      'Pests': [
        'Tiny insects (whiteflies, bugs) on flower buds',
        'Flower buds dropping due to sap-sucking',
        'Chewed or damaged petals',
        'Sticky residue on flowers (honeydew)',
        'Presence of ants tending pests',
        'Malformed or aborted flowers',
      ],
      'Diseases': [
        'Brown or black spots on flower buds',
        'Wilting or drooping flowers (blight)',
        'White fungal coating on buds',
        'Flowers rotting before opening',
        'Premature flower drop with no pest signs',
        'Discolored or shriveled buds',
      ],
    },
  };

  // Store selected symptoms
  Map<String, List<bool>> selectedSymptoms = {
    'Roots': [],
    'Stems/Branches': [],
    'Leaves': [],
    'Fruits': [],
    'Flowers': [],
  };

  bool _isLoading = false;
    late AnimationController _animationController;
    late Animation<int> _guideTextAnimation; // Changed to Animation<int>
    final String _guideText = 'Welcome to the Symptom Checker! Select the symptoms you observe on your coffee plant by checking the boxes below. Choose symptoms from Roots, Stems/Branches, Leaves, Fruits, or Flowers. Once done, press the floating button to analyze whether it’s a pest or disease issue.';
    String _currentGuideText = ''; // Added to hold the current text state
    
  @override
  void initState() {
    super.initState();
    // Initialize selectedSymptoms with false for each symptom
    symptoms.forEach((section, categories) {
      int totalSymptoms = categories['Pests']!.length + categories['Diseases']!.length;
      selectedSymptoms[section] = List.filled(totalSymptoms, false);
    });

    // Setup animation for guide text
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _guideTextAnimation = StepTween(
      begin: 0,
      end: _guideText.length,
    ).animate(_animationController)
      ..addListener(() {
        setState(() {
          _currentGuideText = _guideText.substring(0, _guideTextAnimation.value);
        });
      });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _analyzeSymptoms() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    int pestCount = 0;
    int diseaseCount = 0;
    int totalSelected = 0;

    symptoms.forEach((section, categories) {
      List<String> allSymptoms = [...categories['Pests']!, ...categories['Diseases']!];
      for (int i = 0; i < allSymptoms.length; i++) {
        if (selectedSymptoms[section]![i]) {
          totalSelected++;
          if (i < categories['Pests']!.length) {
            pestCount++;
          } else {
            diseaseCount++;
          }
        }
      }
    });

    String resultMessage;
    Widget navigationButton;

    if (totalSelected == 0) {
      resultMessage = 'Please select at least one symptom to analyze.';
      navigationButton = const SizedBox.shrink();
    } else {
      double pestPercentage = (pestCount / totalSelected) * 100;
      double diseasePercentage = (diseaseCount / totalSelected) * 100;

      if (pestPercentage >= 60) {
        resultMessage = 'Based on your symptoms, it’s likely a pest issue (${pestPercentage.toStringAsFixed(1)}% pest-related). Let’s analyze further.';
        navigationButton = ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoffeePestSymptomAnalysisPage(selectedSymptoms: _getSelectedSymptoms()),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6F4E37),
            foregroundColor: Colors.white,
          ),
          child: const Text('Analyze Pests Further'),
        );
      } else if (diseasePercentage >= 60) {
        resultMessage = 'Based on your symptoms, it’s likely a disease issue (${diseasePercentage.toStringAsFixed(1)}% disease-related). Let’s analyze further.';
        navigationButton = ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoffeeDiseaseSymptomAnalysisPage(selectedSymptoms: _getSelectedSymptoms()),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6F4E37),
            foregroundColor: Colors.white,
          ),
          child: const Text('Analyze Diseases Further'),
        );
      } else {
        resultMessage = 'Symptoms are inconclusive (Pests: ${pestPercentage.toStringAsFixed(1)}%, Diseases: ${diseasePercentage.toStringAsFixed(1)}%). Explore both options.';
        navigationButton = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CoffeePestSymptomAnalysisPage(selectedSymptoms: _getSelectedSymptoms())),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F4E37),
                foregroundColor: Colors.white,
              ),
              child: const Text('Pests'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CoffeeDiseaseSymptomAnalysisPage(selectedSymptoms: _getSelectedSymptoms())),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F4E37),
                foregroundColor: Colors.white,
              ),
              child: const Text('Diseases'),
            ),
          ],
        );
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Initial Analysis'),
          content: Text(resultMessage),
          actions: [
            navigationButton,
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Map<String, List<String>> _getSelectedSymptoms() {
    Map<String, List<String>> selected = {};
    symptoms.forEach((section, categories) {
      List<String> allSymptoms = [...categories['Pests']!, ...categories['Diseases']!];
      selected[section] = allSymptoms.asMap().entries.where((entry) => selectedSymptoms[section]![entry.key]).map((entry) => entry.value).toList();
    });
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker', style: TextStyle(color: Colors.white)),
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
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _currentGuideText, // Use the current text state here
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection('Roots'),
                  const SizedBox(height: 16),
                  _buildSection('Stems/Branches'),
                  const SizedBox(height: 16),
                  _buildSection('Leaves'),
                  const SizedBox(height: 16),
                  _buildSection('Fruits'),
                  const SizedBox(height: 16),
                  _buildSection('Flowers'),
                  const SizedBox(height: 80), // Space for FAB
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
        onPressed: _isLoading ? null : _analyzeSymptoms,
        backgroundColor: const Color(0xFF6F4E37),
        tooltip: 'Analyze Symptoms',
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }

  Widget _buildSection(String section) {
    final pestSymptoms = symptoms[section]!['Pests']!;
    final diseaseSymptoms = symptoms[section]!['Diseases']!;
    final allSymptoms = [...pestSymptoms, ...diseaseSymptoms];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6F4E37)),
            ),
            const SizedBox(height: 8),
            ...List.generate(allSymptoms.length, (index) {
              return CheckboxListTile(
                title: Text(allSymptoms[index], style: const TextStyle(fontSize: 14)),
                value: selectedSymptoms[section]![index],
                onChanged: (bool? value) {
                  setState(() {
                    selectedSymptoms[section]![index] = value!;
                  });
                },
                activeColor: const Color(0xFF6F4E37),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }
}