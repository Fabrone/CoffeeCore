import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeecore/models/market_data.dart'; // Ensure this exists
import 'package:coffeecore/screens/view_saved_data_page.dart'; // Ensure this exists

class MarketPricesWidget extends StatefulWidget {
  const MarketPricesWidget({super.key});

  @override
  MarketPricesWidgetState createState() => MarketPricesWidgetState();
}

class MarketPricesWidgetState extends State<MarketPricesWidget> {
  String? _selectedRegion;
  String? _selectedCoffeeVariety; // Updated to reflect coffee focus
  final TextEditingController _marketController = TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  double? _predictedPrice;
  double? _userRetailPrice;
  bool _isLoading = false;

  static final Color coffeeBrown = Colors.brown[700]!; // CoffeeCore theme color

  // Mock prices for coffee varieties (in Ksh/kg)
  final Map<String, double> _mockPrices = {
    "Arabica": 250.0,
    "Robusta": 180.0,
    "Liberica": 200.0,
    "Excelsa": 220.0,
  };

  @override
  void dispose() {
    _marketController.dispose();
    _retailPriceController.dispose();
    super.dispose();
  }

  void _showPredictedPrice() async {
    if (_selectedCoffeeVariety != null && _mockPrices.containsKey(_selectedCoffeeVariety)) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1)); // Simulated delay
      setState(() {
        _predictedPrice = _mockPrices[_selectedCoffeeVariety];
        _isLoading = false;
      });
    } else {
      _showLogger('Please select a coffee variety.');
    }
  }

  void _updateRetailPrice() {
    final value = double.tryParse(_retailPriceController.text);
    if (value != null && value >= 0) {
      setState(() => _userRetailPrice = value);
    } else {
      _showLogger('Please enter a valid non-negative price.');
      _retailPriceController.clear();
      setState(() => _userRetailPrice = null);
    }
  }

  void _saveMarketPrice() async {
    if (_selectedRegion == null || _marketController.text.isEmpty || _selectedCoffeeVariety == null || _userRetailPrice == null) {
      _showLogger('Please complete all fields before saving.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLogger('Please log in to save data.');
      return;
    }

    final marketData = MarketData(
      region: _selectedRegion!,
      market: _marketController.text.trim(),
      cropType: _selectedCoffeeVariety!, // Using "cropType" as "coffee variety" in model
      predictedPrice: _predictedPrice ?? 0.0,
      retailPrice: _userRetailPrice!,
      userId: user.uid,
      timestamp: Timestamp.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('marketdata')
          .doc()
          .set(marketData.toMap());
      _showLogger('Coffee market price details saved successfully!');
    } catch (e) {
      _showLogger('Failed to save data: $e');
    }
  }

  void _resetFields() {
    setState(() {
      _selectedRegion = null;
      _selectedCoffeeVariety = null;
      _marketController.clear();
      _retailPriceController.clear();
      _predictedPrice = null;
      _userRetailPrice = null;
    });
  }

  void _showLogger(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.brown[50],
        textTheme: TextTheme(
          bodyMedium: const TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: coffeeBrown, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coffeeBrown,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Market Prices', // Updated title
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          elevation: 0,
          backgroundColor: coffeeBrown,
          foregroundColor: Colors.white,
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  items: ['Nairobi', 'Coast', 'Lake', 'Rift Valley', 'Central', 'Eastern']
                      .map((region) => DropdownMenuItem(value: region, child: Text(region)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRegion = value),
                  decoration: InputDecoration(
                    labelText: 'Select Region',
                    prefixIcon: Icon(Icons.location_on, color: coffeeBrown),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _marketController,
                  decoration: InputDecoration(
                    labelText: 'Enter Market',
                    hintText: 'e.g., Gikomba',
                    prefixIcon: Icon(Icons.store, color: coffeeBrown),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCoffeeVariety,
                  items: _mockPrices.keys
                      .map((variety) => DropdownMenuItem(value: variety, child: Text(variety)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCoffeeVariety = value),
                  decoration: InputDecoration(
                    labelText: 'Select Coffee Variety', // Updated label
                    prefixIcon: Icon(Icons.local_cafe, color: coffeeBrown),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showPredictedPrice,
                  icon: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.visibility, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Loading...' : 'Show Predicted Price',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                if (_predictedPrice != null)
                  Row(
                    children: [
                      Icon(Icons.price_check, color: coffeeBrown, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Market Price: Ksh ${_predictedPrice!.toStringAsFixed(2)}/kg',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: coffeeBrown),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _retailPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Your Retail Price (Ksh/kg)',
                    hintText: 'e.g., 260.0',
                    prefixIcon: Icon(Icons.attach_money, color: coffeeBrown),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => _updateRetailPrice(),
                ),
                const SizedBox(height: 16),
                if (_userRetailPrice != null)
                  Row(
                    children: [
                      Icon(
                        _userRetailPrice! > (_predictedPrice ?? 0) ? Icons.arrow_upward : Icons.arrow_downward,
                        color: _userRetailPrice! > (_predictedPrice ?? 0) ? coffeeBrown : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Retail Price: Ksh ${_userRetailPrice!.toStringAsFixed(2)}/kg',
                        style: const TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saveMarketPrice,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _resetFields,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ViewSavedDataPage()),
                    ),
                    icon: const Icon(Icons.list, color: Colors.white),
                    label: const Text(
                      'View Saved Data',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}