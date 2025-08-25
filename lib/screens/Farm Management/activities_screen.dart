import 'package:coffeecore/screens/Farm Management/firestore_service.dart';
import 'package:coffeecore/screens/Farm Management/historical_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'constants.dart';

class ActivitiesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> labourActivities;
  final List<Map<String, dynamic>> mechanicalCosts;
  final List<Map<String, dynamic>> inputCosts;
  final List<Map<String, dynamic>> miscellaneousCosts;
  final List<Map<String, dynamic>> revenues;
  final List<Map<String, dynamic>> paymentHistory;
  final String totalCosts;
  final String profitLoss;
  final Function(String, int) onDelete;

  ActivitiesScreen({
    super.key,
    required this.labourActivities,
    required this.mechanicalCosts,
    required this.inputCosts,
    required this.miscellaneousCosts,
    required this.revenues,
    required this.paymentHistory,
    required this.totalCosts,
    required this.profitLoss,
    required this.onDelete,
  });

  final FirestoreService _firestoreService = FirestoreService();
  final String userUid = FirebaseAuth.instance.currentUser!.uid;
  final Logger logger = Logger();

  Future<void> _deleteActivity(BuildContext context, String type, int index) async {
    try {
      logger.i('Attempting to delete $type activity at index $index');
      Map<String, dynamic> activityData;

      switch (type) {
        case 'labour':
          activityData = labourActivities[index];
          break;
        case 'mechanical':
          activityData = mechanicalCosts[index];
          break;
        case 'input':
          activityData = inputCosts[index];
          break;
        case 'miscellaneous':
          activityData = miscellaneousCosts[index];
          break;
        case 'revenue':
          activityData = revenues[index];
          break;
        case 'payment':
          activityData = paymentHistory[index];
          break;
        default:
          logger.e('Unknown activity type: $type');
          throw Exception('Unknown activity type');
      }

      HistoricalData historicalData = HistoricalData(
        activity: activityData['activity'] ??
            activityData['description'] ??
            activityData['coffeeVariety'],
        cost: activityData['cost'],
        date: activityData['date'],
        userId: userUid,
      );

      logger.i('Deleting activity: ${historicalData.activity}, Cost: ${historicalData.cost}');
      await _firestoreService.deleteFarmData(userUid, historicalData);
      onDelete(type, index);

      logger.i('Activity deleted successfully!');
    } catch (error) {
      logger.e('Failed to delete activity: $error');
      // Check if context is still valid before showing dialog
      if (context.mounted) {
        _showErrorDialog(context, 'Error Deleting Activity',
            'Could not delete the activity. Please try again later.');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    logger.w('Showing error dialog: $title - $message');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building ActivitiesScreen');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Management',
          onPressed: () {
            logger.i('Back button pressed');
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'All Farm Activities',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: customBrown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: const Text(
                  'Total Costs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('KSH $totalCosts'),
                leading: Icon(Icons.account_balance_wallet, color: customBrown),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: const Text(
                  'Profit/Loss',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('KSH $profitLoss'),
                leading: Icon(
                    profitLoss.startsWith('-')
                        ? Icons.trending_down
                        : Icons.trending_up,
                    color: profitLoss.startsWith('-') ? Colors.red : Colors.green),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Labour Activities',
              labourActivities,
              'labour',
              icon: Icons.person,
              itemBuilder: (item) =>
                  '${item['activity']} - KSH ${item['cost']}',
              subtitleBuilder: (item) => 'Date: ${item['date']}',
            ),
            _buildSection(
              context,
              'Mechanical Costs',
              mechanicalCosts,
              'mechanical',
              icon: Icons.build,
              itemBuilder: (item) =>
                  '${item['equipment']} - KSH ${item['cost']}',
              subtitleBuilder: (item) => 'Date: ${item['date']}',
            ),
            _buildSection(
              context,
              'Input Costs',
              inputCosts,
              'input',
              icon: Icons.agriculture,
              itemBuilder: (item) => '${item['input']} - KSH ${item['cost']}',
              subtitleBuilder: (item) => 'Date: ${item['date']}',
            ),
            _buildSection(
              context,
              'Miscellaneous Costs',
              miscellaneousCosts,
              'miscellaneous',
              icon: Icons.miscellaneous_services,
              itemBuilder: (item) =>
                  '${item['description']} - KSH ${item['cost']}',
              subtitleBuilder: (item) => 'Date: ${item['date']}',
            ),
            _buildSection(
              context,
              'Revenues',
              revenues,
              'revenue',
              icon: Icons.monetization_on,
              itemBuilder: (item) =>
                  '${item['coffeeVariety']} - KSH ${item['amount']}',
              subtitleBuilder: (item) =>
                  'Yield: ${item['yield'] ?? 'N/A'} kg - Date: ${item['date']}',
            ),
            _buildSection(
              context,
              'Loan Payments',
              paymentHistory,
              'payment',
              icon: Icons.payment,
              itemBuilder: (item) =>
                  '${item['date']} - KSH ${item['amount']}',
              subtitleBuilder: (item) =>
                  'Remaining: KSH ${item['remainingBalance']}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
    String type, {
    required IconData icon,
    required String Function(Map<String, dynamic>) itemBuilder,
    required String Function(Map<String, dynamic>) subtitleBuilder,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: customBrown),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: customBrown,
          ),
        ),
        children: items.isEmpty
            ? [
                const ListTile(
                  title: Text(
                    'No data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ]
            : items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    ListTile(
                      title: Text(itemBuilder(item)),
                      subtitle: Text(subtitleBuilder(item)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteActivity(context, type, index),
                      ),
                    ),
                    if (index < items.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
      ),
    );
  }
}