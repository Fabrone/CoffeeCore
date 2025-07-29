import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:coffeecore/models/coffee_pest_models.dart'; 
import 'package:coffeecore/screens/Pest%20Management/coffee_intervention_page.dart';
import 'package:coffeecore/screens/Pest%20Management/coffee_user_pest_history.dart';

class CoffeePestManagementPage extends StatefulWidget {
  const CoffeePestManagementPage({super.key});

  @override
  State<CoffeePestManagementPage> createState() => _CoffeePestManagementPageState();
}

class _CoffeePestManagementPageState extends State<CoffeePestManagementPage> {
  String? _selectedStage;
  String? _selectedPest;
  CoffeePestData? _pestData;
  bool _showPestDetails = false;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _hintsKey = GlobalKey();

  // Coffee growth stages
  final List<String> _stages = [
    'Vegetative Stage',
    'Flowering & Fruit Development',
    'Post-harvest / Storage',
  ];

  // Pests by stage
  final Map<String, List<String>> _stagePests = {
    'Vegetative Stage': [
      'Coffee Leaf Miner',
      'Coffee Stem Borer',
      'Root-Knot Nematodes',
      'White Flies',
      'Coffee Mealybug',
      'Caterpillars',
      'Ants',
    ],
    'Flowering & Fruit Development': [
      'Coffee Berry Borer',
      'Coffee Antestia Bug',
      'White Flies',
      'Coffee Mealybug',
      'Caterpillars',
      'Ants',
    ],
    'Post-harvest / Storage': ['Coffee Weevil'],
  };

