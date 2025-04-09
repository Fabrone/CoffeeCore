import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coffeecore/models/market_price.dart';

class MarketOfficerScreen extends StatefulWidget {
  const MarketOfficerScreen({super.key});

  @override
  State<MarketOfficerScreen> createState() => MarketOfficerScreenState();
}

class MarketOfficerScreenState extends State<MarketOfficerScreen> {
  static final Color coffeeBrown = Colors.brown[700]!;
  final List<String> _regions = ['Nairobi', 'Coast', 'Lake', 'Rift Valley', 'Central', 'Eastern'];
  String? _feedbackMessage; // State to hold feedback

  @override
  Widget build(BuildContext context) {
    // Show snackbar if there's a feedback message
    if (_feedbackMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_feedbackMessage!)));
        setState(() => _feedbackMessage = null); // Clear after showing
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Officer Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: coffeeBrown,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOptionCard(
                context,
                'View Price List',
                Icons.list,
                () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceListScreen()));
                },
              ),
              const SizedBox(height: 20),
              _buildOptionCard(
                context,
                'Add New Variety',
                Icons.add,
                () async {
                  await _showAddNewVarietyDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: coffeeBrown),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: coffeeBrown),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddNewVarietyDialog(BuildContext context) async {
    final varietyController = TextEditingController();
    Map<String, TextEditingController> priceControllers = {for (var region in _regions) region: TextEditingController()};
    final user = FirebaseAuth.instance.currentUser!;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Coffee Variety'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: varietyController,
                  decoration: const InputDecoration(labelText: 'New Variety Name'),
                ),
                const SizedBox(height: 16),
                const Text('Initial Prices by Region (Ksh/kg):'),
                ..._regions.map((region) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: priceControllers[region],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: region),
                  ),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: coffeeBrown),
            onPressed: () {
              if (varietyController.text.trim().isEmpty) {
                Navigator.pop(dialogContext, 'Enter a variety name');
                return;
              }
              Navigator.pop(dialogContext, varietyController.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      String newVariety = result;
      bool hasValidPrice = false;

      for (var region in _regions) {
        double? price = double.tryParse(priceControllers[region]!.text);
        if (price != null && price >= 0) {
          hasValidPrice = true;
          String docId = '${region}_$newVariety';
          final marketPrice = MarketPrice(
            id: docId,
            region: region,
            variety: newVariety,
            price: price,
            updatedBy: user.uid,
            timestamp: Timestamp.now(),
          );
          await FirebaseFirestore.instance.collection('market_prices').doc(docId).set(marketPrice.toMap());
        }
      }
      setState(() {
        _feedbackMessage = hasValidPrice ? '$newVariety added successfully' : 'Enter at least one valid price';
      });
    }
  }
}

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});

  @override
  State<PriceListScreen> createState() => PriceListScreenState();
}

class PriceListScreenState extends State<PriceListScreen> {
  static final Color coffeeBrown = Colors.brown[700]!;
  final List<String> _regions = ['Nairobi', 'Coast', 'Lake', 'Rift Valley', 'Central', 'Eastern'];
  String? _feedbackMessage; // State to hold feedback

