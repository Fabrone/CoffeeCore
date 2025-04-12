// File: lib/screens/market_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coffeecore/models/coop_market_price.dart';
import 'package:logger/logger.dart';

class MarketManagerScreen extends StatefulWidget {
  const MarketManagerScreen({super.key});

  @override
  State<MarketManagerScreen> createState() => _MarketManagerScreenState();
}

class _MarketManagerScreenState extends State<MarketManagerScreen>
    with SingleTickerProviderStateMixin {
  static final Color coffeeBrown = Colors.brown[700]!;
  final logger = Logger(printer: PrettyPrinter());
  String? _cooperativeName;
  String? _feedbackMessage;
  late AnimationController _animationController;
  late Animation<int> _currencyAnimation;

  @override
  void initState() {
    super.initState();
    _fetchCooperativeName();
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    _currencyAnimation = IntTween(begin: 0, end: 4).animate(_animationController);
  }

  Future<void> _fetchCooperativeName() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collectionGroup('marketmanagers')
        .where('uid', isEqualTo: userId)
        .get();
    if (snapshot.docs.isNotEmpty) {
      String coopName = snapshot.docs.first.reference.parent.parent!.id.replaceAll('_', ' ');
      setState(() {
        _cooperativeName = coopName;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        title: const Text(
          'Market Manager Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: coffeeBrown,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _cooperativeName == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.brown[50],
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCurrencyAnimation(),
                    const SizedBox(height: 20),
                    _buildOptionCard(
                      'View Price List',
                      Icons.list_alt,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PriceListScreen(cooperativeName: _cooperativeName!),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildOptionCard(
                      'Add Variety Price',
                      Icons.add_circle_outline,
                      () async {
                        await _showAddVarietyDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrencyAnimation() {
    final List<String> currencies = ['\$', '€', '£', 'R', 'Ksh'];
    return AnimatedBuilder(
      animation: _currencyAnimation,
      builder: (context, child) {
        return Text(
          currencies[_currencyAnimation.value],
          style: TextStyle(
            fontSize: 40,
            color: Color.fromRGBO(121, 85, 72, 0.8), // Replaced withOpacity
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }

  Widget _buildOptionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.brown[100]!, Colors.brown[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(121, 85, 72, 0.3), // Replaced withOpacity
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: coffeeBrown),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: coffeeBrown,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddVarietyDialog(BuildContext context) async {
    final varietyController = TextEditingController();
    final priceController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser!;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Coffee Variety & Price'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: varietyController,
                decoration: InputDecoration(
                  labelText: 'Variety Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (Ksh/kg)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
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
              if (varietyController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
                Navigator.pop(dialogContext, 'Fill all fields');
                return;
              }
              double? price = double.tryParse(priceController.text);
              if (price == null || price < 0) {
                Navigator.pop(dialogContext, 'Invalid price');
                return;
              }
              Navigator.pop(dialogContext, varietyController.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result != 'Fill all fields' && result != 'Invalid price') {
      String newVariety = result;
      double price = double.parse(priceController.text);
      String docId = '${_cooperativeName!.replaceAll(' ', '_')}_$newVariety';
      final marketPrice = CoopMarketPrice(
        id: docId,
        cooperative: _cooperativeName!,
        variety: newVariety,
        price: price,
        updatedBy: user.uid,
        timestamp: Timestamp.now(),
      );
      await FirebaseFirestore.instance.collection('coffee_prices').doc(docId).set(marketPrice.toMap());
      setState(() {
        _feedbackMessage = '$newVariety added with price Ksh $price/kg';
      });
    } else if (result == 'Fill all fields' || result == 'Invalid price') {
      setState(() {
        _feedbackMessage = result;
      });
    }
  }
}

class PriceListScreen extends StatefulWidget {
  final String cooperativeName;

  const PriceListScreen({super.key, required this.cooperativeName});

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  static final Color coffeeBrown = Colors.brown[700]!;
  String? _feedbackMessage;

  Future<void> _showEditDialog(String variety, double currentPrice) async {
    final priceController = TextEditingController(text: currentPrice.toString());
    final user = FirebaseAuth.instance.currentUser!;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Price for $variety'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Price (Ksh/kg)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      double? price = double.tryParse(priceController.text);
      if (price != null && price >= 0) {
        String docId = '${widget.cooperativeName.replaceAll(' ', '_')}_$variety';
        final marketPrice = CoopMarketPrice(
          id: docId,
          cooperative: widget.cooperativeName,
          variety: variety,
          price: price,
          updatedBy: user.uid,
          timestamp: Timestamp.now(),
        );
        await FirebaseFirestore.instance.collection('coffee_prices').doc(docId).set(marketPrice.toMap());
        setState(() => _feedbackMessage = 'Price for $variety updated to Ksh $price/kg');
      } else {
        setState(() => _feedbackMessage = 'Invalid price entered');
      }
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
        title: Text(
          'Price List - ${widget.cooperativeName}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: coffeeBrown,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coffee_prices')
            .where('cooperative', isEqualTo: widget.cooperativeName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No varieties added yet for ${widget.cooperativeName}.',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          final prices = snapshot.data!.docs
              .map((doc) => CoopMarketPrice.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null))
              .toList();

          return SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Variety', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Price (Ksh/kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Edit', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: prices.map((price) {
                return DataRow(cells: [
                  DataCell(Text(price.variety)),
                  DataCell(Text(price.price.toStringAsFixed(2))),
                  DataCell(IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      await _showEditDialog(price.variety, price.price);
                    },
                  )),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}