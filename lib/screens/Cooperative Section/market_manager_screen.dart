import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      duration: const Duration(seconds: 10), // Slower for uniform transition
      vsync: this,
    )..repeat();
    _currencyAnimation = IntTween(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _fetchCooperativeName() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _feedbackMessage = 'No user logged in';
      });
      return;
    }

    try {
      QuerySnapshot coopSnapshot = await FirebaseFirestore.instance
          .collection('cooperatives')
          .get();
      for (var coopDoc in coopSnapshot.docs) {
        String coopId = coopDoc.id;
        DocumentSnapshot managerDoc = await FirebaseFirestore.instance
            .collection('${coopId}_marketmanagers')
            .doc(userId)
            .get();
        if (managerDoc.exists) {
          setState(() {
            _cooperativeName = coopId.replaceAll('_', ' ');
          });
          return;
        }
      }
      setState(() {
        _feedbackMessage = 'Not registered as a Market Manager';
      });
    } catch (e) {
      logger.e('Error fetching cooperative: $e');
      setState(() {
        _feedbackMessage = 'Error loading cooperative: $e';
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
    final List<String> currencies = [
      '\$', // USD
      '€', // EUR
      '£', // GBP
      '¥', // JPY
      '₹', // INR
      'R', // ZAR
      'A\$', // AUD
      'Ksh', // KES
      '₣', // CHF
    ];
    return AnimatedBuilder(
      animation: _currencyAnimation,
      builder: (context, child) {
        return Text(
          currencies[_currencyAnimation.value],
          style: TextStyle(
            fontSize: 48, // Larger size
            color: const Color.fromRGBO(121, 85, 72, 1.0),
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            shadows: [
              Shadow(
                blurRadius: 4.0,
                color: const Color.fromRGBO(0, 0, 0, 0.3), // Replaced withOpacity
                offset: const Offset(2.0, 2.0),
              ),
            ],
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
                color: const Color.fromRGBO(121, 85, 72, 0.3),
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _feedbackMessage = 'No user logged in';
      });
      return;
    }

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
      try {
        String newVariety = result;
        double price = double.parse(priceController.text);
        String formattedCoopId = _cooperativeName!.replaceAll(' ', '_');
        await FirebaseFirestore.instance
            .collection('${formattedCoopId}_coffeeprices')
            .doc(newVariety)
            .set({
          'variety': newVariety,
          'price': price,
          'updatedBy': user.uid,
          'timestamp': Timestamp.now(),
        });
        setState(() {
          _feedbackMessage = '$newVariety added with price Ksh $price/kg';
        });
      } catch (e) {
        logger.e('Error adding variety: $e');
        setState(() {
          _feedbackMessage = 'Error adding variety: $e';
        });
      }
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
  final logger = Logger(printer: PrettyPrinter());

  Future<void> _showEditDialog(String variety, double currentPrice) async {
    final priceController = TextEditingController(text: currentPrice.toString());
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _feedbackMessage = 'No user logged in';
      });
      return;
    }

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
            onPressed: () {
              double? price = double.tryParse(priceController.text);
              if (price == null || price < 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Invalid price')),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        double price = double.parse(priceController.text);
        String formattedCoopId = widget.cooperativeName.replaceAll(' ', '_');
        await FirebaseFirestore.instance
            .collection('${formattedCoopId}_coffeeprices')
            .doc(variety)
            .update({
          'price': price,
          'updatedBy': user.uid,
          'timestamp': Timestamp.now(),
        });
        setState(() => _feedbackMessage = 'Price for $variety updated to Ksh $price/kg');
      } catch (e) {
        logger.e('Error updating price: $e');
        setState(() => _feedbackMessage = 'Error updating price: $e');
      }
    }
  }

  Future<void> _deletePrice(String variety) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete $variety'),
        content: const Text('Are you sure you want to delete this variety and price?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        String formattedCoopId = widget.cooperativeName.replaceAll(' ', '_');
        await FirebaseFirestore.instance
            .collection('${formattedCoopId}_coffeeprices')
            .doc(variety)
            .delete();
        setState(() => _feedbackMessage = '$variety deleted');
      } catch (e) {
        logger.e('Error deleting price: $e');
        setState(() => _feedbackMessage = 'Error deleting price: $e');
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

    String formattedCoopId = widget.cooperativeName.replaceAll(' ', '_');
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
            .collection('${formattedCoopId}_coffeeprices')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            logger.e('Error loading prices: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
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

          final prices = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'variety': data['variety'] as String? ?? 'Unknown',
              'price': (data['price'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList();

          return SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Variety', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Price (Ksh/kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: prices.map((price) {
                return DataRow(cells: [
                  DataCell(Text(price['variety'] as String)),
                  DataCell(Text((price['price'] as double).toStringAsFixed(2))),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          await _showEditDialog(price['variety'] as String, price['price'] as double);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _deletePrice(price['variety']! as String);
                        },
                      ),
                    ],
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