import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeecore/models/market_data.dart'; 
import 'package:logger/logger.dart';

class ViewSavedDataPage extends StatefulWidget {
  const ViewSavedDataPage({super.key});

  @override
  ViewSavedDataPageState createState() => ViewSavedDataPageState();
}

class ViewSavedDataPageState extends State<ViewSavedDataPage> {
  final logger = Logger(printer: PrettyPrinter());
  static final Color coffeeBrown = Colors.brown[700]!; // CoffeeCore theme color

  void _deleteData(String docId) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this coffee market data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await FirebaseFirestore.instance.collection('marketdata').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Coffee market data deleted successfully!'),
            backgroundColor: coffeeBrown,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _editData(MarketData data) async {
    if (!mounted) return;

    TextEditingController regionController = TextEditingController(text: data.region);
    TextEditingController marketController = TextEditingController(text: data.market);
    TextEditingController coffeeVarietyController = TextEditingController(text: data.cropType); // Updated label
    TextEditingController retailPriceController = TextEditingController(text: data.retailPrice.toString());

    bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Coffee Market Data'), // Updated title
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: regionController,
                decoration: const InputDecoration(labelText: 'Region'),
              ),
              TextField(
                controller: marketController,
                decoration: const InputDecoration(labelText: 'Market'),
              ),
              TextField(
                controller: coffeeVarietyController,
                decoration: const InputDecoration(labelText: 'Coffee Variety'), // Updated label
              ),
              TextField(
                controller: retailPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Retail Price (Ksh/kg)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (regionController.text.isEmpty ||
                  marketController.text.isEmpty ||
                  coffeeVarietyController.text.isEmpty ||
                  retailPriceController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('All fields must be filled')),
                );
                return;
              }

              double? retailPrice = double.tryParse(retailPriceController.text);
              if (retailPrice == null || retailPrice < 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Enter a valid retail price')),
                );
                return;
              }

              Navigator.pop(dialogContext, true); // Signal to save
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true && mounted) {
      try {
        await FirebaseFirestore.instance.collection('marketdata').doc(data.id).update({
          'region': regionController.text,
          'market': marketController.text,
          'cropType': coffeeVarietyController.text, // Still maps to 'cropType' in Firestore
          'retailPrice': double.parse(retailPriceController.text),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Coffee market data updated successfully!'),
              backgroundColor: coffeeBrown,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update data: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('View Saved Coffee Market Data'), // Updated title
          backgroundColor: coffeeBrown,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please log in to view saved coffee market data.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Saved Coffee Market Data', // Updated title
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: coffeeBrown,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('marketdata')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: coffeeBrown),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading your saved coffee market data...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No saved coffee market data found.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final dataList = snapshot.data!.docs.map((doc) {
            try {
              return MarketData.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
                null,
              );
            } catch (e) {
              logger.e('Error parsing document ${doc.id}: $e');
              return MarketData(
                id: doc.id,
                region: 'Error',
                market: 'Error',
                cropType: 'Error',
                predictedPrice: 0.0,
                retailPrice: 0.0,
                userId: user.uid,
                timestamp: Timestamp.now(),
              ); // Fallback data for parsing errors
            }
          }).toList();

          return ListView.builder(
            itemCount: dataList.length,
            itemBuilder: (context, index) {
              final data = dataList[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    '${data.cropType} - ${data.market}', // Displays coffee variety
                    style: TextStyle(fontWeight: FontWeight.bold, color: coffeeBrown),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Region: ${data.region}'),
                      Text('Predicted: Ksh ${data.predictedPrice.toStringAsFixed(2)}/kg'),
                      Text('Retail: Ksh ${data.retailPrice.toStringAsFixed(2)}/kg'),
                      Text(
                        'Saved on: ${data.timestamp.toDate().toString().substring(0, 19)}',
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editData(data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteData(data.id!),
                      ),
                    ],
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