  Future<List<String>> _fetchVarieties() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('market_prices').get();
    return snapshot.docs.map((doc) => doc['variety'] as String).toSet().toList();
  }

  Future<void> _showEditDialog(Map<String, dynamic> regionData, String region, List<String> varieties) async {
    Map<String, TextEditingController> controllers = {
      for (var variety in varieties) variety: TextEditingController(text: regionData[variety]?.toString() ?? '')
    };
    final user = FirebaseAuth.instance.currentUser!;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Prices for $region'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: varieties.map((variety) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: controllers[variety],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: '$variety Price (Ksh/kg)'),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: coffeeBrown),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      for (var variety in varieties) {
        double? price = double.tryParse(controllers[variety]!.text);
        if (price != null && price >= 0) {
          String docId = '${region}_$variety';
          final marketPrice = MarketPrice(
            id: docId,
            region: region,
            variety: variety,
            price: price,
            updatedBy: user.uid,
            timestamp: Timestamp.now(),
          );
          await FirebaseFirestore.instance.collection('market_prices').doc(docId).set(marketPrice.toMap(), SetOptions(merge: true));
        }
      }
      setState(() => _feedbackMessage = 'Prices updated');
    }
  }

  Future<void> _showBulkEditDialog(List<String> varieties) async {
    String? selectedVariety;
    Map<String, bool> regionSelections = {for (var r in _regions) r: false};
    final bulkPriceController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser!;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bulk Edit Prices'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedVariety,
                items: varieties.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (value) => setState(() => selectedVariety = value),
                decoration: const InputDecoration(labelText: 'Select Variety'),
              ),
              TextField(
                controller: bulkPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Common Price (Ksh/kg)'),
              ),
              const SizedBox(height: 16),
              const Text('Select Regions:'),
              ..._regions.map((region) => CheckboxListTile(
                title: Text(region),
                value: regionSelections[region],
                onChanged: (value) => setState(() => regionSelections[region] = value!),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: coffeeBrown),
            onPressed: () {
              if (selectedVariety == null || bulkPriceController.text.isEmpty) {
                Navigator.pop(dialogContext, {'error': 'Fill variety and price'});
                return;
              }
              double? price = double.tryParse(bulkPriceController.text);
              if (price == null || price < 0) {
                Navigator.pop(dialogContext, {'error': 'Invalid price'});
                return;
              }
              Navigator.pop(dialogContext, {
                'variety': selectedVariety,
                'price': price,
                'regions': regionSelections,
              });
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && result.containsKey('variety')) {
      final variety = result['variety'] as String;
      final price = result['price'] as double;
      final regions = result['regions'] as Map<String, bool>;

      for (var region in _regions) {
        if (regions[region]!) {
          String docId = '${region}_$variety';
          final marketPrice = MarketPrice(
            id: docId,
            region: region,
            variety: variety,
            price: price,
            updatedBy: user.uid,
            timestamp: Timestamp.now(),
          );
          await FirebaseFirestore.instance.collection('market_prices').doc(docId).set(marketPrice.toMap(), SetOptions(merge: true));
        }
      }
      setState(() => _feedbackMessage = 'Bulk update completed');
    } else if (result != null && result.containsKey('error')) {
      setState(() => _feedbackMessage = result['error'] as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_feedbackMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_feedbackMessage!)));
        setState(() => _feedbackMessage = null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price List', style: TextStyle(color: Colors.white)),
        backgroundColor: coffeeBrown,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'bulk_edit') {
                List<String> varieties = await _fetchVarieties();
                await _showBulkEditDialog(varieties);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'bulk_edit', child: Text('Bulk Edit')),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _fetchVarieties(),
        builder: (context, varietySnapshot) {
          if (varietySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!varietySnapshot.hasData || varietySnapshot.data!.isEmpty) {
            return const Center(child: Text('No prices available'));
          }
          List<String> varieties = varietySnapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('market_prices').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No prices available'));
              }

              Map<String, Map<String, double>> priceTable = {};
              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                String region = data['region'];
                String variety = data['variety'];
                double price = data['price'];
                priceTable[region] ??= {};
                priceTable[region]![variety] = price;
              }

              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: MediaQuery.of(context).size.width * 0.05,
                    columns: [
                      const DataColumn(label: Text('Region')),
                      ...varieties.map((v) => DataColumn(label: Text(v))),
                      const DataColumn(label: Text('Edit')),
                    ],
                    rows: _regions.map((region) {
                      return DataRow(cells: [
                        DataCell(Text(region)),
                        ...varieties.map((variety) => DataCell(
                          Text(priceTable[region]?[variety]?.toStringAsFixed(2) ?? '-'),
                        )),
                        DataCell(IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await _showEditDialog(priceTable[region] ?? {}, region, varieties);
                          },
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}