  // Pest details with lifecycle stages
  final Map<String, Map<String, dynamic>> _pestDetails = {
    'Coffee Berry Borer': {
      'description': 'A small beetle that bores into coffee cherries to lay eggs, and the larvae feed on the beans inside.',
      'symptoms': 'Infested cherries have small holes, and the beans are damaged, leading to poor quality.',
      'chemicalControls': ['Imidacloprid', 'Lambda-cyhalothrin'],
      'mechanicalControls': ['Pheromone traps'],
      'biologicalControls': ['Parasitoid wasps'],
      'possibleCauses': ['Warm temperatures (25-30°C)', 'High humidity', 'Poor sanitation'],
      'preventiveMeasures': ['Regular harvesting', 'Sanitation of fallen cherries', 'Shade management'],
      'lifecycleImages': [
        'assets/pests/coffee_berry_borer1.png',
        'assets/pests/coffee_berry_borer2.png',
        'assets/pests/coffee_berry_borer3.png',
        'assets/pests/coffee_berry_borer4.png',
        'assets/pests/coffee_berry_borer.png',
        'assets/pests/coffee_berry_borers.png',
      ],
    },
    'Coffee Leaf Miner': {
      'description': 'A small moth whose larvae mine the leaves of coffee plants.',
      'symptoms': 'Irregular, silvery streaks or tunnels on the leaves. In severe infestations, leaves can die off.',
      'chemicalControls': ['Malathion', 'Permethrin'],
      'mechanicalControls': [],
      'biologicalControls': ['Parasitoid wasps'],
      'possibleCauses': ['Warm, dry conditions', 'Overcrowded plants'],
      'preventiveMeasures': ['Monitor leaf health', 'Avoid dense planting'],
      'lifecycleImages': [
        'assets/pests/coffee_leaf_miner1.png',
        'assets/pests/coffee_leaf_miner2.png',
        'assets/pests/coffee_leaf_miner3.png',
        'assets/pests/coffee_leaf_miner4.png',
        'assets/pests/leaf_miner_lesion.png',
      ],
    },
    'Coffee Antestia Bug': {
      'description': 'A sap-sucking bug that damages coffee berries.',
      'symptoms': 'Fruit deformities, premature fruit drop, reduced size, and weight of the cherries.',
      'chemicalControls': ['Cypermethrin', 'Lambda-cyhalothrin', 'Deltamethrin'],
      'mechanicalControls': ['Pruning and cleaning practices'],
      'biologicalControls': [],
      'possibleCauses': ['High rainfall', 'Poor pruning'],
      'preventiveMeasures': ['Regular pruning', 'Field hygiene'],
      'lifecycleImages': [
        'assets/pests/coffee_antestia_bug1.png',
        'assets/pests/coffee_antestia_bug2.png',
        'assets/pests/coffee_antestia_bug3.png',
        'assets/pests/coffee_antestia_bug4.png',
      ],
    },
    'Coffee Stem Borer': {
      'description': 'A beetle that bores into the stems and branches of coffee plants.',
      'symptoms': 'Holes in the stem or branches, weakening the plant and causing it to break.',
      'chemicalControls': ['Carbaryl', 'Permethrin'],
      'mechanicalControls': ['Pruning of infested branches'],
      'biologicalControls': [],
      'possibleCauses': ['High altitude', 'Old plants'],
      'preventiveMeasures': ['Remove infested branches', 'Plant health monitoring'],
      'lifecycleImages': [
        'assets/pests/coffee_stem_borer1.png',
        'assets/pests/coffee_stem_borer2.png',
        'assets/pests/coffee_stem_borer3.png',
        'assets/pests/coffee_stem_borer4.png',
      ],
    },
    'Root-Knot Nematodes': {
      'description': 'Nematodes that attack the roots of coffee plants, causing galls.',
      'symptoms': 'Root galls, yellowing leaves, stunted growth, and poor fruit development.',
      'chemicalControls': ['Fenamiphos', 'Oxamyl', 'Carbofuran'],
      'mechanicalControls': [],
      'biologicalControls': [],
      'possibleCauses': ['Warm, moist soil', 'Continuous cropping'],
      'preventiveMeasures': ['Crop rotation', 'Soil solarization'],
      'lifecycleImages': [
        'assets/pests/root_knot_nematodes1.png',
        'assets/pests/root_knot_nematodes2.png',
        'assets/pests/root_knot_nematodes3.png',
      ],
    },
    'White Flies': {
      'description': 'Tiny white flying insects that suck sap from coffee plants.',
      'symptoms': 'Yellowing of leaves, sticky honeydew that leads to sooty mold growth.',
      'chemicalControls': ['Imidacloprid', 'Lambda-cyhalothrin'],
      'mechanicalControls': [],
      'biologicalControls': ['Natural predators like ladybugs'],
      'possibleCauses': ['Warm, humid conditions', 'Poor ventilation'],
      'preventiveMeasures': ['Encourage natural predators', 'Improve air circulation'],
      'lifecycleImages': [
        'assets/pests/white_flies1.png',
        'assets/pests/white_flies2.png',
        'assets/pests/white_flies3.png',
        'assets/pests/white_flies4.png',
      ],
    },
    'Coffee Mealybug': {
      'description': 'Sap-sucking insect covered with a waxy coating.',
      'symptoms': 'Leaves curl, plants weaken, and honeydew causes mold growth.',
      'chemicalControls': ['Imidacloprid', 'Pyrethrins', 'Malathion'],
      'mechanicalControls': [],
      'biologicalControls': ['Parasitoid wasps'],
      'possibleCauses': ['High humidity', 'Ant presence'],
      'preventiveMeasures': ['Control ant populations', 'Monitor plant health'],
      'lifecycleImages': [
        'assets/pests/coffee_mealybug1.png',
        'assets/pests/coffee_mealybug2.png',
        'assets/pests/coffee_mealybug3.png',
      ],
    },
    'Caterpillars': {
      'description': 'Larvae of moths that feed on coffee leaves and fruit.',
      'symptoms': 'Holes in the leaves and fruit.',
      'chemicalControls': ['Bacillus thuringiensis (Bt)'],
      'mechanicalControls': [],
      'biologicalControls': ['Trichogramma spp.'],
      'possibleCauses': ['Warm, wet conditions', 'Nearby host plants'],
      'preventiveMeasures': ['Remove debris', 'Monitor for eggs'],
      'lifecycleImages': [
        'assets/pests/caterpillar1.png',
        'assets/pests/caterpillar2.png',
        'assets/pests/caterpillar3.png',
        'assets/pests/caterpillar4.png',
      ],
    },
    'Coffee Weevil': {
      'description': 'A pest that attacks stored coffee beans.',
      'symptoms': 'Holes in the coffee beans, often leading to poor quality and reduced marketability.',
      'chemicalControls': ['Permethrin'],
      'mechanicalControls': ['Proper storage conditions', 'Fumigation'],
      'biologicalControls': [],
      'possibleCauses': ['High moisture in storage', 'Infested beans'],
      'preventiveMeasures': ['Dry beans thoroughly', 'Use airtight storage'],
      'lifecycleImages': [
        'assets/pests/coffee_weevil1.png',
        'assets/pests/coffee_weevil2.png',
        'assets/pests/coffee_weevil3.png',
        'assets/pests/coffee_weevil4.png',
        'assets/pests/coffee_weevil5.png',
        'assets/pests/coffee_weevil6.png',
      ],
    },
    'Ants': {
      'description': 'Certain ants protect and farm pests like aphids or mealybugs.',
      'symptoms': 'Ants promote the spread of pests by protecting them in exchange for honeydew.',
      'chemicalControls': ['Permethrin', 'Cypermethrin'],
      'mechanicalControls': ['Ant baits'],
      'biologicalControls': [],
      'possibleCauses': ['Presence of sap-sucking pests', 'Warm weather'],
      'preventiveMeasures': ['Control sap-sucking pests', 'Use ant barriers'],
      'lifecycleImages': [
        'assets/pests/ants1.png',
        'assets/pests/ants2.png',
        'assets/pests/ants3.png',
        'assets/pests/ants4.png',
      ],
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

  void _updatePestDetails() {
    if (_selectedPest != null && _pestDetails.containsKey(_selectedPest!)) {
      setState(() {
        _pestData = CoffeePestData(
          name: _selectedPest!,
          description: _pestDetails[_selectedPest!]!['description'],
          symptoms: _pestDetails[_selectedPest!]!['symptoms'],
          chemicalControls: List<String>.from(_pestDetails[_selectedPest!]!['chemicalControls']),
          mechanicalControls: List<String>.from(_pestDetails[_selectedPest!]!['mechanicalControls']),
          biologicalControls: List<String>.from(_pestDetails[_selectedPest!]!['biologicalControls']),
          possibleCauses: List<String>.from(_pestDetails[_selectedPest!]!['possibleCauses']),
          preventiveMeasures: List<String>.from(_pestDetails[_selectedPest!]!['preventiveMeasures']),
          lifecycleImages: List<String>.from(_pestDetails[_selectedPest!]!['lifecycleImages']),
        );
      });
    }
  }

  void _scrollToHints() {
    if (_showPestDetails && _hintsKey.currentContext != null) {
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
        title: const Text('Coffee Pest Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6F4E37), // Coffee brown
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
                  _selectedPest = null;
                  _pestData = null;
                  _showPestDetails = false;
                });
              }),
              const SizedBox(height: 16),
              _buildDropdown('Select Pest', _selectedStage != null ? _stagePests[_selectedStage]! : [], _selectedPest, (val) {
                setState(() {
                  _selectedPest = val;
                  _updatePestDetails();
                  _showPestDetails = false;
                });
              }),
              if (_pestData != null) ...[
                const SizedBox(height: 16),
                _buildLifecycleCarousel(_pestData!.lifecycleImages),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (_pestData != null) {
                    setState(() {
                      _showPestDetails = !_showPestDetails;
                      if (_showPestDetails) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHints());
                      }
                    });
                  } else {
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please select a pest first')));
                  }
                },
                child: const Text(
                  'View Pest Management Details',
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
                    MaterialPageRoute(builder: (context) => const CoffeeUserPestHistoryPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F4E37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('View My Pest History'),
              ),
              if (_showPestDetails && _pestData != null) ...[
                const SizedBox(height: 8),
                Column(
                  key: _hintsKey,
                  children: [
                    _buildHintCard('Description', _pestData!.description, Icons.info),
                    _buildHintCard('Symptoms', _pestData!.symptoms, Icons.warning),
                    _buildHintCard('Chemical Controls', _pestData!.chemicalControls.join('\n'), Icons.science),
                    _buildHintCard('Mechanical Controls', _pestData!.mechanicalControls.isEmpty ? 'None' : _pestData!.mechanicalControls.join('\n'), Icons.build),
                    _buildHintCard('Biological Controls', _pestData!.biologicalControls.isEmpty ? 'None' : _pestData!.biologicalControls.join('\n'), Icons.eco),
                    _buildHintCard('Possible Causes', _pestData!.possibleCauses.join('\n'), Icons.search),
                    _buildHintCard('Preventive Measures', _pestData!.preventiveMeasures.join('\n'), Icons.shield),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CoffeeInterventionPage(
                                pestData: _pestData!,
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
                        child: const Text('Manage Pest'),
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

  Widget _buildLifecycleCarousel(List<String> images) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pest Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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